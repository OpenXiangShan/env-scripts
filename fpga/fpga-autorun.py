# Watch / log result and run queued cmd
# Param
# First: xiangshan path
# Second: result log

import os
import time
import sys

current_pos = 0
fpga_job_list = []
xs_path = sys.argv[1] # xiangshan edition
result_path = sys.argv[2] # result log
spec_todo_list = open(sys.argv[3], 'r')
fpga = sys.argv[4]

def wait_fpga_finish():
  while(int(os.popen(f"grep -c '======== END ' {result_path}").read()) < current_pos):
    time.sleep(60)
  print("get cmd " + str(current_pos) + " result, run next ('0-0')")

def spec2fpga():
  vivado_cmd = f"vivado -mode batch -source {fpga} -tclargs " + xs_path + " "
  for x in spec_todo_list:
    fpga_job_list.append(vivado_cmd + "/nfs/home/share/fpga/xsbins50m-bk-md5/" + x.strip() + "/data.txt")

spec2fpga()
# print(fpga_job_list)

# exit()

while(current_pos < len(fpga_job_list)):
  wait_fpga_finish()
  cmd = fpga_job_list[current_pos]
  os.system(f"echo run command {current_pos}: " + cmd)
  os.system("date")
  os.system(cmd)
  current_pos = current_pos + 1
print("done")
