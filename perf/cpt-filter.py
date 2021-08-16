#! /usr/bin/env python3

import argparse
import os
import re

def do_filter(args):
    perf_re = re.compile(r'.*\[PERF \]\[time=\s*\d*\] ((\w*(\.|))*): (\w*)\s*,\s*(\d*)')
    spec_list = os.listdir(args.input)
    simpoint_len = 0
    filter_len = 0
    filter_info = []
    for spec_point in spec_list:
        simpoint_path = args.input + "/" + spec_point
        simpoint_list = os.listdir(simpoint_path)
        simpoint_len += len(simpoint_list)
        for simpoint in simpoint_list:
            content_path = simpoint_path + "/" + simpoint
            content = os.listdir(content_path)
            if 'aborted' in content:
                continue
            assert('completed' in content)
            assert('simulator_err.txt' in content)
            assert('simulator_out.txt' in content)
            # print(content)
            perf_path = content_path + "/" + "simulator_err.txt"
            with open(perf_path, 'r') as f:
                interest_line = []
                instr_line = []
                assert(args.perf != "")
                for line in f.readlines():
                    if args.perf in line:
                        interest_line.append(line)
                    if "roq: commitInstr," in line:
                        instr_line.append(line)
                assert len(interest_line) > 1, "Warmup performance counters should be included"
                assert len(interest_line) == 2, "Extra performance counters matched, please check -P argument"
                perf_match = perf_re.match(interest_line[-1])
                instr_match = perf_re.match(instr_line[-1])
                keep = False
                instr_value = 0
                if instr_match:
                    instr_value = instr_match.group(5)
                if perf_match:
                    perf_name = ".".join([str(perf_match.group(1)), str(perf_match.group(4))])
                    perf_value = perf_match.group(5)
                    assert instr_value != 0
                    if args.maxmin == 0:
                        keep = int(perf_value) / int(instr_value) > float(args.threshold)
                    else:
                        keep = int(perf_value) / int(instr_value) < float(args.threshold)
                else:
                    assert "Performance counter format error"
                if keep:
                    filter_len += 1
                    print(str(spec_point) + " " + str(simpoint) + " (value=" + str(int(perf_value) / int(instr_value)) + ", instr_cnt=" + str(instr_value) + ")")
    
    print("\n===== SUMMARY =====")
    print("Total SPEC: " + str(len(spec_list)))    
    print("Total simpoints: " + str(simpoint_len))
    print("Filtered simpoints: " + str(filter_len))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="SPEC checkpoint filter")
    parser.add_argument('--input', '-I', default="./", help="checkpoint directory")
    parser.add_argument('--perf', '-P', default="", help="performance counters that interest")
    parser.add_argument('--threshold', '-T', default=0, help="threshold for the interesting performance counter")
    parser.add_argument('--maxmin', '-M', default=0, help="0 for filtering perfcnt > threshold while 1 for filtering perfcnt < threshold")
    args = parser.parse_args()
    do_filter(args)
