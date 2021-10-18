#! /usr/bin/env python3

import argparse
import math
import os
import re
from parser import VCollection

from generator import VerilogModuleGenerator
from regfile import *

def check_field(module):
    ok = True
    field_re = re.compile(r'io_(w|r)data_(\d*)(_.*|)')
    wdata_all = sorted(module.get_io(match="input.*wdata.*"))
    rdata_all = sorted(module.get_io(match="output.*rdata.*"))
    wdata_pattern = set(map(lambda x: " ".join((str(x.get_width()), field_re.match(x.get_name()).group(3))), wdata_all))
    rdata_pattern = set(map(lambda x: " ".join((str(x.get_width()), field_re.match(x.get_name()).group(3))), rdata_all))
    wports = list(set(map(lambda x: field_re.match(x.get_name()).group(2), wdata_all)))
    # check whether every rdata is from wdata
    if wdata_pattern != rdata_pattern:
        print("Errors:")
        print("  wdata only:", sorted(wdata_pattern - rdata_pattern, key=lambda x: x.split(" ")[1]))
        print("  rdata only:", sorted(rdata_pattern - wdata_pattern, key=lambda x: x.split(" ")[1]))
        print("In", str(module))
        ok = False
    # check whether every port has the same wdata fields
    for wp in wdata_pattern:
        wp_count = sum(map(lambda x: x.get_name().endswith(wp.split(" ")[1]), wdata_all))
        if not (wp_count == len(wports) and len(wports) > 0):
            print("Warning:")
            print(f"  wdata (wports = {len(wports)}) is not consistent:")
            wp_list = filter(lambda x: x.get_name().endswith(wp.split(" ")[1]), wdata_all)
            print("  " + "\n  ".join(map(lambda x: x.get_name(), wp_list)))
            # ok = False
    return ok

def get_packed_array(fields):
    packed_fields = []
    counter, pack = 0, []
    max_limit, single_width_limit = 39, 32
    for width, name in sorted(fields, key=lambda x: x[0]):
        # add to counter
        if width + counter > max_limit and counter > 0:
            packed_fields.append((counter, pack))
            counter, pack = 0, []
        if width >= single_width_limit or "psrc" in name:
            packed_fields.append((width, [(width, name)]))
        else:
            counter += width
            pack.append((width, name))
    if counter > 0:
        packed_fields.append((counter, pack))
    packed_fields = sorted(packed_fields, key=lambda x: x[0])
    return packed_fields

def generate_regfile_instance(gen, instance, config, nw, nr, depth, rdata_sets=None):
    data_width = config[0]
    connections = [("clock", "clock")]
    for rport in range(nr):
        rdata = f"{instance}_rdata_{rport}"
        gen.add_decl_wire(data_width, rdata)
        index = 0
        for width, field in config[1]:
            io_rdata = f"io_rdata_{rport}{field}"
            if rdata_sets is not None and io_rdata not in rdata_sets:
                print("Do not find rdata io:", io_rdata)
                pass
            else:
                bit_slice = f"{index+width-1}:{index}" if width != 1 else f"{index}"
                gen.add_assign(io_rdata, f"{rdata}[{bit_slice}]")
            index += width
        connections.append((f"raddr{rport}", f"io_raddr_{rport}"))
        connections.append((f"rdata{rport}", rdata))
    for wport in range(nw):
        connections.append((f"wen{wport}", f"io_wen_{wport}"))
        connections.append((f"waddr{wport}", f"io_waddr_{wport}"))
        index, wdata = 0, "{"
        for width, field in reversed(config[1]):
            wdata += f"io_wdata_{wport}{field}, "
            index += width
        wdata = wdata[:-2] + "}"
        connections.append((f"wdata{wport}", wdata))
    class_name = f"sregfile_{depth}x{data_width}_{nw}w{nr}r"
    gen.add_sequential(f"{class_name} {instance} (")
    gen.add_sequential(", \n    ".join(map(lambda c: f".{c[0]}({c[1]})", connections)))
    gen.add_sequential(f");")
    return class_name, (data_width, depth, nw, nr)

