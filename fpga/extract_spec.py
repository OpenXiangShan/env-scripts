import argparse
from genericpath import isfile
import os
import sys
import re
import time
import datetime

# Param
# first: spec log file abs path
# second: output log directory(will output several logs)

def turnpink(string, highlight = True):
  if highlight:
    return "\033[1;35;40m"+string+"\033[0m"
  else:
    return string

def turnred(string, highlight = True):
  if highlight:
    return "\033[1;31;40m"+string+"\033[0m"
  else:
    return string

class RESULT(object):
  def __init__(self, name, begin_time, end_time, success, info):
    self.name = name
    self.begin_time = begin_time
    self.end_time = end_time
    self.success = success
    self.info = info

  def print_result(self, highlight):
    if self.success:
      print(f"{turnpink(self.name, highlight)},{self.begin_time},{self.end_time}")
    else:
      print(f"{turnred(self.name, highlight)},{self.info}")


def extract_output(file_name, print_result=False, highlight=True, print_sum=True):
  succ_times = 0
  fail_times = 0

  error_words = [
    "internal error",
    "unhandled signal",
    "Segmentation fault",
    "Aborted",
    "Kernel panic",
    "unhandled kernel",
    "unhandlable trap",
    "Power off",
    "scause"
  ]
  # extract fpga output, get a dict of RESULT
  begin_pat = re.compile(r'======== BEGIN (?P<spec_name>[\w.-]+) ========')
  end_pat   = re.compile(r'===== Finish running SPEC2006 =====')
  time_pat  = re.compile(r'\w+, \d+ \w+ \d+ (?P<time>\d+:\d+:\d+) \+0000')

  with open(file_name) as log:
    spec_record = {}
    begin_time = ""
    end_time = ""
    spec_name = "linux-begin"

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
        result = RESULT(spec_name, begin_time, end_time, True, file_name[1:])
        succ_times = succ_times + 1
        if print_result:
          result.print_result(highlight)
        spec_record[spec_name] = result
        begin_time = ""
        end_time = ""
      else:
        for ew in error_words:
          if (ew in line):
            if (not fail):
              fail = True
              inside = False
              result = RESULT(spec_name, "", "", False, ew+" at "+file_name[1:])
              fail_times = fail_times + 1
              if print_result:
                result.print_result(highlight)
              spec_record[spec_name] = result
        if (inside and (not fail)):
          time_match = time_pat.match(line)
          if time_match:
            if (begin_time == ""):
              begin_time = time_match.group("time")
            else:
              end_time = time_match.group("time")
    if print_result and print_sum:
      print(f"{succ_times} success, {fail_times} fail")
    return spec_record

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="extract fpga spec output")
  parser.add_argument("capfiles", metavar="logfilename", type=str, nargs="+", help="fpga capture log")
  parser.add_argument("--highlight", "-H", default=False, action="store_true", help="highlight some key word")
  parser.add_argument("--print_filename", "-F", default=False, action="store_true", help="print file name")

  args = parser.parse_args()
  file_list = args.capfiles
  for f in file_list:
    if not os.path.isfile(f):
      print(f"{f} is not exist")
      continue
    if args.print_filename:
      print(f"*****{f}*****")
    extract_output(f, print_result=True, highlight=args.highlight, print_sum=args.print_filename)
