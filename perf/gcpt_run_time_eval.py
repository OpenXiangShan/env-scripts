import argparse
import json
import os
import numpy as np
import re

base_dir = "/nfs/home/share/EmuTasks/SPEC06_EmuTasks_2023_03_31/"
# base_dir = "/nfs/home/liyanqin/xs-workspace/xs-env-gd2/XiangShan/spec06-dwpu-mmru"

perf_re = re.compile(r'.*\[PERF \]\[time=\s+\d+\] (([a-zA-Z0-9_]+\.)+[a-zA-Z0-9_]+): ((\w| |\')+),\s+(\d+)$')
clock_cycle_re = re.compile(r'.*\[PERF \]\[time=\s+\d+\] (([a-zA-Z0-9_]+\.)+[a-zA-Z0-9_]+): clock_cycle,\s+(\d+)$')
divide_str_format = "==================== %s ===================="


class Dispatch:
    def __init__(self):
        self.nums = []

    def add(self, num):
        self.nums.append(num)

    def value(self):
        return sum(self.nums)

    def __str__(self):
        res = "hello: "
        for i in self.nums:
            res += str(i) + " "
        return res
    
    def __lt__(self,other):
        return self.value() < other.value()
    
class CptEntry:
    def __init__(self) -> None:
        # TODO: 根据 hours list 进行贪心
        self.benchspec = ""
        self.point = ""
        self.weight = ""
        self.hour = 0
    
    def set_data(self, benchspec, point, weight):
        self.benchspec = benchspec
        self.point = point
        self.weight = weight
    
    def get_benchspec(self):
        return self.benchspec

    def get_point(self):
        return self.point
    
    def get_weight(self):
        return self.weight

    def get_hour(self):
        return self.hour
    
    def set_time(self, hour):
        self.hour = hour

    def __lt__(self, x):
        return self.hour < x.hour

def cal_exe_hours(hours_list, parallel_num):
    all = len(hours_list)
    dlist = [Dispatch() for _ in range(int(parallel_num))]
    i = 0
    while i < all:
        dlist.sort()
        dlist[0].add(hours_list[i])
        i += 1
    dlist.sort()
    dlist.reverse()
    return dlist[0].value()

def get_default_value():
    cycle_list = []
    wup_cycle_list = []
    for root, ds, fs in os.walk(base_dir):
        for f in fs:
            file_path = os.path.join(root, f)
            if f != "simulator_err.txt":
                continue
            cycle = 0
            warmup_cycle = 0
            with open(file_path) as f:
                for line in f:
                    perf_match = clock_cycle_re.match(line.replace("/", "_"))
                    if perf_match:
                        value = float(perf_match.group(3))
                        cycle += value
                        if warmup_cycle == 0:
                            warmup_cycle = value
            if cycle != 0:
                cycle_list.append(cycle)
            if warmup_cycle != 0:
                wup_cycle_list.append(warmup_cycle)
    return (int(np.array(cycle_list).mean()), int(np.array(wup_cycle_list).mean()))

def get_eval_hour(benchmark, point, weight) -> float:
    ### default value
    # default_cycle, default_wup_cycle = get_default_value()
    default_cycle = 25461496 
    default_wup_cycle = 13024213
    
    dir_name = "_".join([benchmark, point, weight])
    base_path = os.path.join(os.path.join(base_dir, dir_name), "simulator_err.txt")
    cycle = 0
    warmup_cycle = 0
    if os.path.exists(base_path):
        with open(base_path) as f:
            for line in f:
                perf_match = clock_cycle_re.match(line.replace("/", "_"))
                if perf_match:
                    cycle += float(perf_match.group(3))
                    if warmup_cycle == 0:
                        warmup_cycle = float(perf_match.group(3))
    else:
        cycle = default_cycle
        warmup_cycle = default_wup_cycle
    hour = cycle * 1.0 / (10**7)
    return hour

def eval_time_and_opt(data: dict, parallel_num: int, reverse = False):
    ### default value
    # default_cycle, default_wup_cycle = get_default_value()
    default_cycle = 25461496 
    default_wup_cycle = 13024213
    compile_hours = 2

    hours_list = []
    wup_hours_list = []
    bench_list = []

    # print("benchmark, cylces, eval_hours")
    for benchmark in data:
        for serial_num in data[benchmark]:
            percent = data[benchmark][serial_num]

            bench_entry = CptEntry()
            bench_entry.set_data(benchmark, serial_num, percent)
            
            dir_name = "_".join([benchmark, serial_num, percent])
            base_path = os.path.join(os.path.join(base_dir, dir_name), "simulator_err.txt")
            cycle = 0
            warmup_cycle = 0
            if os.path.exists(base_path):
                with open(base_path) as f:
                    for line in f:
                        perf_match = clock_cycle_re.match(line.replace("/", "_"))
                        if perf_match:
                            cycle += float(perf_match.group(3))
                            if warmup_cycle == 0:
                                warmup_cycle = float(perf_match.group(3))
            else:
                cycle = default_cycle
                warmup_cycle = default_wup_cycle
            hour = cycle * 1.0 / (10**7)
            bench_entry.set_time(hour)
            bench_list.append(bench_entry)
            hours_list.append(hour)
            wup_hours_list.append(warmup_cycle * 1.0 / (10**7))
            # print(f"{benchmark}, {cycle}, {hour}")

    exe_hours = cal_exe_hours(hours_list, parallel_num)
    wup_hours = cal_exe_hours(wup_hours_list, parallel_num)
    print(divide_str_format%"evaluation time")
    print(f"warmup hours:\t\t{wup_hours}")
    print(f"origin execute hours:\t{exe_hours}")

    if reverse:
        sorted_by=lambda x: x.hour
    else:
        sorted_by=lambda x: -x.hour
    bench_list = sorted(bench_list, key=sorted_by)

    opt_exe_hours = 0
    opt_hours_list = []
    for be in bench_list:
        opt_hours_list.append(be.hour)
    opt_exe_hours = cal_exe_hours(opt_hours_list, parallel_num)
    print(f"optimize execute hours:\t{opt_exe_hours}")
    print(divide_str_format%"evaluation time")
    return bench_list

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="gcpt run time evaluation")
    
    parser.add_argument('json_path', metavar='json_path', type=str, help='path to gcpt json')
    parser.add_argument('--core_num', default=128, type=int, help='core numbers')
    parser.add_argument('--thread_num', default=16, type=int, help='thread numbers')
    parser.add_argument('--base_dir', default="/nfs/home/share/EmuTasks/SPEC06_EmuTasks_2023_03_31/", type=str, help='base dir to compare')
    
    args = parser.parse_args()

    # assert(args.thread_num!=0, "thread numbers should not be zero")
    # assert(os.path.exists(args.json_path), "json path does not exist")

    parallel_num = args.core_num/args.thread_num
    with open(args.json_path) as f:
        data = json.load(f)
    eval_time_and_opt(data, parallel_num)
