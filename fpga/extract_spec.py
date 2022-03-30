import sys
import re
# Param
# first: spec log file abs path
# second: output log directory(will output several logs)

begin_pat = re.compile(r'======== BEGIN (?P<spec_name>\w*) ========')
end_pat   = re.compile(r'======== END   (?P<spec_name>\w*) ========')
time_pat  = re.compile(r'\w+, \d+ \w+ \d+ \d+:\d+:\d+ \+0000')
log_path = sys.argv[1]
output_dir = sys.argv[2]
sync_to_file = False
spec_name = "default"
inside = False

with open(log_path) as log:
  for line in log:
    begin_match = begin_pat.match(line)
    end_match = end_pat.match(line)
    if begin_match:
      if inside:
        print(f"error, re-inside {spec_name}")
        exit()
      inside = True
      spec_name = begin_match.group("spec_name")
      print(f"Find spec {spec_name}:")
      if sync_to_file:
        output_file = open(output_dir + "/" + spec_name + ".log", "w")
        output_file.write(line)
    elif end_match:
      if not inside:
        print(f"error, out but not inside {spec_name}")
        exit()
      inside = False
      if sync_to_file:
        output_file.write(line)
        output_file.close()
    else:
      if inside:
        if sync_to_file:
          output_file.write(line)
        time_match = time_pat.match(line)
        if time_match:
          print(line, end="")

if inside:
  print(f"Warning: The last spec {spec_name} doesn't finish")