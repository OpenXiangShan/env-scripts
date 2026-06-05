#!/usr/bin/env python3
"""Trigger a workload DDR write in an already-running Hejian UVHS session."""

import os
import shlex
import sys
import time

try:
    import pexpect
except ImportError:
    pexpect = None


def env(name, default=None):
    value = os.environ.get(name)
    return value if value else default


def tcl_brace_quote(value):
    return "{" + "".join("\\" + c if c in "\\{}" else c for c in value) + "}"


def ssh_run(remote_cmd, timeout=None, stream=False):
    if pexpect is None:
        raise SystemExit("python3 pexpect module is required")

    target = env("UVHS_HEJIAN_SSH", "root@172.38.11.85")
    password = env("UVHS_HEJIAN_PASS")
    if not password:
        raise SystemExit("UVHS_HEJIAN_PASS is required")

    child = pexpect.spawn(
        "ssh",
        ["-o", "StrictHostKeyChecking=accept-new", target, remote_cmd],
        encoding="utf-8",
        timeout=timeout,
    )
    while True:
        idx = child.expect(
            [
                r"(?i)are you sure you want to continue connecting",
                r"(?i)assword",
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


def main():
    stage = env("UVHS_STAGE_DIR")
    if not stage:
        raise SystemExit("UVHS_STAGE_DIR is required")

    command_file = env("UVHS_COMMAND_FILE", stage + "/uvhs_host_command.tcl")
    workload = env("UVHS_WORKLOAD_TXT", stage + "/ready-to-run/microbench-nutshell.txt")
    db_path = env("UVHS_DB_PATH", stage + "/hw.dat")
    ddr_rtl = env("UVHS_DDR_RTL", "fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4")
    script = env("UVHS_DDR_SCRIPT", stage + "/user_script/hw_write_workload_only.tcl")
    wait_sec = int(env("UVHS_DDR_WAIT_SEC", "300"))
    tag = f"{int(time.time())}-{os.getpid()}"
    ok_marker = f"/tmp/uvhs-direct-ddr-{tag}.ok"
    fail_marker = f"/tmp/uvhs-direct-ddr-{tag}.fail"

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
    remote_script = "\n".join(
        [
            "set -e",
            "rm -f " + shlex.quote(ok_marker) + " " + shlex.quote(fail_marker),
            "printf '%s\\n' " + shlex.quote(tcl_cmd) + " > " + shlex.quote(tmp),
            "mv -f " + shlex.quote(tmp) + " " + shlex.quote(command_file),
            f"for i in $(seq 1 {wait_sec}); do",
            "  if [ -f " + shlex.quote(ok_marker) + " ]; then rm -f " + shlex.quote(ok_marker) + "; exit 0; fi",
            "  if [ -f " + shlex.quote(fail_marker) + " ]; then cat " + shlex.quote(fail_marker) + " >&2; rm -f " + shlex.quote(fail_marker) + "; exit 1; fi",
            "  sleep 1",
            "done",
            "echo '[uvhs-direct-ddr] timed out waiting for DDR write' >&2",
            "exit 1",
        ]
    )
    return ssh_run("bash -lc " + shlex.quote(remote_script), timeout=wait_sec + 30, stream=True)


if __name__ == "__main__":
    raise SystemExit(main())
