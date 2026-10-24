from collections.abc import Callable, Collection, Sequence
from datetime import datetime, timezone
import hashlib
import os
from pathlib import Path
import re
import shlex
import signal
import subprocess
import time

from .common import ManagerError, execute
from .models import Instance, Operation, Pane, Process, RunnerDetails, RunnerState


def processes() -> dict[int, Process]:
    """Read process ancestry and command lines for the current user."""
    result: dict[int, Process] = {}
    user_id = os.geteuid()
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            if entry.stat().st_uid != user_id:
                continue
            status = (entry / "stat").read_text()
            fields = status[status.rfind(")") + 2 :].split()
            if fields[0] == "Z":
                continue
            result[int(entry.name)] = {
                "parent": int(fields[1]),
                "group": int(fields[2]),
                "command": (entry / "cmdline")
                .read_bytes()
                .replace(b"\0", b" ")
                .decode(errors="replace"),
            }
        except (OSError, ValueError, IndexError):
            continue
    return result


def descendants(pid: int, table: dict[int, Process]) -> set[int]:
    """Find a process and all of its current descendants."""
    found = {pid}
    while True:
        children = {child for child, value in table.items() if value["parent"] in found}
        expanded = found | children
        if expanded == found:
            return found
        found = expanded


def assert_no_unmanaged_process(path: Path, allowed: Collection[int] = ()) -> None:
    """Reject runner processes using a directory outside managed ancestry."""
    path = Path(path).resolve()
    table = processes()
    for pid, value in table.items():
        if pid in allowed or not re.search(
            r"Runner\.(Listener|Worker)|(?:^|[/ ])(?:run|runsvc|run-helper)\.sh(?: |$)",
            value["command"],
        ):
            continue
        try:
            directory = Path(os.readlink(f"/proc/{pid}/cwd")).resolve()
        except FileNotFoundError:
            continue
        except PermissionError as error:
            raise ManagerError(
                f"Cannot verify runner process {pid}; stop it before proceeding"
            ) from error
        if directory == path or directory.is_relative_to(path):
            raise ManagerError(
                f"Unmanaged runner process {pid} is using {path}; stop it first"
            )


def parse_runner_output(output: str, now: datetime | None = None) -> RunnerDetails:
    """Extract runner start, task state and results from timestamped output."""
    details: RunnerDetails = {
        "state": "unknown",
        "current_task": None,
        "started_at": None,
        "elapsed": None,
        "last_task": None,
        "result": None,
    }
    output = output.rsplit("Current runner version:", 1)[-1]
    current_time = now or datetime.now(timezone.utc)
    for line in output.splitlines():
        timestamp = None
        match = re.match(
            r"^\s*(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})):\s*(.*)$",
            line,
        )
        message = line.strip()
        if match:
            try:
                timestamp = datetime.fromisoformat(match[1])
            except ValueError:
                pass
            message = match[2]
        if message == "Listening for Jobs":
            if details["started_at"] is None and timestamp is not None:
                details["started_at"] = timestamp.astimezone().isoformat(
                    timespec="seconds"
                )
            details["state"] = "idle"
            details["current_task"] = None
            details["elapsed"] = None
        elif message.startswith("Running job:"):
            details["state"] = "busy"
            details["current_task"] = (
                message.removeprefix("Running job:").strip() or None
            )
            details["elapsed"] = (
                max(0, int((current_time - timestamp).total_seconds()))
                if timestamp
                else None
            )
        elif completed := re.fullmatch(
            r"Job (.+) completed with result: (\w+)", message
        ):
            details["state"] = "idle"
            details["current_task"] = None
            details["elapsed"] = None
            details["last_task"] = completed[1]
            details["result"] = {
                "succeeded": "Success",
                "success": "Success",
                "failed": "Failed",
                "canceled": "Cancelled",
                "cancelled": "Cancelled",
            }.get(completed[2].casefold(), completed[2])
    return details


