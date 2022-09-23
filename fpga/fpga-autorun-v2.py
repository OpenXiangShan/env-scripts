# Auto assgin spec workload to multiple FPGAs
# Param:
# First: xs_edition, for example: v111, v2fpu
# Second: spec_list, for example: spec06-fp.txt

from enum import Enum
import os
import time
import datetime
import re
import argparse

from send_email import send_email

# globle value, assgined below
workspace = os.popen("pwd").read().strip()
bitstream_path = ""
bitstream_magic_word = ""
spec_magic_word = ""
spec_list = {}
fpga_list = {}
workload_num = 0
count = 0
spec_base_path = ""
log_prefix = ""
fpga_max_list = ["116", "117", "118", "119", "120", "122"]

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

def fpga_send_email(spec):
  if (spec.state == STATE.STATE_FINISHED):
    subject = f"fpga success: {bitstream_magic_word}  {spec.name} of {spec_magic_word} {cal_time(spec.begin_time, spec.end_time)} "
    content = f"{spec.info}"
    send_email(subject, content)
  elif (spec.state == STATE.STATE_ABORTED):
    subject = f"fpga failed xs:{bitstream_magic_word} spec:{spec.name} of {spec_magic_word}"
    content = f"{spec.info}"
    send_email(subject, content)
  else:
    print(f"error state at fpga send email: {spec.name} {spec.state}")

def get_spec_data(spec):
  return spec_base_path + "/" + spec + "/data.txt"

def get_full_fpga_ip(num):
  return "172.28.11." + num

def output_full_path(fpgaid):
  return log_prefix + "-" + fpgaid + ".cap"

class RESULT(object):
  def __init__(self, name, begin_time, end_time, success, info):
    self.name = name
    self.begin_time = begin_time
    self.end_time = end_time
    self.success = success
    self.info = info

def extract_output(file_name):
  # extract minicom output, get a dict of RESULT
  begin_pat = re.compile(r'======== BEGIN (?P<spec_name>[\w.-]+) ========')
  end_pat   = re.compile(r'===== Finish running SPEC2006 =====')
  time_pat  = re.compile(r'\w+, \d+ \w+ \d+ (?P<time>\d+:\d+:\d+) \+0000')

  with open(file_name) as log:
    spec_record = {}
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
          begin_time = ""
        inside = True
        fail = False
        spec_name = begin_match.group("spec_name")
      elif end_match:
        if not inside:
          # exit()
          # ignore error, continue
          continue
        inside = False
        if (begin_time == "" or end_time == ""):
          exit()
        spec_record[spec_name] = RESULT(spec_name, begin_time, end_time, True, file_name[1:])
        begin_time = ""
        end_time = ""
      else:
        for ew in error_words:
          if (ew in line):
            if (not fail):
              fail = True
              inside = False
              spec_record[spec_name] = RESULT(spec_name, "", "", False, ew+" at "+file_name[1:])
        if (inside and (not fail)):
          time_match = time_pat.match(line)
          if time_match:
            if (begin_time == ""):
              begin_time = time_match.group("time")
            else:
              end_time = time_match.group("time")
    return spec_record

class FPGA(object):
  def __init__(self, fpga_name, fpga_ip):
    self.name = fpga_name
    self.tcl = f"/nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1-{fpga_name}.tcl"
    self.ip = fpga_ip
    self.current_workload = ""
    self.output = output_full_path(fpga_name)

  def set_output(self, fpga_output):
    self.output = output_full_path(fpga_output)

  def assign(self, workload):
    # run workload
    self.current_workload = workload.name
    workload_full_path = workload.path

    vivado_cmd = f"vivado -mode batch -source {self.tcl} -tclargs {bitstream_path} {workload_full_path}"
    ssh_cmd = f"ssh zhangzifei@{self.ip} \"\
      source ~/.zshrc; \
      {vivado_cmd}\" \
      "
    # print(f"vivado cmd: {ssh_cmd}")
    print(f"<<<<<<<<<< {turnpink(workload.name)} is assgined to {turnpink(self.name)} at {datetime.datetime.now()}")
    # os.system(ssh_cmd) # blocked
    os.popen(ssh_cmd) # not blocked
    return

  def available(self):
    # check if current worload finish
    if (self.current_workload == ""):
      return True
    fpga_output = extract_output(self.output) # TODO: replace with extract_output.end?
    for o in fpga_output.values():
      if (o.name == self.current_workload):
        self.current_workload = ""
        if o.success:
          spec_list[o.name].finished(o.begin_time,o.end_time, o.info)
        else:
          spec_list[o.name].aborted(o.info)
        spec_list[o.name].print_result()
        fpga_send_email(spec_list[o.name])

        return True
    return False

