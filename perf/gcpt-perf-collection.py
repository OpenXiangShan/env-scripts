#! /usr/bin/env python3

import argparse
import os
import re
import sys
import time
from multiprocessing import Process, Manager

from perfcounter_list.CalculatorList import *

# GCPT perf counter collection
# Input is all the gcpt. This scripts will add all the gcpt into each spec
# and output the sum
# Now: only selected perf are concerned
# TODO: collect all the perf counters

# Usage:
# python3 gcpt-perf-collection.py path_to_SPEC_EMU_TASKS | tee perf_counter.csv
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

parallel_degree = 128
# parallel_degree = 1


if ((sys.argv[1] == "-h") | (sys.argv[1] == "--help") |
    (len(sys.argv) != 2)):
  print("Usage: python3 gcpt-perf-collection.py path_to_SPEC_EMU_TASKS | tee perf_counter.csv")
  exit()

root_path = sys.argv[1]

# root_path = "/nfs-nvme/home/share/tanghaojin/SPEC06_EmuTasks_topdown_0430_2023"

# This list controls pc that u need
# ===================
# NOTE: change it to select the perf counter u need
# ===================
calculator_list = [
  # CalculatorExample(),
  # CalculatorMemblock(),
  # CalculatorBackend(),
  # CalculatorTopDown(),
  # CalculatorDp2Iq(),
  # CalculatorDataPathRFRead(),
  CalculatorDataPathRFWrite(),
]

path_re = re.compile(r'(?P<spec_name>\w+((_\w+)|(_\w+\.\w+)|-\d+|))_(?P<time_point>\d+)_(?P<weight>0\.\d+)')

abs_path=os.path.dirname(os.path.abspath(__file__))
# root_path = "/nfs/home/share/EmuTasks/SPEC06_EmuTasks_2023_03_31"

cpt_list = os.listdir(root_path)
if ("git_commit.txt" in cpt_list):
  cpt_list.remove("git_commit.txt")
eg_cpt_err_file_path = os.path.join(root_path, cpt_list[0], "simulator_err.txt")
# print(cpt)

cpt_list_list = []
stride = len(cpt_list) // parallel_degree
for i in range(0, len(cpt_list), stride):
  cpt_list_list.append(cpt_list[i: min(len(cpt_list), i+stride)])

spec_list = []

# get spec_list from prepared list
# spec_list_path = f"{abs_path}/../fpga/spec06-all-name-new.txt"
# for s in open(spec_list_path).readlines():
#   spec_list.append(s.strip())
# if ("gamess_exam29" in spec_list):
#   spec_list.remove("gamess_exam29")

# get spec_list from root_path
cpt_spec_name_list = []
for cpt in cpt_list:
  re_match = path_re.match(cpt)
  name = re_match.group("spec_name")
  cpt_spec_name_list.append(name)
spec_list = list(set(cpt_spec_name_list))



# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter
# selected perf counter is defined in perfcounter_list

basic_perf_conter = [
  ["ctrlBlock.rob: commitInstr, ", "instrCnt"],
  ["ctrlBlock.rob: clock_cycle, ", "clockCycle"],
]

perf_conter = basic_perf_conter
for pc in calculator_list:
  perf_conter = perf_conter + pc.get_perf_counter_to_parse(eg_cpt_err_file_path)
# print("perf_conter_map: ", end="")
# print(perf_conter)

perf_counter_to_show_list = []
for calculator in calculator_list:
  perf_counter_to_show_list += calculator.get_perf_counter_to_show(eg_cpt_err_file_path)

# print("perf_counter_to_show_list: ", end="")
# print(perf_counter_to_show_list)

def print_err(msg):
  print(msg, file=sys.stderr)

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
    with open(spec_path+"/"+"simulator_err.txt", "r") as file:
      self.name = spec_name
      self.weight = float(spec_weight)
      self.record = {}
      self.success = False

      count = 0
      for line in file:
        if ("[NEMU] " in line):
          print_err("Extract Fail for [NEMU], name:" + self.name + " file:" + spec_path+"/"+"simulator_err.txt")
          self.success = False
          break
        if ("ctrlBlock.rob: commitInstr, " in line):
          count = count + 1
          self.success = count == 2
          if (count > 2):
            print_err("found more than 2 times of commitInstr, what happened")
        for pc in perf_conter:
          if pc[0] in line:
            # print(f"find: origin {pc[0]} to {pc[1]}")
            number = float(line.split(pc[0])[1].split(", ")[0])
            self.record[pc[1]] = number
      # print(self.name+","+self.weight, end="")
      # for pc in perf_conter:
      #   if pc[1] in self.record.keys():
      #     print(","+str(self.record[pc[1]]), end="")
      # print()
      if not self.success:
        print_err("Extrace Failed for nothing")
        print_err("If you want to skip, manually comment the exit() and print")
        sys.exit()

def extract_cpt(global_dic, cpt):
  re_match = path_re.match(cpt)
  name = re_match.group("spec_name")
  weight = re_match.group("weight")
  time_point = re_match.group("time_point")
  cpt_path = root_path + "/" + cpt
  cpt_obj = CPT(name, weight, cpt_path)
  if cpt_obj.success:
    global_dic[name+","+time_point] = cpt_obj

def collect_cpt_into_spec(global_dic, spec_name):
  spec = SPEC(spec_name)
  for cpt_name, cpt in cpt_record.items():
    (spec_name_cpt, time_point) = cpt_name.split(",")
    if (spec_name == spec_name_cpt):
      spec.add_cpt(cpt)

  # normalization to wegiht 1
  if spec.weight_sum == 0:
    print(s+" weight sum == 0")
  for pc in perf_conter:
    spec.record[pc[1]] = spec.record[pc[1]] / spec.weight_sum

  # extra calculation should be here
  for calculator in calculator_list:
    for key, func in calculator.calculation_list.items():
      spec.record[key] = func(spec.record)

  global_dic[spec_name] = spec

def extract_cpt_multi(global_dic, cpt_list):
  for cpt in cpt_list:
    extract_cpt(global_dic, cpt)

manager = Manager()
cpt_record = manager.dict()
spec_record = manager.dict()

jobs = [Process(target=extract_cpt_multi, args=(cpt_record, cpts)) for cpts in cpt_list_list]
_ = [p.start() for p in jobs]
_ = [p.join()  for p in jobs]

jobs = [Process(target=collect_cpt_into_spec, args=(spec_record, name)) for name in spec_list]
_ = [p.start() for p in jobs]
_ = [p.join()  for p in jobs]

# normalization
# for s in spec_list:
#   spec = spec_record[s]
#   if spec.weight_sum == 0:
#     print(s+" weight sum == 0")
#   for pc in perf_conter:
#     spec.record[pc[1]] = spec.record[pc[1]] / spec.weight_sum
#   # extra calculation should be here
#   for calculator in calculator_list:
#     for key, func in calculator.calculation_list.items():
#       spec.record[key] = func(spec.record)


def iprint(str):
  print(","+str, end="")

print("spec", end="")
for pc in perf_counter_to_show_list:
  iprint(pc)
print()

for s in spec_list:
  spec = spec_record[s]
  print(spec.name, end="")
  for pc in perf_counter_to_show_list:
    iprint("%.4f"%spec.record[pc])
  print()
