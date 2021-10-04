#! /usr/bin/env python3

import argparse
import json
import os
import random
import subprocess
import time

import perf


class GCPT(object):
  STATE_NONE     = 0
  STATE_RUNNING  = 1
  STATE_FINISHED = 2
  STATE_ABORTED  = 3

  def __init__(self, base_path, benchspec, point, weight):
    self.base_path = base_path
    self.benchspec = benchspec
    self.point = point
    self.weight = weight
    self.state = self.STATE_NONE
    self.num_cycles = -1
    self.num_instrs = -1

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

  def result_path(self, base_path):
    return  os.path.join(base_path, self.__str__())

  def err_path(self, base_path):
    return os.path.join(self.result_path(base_path), "simulator_err.txt")

  def out_path(self, base_path):
    return os.path.join(self.result_path(base_path), "simulator_out.txt")

  def get_state(self, base_path):
    self.state = self.STATE_NONE
    if os.path.exists(self.out_path(base_path)):
      self.state = self.STATE_RUNNING
      with open(self.out_path(base_path)) as f:
        for line in f:
          if "ABORT at pc" in line or "FATAL:" in line:
            self.state = self.STATE_ABORTED
          elif "EXCEEDING CYCLE/INSTR LIMIT" in line:
            self.state = self.STATE_FINISHED
          else:
            if "cycleCnt = " in line:
              cycle_cnt_str = line.split("cycleCnt =")[1].split(", ")[0]
              self.num_cycles = int(cycle_cnt_str.replace(",", "").strip())
            if "instrCnt = " in line:
              instr_cnt_str = line.split("instrCnt =")[1].split(", ")[0]
              self.num_instrs = int(instr_cnt_str.replace(",", "").strip())
    return self.state

  def state_str(self):
    state_strs = ["S_NONE", "S_RUNNING", "S_FINISHED", "S_ABORTED"]
    return state_strs[self.state]

  def show(self, base_path):
    self.get_state(base_path)
    instr_str = f"instrCnt = {self.num_instrs}"
    cycle_str = f"cycleCnt = {self.num_cycles}"
    print(f"GCPT {str(self)}: {self.state_str()}, {instr_str}, {cycle_str}")


def load_all_gcpt(gcpt_path, json_path, state_filter=None, xs_path=None, sorted_by=None):
  all_gcpt = []
  with open(json_path) as f:
    data = json.load(f)
  for benchspec in data:
    for point in data[benchspec]:
      weight = data[benchspec][point]
      gcpt = GCPT(gcpt_path, benchspec, point, weight)
      if state_filter is None:
        all_gcpt.append(gcpt)
      else:
        perf_base_path = get_perf_base_path(xs_path)
        if gcpt.get_state(perf_base_path) in state_filter:
          all_gcpt.append(gcpt)
  if sorted_by is None:
    return all_gcpt
  else:
    return sorted(all_gcpt, key=sorted_by)


def get_perf_base_path(xs_path):
  return os.path.join(xs_path, "SPEC06_EmuTasks_10_03_2021")


def xs_run(workloads, xs_path, warmup, max_instr):
  emu_path = os.path.join(xs_path, "build/emu")
  base_arguments = [emu_path, '--enable-fork', '-W', str(warmup), '-I', str(max_instr), '-i']
  proc_count = 0
  finish_count = 0
  max_pending_proc = 128
  pending_proc = []
  error_proc = []
  try:
    while len(workloads) > 0 or len(pending_proc) > 0:
      has_pending_workload = len(workloads) > 0 and len(pending_proc) >= max_pending_proc
      has_pending_proc = len(pending_proc) > 0
      if has_pending_workload or has_pending_proc:
          finished_proc = list(filter(lambda p: p[1].poll() is not None, pending_proc))
          for workload, proc in finished_proc:
            print(f"{workload} has finished")
            pending_proc.remove((workload, proc))
            if proc.returncode < 0:
              print(f"[ERROR] {workload} exits with code {proc.returncode}")
              error_proc.append(workload)
              continue
            finish_count += 1
          if len(finished_proc) == 0:
            time.sleep(1)
      can_launch = max_pending_proc - len(pending_proc)
      for workload in workloads[:can_launch]:
        print(workload)
        if len(pending_proc) < max_pending_proc:
          workload_path = workload.get_path()
          perf_base_path = get_perf_base_path(xs_path)
          result_path = workload.result_path(perf_base_path)
          if not os.path.exists(result_path):
            os.makedirs(result_path, exist_ok=True)
          stdout_file = workload.out_path(perf_base_path)
          stderr_file = workload.err_path(perf_base_path)
          with open(stdout_file, "w") as stdout, open(stderr_file, "w") as stderr:
            random_seed = random.randint(0, 9999)
            run_cmd = base_arguments + [workload_path] + ["-s", f"{random_seed}"]
            print(f"cmd {proc_count}: {run_cmd}")
            proc = subprocess.Popen(run_cmd, stdout=stdout, stderr=stderr)
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
  if len(error_proc) > 0:
    print("Errors:")
    for i, workload in enumerate(error_proc):
      print(f"  ({i + 1}) {workload}")


