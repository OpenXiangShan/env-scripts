1.Fisrtly, set the main parameters in *.py:
    1)r_addr_num:读地址(数据)的路数;
    2)w_addr_num:写地址(数据)的路数;
    3)addr_width:(读/写)地址宽度;
    4)data_width:(读/写)数据宽度;
    5)depth:寻址深度(一般是2^addr_width,但我看有自己设定的合适的值的，所以就自给一个值吧)。

2.Use "./regfile_generator.py" to generate the regfile.v;
3.Use "./addr_dec_generator.py" to generate the decoder.v;
4.Use "./cmp_generator.py" to generate the cmp.v;
5.The  decoder.v and cmp.v are the submodules of regfile.v;
6.每次改动参数后执行脚本，会自动追加写进前一次的.v文件(不会覆盖);
7.生成的regfile模块都带了使能端wen的。