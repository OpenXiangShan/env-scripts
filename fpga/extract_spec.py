import sys
import re
# Param
# first: spec log file abs path
# second: output log directory(will output several logs)

begin_pat = re.compile(r'======== BEGIN (?P<spec_name>[\w.-]+) ========')
end_pat   = re.compile(r'===== Finish running SPEC2006 =====')
time_pat  = re.compile(r'\w+, \d+ \w+ \d+ (?P<time>\d+:\d+:\d+) \+0000')
log_path = sys.argv[1]
sync_to_file = (len(sys.argv) == 3)
output_dir = sys.argv[2] if sync_to_file else "error"
spec_name = "default"
inside = False
count = 0
fail = False

toShell = False

def turnpink(str):
  if not toShell:
    return str
  else:
    return "\033[1;35;40m"+str+"\033[0m"

def turnred(str):
  if not toShell:
    return str
  else:
    return "\033[1;31;40m"+str+"\033[0m"

with open(log_path) as log:
  spec_record = ""
  for line in log:
    begin_match = begin_pat.match(line)
    end_match = end_pat.match(line)
    if begin_match:
      if inside:
        print(f"error, re-inside {spec_name}")
        exit()
      inside = True
      fail = False
      spec_name = begin_match.group("spec_name")
      count = count + 1
      spec_record = f"{turnpink(spec_name)}"
      if sync_to_file:
        output_file = open(output_dir + "/" + spec_name + ".log", "w")
        output_file.write(line)
    elif end_match:
      if not inside:
        print(f"error, out but not inside {spec_name}")
        exit()
      inside = False
      print(spec_record)
      if sync_to_file:
        output_file.write(line)
        output_file.close()
    else:
      if ("unhandled signal" in line) or ("Segmentation fault" in line) or ("Aborted" in line):
        if (not fail):
          fail = True
          print(f"{turnpink(spec_name)} {turnred('failed')}, please check the log for:")
        print(turnred(line), end="")
      if inside:
        if sync_to_file:
          output_file.write(line)
        time_match = time_pat.match(line)
        if time_match:
          spec_record  += ","+time_match.group("time")

if toShell:
  if inside:
    print(f"\n{count-1} spec finished\nun-finished spec: {turnpink(spec_name)}")
  else:
    print(f"{count} spec finished")
