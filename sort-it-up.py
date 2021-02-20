#!/bin/python3
import os
import operator
import csv
import sys
def all():
    global time_requirement
    global wrong_time
    time_requirement = 0.35
    #wrong_time = -83
    wrong_time = -92
all()


filename_1 = sys.argv[1]
filename_2 = 'temp.log'
filename_3 = 'result.log'
filename_4 = 'inform.log'
filename_5 = 'inf.log'
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
paixu = []


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

#write the sorted paixu.csv
number = 0
real_time = 0.0
with open(filename_4, 'r') as inform_object:
    inform_lines = inform_object.readlines()
for i_lines in inform_lines:
    if 'Start' in i_lines:
        number_end = number
        number_time = number
        number_delay_c = number
        number_delay_e = number
        while('End' not in inform_lines[number_end]):
            number_end = number_end + 1 
        while('time' not in inform_lines[number_time]):
            number_time = number_time + 1
        while('clock network delay' not in inform_lines[number_delay_c] ):
            number_delay_c = number_delay_c + 1
            if(number_delay_c >= number_time):
                break
        while('input external delay' not in inform_lines[number_delay_e] ):
            number_delay_e = number_delay_e + 1
            if(number_delay_e >= number_time):
                break

        if('clock network delay' in inform_lines[number_delay_c]):
            real_time = float(inform_lines[number_time][-8:-1])-float(inform_lines[number_delay_c][-8:-1])
            new_paixu = {'Startpoint':'{:>50}'.format(i_lines[:-1]), 'Endpoint':'{:>50}'.format(inform_lines[number_end][:-1]),'Time':'{:->20}'.format('%.5f'%real_time)}
        elif('input external delay' in inform_lines[number_delay_e]):
            real_time = float(inform_lines[number_time][-8:-1])-float(inform_lines[number_delay_e][-10:-3])
            new_paixu = {'Startpoint':'{:>50}'.format(i_lines[:-1]), 'Endpoint':'{:>50}'.format(inform_lines[number_end][:-1]),'Time':'{:->20}'.format('%.5f'%real_time)}
        else:
            real_time = float(inform_lines[number_time][-8:-1])
            new_paixu = {'Startpoint':'{:>50}'.format(i_lines[:-1]), 'Endpoint':'{:>50}'.format(inform_lines[number_end][:-1]),'Time':'{:->20}'.format('%.5f'%real_time)}
        paixu.append(new_paixu)
    number = number + 1 
paixu_temp = sorted(paixu, key=operator.itemgetter('Time'), reverse=True)


paixu_final = []
set_new = set()
for d in paixu_temp:
    t = tuple(d.items())
    if t not in set_new:
        set_new.add(t)
        paixu_final.append(d)

output_csv = [['Startpoint', 'Endpoint', 'Time']]
for record in paixu_final:
    start_point = record['Startpoint']
    end_point   = record['Endpoint']
    time        = record['Time']
    output_csv.append([start_point, end_point, time])

with open('paixu.csv', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=',')
    writer.writerows(output_csv)

