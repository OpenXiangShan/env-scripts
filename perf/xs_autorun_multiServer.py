#! /usr/bin/env python3

import argparse
import json
import os
import random
import shutil
import time
import sys
import getpass
import socket
from multiprocessing import Process, Queue
from gcpt import GCPT
import perf
import spec_score
from server import Server
from gcpt_run_time_eval import *
import AutoEmailAlert

tasks_dir = "SPEC06_EmuTasks_10_22_2021"
perf_base_path = ""
def get_perf_base_path(xs_path):
  return os.path.join(xs_path, tasks_dir)

def load_all_gcpt(gcpt_path, json_path, server_num, threads, state_filter=None, xs_path=None, sorted_by=None):
  perf_filter = [
    ("l3cache_mpki_load",      lambda x: float(x) < 3),
    ("branch_prediction_mpki", lambda x: float(x) > 5),
  ]
  perf_filter = None
  all_gcpt = []
  with open(json_path) as f:
    data = json.load(f)
  hour_list=[]
  perf_base_path = get_perf_base_path(xs_path)
  for benchspec in data:
    #if "gcc" not in benchspec:# or "hmmer" in benchspec:
    #  continue
    for point in data[benchspec]:
      weight = data[benchspec][point]
      hour = get_eval_hour(benchspec, point, weight)
      gcpt = GCPT(gcpt_path, perf_base_path, benchspec, point, weight, hour)
      if state_filter is None and perf_filter is None:
        all_gcpt.append(gcpt)
        continue
      perf_match, state_match = True, True
      if state_filter is not None:
        state_match = False
        if gcpt.get_state() in state_filter:
          state_match = True
      if state_match and perf_filter is not None:
        perf_path = gcpt.get_err_path()
        counters = perf.PerfCounters(perf_path)
        counters.add_manip(get_all_manip())
        for fit in perf_filter:
          if not fit[1](counters[fit[0]]):
            perf_match = False
      if perf_match and state_match:
        hour_list.append(hour)
        all_gcpt.append(gcpt)
  print(f"evaluate execute hours: {cal_exe_hours(hour_list, (128 * server_num) // threads)}")

  if sorted_by is not None:
    all_gcpt = sorted(all_gcpt, key=sorted_by)
    hour_list = [g.eval_run_hours for g in all_gcpt]
    print(f"opitimize execute hours: {cal_exe_hours(hour_list, (128 * server_num) // threads)}")
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


def get_server(server_list):
  l = []
  for s in server_list.strip().split(" "):
    l.append(Server(s))
  return l

def xs_run(server_list, workloads, xs_path, warmup, max_instr, threads):
  emu_path = os.path.join(xs_path, "build/emu")
  nemu_so_path = os.path.join(xs_path, "ready-to-run/riscv64-nemu-interpreter-so")
  # nemu_so_path = os.path.join(xs_path, "ready-to-run/riscv64-spike-so")
  base_arguments = [emu_path, '--diff', nemu_so_path, '--enable-fork', '-W', str(warmup), '-I', str(max_instr), '-i']
  # base_arguments = [emu_path, '--diff', nemu_so_path, '-W', str(warmup), '-I', str(max_instr), '-i']
  # base_arguments = [emu_path, '-W', str(warmup), '-I', str(max_instr), '-i']
  servers = get_server(server_list)
  def server_all_free():
    for s in servers:
      if not s.is_free():
        return False
      return True

  try:
    max_num = len(workloads)
    count = 0
    for index in range(max_num):
      workload = workloads[index]
      random_seed = random.randint(0, 9999)
      run_cmd = base_arguments + [workload.get_bin_path()] + ["-s", f"{random_seed}"]

      if not os.path.exists(workload.get_res_dir()):
        os.makedirs(workload.get_res_dir(), exist_ok=True)
      assigned = False
      while not assigned:
        for s in servers:
          if s.assign(f"{workload}", run_cmd, threads, xs_path, workload.get_out_path(), workload.get_err_path()):
            assigned = True
            count = count + 1
            break
        if not assigned:
          time.sleep(1)
          for s in servers:
            s.check_running()
      for s in servers:
        s.check_running()

    if not server_all_free():
      print("Waiting for pending tests to finish")
    while not server_all_free():
      time.sleep(1)
  except KeyboardInterrupt:
    print("Interrupted. Exiting all programs ...")

    pending_tests = []
    success_tests= []
    for s in servers:
      s.stop()
      print(f"{s.ip} stopped")
      pending_tests = pending_tests + s.pending_tests()
      success_tests = success_tests + s.success_tests
    print(f"Finished {len(success_tests)}/{max_num}")
    print(f"Not started {max_num - count}/{max_num}:")
    if (count < max_num):
      for i in range(count, max_num):
        print(f"  ({i + 1 - count}) {workloads[i]}")
    print(f"Not finished {len(pending_tests)}/{max_num}:")
    for i, test in enumerate(pending_tests):
      print(f"  ({i+1}) {test}")

  failed_tests = []
  for s in servers:
    # s.stop()
    # print(f"{s.ip} stopped")
    failed_tests = failed_tests + s.failed_tests
  if len(failed_tests) > 0:
    print(f"Errors {len(failed_tests)}/{max_num}:")
    for i, test in enumerate(failed_tests):
      print(f"  ({i + 1}) {test}")


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
  base_dir = "/nfs-nvme/home/share/checkpoints_profiles"
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
      base_path = os.path.join(base_dir, "spec06_rv64gcb_o2_20m/logs/profiling/")
      filename = benchspec + ".log"
      bench_path = os.path.join(base_path, filename)
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
      return int(line.split("instructions = ")[1].replace("\x1b[0m", ""))
  return None






