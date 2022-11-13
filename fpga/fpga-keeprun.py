# Watch / log result and run queued cmd
# Param
# First: xiangshan path
# Second: result log
# TLDR: python3 fpga-keeprun.py v111 xsbins50m-bk-md5/gcc_166 116

import os
import time
import sys

from send_email import send_email

xs_path = sys.argv[1] # xiangshan edition
spec = sys.argv[2]
fpga = sys.argv[3]
result_path = xs_path+"-kr-"+spec.strip().split("/")[0]+"-"+spec.strip().split("/")[1]+"-"+fpga+".cap"
number = 9999 if (len(sys.argv) <= 4) else int(sys.argv[4])


xs_path = "/nfs/home/share/fpga/bits/"+xs_path
result_path = "/nfs/home/share/fpga/minicom-output/"+result_path
workspace = os.popen("pwd").read().strip()
spec = "/nfs/home/share/fpga/" + spec.strip() + "/data.txt"

current_pos = 0
if os.path.isfile(result_path):
  current_pos = int(os.popen(f"grep -c '======== END ' {result_path}").read())
max_pos = current_pos + number

if not os.path.isfile(spec):
  print(f"Error: {spec} not exists")
  exit()

print(f"xs:{xs_path} spec:{spec} fpga:{fpga} result_path:{result_path} already:{current_pos} todo_time:{number}")

ssh_prefix = f"ssh zhangzifei@172.28.11.{fpga} \"source ~/.zshrc;"
ssh_suffix = "\""
vivado_cmd = ssh_prefix + f"vivado -mode batch -source /nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1-{fpga}.tcl -tclargs " + xs_path + " " + spec + " " + ssh_suffix
uart_cmd = ssh_prefix + f" python3 {workspace}/uart2cap.py \
    {fpga} /dev/ttyUSB0 115200 {result_path} " + ssh_suffix
kill_uart_cmd = ssh_prefix + f" python3 {workspace}/stop_uart.py" + ssh_suffix
kill_vivado_cmd = ssh_prefix + f"python3 {workspace}/stop_vivado.py" + ssh_suffix


def wait_fpga_finish():
  while(int(os.popen(f"grep -c '======== END ' {result_path}").read()) < current_pos):
    time.sleep(60)
  if (current_pos >= max_pos):
    print(f"Execution Times: {number}(this time) + {max_pos-number}(before) = {max_pos}(total)")
    send_email(f"fpga keeprun {sys.argv[1]} run {sys.argv[2]} for {number} times on {fpga}", "log path:{result_path}")
    print("send email success")
    exit()
  print("get cmd " + str(current_pos) + " result, run next ('0-0')")

a = input("Continue?")

try:
  print("kill existed vivado")
  os.system(kill_vivado_cmd)
  print("kill existed uart")
  os.system(kill_uart_cmd)
  if not os.path.isfile(result_path):
    os.popen(f"touch {result_path}")
  time.sleep(10)
  print("watch uart")
  os.popen(uart_cmd)
  while(True):
    wait_fpga_finish()
    os.system(f"echo run command {current_pos}: " + vivado_cmd)
    os.system("date")
    os.system(vivado_cmd)
    print(f"fpga keeprun {sys.argv[1]} run {sys.argv[2]} on {fpga} pos: {current_pos} max_pos: {max_pos} number: {number}")
    print(f"log path: {result_path}")
    current_pos = current_pos + 1
finally:
  print("kill vivado")
  os.system(kill_vivado_cmd)
  print("kill uart")
  os.system(kill_uart_cmd)
  print(f"fpga keeprun {sys.argv[1]} run {sys.argv[2]} for {number} times on {fpga}")
  print(f"log path:{result_path}")
  print("stopped")
