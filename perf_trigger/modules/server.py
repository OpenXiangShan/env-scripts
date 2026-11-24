import logging
import os
from pathlib import Path
import random
import re
import shlex
import signal
import subprocess
import time
from typing import IO, Any

from .gcpt import GCPT
from .types import EmuConfig, FreeCoreInfo, PendingTask
from .tracker import Tracker

GET_FREE_CORE_SCRIPT_PATH = Path(__file__).parent / "get_free_cores.py"
with GET_FREE_CORE_SCRIPT_PATH.open("r", encoding="utf-8") as f:
    GET_FREE_CORE_SCRIPT = f.read()

MIN_ALLOC_CORES = 8
LOG_TRUNCATE_LIMIT = 2048
SSH_STOP_TIMEOUT = 5

# SSH stdin is a lifetime pipe. On EOF the worker stops only its own process
# group, even if the launcher did not get a chance to run its cleanup.
SSH_EMU_GUARD = """\
import os
import select
import signal
import subprocess
import sys
import time

with subprocess.Popen(
    sys.argv[1:], stdin=subprocess.DEVNULL, start_new_session=True
) as emu:
    while emu.poll() is None:
        if not select.select([0], [], [], 1)[0]:
            continue
        try:
            os.killpg(emu.pid, signal.SIGTERM)
            # Keep the leader unreaped so the process group ID cannot be reused.
            time.sleep(1)
            os.killpg(emu.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        break
status = emu.returncode
sys.exit(status if status >= 0 else 128 - status)
"""


