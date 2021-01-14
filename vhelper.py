import argparse
import os
import re
import sys


class VIO(object):
    def __init__(self, info):
        self.info = info

    def startswith(self, prefix):
        return self.info[2].startswith(prefix)

    def __str__(self):
        return " ".join(self.info)

    def __repr__(self):
        return self.__str__()


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

    def get_io(self, prefix=""):
        return list(filter(lambda x: x.startswith(prefix), self.io))

    def get_submodule(self):
        return self.submodule

    def dump_io(self, prefix=""):
        print("\n".join(map(lambda x: str(x), self.get_io(prefix))))

    def __str__(self):
        module_name = "Module {}: \n".format(self.name)
        module_io = "\n".join(map(lambda x: "\t" + x, self.io)) + "\n"
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
                    in_module = True
                if not in_module or current_module is None:
                    if line.strip() != "" and not line.strip().startswith("//"):
                        print("[WARNING]{}:{} is skipped: \n{}".format(vfile, i, line))
                    continue
                current_module.add_line(line)
                if line.startswith("endmodule"):
                    self.modules.append(current_module)
                    current_module = None
                    in_module = False

    def get_module_names(self):
        return list(map(lambda m: m.get_name(), self.modules))

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
            os.mkdir(output_dir)
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

def main(files):
    collection = VCollection()
    for f in files:
        collection.load_modules(f)
    modules = collection.get_module_names()
    modules.sort()
    print(modules)

    roq = collection.get_module("DispatchQueue")
    roq.dump_io()
    roq.dump_io("io_commits_")

    # collection.dump_to_file("XSSoc", "verilog1")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Verilog helper')
    parser.add_argument('vfiles', metavar='filename', type=str, nargs='+',
                        help='input verilog file')
    # parser.add_argument('--sum', dest='accumulate', action='store_const',
    #                     const=sum, default=max,
    #                     help='sum the integers (default: find the max)')

    args = parser.parse_args()

    main(args.vfiles)
