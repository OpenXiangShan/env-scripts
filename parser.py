#! /usr/bin/env python3

import argparse
import os
import re
import sys


class VIO(object):
    def __init__(self, info):
        self.info = info
        assert(self.info[0] in ["input", "output"])
        self.direction = True if self.info[0] == "input" else False
        self.width = 0 if self.info[1] == "" else int(self.info[1].split(":")[0].replace("[", ""))
        self.name = self.info[2]

    def get_width(self):
        return self.width

    def get_name(self):
        return self.name

    def startswith(self, prefix):
        return self.info[2].startswith(prefix)

    def __str__(self):
        return " ".join(self.info)

    def __repr__(self):
        return self.__str__()

    def __lt__(self, other):
        return str(self) < str(other)

class VModule(object):
    io_re = re.compile(r'^\s*(input|output)\s*(\[\s*\d+\s*:\s*\d+\s*\]|)\s*(\w+),?\s*$')
    submodule_re = re.compile(r'^\s*(\w+)\s*(#\(.*\)|)\s*(\w+)\s*\(\s*(|//.*)\s*$')

    def __init__(self, name):
        self.name = name
        self.lines = []
        self.io = []
        self.submodule = set()

    def add_line(self, line):
        self.lines.append(line)
        if len(self.lines):
            io_match = self.io_re.match(line)
            if io_match:
                this_io = VIO(tuple(map(lambda i: io_match.group(i), range(1, 4))))
                self.io.append(this_io)
            submodule_match = self.submodule_re.match(line)
            if submodule_match:
                this_submodule = submodule_match.group(1)
                if this_submodule != "module":
                    self.submodule.add(this_submodule)

    def get_name(self):
        return self.name

    def get_lines(self):
        return self.lines

    def get_io(self, prefix="", match=""):
        if match:
            r = re.compile(match)
            return list(filter(lambda x: r.match(str(x)), self.io))
        else:
            return list(filter(lambda x: x.startswith(prefix), self.io))

    def get_submodule(self):
        return self.submodule

    def dump_io(self, prefix="", match=""):
        print("\n".join(map(lambda x: str(x), self.get_io(prefix, match))))

    def __str__(self):
        module_name = "Module {}: \n".format(self.name)
        module_io = "\n".join(map(lambda x: "\t" + str(x), self.io)) + "\n"
        return module_name + module_io

    def __repr__(self):
        return "{}".format(self.name)

class VCollection(object):
    module_re = re.compile(r'^\s*module\s*(\w+)\s*(#\(?|)\s*(\(.*|)\s*$')

    def __init__(self):
        self.modules = []

    def load_modules(self, vfile):
        in_module = False
        current_module = None
        skipped_lines = []
        with open(vfile) as f:
            print("Loading modules from {}...".format(vfile))
            for i, line in enumerate(f):
                module_match = self.module_re.match(line)
                if module_match:
                    module_name = module_match.group(1)
                    if in_module or current_module is not None:
                        print("Line {}: does not find endmodule for {}".format(i, current_module))
                        exit()
                    current_module = VModule(module_name)
                    for line in skipped_lines:
                        print("[WARNING]{}:{} is added to module {}:\n{}".format(vfile, i, module_name, line), end="")
                        current_module.add_line(line)
                    skipped_lines = []
                    in_module = True
                if not in_module or current_module is None:
                    if line.strip() != "" and not line.strip().startswith("//"):
                        skipped_lines.append(line)
                    continue
                current_module.add_line(line)
                if line.startswith("endmodule"):
                    self.modules.append(current_module)
                    current_module = None
                    in_module = False

    def get_module_names(self):
        return list(map(lambda m: m.get_name(), self.modules))

    def get_all_modules(self, match=""):
        if match:
            r = re.compile(match)
            return list(filter(lambda m: r.match(m.get_name()), self.modules))
        else:
            return self.modules

    def get_module(self, name, with_submodule=False):
        target = None
        for module in self.modules:
            if module.get_name() == name:
                target = module
        if target is None or not with_submodule:
            return target
        submodules = set()
        submodules.add(target)
        for submodule in target.get_submodule():
            result = self.get_module(submodule, with_submodule=True)
            if result is None:
                print("Error: cannot find submodules of {} or the module itself".format(submodule))
                return None
            submodules.update(result)
        return submodules

    def dump_to_file(self, name, output_dir, with_submodule=True, split=True):
        print("Dump module {} to {}...".format(name, output_dir))
        modules = self.get_module(name, with_submodule)
        if modules is None:
            return False
        if not with_submodule:
            modules = [modules]
        if not os.path.isdir(output_dir):
            os.makedirs(output_dir, exist_ok=True)
        if split:
            for module in modules:
                output_file = os.path.join(output_dir, module.get_name() + ".v")
                with open(output_file, "w+") as f:
                    f.writelines(module.get_lines())
        else:
            output_file = os.path.join(output_dir, name + ".v")
            with open(output_file, "w+") as f:
                for module in modules:
                    f.writelines(module.get_lines())

