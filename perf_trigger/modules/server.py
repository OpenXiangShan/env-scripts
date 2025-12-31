import os
import random
import re
import shlex
import subprocess
import time
from typing import IO, Any

from .gcpt import GCPT
from .types import EmuConfig, FreeCoreInfo, PendingTask

GCPT_RESTORER = "/nfs/home/share/liyanqin/old-gcpt-restorer/gcpt.bin"

# NOTE: This script is directly copied from env-scripts/perf/cpuutil.py,
#       and will be sent to remote servers through stdin.
GET_FREE_CORE_SCRIPT = """
import psutil
import os
import numpy as np

percpu_use_thres = 30

def numa_count():
    node_dir = "/sys/devices/system/node/"
    nodes = [node for node in os.listdir(node_dir) if node.startswith("node")]
    return len(nodes)

def get_unset_cores(cpu_count=None, core_usage=None) -> list[int]:
    # FIXME: SMT is not considered temporaryly
    if cpu_count is None:
        cpu_count = psutil.cpu_count(logical=False)
    if core_usage is None:
        core_usage = psutil.cpu_percent(interval=5, percpu=True)

    cpu_affinity_count = {i: 0 for i in range(cpu_count)}
    valid_list = ["running", "disk-sleep", "waking", "waiting"]
    for proc in psutil.process_iter(["pid", "name", "cpu_affinity", "status"]):
        try:
            affinity = proc.info["cpu_affinity"]
            valid = proc.info["status"] in valid_list
            if affinity and max(affinity) < cpu_count and len(affinity) > 1 and valid:
                for cpu in affinity:
                    cpu_affinity_count[cpu] += 1
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass

    unset_cores = [cpu for cpu, count in cpu_affinity_count.items() if count == 0]
    return unset_cores

def get_free_cores(n):
    # SMT is not allowed
    num_core = psutil.cpu_count(logical=False)
    core_usage = psutil.cpu_percent(interval=5, percpu=True)
    unset_cores = get_unset_cores(num_core, core_usage)
    num_window = num_core // n
    numa_node = numa_count()  # default 2
    # use random windows to avoid unexpected waiting on a free window
    rand_windows = np.random.permutation(num_window)
    for i in rand_windows:
        window_cores = range(i * n, i * n + n)
        window_usage = core_usage[i * n : i * n + n]

        # average unsage of window_cores less than percpu_use_thres
        cond1 = sum(window_usage) < percpu_use_thres * n
        # less than 1 core has high usage in window_cores
        cond2 = (
            sum(map(lambda x: x > 80, window_usage if is_epyc() else core_usage)) < 1
        )
        # window_cores is unset
        cond3 = set(window_cores).issubset(unset_cores)
        if cond1 and cond2 and cond3:
            # return (Success?, memory node, start_core, end_core)
            return (
                True,
                (int)(((i * n) % num_core) // (num_core // numa_node)),
                (int)(i * n),
                (int)(i * n + n - 1),
                num_core,
            )
    return (False, 0, 0, 0, num_core)

def is_epyc():
    num_core = psutil.cpu_count(logical=False)
    return num_core > 16
"""


