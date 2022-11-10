# Compare spec time
# spec time are at csv format
# Param:
# First: old csv file
# Second: new csv file

# TLDR: python3 spec_time_diff.py spec_old.csv spec_new.csv 

import os
import sys
import datetime

if sys.argv[1] == "-h" or sys.argv[1] == "--help":
  print("Usage: python3 me.py files.csv")

files = sys.argv[1:]

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
  ratio = ((o - n) / o) * 100.0
  return "%.2f"%ratio+"%"

record_list = []

for fi in files:
  f = open(fi, "r")
  record = {}
  for line in f:
    items = line.strip().split(",")
    if not items:
      print("no items")
      continue
    elif len(items) == 3:
      name, start_time, finish_time = items
      record[name] = [cal_time(start_time, finish_time)]
  record_list.append(record)
  f.close()

record_all = record_list[0]

for f in record_list[1:]:
  for s in record_all.keys():
    if s in f.keys():
      record_all[s].append(f[s][0])
    else:
      record_all[s].append("")

for r in record_all.keys():
  print(f"{r}", end="")
  for s in record_all[r]:
    print(f",{s}", end="")
  print("")
