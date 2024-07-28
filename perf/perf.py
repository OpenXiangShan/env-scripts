#! /usr/bin/env python3

import argparse
import csv
import os
import re
from multiprocessing import Process, Queue
from tqdm import tqdm
import json

gcc12Enable=True
class PerfManip(object):
    def __init__(self, name, counters, func):
        self.name = name
        self.counters = counters
        self.func = func


class PerfCounters(object):
    perf_re = re.compile(r'.*\[PERF \]\[time=\s+\d+\] (([a-zA-Z0-9_]+\.)+[a-zA-Z0-9_]+): ((\w| |\')+),\s+(\d+)$')
    path_re = re.compile(r'(?P<spec_name>\w+((_\w+)|(_\w+\.\w+)|-\d+|))_(?P<time_point>\d+)_(?P<weight>0\.\d+)')

    def __init__(self, args):
        if isinstance(args, str):
            self.file_init(args)
        else:
            (spec_dir, spec_name, spec_json) = args
            self.spec_init(spec_dir, spec_name, spec_json)

    def file_init(self, filename: str):
        all_perf_counters = dict()
        with open(filename) as f:
            for line in f:
                perf_match = self.perf_re.match(line.replace("/", "_"))
                if perf_match:
                    perf_name = ".".join([str(perf_match.group(1)), str(perf_match.group(3))])
                    perf_value = str(perf_match.group(5))
                    perf_name = perf_name.replace(" ", "_").replace("'", "")
                    all_perf_counters[perf_name] = perf_value
        prefix_length = len(os.path.commonprefix(list(all_perf_counters.keys())))
        updated_perf = dict()
        for key in all_perf_counters:
            updated_perf[key[prefix_length:]] = all_perf_counters[key]
        self.counters = updated_perf
        self.filename = filename

    def spec_init(self, spec_dir: str, spec_name: str, spec_json):
        """init PerfCounters in SPEC result directory

        Args:
            spec_dir (str): SPEC result parent directory
            spec_name (str): spec_name that you need
        """
        all_perf_counters = dict()
        total_weight = 0
        data_iterator = spec_json[spec_name]["points"] if gcc12Enable else spec_json[spec_name]
        for point in data_iterator:
            weight = data_iterator[point]   
            dir_name = "_".join([spec_name, point, weight])
            abs_dir = os.path.join(spec_dir, dir_name)
            if not os.path.exists(abs_dir):
                print(f"{abs_dir}路径不存在")
                exit()
        ### 如果没有指定Json，只有spec_name，则按照这种方式处理
        # for sub_dir in os.listdir(spec_dir):
        #     re_match = self.path_re.match(sub_dir)
        #     test_name = re_match.group("spec_name")
        #     weight = re_match.group("weight")
        #     if test_name != spec_name:
        #         continue
        #     abs_dir = os.path.join(spec_dir, sub_dir)
            tmp_counters = dict()
            # check
            check_file = os.path.join(abs_dir, "simulator_out.txt")
            flag = False
            with open(check_file) as f:
                for line in f:
                    if "EXCEEDING CYCLE/INSTR LIMIT" in line or "GOOD TRAP" in line:
                        flag = True
            if not flag:
                print(os.path.join(abs_dir),"spec 测试失败，请查看结果")
            filename = os.path.join(abs_dir, "simulator_err.txt")
            with open(filename) as f:
                for line in f:
                    perf_match = self.perf_re.match(line.replace("/", "_"))
                    if perf_match:
                        perf_name = ".".join([str(perf_match.group(1)), str(perf_match.group(3))])
                        perf_value = str(perf_match.group(5))
                        perf_name = perf_name.replace(" ", "_").replace("'", "")
                        ### warmup result will be overwritten
                        tmp_counters[perf_name] = perf_value
            ### get the weight accumulation
            for perf_name in tmp_counters:
                all_perf_counters[perf_name] = all_perf_counters.get(perf_name,0) + float(tmp_counters[perf_name]) * float(weight)
            total_weight += float(weight)
        
        ### do noramlization
        if total_weight == 0:
            print(f"{spec_name} does not exists in {spec_dir}")
            exit()
        for perf_name in tmp_counters:
            all_perf_counters[perf_name] = all_perf_counters[perf_name] / float(total_weight)

        prefix_length = len(os.path.commonprefix(list(all_perf_counters.keys())))
        updated_perf = dict()
        for key in all_perf_counters:
            updated_perf[key[prefix_length:]] = all_perf_counters[key]
        self.counters = updated_perf
        self.filename = spec_name

    def add_manip(self, all_manip):
        if len(self.counters) == 0:
            return
        for manip in all_manip:
            if None in map(lambda name: self[name], manip.counters):
                # print(list(map(lambda name: self[name], manip.counters)))
                # print(f"Some counters for {manip.name} is not found. Please check it.")
                continue
            numbers = map(lambda name: int(self[name]), manip.counters)
            try:
                self.counters[manip.name] = str(manip.func(*numbers))
            except:
                pass

    def get_counter(self, name, strict=False):
        key = self.counters.get(name, "")
        if strict or key != "":
            return key
        matched_keys = list(filter(lambda k: k.endswith(name), self.keys()))
        if len(matched_keys) == 0:
            return None
        if len(matched_keys) > 1:
            print(f"more than one found for {name}!! Use the first one.")
        return self.counters[matched_keys[0]]

    def get_counters(self):
        return self.counters

    def keys(self):
        return self.counters.keys()

    def __getitem__(self, index):
        return self.get_counter(index)

    def __iter__(self):
        return self.counters.__iter__()