class STATE(Enum):
  STATE_IDLE = 0
  STATE_RUNNING = 1
  STATE_FINISHED = 2
  STATE_ABORTED = 3

class SPEC(object):
  def __init__(self, name):
    self.name = name
    self.state = STATE.STATE_IDLE
    self.path = get_spec_data(name)

  def set_state(self, state):
    self.state = state

  def running(self, fpga):
    self.state = STATE.STATE_RUNNING
    self.fpga = fpga

  def finished(self, begin_time, end_time, info):
    self.state = STATE.STATE_FINISHED
    self.begin_time = begin_time
    self.end_time = end_time
    self.info = info

  def aborted(self, info):
    self.state = STATE.STATE_ABORTED
    self.info = info

  def print_result(self):
    global count
    count = count + 1
    print(">>>>>>>>>> ", end = "")
    if (self.state == STATE.STATE_FINISHED):
      print(f"{turnpink(self.name)} {turnpink(cal_time(self.begin_time, self.end_time))} {count}/{workload_num} {self.info} {datetime.datetime.now()}")
    else:
      print(f"{turnred(self.name)} {self.info} {datetime.datetime.now()}")

def get_spec_list(f):
  spec_list = []
  state_list = {}
  filter_list = ["gamess_exam29"]
  if (".txt" not in f.strip()):
    spec_list = f.strip().split(" ")
  else:
    for s in open(f).readlines():
      spec_list.append(s.strip())
  for n in filter_list:
    if n in spec_list:
      spec_list.remove(n)

  for s in spec_list:
    state_list[s] = (SPEC(s))
  return state_list

def get_fpga_list(fpgas):
  fpga = []
  for f in fpgas.split(" "):
    fpga.append(FPGA(f, get_full_fpga_ip(f), ))
  return fpga

# auto find fpga output file
def extract_old_log(spec_list):
  print("try to find log that already exists")
  for f in fpga_max_list:
    log_name = output_full_path(f)
    if os.path.isfile(log_name) and os.access(log_name, os.R_OK):
      print(f"  existed: {turnpink(log_name)}")
      result = extract_output(log_name)
      for o in result.values():
        if o.name in spec_list.keys():
          # TODO: add print
          if o.success:
            spec_list[o.name].finished(o.begin_time, o.end_time, o.info)
          else:
            spec_list[o.name].aborted(o.info)
          # spec_list[o.name].print_result()
    else:
      print(f"  not existed:{log_name}")
  return spec_list

def create_capture():
  for fpga in fpga_list:
    file = open(fpga.output, 'a')
    file.close()

def watch_uart():
  for fpga in fpga_list:
    uart_cmd = f" python3 {workspace}/uart2cap.py \
      {fpga.ip} /dev/ttyUSB0 115200 {fpga.output} "
    ssh_cmd = f"ssh zhangzifei@{fpga.ip} \"\
      source ~/.zshrc; \
      {uart_cmd} \" \
      "
    # print(f"watch uart cmd: {ssh_cmd}")
    print(f"capture fpga{fpga.name} output to {fpga.output}")
    os.popen(ssh_cmd)

def kill_uart():
  for fpga in fpga_list:
    uart_cmd = f" python3 {workspace}/stop_uart.py"
    ssh_cmd = f"ssh zhangzifei@{fpga.ip} \"\
      source ~/.zshrc; \
      {uart_cmd} \" \
      "
    # print(f"stop uart cmd: {ssh_cmd}")
    print(f"kill watch thread of {fpga.name}")
    os.system(ssh_cmd)

