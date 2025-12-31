from dataclasses import dataclass
import subprocess


@dataclass
class EmuConfig:
    """Configuration for emu runs"""

    gcpt_path: str
    json_path: str
    emu_path: str
    result_path: str
    nemu_so_path: str | None  # if None, difftest will be disabled
    warmup: int
    max_instr: int
    threads: int
    with_numactl: bool = True


@dataclass
class FreeCoreInfo:
    free: bool
    mem_node: int
    start: int
    end: int
    total: int


@dataclass
class PendingTask:
    proc: subprocess.Popen
    name: str
