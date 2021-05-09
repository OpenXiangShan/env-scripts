import os
import os.path

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
    LOGLEVEL_LENGTH = 5
    CYCLE_START, CYCLE_END = 13, 33

    def __init__(self, filename):
        self.file = FileLoader(filename)
        if self.file.is_good():
            self.parse()

    def parse(self):
        self.loglevels, self.cycles, self.modules = set(), set(), set()
        self.logs = dict()
        lines = list(filter(self.__is_log_line, self.file.get_lines()))
        for line in lines:
            try:
                loglevel = self.__get_log_level(line)
                if loglevel not in self.loglevels:
                    self.loglevels.add(loglevel)
                    self.logs[loglevel] = dict()
                cycle = self.__get_cycle(line)
                if cycle not in self.cycles:
                    self.cycles.add(cycle)
                if cycle not in self.logs[loglevel]:
                    self.logs[loglevel][cycle] = dict()
                module = self.__get_module(line)
                if module not in self.modules:
                    self.modules.add(module)
                if module not in self.logs[loglevel][cycle]:
                    self.logs[loglevel][cycle][module] = []
            except:
                continue
            loginfo = ":".join(line.split(":")[1:])
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

    # def __get_log(self, line):
    #     return ":".join(line.split(":")[1:])

    def __is_log_line(self, line):
        return len(line) > self.LOGLEVEL_LENGTH + 2 and line[0] == "[" and line[1 + self.LOGLEVEL_LENGTH] == ']'

    def __get_log_level(self, line):
        return line[1 : 1+self.LOGLEVEL_LENGTH].strip()

    def __get_module(self, line):
        return line.split(":")[0].split(" ")[-1].split(".")[-1]

    def __get_cycle(self, line):
        return int(line[self.CYCLE_START : self.CYCLE_END])

    def is_good(self):
        return self.file.is_good() and len(self.cycles) > 0

logparser = -1

if __name__ == "__main__":
    logparser = XSLogParser("/home/xyn/XiangShan/simv.log")
    assert(logparser.is_good())
    print(logparser.cycles)
    print(logparser.loglevels)
    print(logparser.modules)
    print(logparser.get_logs(0, 20, ["Dispatch1"], ["DEBUG", "INFO"]))

