import argparse
import hashlib
import json
import logging
from math import isnan
from multiprocessing import Process, Queue
import os
from pathlib import Path
import random
import re
import time

from modules.gcpt import GCPT
from modules.lock import Heartbeat, FakeLock
from modules.server import Server
from modules.spec import Spec, get_int_benchmarks, get_fp_benchmarks
from modules.types import EmuConfig, FreeCoreInfo
from modules.tracker import Tracker
from modules.utils import geomean

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

HEARTBEAT_INTERVAL = 60


class XiangShan:
    def __init__(
        self,
        gcpt_path: Path,
        json_path: Path,
        result_path: Path,
        benchmarks: str,
    ):
        self.gcpt_path = gcpt_path
        self.json_path = json_path
        self.result_path = result_path

        with json_path.open("r", encoding="utf-8") as f:
            self.benchmarks = json.load(f)

        if benchmarks != "":
            benchmark_filter = benchmarks.replace(" ", "").split(",")

            # expand alias
            if m := re.match(r"int(\d\d)", " ".join(benchmark_filter)):
                benchmark_filter.extend(get_int_benchmarks(Spec.Version(m.group(1))))
            if m := re.match(r"fp(\d\d)", " ".join(benchmark_filter)):
                benchmark_filter.extend(get_fp_benchmarks(Spec.Version(m.group(1))))

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
                        weight=float(weight),
                    )
                )

        self.servers: list[Server] = []

        self.tracker = Tracker(
            total=len(self.checkpoints), keys=["assigned", "completed"], with_keys=False
        )

    def __infer_spec_version(self) -> Spec.Version | None:
        # try infer from gcpt_path name
        if m := re.search(r"spec(\d\d)", str(self.gcpt_path)):
            return Spec.Version(m.group(1))

        # try infer from benchmarks
        with self.json_path.open("r", encoding="utf-8") as f:
            benchmarks = json.load(f)
        for version in Spec.Version:
            example = get_int_benchmarks(version)[0]
            if example in benchmarks:
                return version

        return None

    def __init_servers(
        self,
        emu_path: Path,
        nemu_so_path: Path | None,
        server_list: str,
    ) -> None:
        # Do not use open servers unless explicitly specified, as they are too slow
        if server_list == "all":
            server_pool = list(filter(lambda s: s.startswith("node"), SERVER_POOL))
        elif server_list == "open":
            server_pool = list(filter(lambda s: s.startswith("open"), SERVER_POOL))
            desired_server_num = min(len(self.checkpoints) // 64 + 1, len(server_pool))
            server_pool = random.sample(server_pool, k=desired_server_num)
        elif server_list == "node" or server_list == "":
            server_pool = list(filter(lambda s: s.startswith("node"), SERVER_POOL))
            desired_server_num = min(len(self.checkpoints) // 64 + 1, len(server_pool))
            server_pool = random.sample(server_pool, k=desired_server_num)
        else:
            server_pool = server_list.replace(" ", "").split(",")
            for server in server_pool:
                if server not in SERVER_POOL:
                    raise ValueError(f"Server {server} is not in the server pool")

        self.servers = [
            Server(hostname, emu_path, self.tracker, nemu_so_path)
            for hostname in server_pool
        ]

        open_server = [s for s in self.servers if s.hostname.startswith("open")]
        if open_server:
            logging.info("Using open servers, initializing binaries and libs...")
            target_result_path = Path(
                str(self.result_path).replace(
                    "/nfs/home/cirunner", "/nfs/home/ci-runner"
                )
            )
            target_emu_path = target_result_path / emu_path.name
            target_nemu_so_path = None

            open_server[0].initialize_open(emu_path, target_emu_path)

            if nemu_so_path is not None:
                target_nemu_so_path = target_result_path / nemu_so_path.name
                open_server[0].initialize_open(nemu_so_path, target_nemu_so_path)

            for server in open_server:
                server.emu_path = target_emu_path
                server.nemu_so_path = target_nemu_so_path

    def __run(
        self,
        emu_config: EmuConfig,
    ) -> None:
        logging.info(
            "Start running %d checkpoints on %d servers",
            len(self.checkpoints),
            len(self.servers),
        )
        logging.debug(
            "Server list: %s", ", ".join(map(lambda s: s.hostname, self.servers))
        )
        failed_checkpoints: list[str] = []

        def poll_servers() -> bool:
            pending = False
            for server in self.servers:
                success, fail, pending_list = server.poll()
                failed_checkpoints.extend(fail)
                self.tracker.step("completed", len(success) + len(fail))
                if len(pending_list) > 0:
                    pending = True
            return pending

        for gcpt in self.checkpoints:
            # check state from disk
            state = gcpt.refresh_state()
            if emu_config.dry_run:
                state = GCPT.State.NONE  # ignore existing state in dry-run mode
            match state:
                case GCPT.State.RUNNING:
                    self.tracker.warning(
                        "%s is RUNNING, resetting it",
                        gcpt,
                    )
                    state = GCPT.State.NONE

                case GCPT.State.FINISHED | GCPT.State.ABORTED:
                    self.tracker.info(
                        "%s is %s, skipping",
                        gcpt,
                        state,
                    )
                    self.tracker.step("assigned", 1)
                    self.tracker.step("completed", 1)
                    continue

            # loop until task is assigned
            assigned = False
            while not assigned:
                # check completion
                poll_servers()
                # assign task to the first available server
                free_server = None
                free_cores = FreeCoreInfo.none()
                # check if a server has enough cached free core
                for server in self.servers:
                    free_cores = server.get_cached_free_cores(emu_config.threads)
                    if free_cores.free:
                        free_server = server
                        self.tracker.debug("Get cached free cores")
                        break
                # no, check if a server can alloc enough free core
                else:
                    for server in self.servers:
                        free_cores = server.get_free_cores(emu_config.threads)
                        if free_cores.free:
                            self.tracker.debug("Allocated free cores")
                            free_server = server
                            break
                # still no, wait and retry
                if free_server is None:
                    self.tracker.debug("No available server, waiting for 60 seconds...")
                    time.sleep(60)
                    continue

                # start job
                free_server.run_gcpt(gcpt, emu_config, free_cores)
                # shuffle for load balancing
                random.shuffle(self.servers)
                assigned = True
                self.tracker.step("assigned", 1)

        # wait for all servers to complete
        self.tracker.info("All checkpoints assigned, waiting for completion...")
        pending = poll_servers()
        while pending:
            self.tracker.debug("Still running, checking again in 60 seconds...")
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
        emu_path: Path,
        nemu_so_path: Path | None,
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

    def report(
        self,
        frequency: float,
        override_version: str | None = None,
    ) -> None:
        version = (
            Spec.Version(override_version)
            if override_version is not None
            else self.__infer_spec_version()
        )

        if version is None:
            logging.critical(
                "Failed to infer SPEC version from gcpt_path, please specify it with --spec-version"
            )
            return

        spec = Spec(version)

        # collect checkpoint -> benchmark, i.e. astar_biglakes_2972, astar_biglakes_3421 -> astar_biglakes
        result_queue = Queue()
        failed_queue = Queue()

        def collect_benchmark(benchmark: str) -> None:
            weighted_cpi_sum = 0.0
            weight_sum = 0.0

            for gcpt in self.checkpoints:
                if gcpt.benchmark != benchmark:
                    continue
                cpi = gcpt.get_cpi()
                if cpi is None:
                    logging.warning("No valid result for checkpoint %s, skipping", gcpt)
                    failed_queue.put(str(gcpt))
                    continue
                # do not need lock as each threading is responsible for a different benchmark
                weighted_cpi_sum += cpi * gcpt.weight
                weight_sum += gcpt.weight

            result_queue.put((benchmark, weighted_cpi_sum, weight_sum))

        processes = [
            Process(target=collect_benchmark, args=(benchmark,))
            for benchmark in self.benchmarks.keys()
        ]
        for p in processes:
            p.start()
        for p in processes:
            p.join()

        benchmark_weighted_cpis = {}
        benchmark_weights = {}
        while not result_queue.empty():
            benchmark, weighted_cpi, weight = result_queue.get()
            if weight == 0:
                logging.warning(
                    "Total weight is 0 for benchmark %s, skipping", benchmark
                )
            benchmark_weighted_cpis[benchmark] = weighted_cpi
            benchmark_weights[benchmark] = weight

        failed_checkpoints = []
        while not failed_queue.empty():
            failed_checkpoints.append(failed_queue.get())

        benchmark_times = {
            benchmark: (  # weighted_avg_cpi * inst / freq
                benchmark_weighted_cpis[benchmark]
                / benchmark_weights[benchmark]
                * float(self.benchmarks[benchmark]["insts"])
                / (frequency * 1e9)
            )
            for benchmark in self.benchmarks.keys()
        }

        def collect_benchmark_group(
            group: str,
        ) -> tuple[float, float, float, float]:  # run_time, ref_time, score, coverage
            run_time = 0.0
            ref_time = spec.get_ref_time(group)
            if ref_time is None:
                logging.warning(
                    "No valid reftime for benchmark group %s, skipping", group
                )
                return 0.0, 0.0, 0.0, 0.0

            weighted_coverage_sum = 0.0
            instruction_sum = 0.0

            for benchmark in self.benchmarks.keys():
                if not benchmark.startswith(group):
                    continue
                run_time += benchmark_times[benchmark]
                weighted_coverage_sum += benchmark_weights[benchmark] * float(
                    self.benchmarks[benchmark]["insts"]
                )
                instruction_sum += float(self.benchmarks[benchmark]["insts"])

            if instruction_sum == 0:
                logging.warning(
                    "Total instruction count is 0 for benchmark group %s, skipping",
                    group,
                )
                return run_time, ref_time, float("nan"), float("nan")

            coverage = weighted_coverage_sum / instruction_sum
            score = ref_time / run_time / frequency

            return run_time, ref_time, score, coverage

        def render_line(
            name: str,
            run_time: float,
            ref_time: float,
            score: float,
            coverage: float,
        ) -> None:
            print(
                f"{name:<19s} {run_time:>8.3f} {ref_time:>8.0f} {score:>8.3f} {coverage:>8.3f}",
            )

        def render_groups(
            name: str, group_names: list[str]
        ) -> tuple[list[float], list[float]]:
            scores = []
            coverages = []
            for group in group_names:
                fullname = spec.get_benchmark_fullname(group)
                run_time, ref_time, score, coverage = collect_benchmark_group(group)
                scores.append(score)
                coverages.append(coverage)
                render_line(fullname, run_time, ref_time, score, coverage)
            render_line(
                f"{name}/GHz", float("nan"), float("nan"), geomean(scores), float("nan")
            )
            return scores, coverages

        print("======================== Score ========================")
        print("                        time ref_time    score coverage")
        int_scores, int_coverages = render_groups(
            spec.get_int_name(), spec.get_int_benchmarks()
        )
        fp_scores, fp_coverages = render_groups(
            spec.get_fp_name(), spec.get_fp_benchmarks()
        )
        final_name = spec.get_name()
        final_geomean = geomean(int_scores + fp_scores)
        render_line(final_name, float("nan"), float("nan"), final_geomean, float("nan"))
        print()
        print(f"{final_name}/GHz:    {final_geomean:.3f}")
        print(f"{final_name}@{frequency:2.1f}GHz: {final_geomean * frequency:.3f}")
        print()
        print("================ Other Information ===============")
        final_coverage = min(c for c in int_coverages + fp_coverages if not isnan(c))
        final_checkpoints = len(self.checkpoints)
        final_success_checkpoints = final_checkpoints - len(failed_checkpoints)
        print(f"Checkpoint Version : {self.gcpt_path}")
        print(f"DRAMSIM3 Config    : {self.checkpoints[0].get_dramsim3_config()}")
        print(f"Data Directory     : {self.result_path.resolve()}")
        print(f"Minimal Coverage   : {final_coverage:.2f}/1.00")
        print(f"Checkpoints Number : {final_success_checkpoints}/{final_checkpoints}")
        print()
        print("=============== Failed Checkpoints ===============")
        print(json.dumps(failed_checkpoints, indent=2, separators=(",", ": ")))

    def reset_running_gcpt(self):
        num = 0
        for gcpt in self.checkpoints:
            state = gcpt.refresh_state()
            if state == GCPT.State.RUNNING:
                logging.info("Resetting GCPT %s", gcpt)
                num += 1
                gcpt.stdout_path.unlink()
                gcpt.stderr_path.unlink()
                gcpt.result_path.rmdir()
                gcpt.clear_state()
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
    parser.add_argument(
        "--cst-file",
        type=str,
        default="",
        help="Path to custom constantin file path (empty for default init setting)",
    )

    # report configs
    parser.add_argument(
        "--frequency",
        type=float,
        default=3.0,
        help="CPU frequency in GHz for performance score calculation, default 3.0GHz",
    )
    parser.add_argument(
        "--spec-version",
        type=str,
        default=None,
        help="Specify SPEC version for report, empty for auto inference from gcpt_path",
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
        "--dry-run",
        action="store_true",
        help="Run emu with only 2000 instructions to check the function",
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

    gcpt_path = Path(args.gcpt_path)
    json_path = Path(args.json_path)
    result_path = Path(args.result_path)

    result_path.mkdir(parents=True, exist_ok=True)

    log_path = result_path / f"runner_{time.strftime('%Y-%m-%d_%H-%M-%S')}.log"
    # if log path is not writable, disable logging to file,
    # to prevent the whole script from failing due to logging error
    if not os.access(result_path, os.W_OK):
        log_path = None

    # setup logging
    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s - %(levelname)5s - %(message)s",
        handlers=[
            logging.StreamHandler(),
        ]
        + (
            [logging.FileHandler(log_path, encoding="utf-8")]
            if log_path is not None
            else []
        ),
    )
    for handler in logging.root.handlers:
        if isinstance(handler, logging.StreamHandler):
            handler.setLevel(logging.INFO)
        if isinstance(handler, logging.FileHandler):
            handler.setLevel(logging.DEBUG)

    if log_path is None:
        logging.warning(
            "Log path %s is not writable, logging to file is disabled", result_path
        )

    # pre-checks
    if not gcpt_path.is_dir():
        raise FileNotFoundError(f"gcpt_path is not a directory: {gcpt_path}")
    if not json_path.is_file():
        raise FileNotFoundError(f"json_path is not a file: {json_path}")

    # if only args.report is specified, no need to acquire lock as it is read-only operation.
    need_lock = args.run or args.dry_run or args.reset_running
    if not need_lock:
        logging.info("Only report is requested, skipping lock acquisition")
    # add lock per (result_path, gcpt_path) pair
    # to prevent the same checkpoint from being run by multiple instances with same result_path simultaneously
    gcpt_hash = hashlib.sha256(str(gcpt_path.resolve()).encode()).hexdigest()[:8]
    lock = (
        Heartbeat(f"trigger_{gcpt_hash}", result_path, HEARTBEAT_INTERVAL)
        if need_lock
        else FakeLock()
    )
    while not lock.try_acquire():
        logging.info(
            "Another instance is running in the same directory (%s), waiting for %d seconds...",
            result_path,
            HEARTBEAT_INTERVAL,
        )
        time.sleep(HEARTBEAT_INTERVAL)

    try:
        xiangshan = XiangShan(
            gcpt_path=gcpt_path,
            json_path=json_path,
            result_path=result_path,
            benchmarks=args.benchmarks,
        )

        if args.reset_running:
            xiangshan.reset_running_gcpt()

        if args.run or args.dry_run:
            emu_path = Path(args.emu_path) if args.emu_path else None
            nemu_so_path = Path(args.nemu_so_path) if args.nemu_so_path else None
            cst_file = Path(args.cst_file) if args.cst_file else None

            if emu_path is None:
                raise ValueError("emu_path is required for --run")
            if not emu_path.is_file():
                raise FileNotFoundError(f"emu_path is not a file: {emu_path}")
            if nemu_so_path is not None and not nemu_so_path.is_file():
                raise FileNotFoundError(f"nemu_so_path is not a file: {nemu_so_path}")
            if cst_file is not None and not cst_file.is_file():
                raise FileNotFoundError(f"cst_file does not exist: {cst_file}")
            xiangshan.run(
                emu_path=emu_path,
                nemu_so_path=nemu_so_path,
                server_list=args.server_list,
                emu_config=EmuConfig(
                    warmup=args.warmup,
                    max_instr=args.max_instr,
                    threads=args.threads,
                    cst_file=cst_file,
                    dry_run=args.dry_run,
                ),
            )

        if args.report:
            xiangshan.report(args.frequency, args.spec_version)

    finally:
        lock.release()


if __name__ == "__main__":
    main()
