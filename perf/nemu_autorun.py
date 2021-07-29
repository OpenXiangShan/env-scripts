#! /usr/bin/env python3

import argparse
import csv
import enum
import json
import os
import subprocess
import time


class GCPT(object):
  def __init__(self, base_path, benchspec, point, weight):
    self.base_path = base_path
    self.benchspec = benchspec
    self.point = point
    self.weight = weight

  def get_path(self):
    dir_name = self.__str__()
    bin_dir = os.path.join(self.base_path, dir_name, "0")
    bin_file = list(os.listdir(bin_dir))
    assert(len(bin_file) == 1)
    bin_path = os.path.join(bin_dir, bin_file[0])
    assert(os.path.isfile(bin_path))
    return bin_path

  def __str__(self):
      return "_".join([self.benchspec, self.point, str(self.weight)])


def load_all_gcpt(gcpt_path, json_path):
  all_gcpt = []
  with open(json_path) as f:
    data = json.load(f)
  for benchspec in data:
    for point in data[benchspec]:
      weight = data[benchspec][point]
      gcpt = GCPT(gcpt_path, benchspec, point, weight)
      all_gcpt.append(gcpt)
  return all_gcpt


def parse_stdout(bytes):
  out = bytes.decode("utf-8")
  out = list(filter(lambda x: x.startswith("[PERF] "), out.split("\n")))
  counters = map(lambda x: x.replace("[PERF] ", "").split(",")[0], out)
  values = map(lambda x: int(x.replace("[PERF] ", "").split(",")[1]), out)
  return list(counters), list(values)


def nemu_run(workloads, nemu_path, output_file, max_instr):
  counters, values = ["workload"], []
  nemu_path = os.path.join(nemu_path, "build/riscv64-nemu-interpreter")
  base_arguments = [nemu_path, '-b', '-I', str(max_instr)]
  proc_count = 0
  finish_count = 0
  max_pending_proc = 200
  pending_proc = []
  error_proc = []
  try:
    while len(workloads) > 0 or len(pending_proc) > 0:
      has_pending_workload = len(workloads) > 0 and len(pending_proc) >= max_pending_proc
      has_pending_proc = len(pending_proc) > 0
      if has_pending_workload or has_pending_proc:
          finished_proc = list(filter(lambda p: p[1].poll() is not None, pending_proc))
          for workload, proc in finished_proc:
            pending_proc.remove((workload, proc))
            if proc.returncode < 0:
              print(f"[ERROR] {workload} exits with code {proc.returncode}")
              error_proc.append(workload)
              continue
            outs, _ = proc.communicate()
            c, v = parse_stdout(outs)
            print(finish_count, workload, c, v)
            if len(counters) == 1:
              counters += c
            assert(c == counters[1:])
            values.append([workload] + v)
            finish_count += 1
          if len(finished_proc) == 0:
            time.sleep(1)
      can_launch = max_pending_proc - len(pending_proc)
      for workload in workloads[:can_launch]:
        if len(pending_proc) < max_pending_proc:
          workload_path = workload.get_path()
          cmd = " ".join(base_arguments + [workload_path])
          print(f"cmd {proc_count}: {cmd}")
          proc = subprocess.Popen(base_arguments + [workload_path], stdout=subprocess.PIPE)
          pending_proc.append((workload, proc))
          proc_count += 1
      workloads = workloads[can_launch:]
  except KeyboardInterrupt:
    print("Interrupted. Exiting all programs ...")
    print("Not finished:")
    for i, (workload, proc) in enumerate(pending_proc):
      proc.terminate()
      print(f"  ({i + 1}) {workload}")
    print("Not started:")
    for i, workload in enumerate(workloads):
      print(f"  ({i + 1}) {workload}")
  with open(output_file, "w") as f:
    writer = csv.writer(f, delimiter=",")
    writer.writerow(counters)
    writer.writerows(values)
  if len(error_proc) > 0:
    print("Errors:")
    for i, workload in enumerate(error_proc):
      print(f"  ({i + 1}) {workload}")


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="autorun script for nemu")
  parser.add_argument('gcpt_path', metavar='gcpt_path', type=str,
                      help='path to gcpt checkpoints')
  parser.add_argument('json_path', metavar='json_path', type=str,
                      help='path to gcpt json')
  parser.add_argument('--nemu', default="/home/xyn/tools/NEMU", help='path to nemu')
  parser.add_argument('--max-instr', '-I', default=100000000, help="max instr counter")
  parser.add_argument('--output', '-o', default="nemu.csv", help='output file')

  args = parser.parse_args()

  gcpt = load_all_gcpt(args.gcpt_path, args.json_path)

  nemu_run(gcpt, args.nemu, args.output, args.max_instr)

