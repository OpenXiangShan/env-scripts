#! /usr/bin/env python3

import argparse
import os
import re

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
      print("file: " + sub)
      add_license(sub)
    elif os.path.isdir(sub):
      print_dot(depth)
      print("dir : " + sub)
      dir_walker(sub, depth + 1)
    else:
      print_dot(depth)
      print(sub + " is not file or directory, skip...")
    os.chdir(path) # return to current path

dir_walker(abs(".."), depth = 0)