class Tmux:
    """Control runner processes through identified tmux windows."""

    def __init__(self, root: Path, hostname: str) -> None:
        """Bind tmux resource names to a manager root and hostname."""
        self.root = root
        self.hostname = hostname

    def key(self, name: str) -> str:
        """Derive a stable ownership key for a runner group."""
        return hashlib.sha256(
            f"{self.root}:{self.hostname}:{name}".encode()
        ).hexdigest()[:16]

    def session(self, name: str) -> str:
        """Build the tmux session name for a runner group."""
        return f"ci-{self.hostname}-{name}-{self.key(name)[:8]}"

    def call(
        self, *arguments: str, check: bool = True
    ) -> subprocess.CompletedProcess[str]:
        """Execute a tmux command and optionally check its exit status."""
        return execute(["tmux", *arguments], check=check)

    def pane(self, name: str, index: int, path: Path) -> Pane | None:
        """Locate the unique pane matching a runner's ownership metadata."""
        result = self.call(
            "list-panes",
            "-a",
            "-F",
            "#{session_name}\t#{pane_id}\t#{pane_pid}\t#{pane_dead}\t#{@ci_key}\t#{@ci_index}\t#{@ci_path}",
            check=False,
        )
        if result.returncode:
            if "no server running" in result.stderr or "No such file" in result.stderr:
                return None
            raise ManagerError(f"Cannot inspect tmux: {result.stderr.strip()}")
        matches: list[Pane] = []
        for line in result.stdout.splitlines():
            fields = line.split("\t")
            if len(fields) != 7:
                continue
            session, pane, pid, dead, key, runner_index, directory = fields
            if key == self.key(name) and runner_index == str(index):
                if directory != str(path) or session != self.session(name):
                    raise ManagerError(f"Conflicting tmux identity for {name}[{index}]")
                matches.append(
                    {
                        "id": pane,
                        "pid": int(pid),
                        "dead": dead == "1",
                        "session": session,
                    }
                )
        if len(matches) > 1:
            raise ManagerError(f"Multiple tmux panes claim {name}[{index}]")
        return matches[0] if matches else None

    def state(self, name: str, instance: Instance) -> tuple[RunnerState, Pane | None]:
        """Observe runner activity from pane state, processes and output."""
        path = Path(instance["path"])
        pane = self.pane(name, instance["index"], path)
        if not pane or pane["dead"]:
            assert_no_unmanaged_process(path)
            return "stopped", pane
        table = processes()
        family = descendants(pane["pid"], table)
        assert_no_unmanaged_process(path, family)
        process = table.get(pane["pid"])
        if process and process["command"].strip() == "sleep 2147483647":
            return "stopped", pane
        if any(
            "Runner.Worker" in table[pid]["command"] for pid in family if pid in table
        ):
            return "busy", pane
        output = self.call("capture-pane", "-pJ", "-S", "-", "-t", pane["id"]).stdout
        return parse_runner_output(output)["state"], pane

    def start(self, name: str, instance: Instance, proxy: Sequence[str]) -> None:
        """Start a stopped runner without duplicating an active process."""
        path = Path(instance["path"])
        state, pane = self.state(name, instance)
        if state != "stopped":
            return
        command = "exec " + shlex.join([*proxy, "./run.sh"])
        if pane:
            self.call("respawn-pane", "-k", "-t", pane["id"], "-c", str(path), command)
            return
        session = self.session(name)
        target = f"={session}"
        existing = self.call("has-session", "-t", target, check=False).returncode == 0
        if existing:
            key = self.call(
                "show-options", "-v", "-t", session, "@ci_key"
            ).stdout.strip()
            if key != self.key(name):
                raise ManagerError(f"Refusing to reuse unowned tmux session {session}")
            result = self.call(
                "new-window",
                "-d",
                "-P",
                "-F",
                "#{pane_id}",
                "-t",
                f"{session}:",
                "-n",
                str(instance["index"]),
                "-c",
                str(path),
                "exec sleep 2147483647",
            )
        else:
            result = self.call(
                "new-session",
                "-d",
                "-P",
                "-F",
                "#{pane_id}",
                "-s",
                session,
                "-n",
                str(instance["index"]),
                "-c",
                str(path),
                "exec sleep 2147483647",
            )
            self.call("set-option", "-t", session, "@ci_key", self.key(name))
        pane_id = result.stdout.strip()
        self.call("set-option", "-w", "-t", pane_id, "remain-on-exit", "on")
        self.call(
            "set-option", "-w", "-t", pane_id, "@ci_index", str(instance["index"])
        )
        self.call("set-option", "-w", "-t", pane_id, "@ci_path", str(path))
        self.call("respawn-pane", "-k", "-t", pane_id, "-c", str(path), command)

    def details(self, pane: Pane | None, state: RunnerState) -> RunnerDetails:
        """Capture task details and runner start time from tmux history."""
        details = parse_runner_output("")
        if pane is None or pane["dead"] or state == "stopped":
            return details
        output = self.call("capture-pane", "-pJ", "-S", "-", "-t", pane["id"]).stdout
        return parse_runner_output(output)

    def stop(
        self,
        name: str,
        instances: Sequence[Instance],
        operation: Operation,
        save: Callable[[], None],
        timeout: int | None = None,
        force: bool = False,
    ) -> None:
        """Stop runners after idle detection and persist stop progress."""
        started = time.monotonic()
        last_summary = None
        force_sent: dict[str, float] = {}
        while True:
            waiting = []
            for instance in instances:
                state, pane = self.state(name, instance)
                if state == "stopped":
                    if pane:
                        self.call("kill-window", "-t", pane["id"])
                    continue
                assert pane is not None
                waiting.append(f"{instance['name']}:{state}")
                index = str(instance["index"])
                stop_sent = operation.setdefault("stop_sent", {})
                identity = f"{pane['id']}:{pane['pid']}"
                if (force or state == "idle") and stop_sent.get(index) != identity:
                    self.call("send-keys", "-t", pane["id"], "C-c")
                    stop_sent[index] = identity
                    save()
                if force:
                    first_sent = force_sent.setdefault(identity, time.monotonic())
                    if time.monotonic() - first_sent >= 10:
                        table = processes()
                        for pid in sorted(
                            descendants(pane["pid"], table), reverse=True
                        ):
                            try:
                                os.kill(pid, signal.SIGKILL)
                            except ProcessLookupError:
                                pass
                        self.call("kill-window", "-t", pane["id"], check=False)
            if not waiting:
                return
            summary = ", ".join(waiting)
            if summary != last_summary:
                print(f"Waiting for stop: {summary}", flush=True)
                last_summary = summary
            if timeout is not None and time.monotonic() - started >= timeout:
                raise ManagerError(
                    "Stop timed out; progress was saved. Retry the same command to resume"
                )
            time.sleep(1)
