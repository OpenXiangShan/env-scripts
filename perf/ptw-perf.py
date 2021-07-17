#! /usr/bin/env python3

import argparse
import os
import re
from sys import modules

# TODO: wrap the "name","after","counter" into a class
class PerfMMU(object):
    def __init__(self, name, counters, func):
        self.name = name
        self.counter = counters
        self.func = func

ptw_counter = dict()
filter_counter = dict()
roq_counter = dict()
dtlb_counter = dict()
other_counter = dict()

counter_list = {
    "dtlb": dtlb_counter,
    "ptw": ptw_counter,
    "dtlbRepeater": filter_counter,
    "roq": roq_counter
}

dtlb_name = {
    "access0":"ld_access0",
    "access1":"ld_access1",
    "access2":"st_access0",
    "access3":"st_access1",
    "miss0":"ld_miss0",
    "miss1":"ld_miss1",
    "miss2":"st_miss0",
    "miss3":"st_miss1",
    "ptw_resp_count":"ptw_resp_count"
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
    "dtlb": dtlb_name,
    "ptw": ptw_name,
    "dtlbRepeater": filter_name,
    "roq": roq_name,
}

def ptw_after():
    ptw_counter["hit_rate"] = (ptw_counter["l3_hit"] + ptw_counter["sp_hit"]) * 1.0 / ptw_counter["access"]
    ptw_counter["mem_cycle_per_count"] = ptw_counter["mem_cycle"] / ptw_counter["mem_count"]
    ptw_counter["mem_count_per_walk"] = ptw_counter["mem_count"] / ptw_counter["fsm_count"]

def dtlb_after():
    dtlb_counter["hit_rate"] = (dtlb_counter["ld_miss0"] + dtlb_counter["ld_miss1"] + dtlb_counter["st_miss0"] + dtlb_counter["st_miss1"]) / (dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"] + dtlb_counter["st_access0"] + dtlb_counter["st_access1"])
    dtlb_counter["ld_hit_rate"] = (dtlb_counter["ld_miss0"] + dtlb_counter["ld_miss1"]) / (dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"])
    dtlb_counter["st_hit_rate"] = (dtlb_counter["st_miss0"] + dtlb_counter["st_miss1"]) / (dtlb_counter["st_access0"] + dtlb_counter["st_access1"])
    dtlb_counter["access"] = (dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"] + dtlb_counter["st_access0"] + dtlb_counter["st_access1"])
    dtlb_counter["ld_access"] = dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"]
    dtlb_counter["st_access"] = dtlb_counter["st_access0"] + dtlb_counter["st_access1"]

def filter_after():
    filter_counter["ptw_cycle_per_count"] = (filter_counter["ptw_req_cycle"] / filter_counter["ptw_req_count"])

def roq_after():
    roq_counter["ipc"] = (roq_counter["instr"] * 1.0 / roq_counter["cycle"])

def other_after():
    return


def abstract(f):
    perf_re = re.compile(r'.*\.(?P<module>\w*)\.(?P<submodule>\w*): (?P<counter>\w*)\s*,\s*(?P<number>\d*)')

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
            print("dismatch: " + line + "   continue...")
            # exit(0)
    return

def after():
    ptw_after()
    roq_after()
    dtlb_after()
    filter_after()
    other_after()

def sync_file(output_file):
    with open(output_file, "w") as f:
        for c in counter_list:
            for item in counter_list[c]:
                f.writelines(c + " : " + item + "," + str(counter_list[c][item]) + "\n")

def main(pfile, output_file):
    abstract(pfile)
    after()
    sync_file(output_file)

    return 0

# input file: a series of perf file
# procedure: only use tlb/ptw relative perf counter
# output file: count and analysis ptw and tlb's perf counter, like miss rate and req num and so on
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    # parser.add_argument('pfiles', metavar='filename', type=str, nargs='+',
    #                     help='performance counter log')
    parser.add_argument('pfile', metavar='filename', type=str,
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output file')

    args = parser.parse_args()

    main(args.pfile,args.output)