def xs_report_ipc(xs_path, gcpt_queue, result_queue):
  while not gcpt_queue.empty():
    gcpt = gcpt_queue.get()
    # print(f"Processing {str(gcpt)}...")
    perf_path = gcpt.get_err_path()
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
    print(f"{benchspec:>25} coverage: {total_weight:.2f}")
    spec_name = benchspec.split("_")[0]
    spec_time[spec_name] = spec_time.get(spec_name, 0) + num_seconds
  print()
  spec_score.get_spec_score(spec_time, spec_version, frequency)
  print(f"Number of Checkpoints: {len(all_gcpt)}")
  print(f"SPEC CPU Version: SPEC CPU{spec_version}, {isa}")


def xs_show(all_gcpt):
  for gcpt in all_gcpt:
    gcpt.show()

def xs_debug(all_gcpt):
  for gcpt in all_gcpt:
    gcpt.debug()

if __name__ == "__main__":
  # python3 xs_autorun_v2.py  /nfs-nvme/home/share/checkpoints_profiles/spec06_rv64gcb_o2_20m/take_cpt /nfs-nvme/home/share/checkpoints_profiles/spec06_rv64gc_o2_20m/simpoint_coverage0.8_test.json --xs /nfs/home/username/XiangShan --threads 16 --dir SPEC06_EmuTasks_02_16_2023 -L "107 104"
  # --show for already running result, including "name, state, ipc, sim speed"
  # --debug for error tests
  # --report for spec scores
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
  parser.add_argument('--server-list', '-L', type=str, help="server list, like \"172.28.9.104 172.28.9.107\", support alias")
  parser.add_argument('--report', '-R', action='store_true', default=False, help='report only')
  parser.add_argument('--show', '-S', action='store_true', default=False, help='show list of gcpt only')
  parser.add_argument('--debug', '-D', action='store_true', default=False, help='debug options')
  parser.add_argument('--version', default=2006, type=int, help='SPEC version')
  parser.add_argument('--isa', default="rv64gcb", type=str, help='ISA version')
  parser.add_argument('--dir', default=None, type=str, help='SPECTasks dir')
  parser.add_argument('--jobs', '-j', default=1, type=int, help="processing files in 'j' threads")
  parser.add_argument('--resume', action='store_true', default=False, help="continue to exe, ignore the aborted and success tests")

  args = parser.parse_args()

  if args.dir is not None:
    tasks_dir = args.dir
  perf_base_path = get_perf_base_path(args.xs)

  if args.xs is None:
    print("need --xs")
    sys.exit()

  if args.ref is None:
    args.ref = args.xs

  if args.server_list is None:
    args.server_list = socket.gethostname()
    server_num = 0
  else:
    server_num = len(args.server_list.strip().split(" "))


  # gcpt = gcpt#[300:]#[::-1]
  #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
  #        state_filter=[GCPT.STATE_RUNNING, GCPT.STATE_NONE, GCPT.STATE_ABORTED], xs_path=args.ref)
  #gcpt = gcpt[242:]#[::-1]

  if args.show:
    gcpt = load_all_gcpt(args.gcpt_path, args.json_path, server_num, args.threads)
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: x.get_simulation_cps())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.get_ipc())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_RUNNING], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
    xs_show(gcpt)
  elif args.debug:
    gcpt = load_all_gcpt(args.gcpt_path, args.json_path, server_num, args.threads, 
                         state_filter=[GCPT.STATE_ABORTED], 
                         xs_path=args.xs, 
                         sorted_by=lambda x: -x.num_cycles
                         )
    xs_debug(gcpt)
  elif args.report:
    gcpt = load_all_gcpt(args.gcpt_path, args.json_path, server_num, args.threads,
      state_filter=[GCPT.STATE_FINISHED], xs_path=args.xs, sorted_by=lambda x: x.benchspec.lower())
    xs_report(gcpt, args.ref, args.version, args.isa, args.jobs)
  else:
    state_filter = None
    print("RESUME:", args.resume)
    if args.resume:
      state_filter = [GCPT.STATE_RUNNING, GCPT.STATE_NONE]
    # If just wanna run aborted test, change the script.
    gcpt = load_all_gcpt(args.gcpt_path, args.json_path, server_num, args.threads, 
                         state_filter=state_filter,
                         xs_path=args.xs,
                         sorted_by=lambda x:-x.eval_run_hours
                         )
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.get_ipc())
      #state_filter=[GCPT.STATE_RUNNING], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
    if (len(gcpt) == 0):
      print("All the tests are already finished.")
      print(f"perf_base_path: {perf_base_path}")
      sys.exit()
    print("All:  ", len(gcpt))
    print("First:", gcpt[0])
    print("Last: ", gcpt[-1])
    xs_run(args.server_list, gcpt, args.xs, args.warmup, args.max_instr, args.threads)

    # AutoEmailAlert.inform(0, f"{args.xs}执行完毕", "maxpicca@qq.com")