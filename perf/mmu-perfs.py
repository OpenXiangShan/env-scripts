#! /usr/bin/env python3

import argparse
import os
from posixpath import curdir
import re

# TODO: wrap the "name","after","counter" into a class

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
    if (ptw_counter["access"] > 0 ):
        ptw_counter["miss_rate"] = (ptw_counter["l3_hit"] + ptw_counter["sp_hit"]) * 1.0 / ptw_counter["access"]

        if (ptw_counter["mem_count"] > 0):
            ptw_counter["mem_cycle_per_count"] = ptw_counter["mem_cycle"] / ptw_counter["mem_count"]
            ptw_counter["mem_count_per_walk"] = ptw_counter["mem_count"] / (ptw_counter["access"] - ptw_counter["l3_hit"] - ptw_counter["sp_hit"]) #ptw_counter["fsm_count"]
        else:
            print("ptw mem count is 0")
    else:
        print("ptw access is 0")

def dtlb_after():
    if ((dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"] + dtlb_counter["st_access0"] + dtlb_counter["st_access1"]) > 0):
        dtlb_counter["miss_rate"] = (dtlb_counter["ld_miss0"] + dtlb_counter["ld_miss1"] + dtlb_counter["st_miss0"] + dtlb_counter["st_miss1"]) / (dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"] + dtlb_counter["st_access0"] + dtlb_counter["st_access1"])
        dtlb_counter["ld_miss_rate"] = (dtlb_counter["ld_miss0"] + dtlb_counter["ld_miss1"]) / (dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"])
        dtlb_counter["st_miss_rate"] = (dtlb_counter["st_miss0"] + dtlb_counter["st_miss1"]) / (dtlb_counter["st_access0"] + dtlb_counter["st_access1"])
        dtlb_counter["access"] = (dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"] + dtlb_counter["st_access0"] + dtlb_counter["st_access1"])
        dtlb_counter["ld_access"] = dtlb_counter["ld_access0"] + dtlb_counter["ld_access1"]
        dtlb_counter["st_access"] = dtlb_counter["st_access0"] + dtlb_counter["st_access1"]
    else:
        print("dtlb access is 0")


def filter_after():
    if (filter_counter["ptw_req_count"] > 0):
        filter_counter["ptw_cycle_per_count"] = (filter_counter["ptw_req_cycle"] / filter_counter["ptw_req_count"])
    else:
        print("ptw_req_count is 0")

def roq_after():
    roq_counter["ipc"] = (roq_counter["instr"] * 1.0 / roq_counter["cycle"])

def other_after():
    return


def read_counter(f):
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
        # else:
            # print("dismatch: " + line + "   continue...")
            # exit(0)
    return

def calculate():
    ptw_after()
    roq_after()
    dtlb_after()
    # filter_after()
    other_after()

def reset():
    for c in counter_list:
        counter_list[c].clear()

def sync_file(output_file):
    print("sync file" + output_file)
    with open(output_file, "w") as f:
        for c in counter_list:
            for item in counter_list[c]:
                f.writelines(c + " : " + item + "," + str(counter_list[c][item]) + "\n")

file_counter = dict()

def record(file):
    file_counter[file] = dtlb_counter["miss_rate"]

result_path = "/bigdata/zzf/perf/SPEC-out"
root_path = "/bigdata/zzf/perf/SPEC06_EmuTasksConfig"

def abstract(pfile, output_file):
    reset()
    read_counter(pfile)
    calculate()
    record(output_file.replace(".csv", ""))
    sync_file(result_path + "/" + output_file)

def sort(output):
    file_sort = sorted(file_counter.items(), key=lambda x: x[1], reverse=True)
    print("write result to " + output)
    with open(output, 'w') as f:
        for key, value in file_sort:
            f.writelines(key + " : " + str(value) + "\n")


def dir_walker(cur_path):
  path = os.path.abspath(cur_path)
  rel_path = os.path.relpath(path, root_path)
  rel_path_str = rel_path.replace("/", "_", 1)
  os.chdir(path) # need change to the path
  sub_dirs = os.listdir(path)
  for sub in sub_dirs:
    if os.path.islink(sub):
      print( rel_path + " " + sub + " is a link, skip...")
    elif os.path.isfile(sub):
        if (sub == "simulator_err.txt"):
            print( rel_path + " file: " + sub)
    #   print("file: " + sub)
            abstract(sub, rel_path_str + ".csv")
    elif os.path.isdir(sub):
      print( rel_path + " " + "dir : " + sub)
      dir_walker(sub)
    else:
      print(sub + " is not file or directory, skip...")
      assert(0, "find unkown files")
    os.chdir(path) # return to current path


def main(path, output):
    cur_dir = os.path.abspath(os.curdir)
    dir_walker(path)
    os.chdir(cur_dir)
    if output[0] != "/":
        output = cur_dir + "/" + output
    sort(output)

# input file: a series of perf file
# procedure: only use tlb/ptw relative perf counter
# output file: count and analysis ptw and tlb's perf counter, like miss rate and req num and so on
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser for several files, order them by dtlb miss, abstract mmu perf into seperate file and output the order in one file')
    parser.add_argument('path', metavar='filename', type=str,
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output path')
    parser.add_argument('--result_path', '-r', default="/bigdata/zzf/perf/SPEC-out", help='abstract counter result root path')


    args = parser.parse_args()
    result_path = args.result_path
    root_path = args.path

    main(args.path, args.output)