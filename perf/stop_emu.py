# -*- coding:utf-8 -*-
import os

emu_mw = '/build/emu'
b = os.popen(f"ps -aux | grep  {emu_mw}").read()
user = os.popen("whoami").read().strip()[0:6]
ls = b.split('\n')

for i in ls:
    if (("grep" not in i) and (emu_mw in i) and (user in i)) and (f"ssh {user}" not in i):
        pid = i.split()[1]
        # os.system() 运行 Linux 命令没有返回值,直接运行
        print(f'command kill -9 {pid} ({i})')
        os.system(f'kill -9 {pid}')
        print(f'{pid} killed')
