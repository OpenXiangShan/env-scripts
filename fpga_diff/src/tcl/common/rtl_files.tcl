set rtl_files [list \
 [file normalize "${rtl_dir}/$cpu/fpga_top_debug.sv"] \
 [file normalize "${rtl_dir}/$cpu/core_def_xdma.sv"] \
 [file normalize "${rtl_dir}/$cpu/SimTop_wrapper.sv" ]\
 [file normalize "${rtl_dir}/$cpu/jtag_ddr_subsys_wrapper.v"] \
]
