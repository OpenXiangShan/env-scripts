#!/bin/python3
import os
def all():
    global time_requirement
    global wrong_time
    time_requirement = 0.35
    #wrong_time = -83
    wrong_time = -92
all()

for file in os.listdir():
    if (file[-7:] == '.detail'):
        filename_1 = file
filename_2 = 'temp.log'
filename_3 = 'result.log'
filename_4 = 'inform.log'
with open(filename_1, 'r') as source_object:
    source_lines = source_object.readlines()

i = 0
whole_lines = 0
keys = '  data arrival time'
start = 'Start'

with open(filename_2, 'w') as temp_object:
    for s_line in source_lines:
        if start in s_line:
            whole_lines = whole_lines + 1 
        i = i+1
        if keys in s_line:
            if float(s_line[-9:]) > time_requirement:
                temp_object.write(str(i - 1))
                temp_object.write(s_line)
    with open(filename_4, 'w') as inform_object:
        inform_object.write('Whole lines are:')
        inform_object.write(str(whole_lines)+'.\n')

with open(filename_2, 'r') as temp_object:
    temp_lines = temp_object.readlines()

flag_start = 0
flag_end = 0
flag_inform_s = 0
flag_inform_e = 0
flag_external = 0
wrong_lines = 0
flag_network_delay = 0

with open(filename_3, 'w') as final_object:
    for t_line in temp_lines:       
        flag_end = int(t_line[0:wrong_time])
        flag_start  = flag_end
        flag_external = flag_end
        while ('Startpoint:' not in source_lines[flag_start]):
            flag_start = flag_start - 1
        flag_inform_s = flag_start
        flag_inform_e = flag_start + 13
        flag_network_delay = flag_start
        while ('input external delay' not in source_lines[flag_external]):
            flag_external = flag_external - 1
            if ('input external delay' in source_lines[flag_external]):
                if ((flag_start < flag_external)&(flag_external < flag_end)):
                    break
            if (flag_external < flag_start):
                break

        while ('clock network delay' not in source_lines[flag_network_delay]):
            flag_network_delay = flag_network_delay + 1
            if ('clock network delay' in source_lines[flag_network_delay]):
                if ((flag_start < flag_network_delay)&(flag_network_delay < flag_end)):
                    break
            if (flag_network_delay > flag_end):
                break
        

        if ((flag_start < flag_external)&(flag_external < flag_end)):
            if ((float(source_lines[flag_end][-8:-1])-float(source_lines[flag_external][-10:-3])) <= time_requirement):
                continue
        
        if((flag_start < flag_network_delay)&(flag_network_delay < flag_end)):
            if ((float(source_lines[flag_end][-8:-1])-float(source_lines[flag_network_delay][-8:-1])) <= time_requirement):
                continue

        wrong_lines = wrong_lines +1

        while (flag_start <= flag_end):
            if start in source_lines[flag_start]:
                while (flag_inform_s < flag_inform_e):
                    with open(filename_4, 'a') as inform_object:
                        inform_object.write(source_lines[flag_inform_s])
                        flag_inform_s = flag_inform_s +1 
                with open(filename_4, 'a') as inform_object:
                    inform_object.write(source_lines[flag_end]+'\n\n')
            final_object.write(source_lines[flag_start])
            flag_start = flag_start + 1
    with open(filename_4, 'a') as inform_object:
        inform_object.write('Wrong lines are:')
        inform_object.write(str(wrong_lines)+'.\n')

os.remove(filename_2)

