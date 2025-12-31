import os
import random
import re
import shlex
import subprocess
import time
from typing import IO, Any

from gcpt import GCPT
from perf.perf_trigger.types import EmuConfig, FreeCoreInfo, PendingTask

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
    # print(f"Core Count: {num_core}\nCore Usage: {core_usage}\nUnset Cores: {unset_cores}")
    num_window = num_core // n
    numa_node = numa_count()  # default 2
    # use random windows to avoid unexpected waiting on a free window
    rand_windows = np.random.permutation(num_window)
    for i in rand_windows:
        window_cores = range(i * n, i * n + n)
        window_usage = core_usage[i * n : i * n + n]
        # print(f"Window{i} Usage: ", window_usage)
        # 5950x only allow 1 emu

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
    # print(f"No free {n} cores found. CPU usage: {core_usage}\n")


def is_epyc():
    num_core = psutil.cpu_count(logical=False)
    return num_core > 16
"""


class Server:
    def __init__(
        self,
        hostname: str,
    ):
        self.hostname = hostname
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
                        GET_FREE_CORE_SCRIPT + f"\nprint(get_free_cores(${threads}))"
                    ),
                ],
                check=True,
            )
        except Exception:
            return FreeCoreInfo(False, 0, 0, 0, 0)

        if p.stdout is None:
            return FreeCoreInfo(False, 0, 0, 0, 0)

        result = p.stdout.read().strip()
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
                print(f"[ERROR] {task.name} exist with code {task.proc.returncode}")
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
        **kwargs: Any,
    ):
        p = subprocess.Popen(
            ["ssh", self.hostname] + cmd,
            stdout=stdout,
            stderr=stderr,
            **kwargs,
        )
        if block or check:
            p.wait()
        if check and p.returncode != 0:
            raise RuntimeError(f"Remote command failed: {' '.join(cmd)}")
        return p

    def run_gcpt(
        self,
        gcpt: GCPT,
        emu_config: EmuConfig,
        free_cores: FreeCoreInfo,
    ):
        with (
            open(gcpt.get_out_path(), "w", encoding="utf-8") as fout,
            open(gcpt.get_err_path(), "w", encoding="utf-8") as ferr,
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
                    emu_config.emu_path,
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

    def initialize(self, emu_path: str):
        # Ensure remote host has the required emu_path; if missing, copy it.
        # Handle multi-process by using an atomic lock directory and tmp rename.
        p = self.run(
            [
                "bash",
                "-lc",
                f"test -e {shlex.quote(emu_path)} && echo EXISTS || echo MISSING",
            ],
        )

        if p.stdout is not None and p.stdout.read().strip() == "EXISTS":
            return

        lock_path = f"{emu_path}.copy.lock"
        tmp_path = f"{emu_path}.tmp.{os.getpid()}"

        lock_state = "BLOCKED"
        try:
            lr = self.run(
                [
                    "bash",
                    "-lc",
                    (
                        "umask 077; LOCK="
                        + shlex.quote(lock_path)
                        + '; if mkdir "$LOCK" 2>/dev/null; then echo ACQUIRED; else echo BLOCKED; fi'
                    ),
                ],
                check=True,
            )
            if lr.stdout is not None:
                lock_state = lr.stdout.read().strip() or "BLOCKED"
        except Exception:
            lock_state = "BLOCKED"

        if lock_state == "ACQUIRED":
            try:
                # Ensure remote parent directory exists
                self.run(
                    [
                        "bash",
                        "-lc",
                        f"mkdir -p {shlex.quote(os.path.dirname(emu_path) or '.')}",
                    ],
                    check=True,
                )

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
                        "bash",
                        "-lc",
                        f"mv -f {shlex.quote(tmp_path)} {shlex.quote(emu_path)}",
                    ],
                    check=True,
                )
            finally:
                # Always release lock
                self.run(
                    [
                        "bash",
                        "-lc",
                        f"rmdir {shlex.quote(lock_path)} 2>/dev/null || true",
                    ]
                )
        else:
            # Another process is copying; wait until path exists or lock disappears
            deadline = time.time() + 300  # 5 minutes timeout
            while time.time() < deadline:
                cr = self.run(
                    [
                        "bash",
                        "-lc",
                        f"test -e {shlex.quote(emu_path)} && echo EXISTS || echo WAIT",
                    ]
                )
                if cr.stdout is None or cr.stdout.read().strip().startswith("EXISTS"):
                    break
                time.sleep(1)

        # Final verify
        fr = self.run(
            [
                "bash",
                "-lc",
                f"test -e {shlex.quote(emu_path)} && echo OK || echo FAIL",
            ],
        )
        if fr.stdout is None or fr.stdout.read().strip() != "OK":
            raise RuntimeError(
                f"Failed to ensure emu_path on {self.hostname}: {emu_path}"
            )
