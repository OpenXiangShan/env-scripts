import sys

# Usage: python3 parse_fanout.py fanout_file.rpt threadhold

fanout_file = sys.argv[1]
threshold = int(sys.argv[2])

record = []

with open(fanout_file, "r") as f:
  name = True
  current_name = ""
  for line in f:
    if ((len(line) > 8) and (not name)):
      continue
    if name:
      current_name = line
    else:
      if (int(line) >= threshold):
        record.append([current_name, line])
    name = not name

def get_number(elem):
  return int(elem[1])

record.sort(key=get_number, reverse=True)

for r in record:
  print(r[0], end="")
  print(r[1], end="")
