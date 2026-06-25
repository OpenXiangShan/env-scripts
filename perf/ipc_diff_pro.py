#!/usr/bin/env python3

'''
Author: Yanqin Li <liyanqin@bosc.ac.cn>

Usage:
    python3 ipc_diff_pro.py checkpoint.json base=/path/to/spec_dir new=/path/to/spec_dir -o ipc-compare.csv -j $(nproc)

Notes:
    The first SPEC directory is treated as the baseline.
    Additional SPEC directories are compared against that baseline.
'''

import argparse
import csv
import json
import os
import queue
import sys
from multiprocessing import Process, Queue

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from perf import PerfCounters


def load_ckpt_list(json_path):
    with open(json_path, "r") as f:
        data = json.load(f)
    ckpts = []
    for bench_name, info in data.items():
        for point, weight in info["points"].items():
            ckpts.append((bench_name, point, str(weight)))
    return ckpts


def read_ipc(sim_err_path):
    if not os.path.isfile(sim_err_path):
        return None
    counters = PerfCounters(sim_err_path)
    cycle = counters["clock_cycle"]
    instr = counters["commitInstr"]
    if cycle is None or instr is None:
        return None
    try:
        cycle = float(cycle)
        instr = float(instr)
        return instr / cycle if cycle != 0 else None
    except Exception:
        return None


def worker(task_q, result_q):
    while True:
        try:
            ckpt, sim_err = task_q.get_nowait()
        except queue.Empty:
            break
        result_q.put((ckpt, read_ipc(sim_err)))


def collect_ipc(spec_dir, json_path, jobs):
    ckpts = load_ckpt_list(json_path)
    task_q = Queue()
    result_q = Queue()
    for bench_name, point, weight in ckpts:
        ckpt = "_".join([bench_name, point, weight])
        sim_err = os.path.join(spec_dir, ckpt, "simulator_err.txt")
        task_q.put((ckpt, sim_err))

    procs = []
    for _ in range(jobs):
        p = Process(target=worker, args=(task_q, result_q))
        p.start()
        procs.append(p)
    for p in procs:
        p.join()

    ipc_map = {}
    for _ in range(len(ckpts)):
        ckpt, ipc = result_q.get()
        ipc_map[ckpt] = ipc
    return ipc_map


def parse_spec_dir_arg(arg):
    parts = arg.split("=", 1)
    if len(parts) != 2:
        raise ValueError("SPEC_DIR must be in name=path format")
    return parts[0], parts[1]


def compute_rates(row, base_idx=0):
    base = row[base_idx]
    rates = []
    for v in row[base_idx + 1:]:
        if base is None or v is None or base == 0:
            rates.append(None)
        else:
            rates.append((v / base - 1) * 100)
    return rates


def main():
    parser = argparse.ArgumentParser(description="Compare IPC across SPEC dirs")
    parser.add_argument("json_path", help="checkpoint json path")
    parser.add_argument("spec_dirs", nargs="+", help="name=SPEC_DIR, multiple")
    parser.add_argument("-o", "--output", default="ipc-compare.csv")
    parser.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 1)
    args = parser.parse_args()

    print("out path of IPC compare:", os.path.abspath(args.output))
    named_dirs = [parse_spec_dir_arg(x) for x in args.spec_dirs]
    ipc_by_dir = []
    for name, path in named_dirs:
        ipc_by_dir.append((name, path, collect_ipc(path, args.json_path, args.jobs)))

    all_ckpts = sorted(set().union(*[set(m.keys()) for _, _, m in ipc_by_dir]))

    rows = []
    for ckpt in all_ckpts:
        ipcs = [m.get(ckpt) for _, _, m in ipc_by_dir]
        rates = compute_rates(ipcs, 0)
        rows.append((ckpt, ipcs, rates))

    def sort_key(item):
        rates = item[2]
        if not rates or rates[0] is None:
            return -1
        return abs(rates[0])

    rows.sort(key=sort_key, reverse=True)

    header = ["ckpt"] + [name for name, _, _ in ipc_by_dir]
    if len(ipc_by_dir) > 1:
        base_name = ipc_by_dir[0][0]
        header += [f"pct {name}/{base_name}" for name, _, _ in ipc_by_dir[1:]]

    with open(args.output, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerow(["path"] + [path for _, path, _ in ipc_by_dir])
        for ckpt, ipcs, rates in rows:
            row = [ckpt] + ipcs
            if len(ipc_by_dir) > 1:
                row += rates
            writer.writerow(row)

    top_n = 3 if len(rows) >= 3 else len(rows)
    if top_n > 0:
        print("\nTop log files:")
        for ckpt, _, _ in rows[:top_n]:
            print(f"{ckpt}:")
            for _, path, _ in ipc_by_dir:
                print(os.path.join(path, ckpt, "simulator_err.txt"))
            print()


if __name__ == "__main__":
    main()