def get_rdata_fields(module):
    max_read_ports = 20
    all_fields = set()
    for i in range(max_read_ports):
        fields = sorted(module.get_io(match="output.*io_rdata_{}(.*)".format(i)), key=lambda x: x.get_width())
        fields = list(map(lambda f: (f.get_width(), f.get_name().replace("io_rdata_{}".format(i), "")), fields))
        all_fields.update(fields)
    # print(all_fields)
    return all_fields

def replace_data_module(module):
    print("Replace", module.get_name(), "...")
    if not check_field(module):
        exit()
        return "", []
    fields = get_rdata_fields(module)
    packed_fields = get_packed_array(fields)
    #if len(fields) == 1:
    #    print("no need for packing, skipped")
    #    return "", []
    nr = len(module.get_io(match=".*io_raddr_(.*)"))
    nw = len(module.get_io(match=".*io_waddr_(.*)"))
    depth = -1
    mem_re = re.compile(r"\s*reg\s*\[\d*:\d*\]\s*\w*\s*\[\d*:(\d*)\];\s*(//.*|)")
    for line in module.get_lines():
        mem_match = mem_re.match(line)
        if mem_match:
            new_depth = int(mem_match.group(1)) + 1
            if depth == -1 or new_depth == depth:
                depth = new_depth
            else:
                depth = 1
                break
    if depth < 0:
        print("ERROR infer depth for", module.get_name())
        exit()
    generator = VerilogModuleGenerator(module.get_name())
    for io in module.get_io():
        generator.add_io(io.get_direction(), io.get_width(), io.get_name())
    regfile_configs = set()
    for i, config in enumerate(packed_fields):
        name, regfile_config = generate_regfile_instance(generator, f"array_{i}", config, nw, nr, depth, list(map(lambda x: x.get_name(), module.get_io())))
        regfile_configs.add(regfile_config)
        module.add_submodule(name)
    print("with regfile configs", regfile_configs)
    return generator.generate(), regfile_configs

def main(files, output_dir):
    if output_dir is None:
        output_dir = "output"
    # print(files, output_dir)
    collection = VCollection()
    for f in files:
        collection.load_modules(f)
    modules = collection.get_all_modules(match="SyncDataModuleTemplate.*")
    regfile_configs = set()
    for module in modules:
        repl, regfile = replace_data_module(module)
        if repl:
            regfile_configs.update(regfile)
            module.replace(repl)
    cmp_configs = set(map(lambda c: (math.ceil(math.log2(c[1])), c[2]), regfile_configs))
    addr_dec_configs = set(map(lambda c: (math.ceil(math.log2(c[1])),), regfile_configs))
    for config in regfile_configs:
        # print("generate refile with config", config)
        name, line, submodules = generate_regfile(*config)
        module = collection.add_module(name, line)
        module.add_submodules(submodules)
    for config in cmp_configs:
        # print("generate addr_cmp with config", config)
        name, line = generate_cmp(*config)
        collection.add_module(name, line)
    for config in addr_dec_configs:
        # print("generate addr_dec with config", config)
        name, line = generate_addr_dec(*config)
        collection.add_module(name, line)

    # out_modules = ["XSSoc", "XSCore", "Frontend", "CtrlBlock", "IntegerBlock", "FloatBlock", "MemBlock", "InclusiveCache", "InclusiveCache_2"]
    # out_modules = ["ReservationStation", "RedirectGenerator", "XSSoc", "XSCore", "Frontend", "CtrlBlock", "IntegerBlock", "FloatBlock", "MemBlock", "PTW", "L1plusCache"]
    # out_modules = ["XSTop", "XSCore", "InclusiveCache", "InclusiveCache_2"]
    # out_modules = ["XSTop", "XSCore", "ExuBlock", "ExuBlock_1", "ExuBlock_2"]
    out_modules = ["XSTop"]
    for m in out_modules:
        collection.dump_to_file(m, os.path.join(output_dir, m))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='regfile generator for SyncDataModuleTemplate')
    parser.add_argument('vfiles', metavar='filename', type=str, nargs='+',
                        help='input verilog file')
    parser.add_argument('--output_dir', '-o', help='output directory')

    args = parser.parse_args()

    main(args.vfiles, args.output_dir)

