from enum import Enum
import os
import shutil


class GCPT:
    class State(Enum):
        NONE = 0
        RUNNING = 1
        FINISHED = 2
        ABORTED = 3

    def __init__(
        self,
        gcpt_path: str,
        result_path: str,
        benchmark: str,
        checkpoint: str,
        weight: str,
    ):
        self.gcpt_path = gcpt_path
        self.benchmark = benchmark
        self.checkpoint = checkpoint
        self.weight = weight
        self.state = GCPT.State.NONE
        self.result_path = os.path.join(result_path, self.__str__())

    def __str__(self) -> str:
        return "_".join([self.benchmark, self.checkpoint, str(self.weight)])

    def get_bin_path(self) -> str:
        bin_dir = os.path.join(self.gcpt_path, self.benchmark, str(self.checkpoint))
        bin_file = list(os.listdir(bin_dir))
        if len(bin_file) != 1:
            print(bin_file)
        bin_file = list(filter(lambda x: x != "_0_0.000000_.gz", bin_file))
        assert len(bin_file) == 1
        bin_path = os.path.join(bin_dir, bin_file[0])
        assert os.path.isfile(bin_path)
        return bin_path

    def get_result_dir(self):
        return self.result_path

    def get_stdout_path(self):
        return os.path.join(self.result_path, "simulator_out.txt")

    def get_stderr_path(self):
        return os.path.join(self.result_path, "simulator_err.txt")

    def refresh_state(self) -> "GCPT.State":
        if (
            not os.path.exists(self.get_stdout_path())
            or self.state == GCPT.State.FINISHED
            or self.state == GCPT.State.ABORTED
        ):
            return self.state

        self.state = GCPT.State.RUNNING
        with open(self.get_stdout_path(), "r", encoding="utf-8") as f:
            for line in f:
                if "ABORT at pc" in line or "FATAL:" in line or "Error:" in line:
                    self.state = GCPT.State.ABORTED
                elif "EXCEEDING CYCLE/INSTR LIMIT" in line or "GOOD TRAP" in line:
                    self.state = GCPT.State.FINISHED
                elif "SOME SIGNAL STOPS THE PROGRAM" in line:
                    self.state = GCPT.State.NONE

        return self.state
