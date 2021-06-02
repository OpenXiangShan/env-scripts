#! /usr/bin/env python3

import argparse
import os
import re

'''
ignore list: (dir_name, dir_depth)
dir_depth: -1 means all the depth
dir_depth: -2 means no ignore
'''
ignore_list_depth = {
  "out": 0,
  "api-config-chipsalliance": 0,
  "berkeley-hardfloat": 0,
  "block-inclusivecache-sifive": 0,
}

ignore_list_abs = set(

)

wanna_list = {

}

def ignore(path, depth):
  ignore_depth = ignore_list_depth.get(path, -2)
  if ignore_depth == -2:
    return False
  elif ignore_depth == -1 or ignore_depth == depth:
    return True

  if abs(path) in ignore_list_abs:
    return True

  return False

def wanna(file, depth):
  # only use for file now
  if file in wanna_list:
    return True

  if ".scala" in file:
    return True

  return False

def abs(path):
  return os.path.abspath(path)

def add_license(path):
  return

def print_dot(num):
  for i in range(num):
    print("-|", end="")

def dir_walker(path, depth):
  path = abs(path)
  os.chdir(path) # need change to the path
  sub_dirs = os.listdir(path)
  for sub in sub_dirs:
    if os.path.islink(sub):
      print_dot(depth)
      print(sub + " is a link, skip...")
    elif os.path.isfile(sub):
      print_dot(depth)
      print("file: " + sub, end="")
      if wanna(sub, depth) & ~ignore(sub, depth):
        print("  add license...")
      else:
        print("  ignore it...")
      add_license(sub)
    elif os.path.isdir(sub) & ~ignore(sub, depth):
      print_dot(depth)
      print("dir : " + sub, end="")
      if ignore(sub, depth):
        print("  ignore it...")
      else:
        print("")
        dir_walker(sub, depth + 1)
    else:
      print_dot(depth)
      print(sub + " is not file or directory, skip...")
      assert(0, "find unkown files")
    os.chdir(path) # return to current path

dir_walker(abs("/home/zzf/RISCVERS/XiangShan"), depth = 0)