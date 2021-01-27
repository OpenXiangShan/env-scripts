#!/bin/python3
filename = 'cmp.v'
def all():
    global addr_width
    global w_addr_num
    addr_width = 8
    w_addr_num = 19
all()
flag = 0
with open(filename,'a') as cmp_object:
    cmp_object.write('module addr_cmp_w'+str(w_addr_num)+'_'+str(addr_width)+'b (\n  input [')
    cmp_object.write(str(addr_width-1)+':0] ra, ')
    for flag in range(w_addr_num):
        cmp_object.write('wa'+str(flag)+', ')
    cmp_object.write('\n  input ')
    for flag in range(w_addr_num):
        cmp_object.write('we'+str(flag)+', ')
    cmp_object.write('\n  output ['+str(w_addr_num-1)+':0] by);\n')
    for flag in range(w_addr_num):
        cmp_object.write('  assign by['+str(flag)+'] = we'+str(flag)+' && (ra == wa'+str(flag)+');\n')
    cmp_object.write('endmodule\n\n//This is the boundry##########################################\n\n')
