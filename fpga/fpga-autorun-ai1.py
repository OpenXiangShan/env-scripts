# Auto assgin spec workload to multiple FPGAs
# Param:
# First: xs_edition, for example: v111, v2fpu
# Second: spec_list, for example: spec06-fp.txt

import os
import time
import sys
import datetime
import re

xs_edition = sys.argv[1]
spec_flist = sys.argv[2]

xs_path = f"/nfs/home/share/fpga/bits/{xs_edition}"

# get workload list

spec_path = "/nfs/home/share/fpga/xsbins50m-bk-md5"
spec_list = []
for s in open(spec_flist).readlines():
  spec_list.append(s.strip())
# spec_list = os.popen(f"ls {spec_path}").read().strip().split("\n")
if ("gamess_exam29" in spec_list):
  spec_list.remove("gamess_exam29")

def get_workload_path(spec_name):
  return spec_path + "/" + spec_name + "/data.txt"

# extract output
count = 0
max_count = len(spec_list)

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

ignore_not_finish = True

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
          # re-inside a spec output, which means last not finish
          if ignore_not_finish:
            begin_time = ""
          else:
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
def output_full_path(file_name):
  return minicom_output + "/" + file_name
class FPGA(object):
  def __init__(self, fpga_name, fpga_ip, fpga_output, current_workload = ""):
    self.name = fpga_name
    self.tcl = f"/nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1-{fpga_name}.tcl"
    self.output = output_full_path(fpga_output)
    self.ip = fpga_ip
    self.current_workload = current_workload # if there is a running workload, set it to avoid conflict or re-running
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
    # os.system(ssh_cmd) # blocked
    os.popen(ssh_cmd) # not blocked
    return

  def available(self):
    # check if current worload finish
    if (self.current_workload == ""):
      return True
    fpga_output = extract_output(self.output) # TODO: replace with extract_output.end?
    for s in fpga_output:
      if (s[0] == self.current_workload):
        self.finish_list.append(s)
        global count
        count = count + 1
        self.current_workload = ""
        print(f"                                           ", end="")
        print(f"{turnpink(s[0])}:{turnpink(s[1])}.   {count}/{max_count} spec is finished")
        return True
    return False

fpga116 = FPGA("116", "172.28.11.116", f"{xs_edition}-spec-116.cap")
fpga117 = FPGA("117", "172.28.11.117", f"{xs_edition}-spec-117.cap")
fpga118 = FPGA("118", "172.28.11.118", f"{xs_edition}-spec-118.cap")
fpga119 = FPGA("119", "172.28.11.119", f"{xs_edition}-spec-119.cap")
fpga120 = FPGA("116", "172.28.11.120", f"{xs_edition}-spec-120.cap")
fpga122 = FPGA("122", "172.28.11.122", f"{xs_edition}-spec-122.cap")

# fpga that we can use
fpga_list = [
  fpga116,
  fpga117,
  fpga122
]

# output that already have
# use output_full_path(file_name)
already_output_files = [
]

for fpga in fpga_list:
  already_output_files.append(fpga.output)

def already_finish(file_name, workload_name):
    fpga_output = extract_output(file_name)
    for s in fpga_output:
      if (s[0] == workload_name):
        global count
        count = count + 1
        print(f"                                           ", end="")
        print(f"{turnpink(s[0])}:{turnpink(s[1])}.   {count}/{max_count} spec is finished")
        return True
    return False

# here is the begin
if __name__ == "__main__":
  print(f"xs_path: {turnpink(xs_path)}")
  print("fpga in use:", end="")
  for fpga in fpga_list:
    print(turnpink("  " + fpga.name), end="")
  print("")
  print("already output files:")
  for aof in already_output_files:
    print(turnpink("  " + aof))
  print(f"spec_path: {spec_path}")
  print(f"spec_list: {spec_list}")

  # pre-check
  for of in already_output_files:
    if not (os.path.isfile(of) and os.access(of, os.R_OK)):
      print(trunred(f"Error: {of} doesn't exist or has no read right"))
      exit()
  for sp in spec_list:
    full_path = get_workload_path(sp)
    if not (os.path.isfile(full_path) and os.access(full_path, os.R_OK)):
      print(trunred(f"Error: {full_path} doesn't exist or has no read right"))
      exit()

  print(turnred("IMPORTANT: please manual set minicom output file to "+ xs_edition + "-spec-'fpga'.cap"))

  a = input("Ctrl-C to stop. Or any other key to continue.")

  start_time = datetime.datetime.now()

  for workload in spec_list:
    assigned = False
    while not assigned:
      # is the workload finished before
      for output_file in already_output_files:
        if already_finish(output_file, workload):
          assigned = True
          break
      if assigned:
        continue

      # is the workload is running at a fpga
      for fpga in fpga_list:
        if (fpga.current_workload == workload):
          print(f"{turnpink(workload)} is already running on {turnpink(fpga.name)}")
          assigned = True
          break
      if assigned:
        continue

      # assgin to a fpga
      for fpga in fpga_list:
        if fpga.available():
          fpga.assign(workload)
          assigned = True
          print(f"{turnpink(workload)} is assgined to {turnpink(fpga.name)}")
          break
      if not assigned:
        time.sleep(60)

  print("all the spec has been assigned, wait for the unfinished.")
  if (count < max_count):
    for fpga in fpga_list:
      if fpga.current_workload != "":
        print(f"{turnpink(fpga.current_workload)} is running on {turnpink(fpga.name)}")
      else:
        print(f"{turnpink(fpga.name)} is available")
  while (count < max_count):
    for fpga in fpga_list:
      a = fpga.available()
    time.sleep(60)

  end_time = datetime.datetime.now()
  print("Time Usage: " + str(end_time -start_time))
