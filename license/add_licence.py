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
  ".git": 0,
  "ready-to-run": 0,
  "chiseltest": 0,
  ".github": 0,
  "debug": 0,
  "timingScripts": 0,
  "tools": 0,
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
  # if file in wanna_list:
  #   return True

  # if ".scala" in file:
  #   return True

  # return False
  return True

def abs(path):
  return os.path.abspath(path)

header = open("/home/zzf/env-scripts/license/mulan-psl2-header-clike.txt", mode='r')
header_content_c = header.readlines()
header.close()
header = open("/home/zzf/env-scripts/license/mulan-psl2-header-shlike.txt", mode='r')
header_content_sh = header.readlines()
header.close()

do_write = True

def get_header(path):
  c_set = (".scala", ".h", ".c", ".cc", ".cpp", ".v", ".sv")
  sh_set = (".py", ".mk", "Makefile")
  for t in c_set:
    if t in path:
      print(" c-type ", end="")
      return header_content_c
  for t in sh_set:
    if t in path:
      print(" sh-type ", end="")
      return header_content_sh
  print("header: unknow type", end="")
  return header_content_c

def add_license(path):
  header_content = get_header(path)

  if do_write:
    print("add license...")
    dest = open(abs(path), "r+")
    dest_content = dest.readlines()
    dest.close()
    os.remove(path)
    dest = open(abs(path), "w")
    dest_content.insert(0, header_content)
    # print(dest_content)
    for c in dest_content:
      dest.writelines(c)
    # dest.writelines(dest_content)
    dest.flush()
    dest.close()
    # print("-------------------------")
    # dest = open(abs(path), "r").readlines()
    # print(dest)
  else:
    print("will add license...")
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
        add_license(sub)
      else:
        print("  ignore it...")

    elif os.path.isdir(sub):
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

dir_walker(abs("/home/zzf/RISCVERS/XiangShan/src"), depth = 0)
# add_license(abs("result.scala"))
# TODO: re-add is not checked