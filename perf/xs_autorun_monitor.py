#! /usr/bin/env python3

import argparse
import json
import os
import sys
import random
import shutil
import signal
import subprocess
import time
from multiprocessing import Process, Queue

import perf
import spec_score


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
    self.ipc = -1
    self.num_seconds = -1
    self.waveform = []

  def get_path(self):
    dir_name = self.__str__()
    bin_dir = os.path.join(self.base_path, self.benchspec, str(self.point))
    bin_file = list(os.listdir(bin_dir))
    assert(len(bin_file) == 1)
    bin_path = os.path.join(bin_dir, bin_file[0])
    assert(os.path.isfile(bin_path))
    return bin_path

  def __str__(self):
    return "_".join([self.benchspec, self.point, str(self.weight)])

  def result_path(self, base_path):
    return os.path.join(base_path, self.__str__())

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
          if "ABORT at pc" in line or "FATAL:" in line or "Error:" in line:
            self.state = self.STATE_ABORTED
          elif "EXCEEDING CYCLE/INSTR LIMIT" in line or "GOOD TRAP" in line:
            self.state = self.STATE_FINISHED
          else:
            if "cycleCnt = " in line:
              cycle_cnt_str = line.split("cycleCnt =")[1].split(", ")[0]
              self.num_cycles = int(cycle_cnt_str.replace(",", "").strip())
            if "instrCnt = " in line:
              instr_cnt_str = line.split("instrCnt =")[1].split(", ")[0]
              self.num_instrs = int(instr_cnt_str.replace(",", "").strip())
            if "Host time spent" in line:
              second_cnt_str = line.split("Host time spent:")[1].replace("ms", "")
              self.num_seconds = int(second_cnt_str.replace(",", "").strip()) / 1000
    return self.state

  def get_simulation_cps(self):
    return int(round(self.num_cycles / self.num_seconds))

  def get_ipc(self):
    if self.num_cycles == 0:
      return -1
    return round(self.num_instrs / self.num_cycles, 3)

  def state_str(self):
    state_strs = ["S_NONE", "S_RUNNING", "S_FINISHED", "S_ABORTED"]
    return state_strs[self.state]

  def debug(self, base_path):
    if os.path.exists(self.out_path(base_path)):
      with open(self.out_path(base_path)) as f:
        for line in f:
          if "dump wave to" in line:
            wave_path = line.replace("...", "").replace("dump wave to", "").strip()
            if not os.path.exists(wave_path):
              print(f"{wave_path} does not exist!!!")
            else:
              print(f"cp {wave_path} {self.result_path(base_path)}")
              shutil.copy(wave_path, self.result_path(base_path))

  def show(self, base_path):
    self.get_state(base_path)
    attributes = {
      "instrCnt": self.num_instrs,
      "cycleCnt": self.num_cycles,
      "totalIPC": f"{self.get_ipc():.3f}",
      "simSpeed": self.get_simulation_cps()
    }
    attributes_str = ", ".join(map(lambda k: f"{k:>8} = {str(attributes[k]):>9}", attributes))
    print(f"GCPT {str(self):>50}: {self.state_str():>10}, {attributes_str}")


def load_all_gcpt(gcpt_path, json_path, state_filter=None, xs_path=None, sorted_by=None):
  perf_filter = [
    ("l3cache_mpki_load",      lambda x: float(x) < 3),
    ("branch_prediction_mpki", lambda x: float(x) > 5),
  ]
  perf_filter = None
  all_gcpt = []
  with open(json_path) as f:
    data = json.load(f)
  for benchspec in data:
    #if "gcc" not in benchspec:# or "hmmer" in benchspec:
    #  continue
    for point in data[benchspec]["points"]:
      cpt = point
      weight = data[benchspec]["points"][point]
      gcpt = GCPT(gcpt_path, benchspec, point, weight)
      if state_filter is None and perf_filter is None:
        all_gcpt.append(gcpt)
        continue
      perf_match, state_match = True, True
      if state_filter is not None:
        state_match = False
        perf_base_path = get_perf_base_path(xs_path)
        if gcpt.get_state(perf_base_path) in state_filter:
          state_match = True
      if state_match and perf_filter is not None:
        perf_path = gcpt.err_path(get_perf_base_path(xs_path))
        counters = perf.PerfCounters(perf_path)
        counters.add_manip(get_all_manip())
        for fit in perf_filter:
          if not fit[1](counters[fit[0]]):
            perf_match = False
      if perf_match and state_match:
        all_gcpt.append(gcpt)
  if sorted_by is not None:
    all_gcpt = sorted(all_gcpt, key=sorted_by)
  dump_json = True
  dump_json = False
  if dump_json:
    json_dict = dict()
    for gcpt in all_gcpt:
      bench_dict = json_dict.get(gcpt.benchspec, dict())
      bench_dict[gcpt.point] = gcpt.weight
      json_dict[gcpt.benchspec] = bench_dict
    with open("gcpt.json", "w") as f:
      json.dump(json_dict, f)
  return all_gcpt

