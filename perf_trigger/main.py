import argparse
import json
import os
import random
import time
from tqdm import tqdm

from modules.gcpt import GCPT
from modules.server import Server
from modules.types import EmuConfig

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
REF_RUN_TIME = "/nfs/home/share/liyanqin/env-scripts/perf/json/gcc12o3-incFpcOff-jeMalloc-time.json"


class XiangShan:
    def __init__(
        self,
        emu_config: EmuConfig,
        benchmarks: str,
        server_list: str,
    ):
        self.emu_config = emu_config

        with open(self.emu_config.json_path, "r", encoding="utf-8") as f:
            self.benchmarks = json.load(f)
        if benchmarks != "":
            benchmark_filter = benchmarks.replace(" ", "").split(",")
            self.benchmarks = {
                k: v
                for k, v in self.benchmarks.items()
                if any(k.startswith(prefix) for prefix in benchmark_filter)
            }

        if server_list == "all":
            server_pool = SERVER_POOL
        elif server_list == "":
            server_pool = random.sample(SERVER_POOL, k=len(self.benchmarks) // 10 + 1)
        else:
            server_pool = server_list.replace(" ", "").split(",")
            for server in server_pool:
                if server not in SERVER_POOL:
                    raise ValueError(f"Server {server} is not in the server pool")

        self.servers = [Server(hostname) for hostname in server_pool]

        self.checkpoints = []
        for benchmark_name, benchmark_config in self.benchmarks.items():
            for point, weight in benchmark_config["points"].items():
                self.checkpoints.append(
                    GCPT(
                        gcpt_bin_dir=self.emu_config.gcpt_path,
                        perf_base_dir=self.emu_config.result_path,
                        benchspec=benchmark_name,
                        point=point,
                        weight=weight,
                        gcc12Enable=True,
                    )
                )

        if not os.path.exists(self.emu_config.result_path):
            os.makedirs(self.emu_config.result_path, exist_ok=True)

    def run(self):
        failed_checkpoints = []

        with (
            tqdm(total=len(self.checkpoints), desc="  Assign") as assigned_bar,
            tqdm(total=len(self.checkpoints), desc="Complete") as completed_bar,
        ):
            for gcpt in self.checkpoints:
                # check completion
                for server in self.servers:
                    success, fail, _ = server.poll()
                    failed_checkpoints.extend(fail)
                    completed_bar.update(len(success) + len(fail))
                # assign task to the first available server
                for server in self.servers:
                    free_cores = server.get_free_cores(self.emu_config.threads)
                    if free_cores.free:
                        server.run_gcpt(gcpt, self.emu_config, free_cores)
                        assigned_bar.update(1)
                        break
                else:
                    # no available server, wait and retry
                    time.sleep(60)

            # wait for all servers to complete
            pending = True
            while pending:
                pending = False
                for server in self.servers:
                    success, fail, pending_list = server.poll()
                    failed_checkpoints.extend(fail)
                    completed_bar.update(len(success) + len(fail))
                    if len(pending_list) > 0:
                        pending = True
                if pending:
                    time.sleep(60)

            # report all failed jobs
        if len(failed_checkpoints) > 0:
            print("Failed checkpoints:")
            for gcpt in failed_checkpoints:
                print(f"- {gcpt}")

    def report(self):
        pass


def main():
    parser = argparse.ArgumentParser(description="Performance regression script")
    # emu
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
        "--warmup", "-W", default=20000000, type=int, help="warmup instr count"
    )
    parser.add_argument(
        "--max-instr", "-I", default=40000000, type=int, help="max instr count"
    )
    parser.add_argument(
        "--threads", "-T", default=8, type=int, help="number of emu threads"
    )

    # autorun
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
        "--run",
        action="store_true",
    )

    parser.add_argument(
        "--report",
        action="store_true",
    )

    args = parser.parse_args()

    # pre-checks
    if not os.path.isdir(args.gcpt_path):
        raise FileNotFoundError(f"gcpt_path is not a file: {args.gcpt_path}")
    if not os.path.isfile(args.json_path):
        raise FileNotFoundError(f"json_path is not a file: {args.json_path}")
    if not os.path.isfile(args.emu_path):
        raise FileNotFoundError(f"emu_path is not a file: {args.emu_path}")
    if args.nemu_so_path and not os.path.isfile(args.nemu_so_path):
        raise FileNotFoundError(f"nemu_so_path is not a file: {args.nemu_so_path}")

    os.makedirs(args.result_path, exist_ok=True)

    config = EmuConfig(
        gcpt_path=args.gcpt_path,
        json_path=args.json_path,
        emu_path=args.emu_path,
        result_path=args.result_path,
        nemu_so_path=args.nemu_so_path,
        warmup=args.warmup,
        max_instr=args.max_instr,
        threads=args.threads,
    )

    xiangshan = XiangShan(config, args.benchmarks, args.server_list)

    if args.run:
        xiangshan.run()

    if args.report:
        xiangshan.report()


if __name__ == "__main__":
    main()
