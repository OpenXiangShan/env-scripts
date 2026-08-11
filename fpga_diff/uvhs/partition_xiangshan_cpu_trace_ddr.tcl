# Three-FPGA XiangShan trace topology.
# F2 is the default FPGA and keeps CPU/XDMA plus trace CH0 DDR.
create_fpga -name b0.f1 \
    -cells [get_cells -rtl { \
        fpga_top_debug.core_def.U_CPU_TRACE.U_CPU_TRACE_CH1_DDR \
        fpga_top_debug.core_def.U_CPU_TRACE.u_trace_core0.u_passive_backend.u_ch1_remote_sink \
    }] \
    -update

create_fpga -name b0.f2 \
    -cells [get_cells -rtl fpga_top_debug.core_def.U_CPU_TRACE.U_CPU_TRACE_CH0_DDR] \
    -update

# Keep the functional DDR controller and its compact AXI sink together on F3.
create_fpga -name b0.f3 \
    -cells [get_cells { \
        core_def/U_UVHS_UVW_AXI4_TO_DDR4 \
        core_def/u_uvhs_func_ddr_remote_sink \
    }] \
    -update