class Server:
    def __init__(
        self,
        hostname: str,
        emu_path: Path,
        tracker: Tracker,
        nemu_so_path: Path | None = None,
    ):
        self.hostname = hostname
        self.emu_path = emu_path
        self.nemu_so_path = nemu_so_path
        self.pending_task: list[PendingTask] = []
        self.free_info: FreeCoreInfo = FreeCoreInfo(
            free=False, mem_node=0, start=0, end=0, total=0
        )
        self.tracker = tracker

    def __str__(self) -> str:
        return self.hostname

    def self_test(self) -> bool:
        return self.run(["hostname"]).wait() == 0

    def has_cached_free_core(self, threads: int) -> bool:
        return self.free_info.free and self.free_info.num() >= threads

    def get_cached_free_cores(self, threads: int) -> FreeCoreInfo:
        # if we have enough cached free cores, split and return
        if self.has_cached_free_core(threads):
            return self.free_info.split(threads)
        return FreeCoreInfo.none()

    def __detect_free_core_script(self) -> None:
        # check if script path exists on remote server, if true, use it to get free cores, otherwise fallback to inline script
        p = self.run(
            [
                "test",
                "-e",
                shlex.quote(str(GET_FREE_CORE_SCRIPT_PATH)),
            ],
        )
        if p.returncode == 0:
            self.__use_inline_script = False
            logging.debug(
                "get_free_cores.py found on %s, using it to detect free cores",
                self.hostname,
            )
        else:
            self.__use_inline_script = True
            logging.warning(
                "get_free_cores.py not found on %s, fallback to inline script",
                self.hostname,
            )

    @property
    def use_inline_script(self) -> bool:
        if not hasattr(self, "_Server__use_inline_script"):
            self.__detect_free_core_script()
        return self.__use_inline_script

    def get_free_cores(self, threads: int) -> FreeCoreInfo:
        try:
            if self.use_inline_script:
                p = self.run(
                    [
                        "python3",
                        "-c",
                        shlex.quote(
                            GET_FREE_CORE_SCRIPT.format(n=max(threads, MIN_ALLOC_CORES))
                        ),
                    ],
                    check=True,
                )
            else:
                p = self.run(
                    [
                        "python3",
                        "-P",
                        shlex.quote(str(GET_FREE_CORE_SCRIPT_PATH)),
                        str(max(threads, MIN_ALLOC_CORES)),
                    ],
                    check=True,
                )
        except RuntimeError as e:
            logging.error(e)
            return FreeCoreInfo.none()

        if p.stdout is None:
            logging.error("No stdout from get_free_cores.py on %s", self.hostname)
            return FreeCoreInfo.none()

        result = p.stdout.read().decode().strip()
        if len(result) == 0:
            logging.error("Empty output from get_free_cores.py on %s", self.hostname)
            return FreeCoreInfo.none()

        result = re.match(r"\((True|False), (\d+), (\d+), (\d+), (\d+)\)", result)
        if result is None:
            logging.error(
                "Unexpected output from get_free_cores.py on %s: %s",
                self.hostname,
                result,
            )
            return FreeCoreInfo.none()

        info = FreeCoreInfo(
            free=result.group(1) == "True",
            mem_node=int(result.group(2)),
            start=int(result.group(3)),
            end=int(result.group(4)),
            total=int(result.group(5)),
        )

        # if we got more than needed, cache the remaining cores
        if info.free and MIN_ALLOC_CORES > threads:
            self.free_info = info
            info = self.free_info.split(threads)

        # there is already a pending task using the same free cores, it may not started properly yet
        # return not free in this case, let higher level wait and retry
        if any(info == pending.free for pending in self.pending_task):
            info.free = False

        return info

    def __log_str(self, s: str) -> str:
        if len(s) >= LOG_TRUNCATE_LIMIT:
            half = LOG_TRUNCATE_LIMIT // 2
            return f"{s[:half]} ... truncated ... {s[-half:]}"
        return s

    def __read_output(
        self,
        name: str,
        stream: int | IO[Any] | Path | None,
        destination: int | IO[Any] | None = None,
        path: Path | None = None,
    ) -> tuple[bool, str, str]:
        """Return readability, display name, and full data or an unavailable reason."""
        if path is not None:
            source = path
        else:
            source = stream if stream is not None else destination

        if source is None:
            return False, name, "not captured"
        if isinstance(source, int):
            if source == subprocess.DEVNULL:
                return False, name, "redirected to /dev/null"
            if source == subprocess.STDOUT:
                return False, name, "redirected to stdout"
            if source == subprocess.PIPE:
                return False, name, "capture pipe unavailable"
            return (
                False,
                name,
                f"redirected to file descriptor {source}; output unavailable",
            )

        if isinstance(source, Path):
            output_path = source
        else:
            try:
                source.flush()
            except (OSError, ValueError):
                pass
            source_name = getattr(source, "name", None)
            output_path = (
                Path(source_name)
                if isinstance(source_name, (str, os.PathLike))
                else None
            )

        if output_path is not None:
            name = f"{name} ({output_path})"
        try:
            output = (
                output_path.read_bytes() if output_path is not None else source.read()
            )
        except (OSError, ValueError) as e:
            return False, name, f"unable to read output: {type(e).__name__}: {e}"

        data = (
            output.decode(errors="replace")
            if isinstance(output, bytes)
            else str(output)
        )
        return True, name, data

    def __format_output(self, readable: bool, name: str, data: str) -> str:
        output = self.__log_str(data) if readable else f"<{data}>"
        return f"=== {name} ===\n{output}\n"

    def poll(self) -> tuple[list[PendingTask], list[PendingTask], list[PendingTask]]:
        still_pending: list[PendingTask] = []
        failed: list[PendingTask] = []
        success: list[PendingTask] = []
        for task in self.pending_task:
            result = task.proc.poll()
            if result is None:
                still_pending.append(task)
                continue

            if task.proc.stdin is not None:
                task.proc.stdin.close()

            # process finished, check result and call .wait() to cleanup
            if result != 0:
                stdout = self.__read_output(
                    "stdout", task.proc.stdout, path=task.stdout_path
                )
                stderr = self.__read_output(
                    "stderr", task.proc.stderr, path=task.stderr_path
                )
                self.tracker.error(
                    "%s failed \twith code %d \ton %s \tin %s\n"
                    "=== Command ===\n%s\n%s%s",
                    task.name,
                    task.proc.returncode,
                    self.hostname,
                    time.strftime("%Hh %Mm %Ss", time.gmtime(task.elapsed)),
                    (
                        self.__log_str(shlex.join(task.command))
                        if task.command
                        else "<unknown>"
                    ),
                    self.__format_output(*stdout),
                    self.__format_output(*stderr),
                )
                failed.append(task)
            else:
                self.tracker.info(
                    "%s succeeded \ton %s \tin %s",
                    task.name,
                    self.hostname,
                    time.strftime("%Hh %Mm %Ss", time.gmtime(task.elapsed)),
                )
                success.append(task)
            task.proc.wait()
        self.pending_task = still_pending
        if self.pending_task:
            self.tracker.debug(
                "Pending tasks on %s: %s",
                self.hostname,
                (
                    ", ".join([t.name for t in self.pending_task[:5]])
                    + (
                        f" (+{len(self.pending_task) - 5})"
                        if len(self.pending_task) > 5
                        else ""
                    )
                ),
            )
        return success, failed, self.pending_task.copy()

    def run(
        self,
        cmd: list[str],
        stdout: int | IO[Any] = subprocess.PIPE,
        stderr: int | IO[Any] = subprocess.PIPE,
        block: bool = True,
        check: bool = False,
        *,
        stop_on_disconnect: bool = False,
    ):
        guard_options = []
        remote_cmd = cmd
        if stop_on_disconnect:
            guard_options = ["-T", "-o", "StdinNull=no"]
            remote_cmd = ["python3", "-c", shlex.quote(SSH_EMU_GUARD), *cmd]
        p = subprocess.Popen(
            [
                "ssh",
                self.hostname,
                *guard_options,
                "-o",
                "BatchMode=yes",
                "-o",
                "ConnectionAttempts=3",
                "-o",
                "TCPKeepAlive=yes",
                "-o",
                "ServerAliveInterval=300",
                "-o",
                "ServerAliveCountMax=576",  # 2 days
            ]
            + remote_cmd,
            stdin=subprocess.PIPE if stop_on_disconnect else None,
            stdout=stdout,
            stderr=stderr,
        )
        if block or check:
            p.wait()
        if check and p.returncode != 0:
            stdout_output = self.__read_output("stdout", p.stdout, destination=stdout)
            stderr_output = self.__read_output("stderr", p.stderr, destination=stderr)
            raise RuntimeError(
                f"Remote command failed({p.returncode}) on {self.hostname}\n"
                + f"=== Command ===\n{self.__log_str(shlex.join(cmd))}\n"
                + self.__format_output(*stdout_output)
                + self.__format_output(*stderr_output)
            )
        return p

    def run_gcpt(
        self,
        gcpt: GCPT,
        emu_config: EmuConfig,
        free_cores: FreeCoreInfo,
    ):
        gcpt.result_path.mkdir(parents=True, exist_ok=True)

        # find binary
        with (
            gcpt.stdout_path.open("w", encoding="utf-8") as fout,
            gcpt.stderr_path.open("w", encoding="utf-8") as ferr,
        ):
            run_cmd = (
                (
                    [
                        "numactl",
                        "-m",
                        str(free_cores.mem_node),
                        "-C",
                        f"{free_cores.start}-{free_cores.end}",
                    ]
                    if emu_config.with_numactl
                    else []
                )
                + [
                    str(self.emu_path),
                    "-W",
                    str(emu_config.warmup) if not emu_config.dry_run else "1000",
                    "-I",
                    str(emu_config.max_instr) if not emu_config.dry_run else "2000",
                    "-i",
                    shlex.quote(str(gcpt.bin_path)),
                    "-s",
                    str(random.randint(0, 9999)),
                ]
                + (
                    ["--diff", str(self.nemu_so_path)]
                    if self.nemu_so_path
                    else ["--no-diff"]
                )
                + (
                    ["-C", str(emu_config.max_cycles)]
                    if emu_config.max_cycles is not None
                    else []
                )
                + (
                    ["--cst-file", shlex.quote(str(emu_config.cst_file))]
                    if emu_config.cst_file
                    else []
                )
                + (
                    [
                        "--dump-db",
                        "--db-path",
                        shlex.quote(str(gcpt.db_path)),
                    ]
                    if emu_config.dump_db
                    else []
                )
            )
            if emu_config.dry_run:
                cmd_str = " ".join(run_cmd)
                self.tracker.info("[DRYRUN] CMD: %s", cmd_str)

            # The cancellation handler must see every SSH writer we start.
            interrupted = False

            def defer_sigint(_signum, _frame):
                nonlocal interrupted
                interrupted = True

            previous_handler = signal.signal(signal.SIGINT, defer_sigint)
            try:
                p = self.run(
                    run_cmd,
                    stdout=fout,
                    stderr=ferr,
                    block=False,
                    stop_on_disconnect=True,
                )
                self.pending_task.append(
                    PendingTask(
                        proc=p,
                        name=str(gcpt),
                        free=free_cores,
                        command=tuple(run_cmd),
                        stdout_path=gcpt.stdout_path,
                        stderr_path=gcpt.stderr_path,
                        gcpt=gcpt,
                    )
                )
            finally:
                signal.signal(signal.SIGINT, previous_handler)
                if interrupted:
                    signal.raise_signal(signal.SIGINT)
        self.tracker.info("Started %s on %s", gcpt, self.hostname)
        self.tracker.debug(
            "Assigned cores %d-%d (total %d) on mem node %d",
            free_cores.start,
            free_cores.end,
            free_cores.total,
            free_cores.mem_node,
        )

    @staticmethod
    def stop_all(servers: list["Server"]) -> None:
        processes = []
        for server in servers:
            for task in server.pending_task:
                proc = task.proc
                if proc.stdin is not None:
                    proc.stdin.close()
                processes.append(proc)
            server.pending_task = []

        # Drain the old SSH writers before the launcher releases the result lock.
        deadline = time.monotonic() + SSH_STOP_TIMEOUT
        for proc in processes:
            try:
                proc.wait(timeout=max(0, deadline - time.monotonic()))
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()

    def initialize_open(self, source_path: Path, target_path: Path):
        """Open servers does not share the same nfs with node, rsync emu to server target_path"""
        assert self.hostname.startswith("open")

        source_path = source_path.resolve()

        # Skip if already exists
        p = self.run(
            [
                "test",
                "-e",
                shlex.quote(str(target_path)),
            ],
        )
        if p.returncode == 0:
            logging.info(
                "File already exists on open server (%s), skip copying.", target_path
            )
            return

        # Ensure remote parent directory exists
        self.run(
            ["mkdir", "-p", shlex.quote(str(target_path.parent))],
            check=True,
        )

        lock_path = Path(f"{target_path}.copy.lock")
        tmp_path = Path(f"{target_path}.tmp")

        lock_state = "BLOCKED"
        try:
            lr = self.run(
                [
                    "bash",
                    "-lc",
                    (
                        "umask 077 >/dev/null; LOCK="
                        + shlex.quote(str(lock_path))
                        + '; if mkdir "$LOCK"; then echo ACQUIRED; else echo BLOCKED; fi'
                    ),
                ],
                check=True,
            )
            if lr.stdout is not None:
                lock_state = lr.stdout.read().decode().strip() or "BLOCKED"
        except RuntimeError as e:
            logging.error(e)
            lock_state = "BLOCKED"

        if lock_state == "ACQUIRED":
            try:
                # emu_path is a file: copy via rsync, then atomically move into place
                subprocess.run(  # do not use self.run, we need this locally
                    [
                        "rsync",
                        "-a",
                        str(source_path),
                        f"{self.hostname}:{tmp_path}",
                    ],
                    check=True,
                )

                self.run(
                    [
                        "mv",
                        "-f",
                        shlex.quote(str(tmp_path)),
                        shlex.quote(str(target_path)),
                    ],
                    check=True,
                )
            except (RuntimeError, subprocess.CalledProcessError) as e:
                logging.error(e)
            finally:
                # Always release lock
                self.run(["rmdir", shlex.quote(str(lock_path))])
        else:
            # Another process is copying; wait until path exists or lock disappears
            deadline = time.time() + 300  # 5 minutes timeout
            while time.time() < deadline:
                cr = self.run(
                    [
                        "test",
                        "-e",
                        shlex.quote(str(target_path)),
                    ]
                )
                if cr.returncode == 0:
                    break
                time.sleep(1)

        # Final verify
        self.run(
            [
                "test",
                "-e",
                shlex.quote(str(target_path)),
            ],
            check=True,
        )
        logging.info(
            "Copied %s to open server (%s) successfully.",
            source_path.name,
            target_path,
        )
