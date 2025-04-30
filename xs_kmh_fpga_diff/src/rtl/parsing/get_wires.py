import re
import sys

def get_wires(lines):
  wires = []
  assigns = []
  bindings = []
  for line in lines:
    line = line.lstrip().rstrip()
    line = re.sub('//.*$', '', line)
    if 'input ' in line or 'output ' in line:
      m = re.search("(input|output) +(wire |reg )? *(\[[^\]]+\])? *(\w+)", line)
      wires.append([m.group(4), m.group(1)])
    elif line.startswith('wire') or line.startswith('reg'):
      m = re.search("^(wire|reg) +(\[[^\]]+\])? *(\w+)", line)
      wires.append([m.group(3), m.group(1)])
    elif line.startswith('assign'):
      assigns.append(line)
    elif line.startswith('.'):
      m = re.search("\(.*\)", line)
      bindings.append(m.group(0))
  
  for wire, wire_T in wires:
    hit = False
    for assign in assigns:
      if wire in assign:
        hit = True
        break
    if hit:
      continue
    for bind in bindings:
      if wire in bind:
        hit = True
        break

    if not hit:
      print(f"unused: {wire} ({wire_T})")


if __name__ == '__main__':
  lines = open(sys.argv[1]).readlines()
  get_wires(lines)
