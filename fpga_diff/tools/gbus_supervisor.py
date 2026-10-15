#!/usr/bin/env python3
"""Fail-closed GBus orchestration and small, authenticated remote operations.

No hardware action is performed merely by importing this module. Remote workers
have an owned cwd, a unique environment token, and atomic status/rc records.
"""
import base64
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import shlex
import signal
import stat
import subprocess
import sys
import threading
import time
import uuid

OWNER = "minjie-gbus-supervisor-v3"
SAMPLE_CAP = 128 * 1024
TRANSPORT_ERROR = re.compile(
    r"invalid (?:read|write) ACK|ACK.*(?:invalid|timeout)|"
    r"FIFO.*(?:error|timeout|fail|length mismatch)|reg rw timeout|"
    r"IOCTL_XDMA_[A-Z_]+ failed|consumeDmaData timeout|failed to execute ioctl", re.I)
HOST_FINALIZED = "[fpga-host] GBus finalized; socket close confirmed"
SOURCE_EXCLUDES = ("build/", ".git", ".github/", ".kcode/", "docs/", "build_logs/", "out/",
                   "__pycache__/", ".env", ".env.*", "credentials*", "*.md", "*.log", "*.o", "*.d",
                   "*.bin", "*.dcp", "*.dat", "*.pem", "id_*", "*.key", "*.so", "*.so.*", "*.a",
                   "*.pyc", "*.vcd", "*.fst", "*.usdb", "*.tar", "*.tar.*", "*.zip")


def test_inputs(path):
    data = json.loads(Path(path).read_text())
    if data.get("cpu") not in ("nutshell", "kmh", "nanhu"):
        raise RuntimeError("manifest cpu must be nutshell, kmh or nanhu")
    if data.get("c2h_mode") not in ("config-window", "axi-dma"):
        raise RuntimeError("manifest c2h_mode must be config-window or axi-dma")
    if type(data.get("difftest_perfcnt")) is not int or data["difftest_perfcnt"] != 1:
        raise RuntimeError("manifest requires difftest_perfcnt=1")
    for name in ("workload", "reference"):
        item = data.get(name, {})
        if not isinstance(item, dict) or not re.fullmatch(r"[0-9a-f]{64}", item.get("sha256", "")):
            raise RuntimeError("manifest requires explicit " + name + " SHA256")
        source = Path(item.get("path", ""))
        if not source.is_absolute() or source.is_symlink() or not source.is_file():
            raise RuntimeError("manifest requires local absolute " + name + " file")
        if digest(source) != item["sha256"]:
            raise RuntimeError(name + " input hash mismatch")
        item["path"] = str(source.resolve(strict=True))
    release = Path(data.get("release_dir", ""))
    if not release.is_absolute() or not (release / "build/generated-src/difftest-state.h").is_file():
        raise RuntimeError("manifest release generated ABI missing")
    data["release_dir"] = str(release.resolve(strict=True))
    return data


def atomic(path, value):
    path = Path(path)
    temp = path.with_name(path.name + ".tmp." + str(os.getpid()))
    temp.write_text(value)
    os.replace(str(temp), str(path))


def digest(path):
    h = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def manifest(directory):
    directory = Path(directory)
    if directory.is_symlink() or directory.resolve(strict=True) != directory or not directory.is_dir():
        raise RuntimeError("noncanonical manifest directory: " + str(directory))
    result = {}
    for path in sorted(directory.rglob("*")):
        if path.is_symlink():
            raise RuntimeError("symlink in generated inputs: " + str(path))
        mode = path.stat().st_mode
        if stat.S_ISREG(mode):
            result[str(path.relative_to(directory))] = digest(path)
        elif not stat.S_ISDIR(mode):
            raise RuntimeError("special file in generated inputs: " + str(path))
    if not result:
        raise RuntimeError("empty generated inputs")
    return result


