import argparse
import json
import logging
import os
import random
import time
from tqdm import tqdm
from tqdm.contrib.logging import logging_redirect_tqdm

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
    "open07",
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
STUCK_THRESHOLD = 10 * 3600  # 10 hours

SPEC06_INT_BENCHMARKS = [
    "perlbench",
    "bzip2",
    "gcc",
    "mcf",
    "gobmk",
    "hmmer",
    "sjeng",
    "libquantum",
    "h264ref",
    "omnetpp",
    "astar",
    "xalancbmk",
]

SPEC06_FP_BENCHMARKS = [
    "bwaves",
    "gamess",
    "milc",
    "zeusmp",
    "gromacs",
    "cactusADM",
    "leslie3d",
    "namd",
    "dealII",
    "soplex",
    "povray",
    "Calculix",
    "GemsFDTD",
    "tonto",
    "lbm",
    "wrf",
    "sphinx3",
]


class XiangShan:
    def __init__(
        self,
        gcpt_path: str,
        json_path: str,
        result_path: str,
        benchmarks: str,
    ):
        self.gcpt_path = gcpt_path
        self.json_path = json_path
        self.result_path = result_path

        with open(json_path, "r", encoding="utf-8") as f:
            self.benchmarks = json.load(f)

        if benchmarks != "":
            benchmark_filter = benchmarks.replace(" ", "").split(",")

            # expand alias
            if "int06" in benchmark_filter:
                benchmark_filter.extend(SPEC06_INT_BENCHMARKS)
            if "fp06" in benchmark_filter:
                benchmark_filter.extend(SPEC06_FP_BENCHMARKS)

            self.benchmarks = {
                k: v
                for k, v in self.benchmarks.items()
                if any(k.startswith(prefix) for prefix in benchmark_filter)
            }

        self.checkpoints: list[GCPT] = []
        for benchmark_name, benchmark_config in self.benchmarks.items():
            for point, weight in benchmark_config["points"].items():
                self.checkpoints.append(
                    GCPT(
                        gcpt_path=gcpt_path,
                        result_path=result_path,
                        benchmark=benchmark_name,
                        checkpoint=point,
                        weight=weight,
                    )
                )

        self.servers: list[Server] = []

    def __init_servers(
        self,
        emu_path: str,
        nemu_so_path: str | None,
        server_list: str,
    ) -> None:
        if server_list == "all":
            server_pool = SERVER_POOL
        elif server_list == "":
            desired_sever_num = min(len(self.checkpoints) // 64 + 1, len(SERVER_POOL))
            server_pool = random.sample(SERVER_POOL, k=desired_sever_num)
        else:
            server_pool = server_list.replace(" ", "").split(",")
            for server in server_pool:
                if server not in SERVER_POOL:
                    raise ValueError(f"Server {server} is not in the server pool")

        self.servers = [
            Server(hostname, emu_path, nemu_so_path) for hostname in server_pool
        ]

        open_server = [s for s in self.servers if s.hostname.startswith("open")]
        if open_server:
            logging.info("Using open servers, initializing binaries and libs...")
            target_result_path = self.result_path.replace(
                "/nfs/home/cirunner", "/nfs/home/ci-runner"
            )
            target_emu_path = os.path.join(target_result_path, "emu")
            target_nemu_so_path = None

            open_server[0].initialize_open(emu_path, target_emu_path)

            if nemu_so_path is not None:
                target_nemu_so_path = os.path.join(target_result_path, "nemu.so")
                open_server[0].initialize_open(nemu_so_path, target_nemu_so_path)

            for server in open_server:
                server.emu_path = target_emu_path
                server.nemu_so_path = target_nemu_so_path

    def __run(
        self,
        emu_config: EmuConfig,
    ) -> None:
        logging.info(
            "Start Running %d checkpoints on %d servers",
            len(self.checkpoints),
            len(self.servers),
        )
        logging.debug(
            "Server list: %s", ", ".join(map(lambda s: s.hostname, self.servers))
        )
        failed_checkpoints: list[str] = []

        with (
            tqdm(
                total=len(self.checkpoints), desc="  Assign", miniters=1, leave=True
            ) as assigned_bar,
            tqdm(
                total=len(self.checkpoints), desc="Complete", miniters=1, leave=True
            ) as completed_bar,
            logging_redirect_tqdm(),
        ):

            def poll_servers() -> bool:
                pending = False
                for server in self.servers:
                    success, fail, pending_list = server.poll()
                    failed_checkpoints.extend(fail)
                    completed_bar.update(len(success) + len(fail))
                    if len(pending_list) > 0:
                        pending = True
                return pending

            for gcpt in self.checkpoints:
                # check state from disk
                state = gcpt.refresh_state()
                match state:
                    case GCPT.State.RUNNING:
                        logging.warning(
                            "Checkpoint %s is in RUNNING state, there can be another process running it",
                            gcpt,
                        )
                        if (
                            time.time() - os.path.getmtime(gcpt.get_stdout_path())
                            > STUCK_THRESHOLD
                            and time.time() - os.path.getmtime(gcpt.get_stderr_path())
                            > STUCK_THRESHOLD
                        ):
                            logging.warning(
                                "Checkpoint %s no output for more than %d seconds, try restarting it",
                                gcpt,
                                STUCK_THRESHOLD,
                            )
                            state = GCPT.State.NONE
                        else:
                            assigned_bar.update(1)
                            continue

                    case GCPT.State.FINISHED | GCPT.State.ABORTED:
                        logging.info(
                            "Checkpoint %s is already in state %s, skipping assignment",
                            gcpt,
                            state,
                        )
                        assigned_bar.update(1)
                        completed_bar.update(1)
                        continue

                # loop until task is assigned
                assigned = False
                while not assigned:
                    # assign task to the first available server
                    for server in self.servers:
                        free_cores = server.get_free_cores(emu_config.threads)
                        if free_cores.free:
                            server.run_gcpt(gcpt, emu_config, free_cores)
                            # shuffle for load balancing, unless current has some cached free cores
                            if not server.free_info.free:
                                random.shuffle(self.servers)
                            assigned = True
                            assigned_bar.update(1)
                            break
                    else:
                        # no available server, wait and retry
                        logging.debug("No available server, waiting for 60 seconds...")
                        time.sleep(60)

                    # check completion
                    poll_servers()

            # wait for all servers to complete
            logging.info("All checkpoints assigned, waiting for completion...")
            pending = poll_servers()
            while pending:
                logging.debug(
                    "Waiting for all servers to complete, checking again in 60 seconds..."
                )
                time.sleep(60)
                pending = poll_servers()

        # report all failed jobs
        if len(failed_checkpoints) > 0:
            logging.error("Failed checkpoints:")
            for gcpt in failed_checkpoints:
                logging.error("- %s", gcpt)

    def __stop(self):
        logging.info("Stopping all servers...")
        for server in self.servers:
            server.stop()

    def run(
        self,
        emu_path: str,
        nemu_so_path: str | None,
        server_list: str,
        emu_config: EmuConfig,
    ) -> None:
        try:
            self.__init_servers(
                emu_path,
                nemu_so_path,
                server_list,
            )
            self.__run(emu_config)
        except KeyboardInterrupt as e:
            logging.info("SIGINT received")
            self.__stop()
            raise KeyboardInterrupt("Run interrupted by user") from e
        except Exception as e:
            logging.critical("Critical failure")
            self.__stop()
            raise e

    def report(self):
        raise NotImplementedError("use xs_autorun_multiServer.py instead")

    def reset_running_gcpt(self):
        num = 0
        for gcpt in self.checkpoints:
            state = gcpt.refresh_state()
            if state == GCPT.State.RUNNING:
                logging.info("Resetting GCPT %s", gcpt)
                num += 1
                os.remove(gcpt.get_stdout_path())
                os.remove(gcpt.get_stderr_path())
                os.rmdir(gcpt.get_result_path())
        logging.info("Reset %d RUNNING GCPTs", num)


def main():
    parser = argparse.ArgumentParser(description="Performance regression script")

    # general task configs
    parser.add_argument(
        "--gcpt-path", type=str, required=True, help="Path to the GCPT checkpoints"
    )
    parser.add_argument(
        "--json-path", type=str, required=True, help="Path to the GCPT json"
    )
    parser.add_argument(
        "--result-path", type=str, required=True, help="Path to store the results"
    )

    # run emu configs
    parser.add_argument("--emu-path", type=str, help="Path to the emu")
    parser.add_argument("--nemu-so-path", type=str, help="Path to NEMU diff so")
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

    # function options
    parser.add_argument(
        "--run",
        action="store_true",
    )

    parser.add_argument(
        "--report",
        action="store_true",
    )

    parser.add_argument(
        "--reset-running",
        action="store_true",
        help="Reset checkpoints in RUNNING state by removing their output files",
    )

    # debug options
    parser.add_argument(
        "--log-level",
        type=str,
        default="INFO",
        help="Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)",
    )

    args = parser.parse_args()

    os.makedirs(args.result_path, exist_ok=True)

    # setup logging
    file_handler = logging.FileHandler(os.path.join(args.result_path, "runner_log.txt"))
    file_handler.setLevel(logging.NOTSET)

    stdout_handler = logging.StreamHandler()
    stdout_handler.setLevel(args.log_level.upper())

    logging.basicConfig(
        handlers=[file_handler, stdout_handler],
        force=True,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    # pre-checks
    if not os.path.isdir(args.gcpt_path):
        raise FileNotFoundError(f"gcpt_path is not a file: {args.gcpt_path}")
    if not os.path.isfile(args.json_path):
        raise FileNotFoundError(f"json_path is not a file: {args.json_path}")


    xiangshan = XiangShan(
        gcpt_path=args.gcpt_path,
        json_path=args.json_path,
        result_path=args.result_path,
        benchmarks=args.benchmarks,
    )

    if args.reset_running:
        xiangshan.reset_running_gcpt()

    if args.run:
        if not args.emu_path:
            raise ValueError("emu_path is required for --run")
        if not os.path.isfile(args.emu_path):
            raise FileNotFoundError(f"emu_path is not a file: {args.emu_path}")
        if args.nemu_so_path and not os.path.isfile(args.nemu_so_path):
            raise FileNotFoundError(f"nemu_so_path is not a file: {args.nemu_so_path}")
        xiangshan.run(
            emu_path=args.emu_path,
            nemu_so_path=args.nemu_so_path,
            server_list=args.server_list,
            emu_config=EmuConfig(
                warmup=args.warmup,
                max_instr=args.max_instr,
                threads=args.threads,
            ),
        )

    if args.report:
        xiangshan.report()


if __name__ == "__main__":
    main()
