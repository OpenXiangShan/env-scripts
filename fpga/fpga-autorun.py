# Watch / log result and run queued cmd

import os
import time
import sys

current_pos = 0
fpga_job_list = []
spec_todo_list = open('spec06-all-time.txt', 'r')
xs_path = sys.argv[1] # xiangshan edition
result_path = "/nfs/home/share/fpga/minicom-output/v2-def-1MBL2-2MBL3-noalias/spec_autorun.cap"

def wait_fpga_finish():
  while(int(os.popen(f"grep -c END {result_path}").read()) <= current_pos):
    time.sleep(60)
  print("get cmd " + str(current_pos) + " result, run next ('0-0')")

def spec2fpga():
  vivado_cmd = "vivado -mode batch -source /nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1.tcl -tclargs " + xs_path + " "
  for x in spec_todo_list:
    fpga_job_list.append(vivado_cmd + "/nfs/home/share/fpga/xsbins/" + x.strip() + "/data.txt")

spec2fpga()
print(fpga_job_list)

# exit()

while(current_pos < len(fpga_job_list)):
  cmd = fpga_job_list[current_pos]
  print(f'run command {current_pos}: ' + cmd)
  os.system("date")
  os.system(cmd)
  wait_fpga_finish()
  current_pos = current_pos + 1
print("done")
