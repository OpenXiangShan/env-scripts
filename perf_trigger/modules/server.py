import logging
import os
import random
import re
import shlex
import subprocess
import time
from typing import IO, Any

from .gcpt import GCPT
from .types import EmuConfig, FreeCoreInfo, PendingTask
from .tracker import Tracker

GCPT_RESTORER = "/nfs/home/share/ci-workloads/old-gcpt-restorer/gcpt.bin"

# NOTE: This script is directly copied from env-scripts/perf/cpuutil.py,
#       and will be sent to remote servers through stdin.
GET_FREE_CORE_SCRIPT = """
import psutil
import os
import time
import random

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
        core_usage = psutil.cpu_percent(interval=0.5, percpu=True)

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
    num_window = max(num_core // n - 1, 0)
    numa_node = numa_count()  # default 2

    def check(i):
        core_usage = psutil.cpu_percent(interval=0.5, percpu=True)
        unset_cores = get_unset_cores(num_core, core_usage)

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
        return cond1 and cond2 and cond3

    for i in random.sample(range(num_window), num_window):
        if not check(i):
            continue

        # sleep random time to avoid contention, then re-check
        time.sleep(random.uniform(1, 30))
        if not check(i):
            continue

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

MIN_ALLOC_CORES = 8


class Server:
    def __init__(
        self,
        hostname: str,
        emu_path: str,
        tracker: Tracker,
        nemu_so_path: str | None = None,
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

    def get_free_cores(self, threads: int) -> FreeCoreInfo:
        try:
            p = self.run(
                [
                    "python3",
                    "-c",
                    shlex.quote(
                        GET_FREE_CORE_SCRIPT
                        + f"\nprint(get_free_cores({max(threads, MIN_ALLOC_CORES)}))"
                    ),
                ],
                check=True,
            )
        except RuntimeError as e:
            logging.error(e)
            return FreeCoreInfo.none()

        if p.stdout is None:
            return FreeCoreInfo.none()

        result = p.stdout.read().decode().strip()
        if len(result) == 0:
            return FreeCoreInfo.none()

        result = re.match(r"\((True|False), (\d+), (\d+), (\d+), (\d+)\)", result)
        if result is None:
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

    def poll(self) -> tuple[list[str], list[str], list[str]]:
        still_pending: list[PendingTask] = []
        failed: list[str] = []
        success: list[str] = []
        for task in self.pending_task:
            result = task.proc.poll()
            if result is None:
                still_pending.append(task)
                continue

            # process finished, check result and call .wait() to cleanup
            if result != 0:
                self.tracker.error(
                    "%s failed with code %d on %s",
                    task.name,
                    task.proc.returncode,
                    self.hostname,
                )
                failed.append(task.name)
            else:
                self.tracker.info("%s succeeded on %s", task.name, self.hostname)
                success.append(task.name)
            self.tracker.debug("... elapsed: %.3f", task.elapsed())
            task.proc.wait()
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
            [
                "ssh",
                self.hostname,
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
            + cmd,
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
        os.makedirs(gcpt.get_result_path(), exist_ok=True)

        # find binary
        gcpt_path = gcpt.get_bin_path()
        p = self.run(
            [
                "ls",
                shlex.quote(gcpt_path),
            ]
        )
        if p.returncode != 0 or p.stdout is None:
            self.tracker.error("Failed to find gcpt binary: %s", gcpt_path)
            return

        gcpt_file = [f.strip() for f in p.stdout.read().decode().split()]
        gcpt_file = [
            f
            for f in gcpt_file
            if f.endswith(".gz") or f.endswith(".zstd") or f.endswith(".bin")
        ]
        if len(gcpt_file) == 0:
            self.tracker.error("Failed to find gcpt binary: %s", gcpt_path)
            return
        if len(gcpt_file) > 1:
            self.tracker.warning("Multiple gcpt binaries found, using the first one.")
        gcpt_file = gcpt_file[0]

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
                    shlex.quote(os.path.join(gcpt_path, gcpt_file)),
                    "-s",
                    str(random.randint(0, 9999)),
                ]
                + (
                    ["--diff", self.nemu_so_path]
                    if self.nemu_so_path
                    else ["--no-diff"]
                ),
                stdout=fout,
                stderr=ferr,
                block=False,
            )
        self.pending_task.append(PendingTask(proc=p, name=str(gcpt), free=free_cores))
        self.tracker.info("Started %s on %s", gcpt, self.hostname)
        self.tracker.debug(
            "Assigned cores %d-%d (total %d) on mem node %d",
            free_cores.start,
            free_cores.end,
            free_cores.total,
            free_cores.mem_node,
        )

    def stop(self):
        for task in self.pending_task:
            task.proc.terminate()

        if self.pending_task:
            # send kill signal to all remaining emu processes
            p = self.run(["pkill", "-e", "-f", shlex.quote(self.emu_path)], check=False)

            if p.stdout is not None:
                logging.info(
                    "Sent pkill to %s:\n%s", self.hostname, p.stdout.read().decode()
                )

        self.pending_task = []

    def initialize_open(self, source_path: str, target_path: str):
        """Open servers does not share the same nfs with node, rsync emu to server target_path"""
        assert self.hostname.startswith("open")

        if os.path.islink(source_path):
            source_path = os.path.realpath(source_path)

        # Skip if already exists
        p = self.run(
            [
                "test",
                "-e",
                shlex.quote(target_path),
            ],
        )
        if p.returncode == 0:
            logging.info(
                "File already exists on open server (%s), skip copying.", target_path
            )
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
                        source_path,
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
            except (RuntimeError, subprocess.CalledProcessError) as e:
                logging.error(e)
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
        logging.info(
            "Copied %s to open server (%s) successfully.",
            os.path.basename(source_path),
            target_path,
        )
