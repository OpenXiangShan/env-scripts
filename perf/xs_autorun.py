#! /usr/bin/env python3

import argparse
import json
import os
import random
import shutil
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
    self.ipc = -1
    self.num_seconds = -1
    self.waveform = []

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
    for point in data[benchspec]:
      weight = data[benchspec][point]
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
  if sorted_by is None:
    return all_gcpt
  else:
    return sorted(all_gcpt, key=sorted_by)

tasks_dir = "SPEC06_EmuTasks_10_22_2021"

def get_perf_base_path(xs_path):
  return os.path.join(xs_path, tasks_dir)

def xs_run(workloads, xs_path, warmup, max_instr, threads):
  emu_path = os.path.join(xs_path, "build/emu")
  nemu_so_path = os.path.join(xs_path, "ready-to-run/riscv64-nemu-interpreter-so")
  base_arguments = [emu_path, '--diff', nemu_so_path, '--dump-tl', '--enable-fork', '-W', str(warmup), '-I', str(max_instr), '-i']
  # base_arguments = [emu_path, '-W', str(warmup), '-I', str(max_instr), '-i']
  proc_count, finish_count = 0, 0
  max_pending_proc = 128 // threads
  pending_proc, error_proc = [], []
  free_cores = list(range(max_pending_proc))
  # skip CI cores
  ci_cores = []#list(range(0, 64))# + list(range(32, 48)) + list(range(56, 64)) + list(range(72, 80))# + list(range(112, 120))
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
            proc = subprocess.Popen(run_cmd, stdout=stdout, stderr=stderr)
          pending_proc.append((workload, proc, allocate_core))
          free_cores = free_cores[1:]
          proc_count += 1
      workloads = workloads[can_launch:]
  except KeyboardInterrupt:
    print("Interrupted. Exiting all programs ...")
    print("Not finished:")
    for i, (workload, proc, _) in enumerate(pending_proc):
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
  base_dir = "/nfs/home/share/checkpoints_profiles"
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
    else:
      print("Unknown ISA\n")
      return None
  elif spec_version == 2017:
    if isa == "rv64gc_old":
      base_path = os.path.join(base_dir, "spec17_rv64gc_o2_50m/profiling")
      filename = "nemu_out.txt"
      bench_path = os.path.join(base_path, benchspec, filename)
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

def get_spec_reftime(benchspec, spec_version):
  if spec_version == 2006:
    base_path = "/nfs/home/share/cpu2006v99/benchspec/CPU2006"
    for dirname in os.listdir(base_path):
      if benchspec in dirname:
        reftime_path = os.path.join(base_path, dirname, "data/ref/reftime")
        f = open(reftime_path)
        reftime = int(f.readlines()[-1])
        f.close()
        return reftime
  elif spec_version == 2017:
    base_path = "/nfs/home/share/spec2017_slim/benchspec/CPU"
    for dirname in os.listdir(base_path):
      if benchspec in dirname and dirname.endswith("_r"):
        reftime_path = os.path.join(base_path, dirname, "data/refrate/reftime")
        f = open(reftime_path)
        reftime = int(f.readlines()[0].split()[-1])
        f.close()
        return reftime
  return None

def get_spec_int(spec_version):
  if spec_version == 2006:
    return [
      "400.perlbench",
      "401.bzip2",
      "403.gcc",
      "429.mcf",
      "445.gobmk",
      "456.hmmer",
      "458.sjeng",
      "462.libquantum",
      "464.h264ref",
      "471.omnetpp",
      "473.astar",
      "483.xalancbmk"
    ]
  elif spec_version == 2017:
    return [
      "500.perlbench_r",
      "502.gcc_r",
      "505.mcf_r",
      "520.omnetpp_r",
      "523.xalancbmk_r",
      "525.x264_r",
      "531.deepsjeng_r",
      "541.leela_r",
      "548.exchange2_r",
      "557.xz_r"
    ]
  return None