def get_all_manip():
    all_manip = []
    ipc = perf.PerfManip(
        name = "IPC",
        counters = [f"roq.clock_cycle", f"roq.commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    all_manip.append(ipc)
    return all_manip

def get_total_inst(benchspec):
  if True:
    base_path = "/bigdata/zzf/spec_cpt/logs/profiling/"
    filename = benchspec + ".log"
    bench_path = os.path.join(base_path, filename)
  else:
    base_path = "/bigdata/zyy/checkpoints_profiles/betapoint_profile_06_fix_mem_addr"
    filename = "nemu_out.txt"
    bench_path = os.path.join(base_path, benchspec, filename)
  f = open(bench_path)
  for line in f:
    if "total guest instructions" in line:
      f.close()
      return int(line.split("instructions = ")[1].replace("\x1b[0m", ""))
  return None

def get_spec_reftime(benchspec):
  base_path = "/bigdata/cpu2006v99/benchspec/CPU2006"
  for dirname in os.listdir(base_path):
    if benchspec in dirname:
      reftime_path = os.path.join(base_path, dirname, "data/ref/reftime")
      f = open(reftime_path)
      reftime = int(f.readlines()[-1])
      f.close()
      return reftime
  return None

def xs_report(all_gcpt, xs_path):
  frequency = 1.5 * (10 ** 9)
  gcpt_ipc = dict()
  keys = list(map(lambda gcpt: gcpt.benchspec, all_gcpt))
  for k in keys:
    gcpt_ipc[k] = []
  for i, gcpt in enumerate(all_gcpt):
    print(f"Processing {i + 1} out of {len(all_gcpt)} {str(gcpt)}...")
    perf_path = gcpt.err_path(get_perf_base_path(xs_path))
    counters = perf.PerfCounters(perf_path)
    counters.add_manip(get_all_manip())
    # when the spec has not finished, IPC may be None
    if counters["IPC"] is not None:
      gcpt_ipc[gcpt.benchspec].append([float(gcpt.weight), float(counters["IPC"])])
    else:
      print("IPC not found in", gcpt.benchspec, gcpt.point, gcpt.weight)
  spec_time = {}
  for benchspec in gcpt_ipc:
    total_weight = sum(map(lambda info: info[0], gcpt_ipc[benchspec]))
    total_cpi = sum(map(lambda info: info[0] / info[1], gcpt_ipc[benchspec])) / total_weight
    num_instr = get_total_inst(benchspec)
    num_seconds = total_cpi * num_instr / frequency
    print(benchspec, "coverage", total_weight)
    spec_name = benchspec.split("_")[0]
    spec_time[spec_name] = spec_time.get(spec_name, 0) + num_seconds
  for spec_name in spec_time:
    reftime = get_spec_reftime(spec_name)
    score = reftime / spec_time[spec_name]
    print(spec_name, score, score / 1.5)

def xs_show(all_gcpt, xs_path):
  for gcpt in all_gcpt:
    perf_base_path = get_perf_base_path(xs_path)
    gcpt.show(perf_base_path)

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="autorun script for xs")
  parser.add_argument('gcpt_path', metavar='gcpt_path', type=str,
                      help='path to gcpt checkpoints')
  parser.add_argument('json_path', metavar='json_path', type=str,
                      help='path to gcpt json')
  parser.add_argument('--xs', help='path to xs')
  parser.add_argument('--warmup', '-W', default=20000000, help="warmup instr count")
  parser.add_argument('--max-instr', '-I', default=40000000, help="max instr count")
  parser.add_argument('--report', '-R', action='store_true', default=False, help='report only')
  parser.add_argument('--show', '-S', action='store_true', default=False, help='show list of gcpt only')

  args = parser.parse_args()

  gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
  # gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
  #   state_filter=[GCPT.STATE_ABORTED], xs_path=args.xs, sorted_by=lambda x: x.num_cycles)

  if args.show:
    xs_show(gcpt, args.xs)
  elif args.report:
    xs_report(gcpt, args.xs)
  else:
    xs_run(gcpt, args.xs, args.warmup, args.max_instr)

