#!/usr/bin/env python3
"""FPGA-host side helper for controlling the remote UVHS programming host.

Credentials are intentionally read from the environment, not stored here.
"""

import argparse
import os
import shlex
import subprocess
import sys
import time

try:
    import pexpect
except ImportError:
    pexpect = None


DEFAULT_STAGE = "/home/data/test/fengkehan/uvhs-ddr-uvw-ip-bind-20260527"
DEFAULT_UV_SHELL = "/home/data/UVHS/2506p4_0210/bin/uv_shell"
DEFAULT_DDR_RTL = "fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4"
DEFAULT_TMUX_SESSION = "uvhs-fpga-host"


def env(name, default=None):
    value = os.environ.get(name)
    return value if value else default


def tcl_brace_quote(value):
    return "{" + "".join("\\" + c if c in "\\{}" else c for c in value) + "}"


def require_pexpect():
    if pexpect is None:
        raise SystemExit("python3 pexpect module is required for UVHS password SSH")


def ssh_run(remote_cmd, timeout=None, stream=False):
    require_pexpect()
    target = env("UVHS_HEJIAN_SSH", "root@172.38.11.85")
    password = env("UVHS_HEJIAN_PASS")
    if not password:
        raise SystemExit("UVHS_HEJIAN_PASS is required")

    cmd = "ssh -o StrictHostKeyChecking=accept-new " + shlex.quote(target) + " " + shlex.quote(remote_cmd)
    child = pexpect.spawn(cmd, encoding="utf-8", timeout=timeout)
    while True:
        idx = child.expect(
            [
                r"(?i)are you sure you want to continue connecting",
                r"(?i)password:",
                pexpect.EOF,
                pexpect.TIMEOUT,
            ]
        )
        if child.before and stream:
            sys.stdout.write(child.before)
            sys.stdout.flush()
        if idx == 0:
            child.sendline("yes")
        elif idx == 1:
            child.sendline(password)
        elif idx == 2:
            child.close()
            return child.exitstatus if child.exitstatus is not None else 128 + int(child.signalstatus or 0)
        else:
            child.close(force=True)
            return 124


def remote_shell_script(lines):
    return "bash -lc " + shlex.quote("\n".join(lines))


def run_local(args, check=True):
    print("[uvhs-host-remote] " + " ".join(shlex.quote(arg) for arg in args), flush=True)
    completed = subprocess.run(args)
    if check and completed.returncode != 0:
        raise SystemExit(completed.returncode)
    return completed.returncode


def tmux_session():
    return env("UVHS_TMUX_SESSION", DEFAULT_TMUX_SESSION)


def tmux_bin():
    return env("UVHS_TMUX_BIN", "tmux")