def get_rs_manip():
    all_manip = []
    alu_bypass_from_mdu = PerfManip(
        name = "global.rs.alu_bypass_from_mdu",
        counters = [
            "exuBlocks.scheduler.issue_fire",
            "exuBlocks.scheduler.rs.source_bypass_6_0",
            "exuBlocks.scheduler.rs.source_bypass_6_1",
            "exuBlocks.scheduler.rs.source_bypass_6_2",
            "exuBlocks.scheduler.rs.source_bypass_6_3",
            "exuBlocks.scheduler.rs.source_bypass_7_0",
            "exuBlocks.scheduler.rs.source_bypass_7_1",
            "exuBlocks.scheduler.rs.source_bypass_7_2",
            "exuBlocks.scheduler.rs.source_bypass_7_3"
        ],
        func = lambda fire, b60, b61, b62, b63, b70, b71, b72, b3: (b60 + b61 + b62 + b63 + b70 + b71 + b72 + b3)# / fire
    )
    # all_manip.append(alu_bypass_from_mdu)
    mdu_bypass_from_mdu = PerfManip(
        name = "global.rs.mdu_bypass_from_mdu",
        counters = [
            "exuBlocks_1.scheduler.rs.deq_fire_0",
            "exuBlocks_1.scheduler.rs.deq_fire_1",
            "exuBlocks_1.scheduler.rs.source_bypass_4_0",
            "exuBlocks_1.scheduler.rs.source_bypass_4_1",
            "exuBlocks_1.scheduler.rs.source_bypass_5_0",
            "exuBlocks_1.scheduler.rs.source_bypass_5_1"
        ],
        func = lambda fire0, fire1, b40, b41, b50, b51: (b40 + b41 + b50 + b51)# / (fire0 + fire1)# if (fire0 + fire1) > 0 else 0
    )
    # all_manip.append(mdu_bypass_from_mdu)
    load_bypass_from_mdu = PerfManip(
        name = "global.rs.load_bypass_from_mdu",
        counters = [
            "memScheduler.rs.deq_fire_0",
            "memScheduler.rs.deq_fire_1",
            "memScheduler.rs.source_bypass_6_0",
            "memScheduler.rs.source_bypass_6_1",
            "memScheduler.rs.source_bypass_7_0",
            "memScheduler.rs.source_bypass_7_1"
        ],
        func = lambda fire0, fire1, b60, b61, b70, b71: (b60 + b61 + b70 + b71)# / (fire0 + fire1)# if (fire0 + fire1) > 0 else 0
    )
    # all_manip.append(load_bypass_from_mdu)
    alu_issue_exceed_limit = PerfManip(
        name = "global.rs.alu_issue_exceed_limit",
        counters = [
            "exuBlocks.scheduler.rs.rs_0.statusArray.not_selected_entries",
            "exuBlocks.scheduler.rs.rs_1.statusArray.not_selected_entries",
            "ctrlBlock.rob.clock_cycle"
        ],
        func = lambda ex0, ex1, cycle : (ex0 + ex1) / cycle
    )
    # all_manip.append(alu_issue_exceed_limit)
    alu_issue_exceed_limit_instr = PerfManip(
        name = "global.rs.alu_issue_exceed_limit_instr",
        counters = [
            "exuBlocks.scheduler.rs.rs_0.statusArray.not_selected_entries",
            "exuBlocks.scheduler.rs.rs_1.statusArray.not_selected_entries",
            "exuBlocks.scheduler.issue_fire"
        ],
        func = lambda ex0, ex1, cycle : (ex0 + ex1) / cycle
    )
    # all_manip.append(alu_issue_exceed_limit_instr)
    return all_manip

