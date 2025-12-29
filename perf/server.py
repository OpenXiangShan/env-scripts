import os
import subprocess
import time
import ast
import shlex


class Server(object):
    glance_port = 61208

    def __init__(self, host_name, verbose=False):
        self.host_name = host_name
        self.remote_cmd = ["ssh", host_name]
        self.failed_tests = []
        self.success_tests = []
        self.pending_proc = []

    def pending_tests(self):
        self.check_running()
        tests = []
        for proc in self.pending_proc:
            tests.append(proc[0])
        return tests

    def numactl(self, cmd, mem, start, end, num_cores):
        if not self.is_epyc(num_cores):
            return cmd
        return ["numactl", "-m", f"{str(mem)}", "-C", f"{start}-{end}"] + cmd

    def remote_get_free_cores(self, threads):
        pwd = os.path.dirname(os.path.abspath(__file__))
        cmd = ["python3", f"{pwd}/get_free_core.py", f"{threads}"]
        ssh_cmd_str = " ".join(self.remote_cmd + cmd)
        # print(ssh_cmd_str)
        proc = os.popen(ssh_cmd_str)
        result = proc.read().strip()
        if len(result) == 0:
            return "(False, 0, 0, 0, 0)"
        result = ast.literal_eval(result)
        # (free, mem, start, end, server_cores)
        return result

    def initialize(self, emu_path):
        # Ensure remote host has the required emu_path; if missing, copy it.
        # Handle multi-process by using an atomic lock directory and tmp rename.
        if not emu_path:
            return

        remote_test_cmd = self.remote_cmd + [
            "bash",
            "-lc",
            f"test -e {shlex.quote(emu_path)} && echo EXISTS || echo MISSING",
        ]
        try:
            res = subprocess.run(
                remote_test_cmd, capture_output=True, text=True, check=False
            )
            exists = res.stdout.strip() == "EXISTS"
        except Exception:
            exists = False

        if exists:
            return

        lock_path = f"{emu_path}.copy.lock"
        tmp_path = f"{emu_path}.tmp.{os.getpid()}"

        acquire_lock_cmd = self.remote_cmd + [
            "bash",
            "-lc",
            (
                "umask 077; LOCK="
                + shlex.quote(lock_path)
                + '; if mkdir "$LOCK" 2>/dev/null; then echo ACQUIRED; else echo BLOCKED; fi'
            ),
        ]
        lock_state = "BLOCKED"
        try:
            lr = subprocess.run(
                acquire_lock_cmd, capture_output=True, text=True, check=False
            )
            lock_state = lr.stdout.strip() or "BLOCKED"
        except Exception:
            lock_state = "BLOCKED"

        if lock_state == "ACQUIRED":
            try:
                # Ensure remote parent directory exists
                remote_mkdir = self.remote_cmd + [
                    "bash",
                    "-lc",
                    f"mkdir -p {shlex.quote(os.path.dirname(emu_path) or '.')}",
                ]
                subprocess.run(remote_mkdir, check=True)

                # Copy to tmp path on remote via rsync, then atomically move into place
                is_dir = os.path.isdir(emu_path)
                if is_dir:
                    # Ensure tmp directory exists on remote for directory sync
                    remote_tmp_mkdir = self.remote_cmd + [
                        "bash",
                        "-lc",
                        f"mkdir -p {shlex.quote(tmp_path)}",
                    ]
                    subprocess.run(remote_tmp_mkdir, check=True)

                rsync_cmd = [
                    "rsync",
                    "-a",
                    emu_path if not is_dir else os.path.join(emu_path, ""),
                    f"{self.host_name}:{tmp_path}",
                ]
                subprocess.run(rsync_cmd, check=True)

                remote_mv = self.remote_cmd + [
                    "bash",
                    "-lc",
                    f"mv -f {shlex.quote(tmp_path)} {shlex.quote(emu_path)}",
                ]
                subprocess.run(remote_mv, check=True)
            finally:
                # Always release lock
                remote_unlock = self.remote_cmd + [
                    "bash",
                    "-lc",
                    f"rmdir {shlex.quote(lock_path)} 2>/dev/null || true",
                ]
                subprocess.run(remote_unlock, check=False)
        else:
            # Another process is copying; wait until path exists or lock disappears
            deadline = time.time() + 300  # 5 minutes timeout
            while time.time() < deadline:
                check_cmd = self.remote_cmd + [
                    "bash",
                    "-lc",
                    f"test -e {shlex.quote(emu_path)} && echo EXISTS || echo WAIT",
                ]
                cr = subprocess.run(
                    check_cmd, capture_output=True, text=True, check=False
                )
                if (cr.stdout.strip() or "").startswith("EXISTS"):
                    break
                time.sleep(1)

        # Final verify
        final_check = self.remote_cmd + [
            "bash",
            "-lc",
            f"test -e {shlex.quote(emu_path)} && echo OK || echo FAIL",
        ]
        fr = subprocess.run(final_check, capture_output=True, text=True, check=False)
        if fr.stdout.strip() != "OK":
            raise RuntimeError(
                f"Failed to ensure emu_path on {self.host_name}: {emu_path}"
            )

    def assign(
        self,
        test_name,
        cmd,
        threads,
        xs_path,
        stdout_file,
        stderr_file,
        dry_run=False,
        verbose=True,
    ):
        try:
            self.initialize(emu_path=cmd[0])
        except RuntimeError as e:
            # Record initialization failure for this test instead of crashing the whole program.
            print(f"[ERROR] Failed to initialize emu for test '{test_name}': {e}")
            self.failed_tests.append(test_name)
            return False
        self.check_running()
        try:
            (free, mem, start, end, server_cores) = self.remote_get_free_cores(threads)
        except:
            (free, mem, start, end, server_cores) = (False, 0, 0, 0, 0)
        if not free:
            return False
        for running in self.pending_proc:
            pending_cores = running[2]
            if (start, end) == pending_cores:
                return False
        if dry_run:
            cmd = ["hostname;", "sleep", "60"]
        run_cmd = self.numactl(cmd, mem, start, end, server_cores)
        run_cmd = self.remote_cmd + [f"NOOP_HOME={xs_path}"] + run_cmd
        if verbose:
            os.system("date")
            print(f"{' '.join(run_cmd)}")

        with open(stdout_file, "w") as stdout, open(stderr_file, "w") as stderr:
            proc = subprocess.Popen(
                run_cmd, stdout=stdout, stderr=stderr, preexec_fn=os.setsid
            )
            if not dry_run:
                time.sleep(1)
        self.pending_proc.append((test_name, proc, (start, end)))
        if len(self.pending_proc) > (server_cores // threads):
            print(
                f"Server {self.ipname} has more than {len(self.pending_proc)} proc. Is it OK?"
            )
        return True

    def check_running(self):
        for running in self.pending_proc:
            test = running[0]
            proc = running[1]
            result = proc.poll()
            # print(f"Check {test} {result}")
            if result is not None:
                # finished
                self.pending_proc.remove(running)
                if result != 0:
                    print(f"[ERROR] {test} exist with code {proc.returncode}")
                    self.failed_tests.append(test)
                else:
                    self.success_tests.append(test)

    def is_free(self):
        self.check_running()
        return len(self.pending_proc) == 0

    def stop(self):
        # for proc in self.pending_proc:
        # os.killpg(os.getpgid(proc[1].pid), signal.SIGINT)
        # kill emu by ssh kill 'emu.pid'
        pwd = os.path.dirname(os.path.abspath(__file__))
        os.popen(" ".join(self.remote_cmd) + f" python3 {pwd}/stop_emu.py")

    def is_epyc(self, num_cores):
        return num_cores > 16
