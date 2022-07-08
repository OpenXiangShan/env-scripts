# Compare spec time
# spec time are at csv format
# Param:
# First: old csv file
# Second: new csv file

# TLDR: python3 spec_time_diff.py spec_old.csv spec_new.csv 

import os
import sys
import datetime

old_file = sys.argv[1]
new_file = sys.argv[2]

def cal_time(begin_time, end_time):
  begin = datetime.datetime.strptime(begin_time, '%H:%M:%S')
  end = datetime.datetime.strptime(end_time, '%H:%M:%S')
  delta = end - begin
  return str(delta)

def time_to_second(f_time):
  hours, minutes, seconds = f_time.split(":")
  return int(hours)*3600 + int(minutes)*60 + int(seconds)

def cal_ratio(old_time, new_time):
  o = time_to_second(old_time)
  n = time_to_second(new_time)
  return (n - o) / o

record = {}

with open(old_file, "r") as f:
  for line in f:
    items = line.strip().split(",")
    if not items:
      continue
    elif len(items) == 3:
      name, start_time, finish_time = items
      record[name] = [cal_time(start_time, finish_time),"",0.0]

with open(new_file, "r") as f:
  for line in f:
    items = line.strip().split(",")
    if not items:
      continue
    elif len(items) == 3:
      name, start_time, finish_time = items
      if name in record.keys():
        old = record[name]
        new_time = cal_time(start_time, finish_time)
        record[name] = [old[0], new_time, cal_ratio(old[0], new_time)]
      else:
        record[name] = ["", new_time, 0.0]

print(f"spec,{old_file},{new_file},inc ratio")
for r in record.keys():
  print(f"{r},{record[r][0]},{record[r][1]},"+"%.4f"%record[r][2])
