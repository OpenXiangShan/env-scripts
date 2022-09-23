# Watch / log result and run queued cmd
# Param
# First: xiangshan path
# Second: result log
# TLDR: python3 fpga-keeprun.py v111 /nfs/home/share/fpga/minicom-output/v111-gcc_166-116.log xsbins50m-bk-md5/gcc_166 116

import os
import time
import sys

xs_path = sys.argv[1] # xiangshan edition
result_path = sys.argv[2] # result log
workload = sys.argv[3]
fpga = sys.argv[4]

xs_path = "/nfs/home/share/fpga/bits/"+xs_path
result_path = "/nfs/home/share/fpga/minicom-output/"+result_path
workspace = os.popen("pwd").read().strip()

ssh_prefix = f"ssh zhangzifei@172.28.11.{fpga} \"source ~/.zshrc;"
ssh_suffix = "\""
vivado_cmd = ssh_prefix + f"vivado -mode batch -source /nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1-{fpga}.tcl -tclargs " + xs_path + " " + workload + " "  + ssh_suffix
uart_cmd = ssh_prefix + f" python3 {workspace}/uart2cap.py \
    {fpga} /dev/ttyUSB0 115200 {result_path} " + ssh_suffix
kill_uart_cmd = ssh_prefix + f" python3 {workspace}/stop_uart.py" + ssh_suffix
kill_vivado_cmd = ssh_prefix + f"python3 {workspace}/stop_vivado.py" + ssh_suffix
keep_tail = f"tail -f {result_path}"

print("kill existed vivado")
os.system(kill_vivado_cmd)
print("kill existed uart")
os.system(kill_uart_cmd)
if not os.path.isfile(result_path):
  os.system(f"touch {result_path}")
print("watch uart")
os.popen(uart_cmd)
print("run command : " + vivado_cmd)
os.system("date")
os.system(vivado_cmd)
print("keep tail foga output, please don't kill the script")
os.system(keep_tail)
os.system(kill_uart_cmd)
os.system
