import argparse
import csv
import os
import sys

sys.path.append('../perf')
import perf

from github import Github


def get_recent_commits(token):
    g = Github(token)

    xs = g.get_repo("OpenXiangShan/XiangShan")
    actions = xs.get_workflow_runs(branch="master")
    recent_commits = list(map(lambda a: a.head_sha, actions[:10]))
    print(recent_commits)
    return recent_commits

def write_to_csv(rows, filename):
    with open(filename, 'w') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerows(rows)

def get_all_manip():
    all_manip = []
    ipc = perf.PerfManip(
        name = "global.IPC",
        counters = [f"ctrlBlock.roq.clock_cycle",
        f"ctrlBlock.roq.commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    all_manip.append(ipc)
    return all_manip

def main(token, output_csv):
    commits = get_recent_commits(token)
    base_dir = "/bigdata/xs-perf"
    results = {}
    benchmarks = []
    for commit in commits:
        perf_path = os.path.join(base_dir, commit)
        if not os.path.isdir(perf_path):
            print(f"{commit} perf data not found. Skip.")
            continue
        results[commit] = {}
        for filename in os.listdir(perf_path):
            if filename.endswith(".log"):
                benchmark = filename[:-4]
                counters = perf.PerfCounters(os.path.join(perf_path, filename))
                counters.add_manip(get_all_manip())
                benchmarks.append(benchmark)
                results[commit][benchmark] = counters["global.IPC"]
    benchmarks = sorted(list(set(benchmarks)))
    all_rows = [["commit"] + benchmarks]
    for commit in results:
        all_rows.append([commit] + [results.get(commit, dict()).get(bench,"") for bench in benchmarks])
    write_to_csv(all_rows, output_csv)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='stargazers analysis')
    parser.add_argument('--token', '-t', default=None, help='github token')
    parser.add_argument('--output', '-o', default=None, help='output csv file')

    args = parser.parse_args()

    main(args.token, args.output)

