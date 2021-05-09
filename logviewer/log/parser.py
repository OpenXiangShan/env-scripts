#! /usr/bin/env python3

import os
import os.path
import re


class FileLoader(object):
    def __init__(self, filename):
        self.good = True
        if not os.path.isfile(filename):
            self.good = False
        else:
            fh = open(filename, "r")
            self.current = 0
            print("load file {}...".format(filename), end="")
            self.lines = fh.readlines()
            self.line_number = len(self.lines)
            print("ok!")

    def is_good(self):
        return self.good

    def get_lines(self, num=-1, move=True):
        if num == -1:
            return self.lines
        if self.current >= self.line_number:
            return []
        end_position = min(self.current + num, self.line_number)
        content = self.lines[self.current : end_position]
        if move:
            self.current = end_position
        return content

    def reset_current(self, current):
        self.current = current

    def step_back(self, steps=-2):
        self.current -= steps


class XSLogParser(object):
    log_re = re.compile(r'^\[(\w*)\s*\]\[time=\s*(\d*)\] ((\w*(\.|))*): (.*)')

    def __init__(self, filename):
        self.file = FileLoader(filename)
        if self.file.is_good():
            self.parse()

    def parse(self):
        self.loglevels, self.cycles, self.modules = set(), set(), set()
        self.logs = dict()
        for line in self.file.get_lines():
            is_log, content = self.do_parse(line)
            if not is_log:
                continue
            loglevel, cycle, module, loginfo = content
            if loglevel not in self.loglevels:
                self.loglevels.add(loglevel)
                self.logs[loglevel] = dict()
            if cycle not in self.cycles:
                self.cycles.add(cycle)
            if cycle not in self.logs[loglevel]:
                self.logs[loglevel][cycle] = dict()
            if module not in self.modules:
                self.modules.add(module)
            if module not in self.logs[loglevel][cycle]:
                self.logs[loglevel][cycle][module] = []
            self.logs[loglevel][cycle][module].append(loginfo)
        self.loglevels = sorted(list(self.loglevels))
        self.cycles = sorted(list(self.cycles))
        self.modules = sorted(list(self.modules))

    def get_logs(self, begin, end, module, loglevel):
        loglevel = loglevel + ["PERF"]
        print(begin, end, module, loglevel)
        target = []
        for c in range(begin, end+1):
            for m in module:
                for l in loglevel:
                    if l in self.logs and c in self.logs[l] and m in self.logs[l][c]:
                        target += list(map(lambda x: "[{}][{}][{}]{}".format(l, c, m, x), self.logs[l][c][m]))
        return target

    def do_parse(self, line):
        log_match = self.log_re.match(line)
        if log_match is None:
            return False,()
        level = str(log_match.group(1))
        cycle = int(log_match.group(2))
        module = str(log_match.group(3))
        info = str(log_match.group(6))
        return True, (level, cycle, module, info)

    def is_good(self):
        return self.file.is_good() and len(self.cycles) > 0

logparser = -1

if __name__ == "__main__":
    logparser = XSLogParser("/home52/xyn/xs/XiangShan/coremark.txt")
    assert(logparser.is_good())
    print(logparser.cycles)
    print(logparser.loglevels)
    print(logparser.modules)
    print(logparser.get_logs(2000, 2010, ["tb_top.sim.l_soc.core_with_l2.l2prefetcher.BestOffsetPrefetch"], ["DEBUG", "INFO"]))