def get_spec_fp(spec_version):
  if spec_version == 2006:
    return [
      "410.bwaves",
      "416.gamess",
      "433.milc",
      "434.zeusmp",
      "435.gromacs",
      "436.cactusADM",
      "437.leslie3d",
      "444.namd",
      "447.dealII",
      "450.soplex",
      "453.povray",
      "454.Calculix",
      "459.GemsFDTD",
      "465.tonto",
      "470.lbm",
      "481.wrf",
      "482.sphinx3",
    ]
  elif spec_version == 2017:
    return [
      "503.bwaves_r",
      "507.cactuBSSN_r",
      "508.namd_r",
      "510.parest_r",
      "511.povray_r",
      "519.lbm_r",
      "521.wrf_r",
      "526.blender_r",
      "527.cam4_r",
      "538.imagick_r",
      "544.nab_r",
      "549.fotonik3d_r",
      "554.roms_r"
    ]
  return None


def xs_report(all_gcpt, xs_path, spec_version, isa):
  # frequency/GHz
  frequency = 2
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
  print()
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
  print("==================== Score ===================")
  total_count = 0
  total_score = 1
  spec_score = dict()
  for spec_name in spec_time:
    reftime = get_spec_reftime(spec_name, spec_version)
    score = reftime / spec_time[spec_name]
    total_count += 1
    total_score *= score
    print(f"{spec_name:>15}: {score:6.2f}, {score / frequency:6.2f}")
    spec_score[spec_name] = score
  geomean_score = total_score ** (1 / total_count)
  print(f"SPEC{spec_version}@{frequency}GHz: {geomean_score:6.2f}")
  print(f"SPEC{spec_version}/GHz:  {geomean_score / frequency:6.2f}")
  print()
  print(f"********* SPECINT {spec_version} *********")
  specint_list = get_spec_int(spec_version)
  specint_score = 1
  for benchspec in specint_list:
    found = False
    for name in spec_score:
      if name.lower() in benchspec.lower():
        found = True
        score = spec_score[name]
        specint_score *= score
        print(f"{benchspec:>15}: {score:6.2f}, {score / frequency:6.2f}")
    if not found:
      print(f"{benchspec:>15}: N/A")
  geomean_specint_score = specint_score ** (1 / len(specint_list))
  print(f"SPECint{spec_version}@{frequency}GHz: {geomean_specint_score:6.2f}")
  print(f"SPECint{spec_version}/GHz:  {geomean_specint_score / frequency:6.2f}")
  print()
  print(f"********* SPECFP  {spec_version} *********")
  specfp_list = get_spec_fp(spec_version)
  specfp_score = 1
  for benchspec in specfp_list:
    found = False
    for name in spec_score:
      if name.lower() in benchspec.lower():
        found = True
        score = spec_score[name]
        specfp_score *= score
        print(f"{benchspec:>15}: {score:6.2f}, {score / frequency:6.2f}")
    if not found:
      print(f"{benchspec:>15}: N/A")
  geomean_specfp_score = specfp_score ** (1 / len(specfp_list))
  print(f"SPECfp{spec_version}@{frequency}GHz: {geomean_specfp_score:6.2f}")
  print(f"SPECfp{spec_version}/GHz: {geomean_specfp_score / frequency:6.2f}")


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

  args = parser.parse_args()

  if args.dir is not None:
    tasks_dir = args.dir

  if args.ref is None:
    args.ref = args.xs

  gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
  gcpt = gcpt#[830:]
  # gcpt = gcpt[810:]
  #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
  #state_filter=[GCPT.STATE_RUNNING, GCPT.STATE_NONE, GCPT.STATE_ABORTED], xs_path=args.ref)#[810:]
  #gcpt = gcpt[66:] + gcpt[:66]

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
    xs_report(gcpt, args.ref, args.version, args.isa)
  else:
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path)
    #gcpt = load_all_gcpt(args.gcpt_path, args.json_path,
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_FINISHED], xs_path=args.ref, sorted_by=lambda x: -x.num_cycles)
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
      #state_filter=[GCPT.STATE_ABORTED], xs_path=args.ref, sorted_by=lambda x: x.get_ipc())
      #state_filter=[GCPT.STATE_RUNNING], xs_path=args.ref, sorted_by=lambda x: x.benchspec.lower())
    xs_run(gcpt, args.xs, args.warmup, args.max_instr, args.threads)

