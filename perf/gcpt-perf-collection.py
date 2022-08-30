#! /usr/bin/env python3

import argparse
import os
import re

# GCPT perf counter collection
# Input is all the gcpt. This scripts will add all the gcpt into each spec
# and output the sum
# Now: only selected perf are concerned
# TODO: collect all the perf counters

# Usage:
# python3 gcpt-perf-collection.py | tee perf_counter.csv
# parameters are written in codes
# root_path: gcpt path

# Output:
# specx,perf1,perf2,perf3
# specy,perf1,perf2,perf3
# specz,perf1,perf2,perf3

# How the scripts do
# 1. read all the cpt file, store the perf by "name,time"
# 2. for each spec, add the cpt together
# 3. normalization by sum of weight
# 4. print

path_re = re.compile(r'(?P<spec_name>\w+((_\w+)|(_\w+\.\w+)|-\d+|))_(?P<time_point>\d+)_(?P<weight>0\.\d+)')

root_path = "/nfs/home/share/EmuTasks/SPEC06_EmuTasks_08_15_2022"
spec_list_path = "/nfs/home/zhangzifei/work/env-scripts/fpga/spec06-all-name-new.txt"

cpt_list = os.listdir(root_path)
cpt_list.remove("git_commit.txt")
# print(cpt)
cpt_record = {}

spec_list = []
for s in open(spec_list_path).readlines():
  spec_list.append(s.strip())
if ("gamess_exam29" in spec_list):
  spec_list.remove("gamess_exam29")
spec_record = {}


# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter
perf_conter = [
  ["ctrlBlock.rob: commitInstr, ", "instrCnt"],
  ["ctrlBlock.rob: clock_cycle, ", "clockCycle"],
  ["ctrlBlock.fusionDecoder: fused_instr, ", "fused_instr"],
  ["ctrlBlock.rename: fused_lui_load_instr_count, ", "fused_lui_load"],
  ["ctrlBlock.rename: in,   ", "rename_in"],
  ["ctrlBlock.rename: move_instr_count,  ", "move_elimination"],
  ["ctrlBlock.rob: fmac_instr_cnt_fma,  ", "fmac_instr_cnt"],
  ["ctrlBlock.rob: fmac_latency_execute_fma,   ", "fmac_latency_execute"],
  ["ctrlBlock.rob: commitInstrMoveElim,   ", "moveElim"],
  ["ctrlBlock.rob: commitInstrFused,  ", "commitFused"]
]

class SPEC(object):
  def __init__(self, spec_name):
    self.name = spec_name
    self.weight_sum = 0
    self.cpts = {}
    self.record = {}
    for pc in perf_conter:
      self.record[pc[1]] = 0

  def add_cpt(self, cpt):
    if (self.name != cpt.name):
      print("error 1")
      exit()
    weight = cpt.weight
    self.weight_sum = self.weight_sum + cpt.weight
    for pc in perf_conter:
      self.record[pc[1]] = self.record[pc[1]] + weight * cpt.record[pc[1]]

class CPT(object):
  def __init__(self, spec_name, spec_weight, spec_path):
    file = open(spec_path+"/"+"simulator_err.txt", "r")
    self.name = spec_name
    self.weight = float(spec_weight)
    self.record = {}
    for line in file:
      for pc in perf_conter:
        if pc[0] in line:
          number = int(line.split(pc[0])[1].split(", ")[0])
          self.record[pc[1]] = number

    # print(self.name+","+self.weight, end="")
    # for pc in perf_conter:
    #   if pc[1] in self.record.keys():
    #     print(","+str(self.record[pc[1]]), end="")
    # print()


for cpt in cpt_list:
  re_match = path_re.match(cpt)
  name = re_match.group("spec_name")
  weight = re_match.group("weight")
  time_point = re_match.group("time_point")
  # print(cpt)
  cpt_path = root_path + "/" + cpt
  cpt_record[name+","+time_point] = CPT(name, weight, cpt_path)

  # print(re_match.group("spec_name"))
  # print(re_match.group("time_point"))
  # print(re_match.group("weight"))


for s in spec_list:
  spec_record[s] = SPEC(s)

for key in cpt_record.keys():
  (name, time_point) = key.split(",")
  spec_record[name].add_cpt(cpt_record[key])

# normalization
for s in spec_list:
  spec = spec_record[s]
  for pc in perf_conter:
    spec.record[pc[1]] = spec.record[pc[1]] / spec.weight_sum

def iprint(str):
  print(","+str, end="")

print("spec", end="")
for pc in perf_conter:
  iprint(pc[1])
print(",fused+luiload,fused,luiload,move,fmalatency,commitFuesd")


for s in spec_list:
  spec = spec_record[s]
  print(spec.name, end="")
  for pc in perf_conter:
    iprint("%.2f"%(spec.record[pc[1]]))
  iprint("%.4f"%((spec.record["fused_instr"]+spec.record["fused_lui_load"])/spec.record["rename_in"]))
  iprint("%.4f"%(spec.record["fused_instr"] / spec.record["rename_in"]))
  iprint("%.4f"%(spec.record["fused_lui_load"]/spec.record["rename_in"]))
  iprint("%.4f"%(spec.record["moveElim"] / spec.record["instrCnt"]))
  if (spec.record["fmac_instr_cnt"] == 0):
    iprint("0")
  else:
    iprint("%.4f"%(spec.record["fmac_latency_execute"]/spec.record["fmac_instr_cnt"]))
  iprint("%.4f"%(spec.record["commitFused"]/spec.record["instrCnt"]))
  print()
