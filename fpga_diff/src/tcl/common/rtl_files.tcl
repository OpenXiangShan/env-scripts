set rtl_files [list \
 [file normalize "${rtl_dir}/common/fpga_top_debug.sv"] \
 [file normalize "${rtl_dir}/common/core_def_xdma.sv"] \
 [file normalize "${rtl_dir}/$cpu/SimTop_wrapper.sv" ]\
 [file normalize "${rtl_dir}/common/jtag_ddr_subsys_wrapper.v"] \
]