def load_local_tool(name):
    path = Path(__file__).resolve().parent / (name + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def owned(directory, token):
    path = Path(directory)
    if not path.is_absolute() or path.is_symlink() or path.resolve() != path:
        raise RuntimeError("noncanonical owned directory: " + str(path))
    meta = json.loads((path / ".gbus-owner.json").read_text())
    if meta.get("owner") != OWNER or meta.get("token") != token or meta.get("path") != str(path):
        raise RuntimeError("ownership mismatch: " + str(path))
    if path.stat().st_uid != os.getuid():
        raise RuntimeError("directory uid mismatch")
    return path


def proc_identity(pid, proc=Path("/proc")):
    p = proc / str(pid)
    stat = (p / "stat").read_text().rsplit(")", 1)[1].split()
    return {"pid": int(pid), "start": stat[19], "state": stat[0],
            "ppid": int(stat[1]), "uid": p.stat().st_uid,
            "cwd": os.readlink(str(p / "cwd")),
            "env": (p / "environ").read_bytes().split(b"\0")}


def verify_identity(record, directory, token, proc=Path("/proc")):
    current = proc_identity(record["pid"], proc)
    cwd = Path(current["cwd"])
    return (current["start"] == record["start"] and current["uid"] == os.getuid()
            and current["state"] != "Z" and cwd.resolve() == cwd
            and (cwd == directory or directory in cwd.parents)
            and ("GBUS_OWNER_TOKEN=" + token).encode() in current["env"]
            and ("worker" not in record or
                 ("GBUS_WORKER_NAME=" + record["worker"]).encode() in current["env"]))


def safe_signal(record, directory, token, sig=signal.SIGTERM):
    # Modern kernels use pidfds. The runtime's Linux 3.10 has no pidfds:
    # pin its proc directory and revalidate starttime/token/cwd immediately
    # before signaling. Never substitute a process-name or process-group kill.
    owned(directory, token)
    pidfds = hasattr(os, "pidfd_open") and hasattr(signal, "pidfd_send_signal")
    try:
        fd = os.pidfd_open(record["pid"]) if pidfds else os.open(
            "/proc/" + str(record["pid"]), os.O_RDONLY | os.O_DIRECTORY)
    except (FileNotFoundError, ProcessLookupError):
        return "already exited"
    try:
        if not verify_identity(record, Path(directory), token):
            raise RuntimeError("process identity/cwd/token mismatch; no signal sent")
        if pidfds:
            signal.pidfd_send_signal(fd, sig)
        else:
            pinned = os.open("stat", os.O_RDONLY, dir_fd=fd)
            try:
                start = os.read(pinned, 4096).decode().rsplit(")", 1)[1].split()[19]
            finally:
                os.close(pinned)
            if start != record["start"] or not verify_identity(record, Path(directory), token):
                raise RuntimeError("process changed during identity check; no signal sent")
            os.kill(record["pid"], sig)
        return "signaled verified pid " + str(record["pid"])
    except (FileNotFoundError, ProcessLookupError):
        return "already exited"
    finally:
        os.close(fd)


def board_state(proc=Path("/proc"), directory=None, token=None):
    """Unknown shell modes are busy; only explicit compiler modes are exempt."""
    busy = []
    for entry in proc.iterdir():
        if not entry.name.isdigit():
            continue
        try:
            args = (entry / "cmdline").read_bytes().decode(errors="replace").split("\0")
            if not any(Path(arg).name in ("uv_shell", "uv_shell_exec") for arg in args if arg):
                continue
            runtime = "-rt_shell" in args or any("runtime_server.tcl" in a for a in args)
            scripts = [args[i + 1] for i, arg in enumerate(args[:-1]) if arg in ("-s", "-script")]
            build = (not runtime and bool(scripts) and all(Path(s).name in {
                "frontend_run.tcl", "backend_run.tcl", "pnr.tcl"} for s in scripts))
            if not build:
                if directory is not None:
                    ident = proc_identity(int(entry.name), proc)
                    cwd = Path(ident["cwd"])
                    if ((cwd == directory or directory in cwd.parents) and
                            ("GBUS_OWNER_TOKEN=" + token).encode() in ident["env"]):
                        continue
                busy.append({"pid": int(entry.name), "args": args})
        except FileNotFoundError:
            continue
        except (PermissionError, OSError) as exc:
            return {"state": "unknown", "error": str(exc)}
    return {"state": "busy" if busy else "free", "processes": busy}


def require_live_transport_contract():
    # The installed driver reports wrong-kind ACKs as success; quiet logs cannot validate its I/O contract.
    raise RuntimeError("live GBus programming/I/O blocked: vendor ACK failure propagation and request drain unverified")


def daemon_transport_history(path):
    path = Path(path)
    limit = 128 * 1024 * 1024
    descriptor = os.open(str(path), os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    with os.fdopen(descriptor, "rb") as stream:
        before = os.fstat(stream.fileno())
        if not stat.S_ISREG(before.st_mode) or before.st_size > limit:
            raise RuntimeError("daemon history not a bounded regular file")
        payload = stream.read(before.st_size + 1)
        payload = payload[:before.st_size]
        if len(payload) != before.st_size:
            raise RuntimeError("daemon history truncated during scan")
        if payload and not payload.endswith(b"\n"):
            raise RuntimeError("daemon history has an incomplete trailing record")
        errors = []
        for line in payload.splitlines():
            if len(line) > 1024 * 1024:
                raise RuntimeError("daemon history exceeds bounded scan")
            text = line.decode(errors="replace")
            if TRANSPORT_ERROR.search(text):
                errors.append(text.strip())
        after = os.fstat(stream.fileno())
        visible = path.stat()
        if ((before.st_dev, before.st_ino) != (visible.st_dev, visible.st_ino)
                or after.st_size < before.st_size or after.st_size > limit):
            raise RuntimeError("daemon history changed or rotated during scan")
        stream.seek(0)
        if stream.read(before.st_size) != payload:
            raise RuntimeError("daemon history prefix changed during scan")
        return {"errors": errors, "identity": [before.st_dev, before.st_ino], "size": before.st_size}


def transport_snapshot():
    state = {"services": {}, "time": time.time(),
             "boot_id": Path("/proc/sys/kernel/random/boot_id").read_text().strip()}
    for name in ("minjie-uvhs-driver.service", "minjie-uvhs-runtime.service"):
        done = subprocess.run(["systemctl", "show", name, "--property=ActiveState,SubState,MainPID"],
                              capture_output=True, timeout=10)
        if done.returncode:
            raise RuntimeError("cannot read runtime service state")
        fields = dict(line.split("=", 1) for line in done.stdout.decode().splitlines() if "=" in line)
        state["services"][name] = fields
        if fields.get("ActiveState") != "active":
            raise RuntimeError("runtime service inactive: " + name)
        if name.endswith("runtime.service") and (fields.get("SubState") != "running" or fields.get("MainPID") == "0"):
            raise RuntimeError("runtime daemon unavailable")
    driver = Path("/sys/bus/pci/devices/0000:02:00.0/driver").resolve(strict=True).name
    if driver != "uvp_pcie_drv":
        raise RuntimeError("runtime vendor PCIe driver mismatch")
    done = subprocess.run(["dmesg"], capture_output=True, timeout=10)
    if done.returncode:
        raise RuntimeError("cannot read kernel transport health")
    kernel = done.stdout.decode(errors="replace")
    state["kernel"] = kernel[-1024 * 1024:]
    state["kernel_errors"] = [line for line in kernel.splitlines() if TRANSPORT_ERROR.search(line)][-20:]
    state["uptime"] = float(Path("/proc/uptime").read_text().split()[0])
    log = Path("/var/log/uv_runtime_sw/uv_runtime_daemon.log")
    history = daemon_transport_history(log)
    state["daemon"] = "\n".join(history["errors"])
    state["daemon_identity"] = history["identity"]
    state["daemon_size"] = history["size"]
    return state


def transport_health():
    try:
        first = transport_snapshot()
        time.sleep(2)
        second = transport_snapshot()
        errors = []
        first_lines = first["kernel"].splitlines()
        second_lines = second["kernel"].splitlines()
        if first_lines and first_lines[-1] not in second_lines:
            raise RuntimeError("kernel health snapshots cannot be aligned")
        if not first.get("boot_id") or first["boot_id"] != second.get("boot_id"):
            raise RuntimeError("runtime boot identity unavailable or changed during health check")
        if first["services"] != second["services"]:
            raise RuntimeError("runtime services changed during health check")
        if (first.get("daemon_identity") != second.get("daemon_identity")
                or second.get("daemon_size", 0) < first.get("daemon_size", 0)):
            raise RuntimeError("daemon history rotated or truncated during health check")
        for snapshot in (first, second):
            # Kernel messages belong to this boot; a quiet interval cannot clear a fault.
            errors.extend(snapshot.get("kernel_errors", [line for line in snapshot["kernel"].splitlines()
                                                         if TRANSPORT_ERROR.search(line)]))
            boot_time = snapshot["time"] - snapshot["uptime"]
            for line in snapshot["daemon"].splitlines():
                if not TRANSPORT_ERROR.search(line):
                    continue
                wall = re.search(r"\b(20[0-9]{2}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})(\.[0-9]+)?", line)
                if not wall:
                    raise RuntimeError("daemon transport failure has no usable boot timestamp")
                stamp = time.mktime(time.strptime(wall[1], "%Y-%m-%d %H:%M:%S")) + float(wall[2] or 0)
                if stamp >= boot_time:
                    errors.append(line)
        return {"state": "unhealthy" if errors else "healthy", "errors": list(dict.fromkeys(errors))[-20:],
                "time": second["time"], "boot_id": second["boot_id"], "services": second["services"]}
    except Exception as exc:
        return {"state": "unknown", "error": str(exc)}


def session_transport_health(directory, token):
    directory = owned(directory, token)
    latch = directory / "transport-fault.json"
    if latch.exists():
        return {"state": "unhealthy", "error": "owned session transport fault is latched"}
    state = transport_health()
    if state.get("state") != "healthy":
        atomic(latch, json.dumps(state))
    return state


def session_lock(directory):
    descriptor = os.open(str(directory / ".session.lock"), os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    stream = os.fdopen(descriptor, "r+")
    fcntl.flock(stream.fileno(), fcntl.LOCK_EX)
    return stream


def recorded_host_pids(directory):
    pids = set()
    for name in ("host.identity.json", "host.children.json"):
        path = directory / name
        if not path.exists():
            continue
        data = json.loads(path.read_text())
        for item in (data if isinstance(data, list) else [data]):
            if isinstance(item, dict) and isinstance(item.get("pid"), int):
                pids.add(item["pid"])
    return pids


def host_quiescent(directory, token):
    directory = owned(directory, token)
    with session_lock(directory):
        # Seal even a failed attempt, so an exit proof cannot race a later launch.
        atomic(directory / "host-closed.json", json.dumps({"token": token}))
        recorded = recorded_host_pids(directory)
        deadline = time.monotonic() + 3
        unreadable_entries = 0
        while True:
            live = []
            unreadable_entries = 0
            for entry in Path("/proc").iterdir():
                if not entry.name.isdigit():
                    continue
                try:
                    if entry.stat().st_uid != os.getuid():
                        continue
                    identity = proc_identity(int(entry.name))
                    if (identity["state"] != "Z" and ("GBUS_OWNER_TOKEN=" + token).encode() in identity["env"]
                            and b"GBUS_WORKER_NAME=host" in identity["env"]):
                        live.append(identity["pid"])
                except (FileNotFoundError, ProcessLookupError):
                    continue
                except PermissionError:
                    # Same-uid but non-dumpable session helpers (sshd session
                    # children, (sd-pam), fusermount3) deny /proc metadata
                    # reads, and every SSH invocation of this scan creates
                    # them.  Processes launched by this supervisor stay
                    # dumpable and are recorded, so an unreadable entry is
                    # skipped and counted; a recorded PID that cannot be
                    # verified still blocks below.
                    if int(entry.name) in recorded:
                        live.append(int(entry.name))
                    else:
                        unreadable_entries += 1
                    continue
            if not live:
                break
            if time.monotonic() >= deadline:
                raise RuntimeError("host processes still active; runtime preserved: " + json.dumps(live))
            time.sleep(0.1)
        state = "never_started"
        if (directory / "host.spec.json").exists():
            result = json.loads((directory / "host.result.json").read_text())
            rc = int((directory / "host.rc").read_text())
            if (rc != 0 or result.get("rc") != 0 or result.get("child_rc") != 0
                    or result.get("reason") != "exited" or result.get("cleanup_errors")):
                raise RuntimeError("host clean exit unconfirmed; runtime preserved")
            finalized = 0
            log = directory / "host.log"
            if log.is_symlink():
                raise RuntimeError("host log is a symlink")
            with log.open() as stream:
                metadata = os.fstat(stream.fileno())
                if not stat.S_ISREG(metadata.st_mode) or metadata.st_size > 128 * 1024 * 1024:
                    raise RuntimeError("host log cannot certify bounded exit proof")
                for line in stream:
                    if TRANSPORT_ERROR.search(line) or re.search(r"(?:G[Bb]us|GBD1).*\b(?:failed|timeout|deadline)\b", line):
                        raise RuntimeError("host reported transport failure; runtime preserved")
                    finalized += line.strip() == HOST_FINALIZED
            if finalized != 1:
                raise RuntimeError("host socket finalization unconfirmed; runtime preserved")
            state = "finalized"
        proof = {"token": token, "host_directory": str(directory), "state": state,
                 "sealed": True, "daemon_request_drain": "unproven",
                 "unreadable_entries_skipped": unreadable_entries}
        atomic(directory / "host-quiescent.json", json.dumps(proof))
        return proof


def runtime_identity(directory, token):
    pid = int((directory / "uv_shell.pid").read_text().strip())
    if int((directory / "uv_shell.ready").read_text().strip()) != pid:
        raise RuntimeError("runtime ready PID mismatch")
    records = json.loads((directory / "runtime.children.json").read_text())
    record = next((r for r in records if r["pid"] == pid), None)
    if record is None or record.get("worker") != "runtime" or not verify_identity(record, directory, token):
        raise RuntimeError("runtime readiness lacks a live owned process")
    return record


def require_session_safe(directory, token):
    if (directory / "runtime-fault").exists():
        raise RuntimeError("runtime initialization/command fault is latched; session preserved")
    health = session_transport_health(directory, token)
    board = board_state(directory=directory, token=token)
    if health.get("state") != "healthy" or board.get("state") != "free":
        raise RuntimeError("transport unhealthy/unknown or foreign runtime active; session preserved")
    return {"transport": health, "board": board}


def authorize_runtime_stop(directory, token, host_proof):
    directory = owned(directory, token)
    with session_lock(directory):
        spec = json.loads((directory / "runtime.spec.json").read_text())
        if (host_proof.get("token") != token or host_proof.get("host_directory") != spec.get("host_directory")
                or host_proof.get("state") not in ("never_started", "finalized") or host_proof.get("sealed") is not True):
            raise RuntimeError("sealed host exit proof missing/mismatched; runtime preserved")
        if host_proof.get("state") == "finalized" and host_proof.get("daemon_request_drain") != "verified":
            raise RuntimeError("vendor daemon request drain unproven; automatic runtime close blocked")
        require_session_safe(directory, token)
        record = runtime_identity(directory, token)
        permit = {"token": token, "runtime_directory": str(directory), "pid": record["pid"],
                  "start": record["start"], "host": host_proof, "expires": time.monotonic() + 60}
        atomic(directory / "runtime-stop-permit.json", json.dumps(permit))
        return permit


def require_runtime_stop_permit(directory, token, consume=False):
    permit = json.loads((directory / "runtime-stop-permit.json").read_text())
    spec = json.loads((directory / "runtime.spec.json").read_text())
    host = permit.get("host", {})
    if (permit.get("token") != token or permit.get("runtime_directory") != str(directory)
            or host.get("token") != token or host.get("host_directory") != spec.get("host_directory")
            or host.get("state") not in ("never_started", "finalized") or host.get("sealed") is not True
            or (host.get("state") == "finalized" and host.get("daemon_request_drain") != "verified")
            or time.monotonic() > permit["expires"]):
        raise RuntimeError("runtime stop permit invalid/expired; session preserved")
    record = runtime_identity(directory, token)
    if (permit.get("pid"), permit.get("start")) != (record["pid"], record["start"]):
        raise RuntimeError("runtime stop permit PID/starttime mismatch; session preserved")
    require_session_safe(directory, token)
    if consume:
        os.replace(str(directory / "runtime-stop-permit.json"), str(directory / "runtime-stop-consumed.json"))
    return permit


def runtime_guard(directory, token, action, pid=None):
    require_live_transport_contract()
    directory = owned(directory, token)
    spec = json.loads((directory / "runtime.spec.json").read_text())
    helper = directory / "gbus_supervisor.py"
    if helper.is_symlink() or digest(helper) != spec["env"].get("UVHS_SUPERVISOR_SHA256"):
        raise RuntimeError("runtime safety helper identity mismatch")
    if action == "launch":
        if (directory / "runtime.result.json").exists():
            raise RuntimeError("runtime worker already failed; session preserved")
        return require_session_safe(directory, token)
    if pid is None:
        pid = int((directory / "uv_shell.pid").read_text().strip())
    identity = proc_identity(pid)
    record = {"pid": pid, "start": identity["start"], "worker": "runtime"}
    if not verify_identity(record, directory, token):
        raise RuntimeError("runtime guard PID/UID/cwd/token mismatch")
    if action == "stop":
        with session_lock(directory):
            return require_runtime_stop_permit(directory, token, consume=True)
    if action == "stop-check":
        return require_runtime_stop_permit(directory, token)
    if (directory / "runtime.result.json").exists():
        raise RuntimeError("runtime owner worker stopped; session preserved")
    return require_session_safe(directory, token)


def graceful_runtime_stop(directory, token):
    directory = owned(directory, token)
    script = directory.parent / "runtime_session.sh"
    owned(directory.parent, token)
    spec = json.loads((directory / "runtime.spec.json").read_text())
    if script.is_symlink() or digest(script) != spec["env"].get("UVHS_SESSION_SCRIPT_SHA256"):
        raise RuntimeError("runtime shutdown script identity mismatch")
    pidfile = directory / "uv_shell.pid"
    def already_exited():
        records = json.loads((directory / "runtime.children.json").read_text())
        for record in records:
            try:
                if verify_identity(record, directory, token):
                    raise RuntimeError("runtime PID unavailable/exited but a live child remains; session preserved")
            except (FileNotFoundError, ProcessLookupError):
                continue
        return {"state": "already exited"}
    if not pidfile.exists():
        return already_exited()
    pid = int(pidfile.read_text().strip())
    records = json.loads((directory / "runtime.children.json").read_text())
    record = next((r for r in records if r["pid"] == pid), None)
    if record is None:
        raise RuntimeError("runtime PID has no owned identity")
    try:
        current = proc_identity(pid)
    except (FileNotFoundError, ProcessLookupError):
        return already_exited()
    if current["state"] == "Z" and current["start"] == record["start"]:
        return already_exited()
    if not verify_identity(record, directory, token):
        raise RuntimeError("runtime PID/starttime/UID/cwd/token mismatch")
    ready = directory / "uv_shell.ready"
    if not ready.is_file() or int(ready.read_text().strip()) != pid:
        raise RuntimeError("runtime not ready; no forced shutdown")
    permit = require_runtime_stop_permit(directory, token)
    if (permit["pid"], permit["start"]) != (pid, record["start"]):
        raise RuntimeError("runtime stop permit identity mismatch")
    with (directory / "runtime-stop.log").open("ab") as log:
        commands = (["bash", str(script), "enqueue", str(directory / "command.tcl"), "30", "stop"],
                    ["bash", str(script), "wait", str(pidfile), str(ready), str(directory / "command.tcl"), "30"])
        for command in commands:
            if command[2] == "enqueue" and not verify_identity(record, directory, token):
                raise RuntimeError("runtime identity changed before normal stop")
            stop_env = dict(os.environ, **spec["env"], GBUS_OWNER_TOKEN=token, GBUS_WORKER_NAME="runtime")
            done = subprocess.run(command, cwd=directory, env=stop_env, stdout=log, stderr=log, timeout=35)
            if done.returncode:
                raise RuntimeError("normal runtime " + command[2] + " failed; session preserved")
    return {"state": "gracefully stopped", "pid": pid}


def sample(path, cap=SAMPLE_CAP):
    path = Path(path)
    if path.is_symlink():
        raise RuntimeError("refusing symlink log")
    with path.open("rb") as stream:
        size = os.fstat(stream.fileno()).st_size
        first = stream.read(cap // 2)
        if size > cap:
            stream.seek(-cap // 2, 2)
            first += b"\n[... bounded sample ...]\n" + stream.read(cap // 2)
        else:
            first += stream.read(cap - len(first))
    return {"size": size, "sample_b64": base64.b64encode(first).decode()}


def init_owned(path, token, series, helper):
    path = Path(path)
    if not path.is_absolute() or path.resolve() != path or not path.parent.is_dir():
        raise RuntimeError("new directory needs a canonical existing parent")
    path.mkdir(mode=0o700)  # Never reuse a donor, old run, or shared directory.
    atomic(path / ".gbus-owner.json", json.dumps({"owner": OWNER, "token": token,
           "path": str(path), "series": series, "created_ns": time.time_ns(), "uid": os.getuid()}))
    (path / "gbus_supervisor.py").write_text(helper)
    return str(path)


def retention_guard(series, base=Path("/home/data/test")):
    prefix = "runtime_stage_" + series + "_"
    versions = []
    for path in base.iterdir():
        if not path.name.startswith(prefix):
            continue
        if path.is_symlink() or not path.is_dir() or path.resolve() != path:
            raise RuntimeError("uncertain runtime retention candidate; no upload: " + str(path))
        try:
            meta = json.loads((path / ".gbus-owner.json").read_text())
            if (meta.get("owner") != OWNER or meta.get("series") != series or
                    meta.get("path") != str(path) or path.stat().st_uid != os.getuid()):
                raise RuntimeError("uncertain runtime project ownership")
        except Exception as exc:
            raise RuntimeError("runtime retention cannot certify candidate; no upload: " + str(path)) from exc
        versions.append(str(path))
    if len(versions) >= 3:
        raise RuntimeError("runtime retention limit reached; certify and clean older uploads before staging: " +
                           json.dumps(sorted(versions)))
    return {"existing_versions": sorted(versions), "upload_allowed": True}


def authorize_host_launch(directory, token, host_directory, command):
    require_live_transport_contract()
    directory = owned(directory, token)
    with session_lock(directory):
        status = remote({"action": "status", "directory": str(directory), "token": token, "name": "runtime"})
        if status["result"] is not None or status["rc"] is not None:
            raise RuntimeError("runtime owner worker exited; no host launch")
        spec = json.loads((directory / "runtime.spec.json").read_text())
        if host_directory != spec.get("host_directory"):
            raise RuntimeError("host/runtime binding mismatch")
        if any((directory / name).exists() for name in ("runtime-stop-permit.json", "runtime-stop-consumed.json", "host-launch-permit.json")):
            raise RuntimeError("session already issued a host/stop permit; no repeated host launch")
        health = require_session_safe(directory, token)
        record = runtime_identity(directory, token)
        permit = {"token": token, "host_directory": host_directory, "runtime_directory": str(directory),
                  "pid": record["pid"], "start": record["start"], "boot_id": health["transport"]["boot_id"],
                  "command": command, "state": "owned_runtime_healthy", "id": uuid.uuid4().hex}
        atomic(directory / "host-launch-permit.json", json.dumps(permit))
        return permit


def require_host_launch_permit(directory, token, command, permit):
    require_live_transport_contract()
    if (not isinstance(permit, dict) or permit.get("token") != token
            or permit.get("host_directory") != str(directory) or permit.get("command") != command
            or permit.get("state") != "owned_runtime_healthy" or not permit.get("boot_id")
            or not permit.get("runtime_directory") or not permit.get("pid") or not permit.get("start")
            or not re.fullmatch(r"[0-9a-f]{32}", permit.get("id", ""))):
        raise RuntimeError("mandatory owned runtime health/readiness permit missing; no host launch")
    if (directory / "host-closed.json").exists():
        raise RuntimeError("host session sealed; no further host launch")


def launch(directory, token, name, command, env=None, timeout=1800, authorization=None, host_directory=None):
    directory = owned(directory, token)
    if not re.fullmatch(r"[a-z][a-z0-9_-]*", name):
        raise RuntimeError("invalid worker name")
    with session_lock(directory):
        if name == "host":
            require_host_launch_permit(directory, token, command, authorization)
        if name == "runtime":
            require_live_transport_contract()
            if not host_directory:
                raise RuntimeError("runtime requires an explicit host binding")
            require_session_safe(directory, token)
        spec = directory / (name + ".spec.json")
        with spec.open("x") as stream:
            json.dump({"directory": str(directory), "token": token, "name": name,
                       "command": command, "env": env or {}, "timeout": timeout,
                       "authorization": authorization, "host_directory": host_directory,
                       "launch_deadline": time.monotonic() + 30}, stream)
        # All three inherited descriptors are closed. SSH returns immediately.
        with open(os.devnull, "rb") as stdin, open(directory / (name + ".wrapper.log"), "xb") as log:
            worker_process = subprocess.Popen([sys.executable, str(directory / "gbus_supervisor.py"), "worker", str(spec)],
                             cwd=str(directory), stdin=stdin, stdout=log, stderr=log,
                             start_new_session=True, close_fds=True,
                             env=dict(os.environ, GBUS_OWNER_TOKEN=token, GBUS_WORKER_NAME=name))
    # Reap in local tests; daemon threads never delay the remote RPC exit.
    threading.Thread(target=worker_process.wait, daemon=True).start()
    return {"launched": name}


def worker(spec_file):
    spec = json.loads(Path(spec_file).read_text())
    directory = owned(spec["directory"], spec["token"])
    token, name = spec["token"], spec["name"]
    # Do not impose RLIMIT_FSIZE: vendor logs rotate at sizes larger than our
    # collection budget, and SIGXFSZ would kill an otherwise healthy process.
    # Keep full remote stdout/vendor logs; collect only bounded samples. A
    # separate free-space guard reports disk_guard, never a fake application rc.
    disk_floor = 2 * 1024 * 1024 * 1024
    disk_initial = shutil.disk_usage(str(directory)).free
    disk_last = disk_initial
    next_disk_check = 0.0
    records = {}
    reason, child_rc, rc = "error", None, 125
    stopping = [False]
    signal.signal(signal.SIGTERM, lambda *_: stopping.__setitem__(0, True))
    signal.signal(signal.SIGINT, lambda *_: stopping.__setitem__(0, True))
    self_id = proc_identity(os.getpid())
    atomic(directory / (name + ".identity.json"), json.dumps({"pid": os.getpid(), "start": self_id["start"], "worker": name}))
    try:
        env = dict(os.environ, **spec["env"], GBUS_OWNER_TOKEN=token, GBUS_WORKER_NAME=name)
        # Do not inherit arbitrary transport/DDR/debug settings from an SSH shell.
        for key in list(env):
            if key.startswith(("GBUS_", "UVHS_", "FPGA_")) and key not in spec["env"] and key not in ("GBUS_OWNER_TOKEN", "GBUS_WORKER_NAME"):
                del env[key]
        # A UART PTY must reach the host when the spec asks for it (the loop
        # above already drops any FPGA_* value the shell merely exported), but
        # stale make state from the calling environment must never leak.
        if "FPGA_UART_PORT" not in spec["env"]:
            env.pop("FPGA_UART_PORT", None)
        for key in ("MAKEFLAGS", "MFLAGS", "MAKEOVERRIDES"):
            env.pop(key, None)
        with open(directory / (name + ".log"), "xb") as log:
            with session_lock(directory):
                if name == "host":
                    require_host_launch_permit(directory, token, spec["command"], spec.get("authorization"))
                    if time.monotonic() > spec["launch_deadline"]:
                        raise RuntimeError("host launch lease expired; no host I/O")
                if name == "runtime":
                    require_live_transport_contract()
                    require_session_safe(directory, token)
                child = subprocess.Popen(spec["command"], cwd=str(directory), env=env,
                                         stdin=subprocess.DEVNULL, stdout=log, stderr=log, close_fds=True)
            deadline = None if spec["timeout"] is None else time.monotonic() + spec["timeout"]
            while True:
                # Track descendants while alive; detached runtime children retain
                # the token and cwd even after runtime_session start returns.
                for p in Path("/proc").iterdir():
                    if not p.name.isdigit() or int(p.name) == os.getpid():
                        continue
                    try:
                        ident = proc_identity(int(p.name))
                        if (("GBUS_OWNER_TOKEN=" + token).encode() in ident["env"]
                                and ("GBUS_WORKER_NAME=" + name).encode() in ident["env"]
                                and (Path(ident["cwd"]) == directory or directory in Path(ident["cwd"]).parents)):
                            records[int(p.name)] = {"pid": int(p.name), "start": ident["start"], "worker": name}
                    except (FileNotFoundError, ProcessLookupError, PermissionError):
                        continue
                atomic(directory / (name + ".children.json"), json.dumps(list(records.values())))
                polled = child.poll()
                if time.monotonic() >= next_disk_check:
                    disk_last = shutil.disk_usage(str(directory)).free
                    next_disk_check = time.monotonic() + 5
                    if disk_last < disk_floor:
                        reason, rc = "disk_guard", 125
                        break
                if stopping[0]:
                    reason, rc = "cancelled", 143
                    break
                if deadline is not None and time.monotonic() >= deadline:
                    reason, rc = "timeout", 124
                    break
                if polled is not None:
                    child_rc = polled if polled >= 0 else 128 - polled
                    # Runtime start returns once ready; retain an owner worker
                    # until explicit cleanup, rather than abandoning the shell.
                    if name != "runtime" or child_rc != 0:
                        reason, rc = "exited", child_rc
                        break
                time.sleep(0.1)
    finally:
        errors = []
        if name == "runtime":
            try:
                graceful_runtime_stop(directory, token)
            except Exception as exc:
                errors.append(str(exc))
        else:
            for sig in (signal.SIGTERM, signal.SIGKILL):
                for record in records.values():
                    try:
                        current = proc_identity(record["pid"])
                        if current["state"] != "Z":
                            safe_signal(record, directory, token, sig)
                    except (FileNotFoundError, ProcessLookupError):
                        pass
                    except Exception as exc:
                        errors.append(str(exc))
                if sig == signal.SIGTERM and records:
                    time.sleep(1)
        if "child" in locals():
            try:
                raw = child.wait(timeout=2)
                child_rc = raw if raw >= 0 else 128 - raw
            except subprocess.TimeoutExpired:
                errors.append("child still alive")
        result = {"reason": reason, "rc": rc, "child_rc": child_rc, "cleanup_errors": errors,
                  "disk_guard": {"minimum_free_bytes": disk_floor, "initial_free_bytes": disk_initial,
                                 "last_free_bytes": disk_last},
                  "logging": "full remote logs; bounded local collection; no imposed file-size limit"}
        atomic(directory / (name + ".result.json"), json.dumps(result))
        atomic(directory / (name + ".rc"), str(rc) + "\n")
    return rc


def remote(req):
    action = req["action"]
    if action == "board":
        return {"board": board_state(), "transport": transport_health()}
    if action == "health":
        directory = owned(req["directory"], req["token"])
        return {"board": board_state(directory=directory, token=req["token"]),
                "transport": session_transport_health(directory, req["token"])}
    if action == "init":
        return init_owned(req["directory"], req["token"], req["series"], req["helper"])
    if action == "retention_guard":
        return retention_guard(req["series"])
    if action == "retention":
        # Legacy dirs have no trustworthy ownership/version/live-use evidence.
        # Audit only: no deletion is authorized by a name prefix or lsof failure.
        base = Path("/home/data/test")
        rows = []
        for p in base.iterdir():
            if p.name.startswith(req["prefix"]):
                rows.append({"target": str(p), "realpath": str(p.resolve()),
                             "decision": "SKIP: ownership/order/live cwd and open files not certified"})
        return {"removed": [], "reclaimed_bytes": 0, "skipped": rows}
    directory = owned(req["directory"], req["token"])
    if action == "prepare_inputs":
        for name in ("workload", "ref"):
            (directory / name).mkdir(exist_ok=False)
        return {"prepared": True}
    if action == "inputs":
        result = {}
        for rel, expected in (("workload/hello.bin", req["workload_sha"]), ("ref/reference.so", req["reference_sha"])):
            dest = directory / rel
            if dest.is_symlink() or digest(dest) != expected:
                raise RuntimeError("uploaded input hash mismatch: " + str(dest))
            result[rel] = expected
        return result
    if action == "prepare_generated":
        (directory / "difftest-src/build/generated-src").mkdir(parents=True, exist_ok=False)
        return {"prepared": True}
    if action == "generated":
        actual = manifest(directory / "difftest-src/build/generated-src")
        if actual != req["manifest"]:
            raise RuntimeError("release generated-src mismatch after transfer")
        return actual
    if action == "runtime_package":
        actual = manifest(directory / "hw.dat")
        if actual != req["manifest"]:
            raise RuntimeError("runtime package mismatch after transfer")
        return actual
    if action == "runtime_ready":
        status = remote(dict(req, action="status", name="runtime"))
        if not status["ready"] or status["result"] is not None or status["rc"] is not None:
            raise RuntimeError("runtime worker exited or has no ready marker")
        record = runtime_identity(directory, req["token"])
        require_session_safe(directory, req["token"])
        return {"ready": True, "pid": record["pid"], "start": record["start"]}
    if action == "host_launch_permit":
        return authorize_host_launch(directory, req["token"], req["host_directory"], req["command"])
    if action == "host_quiescent":
        return host_quiescent(directory, req["token"])
    if action == "runtime_stop_permit":
        return authorize_runtime_stop(directory, req["token"], req["host_proof"])
    if action == "launch":
        return launch(str(directory), req["token"], req["name"], req["command"], req.get("env"), req["timeout"],
                      req.get("authorization"), req.get("host_directory"))
    if action == "stop":
        name = req["name"]
        if (directory / (name + ".result.json")).exists():
            return {"state": "finished"}
        if name == "runtime":
            require_runtime_stop_permit(directory, req["token"])
        identity = directory / (name + ".identity.json")
        if not identity.exists():
            raise RuntimeError("worker identity unavailable; no fallback kill")
        return {"state": safe_signal(json.loads(identity.read_text()), directory, req["token"])}
    if action == "status":
        name = req["name"]
        result = directory / (name + ".result.json")
        rcfile = directory / (name + ".rc")
        return {"result": json.loads(result.read_text()) if result.exists() else None,
                "rc": int(rcfile.read_text()) if rcfile.exists() else None,
                "ready": (directory / "uv_shell.ready").exists()}
    if action == "proof":
        binary = directory / "difftest-src/build/fpga-host"
        if not binary.is_file() or not os.access(str(binary), os.X_OK) or binary.read_bytes()[:4] != b"\x7fELF":
            raise RuntimeError("fresh executable ELF binary missing")
        linked = subprocess.run(["ldd", str(binary)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if linked.returncode or b"not found" in linked.stdout:
            raise RuntimeError("binary dependency proof failed: " + linked.stdout.decode(errors="replace"))
        proof = {"sha256": digest(binary), "size": binary.stat().st_size,
                 "ldd": linked.stdout.decode(errors="replace")}
        atomic(directory / "binary-proof.json", json.dumps(proof))
        return proof
    if action == "logs":
        # Fixed top-level allowlist: no wildcard rsync, recursive vendor dump,
        # old donor logs, memory dumps, or prior-attempt files.
        files = ["build.log", "build.result.json", "build.rc", "binary-proof.json",
                 "runtime.log", "runtime.result.json", "runtime.rc", "uv_shell.log",
                 "uart.log", "uart.result.json", "uart.rc", "host.log", "host.result.json", "host.rc"]
        return {name: sample(directory / name) for name in files if (directory / name).is_file()}
    if action == "verdict":
        status = remote(dict(req, action="status", name="host"))
        log = directory / "host.log"
        text = log.read_text(errors="replace") if log.exists() else ""
        return verdict(status, text, req["mode"])
    if action == "diagnostics":
        result = {}
        for name, command in (("dmesg", ["dmesg"]), ("pcie", ["lspci", "-s", "01:00.0"])):
            try:
                done = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=15)
                result[name] = {"rc": done.returncode, "stdout": done.stdout[-SAMPLE_CAP:].decode(errors="replace"),
                                "stderr": done.stderr[-SAMPLE_CAP:].decode(errors="replace")}
            except Exception as exc:
                result[name] = {"rc": 125, "error": str(exc)}
        return result
    raise RuntimeError("unknown remote action " + action)


def verdict(status, text, mode):
    result, rc = status.get("result"), status.get("rc")
    if result is None or rc is None:
        return {"verdict": "pending", "rc": rc}
    if result.get("reason") == "timeout" or rc == 124:
        return {"verdict": "timeout", "rc": rc}
    text = re.sub(r"\x1b\[[0-9;]*m", "", text)
    evidence = (mode in ("config-window", "axi-dma") and "HIT GOOD TRAP" in text
                and not re.search(r"HIT BAD TRAP|ABORT at|FAILED at|EXCEEDING INSTR LIMIT|DMA/config mirror mismatch", text)
                and "GBus C2H interface layer=sram-window mode=" + mode in text
                and re.search(r"GBus DMA workload queued [1-9][0-9]* bytes", text)
                and re.search(r"GBD1 progress mode=" + re.escape(mode) + r" banks=[1-9][0-9]* bytes=[1-9][0-9]* seq=[0-9]+", text)
                and "Difftest PerfCnt" in text and re.search(r"Run time: [0-9]+ s [0-9]+ ms", text)
                and re.search(r"Simulation speed: [0-9.]+ (?:KHz|MHz), [0-9.]+ (?:KIPS|MIPS)", text)
                and re.search(r"instrCnt = [1-9][0-9,]*, cycleCnt = [1-9][0-9,]*", text))
    if mode == "axi-dma":
        evidence = (evidence and re.search(r"GBD1 AXI verified addr=0x0ffff[0-9a-f]{3} len=[0-9]+ count=[1-9][0-9]* bytes=[1-9][0-9]*", text)
                    and re.search(r"GBD1 first frozen bank DMA/config mirror verified seq=[0-9]+ bytes=[1-9][0-9]*", text))
    good = (rc == 0 and result.get("rc") == 0 and result.get("child_rc") == 0
            and result.get("reason") == "exited" and not result.get("cleanup_errors") and evidence)
    return {"verdict": "good_trap" if good else "failed_or_unproven", "rc": rc, "mode": mode}


class Remote:
    def __init__(self, host, key=None):
        self.host = host
        self.ssh = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15",
                    "-o", "ServerAliveInterval=15", "-o", "ServerAliveCountMax=2"]
        if key:
            self.ssh += ["-i", str(key), "-o", "IdentitiesOnly=yes"]

    def call(self, action, **kwargs):
        request = dict(kwargs, action=action)
        payload = base64.b64encode(json.dumps(request).encode()).decode()
        command = shlex.join(["python3", "-", "rpc", payload])
        done = subprocess.run(self.ssh + [self.host, command], input=Path(__file__).read_bytes(),
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90)
        if done.returncode:
            raise RuntimeError("SSH/RPC {} rc={}: {}".format(action, done.returncode, done.stderr.decode(errors="replace")))
        try:
            return json.loads(done.stdout)
        except ValueError as exc:
            raise RuntimeError("invalid SSH/RPC response: " + done.stdout.decode(errors="replace")) from exc

    def sync(self, source, dest, excludes=()):
        command = ["rsync", "-a", "--safe-links", "-e", shlex.join(self.ssh)]
        command += ["--exclude=" + pattern for pattern in excludes]
        command += [str(source), self.host + ":" + dest]
        subprocess.run(command, check=True, timeout=1800)


class Supervisor:
    def __init__(self, env=None):
        self.env = dict(os.environ if env is None else env)
        self.root = Path(__file__).resolve().parents[3]
        if not self.env.get("GBUS_TEST_MANIFEST"):
            raise RuntimeError("GBUS_TEST_MANIFEST is required")
        self.inputs = test_inputs(self.env["GBUS_TEST_MANIFEST"])
        self.mode = self.inputs["c2h_mode"]
        runtime_key = Path(self.env.get("RUNTIME_KEY", str(Path.home() / ".ssh/id_rsa")))
        self.tag = self.env.get("TAG", "gbus")
        if not re.fullmatch(r"[A-Za-z0-9_-]+", self.tag):
            raise RuntimeError("TAG must contain only letters, digits, underscores and hyphens")
        self.token = uuid.uuid4().hex
        self.run_id = self.tag + "_" + time.strftime("%Y%m%dT%H%M%S", time.gmtime()) + "_" + self.token[:12]
        self.out = Path(self.env.get("OUT_DIR", str(self.root / "build_logs/uvhs_runs"))) / self.run_id
        self.out.mkdir(parents=True, exist_ok=False)
        key = Path(self.env.get("FPGA_HOST_KEY", str(self.root / "id_ed25519")))
        if not key.is_file():
            raise RuntimeError("FPGA host SSH key is missing")
        if not runtime_key.is_file():
            raise RuntimeError("runtime id_rsa SSH key is missing")
        self.fpga = Remote(self.env.get("FPGA_HOST", "fengkehan@172.38.11.131"), key)
        self.rt = Remote(self.env.get("RUNTIME_HOST", "root@172.38.11.85"), runtime_key)
        parent = self.env.get("FPGA_HOST_PARENT", "")
        if not re.fullmatch(r"/[A-Za-z0-9_./-]+", parent) or Path(parent).is_absolute() is False or str(Path(parent)) != parent or ".." in Path(parent).parts:
            raise RuntimeError("canonical FPGA_HOST_PARENT is required")
        self.host_dir = str(Path(parent) / ("minjie_gbus_host_" + self.run_id))
        self.series = self.env.get("LOGICAL_PROJECT", "minjie_" + self.inputs["cpu"] + "_gbus")
        if not re.fullmatch(r"[A-Za-z0-9_-]+", self.series):
            raise RuntimeError("invalid logical project")
        self.stage = "/home/data/test/runtime_stage_" + self.series + "_" + self.run_id
        self.owned_dirs = []
        self.workers = []
        self.result = {"verdict": "not_started", "run_id": self.run_id, "host_dir": self.host_dir, "stage": self.stage}
        self.save("test-inputs.json", self.inputs)
        self.log("output=" + str(self.out))

    def log(self, message):
        line = time.strftime("[%F %T] ") + message
        print(line, flush=True)
        with (self.out / "supervisor.log").open("a") as stream:
            stream.write(line + "\n")

    def save(self, name, value):
        atomic(self.out / name, json.dumps(value, indent=2) + "\n")

    def rpc(self, host, directory, action, **kwargs):
        return host.call(action, directory=directory, token=self.token, **kwargs)

    def init(self, host, directory):
        self.rpc(host, directory, "init", series=self.series, helper=Path(__file__).read_text())
        self.owned_dirs.append((host, directory))

    def start(self, host, directory, name, command, env=None, timeout=1800, authorization=None):
        # Register before SSH: loss of the launch acknowledgement still cleans up.
        self.workers.append((host, directory, name))
        binding = self.host_dir if name == "runtime" else None
        self.rpc(host, directory, "launch", name=name, command=command, env=env or {}, timeout=timeout,
                 authorization=authorization, host_directory=binding)

    def wait_worker(self, host, directory, name, timeout):
        deadline = None if timeout is None else time.monotonic() + timeout
        while deadline is None or time.monotonic() <= deadline:
            state = self.rpc(host, directory, "status", name=name)
            if state["result"] is not None and state["rc"] is not None:
                return state
            time.sleep(1)
        raise RuntimeError(name + " wrapper did not publish an atomic rc")

    def release(self, project=None):
        release = self.inputs["release_dir"]
        if self.env.get("RELEASE_DIR") and str(Path(self.env["RELEASE_DIR"]).resolve()) != release:
            raise RuntimeError("RELEASE_DIR does not match manifest")
        if project is not None:
            text = (project / "rtl/filelist.f").read_text()
            defines = set(re.findall(r"^\+define\+([A-Za-z0-9_]+)(?:\s|$|=)", text, re.M))
            wrappers = set(re.findall(r"^/[^\n]+/src/rtl/(nutshell|kmh|nanhu)/SimTop_wrapper\.sv\s*$", text, re.M))
            if wrappers != {self.inputs["cpu"]} or (("CPU_NUTSHELL" in defines) != (self.inputs["cpu"] == "nutshell")):
                raise RuntimeError("project CPU does not match manifest")
            if defines.intersection({"DIFFTEST_HOST_GBUS", "DIFFTEST_HOST_XDMA"}) != {"DIFFTEST_HOST_GBUS"}:
                raise RuntimeError("project must use the GBus host interface")
            if self.mode == "axi-dma" and "UVHS_GBUS_C2H_DMA" not in defines:
                raise RuntimeError("axi-dma manifest requires a DMA-enabled project")
            candidates = set(re.findall(r"(?:\+incdir\+)(/[^\s]+/build/generated-src)(?:\s|$)", text))
            candidates = {str(Path(p).resolve().parent.parent) for p in candidates}
            if len(candidates) != 1:
                raise RuntimeError("project filelist must identify exactly one release generated-src")
            linked = candidates.pop()
            if release and str(Path(release).resolve()) != linked:
                raise RuntimeError("RELEASE_DIR does not match project RTL filelist")
            release = linked
        if not release:
            raise RuntimeError("RELEASE_DIR is required; current difftest/build is not an ABI source")
        path = Path(release).resolve(strict=True) / "build/generated-src"
        if not (path / "difftest-state.h").is_file():
            raise RuntimeError("release generated difftest-state.h missing")
        self.generated = path
        self.generated_manifest = manifest(path)
        self.save("release-inputs.json", {"release": str(path.parent.parent), "generated": self.generated_manifest})

    def build(self):
        build_env = {key: self.env[key] for key in ("GBUS_LIBUVGBUS", "GBUS_RUNTIME_ROOT") if self.env.get(key)}
        if not build_env:
            raise RuntimeError("explicit FPGA-host GBUS_LIBUVGBUS or GBUS_RUNTIME_ROOT is required")
        self.log("phase=host_build isolated_dir=" + self.host_dir)
        self.init(self.fpga, self.host_dir)
        self.rpc(self.fpga, self.host_dir, "prepare_inputs")
        self.fpga.sync(self.inputs["workload"]["path"], self.host_dir + "/workload/hello.bin")
        self.fpga.sync(self.inputs["reference"]["path"], self.host_dir + "/ref/reference.so")
        inputs = self.rpc(self.fpga, self.host_dir, "inputs", workload_sha=self.inputs["workload"]["sha256"],
                          reference_sha=self.inputs["reference"]["sha256"])
        self.save("input-hashes.json", inputs)
        source = Path(self.env.get("DIFFTEST_SRC", str(self.root / "difftest"))).resolve(strict=True)
        self.fpga.sync(str(source) + "/", self.host_dir + "/difftest-src/",
                       SOURCE_EXCLUDES)
        self.rpc(self.fpga, self.host_dir, "prepare_generated")
        self.fpga.sync(str(self.generated) + "/", self.host_dir + "/difftest-src/build/generated-src/")
        self.rpc(self.fpga, self.host_dir, "generated", manifest=self.generated_manifest)
        # Bash preserves make's status through tee. Fresh directory means no
        # stale binary can satisfy proof. No interactive shell startup is sourced.
        script = ('set -euo pipefail; cd difftest-src; '
                  'test ! -e build/fpga-host; '
                  'make -j4 fpga-host FPGA=1 RELEASE=1 CPU=' + self.inputs["cpu"] + ' UVHS=1 USE_XDMA_H2C=1 '
                  'DIFFTEST_HOSTIF=GBUS USE_SERIAL_PORT=0 DIFFTEST_PERFCNT=1 '
                  'NOOP_HOME="$PWD" DESIGN_DIR="$PWD" 2>&1 | tee ../make.log')
        self.start(self.fpga, self.host_dir, "build", ["bash", "-c", script], env=build_env, timeout=3600)
        status = self.wait_worker(self.fpga, self.host_dir, "build", 3630)
        self.save("build-status.json", status)
        if status["rc"] != 0 or status["result"]["child_rc"] != 0 or status["result"]["cleanup_errors"]:
            raise RuntimeError("host build failed; no runtime upload or launch permitted")
        proof = self.rpc(self.fpga, self.host_dir, "proof")
        self.save("binary-proof.json", proof)
        self.log("phase=host_build OK sha256=" + proof["sha256"])

    def wait_board(self):
        deadline = time.monotonic() + int(self.env.get("WAIT_BOARD_TIMEOUT", "0"))
        while True:
            try:
                state = self.rt.call("board")
            except Exception as exc:
                state = {"state": "unknown", "error": str(exc)}
            self.log("board=" + json.dumps(state))
            health = state.get("transport", {})
            if health.get("state") != "healthy":
                raise RuntimeError("transport unhealthy/unknown; no programming or DMA: " + json.dumps(health))
            if state.get("board", {}).get("state") == "free":
                return
            if time.monotonic() >= deadline:
                raise RuntimeError("board busy/unknown; no runtime launch")
            time.sleep(int(self.env.get("BOARD_POLL_SEC", "120")))

    def stop(self, host, directory, name):
        # No process name search, PID-only kill, process-group kill or fallback.
        if name == "runtime":
            state = self.rpc(host, directory, "status", name=name)
            if state["result"] is None:
                proof = self.rpc(self.fpga, self.host_dir, "host_quiescent")
                self.save("host-quiescent.json", proof)
                self.rpc(host, directory, "runtime_stop_permit", host_proof=proof)
        answer = self.rpc(host, directory, "stop", name=name)
        self.log("cleanup " + directory + "/" + name + " " + json.dumps(answer))
        status = self.wait_worker(host, directory, name, 15)
        if status["result"]["cleanup_errors"]:
            raise RuntimeError("cleanup refused: " + json.dumps(status))
        return status

    def runtime(self):
        require_live_transport_contract()
        self.revalidate_runtime_package()
        self.wait_board()
        guard = self.rt.call("retention_guard", series=self.series)
        self.save("pre-upload-retention.json", guard)
        self.revalidate_runtime_package()
        self.init(self.rt, self.stage)
        self.rt.sync(str(self.runtime_package), self.stage + "/hw.dat")
        self.rpc(self.rt, self.stage, "runtime_package", manifest=self.inputs["runtime_files"])
        runtime = Path(__file__).resolve().parents[1] / "uvhs/runtime"
        for name in ("runtime_server.tcl", "runtime_session.sh", "uv_shell_exec_compat.sh"):
            self.rt.sync(runtime / name, self.stage + "/")
        uv = self.env.get("UV_ROOT_ON_RUNTIME", "/home/data/UVHS/2506p4_0210")
        ready_timeout = int(self.env.get("RUNTIME_READY_TIMEOUT", "900"))
        attempts = int(self.env.get("RUNTIME_ATTEMPTS", "3"))
        if ready_timeout <= 0 or attempts <= 0:
            raise RuntimeError("runtime readiness timeout and attempts must be positive")
        for attempt in range(1, attempts + 1):
            self.wait_board()
            directory = self.stage + "/attempt-" + str(attempt)
            self.init(self.rt, directory)
            self.attempt = directory
            compat = self.stage + "/uv_shell_exec_compat.sh"
            env = {"UV_ROOT": uv, "UVHS_DB_PATH": self.stage + "/hw.dat",
                   "UVHS_RUNTIME_WORK_DIR": directory, "UVHS_COMMAND_FILE": directory + "/command.tcl",
                   "UVHS_RUNTIME_READY_FILE": directory + "/uv_shell.ready",
                   "UVHS_RUNTIME_LIB_DIR": directory + "/.uvhs-runtime-lib",
                   "UVHS_COMPAT_BIN": directory + "/.uvhs-compat-bin",
                   "UVSHELL_EXEC_NAME": compat,
                   "UVHS_SESSION_SCRIPT_SHA256": digest(runtime / "runtime_session.sh"),
                   "UVHS_RUNTIME_SAFETY_HELPER": directory + "/gbus_supervisor.py",
                   "UVHS_RUNTIME_PYTHON": uv + "/lib/venv3.8/bin/python3",
                   "UVHS_SUPERVISOR_SHA256": digest(Path(__file__)),
                   "UVHS_RUNTIME_PRESERVE_ON_TIMEOUT": "1",
                   "PATH": uv + "/bin:" + uv + "/lib/venv3.8/bin:" + uv + "/lib/gcc10.3/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"}
            # runtime_session/server gate programming and retain a faulted session.
            # The readiness waiter never signals a session on its own timeout.
            args = ["bash", self.stage + "/runtime_session.sh", "start", directory + "/uv_shell.pid",
                    directory + "/uv_shell.ready", directory + "/uv_shell.log", directory + "/command.tcl",
                    str(ready_timeout + 120), "bash", uv + "/bin/uv_shell", "-rt_shell", "-workdir", directory,
                    "-script", self.stage + "/runtime_server.tcl"]
            setup = ('set -euo pipefail; mkdir .uvhs-compat-bin .uvhs-runtime-lib; '
                     'ln -s ' + shlex.quote(compat) + ' .uvhs-compat-bin/python; '
                     'ln -s ' + shlex.quote(compat) + ' .uvhs-compat-bin/python3; exec ' + shlex.join(args))
            self.start(self.rt, directory, "runtime", ["bash", "-c", setup], env,
                       ready_timeout + int(self.env.get("RUN_TIMEOUT", "1800")) + 600)
            deadline = time.monotonic() + ready_timeout
            while time.monotonic() <= deadline:
                state = self.rpc(self.rt, directory, "status", name="runtime")
                if state["result"] is not None or state["rc"] is not None:
                    break
                if state["ready"]:
                    self.require_session_health()
                    self.log("runtime ready attempt=" + str(attempt))
                    return
                time.sleep(1)
            self.stop(self.rt, directory, "runtime")
            logs = self.rpc(self.rt, directory, "logs")
            text = "\n".join(base64.b64decode(v["sample_b64"]).decode(errors="replace") for v in logs.values())
            self.collect_one(self.rt, directory)
            if not re.search(r"RTM-101|occupied by other users", text, re.I):
                raise RuntimeError("runtime failed/timeout (not an occupied-board retry)")
            self.log("occupied RTM-101; cleaned owned attempt, retrying with a new directory")
        raise RuntimeError("runtime occupied retry limit reached")

    def require_session_health(self):
        self.rpc(self.rt, self.attempt, "runtime_ready")
        state = self.rpc(self.rt, self.attempt, "health")
        self.save("session-health.json", state)
        if state.get("transport", {}).get("state") != "healthy" or state.get("board", {}).get("state") != "free":
            raise RuntimeError("transport unhealthy or foreign runtime active; no host DMA: " + json.dumps(state))

    def run_host(self):
        require_live_transport_contract()
        self.require_session_health()
        timeout = int(self.env.get("RUN_TIMEOUT", "1800"))
        device = self.env.get("UART_DEVICE", "/dev/ttyUSB0")
        if device != "/dev/ttyUSB0":
            raise RuntimeError("this experiment requires runtime /dev/ttyUSB0")
        self.start(self.rt, self.attempt, "uart", ["bash", "-c",
                   "set -euo pipefail; stty -F /dev/ttyUSB0 115200 raw -echo; exec cat /dev/ttyUSB0"], timeout=timeout + 60)
        env = {"UVHS_DISABLE_DOWNLOAD": "1",
               "GBUS_HOST": self.rt.host.split("@")[-1], "GBUS_FPGA": "2", "GBUS_DMA_FPGA": "2",
               "GBUS_CONFIG_BASE": "0x1000", "GBUS_DDR_BASE": "0", "GBUS_CONFIG_READBACK": "1",
               "GBUS_C2H_SRAM": "1", "GBUS_C2H_MODE": self.mode, "GBUS_C2H_VERIFY_FIRST_BANK": "1",
               "GBUS_C2H_DMA_CHUNK_BYTES": "256", "GBUS_PORT": "0",
               "GBUS_CHANNEL": "0", "GBUS_DDR_INSTANCE": "0"}
        command = [self.host_dir + "/difftest-src/build/fpga-host", "--ram-size=16MB", "--diff",
                   self.host_dir + "/ref/reference.so", "-i", self.host_dir + "/workload/hello.bin"]
        authorization = self.rpc(self.rt, self.attempt, "host_launch_permit",
                                 host_directory=self.host_dir, command=command)
        self.start(self.fpga, self.host_dir, "host", command, env, timeout, authorization=authorization)
        state = self.wait_worker(self.fpga, self.host_dir, "host", timeout + 30)
        self.save("host-status.json", state)
        self.result.update(self.rpc(self.fpga, self.host_dir, "verdict", mode=self.mode))
        self.log("verdict=" + json.dumps(self.result))
        if self.result["verdict"] != "good_trap":
            raise RuntimeError("no proven host rc0/mode/PerfCnt DiffTest GOOD TRAP")

    def collect_one(self, host, directory):
        logs = self.rpc(host, directory, "logs")
        dest = self.out / Path(directory).name
        dest.mkdir(exist_ok=True)
        for name, data in logs.items():
            (dest / name).write_bytes(base64.b64decode(data["sample_b64"]))
        atomic(dest / "sample-sizes.json", json.dumps({k: v["size"] for k, v in logs.items()}))

    def finish(self, rc):
        errors = []
        host_failed = False
        workers = list(reversed(self.workers))
        workers.sort(key=lambda item: item[2] == "runtime")
        for host, directory, name in workers:
            if name == "runtime" and host_failed:
                message = "host stop failed/unknown; runtime preserved: " + directory
                errors.append(message)
                self.log("cleanup BLOCKED " + message)
                continue
            try:
                self.stop(host, directory, name)
            except Exception as exc:
                if name == "host":
                    host_failed = True
                errors.append(str(exc))
                self.log("cleanup ERROR " + str(exc))
        for host, directory in self.owned_dirs:
            try:
                self.collect_one(host, directory)
            except Exception as exc:
                errors.append(str(exc))
                self.log("collection ERROR " + str(exc))
        for host, directory in ((self.fpga, self.host_dir), (self.rt, self.stage)):
            if (host, directory) in self.owned_dirs:
                try:
                    self.save("diagnostics-" + host.host.split("@")[-1] + ".json", self.rpc(host, directory, "diagnostics"))
                except Exception as exc:
                    errors.append(str(exc))
        if (self.rt, self.stage) in self.owned_dirs:
            try:
                health = self.rt.call("board")
                self.save("post-runtime-health.json", health)
                if health.get("transport", {}).get("state") != "healthy":
                    raise RuntimeError("post-run transport unhealthy/unknown")
                retention = self.rt.call("retention", prefix="runtime_stage_" + self.series + "_")
                self.save("retention-audit.json", retention)
                self.log("retention audit-only: removed=[] reclaimed_bytes=0; uncertain candidates skipped")
            except Exception as exc:
                errors.append(str(exc))
        self.result.update({"supervisor_rc": rc or (1 if errors else 0), "cleanup_collection_errors": errors})
        self.save("result.json", self.result)
        atomic(self.out / "supervisor.rc", str(self.result["supervisor_rc"]) + "\n")
        return self.result["supervisor_rc"]

    def lock_project(self, project):
        lock_dir = self.root / "build_logs/uvhs_runs/.locks"
        lock_dir.mkdir(parents=True, exist_ok=True)
        key = hashlib.sha256(str(project.resolve()).encode()).hexdigest()
        self.project_lock = (lock_dir / (key + ".lock")).open("a+")
        try:
            fcntl.flock(self.project_lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            self.project_lock.close()
            self.project_lock = None
            raise RuntimeError("another supervisor owns this project; no launch: " + str(project))
        self.project_lock.seek(0)
        self.project_lock.truncate()
        self.project_lock.write(json.dumps({"pid": os.getpid(), "project": str(project), "run_id": self.run_id}))
        self.project_lock.flush()

    def validate_runtime_package(self):
        load_local_tool("uvhs_build_artifacts").validate_build_logs(self.project)
        package = Path(self.inputs.get("runtime_package_dir", ""))
        if (not package.is_absolute() or package.is_symlink() or not package.is_dir()
                or package.resolve(strict=True) != package):
            raise RuntimeError("explicit canonical runtime_package_dir is required")
        actual = manifest(package)
        if actual != self.inputs.get("runtime_files"):
            raise RuntimeError("runtime package must match explicit manifest hashes")
        selected, _ = load_local_tool("uvhs_runtime_package").runtime_files(self.project / "hw.dat")
        expected = {name: digest(path) for name, path in selected.items()}
        if actual != expected:
            raise RuntimeError("runtime package does not match compiled project runtime inputs")
        for fpga in ("F0", "F1", "F2"):
            name = "Compile/PnR/B0/" + fpga + "/MOD_b0_" + fpga.lower() + ".bin"
            if name not in actual or not (package / name).stat().st_size:
                raise RuntimeError("required runtime FPGA missing: " + fpga)
        self.runtime_package = package

    def revalidate_runtime_package(self):
        if manifest(self.runtime_package) != self.inputs.get("runtime_files"):
            raise RuntimeError("runtime package changed before upload")

    def execute(self, mode):
        rc = 1
        try:
            if mode == "supervise":
                require_live_transport_contract()
                if not self.env.get("PRJ_DIR"):
                    raise RuntimeError("explicit PRJ_DIR is required")
                self.project = Path(self.env["PRJ_DIR"]).resolve(strict=True)
                self.lock_project(self.project)
                self.release(self.project)
                deadline = time.monotonic() + int(self.env.get("WAIT_BIT_TIMEOUT", "28800"))
                while True:
                    log = self.project / "backend_run.log"
                    text = log.read_text(errors="replace") if log.exists() else ""
                    if "Error: in running command" in text:
                        raise RuntimeError("backend failed")
                    if "UVHS_BACKEND_SUCCESS" in text.splitlines():
                        break
                    if time.monotonic() >= deadline:
                        raise RuntimeError("backend timeout")
                    time.sleep(30)
                self.validate_runtime_package()
            else:
                self.release()
            self.build()
            if mode == "supervise":
                self.runtime()
                self.run_host()
            else:
                self.result["verdict"] = "build_only"
            rc = 0
        except (Exception, KeyboardInterrupt) as exc:
            self.result["error"] = str(exc)
            self.log("FAIL " + str(exc))
        finally:
            try:
                return self.finish(rc)
            finally:
                lock = getattr(self, "project_lock", None)
                if lock is not None:
                    lock.close()
                    self.project_lock = None


def main():
    mode = sys.argv[1]
    if mode == "runtime-guard":
        try:
            directory, token, action = sys.argv[2:5]
            pid = int(sys.argv[5]) if len(sys.argv) == 6 else None
            print(json.dumps(runtime_guard(directory, token, action, pid)))
            return 0
        except Exception as exc:
            print(str(exc), file=sys.stderr)
            return 1
    if mode == "rpc":
        try:
            print(json.dumps(remote(json.loads(base64.b64decode(sys.argv[2])))))
            return 0
        except Exception as exc:
            print(str(exc), file=sys.stderr)
            return 1
    if mode == "worker":
        return worker(sys.argv[2])
    if "--status" in sys.argv[2:]:
        root = Path(__file__).resolve().parents[3]
        out = Path(os.environ.get("OUT_DIR", str(root / "build_logs/uvhs_runs")))
        for result in sorted(out.glob("*/result.json")):
            print(str(result) + " " + result.read_text())
        return 0
    gate = "BOARD_TEST_AUTHORIZE" if mode == "supervise" else "HOST_BUILD_AUTHORIZE"
    if os.environ.get(gate) != "YES":
        print("BLOCKED: set " + gate + "=YES only after review and explicit upload/board authorization", file=sys.stderr)
        return 64
    supervisor = Supervisor()
    signal.signal(signal.SIGTERM, lambda *_: (_ for _ in ()).throw(KeyboardInterrupt("SIGTERM")))
    return supervisor.execute(mode)


if __name__ == "__main__":
    sys.exit(main())
