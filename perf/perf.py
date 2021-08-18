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
    perf_re = re.compile(r'.*\[PERF \]\[time=\s*\d*\] ((\w*(\.|))*): (.*)\s*,\s*(\d*)')

    def __init__(self, filename):
        all_perf_counters = dict()
        with open(filename) as f:
            for line in f:
                perf_match = self.perf_re.match(line)
                if perf_match:
                    perf_name = ".".join([str(perf_match.group(1)), str(perf_match.group(4))])
                    perf_value = str(perf_match.group(5))
                    perf_name = perf_name.replace(" ", "_").replace("'", "")
                    all_perf_counters[perf_name] = perf_value
        prefix_length = len(os.path.commonprefix(list(all_perf_counters.keys())))
        updated_perf = dict()
        for key in all_perf_counters:
            updated_perf[key[prefix_length:]] = all_perf_counters[key]
        self.counters = updated_perf

    def add_manip(self, all_manip):
        for manip in all_manip:
            if None in map(lambda name: self[name], manip.counters):
                continue
            numbers = map(lambda name: int(self[name]), manip.counters)
            self.counters[manip.name] = str(manip.func(*numbers))

    def get_counter(self, name, strict=False):
        key = self.counters.get(name, "")
        if strict or key != "":
            return key
        matched_keys = list(filter(lambda k: k.endswith(name), self.keys()))
        if len(matched_keys) == 0:
            return None
        if len(matched_keys) > 1:
            print(f"more than one found for {name}!! Use the first one.")
        return self.counters[matched_keys[0]]

    def get_counters(self):
        return self.counters

    def keys(self):
        return self.counters.keys()

    def __getitem__(self, index):
        return self.get_counter(index)

    def __iter__(self):
        return self.counters.__iter__()

def get_all_manip():
    all_manip = []
    ipc = PerfManip(
        name = "global.IPC",
        counters = [f"ctrlBlock.roq.clock_cycle",
        f"ctrlBlock.roq.commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    all_manip.append(ipc)
    block_fraction = PerfManip(
        name = "global.intDispatch.blocked_fraction",
        counters = [f"ctrlBlock.dispatch.intDispatch.blocked",
        f"ctrlBlock.dispatch.intDispatch.in"],
        func = lambda blocked, dpin: blocked * 1.0 / dpin
    )
    # all_manip.append(block_fraction)
    icache_miss_rate = PerfManip(
        name = "global.icache_miss_rate",
        counters = [f"frontend.ifu.icache.req", f"frontend.ifu.icache.miss"],
        func = lambda req, miss: miss / req
    )
    # all_manip.append(icache_miss_rate)
    dtlb_miss_rate = PerfManip(
        name = "global.dtlb_miss_rate",
        counters = [f"memBlock.LoadUnit_0.load_s1.in", f"memBlock.LoadUnit_0.load_s1.tlb_miss",
            f"memBlock.LoadUnit_1.load_s1.in", f"memBlock.LoadUnit_1.load_s1.tlb_miss"],
        func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2)
    )
    # all_manip.append(dtlb_miss_rate)
    dcache_load_miss_rate = PerfManip(
        name = "global.dcache_load_miss_rate",
        counters = [f"memBlock.LoadUnit_0.load_s2.in", f"memBlock.LoadUnit_0.load_s2.dcache_miss",
            f"memBlock.LoadUnit_1.load_s2.in", f"memBlock.LoadUnit_1.load_s2.dcache_miss"],
        func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2)
    )
    # all_manip.append(dcache_load_miss_rate)
    branch_mispred = PerfManip(
        name = "global.branch_mispred",
        counters = [f"ctrlBlock.ftq.BpRight", f"ctrlBlock.ftq.BpWrong"],
        func = lambda right, wrong: wrong / (right + wrong)
    )
    # all_manip.append(branch_mispred)
    return all_manip


def get_prefix_length(names):
    return len(os.path.commonprefix(names))

def merge_perf_counters(filenames, all_perf, verbose=False):
    def extract_numbers(s):
        re_digits = re.compile(r"(\d+)")
        pieces = re_digits.split(s)
        # convert int strings to int
        pieces = list(map(lambda x: int(x) if x.isdecimal() else x, pieces))
        return pieces
    all_names = sorted(list(set().union(*list(map(lambda s: s.keys(), all_perf)))), key=extract_numbers)
    # remove common prefix
    prefix_length = get_prefix_length(filenames) if len(filenames) > 1 else 0
    if prefix_length > 0:
        filenames = list(map(lambda name: name[prefix_length:], filenames))
    # remove common suffix
    reversed_names = list(map(lambda x: x[::-1], filenames))
    suffix_length = get_prefix_length(reversed_names) if len(filenames) > 1 else 0
    if suffix_length > 0:
        filenames = list(map(lambda name: name[:-suffix_length], filenames))
    all_sources = filenames
    yield [""] + all_sources
    for i, name in enumerate(all_names):
        if verbose:
            percentage = (i + 1) / len(all_names)
            print(f"Processing ({i + 1}/{len(all_names)})({percentage:.2%}) {name} ...")
        yield [name] + list(map(lambda perf: perf.get_counter(name, strict=True), all_perf))


def main(pfiles, output_file, verbose=False):
    all_perf = []
    all_manip = get_all_manip()
    files_count = len(pfiles)
    for i, filename in enumerate(pfiles):
        if verbose:
            percentage = (i + 1) / files_count
            print(f"Processing ({i + 1}/{files_count})({percentage:.2%}) {filename} ...")
        perf = PerfCounters(filename)
        perf.add_manip(all_manip)
        all_perf.append(perf)
    with open(output_file, 'w') as csvfile:
        csvwriter = csv.writer(csvfile)
        for output_row in merge_perf_counters(pfiles, all_perf, verbose):
            csvwriter.writerow(output_row)


def find_simulator_err(pfiles):
    if len(pfiles) > 1:
        return sum(map(lambda filename: find_simulator_err([filename])), [])
    # recursively find simulator_err.txt
    base_path = pfiles[0]
    all_files = []
    for sub_dir in os.listdir(base_path):
        sub_path = os.path.join(base_path, sub_dir)
        if os.path.isfile(sub_path) and sub_dir == "simulator_err.txt":
            all_files.append(sub_path)
        elif os.path.isdir(sub_path):
            all_files += find_simulator_err([sub_path])
    return all_files


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    parser.add_argument('pfiles', metavar='filename', type=str, nargs='*', default=None,
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output file')
    parser.add_argument('--filelist', '-f', default=None, help="filelist")
    parser.add_argument('--recursive', '-r', action='store_true', default=False,
        help="recursively find simulator_err.txt")
    parser.add_argument('--verbose', '-v', action='store_true', default=False,
        help="show processing logs")

    args = parser.parse_args()

    if args.filelist is not None:
        with open(args.filelist) as f:
            args.pfiles = list(map(lambda x: x.strip(), f.readlines()))

    if args.recursive:
        args.pfiles = find_simulator_err(args.pfiles)

    for filename in args.pfiles:
        if not os.path.isfile(filename):
            print(f"{filename} is not a file. Probably you need --recursive?")
            exit()

    main(args.pfiles, args.output, args.verbose)

