#! /usr/bin/env python3

import argparse
import os
import re

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

def main(pfiles, output_file):
    all_perf = []
    for filename in pfiles:
        all_perf.append(load_perf(filename))
    all_names = sorted(list(set().union(*list(map(lambda s: s.keys(), all_perf)))))
    all_sources = list(map(lambda x: os.path.split(x)[1], pfiles))
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