def get_fu_manip():
    all_manip = []
    div_0_in_blocked = PerfManip(
        name = "global.fu.div_0_in_blocked",
        counters = ["exeUnits_0.div.in_fire", "exeUnits_0.div.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(div_0_in_blocked)
    div_1_in_blocked = PerfManip(
        name = "global.fu.div_1_in_blocked",
        counters = ["exeUnits_1.div.in_fire", "exeUnits_1.div.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(div_1_in_blocked)
    mul_0_in_blocked = PerfManip(
        name = "global.fu.mul_0_in_blocked",
        counters = ["exeUnits_0.mul.in_fire", "exeUnits_0.mul.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(mul_0_in_blocked)
    mul_1_in_blocked = PerfManip(
        name = "global.fu.mul_1_in_blocked",
        counters = ["exeUnits_1.mul.in_fire", "exeUnits_1.mul.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(mul_1_in_blocked)
    i2f_in_blocked = PerfManip(
        name = "global.fu.i2f_in_blocked",
        counters = ["exeUnits_2.i2f.in_fire", "exeUnits_2.i2f.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(i2f_in_blocked)
    f2i_0_in_blocked = PerfManip(
        name = "global.fu.f2i_0_in_blocked",
        counters = ["exeUnits_4.f2i.in_fire", "exeUnits_4.f2i.in_fire"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(f2i_0_in_blocked)
    f2i_1_in_blocked = PerfManip(
        name = "global.fu.f2i_1_in_blocked",
        counters = ["exeUnits_5.f2i.in_fire", "exeUnits_5.f2i.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(f2i_1_in_blocked)
    f2f_0_in_blocked = PerfManip(
        name = "global.fu.f2f_0_in_blocked",
        counters = ["exeUnits_4.f2f.in_fire", "exeUnits_4.f2f.in_fire"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(f2f_0_in_blocked)
    f2f_1_in_blocked = PerfManip(
        name = "global.fu.f2f_1_in_blocked",
        counters = ["exeUnits_5.f2f.in_fire", "exeUnits_5.f2f.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(f2f_1_in_blocked)
    fdiv_sqrt_0_in_blocked = PerfManip(
        name = "global.fu.fdiv_sqrt_0_in_blocked",
        counters = ["exeUnits_4.fdivSqrt.in_fire", "exeUnits_4.fdivSqrt.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(fdiv_sqrt_0_in_blocked)
    fdiv_sqrt_1_in_blocked = PerfManip(
        name = "global.fu.fdiv_sqrt_1_in_blocked",
        counters = ["exeUnits_5.fdivSqrt.in_fire", "exeUnits_5.fdivSqrt.in_valid"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    all_manip.append(fdiv_sqrt_1_in_blocked)
    load_0_in_blocked = PerfManip(
        name = "global.fu.load_0_in_blocked",
        counters = ["memScheduler.rs.deq_fire_0", "memScheduler.rs.deq_valid_0"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    # all_manip.append(load_0_in_blocked)
    load_1_in_blocked = PerfManip(
        name = "global.fu.load_1_in_blocked",
        counters = ["memScheduler.rs.deq_fire_1", "memScheduler.rs.deq_valid_1"],
        func = lambda f, v: (v - f) / v if v != 0 else 0
    )
    # all_manip.append(load_1_in_blocked)
    load_replay_frac = PerfManip(
        name = "global.fu.load_replay_frac",
        counters = ["memScheduler.rs.deq_fire_0", "memScheduler.rs.deq_fire_1", "memScheduler.rs.deq_not_first_issue_0", "memScheduler.rs.deq_not_first_issue_1"],
        func = lambda f0, f1, r0, r1: (r0 + r1) / (f0 + f1) if (f0 + f1) != 0 else 0
    )
    # all_manip.append(load_replay_frac)
    store_replay_frac = PerfManip(
        name = "global.fu.store_replay_frac",
        counters = ["memScheduler.rs_1.deq_fire_0", "memScheduler.rs_1.deq_fire_1", "memScheduler.rs_1.deq_not_first_issue_0", "memScheduler.rs_1.deq_not_first_issue_1"],
        func = lambda f0, f1, r0, r1: (r0 + r1) / (f0 + f1) if (f0 + f1) != 0 else 0
    )
    # all_manip.append(store_replay_frac)
    return all_manip

def get_wpu_manip():
    all_manip = []
    # Flip rate
    all_manip.append(PerfManip(
        name = "global.T_ICache",
        counters = [
            "icache.dataArray.data_read_counter",
            "ctrlBlock.rob.clock_cycle"
        ],
        func = lambda cnt, time: 512.0 * cnt / time
    ))
    all_manip.append(PerfManip(
        name = "global.T_DCache",
        counters = [
            "dcache.bankedDataArray.data_read_counter",
            "ctrlBlock.rob.clock_cycle"
        ],
        func = lambda cnt, time: 64.0 * cnt / time
    ))

    # iwpu precision
    all_manip.append(PerfManip(
        name = "global.iwpu_pred_precision",
        counters = [
            "icache.iwpu.wpu_pred_succ",
            "icache.iwpu.wpu_pred_total"
        ],
        func = lambda succ, total: 1.0 * succ / total
    ))
    all_manip.append(PerfManip(
        name = "global.iwpu_part_pred_precision",
        counters = [
            "icache.mainPipe.iwpu.wpu_pred_succ",
            "icache.mainPipe.iwpu.wpu_pred_total",
            "icache.replacePipe.iwpu.wpu_pred_succ",
            "icache.replacePipe.iwpu.wpu_pred_total",
        ],
        func = lambda succ1, total1, succ2, total2: 1.0 * (succ1 + succ2) / (total1 + total2)
    ))
    all_manip.append(PerfManip(
        name = "global.iwpu_part0_pred_precision",
        counters = [
            "icache.mainPipe.iwpu.wpu_pred_succ",
            "icache.mainPipe.iwpu.wpu_pred_total",
        ],
        func = lambda succ, total: 1.0 * succ / total
    ))
    all_manip.append(PerfManip(
        name = "global.iwpu_part1_pred_precision",
        counters = [
            "icache.replacePipe.iwpu.wpu_pred_succ",
            "icache.replacePipe.iwpu.wpu_pred_total",
        ],
        func = lambda succ, total: 1.0 * succ / total
    ))
    # dwpu precision
    all_manip.append(PerfManip(
        name = "global.dwpu_pred_precision",
        counters = [
            "dcache.dwpu.wpu_pred_succ",
            "dcache.dwpu.wpu_pred_total"
        ],
        func = lambda succ, total: 1.0 * succ / total
    ))
    all_manip.append(PerfManip(
        name = "global.dwpu_part_pred_precision",
        counters = [
            "dcache.ldu_0.dwpu.wpu_pred_succ",
            "dcache.ldu_0.dwpu.wpu_pred_total",
            "dcache.ldu_1.dwpu.wpu_pred_succ",
            "dcache.ldu_1.dwpu.wpu_pred_total",
        ],
        func = lambda succ1, total1, succ2, total2: (1.0 * succ1 / total1 + 1.0 * succ2 / total2) / 2
    ))
    all_manip.append(PerfManip(
        name = "global.dwpu_part0_pred_precision",
        counters = [
            "dcache.ldu_0.dwpu.wpu_pred_succ",
            "dcache.ldu_0.dwpu.wpu_pred_total",
        ],
        func = lambda succ, total: 1.0 * succ / total
    ))
    all_manip.append(PerfManip(
        name = "global.dwpu_part1_pred_precision",
        counters = [
            "dcache.ldu_1.dwpu.wpu_pred_succ",
            "dcache.ldu_1.dwpu.wpu_pred_total",
        ],
        func = lambda succ, total: 1.0 * succ / total
    ))
    # iwpu mpki
    all_manip.append(PerfManip(
        name = "global.iwpu_pred_mpki",
        counters = [
            "icache.iwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail, instr: 1000.0 * fail / instr
    ))
    all_manip.append(PerfManip(
        name = "global.iwpu_part_pred_mpki",
        counters = [
            "icache.mainPipe.iwpu.wpu_pred_fail",
            "icache.replacePipe.iwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail1, fail2, instr: 1000.0 * (fail1 + fail2) / instr
    ))
    all_manip.append(PerfManip(
        name = "global.iwpu_part0_pred_mpki",
        counters = [
            "icache.mainPipe.iwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail, instr: 1000.0 * fail / instr
    ))
    all_manip.append(PerfManip(
        name = "global.iwpu_part1_pred_mpki",
        counters = [
            "icache.replacePipe.iwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail, instr: 1000.0 * fail / instr
    ))
    # dwpu mpki
    all_manip.append(PerfManip(
        name = "global.dwpu_pred_mpki",
        counters = [
            "dcache.dwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail, instr: 1000.0 * fail / instr
    ))
    all_manip.append(PerfManip(
        name = "global.dwpu_part_pred_mpki",
        counters = [
            "dcache.ldu_0.dwpu.wpu_pred_fail",
            "dcache.ldu_1.dwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail1, fail2, instr: 1000.0 * (fail1 + fail2) / instr
    ))
    all_manip.append(PerfManip(
        name = "global.dwpu_part0_pred_mpki",
        counters = [
            "dcache.ldu_0.dwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail, instr: 1000.0 * fail / instr
    ))
    all_manip.append(PerfManip(
        name = "global.dwpu_part1_pred_mpki",
        counters = [
            "dcache.ldu_1.dwpu.wpu_pred_fail",
            "commitInstr"
        ],
        func = lambda fail, instr: 1000.0 * fail / instr
    ))
    return all_manip

def get_all_manip():
    all_manip = []
    ipc = PerfManip(
        name = "global.IPC",
        counters = [f"clock_cycle",
        f"commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    all_manip.append(ipc)
    branch_mpki = PerfManip(
        name = "global.branch_prediction_mpki",
        counters = [f"ftq.BpWrong",
        f"commitInstr"],
        func = lambda wrong, instr: 1000 * wrong / instr
    )
    all_manip.append(branch_mpki)
    load_latency = PerfManip(
        name = "global.load_instr_latency",
        counters = ["rob.load_latency_execute", "rob.load_instr_cnt"],
        func = lambda latency, count: latency / count
    )
    all_manip.append(load_latency)
    fma_latency = PerfManip(
        name = "global.fma_instr_latency",
        counters = ["rob.fmac_latency_execute_fma", "rob.fmac_instr_cnt_fma"],
        func = lambda latency, count: latency / count if count != 0 else 0
    )
    all_manip.append(fma_latency)
    icache_miss_rate = PerfManip(
        name = "global.icache_miss_rate",
        counters = [f"frontend.ifu.icache.req", f"frontend.ifu.icache.miss"],
        func = lambda req, miss: miss / req
    )
    # all_manip.append(icache_miss_rate)
    dtlb_miss_rate = PerfManip(
        name = "global.dtlb_miss_rate",
        counters = [f"memBlock.TLB.first_access0", f"memBlock.TLB.first_miss0",
            f"memBlock.TLB_1.first_access0", f"memBlock.TLB_1.first_miss0",
            f"memBlock.TLB_2.first_access0", f"memBlock.TLB_2.first_miss0",
            f"memBlock.TLB_3.first_access0", f"memBlock.TLB_3.first_miss0"],
        func = lambda req1, miss1, req2, miss2, req3, miss3, req4, miss4: (miss1 + miss2 + miss3 + miss4) / (req1 + req2 + req3 + req4) if ((req1 + req2 + req3 + req4) > 0) else 0
    )
    all_manip.append(dtlb_miss_rate)
    dtlb_sa_percent = PerfManip(
        name = "global.dtlb_sa_hit_percent",
        counters = [f"memBlock.TLB.tlb_normal_sa.hit", f"memBlock.TLB.tlb_super_fa.hit",
                   f"memBlock.TLB_1.tlb_normal_sa.hit", f"memBlock.TLB_1.tlb_super_fa.hit",
                   f"memBlock.TLB_2.tlb_normal_sa.hit", f"memBlock.TLB_2.tlb_super_fa.hit",
                   f"memBlock.TLB_3.tlb_normal_sa.hit", f"memBlock.TLB_3.tlb_super_fa.hit"],
        func = lambda sa0, fa0, sa1, fa1, sa2, fa2, sa3, fa3: (sa0 + sa1 + sa2 + sa3) / (sa0 + sa1 + sa2 + sa3 + fa0 + fa1 + fa2 + fa3) if ((sa0 + sa1 + sa2 + sa3 + fa0 + fa1 + fa2 + fa3) > 0) else 0
    )
    all_manip.append(dtlb_sa_percent)
    ldtlb_miss_rate = PerfManip(
        name = "global.ldtlb_miss_rate",
        # counters = [f"memBlock.TLB.first_access0", f"memBlock.TLB.first_miss0",
        #     f"memBlock.TLB_1.first_access0", f"memBlock.TLB_1.first_miss0"],
        # func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2) if ((req1 + req2) > 0) else 0
        counters = [f"memBlock.dtlb_ld_tlb_ld.first_access0", f"memBlock.dtlb_ld_tlb_ld.first_miss0"],
        func = lambda req, miss: 1.0*miss / req if (req > 0) else 0
    )
    all_manip.append(ldtlb_miss_rate)
    ldtlb_sa_percent = PerfManip(
        name = "global.ldtlb_sa_hit_percent",
        counters = [f"memBlock.TLB.tlb_normal_sa.hit", f"memBlock.TLB.tlb_super_fa.hit",
                   f"memBlock.TLB_1.tlb_normal_sa.hit", f"memBlock.TLB_1.tlb_super_fa.hit"],
        func = lambda sa0, fa0, sa1, fa1: (sa0 + sa1) / (sa0 + sa1 + fa0 + fa1) if ((sa0 + sa1 + fa0 + fa1) > 0) else 0
    )
    all_manip.append(ldtlb_sa_percent)
    sttlb_miss_rate = PerfManip(
        name = "global.sttlb_miss_rate",
        # counters = [f"memBlock.TLB_2.first_access0", f"memBlock.TLB_2.first_miss0",
        #     f"memBlock.TLB_2.first_access0", f"memBlock.TLB_2.first_miss0"],
        # func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2) if ((req1 + req2) > 0) else 0
        counters = [f"memBlock.dtlb_st_tlb_st.first_access0", f"memBlock.dtlb_st_tlb_st.first_miss0"],
        func = lambda req, miss: 1.0*miss / req if (req > 0) else 0
    )
    all_manip.append(sttlb_miss_rate)
    sttlb_sa_percent = PerfManip(
        name = "global.sttlb_sa_hit_percent",
        counters = [f"memBlock.TLB_2.tlb_normal_sa.hit", f"memBlock.TLB_2.tlb_super_fa.hit",
                   f"memBlock.TLB_3.tlb_normal_sa.hit", f"memBlock.TLB_3.tlb_super_fa.hit"],
        func = lambda sa0, fa0, sa1, fa1: (sa0 + sa1) / (sa0 + sa1 + fa0 + fa1) if ((sa0 + sa1 + fa0 + fa1) > 0) else 0
    )
    all_manip.append(sttlb_sa_percent)
    ptw_access_latency = PerfManip(
        name = "global.ptw_access_latency",
        counters = [f"dtlbRepeater1.inflight_cycle", f"dtlbRepeater1.ptw_req_count"],
        func = lambda cycle, count: cycle / count if (count > 0) else 0
    )
    all_manip.append(ptw_access_latency)
    dcache_load_miss_rate = PerfManip(
        name = "global.dcache_load_miss_rate_first_issue",
        counters = [f"LoadUnit_0.s2_in_fire_first_issue", f"LoadUnit_0.s2_dcache_miss_first_issue",
            f"LoadUnit_1.s2_in_fire_first_issue", f"LoadUnit_1.s2_dcache_miss_first_issue"],
        func = lambda req1, miss1, req2, miss2: (miss1 + miss2) / (req1 + req2)
    )
    all_manip.append(dcache_load_miss_rate)
    branch_mispred = PerfManip(
        name = "global.branch_mispred",
        counters = [f"ftq.BpRight", f"ftq.BpWrong"],
        func = lambda right, wrong: wrong / (right + wrong)
    )
    all_manip.append(branch_mispred)
    load_replay_rate = PerfManip(
        name = "global.load_replay_rate",
        counters = [f"ftq.replayRedirect", f"rob.commitInstrLoad"],
        func = lambda redirect, load: redirect / load
    )
    # all_manip.append(load_replay_rate)
    ptw_mem_latency = PerfManip(
        name = "global.ptw_mem_latency",
        counters = [
            "core.memBlock.ptw.ptw.mem_count",
            "core.memBlock.ptw.ptw.mem_cycle"
        ],
        func = lambda count, cycle : cycle / count if count > 0 else 0
    )
    all_manip.append(ptw_mem_latency)
    l2tlb_cache_l2 = PerfManip(
        name = "global.ptw.l2hit_rate",
        counters = [
            "core.memBlock.ptw.ptw.cache.l2_hit_first",
            'core.memBlock.ptw.ptw.cache.access_first',
        ],
        func = lambda hit, access : hit / access if access > 0 else 0
    )
    all_manip.append(l2tlb_cache_l2)
    l2tlb_cache_pte = PerfManip(
        name = "global.ptw.pte_hit_rate",
        counters = [
            "core.memBlock.ptw.ptw.cache.pte_hit_first",
            'core.memBlock.ptw.ptw.cache.access_first',
        ],
        func = lambda hit, access : hit / access if access > 0 else 0
    )
    all_manip.append(l2tlb_cache_pte)
    l2tlb_cache_pte_pre = PerfManip(
        name = "global.ptw.pte_hit_pre_rate",
        counters = [
            "core.memBlock.ptw.ptw.cache.pte_hit_pre_first",
            'core.memBlock.ptw.ptw.cache.pte_hit_first',
        ],
        func = lambda pre, hit : pre / hit if hit > 0 else 0
    )
    all_manip.append(l2tlb_cache_pte_pre)
    l2tlb_cache_pre_hit = PerfManip(
        name = "global.ptw.pre_pte_hit_rate",
        counters = [
            "core.memBlock.ptw.ptw.cache.pre_pte_hit_first",
            'core.memBlock.ptw.ptw.cache.pre_access_first',
        ],
        func = lambda hit, access : hit / access if access > 0 else 0
    )
    all_manip.append(l2tlb_cache_pre_hit)

    l2cache_hit_rate = PerfManip(
        name = "global.l2cache_hit_rate",
        counters = [f"l2top.l2cache.slices_0.mainPipe.a_req_miss", f"l2top.l2cache.slices_0.mainPipe.a_req_hit", 
                    f"l2top.l2cache.slices_1.mainPipe.a_req_miss", f"l2top.l2cache.slices_1.mainPipe.a_req_hit", 
                    f"l2top.l2cache.slices_2.mainPipe.a_req_miss", f"l2top.l2cache.slices_2.mainPipe.a_req_hit", 
                    f"l2top.l2cache.slices_3.mainPipe.a_req_miss", f"l2top.l2cache.slices_3.mainPipe.a_req_hit"],
        func = lambda miss0, hit0, miss1, hit1, miss2, hit2, miss3, hit3  : 
            (hit0 + hit1 + hit2 + hit3) / (hit0 + hit1 + hit2 + hit3 + miss0 + miss1 + miss2 + miss3)  if (hit0 + hit1 + hit2 + hit3 + miss0 + miss1 + miss2 + miss3) > 0 else 0
    )
    all_manip.append(l2cache_hit_rate)
    l2cache_acq_hit_rate = PerfManip(
        name = "global.l2cache_acq_hit_rate",
        counters = [f"l2top.l2cache.slices_0.mainPipe.acquire_miss", f"l2top.l2cache.slices_0.mainPipe.acquire_hit", 
                    f"l2top.l2cache.slices_1.mainPipe.acquire_miss", f"l2top.l2cache.slices_1.mainPipe.acquire_hit", 
                    f"l2top.l2cache.slices_2.mainPipe.acquire_miss", f"l2top.l2cache.slices_2.mainPipe.acquire_hit", 
                    f"l2top.l2cache.slices_3.mainPipe.acquire_miss", f"l2top.l2cache.slices_3.mainPipe.acquire_hit"],
        func = lambda miss0, hit0, miss1, hit1, miss2, hit2, miss3, hit3  : 
            (hit0 + hit1 + hit2 + hit3) / (hit0 + hit1 + hit2 + hit3 + miss0 + miss1 + miss2 + miss3)  if (hit0 + hit1 + hit2 + hit3 + miss0 + miss1 + miss2 + miss3) > 0 else 0
    )
    all_manip.append(l2cache_acq_hit_rate)

    l2cache_mpki_load = PerfManip(
        name = "global.l2cache_mpki_load",
        counters = [
            "l2cache.slices_0.mainPipe.a_req_miss", "l2cache.slices_1.mainPipe.a_req_miss",
            "l2cache.slices_2.mainPipe.a_req_miss", "l2cache.slices_3.mainPipe.a_req_miss",
            "commitInstr"
        ],
        func = lambda miss0, miss1, miss2, miss3, instr :
            1000 * (miss0 + miss1 + miss2 + miss3) / instr
    )
    all_manip.append(l2cache_mpki_load)
    l3cache_mpki_load = PerfManip(
        name = "global.l3cache_mpki_load",
        counters = [
            "L3_bank_0_A_channel_AcquireBlock_fire", "L3_bank_0_A_channel_Get_fire",
            "L3_bank_1_A_channel_AcquireBlock_fire", "L3_bank_1_A_channel_Get_fire",
            "L3_bank_2_A_channel_AcquireBlock_fire", "L3_bank_2_A_channel_Get_fire",
            "L3_bank_3_A_channel_AcquireBlock_fire", "L3_bank_3_A_channel_Get_fire",
            "commitInstr"
        ],
        func = lambda fire1, fire2, fire3, fire4, fire5, fire6, fire7, fire8, instr :
            1000 * (fire1 + fire2 + fire3 + fire4 + fire5 + fire6 + fire7 + fire8) / instr
    )
    all_manip.append(l3cache_mpki_load)
    all_manip += get_wpu_manip()
    # all_manip += get_rs_manip()
    # all_manip += get_fu_manip()
    return all_manip


def get_prefix_length(names):
    return len(os.path.commonprefix(names))

def merge_perf_counters(all_perf, verbose=False):
    def extract_numbers(s):
        re_digits = re.compile(r"(\d+)")
        pieces = re_digits.split(s)
        # convert int strings to int
        pieces = list(map(lambda x: int(x) if x.isdecimal() else x.lower(), pieces))
        return pieces
    all_names = sorted(list(set().union(*list(map(lambda s: s.keys(), all_perf)))), key=extract_numbers)
    all_perf = sorted(all_perf, key=lambda x: extract_numbers(x.filename))
    filenames = list(map(lambda x: x.filename, all_perf))
    # remove common prefix
    prefix_length = get_prefix_length(filenames) if len(filenames) > 1 else 0
    if prefix_length > 0:
        filenames = list(map(lambda name: name[prefix_length:], filenames))
    # remove common suffix
    reversed_names = list(map(lambda x: x[::-1], filenames))
    suffix_length = get_prefix_length(reversed_names) if len(filenames) > 1 else 0
    if suffix_length > 0:
        filenames = list(map(lambda name: name[:-suffix_length], filenames))
    all_sources = filenames

    # Yield first row as header, use header.cases as [0] to avoid conflict in pick()
    yield ["header.cases"] + all_sources

    pbar = tqdm(total = len(all_names), disable = not verbose, position = 3)
    for name in all_names:
        if verbose:
            # pbar.display(f"Merging perf counter: {name}", 2)
            pbar.update(1)
        yield [name] + list(map(lambda perf: perf.get_counter(name, strict=True), all_perf))

def pick(include_names, name, include_manip = False):
    '''
        Filter output rows by name
    '''
    if len(include_names) == 0:
        return True
    if name == "header.cases": # First row is header, should always be true
        return True
    if include_manip and name.startswith("global."):
        return True
    for r in include_names:
        if r.search(name) != None:
            return True
    return False

def perf_work(manip, work_queue, perf_queue):
  while not work_queue.empty():
    item = work_queue.get()
    try:
        perf = PerfCounters(item)
        perf.add_manip(manip)
        perf_queue.put(perf)
    except:
      perf_queue.put(None)

def main(pfiles, output_file, include_names, include_manip=False, verbose=False, jobs = 1, normalize_spec = None, dirs = None):
    all_perf = []
    all_manip = get_all_manip()
    
    work_queue = Queue()
    perf_queue = Queue()
    process_lst = []
    if len(normalize_spec) > 0 and dirs is not None:
        for spec_name in normalize_spec.keys():
            work_queue.put((dirs, spec_name, normalize_spec))
    else:
        for filename in pfiles:
            work_queue.put(filename)
    files_count = work_queue.qsize()
    pbar = tqdm(total = files_count, disable = not verbose, position = 1)
    for i in range(0, jobs):
        p = Process(target = perf_work, args=(all_manip, work_queue, perf_queue))
        process_lst.append(p)
        p.start()
    perf_lst = []
    while len(perf_lst) != files_count:
      if verbose:
        pbar.display(f"Processing files with {jobs} threads ...", 0)
      perf = perf_queue.get()
      perf_lst.append(perf)
      if perf and perf.counters:
        all_perf.append(perf)
      elif perf:
        pbar.write(f"{perf.filename} skipped because it is empty.")
      pbar.update(1)
    for p in process_lst:
      p.join()

    with open(output_file, 'w') as csvfile:
        csvwriter = csv.writer(csvfile)
        for output_row in merge_perf_counters(all_perf, verbose):
            if pick(include_names, output_row[0], include_manip):
                csvwriter.writerow(output_row)
    pbar.write(f"Finished processing {len(all_perf)} non-empty files.")

def find_simulator_err(pfiles):
    if len(pfiles) > 1:
        return sum(map(lambda filename: find_simulator_err([filename]), pfiles), [])
    # recursively find simulator_err.txt
    base_path = pfiles[0]
    all_files = []
    for sub_dir in os.listdir(base_path):
        sub_path = os.path.join(base_path, sub_dir)
        if os.path.isfile(sub_path) and sub_dir == "simulator_err.txt":
            all_files.append(sub_path)
        elif os.path.isdir(sub_path):
            all_files += find_simulator_err([sub_path])
    return all_files

def find_all_in_dir(dir_path):
    base_path = dir_path
    all_files = []
    for sub_dir in os.listdir(base_path):
        sub_path = os.path.join(base_path, sub_dir)
        if os.path.isfile(sub_path):
            all_files.append(sub_path)
        else:
            print("find non-file" + sub_path)
    return all_files

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='performance counter log parser')
    parser.add_argument('pfiles', metavar='filename', type=str, nargs='*', default=None,
                        help='performance counter log')
    parser.add_argument('--output', '-o', default="stats.csv", help='output file')
    parser.add_argument('--filelist', '-f', default=None, help="filelist")
    parser.add_argument('--recursive', '-r', action='store_true', default=False,
        help="recursively find simulator_err.txt")
    parser.add_argument('--dir', '-d', default = None, help="directory")
    parser.add_argument('--spec_json', '-S', default = None, help="spec test json")
    parser.add_argument('--verbose', '-v', action='store_true', default=False,
        help="show processing logs")
    parser.add_argument('--include', '-I', action='extend', nargs='+', type=str, help="select given counters (using re)")
    parser.add_argument('--manip', '-M', action='store_true', default=False, help="whether inlcude the manipulations in the res (for --include args)")
    parser.add_argument('--jobs', '-j', default=1, type=int, help="processing files in 'j' threads")

    args = parser.parse_args()

    if args.filelist is not None:
        with open(args.filelist) as f:
            args.pfiles = list(map(lambda x: x.strip(), f.readlines()))

    # for every file in SPEC tests
    if args.recursive:
        args.pfiles = find_simulator_err(args.pfiles)

    normalize_spec = dict()
    if args.dir is not None:
        if args.spec_json is not None:
            with open(args.spec_json) as f:
                normalize_spec = json.load(f)
        else:
            args.pfiles += find_all_in_dir(args.dir)

    if args.include is not None:
        args.include = list(map(lambda x: re.compile(x), args.include))
    else:
        args.include = list()

    print("input files:")
    for filename in args.pfiles:
        print(filename)
        if not os.path.isfile(filename):
            print(f"{filename} is not a file. Probably you need --recursive?")
            exit()

    print(f"output file: {args.output}")

    main(args.pfiles, args.output, args.include, args.manip, args.verbose, args.jobs, normalize_spec, args.dir)
