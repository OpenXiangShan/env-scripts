# Auto assgin spec workload to multiple FPGAs
# Param:
# no currently, please change this script manually

import os
import time
import sys
import datetime
import re

xs_edition = "v1000"
xs_path = f"/nfs/home/share/fpga/bits/{xs_edition}"

# get workload list

spec_path = "/nfs/home/share/fpga/xsbins50m-bk-md5"
spec_list = os.popen(f"ls {spec_path}").read().strip().split("\n")
if ("gamess_exam29" in spec_list):
  spec_list.remove("gamess_exam29")

def get_workload_path(spec_name):
  return spec_path + "/" + spec_name + "/data.txt"

# extract output
count = 0

error_words = [
  "unhandled signal",
  "Segmentation fault",
  "Aborted",
  "Kernel panic",
  "unhandled kernel",
  "scause"
]

def turnpink(str):
    return "\033[1;35;40m"+str+"\033[0m"

def turnred(str):
    return "\033[1;31;40m"+str+"\033[0m"

def cal_time(begin_time, end_time):
  begin = datetime.datetime.strptime(begin_time, '%H:%M:%S')
  end = datetime.datetime.strptime(end_time, '%H:%M:%S')
  delta = end - begin
  return str(delta)

def extract_output(file_name):
  # extract minicom output, get a list of ["name", "begin", "end"]
  begin_pat = re.compile(r'======== BEGIN (?P<spec_name>[\w.-]+) ========')
  end_pat   = re.compile(r'===== Finish running SPEC2006 =====')
  time_pat  = re.compile(r'\w+, \d+ \w+ \d+ (?P<time>\d+:\d+:\d+) \+0000')

  with open(file_name) as log:
    spec_record = []
    begin_time = ""
    end_time = ""

    inside = False
    fail = False
    for line in log:
      begin_match = begin_pat.match(line)
      end_match = end_pat.match(line)
      if begin_match:
        if inside:
          print(f"error, re-inside {spec_name}")
          exit()
        inside = True
        fail = False
        spec_name = begin_match.group("spec_name")
      elif end_match:
        if not inside:
          print(f"error, out but not inside {spec_name}")
          exit()
        inside = False
        spec_record.append([spec_name, cal_time(begin_time, end_time)])
        begin_time = ""
        end_time = ""
      else:
        for ew in error_words:
          if (ew in line):
            if (not fail):
              fail = True
              print(f"{spec_name} {'failed'}, please check the log for:")
        if inside:
          time_match = time_pat.match(line)
          if time_match:
            if (begin_time == ""):
              begin_time = time_match.group("time")
            else:
              end_time = time_match.group("time")
    return spec_record


# define FPGA Class

minicom_output = "/nfs/home/share/fpga/minicom-output"
class FPGA(object):
  def __init__(self, fpga_name, fpga_ip, fpga_output):
    self.name = fpga_name
    self.tcl = f"/nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1-{fpga_name}.tcl"
    self.output = minicom_output + "/" + fpga_output
    self.ip = fpga_ip
    self.current_workload = ""
    self.finish_list = []



  def assign(self, workload):
    # run workload
    self.current_workload = workload
    workload_full_path = get_workload_path(self.current_workload)
    vivado_cmd = f"vivado -mode batch -source {self.tcl} -tclargs {xs_path} {workload_full_path}"
    # cmd_prefix = "python3 /nfs/home/zhangzifei/work/env-scripts/fpga/fpga_single_run.py"
    # ssh_cmd = f"ssh zhangzifei@{self.ip} {cmd_prefix} {self.tcl} {xs_path} {workload_full_path}"
    ssh_cmd = f"ssh zhangzifei@{self.ip} \"\
      source ~/.zshrc; \
      {vivado_cmd}\" \
      "
    os.system(ssh_cmd) # blocked
    # print(f"cmd: {ssh_cmd}")
    # os.popen(ssh_cmd) # not blocked
    return

  def is_finish(self):
    # check if current worload finish
    if (self.current_workload == ""):
      return True
    fpga_output = extract_output(self.output)
    for s in fpga_output:
      if (s[0] == self.current_workload):
        self.finish_list.append(s)
        global count
        count = count + 1
        print(f"                                           ", end="")
        print(f"{turnpink(s[0])}:{turnpink(s[1])}.   {count} spec is finished")
        return True
    return False


fpga116 = FPGA("116", "172.28.11.119", f"{xs_edition}-spec-116.cap")
fpga117 = FPGA("117", "172.28.11.117", f"{xs_edition}-spec-117.cap")
fpga118 = FPGA("118", "172.28.11.118", f"{xs_edition}-spec-118.cap")
fpga119 = FPGA("119", "172.28.11.119", f"{xs_edition}-spec-119.cap")
fpga120 = FPGA("116", "172.28.11.120", f"{xs_edition}-spec-120.cap")
fpga122 = FPGA("122", "172.28.11.122", f"{xs_edition}-spec-122.cap")

# fpga that we can use
fpga_list = [
  fpga116
]

# here is the begin
if __name__ == "__main__":
  print(f"xs_path: {xs_path}")
  print("fpga in use:")
  for fpga in fpga_list:
    print("  " + fpga.name)
  print(f"spec_path: {spec_path}")
  print(f"spec_list: {spec_list}")

  print(turnred("IMPORTANT: please manual set minicom output file to "+ xs_edition + "-spec-'fpga'.cap"))

  a = input("Ctrl-C to stop. Or any other key to continue.")

  for workload in spec_list:
    assigned = False
    while not assigned:
      for fpga in fpga_list:
        if fpga.is_finish():
          fpga.assign(workload)
          assigned = True
          print(f"{turnpink(workload)} is assgin to {turnpink(fpga.name)}")
          break
      if not assigned:
        print(f"{workload} has no seats, sleep 5s")
        time.sleep(5)
