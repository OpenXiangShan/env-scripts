# -*- coding:utf-8 -*-
import os

vivado_cmd = "/nfs/home/tools/Xilinx/Vivado/"
vivado_cmd2 = "-mode batch -source /nfs/home/share/fpga/0210xsmini/tcl/onboard-ai1-"

b = os.popen(f'ps -aux | grep {vivado_cmd}').read()
user = os.popen("whoami").read().strip()[0:6]
ls = b.split('\n')

for i in ls:
    if (("grep" not in i) and (vivado_cmd in i) and (vivado_cmd2 in i) and (user in i)):
        pid = i.split(" ")[1]
        # os.system() 运行 Linux 命令没有返回值,直接运行
        print(f'command kill -9 {pid} ({i})')
        os.system(f'kill -9 {pid}')
        print(f'{pid} killed')
