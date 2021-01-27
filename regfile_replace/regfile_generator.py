#!/bin/python3

filename = 'regfile.v'
def all():
    global r_addr_num
    global w_addr_num
    global addr_width
    global data_width
    global depth
    r_addr_num = 6
    w_addr_num = 19
    addr_width = 8
    data_width = 17
    depth = 192
all()
flag_raddr = 0
flag_waddr = 0
with open(filename, 'a') as reg_object:
    reg_object.write('`define ADDR_WIDTH' +' ' + str(addr_width)+'\n'+'`define ENTRY_NUMBER' + ' ' + str(depth)+'\n')
    reg_object.write('`define DATA_WIDTH' + ' ' + str(data_width)+'\n')
    reg_object.write('module'+' '+'regfile_'+str(depth)+'x'+str(data_width)+'_'+str(w_addr_num)+'w'+str(r_addr_num)+'r'+' '+'('+'\n')
    reg_object.write('    '+'input clock'+','+'\n')
    #generate the I/O
    for flag_raddr in range(r_addr_num):
        reg_object.write('    input [`ADDR_WIDTH-1:0] '+'raddr'+str(flag_raddr)+',\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('    input wen'+str(flag_waddr)+',\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('    input [`ADDR_WIDTH-1:0] waddr'+str(flag_waddr)+',\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('    input [`DATA_WIDTH-1:0] wdata'+str(flag_waddr)+',\n')
    for flag_raddr in range(r_addr_num -1):
        reg_object.write('    output [`DATA_WIDTH-1:0] rdata'+str(flag_raddr)+',\n')
    reg_object.write('    output [`DATA_WIDTH-1:0] rdata'+str(r_addr_num -1)+'\n);\n\n')
    #generate the reg signals
    for flag_waddr in range(w_addr_num):
        reg_object.write('    reg reg_wen'+str(flag_waddr)+';\n')
    reg_object.write('\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('    reg [`ADDR_WIDTH-1:0] reg_waddr'+str(flag_waddr)+';\n')
    reg_object.write('\n')
    for flag_raddr in range(r_addr_num):
        reg_object.write('    reg [`ADDR_WIDTH-1:0] reg_raddr'+str(flag_raddr)+';\n')
    reg_object.write('\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('    reg [`DATA_WIDTH-1:0] reg_wdata'+str(flag_waddr)+';\n')
    reg_object.write('\n')
    #generate the always blocks
    reg_object.write('always @(posedge clock) begin\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('\tif (wen'+str(flag_waddr)+') reg_waddr'+str(flag_waddr)+' <= waddr'+str(flag_waddr)+';\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('\treg_wen'+str(flag_waddr)+' <= wen'+str(flag_waddr)+';\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('\treg_wdata'+str(flag_waddr)+' <= wdata'+str(flag_waddr)+';\n')
    for flag_raddr in range(r_addr_num):
        reg_object.write('\treg_raddr'+str(flag_raddr)+' <= '+'raddr'+str(flag_raddr)+';\n')
    reg_object.write('end\n\n')
    #one hot address decoder
    for flag_waddr in range(w_addr_num):
        reg_object.write('wire [2**`ADDR_WIDTH-1:0] '+'wdec'+str(flag_waddr)+';\n')
    for flag_waddr in range(w_addr_num):
        reg_object.write('addr_dec_'+str(addr_width)+'x'+str(2**addr_width)+"_with_en U_wad"+str(flag_waddr)+'_dec ( .en(reg_wen'+\
        str(flag_waddr)+'), .addr(reg_waddr'+str(flag_waddr)+'), .dec(wdec'+str(flag_waddr)+') );\n')
    reg_object.write('\n')
    #write to the Mem
    reg_object.write('reg [`DATA_WIDTH-1:0] reg_MEM [`ENTRY_NUMBER-1:0];\ninteger i;\nalways @(negedge clock) begin\n'+\
    '\tfor(i=0;i<`ENTRY_NUMBER;i=i+1) begin\n\t  if(')
    for flag_waddr in range(w_addr_num-1):
        reg_object.write('wdec'+str(flag_waddr)+'[i]||')
    reg_object.write('wdec'+str(w_addr_num-1)+'[i]) begin\n\t\treg_MEM[i] <=')
    for flag_waddr in range(w_addr_num-1):
        reg_object.write(' {`DATA_WIDTH{wdec'+str(flag_waddr)+'[i]}}&reg_wdata'+str(flag_waddr)+' |')
    reg_object.write('{`DATA_WIDTH{wdec'+str(w_addr_num-1)+'[i]}}&reg_wdata'+str(w_addr_num-1)+';\n\t\tend\n\tend\nend\n\n')
    #read te data out and judge which come out first
    for flag_raddr in range(r_addr_num):
        reg_object.write('wire [`DATA_WIDTH-1:0] rdata_'+str(flag_raddr)+' = reg_MEM[reg_raddr'+str(flag_raddr)+'];\n')
    for flag_waddr in range(r_addr_num):
        reg_object.write('wire ['+str(w_addr_num-1)+':0]'+'by'+str(flag_waddr)+';\n')
    for flag_raddr in range(r_addr_num):
        reg_object.write('addr_cmp_w'+str(w_addr_num)+'_'+str(addr_width)+'b U_rad'+str(flag_raddr)+'_cmp ( .by(by'+str(flag_raddr)+'), '+\
        '.ra(reg_raddr'+str(flag_raddr)+')\n\t')
        for flag_waddr in range(w_addr_num):
            reg_object.write(', .we'+str(flag_waddr)+'(reg_wen'+str(flag_waddr)+')'+', .wa'+str(flag_waddr)+'(reg_waddr'+str(flag_waddr)+')')
        reg_object.write(');\n')
    reg_object.write('\n')
    reg_object.write('wire [`DATA_WIDTH-1:0] ')
    for flag_raddr in range(r_addr_num-1):
        reg_object.write('by'+str(flag_raddr)+'_data, ')
    reg_object.write('by'+str(r_addr_num-1)+'_data;\n\n')
    for flag_raddr in range(r_addr_num):
        reg_object.write('assign by'+str(flag_raddr)+'_data = ')
        for flag_waddr in range(w_addr_num -1):
            reg_object.write('{`DATA_WIDTH{by'+str(flag_raddr)+'['+str(flag_waddr)+']'+\
            '}}&reg_wdata'+str(flag_waddr)+' | ')
        reg_object.write('{`DATA_WIDTH{by'+str(flag_raddr)+'['+str(w_addr_num-1)+']}}&reg_wdata'+str(w_addr_num-1)+';\n')
    reg_object.write('\n')
    for flag_raddr in range(r_addr_num):
        reg_object.write('assign rdata'+str(flag_raddr)+'  = (|by'+str(flag_raddr)+') ? by'+str(flag_raddr)+'_data : rdata_'+str(flag_raddr)+';\n')
    reg_object.write('endmodule\n`undef ADDR_WIDTH\n`undef ENTRY_NUMBER\n`undef DATA_WIDTH\n\n//This is the boundry###################################\n\n')
    
    

    