def start_download(_args):
    session = tmux_session()
    tmux = tmux_bin()
    wait_sec = int(env("UVHS_DOWNLOAD_WAIT_SEC", "90"))
    helper = os.path.abspath(__file__)

    if subprocess.run([tmux, "has-session", "-t", session], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
        raise SystemExit(f"tmux session already exists: {session}")

    exports = []
    for name, value in sorted(os.environ.items()):
        if name.startswith("UVHS_"):
            exports.append(f"export {name}={shlex.quote(value)}")
    exports.append("exec " + shlex.quote(helper) + " download")
    run_local([tmux, "new-session", "-d", "-s", session, "bash", "-lc", "; ".join(exports)])
    if wait_sec > 0:
        print(f"[uvhs-host-remote] wait {wait_sec} second(s) for UVHS download session", flush=True)
        time.sleep(wait_sec)
    return 0


def cleanup(_args):
    return run_local([tmux_bin(), "kill-session", "-t", tmux_session()], check=False)


def download(_args):
    stage = env("UVHS_STAGE_DIR", DEFAULT_STAGE)
    uv_shell = env("UVHS_UV_SHELL", DEFAULT_UV_SHELL)
    db_path = env("UVHS_DB_PATH", stage + "/hw.dat")
    script = env("UVHS_DOWNLOAD_SCRIPT", stage + "/user_script/hw_run_download.tcl")
    command_file = env("UVHS_COMMAND_FILE", stage + "/uvhs_host_command.tcl")
    workdir = env("UVHS_DOWNLOAD_WORKDIR", stage + "/uvshell_download_host_" + str(os.getpid()))

    lines = [
        "set -e",
        "mkdir -p " + shlex.quote(workdir),
        "cd " + shlex.quote(stage),
        "rm -f " + shlex.quote(command_file) + " " + shlex.quote(command_file + ".running"),
        "export UVHS_DB_PATH=" + shlex.quote(db_path),
        "export UVHS_COMMAND_FILE=" + shlex.quote(command_file),
        "export UVHS_DDR_RTL=" + shlex.quote(env("UVHS_DDR_RTL", DEFAULT_DDR_RTL)),
        "exec " + shlex.quote(uv_shell) + " -rt_shell -workdir " + shlex.quote(workdir) + " -script " + shlex.quote(script),
    ]
    return ssh_run(remote_shell_script(lines), timeout=None, stream=True)


def ddr(_args):
    stage = env("UVHS_STAGE_DIR", DEFAULT_STAGE)
    script = env("UVHS_DDR_SCRIPT", stage + "/user_script/hw_write_workload_only.tcl")
    command_file = env("UVHS_COMMAND_FILE", stage + "/uvhs_host_command.tcl")
    db_path = env("UVHS_DB_PATH", stage + "/hw.dat")
    workload = env("UVHS_WORKLOAD_TXT", stage + "/ready-to-run/microbench-nutshell.txt")
    ddr_rtl = env("UVHS_DDR_RTL", DEFAULT_DDR_RTL)
    wait_sec = int(env("UVHS_DDR_WAIT_SEC", "300"))
    tag = f"{int(time.time())}-{os.getpid()}"
    ok_marker = f"/tmp/uvhs-fpga-host-ddr-{tag}.ok"
    fail_marker = f"/tmp/uvhs-fpga-host-ddr-{tag}.fail"

    tcl_cmd = (
        "set ::env(UVHS_NO_EXIT) 1; "
        "set ::env(UVHS_ATTACHED_RUNTIME) 1; "
        f"set ::env(UVHS_DB_PATH) {tcl_brace_quote(db_path)}; "
        f"set ::env(UVHS_WORKLOAD_TXT) {tcl_brace_quote(workload)}; "
        f"set ::env(UVHS_DDR_RTL) {tcl_brace_quote(ddr_rtl)}; "
        f"if {{[catch {{source {tcl_brace_quote(script)}}} ::uvhs_err]}} "
        f"{{set fp [open {tcl_brace_quote(fail_marker)} w]; puts $fp $::uvhs_err; close $fp}} "
        f"else {{set fp [open {tcl_brace_quote(ok_marker)} w]; puts $fp ok; close $fp}}"
    )

    tmp = command_file + "." + tag + ".tmp"
    lines = [
        "set -e",
        "rm -f " + shlex.quote(ok_marker) + " " + shlex.quote(fail_marker),
        "printf '%s\\n' " + shlex.quote(tcl_cmd) + " > " + shlex.quote(tmp),
        "mv -f " + shlex.quote(tmp) + " " + shlex.quote(command_file),
        f"for i in $(seq 1 {wait_sec}); do",
        "  if [ -f " + shlex.quote(ok_marker) + " ]; then rm -f " + shlex.quote(ok_marker) + "; exit 0; fi",
        "  if [ -f " + shlex.quote(fail_marker) + " ]; then cat " + shlex.quote(fail_marker) + " >&2; rm -f " + shlex.quote(fail_marker) + "; exit 1; fi",
        "  sleep 1",
        "done",
        "echo '[uvhs-host-remote] timed out waiting for DDR write' >&2",
        "exit 1",
    ]
    return ssh_run(remote_shell_script(lines), timeout=wait_sec + 30, stream=True)


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("start-download")
    subparsers.add_parser("download")
    subparsers.add_parser("ddr")
    subparsers.add_parser("cleanup")
    args = parser.parse_args()
    if args.command == "start-download":
        return start_download(args)
    if args.command == "download":
        return download(args)
    if args.command == "ddr":
        return ddr(args)
    if args.command == "cleanup":
        return cleanup(args)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