tasks_dir = "SPEC06_EmuTasks_10_22_2021"

def get_perf_base_path(xs_path):
  return os.path.join(xs_path, tasks_dir)

def xs_run(workloads, xs_path, warmup, max_instr, threads):
  emu_path = os.path.join(xs_path, "build/emu")
  nemu_so_path = os.path.join(xs_path, "ready-to-run/riscv64-nemu-interpreter-so")
  #nemu_so_path = os.path.join(xs_path, "ready-to-run/riscv64-spike-so")
  base_arguments = [emu_path, '--diff', nemu_so_path, '--dump-db', '--enable-fork', '-W', str(warmup), '-I', str(max_instr), '-i']
  # base_arguments = [emu_path, '-W', str(warmup), '-I', str(max_instr), '-i']
  proc_count, finish_count = 0, 0
  max_pending_proc = 128 // threads
  pending_proc, error_proc = [], []
  free_cores = list(range(max_pending_proc))
  # skip CI cores
  ci_cores = []#list(range(0, 64))# + list(range(32, 48))
  for core in list(map(lambda x: x // threads, ci_cores)):
    if core in free_cores:
      free_cores.remove(core)
      max_pending_proc -= 1
  print("Free cores:", free_cores)
  try:
    while len(workloads) > 0 or len(pending_proc) > 0:
      has_pending_workload = len(workloads) > 0 and len(pending_proc) >= max_pending_proc
      has_pending_proc = len(pending_proc) > 0
      if has_pending_workload or has_pending_proc:
          finished_proc = list(filter(lambda p: p[1].poll() is not None, pending_proc))
          for workload, proc, core in finished_proc:
            print(f"{workload} has finished")
            pending_proc.remove((workload, proc, core))
            free_cores.append(core)
            if proc.returncode != 0:
              print(f"[ERROR] {workload} exits with code {proc.returncode}")
              error_proc.append(workload)
              continue
            finish_count += 1
          if len(finished_proc) == 0:
            time.sleep(1)
      can_launch = max_pending_proc - len(pending_proc)
      for workload in workloads[:can_launch]:
        if len(pending_proc) < max_pending_proc:
          allocate_core = free_cores[0]
          numa_cmd = []
          if threads > 1:
            start_core = threads * allocate_core
            end_core = threads * allocate_core + threads - 1
            numa_node = 1 if start_core >= 64 else 0
            numa_cmd = ["numactl", "-m", str(numa_node), "-C", f"{start_core+128}-{end_core+128}"]
            numa_cmd = ["numactl", "-m", str(numa_node), "-C", f"{start_core}-{end_core}"]
          workload_path = workload.get_path()
          perf_base_path = get_perf_base_path(xs_path)
          result_path = workload.result_path(perf_base_path)
          if not os.path.exists(result_path):
            os.makedirs(result_path, exist_ok=True)
          stdout_file = workload.out_path(perf_base_path)
          stderr_file = workload.err_path(perf_base_path)
          with open(stdout_file, "w") as stdout, open(stderr_file, "w") as stderr:
            random_seed = random.randint(0, 9999)
            run_cmd = numa_cmd + base_arguments + [workload_path] + ["-s", f"{random_seed}"]
            cmd_str = " ".join(run_cmd)
            print(f"cmd {proc_count}: {cmd_str}")
            proc = subprocess.Popen(run_cmd, stdout=stdout, stderr=stderr, preexec_fn=os.setsid)
          pending_proc.append((workload, proc, allocate_core))
          free_cores = free_cores[1:]
          proc_count += 1
      workloads = workloads[can_launch:]
  except KeyboardInterrupt:
    print("Interrupted. Exiting all programs ...")
    print("Not finished:")
    for i, (workload, proc, _) in enumerate(pending_proc):
      os.killpg(os.getpgid(proc.pid), signal.SIGINT)
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
        counters = [f"clock_cycle", f"commitInstr"],
        func = lambda cycle, instr: instr * 1.0 / cycle
    )
    all_manip.append(ipc)
    l3cache_mpki_load = perf.PerfManip(
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
    branch_mpki = perf.PerfManip(
      name = "global.branch_prediction_mpki",
      counters = ["ftq.BpWrong", "commitInstr"],
      func = lambda wrong, instr: 1000 * wrong / instr
    )
    all_manip.append(branch_mpki)
    return all_manip

def get_total_inst(benchspec, spec_version, isa):
  print(isa)

'''
def get_total_inst(benchspec, spec_version, isa):
  # base_dir = "/nfs-nvme/home/share/checkpoints_profiles"
  base_dir = "/nfs/home/wulingyun/ci-workloads/o3_20m-gcc12_profiling"
  if spec_version == 2006:
    if isa == "rv64gc_old":
      base_path = os.path.join(base_dir, "spec06_rv64gc_o2_50m/profiling")
      filename = "nemu_out.txt"
      bench_path = os.path.join(base_path, benchspec, filename)
    elif isa == "rv64gc":
      base_path = os.path.join(base_dir, "spec06_rv64gc_o2_20m/logs/profiling/")
      filename = benchspec + ".log"
      bench_path = os.path.join(base_path, filename)
    elif isa == "rv64gcb":
      # base_path = os.path.join(base_dir, "spec06_rv64gcb_o2_20m/logs/profiling/")
      # filename = benchspec + ".log"
      # bench_path = os.path.join(base_path, filename)
      base_path = base_dir
      filename = os.path.join(benchspec, "stdout.log")
      bench_path =  os.path.join(base_path, filename)
    elif isa == "rv64gcb_o3":
      base_path = os.path.join(base_dir, "spec06_rv64gcb_o3_20m/logs/profiling/")
      filename = benchspec + ".log"
      bench_path = os.path.join(base_path, filename)
    else:
      print("Unknown ISA\n")
      return None
  elif spec_version == 2017:
    if isa == "rv64gc_old":
      base_path = os.path.join(base_dir, "spec17_rv64gc_o2_50m/profiling")
      filename = "nemu_out.txt"
      bench_path = os.path.join(base_path, benchspec, filename)
    elif isa == "rv64gcb":
      base_path = os.path.join(base_dir, "spec17_rv64gcb_o2_20m/logs/profiling/")
      filename = benchspec + ".log"
      bench_path = os.path.join(base_path, filename)
    elif isa == "rv64gcb_o3":
      base_path = os.path.join(base_dir, "spec17_rv64gcb_o3_20m/logs/profiling/")
      filename = benchspec + ".log"
      bench_path = os.path.join(base_path, filename)
    else:
      print("Unknown ISA\n")
      return None
  else:
    print("Unknown SPEC version\n")
    return None
  f = open(bench_path)
  for line in f:
    if "total guest instructions" in line:
      f.close()
      # return int(line.split("instructions = ")[1].replace("\x1b[0m", ""))
      inst = int(line.split("instructions = ")[1].replace("\x1b[0m", "").replace(',', ''))
  return None
'''

def xs_report_ipc(xs_path, gcpt_queue, result_queue):
  while not gcpt_queue.empty():
    gcpt = gcpt_queue.get()
    # print(f"Processing {str(gcpt)}...")
    perf_path = gcpt.err_path(get_perf_base_path(xs_path))
    counters = perf.PerfCounters(perf_path)
    counters.add_manip(get_all_manip())
    # when the spec has not finished, IPC may be None
    if counters["IPC"] is not None:
      result_queue.put([gcpt.benchspec, [float(gcpt.weight), float(counters["IPC"])]])
    else:
      print("IPC not found in", gcpt.benchspec, gcpt.point, gcpt.weight)

def xs_report(all_gcpt, xs_path, spec_version, isa, num_jobs):
  # frequency/GHz
  frequency = 2
  gcpt_ipc = dict()
  keys = list(map(lambda gcpt: gcpt.benchspec, all_gcpt))
  for k in keys:
    gcpt_ipc[k] = []
  # multi-threading for processing the performance counters
  gcpt_queue = Queue()
  for gcpt in all_gcpt:
    gcpt_queue.put(gcpt)
  result_queue = Queue()
  process_list = []
  for _ in range(num_jobs):
    p = Process(target=xs_report_ipc, args=(xs_path, gcpt_queue, result_queue))
    process_list.append(p)
    p.start()
  for p in process_list:
    p.join()
  while not result_queue.empty():
    result = result_queue.get()
    gcpt_ipc[result[0]].append(result[1])
  print("=================== Coverage ==================")
  spec_time = {}
  for benchspec in gcpt_ipc:
    total_weight = sum(map(lambda info: info[0], gcpt_ipc[benchspec]))
    total_cpi = sum(map(lambda info: info[0] / info[1], gcpt_ipc[benchspec])) / total_weight
    num_instr = get_total_inst(benchspec, spec_version, isa)
    num_seconds = total_cpi * num_instr / (frequency * (10 ** 9))
    spec_name = benchspec.split("_")[0]
    spec_time[spec_name] = spec_time.get(spec_name, 0) + num_seconds
  print()
  spec_score.get_spec_score(spec_time, spec_version, frequency)
  print(f"Number of Checkpoints: {len(all_gcpt)}")
  print(f"SPEC CPU Version: SPEC CPU{spec_version}, {isa}")


def xs_show(all_gcpt, xs_path):
  for gcpt in all_gcpt:
    perf_base_path = get_perf_base_path(xs_path)
    gcpt.show(perf_base_path)

def xs_debug(all_gcpt, xs_path):
  for gcpt in all_gcpt:
    perf_base_path = get_perf_base_path(xs_path)
    gcpt.debug(perf_base_path)

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="autorun script for xs")
  parser.add_argument('gcpt_path', metavar='gcpt_path', type=str,
                      help='path to gcpt checkpoints')
  parser.add_argument('json_path', metavar='json_path', type=str,
                      help='path to gcpt json')
  parser.add_argument('--xs', help='path to xs')
  parser.add_argument('--ref', default=None, type=str, help='path to ref')
  parser.add_argument('--warmup', '-W', default=20000000, type=int, help="warmup instr count")
  parser.add_argument('--max-instr', '-I', default=40000000, type=int, help="max instr count")
  parser.add_argument('--threads', '-T', default=1, type=int, help="number of emu threads")
  parser.add_argument('--report', '-R', action='store_true', default=False, help='report only')
  parser.add_argument('--show', '-S', action='store_true', default=False, help='show list of gcpt only')
  parser.add_argument('--debug', '-D', action='store_true', default=False, help='debug options')
  parser.add_argument('--version', default=2006, type=int, help='SPEC version')
  parser.add_argument('--isa', default="rv64gcb", type=str, help='ISA version')
  parser.add_argument('--dir', default=None, type=str, help='SPECTasks dir')
  parser.add_argument('--jobs', '-j', default=1, type=int, help="processing files in 'j' threads")
  parser.add_argument('--output', '-o', default=None, type=str, help='output csv file')

  args = parser.parse_args()

  if args.dir is not None:
    tasks_dir = args.dir

  if args.ref is None:
    args.ref = args.xs

  gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
  gcpt = gcpt#[300:]#[::-1]
  #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
  #        state_filter=[GCPT.STATE_RUNNING, GCPT.STATE_NONE, GCPT.STATE_ABORTED], xs_path=args.ref)
  #gcpt = gcpt[242:]#[::-1]

  if args.show:
    # gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: x.get_simulation_cps())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.get_ipc())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_RUNNING], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
    xs_show(gcpt, args.ref)
  elif args.debug:
    gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
    xs_debug(gcpt, args.ref)
  elif args.report:
    gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
    xs_report(gcpt, args.ref, args.version, args.isa, args.jobs)
  else:
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.get_ipc())
      #state_filter=[GCPT.STATE_RUNNING], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
    print("All:  ", len(gcpt))
    print("First:", gcpt[0])
    print("Last: ", gcpt[-1])
    xs_run(gcpt, args.xs, args.warmup, args.max_instr, args.threads)
