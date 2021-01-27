#!/bin/python3

filename = 'decoder.v'
def all():
    global addr_width
    global depth
    addr_width = 8
    depth = 2 ** addr_width
all()
flag = 0 
with open(filename,'a') as dec_object:
    dec_object.write('module addr_dec_'+str(addr_width)+'x'+str(depth)+'_with_en (\ninput en,\n')
    dec_object.write('input ['+str(addr_width-1)+':0] addr,\n'+'output ['+str(depth-1)+':0] dec);\n')
    dec_object.write('reg ['+str(depth-1)+':0] dec_0;\nalways @(addr) begin\n'+'  '+'case(addr)\n')
    for flag in range(depth):
        if (flag == 0):
            dec_object.write('    '+str(flag)+': '+'dec_0 = {'+str(depth-flag-1)+"'b0,"+"1'b1"+"};\n")
        elif(flag == depth-1):
            dec_object.write('    '+str(flag)+': '+"dec_0 = {1'b1"+','+str(flag)+"'b0};\n")
        else:
            dec_object.write('    '+str(flag)+': '+'dec_0 = {'+str(depth-flag-1)+"'b0,1'b1"+','+str(flag)+"'b0};\n")
    dec_object.write('\tdefault: dec_0 = {'+str(int(depth/2))+"'b0,"+str(int(depth/2))+"'b1};\n"+'\tendcase\nend\n')
    dec_object.write('assign dec = {'+str(depth)+'{en}}&dec_0;\nendmodule\n\n//This is the boundry################################\n\n')