def kill_vivado():
  for fpga in fpga_list:
    kill_cmd = f" python3 {workspace}/stop_vivado.py"
    ssh_cmd = f"ssh zhangzifei@{fpga.ip} \"\
      source ~/.zshrc; \
      {kill_cmd} \" \
      "
    # print(f"stop vivado cmd: {ssh_cmd}")
    print(f"kill vivado thread of {fpga.name}")
    os.system(ssh_cmd)

def wait_unfinished():
  print ("======================")
  for fpga in fpga_list:
    if (fpga.current_workload != ""):
      print(f"{fpga.current_workload} is running on {fpga.name}")
  while (count < workload_num):
    for fpga in fpga_list:
      fpga.available()

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="run fpga script")
  parser.add_argument("--absolute-path", "-R", action="store_true", default=False, help='path param use relative path')
  parser.add_argument("--bitstream", "-B", type=str, help='path to bitstream')
  parser.add_argument("--spec-list", "-L", type=str, help="path to spec list file")
  parser.add_argument("--spec-edition", "-S", default="xsbins50m-9-md5", type=str, help="path to spec workload subpath")
  parser.add_argument("--fpga-list", "-F", type=str, help="fpga list that can use, wrap with \"")
  parser.add_argument("--magic-word", "-M", default="", type=str, help="magic word that used at output log name")
  parser.add_argument("--output-path", "-O", default="/nfs/home/share/fpga/minicom-output", type=str, help="path to fpga uart output")
  parser.add_argument("--confirm", "-C", action="store_true", default=False, help="confirm from command, not keyboard")

  args = parser.parse_args()

  if "env-scripts/fpga" not in workspace:
    print("This script should run at env-scripts/fpga")


  normal_root_path = "/nfs/home/share/fpga"
  if not args.absolute_path:
    bitstream_path = normal_root_path + "/bits/" + args.bitstream
    bitstream_magic_word = args.bitstream
  else:
    bitstream_path = args.bitstream
    bitstream_magic_word = args.bitstream.split("/")[-1]

  if (args.magic_word == ""):
    spec_magic_word = args.spec_edition
  else:
    spec_magic_word = args.magic_word

  log_dir = args.output_path
  spec_base_path = normal_root_path + "/" + args.spec_edition
  log_prefix = log_dir + "/" + bitstream_magic_word + "-" + spec_magic_word

  print(f"bitstream: {turnpink(bitstream_path)}")
  print(f"fpga in use: {args.fpga_list}")
  print("fpga output path: %s"%turnpink(output_full_path("fpga")))
  attention_word = "Please make sure /dev/ttyUSB* is not used, or error will happen later"
  print(turnred(attention_word))

  # pre-check
  spec_list = get_spec_list(args.spec_list)
  fpga_list = get_fpga_list(args.fpga_list)
  spec_list = extract_old_log(spec_list)
  workload_num = len(spec_list)

  print("spec already finished:")
  for spec in spec_list.values():
    if (spec.state == STATE.STATE_FINISHED or spec.state == STATE.STATE_ABORTED):
      spec.print_result()
  print("spec to do:", end="")
  for spec in spec_list.values():
    if (spec.state == STATE.STATE_IDLE):
      print(f" {spec.name}", end="")
  print()

  if (not args.confirm):
    a = input("Ctrl-C to stop. Or any other key to continue.")

  start_time = datetime.datetime.now()
  print("Begin Time: ", start_time)

  try:
    kill_uart()
    kill_vivado()
    create_capture()
    watch_uart()
    print("======================")
    for s in spec_list.keys():
      while (spec_list[s].state == STATE.STATE_IDLE):
        for f in fpga_list:
          if f.available():
            f.assign(spec_list[s])
            spec_list[s].running(f)
            break
        if (spec_list[s].state == STATE.STATE_IDLE):
          time.sleep(60)
    wait_unfinished()

  finally:
    kill_uart()
    kill_vivado()
    end_time = datetime.datetime.now()
    print("End Time: ", end_time)
    print("Time Used:", end_time - start_time)