def check_data_module_template(collection):
    error_modules = []
    field_re = re.compile(r'io_(w|r)data_(\d*)(_.*|)')
    modules = collection.get_all_modules(match="(Sync|Async)DataModuleTemplate.*")
    for module in modules:
        module_name = module.get_name()
        print("Checking", module_name, "...")
        wdata_all = sorted(module.get_io(match="input.*wdata.*"))
        rdata_all = sorted(module.get_io(match="output.*rdata.*"))
        field_re.match("io_wdata_14_inst").group(3)
        wdata_pattern = set(map(lambda x: " ".join((str(x.get_width()), field_re.match(x.get_name()).group(3))), wdata_all))
        rdata_pattern = set(map(lambda x: " ".join((str(x.get_width()), field_re.match(x.get_name()).group(3))), rdata_all))
        if wdata_pattern != rdata_pattern:
            print("Errors:")
            print("  wdata only:", sorted(wdata_pattern - rdata_pattern, key=lambda x: x.split(" ")[1]))
            print("  rdata only:", sorted(rdata_pattern - wdata_pattern, key=lambda x: x.split(" ")[1]))
            print("In", str(module))
            error_modules.append(module)
    return error_modules

def main(files):
    collection = VCollection()
    for f in files:
        collection.load_modules(f)

    # errors = check_data_module_template(collection)
    # if errors:
    #     print("Errors in checking data module template input/output:", errors)

    # modules = collection.get_module_names()
    # modules.sort()
    # print(modules)

    # for m in modules:
    #     module = collection.get_module(m)
    #     print("Module:", m)
    #     module.dump_io(match=".*put.*exception.*")
    # roq = collection.get_module("DispatchQueue")
    # print(roq.get_submodule())
    # roq.dump_io()
    # roq.dump_io(match=".*io_deq_0_.*")
    # alu = collection.get_module("ReservationStationData_7")
    # alu.dump_io(match=".*exception.*")
    # r = re.compile(".*exception.*")
    # print("".join(filter(lambda x: r.match(x), alu.get_lines())))

    directory = "XSSoc-20210127"
    # out_modules = ["XSSimSoC", "XSSoc", "XSCore", "Frontend", "CtrlBlock", "IntegerBlock", "FloatBlock", "MemBlock", "InclusiveCache", "InclusiveCache_2"]
    out_modules = ["XSSoc"]
    for m in out_modules:
        collection.dump_to_file(m, os.path.join(directory, m))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Verilog helper')
    parser.add_argument('vfiles', metavar='filename', type=str, nargs='+',
                        help='input verilog file')
    # parser.add_argument('--sum', dest='accumulate', action='store_const',
    #                     const=sum, default=max,
    #                     help='sum the integers (default: find the max)')

    args = parser.parse_args()

    main(args.vfiles)
