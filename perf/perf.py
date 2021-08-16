#! /usr/bin/env python3

import argparse
import csv
import os
import re


class PerfManip(object):
    def __init__(self, name, counters, func):
        self.name = name
        self.counters = counters
        self.func = func


class PerfCounters(object):
    perf_re = re.compile(r'.*\[PERF \]\[time=\s*\d*\] ((\w*(\.|))*): (\w*)\s*,\s*(\d*)')

    def __init__(self, filename):
        all_perf_counters = dict()
        with open(filename) as f:
            for line in f:
                perf_match = self.perf_re.match(line)
                if perf_match:
                    perf_name = ".".join([str(perf_match.group(1)), str(perf_match.group(4))])
                    perf_value = str(perf_match.group(5))
                    all_perf_counters[perf_name] = perf_value
        prefix_length = len(os.path.commonprefix(list(all_perf_counters.keys())))
        updated_perf = dict()
        for key in all_perf_counters:
            updated_perf[key[prefix_length:].replace("xs_", "")] = all_perf_counters[key]
        self.counters = updated_perf

    def add_manip(self, all_manip):
        for manip in all_manip:
            numbers = map(lambda name: int(self.counters[name]), manip.counters)
            self.counters[manip.name] = str(manip.func(*numbers))

    def get_counters(self):
        return self.counters

    def keys(self):
        return self.counters.keys()

    def __getitem__(self, index):
        return self.counters[index]

    def __iter__(self):
        return self.counters.__iter__()

def get_all_manip():
    all_manip = []
    old_data = False
    if old_data:
        soc = "TOP.XSSimSoC.soc"
        core = ".".join([soc, "xs_core"])
    else:
        soc = "TOP.SimTop.l_soc"
        core = ".".join([soc, "core_with_l2.core"])
    ipc = PerfManip(
        name = "global.IPC",
        counters = [f"{core}.ctrlBlock.roq.clock_cycle",
        f"{core}.ctrlBlock.roq.commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    # all_manip.append(ipc)
    block_fraction = PerfManip(
        name = "global.intDispatch.blocked_fraction",
        counters = [f"{core}.ctrlBlock.dispatch.intDispatch.blocked",
        f"{core}.ctrlBlock.dispatch.intDispatch.in"],
        func = lambda blocked, dpin: blocked * 1.0 / dpin
    )
    # all_manip.append(block_fraction)
    icache_miss_rate = PerfManip(
        name = "global.icache_miss_rate",
        counters = [f"{core}.frontend.ifu.icache.req", f"{core}.frontend.ifu.icache.miss"],
        func = lambda req, miss: miss / req
    )
    # all_manip.append(icache_miss_rate)
    dtlb_miss_rate = PerfManip(
        name = "global.dtlb_miss_rate",
        counters = [f"{core}.memBlock.LoadUnit_0.load_s1.in", f"{core}.memBlock.LoadUnit_0.load_s1.tlb_miss",
            f"{core}.memBlock.LoadUnit_1.load_s1.in", f"{core}.memBlock.LoadUnit_1.load_s1.tlb_miss"],
        func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2)
    )
    # all_manip.append(dtlb_miss_rate)
    dcache_load_miss_rate = PerfManip(
        name = "global.dcache_load_miss_rate",
        counters = [f"{core}.memBlock.LoadUnit_0.load_s2.in", f"{core}.memBlock.LoadUnit_0.load_s2.dcache_miss",
            f"{core}.memBlock.LoadUnit_1.load_s2.in", f"{core}.memBlock.LoadUnit_1.load_s2.dcache_miss"],
        func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2)
    )
    # all_manip.append(dcache_load_miss_rate)
    branch_mispred = PerfManip(
        name = "global.branch_mispred",
        counters = [f"{core}.ctrlBlock.ftq.BpRight", f"{core}.ctrlBlock.ftq.BpWrong"],
        func = lambda right, wrong: wrong / (right + wrong)
    )
    # all_manip.append(branch_mispred)
    return all_manip


def merge_perf_counters(filenames, all_perf):
    all_names = sorted(list(set().union(*list(map(lambda s: s.keys(), all_perf)))))
    all_sources = filenames
    output_rows = [[""] + all_sources]
    for name in all_names:
        output_rows.append([name] + list(map(lambda col: col[name] if name in col else "", all_perf)))
    return output_rows


def main(pfiles, output_file):
    all_perf = []
    all_manip = get_all_manip()
    for filename in pfiles:
        perf = PerfCounters(filename)
        perf.add_manip(all_manip)
        all_perf.append(perf)
    output_rows = merge_perf_counters(pfiles, all_perf)
    with open(output_file, 'w') as csvfile:
        csvwriter = csv.writer(csvfile)
        csvwriter.writerows(output_rows)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    parser.add_argument('pfiles', metavar='filename', type=str, nargs='*', default=None,
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output file')
    parser.add_argument('--filelist', '-f', default=None, help="filelist")

    args = parser.parse_args()

    if args.filelist is not None:
        with open(args.filelist) as f:
            args.pfiles = list(map(lambda x: x.strip(), f.readlines()))

    main(args.pfiles, args.output)

