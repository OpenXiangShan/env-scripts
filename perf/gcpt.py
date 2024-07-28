import os
import shutil

class GCPT(object):
  STATE_NONE     = 0
  STATE_RUNNING  = 1
  STATE_FINISHED = 2
  STATE_ABORTED  = 3

  def __init__(self, gcpt_bin_dir: str, perf_base_dir: str,benchspec: str, point: str, weight: str, eval_run_time: int, gcc12Enable = False):
    self.bin_base_dir = gcpt_bin_dir
    self.benchspec = benchspec
    self.point = point
    self.weight = weight
    self.state = self.STATE_NONE
    self.total_num_cycles = -1
    self.total_num_instrs = -1
    self.second_num_cycles = -1
    self.second_num_instrs = -1
    self.ipc = -1
    self.num_seconds = -1
    self.waveform = []
    self.res_dir = os.path.join(perf_base_dir, self.__str__())
    self.eval_run_time = eval_run_time
    self.gcc12Enable = gcc12Enable

  def __str__(self):
    return "_".join([self.benchspec, self.point, str(self.weight)])

  def get_bin_path(self):
    if self.gcc12Enable:
      bin_dir = os.path.join(self.bin_base_dir, self.benchspec, str(self.point))
    else:
      dir_name = self.__str__()
      bin_dir = os.path.join(self.bin_base_dir, dir_name, "0")
    bin_file = list(os.listdir(bin_dir))
    if len(bin_file) != 1:
      print(bin_file)
    if self.gcc12Enable:
      bin_file = list(filter(lambda x: x != '_0_0.000000_.gz', bin_file))
    assert(len(bin_file) == 1)
    bin_path = os.path.join(bin_dir, bin_file[0])
    assert(os.path.isfile(bin_path))
    return bin_path

  def get_res_dir(self):
    return self.res_dir

  def get_err_path(self):
    return os.path.join(self.res_dir, "simulator_err.txt")

  def get_out_path(self):
    return os.path.join(self.res_dir, "simulator_out.txt")

  def get_state(self):
    self.state = self.STATE_NONE
    if os.path.exists(self.get_out_path()):
      self.state = self.STATE_RUNNING
      with open(self.get_out_path()) as f:
        for line in f:
          if "ABORT at pc" in line or "FATAL:" in line or "Error:" in line:
            self.state = self.STATE_ABORTED
          elif "EXCEEDING CYCLE/INSTR LIMIT" in line or "GOOD TRAP" in line:
            self.state = self.STATE_FINISHED
          else:
            if "cycleCnt = " in line:
              cycle_cnt_str = line.split("cycleCnt =")[1].split(", ")[0]
              self.total_num_cycles = int(cycle_cnt_str.replace(",", "").strip())
            if "instrCnt = " in line:
              instr_cnt_str = line.split("instrCnt =")[1].split(", ")[0]
              self.total_num_instrs = int(instr_cnt_str.replace(",", "").strip())
            if "Host time spent" in line:
              second_cnt_str = line.split("Host time spent:")[1].replace("ms", "")
              self.num_seconds = int(second_cnt_str.replace(",", "").strip()) / 1000

    if os.path.exists(self.get_err_path()):
      # print(f"{self.get_err_path()} does not exist!!!")

      instr_count = 0
      cycle_count = 0
      instr_key = "rob: commitInstr,"
      cycle_key = "rob: clock_cycle,"
      instr_num = 0
      cycle_num = 0
      with open(self.get_err_path()) as f:
        for line in f:
          if instr_key in line:
            instr_count += 1
            instr_num = int(line.split(instr_key)[1])
          if cycle_key in line:
            cycle_count += 1
            cycle_num = int(line.split(cycle_key)[1].split(", ")[-1])
      if (instr_count == 2) and (cycle_count == 2):
        self.second_num_cycles = cycle_num
        self.second_num_instrs = instr_num

    return self.state

  def get_simulation_cps(self):
    return int(round(self.total_num_cycles / self.num_seconds))

  def get_second_ipc(self):
    # need first execte get_state()
    if self.second_num_cycles == 0 or self.second_num_cycles == -1:
      return -1
    return round(self.second_num_instrs / self.second_num_cycles, 3)

  def get_total_ipc(self):
    if self.total_num_cycles == 0 or self.total_num_cycles == -1:
      return -1
    return round(self.total_num_instrs / self.total_num_cycles, 3)

  def state_str(self):
    state_strs = ["S_NONE", "S_RUNNING", "S_FINISHED", "S_ABORTED"]
    return state_strs[self.state]

  def debug(self):
    if os.path.exists(self.get_out_path()):
      with open(self.get_out_path()) as f:
        for line in f:
          if "dump wave to" in line:
            wave_path = line.replace("...", "").replace("dump wave to", "").strip()
            if not os.path.exists(wave_path):
              print(f"{wave_path} does not exist!!!")
            else:
              print(f"cp {wave_path} {self.get_res_dir()}")
              shutil.copy(wave_path, self.get_res_dir())

  def show(self):
    self.get_state()
    attributes = {
      "2ndInsts": self.second_num_instrs,
      "2ndCycles": self.second_num_cycles,
      "2ndIPC": f"{self.get_second_ipc():.3f}",
      "simSpeed": self.get_simulation_cps(),
      "simTime" : f"{(self.num_seconds / 3600):.1f}h"
    }
    attributes_str = ", ".join(map(lambda k: f"{k:>8} = {str(attributes[k]):>9}", attributes))
    print(f"GCPT {str(self):>50}: {self.state_str():>10}, {attributes_str}")
