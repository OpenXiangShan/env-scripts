import os
import shutil

class GCPT(object):
  STATE_NONE     = 0
  STATE_RUNNING  = 1
  STATE_FINISHED = 2
  STATE_ABORTED  = 3

  def __init__(self, gcpt_bin_dir: str, perf_base_dir: str,benchspec: str, point: str, weight: str, eval_run_hours: float = 0):
    self.bin_base_dir = gcpt_bin_dir
    self.benchspec = benchspec
    self.point = point
    self.weight = weight
    self.state = self.STATE_NONE
    self.num_cycles = -1
    self.num_instrs = -1
    self.ipc = -1
    self.num_seconds = -1
    self.waveform = []
    self.res_dir = os.path.join(perf_base_dir, self.__str__())
    self.eval_run_hours = eval_run_hours

  def __str__(self):
    return "_".join([self.benchspec, self.point, str(self.weight)])
  
  def get_bin_path(self):
    dir_name = self.__str__()
    bin_dir = os.path.join(self.bin_base_dir, dir_name, "0")
    bin_file = list(os.listdir(bin_dir))
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
      "instrCnt": self.num_instrs,
      "cycleCnt": self.num_cycles,
      "totalIPC": f"{self.get_ipc():.3f}",
      "simSpeed": self.get_simulation_cps()
    }
    attributes_str = ", ".join(map(lambda k: f"{k:>8} = {str(attributes[k]):>9}", attributes))
    print(f"GCPT {str(self):>50}: {self.state_str():>10}, {attributes_str}")