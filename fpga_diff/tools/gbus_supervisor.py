#!/usr/bin/env python3
"""Fail-closed GBus orchestration and small, authenticated remote operations.

No hardware action is performed merely by importing this module. Remote workers
have an owned cwd, a unique environment token, and atomic status/rc records.
"""
import base64
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import shlex
import signal
import subprocess
import sys
import threading
import time
import uuid

OWNER = "minjie-gbus-supervisor-v2"
WORKLOAD_SHA = "2481e529d4290980f0af7061fa2c13e68efdffa1abb981907966960b9dd50458"
NEMU_SHA = "8bcd3ebd3d21bb26f386b4734ff0be28898873f2b35d901c9c6f4718279f46cb"
LOG_CAP = 8 * 1024 * 1024
SAMPLE_CAP = 128 * 1024


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
    directory = Path(directory).resolve(strict=True)
    result = {}
    for path in sorted(directory.rglob("*")):
        if path.is_symlink():
            raise RuntimeError("symlink in generated inputs: " + str(path))
        if path.is_file():
            result[str(path.relative_to(directory))] = digest(path)
    if not result:
        raise RuntimeError("empty generated inputs")
    return result


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


def board_state(proc=Path("/proc")):
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
                busy.append({"pid": int(entry.name), "args": args})
        except FileNotFoundError:
            continue
        except (PermissionError, OSError) as exc:
            return {"state": "unknown", "error": str(exc)}
    return {"state": "busy" if busy else "free", "processes": busy}


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


def launch(directory, token, name, command, env=None, timeout=1800):
    directory = owned(directory, token)
    if not re.fullmatch(r"[a-z][a-z0-9_-]*", name):
        raise RuntimeError("invalid worker name")
    spec = directory / (name + ".spec.json")
    with spec.open("x") as stream:
        json.dump({"directory": str(directory), "token": token, "name": name,
                   "command": command, "env": env or {}, "timeout": timeout}, stream)
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
        for key in ("FPGA_UART_PORT", "MAKEFLAGS", "MFLAGS", "MAKEOVERRIDES"):
            env.pop(key, None)
        with open(directory / (name + ".log"), "xb") as log:
            child = subprocess.Popen(spec["command"], cwd=str(directory), env=env,
                                     stdin=subprocess.DEVNULL, stdout=log, stderr=log, close_fds=True)
            deadline = time.monotonic() + spec["timeout"]
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
                if time.monotonic() >= deadline:
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
        return board_state()
    if action == "init":
        return init_owned(req["directory"], req["token"], req["series"], req["helper"])
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
    if action == "inputs":
        donor = Path(req["donor"]).resolve(strict=True)
        import shutil
        result = {}
        for rel, expected in (("workload/xiangshan-am-hello.bin", req["workload_sha"]),
                              ("ref/riscv64-nemu-interpreter-so", req["nemu_sha"])):
            source, dest = donor / rel, directory / rel
            if digest(source) != expected:
                raise RuntimeError("donor input hash mismatch: " + str(source))
            dest.parent.mkdir(exist_ok=True)
            with source.open("rb") as inp, dest.open("xb") as out:
                shutil.copyfileobj(inp, out)
            if digest(dest) != expected:
                raise RuntimeError("copied input hash mismatch")
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
    if action == "launch":
        return launch(str(directory), req["token"], req["name"], req["command"], req.get("env"), req["timeout"])
    if action == "stop":
        name = req["name"]
        if (directory / (name + ".result.json")).exists():
            return {"state": "finished"}
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
        return verdict(status, text)
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


