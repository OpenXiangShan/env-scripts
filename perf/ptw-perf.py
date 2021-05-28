#! /usr/bin/env python3

import argparse
import os
import re
from sys import modules

class PerfMMU(object):
    def __init__(self, name, counters, func):
        self.name = name
        self.counter = counters
        self.func = func

ptw_counter = dict()
filter_counter = dict()
roq_counter = dict()
other_counter = dict()

counter_list = {
    "ptw": ptw_counter,
    "roq": roq_counter,
    "dtlbRepeater": filter_counter
}

ptw_name = {
        "req_count0":"itlb_req",
        "req_count1":"dtlb_req",
        "access":"access",
        "l1_hit":"l1_hit",
        "l2_hit":"l2_hit",
        "l3_hit":"l3_hit",
        "sp_hit":"sp_hit",
        "fsm_count":"fsm_count",
        "mem_count":"mem_count",
        "mem_cycle":"mem_cycle",
        "ptw_pre_count":"pre_count"
}

filter_name = {
    "ptw_req_count":"ptw_req_count",
    "ptw_req_cycle":"ptw_req_cycle"
}

roq_name = {
        "clock_cycle":"cycle",
        "commitInstr":"instr"
}

other_name = {}

def pre(nameList, count, counter, number):
    name = nameList.get(counter, "dontcare")
    if name != "dontcare":
        count[name] = int(number)

def other_pre(name, count, counter, number):
    # print("other")
    return

name_list = {
    "ptw": ptw_name,
    "roq": roq_name,
    "dtlbRepeater": filter_name
}

def ptw_after():
    ptw_counter["hit_rate"] = (ptw_counter["l3_hit"] + ptw_counter["sp_hit"]) * 1.0 / ptw_counter["access"]

def roq_after():
    roq_counter["ipc"] = (roq_counter["instr"] * 1.0 / roq_counter["cycle"])

def other_after():
    return


def abstract(filelist):
    perf_re = re.compile(r'.*\.(?P<module>\w*)\.(?P<submodule>\w*): (?P<counter>\w*)\s*,\s*(?P<number>\d*)')

    for f in filelist:
        file = open(f)
        for line in file:
            perf_match = perf_re.match(line)
            if perf_match:
                module = perf_match.group("module")
                submodule = perf_match.group("submodule")
                counter = perf_match.group("counter")
                number = perf_match.group("number")

                name = name_list.get(module, other_name)
                count = counter_list.get(module, other_counter)
                if name is other_name:
                    name = name_list.get(submodule, other_name)
                    count = counter_list.get(submodule, other_counter)
                pre(name, count, counter, number)
            else:
                print("dismatch: " + line)
                exit(0)
    return

def after():
    ptw_after()
    roq_after()
    other_after()

def sync_file(output_file):
    with open(output_file, "w") as f:
        for c in counter_list:
            for item in counter_list[c]:
                f.writelines(item + "," + str(counter_list[c][item]) + "\n")

def main(pfiles, output_file):
    abstract(pfiles)
    after()
    sync_file(output_file)

    return 0

# input file: a series of perf file
# procedure: only use tlb/ptw relative perf counter
# output file: count and analysis ptw and tlb's perf counter, like miss rate and req num and so on
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    parser.add_argument('pfiles', metavar='filename', type=str, nargs='+',
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output file')

    args = parser.parse_args()

    main(args.pfiles,args.output)