class Server:
    def __init__(
        self,
        hostname: str,
        emu_path: str,
    ):
        self.hostname = hostname
        self.emu_path = emu_path
        self.pending_task: list[PendingTask] = []

    def self_test(self) -> bool:
        return self.run(["hostname"]).wait() == 0

    def get_free_cores(self, threads: int) -> FreeCoreInfo:
        # (free, mem, start, end, server_cores)
        try:
            p = self.run(
                [
                    "python3",
                    "-c",
                    shlex.quote(
                        GET_FREE_CORE_SCRIPT + f"\nprint(get_free_cores({threads}))"
                    ),
                ],
                check=True,
            )
        except Exception as e:
            print(e)
            return FreeCoreInfo(False, 0, 0, 0, 0)

        if p.stdout is None:
            return FreeCoreInfo(False, 0, 0, 0, 0)

        result = p.stdout.read().decode().strip()
        if len(result) == 0:
            return FreeCoreInfo(False, 0, 0, 0, 0)

        result = re.match(r"\((True|False), (\d+), (\d+), (\d+), (\d+)\)", result)
        if result is None:
            return FreeCoreInfo(False, 0, 0, 0, 0)

        return FreeCoreInfo(
            free=result.group(1) == "True",
            mem_node=int(result.group(2)),
            start=int(result.group(3)),
            end=int(result.group(4)),
            total=int(result.group(5)),
        )

    def poll(self) -> tuple[list[str], list[str], list[str]]:
        still_pending: list[PendingTask] = []
        failed: list[str] = []
        success: list[str] = []
        for task in self.pending_task:
            result = task.proc.poll()
            if result is None:
                still_pending.append(task)
                continue
            if result != 0:
                print(f"[ERROR] {task.name} exits with code {task.proc.returncode}")
                failed.append(task.name)
            else:
                success.append(task.name)
        self.pending_task = still_pending
        return success, failed, [t.name for t in self.pending_task]

    def run(
        self,
        cmd: list[str],
        stdout: int | IO[Any] = subprocess.PIPE,
        stderr: int | IO[Any] = subprocess.PIPE,
        block: bool = True,
        check: bool = False,
    ):
        p = subprocess.Popen(
            ["ssh", self.hostname] + cmd,
            stdout=stdout,
            stderr=stderr,
        )
        if block or check:
            p.wait()
        if check and p.returncode != 0:
            raise RuntimeError(
                f"Remote command failed({p.returncode})\n"
                + f"=== Command ===\n{' '.join(cmd)}\n"
                + (
                    f"=== stdout ===\n{p.stdout.read().decode()}\n"
                    if p.stdout is not None
                    else ""
                )
                + (
                    f"=== stderr ===\n{p.stderr.read().decode()}\n"
                    if p.stderr is not None
                    else ""
                )
            )
        return p

    def run_gcpt(
        self,
        gcpt: GCPT,
        emu_config: EmuConfig,
        free_cores: FreeCoreInfo,
    ):
        os.makedirs(gcpt.get_result_dir(), exist_ok=True)
        with (
            open(gcpt.get_stdout_path(), "w", encoding="utf-8") as fout,
            open(gcpt.get_stderr_path(), "w", encoding="utf-8") as ferr,
        ):
            p = self.run(
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
                    self.emu_path,
                    "-W",
                    str(emu_config.warmup),
                    "-I",
                    str(emu_config.max_instr),
                    "-r",
                    GCPT_RESTORER,
                    "-i",
                    shlex.quote(gcpt.get_bin_path()),
                    "-s",
                    str(random.randint(0, 9999)),
                ]
                + (
                    ["--diff", emu_config.nemu_so_path]
                    if emu_config.nemu_so_path
                    else ["--no-diff"]
                ),
                stdout=fout,
                stderr=ferr,
                block=False,
            )
        self.pending_task.append(PendingTask(proc=p, name=gcpt.get_bin_path()))
        time.sleep(10)  # wait for a while to let emu process start properly

    def stop(self):
        for task in self.pending_task:
            task.proc.terminate()
        self.pending_task = []

    def initialize_open(self, emu_path: str, target_path: str):
        """Open servers does not share the same nfs with node, rsync emu to server target_path"""
        assert self.hostname.startswith("open")

        if os.path.islink(emu_path):
            emu_path = os.path.realpath(emu_path)

        # Skip if already exists
        p = self.run(
            [
                "test",
                "-e",
                shlex.quote(target_path),
            ],
        )
        if p.returncode == 0:
            print(f"Emu already exists on open server ({target_path}), skip copying.")
            return

        # Ensure remote parent directory exists
        self.run(
            ["mkdir", "-p", shlex.quote(os.path.dirname(target_path))],
            check=True,
        )

        lock_path = f"{target_path}.copy.lock"
        tmp_path = f"{target_path}.tmp"

        lock_state = "BLOCKED"
        try:
            lr = self.run(
                [
                    "bash",
                    "-lc",
                    (
                        "umask 077 >/dev/null; LOCK="
                        + shlex.quote(lock_path)
                        + '; if mkdir "$LOCK"; then echo ACQUIRED; else echo BLOCKED; fi'
                    ),
                ],
                check=True,
            )
            if lr.stdout is not None:
                lock_state = lr.stdout.read().decode().strip() or "BLOCKED"
        except Exception as e:
            print(e)
            lock_state = "BLOCKED"

        if lock_state == "ACQUIRED":
            try:
                # emu_path is a file: copy via rsync, then atomically move into place
                subprocess.run(  # do not use self.run, we need this locally
                    [
                        "rsync",
                        "-a",
                        emu_path,
                        f"{self.hostname}:{tmp_path}",
                    ],
                    check=True,
                )

                self.run(
                    [
                        "mv",
                        "-f",
                        shlex.quote(tmp_path),
                        shlex.quote(target_path),
                    ],
                    check=True,
                )
            except Exception as e:
                print(e)
            finally:
                # Always release lock
                self.run(["rmdir", shlex.quote(lock_path)])
        else:
            # Another process is copying; wait until path exists or lock disappears
            deadline = time.time() + 300  # 5 minutes timeout
            while time.time() < deadline:
                cr = self.run(
                    [
                        "test",
                        "-e",
                        shlex.quote(target_path),
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
                shlex.quote(target_path),
            ],
            check=True,
        )
        print(f"Copied emu to open server ({target_path}) successfully.")
        # override self.emu_path
        self.emu_path = target_path
