#! /usr/bin/env python3

import argparse
import os
import re

class PerfManip(object):
    def __init__(self, name, counters, func):
        self.name = name
        self.counters = counters
        self.func = func

def load_perf(filename):
    perf_re = re.compile(r'.*\[PERF \]\[time=\s*\d*\] ((\w*(\.|))*): (\w*)\s*,\s*(\d*)')
    all_perf_counters = dict()
    with open(filename) as f:
        for line in f:
            perf_match = perf_re.match(line)
            if perf_match:
                perf_name = ".".join([str(perf_match.group(1)), str(perf_match.group(4))])
                perf_value = str(perf_match.group(5))
                all_perf_counters[perf_name] = perf_value
    return all_perf_counters

def calc(counters, target, func):
    numbers = map(lambda name: int(counters[name]), target)
    return str(func(*numbers))

def get_all_manip():
    all_manip = []
    ipc = PerfManip(
        name = "global.IPC",
        counters = ["TOP.SimTop.l_soc.core_with_l2.core.ctrlBlock.roq.clock_cycle",
        "TOP.SimTop.l_soc.core_with_l2.core.ctrlBlock.roq.commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    all_manip.append(ipc)
    block_fraction = PerfManip(
        name = "global.intDispatch.blocked_fraction",
        counters = ["TOP.SimTop.l_soc.core_with_l2.core.ctrlBlock.dispatch.intDispatch.blocked",
        "TOP.SimTop.l_soc.core_with_l2.core.ctrlBlock.dispatch.intDispatch.in"],
        func = lambda blocked, dpin: blocked * 1.0 / dpin
    )
    all_manip.append(block_fraction)
    return all_manip

def main(pfiles, output_file):
    all_perf = []
    all_manip = get_all_manip()
    for filename in pfiles:
        perf = load_perf(filename)
        for manip in all_manip:
            perf[manip.name] = calc(perf, manip.counters, manip.func)
        all_perf.append(perf)
    all_names = sorted(list(set().union(*list(map(lambda s: s.keys(), all_perf)))))
    # all_sources = list(map(lambda x: os.path.split(x)[1], pfiles))
    all_sources = pfiles
    output_lines = [",".join([""] + all_sources) + "\n"]
    for name in all_names:
        output_lines.append(",".join([name] + list(map(lambda col: col[name] if name in col else "", all_perf))) + "\n")
    with open(output_file, "w") as f:
        f.writelines(output_lines)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    parser.add_argument('pfiles', metavar='filename', type=str, nargs='+',
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output file')

    args = parser.parse_args()

    main(args.pfiles,args.output)

