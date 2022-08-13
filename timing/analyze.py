#! /usr/bin/env python3

import argparse
import csv
import os
import re

class TimingPath(object):
    csv_elements = ["startpoint", "endpoint", "input_delay", "arrival_time", "slack"]

    def __init__(self, startpoint=None, endpoint=None, input_delay=None, arrival_time=None, slack=None):
        self.startpoint = startpoint
        self.endpoint = endpoint
        self.input_delay = input_delay
        self.arrival_time = arrival_time
        self.slack = slack

    def get_all(self):
        return [self.startpoint, self.endpoint, self.input_delay, self.arrival_time, self.slack]

    def get_length(self):
        return float(self.arrival_time) - float(self.input_delay)

    def to_csv(self):
        return ",".join(self.get_all())

    def dedup_digits(self):
        re_digits = re.compile(r"(\d+)")
        pieces = re_digits.split(self.startpoint)
        startpoint = "".join(map(lambda x: "*" if x.isdecimal() else x, pieces))
        pieces = re_digits.split(self.endpoint)
        endpoint = "".join(map(lambda x: "*" if x.isdecimal() else x, pieces))
        return (startpoint, endpoint)


class TimingReport(object):
    def __init__(self, filenames):
        self.all_timing_path = []
        for filename in filenames:
            self.load(filename)

    def load(self, filename):
        report = TimingPath()
        with open(filename) as f:
            for line in f:
                if "Startpoint:" in line:
                    report.startpoint = line.replace("Startpoint:", "").strip().split()[0]
                elif "Endpoint:" in line:
                    report.endpoint = line.replace("Endpoint:", "").strip().split()[0]
                elif "input external delay" in line:
                    report.input_delay = line.replace("input external delay", "").strip().split()[0]
                elif "clock network delay (ideal)" in line:
                    report.input_delay = line.replace("clock network delay (ideal)", "").strip().split()[0]
                elif "data arrival time" in line:
                    report.arrival_time = line.replace("data arrival time", "").strip().split()[0].replace("-", "")
                elif "slack (VIOLATED)" in line:
                    report.slack = line.replace("slack (VIOLATED)", "").strip().split()[0]
                    # print(report.get_all())
                    assert(None not in report.get_all())
                    self.all_timing_path.append(report)
                    report = TimingPath()

    def to_csv(self, output_file):
        with open(output_file, 'w') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow(self.all_timing_path[0].csv_elements)
            for report in self.all_timing_path:
                csvwriter.writerow(report.get_all())

    def dedup(self):
        self.dedup_timing_path = dict()
        for p in self.all_timing_path:
            dedup_key = p.dedup_digits()
            if dedup_key not in self.dedup_timing_path:
                self.dedup_timing_path[dedup_key] = []
            self.dedup_timing_path[dedup_key].append(p)

    def to_csv_dedup(self, output_file):
        with open(output_file, 'w') as csvfile:
            csvwriter = csv.writer(csvfile)
            csvwriter.writerow(["startpoint", "endpoint", "max_delay", "min_slack"])
            for dedup_key in self.dedup_timing_path:
                startpoint, endpoint = dedup_key
                dedup_paths = self.dedup_timing_path[dedup_key]
                delay = max(map(lambda x: x.get_length(), dedup_paths))
                slack = min(map(lambda x: x.slack, dedup_paths))
                csvwriter.writerow([startpoint, endpoint, delay, slack])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    parser.add_argument('pfiles', metavar='filename', type=str, nargs='*', default=None,
                        help='timing log')

    args = parser.parse_args()

    report = TimingReport(args.pfiles)
    report.to_csv("timing.csv")
    report.dedup()
    report.to_csv_dedup("timing_dedup.csv")
