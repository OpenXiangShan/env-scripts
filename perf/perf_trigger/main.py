import argparse
import random
from tqdm import tqdm
import json
from gcpt import GCPT
import os

SERVER_POOL = [
    "node003",
    "node004",
    "node005",
    "node006",
    "node007",
    "node008",
    "node009",
    "node020",
    "node021",
    "node022",
    "node023",
    "node024",
    "node025",
    "node026",
    "node027",
    "node028",
    "node029",
    "node030",
    "node031",
    "node032",
    "node033",
    "node034",
    "node036",
    "node037",
    "node038",
    "node039",
    "node040",
    "node041",
    "node042",
    "open01",
    "open02",
    "open03",
    "open04",
    "open05",
    "open06",
    "open08",
    "open09",
    "open10",
    "open11",
    "open12",
    "open13",
    "open14",
    "open15",
    "open23",
    "open24",
    "open25",
    "open26",
    "open27",
]
NEMU_DIFF_SO = None
REF_RUN_TIME = "/nfs/home/share/liyanqin/env-scripts/perf/json/gcc12o3-incFpcOff-jeMalloc-time.json"
GCPT_RESTORER = "/nfs/home/share/liyanqin/old-gcpt-restorer/gcpt.bin"


class XiangShan:
    def __init__(
        self,
        gcpt_path: str,
        json_path: str,
        emu_path: str,
        result_path: str,
        server_list: str,
        benchmarks: str,
        nemu_so_path: str | None,
        warmup: int,
        max_instr: int,
    ):
        self.gcpt_path = gcpt_path
        self.json_path = json_path
        self.emu_path = emu_path
        self.result_path = result_path
        self.nemu_so_path = nemu_so_path
        self.warmup = warmup
        self.max_instr = max_instr

        with open(self.json_path, "r") as f:
            self.benchmarks = json.load(f)
        if benchmarks != "":
            benchmark_filter = benchmarks.replace(" ", "").split(",")
            self.benchmarks = {
                k: v
                for k, v in self.benchmarks.items()
                if any(k.startswith(prefix) for prefix in benchmark_filter)
            }

        if server_list == "all":
            self.servers = SERVER_POOL
        elif server_list == "":
            self.servers = random.sample(SERVER_POOL, k=len(self.benchmarks) // 10 + 1)
        else:
            self.servers = server_list.replace(" ", "").split(",")
            for server in self.servers:
                if server not in SERVER_POOL:
                    raise ValueError(f"Server {server} is not in the server pool")

        self.checkpoints = []
        for benchmark_name, benchmark_config in self.benchmarks.items():
            for point, weight in benchmark_config["points"].items():
                self.checkpoints.append(
                    GCPT(
                        gcpt_bin_dir=self.gcpt_path,
                        perf_base_dir=self.result_path,
                        benchspec=benchmark_name,
                        point=point,
                        weight=weight,
                        gcc12Enable=True,
                    )
                )

        if not os.path.exists(self.result_path):
            os.makedirs(self.result_path, exist_ok=True)

    def __get_run_command(self, gcpt: GCPT):
        return [
            self.emu_path,
            "--enable-fork",
            "-W",
            str(self.warmup),
            "-I",
            str(self.max_instr),
            "-r",
            GCPT_RESTORER,
            "-i",
            gcpt.get_bin_path(),
            "-s",
            str(random.randint(0, 9999)),
        ] + (["--diff", self.nemu_so_path] if self.nemu_so_path else ["--no-diff"])

    def run(self):
        for gcpt in tqdm(self.checkpoints):
            command = self.__get_run_command(gcpt)

    def run_checkpoints(self):
        pass

    def report(self):
        pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Performance regression script")
    parser.add_argument(
        "--gcpt-path", type=str, required=True, help="Path to the GCPT checkpoints"
    )
    parser.add_argument(
        "--json-path", type=str, required=True, help="Path to the GCPT json"
    )
    parser.add_argument("--emu-path", type=str, required=True, help="Path to the emu")
    parser.add_argument("--nemu-so-path", type=str, help="Path to NEMU diff so")
    parser.add_argument(
        "--result-path", type=str, required=True, help="Path to store the results"
    )
    parser.add_argument(
        "--server-list",
        type=str,
        default="",
        help="Comma-separated list of servers to use, leave empty to use all",
    )
    parser.add_argument(
        "--benchmarks",
        default="",
        type=str,
        help="Comma-separated list of benchmarks to run, leave empty to run all",
    )

    parser.add_argument(
        "--warmup", "-W", default=20000000, type=int, help="warmup instr count"
    )
    parser.add_argument(
        "--max-instr", "-I", default=40000000, type=int, help="max instr count"
    )

    args = parser.parse_args()