def verdict(status, text):
    result, rc = status.get("result"), status.get("rc")
    if result is None or rc is None:
        return {"verdict": "pending", "rc": rc}
    if result.get("reason") == "timeout" or rc == 124:
        return {"verdict": "timeout", "rc": rc}
    evidence = ("HIT GOOD TRAP" in text and "HIT BAD TRAP" not in text
                and "ABORT at" not in text
                and "GBus C2H interface layer=sram-window" in text
                and re.search(r"GBus DMA workload queued [1-9][0-9]* bytes", text)
                and (re.search(r"GBus C2H progress reads=[1-9][0-9]* bytes=[1-9][0-9]*.*staged=", text)
                     or re.search(r"GBus GBD1 progress reads=[1-9][0-9]* bytes=[1-9][0-9]* seq=[0-9]+", text)))
    good = (rc == 0 and result.get("rc") == 0 and result.get("child_rc") == 0
            and result.get("reason") == "exited" and not result.get("cleanup_errors") and evidence)
    return {"verdict": "good_trap" if good else "failed_or_unproven", "rc": rc}


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
        self.fpga = Remote(self.env["FPGA_HOST"], key)
        self.rt = Remote(self.env["RUNTIME_HOST"])
        self.donor = self.env.get("FPGA_HOST_DONOR_DIR", self.env.get("FPGA_HOST_DIR", ""))
        if not re.fullmatch(r"/[A-Za-z0-9_./-]+", self.donor):
            raise RuntimeError("canonical FPGA_HOST_DONOR_DIR is required (legacy FPGA_HOST_DIR is donor-only)")
        self.host_dir = str(Path(self.donor).parent / ("minjie_gbus_host_" + self.run_id))
        self.series = self.env.get("LOGICAL_PROJECT", "minjie_xsmini_gbus_pr954")
        if not re.fullmatch(r"[A-Za-z0-9_-]+", self.series):
            raise RuntimeError("invalid logical project")
        self.stage = "/home/data/test/runtime_stage_" + self.series + "_" + self.run_id
        self.owned_dirs = []
        self.workers = []
        self.result = {"verdict": "not_started", "run_id": self.run_id, "host_dir": self.host_dir, "stage": self.stage}
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

    def start(self, host, directory, name, command, env=None, timeout=1800):
        # Register before SSH: loss of the launch acknowledgement still cleans up.
        self.workers.append((host, directory, name))
        self.rpc(host, directory, "launch", name=name, command=command, env=env or {}, timeout=timeout)

    def wait_worker(self, host, directory, name, timeout):
        deadline = time.monotonic() + timeout
        while time.monotonic() <= deadline:
            state = self.rpc(host, directory, "status", name=name)
            if state["result"] is not None and state["rc"] is not None:
                return state
            time.sleep(1)
        raise RuntimeError(name + " wrapper did not publish an atomic rc")

    def release(self, project=None):
        release = self.env.get("RELEASE_DIR")
        if not release and self.env.get("CORE_DIR"):
            core = Path(self.env["CORE_DIR"]).resolve()
            if core.name == "build":
                release = str(core.parent)
        if project is not None:
            text = (project / "rtl/filelist.f").read_text()
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
        self.log("phase=host_build isolated_dir=" + self.host_dir)
        self.init(self.fpga, self.host_dir)
        inputs = self.rpc(self.fpga, self.host_dir, "inputs", donor=self.donor,
                          workload_sha=WORKLOAD_SHA, nemu_sha=NEMU_SHA)
        self.save("input-hashes.json", inputs)
        source = Path(self.env.get("DIFFTEST_SRC", str(self.root / "difftest"))).resolve(strict=True)
        self.fpga.sync(str(source) + "/", self.host_dir + "/difftest-src/",
                       ("build/", ".git", "*.o", "*.d", "*.log"))
        self.rpc(self.fpga, self.host_dir, "prepare_generated")
        self.fpga.sync(str(self.generated) + "/", self.host_dir + "/difftest-src/build/generated-src/")
        self.rpc(self.fpga, self.host_dir, "generated", manifest=self.generated_manifest)
        # Bash preserves make's status through tee. Fresh directory means no
        # stale binary can satisfy proof. No interactive shell startup is sourced.
        script = ('set -euo pipefail; cd difftest-src; '
                  'test ! -e build/fpga-host; '
                  'make fpga-host FPGA=1 RELEASE=1 CPU=kmh UVHS=1 USE_XDMA_H2C=1 '
                  'DIFFTEST_HOSTIF=GBUS USE_SERIAL_PORT=0 '
                  'NOOP_HOME="$PWD" DESIGN_DIR="$PWD" 2>&1 | tee ../make.log')
        self.start(self.fpga, self.host_dir, "build", ["bash", "-c", script], timeout=3600)
        status = self.wait_worker(self.fpga, self.host_dir, "build", 3630)
        self.save("build-status.json", status)
        if status["rc"] != 0 or status["result"]["child_rc"] != 0 or status["result"]["cleanup_errors"]:
            raise RuntimeError("host build failed; no runtime upload or launch permitted")
        proof = self.rpc(self.fpga, self.host_dir, "proof")
        self.save("binary-proof.json", proof)
        self.log("phase=host_build OK sha256=" + proof["sha256"])

    def wait_board(self):
        deadline = time.monotonic() + int(self.env.get("WAIT_BOARD_TIMEOUT", "86400"))
        while True:
            try:
                state = self.rt.call("board")
            except Exception as exc:
                state = {"state": "unknown", "error": str(exc)}
            self.log("board=" + json.dumps(state))
            if state.get("state") == "free":
                return
            if time.monotonic() >= deadline:
                raise RuntimeError("board busy/unknown; no runtime launch")
            time.sleep(int(self.env.get("BOARD_POLL_SEC", "120")))

    def stop(self, host, directory, name):
        # No process name search, PID-only kill, process-group kill or fallback.
        answer = self.rpc(host, directory, "stop", name=name)
        self.log("cleanup " + directory + "/" + name + " " + json.dumps(answer))
        status = self.wait_worker(host, directory, name, 15)
        if status["result"]["cleanup_errors"]:
            raise RuntimeError("cleanup refused: " + json.dumps(status))
        return status

    def runtime(self):
        self.wait_board()
        self.init(self.rt, self.stage)
        self.rt.sync(str(self.project / "hw.dat"), self.stage + "/")
        runtime = self.root / "env-scripts/fpga_diff/uvhs/runtime"
        for name in ("runtime_server.tcl", "runtime_session.sh", "uv_shell_exec_compat.sh"):
            self.rt.sync(runtime / name, self.stage + "/")
        uv = self.env.get("UV_ROOT_ON_RUNTIME", "/home/data/UVHS/2506p4_0210")
        ready_timeout = int(self.env.get("RUNTIME_READY_TIMEOUT", "900"))
        attempts = int(self.env.get("RUNTIME_ATTEMPTS", "3"))
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
                   "PATH": uv + "/bin:" + uv + "/lib/venv3.8/bin:" + uv + "/lib/gcc10.3/bin:/usr/local/bin:/usr/bin:/bin"}
            if self.env.get("UVHS_IGNORE_TIMING_SIGNOFF_ERROR") == "1":
                env["UVHS_IGNORE_TIMING_SIGNOFF_ERROR"] = "1"
            # The unchanged runtime_session/server own programming and readiness.
            # An outer tracked worker handles timeout before runtime_session's
            # legacy PID-only timeout path could execute.
            args = ["bash", self.stage + "/runtime_session.sh", "start", directory + "/uv_shell.pid",
                    directory + "/uv_shell.ready", directory + "/uv_shell.log", directory + "/command.tcl",
                    str(ready_timeout + 86400), "uv_shell", "-rt_shell", "-workdir", directory,
                    "-script", self.stage + "/runtime_server.tcl"]
            setup = ('set -euo pipefail; mkdir .uvhs-compat-bin .uvhs-runtime-lib; '
                     'ln -s ' + shlex.quote(compat) + ' .uvhs-compat-bin/python; '
                     'ln -s ' + shlex.quote(compat) + ' .uvhs-compat-bin/python3; exec ' + shlex.join(args))
            self.start(self.rt, directory, "runtime", ["bash", "-c", setup], env, ready_timeout + 86400)
            deadline = time.monotonic() + ready_timeout
            while time.monotonic() <= deadline:
                state = self.rpc(self.rt, directory, "status", name="runtime")
                if state["ready"]:
                    self.log("runtime ready attempt=" + str(attempt))
                    return
                if state["result"] is not None:
                    break
                time.sleep(1)
            self.stop(self.rt, directory, "runtime")
            logs = self.rpc(self.rt, directory, "logs")
            text = "\n".join(base64.b64decode(v["sample_b64"]).decode(errors="replace") for v in logs.values())
            self.collect_one(self.rt, directory)
            if not re.search(r"RTM-101|occupied by other users", text, re.I):
                raise RuntimeError("runtime failed/timeout (not an occupied-board retry)")
            self.log("occupied RTM-101; cleaned owned attempt, retrying with a new directory")
        raise RuntimeError("runtime occupied retry limit reached")

    def run_host(self):
        timeout = int(self.env.get("RUN_TIMEOUT", "1800"))
        device = self.env.get("UART_DEVICE", "/dev/ttyUSB0")
        if device != "/dev/ttyUSB0":
            raise RuntimeError("this experiment requires runtime /dev/ttyUSB0")
        self.start(self.rt, self.attempt, "uart", ["bash", "-c",
                   "set -euo pipefail; stty -F /dev/ttyUSB0 115200 raw -echo; exec cat /dev/ttyUSB0"], timeout=timeout + 60)
        env = {"UVHS_DISABLE_DOWNLOAD": "1", "UVHS_DDR_LOAD_CMD": "/bin/true",
               "GBUS_HOST": self.rt.host.split("@")[-1], "GBUS_FPGA": "2", "GBUS_DMA_FPGA": "2",
               "GBUS_CONFIG_BASE": "0x1000", "GBUS_DDR_BASE": "0", "GBUS_CONFIG_READBACK": "1"}
        command = [self.host_dir + "/difftest-src/build/fpga-host", "--ram-size=16MB", "--diff",
                   self.host_dir + "/ref/riscv64-nemu-interpreter-so", "-i", self.host_dir + "/workload/xiangshan-am-hello.bin"]
        self.start(self.fpga, self.host_dir, "host", command, env, timeout)
        state = self.wait_worker(self.fpga, self.host_dir, "host", timeout + 30)
        self.save("host-status.json", state)
        self.result.update(self.rpc(self.fpga, self.host_dir, "verdict"))
        self.log("verdict=" + json.dumps(self.result))
        if self.result["verdict"] != "good_trap":
            raise RuntimeError("no proven host rc0 GBus SRAM DiffTest GOOD TRAP")

    def collect_one(self, host, directory):
        logs = self.rpc(host, directory, "logs")
        dest = self.out / Path(directory).name
        dest.mkdir(exist_ok=True)
        for name, data in logs.items():
            (dest / name).write_bytes(base64.b64decode(data["sample_b64"]))
        atomic(dest / "sample-sizes.json", json.dumps({k: v["size"] for k, v in logs.items()}))

    def finish(self, rc):
        errors = []
        for host, directory, name in reversed(self.workers):
            try:
                self.stop(host, directory, name)
            except Exception as exc:
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

    def execute(self, mode):
        rc = 1
        try:
            if mode == "supervise":
                self.project = Path(self.env.get("PRJ_DIR", str(self.root / "env-scripts/fpga_diff" / self.env["PRJ"]))).resolve(strict=True)
                self.lock_project(self.project)
                self.release(self.project)
                deadline = time.monotonic() + int(self.env.get("WAIT_BIT_TIMEOUT", "28800"))
                while True:
                    log = self.project / "backend_run.log"
                    text = log.read_text(errors="replace") if log.exists() else ""
                    if "Error: in running command" in text:
                        raise RuntimeError("backend failed")
                    if "UVHS_BACKEND_SUCCESS" in text:
                        break
                    if time.monotonic() >= deadline:
                        raise RuntimeError("backend timeout")
                    time.sleep(30)
                if not (self.project / "hw.dat").is_dir():
                    raise RuntimeError("backend success without hw.dat")
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
