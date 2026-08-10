# Three-FPGA NutShell commit-trace topology.
#
# F2 keeps the already validated NutShell CPU/XDMA complex and trace CH0 DDR.
# F1 owns trace CH1 DDR and the corresponding remote write sink.  Move only
# the complete functional DDR IP to F3, exactly as in the known-good NutShell
# dual-DDR partition.  Keeping the 64-to-256 converter on F2 lets UVHS create
# the same functional AXI partition boundary that has passed default H2C and
# DiffTest on board; the compact functional-DDR serializer is not used here.
create_fpga -name b0.f1 \
    -cells [get_cells -rtl { \
        fpga_top_debug.core_def.U_CPU_TRACE.U_CPU_TRACE_CH1_DDR \
        fpga_top_debug.core_def.U_CPU_TRACE.u_trace_core0.u_passive_backend.u_ch1_remote_sink \
    }] \
    -update

create_fpga -name b0.f2 \
    -cells [get_cells -rtl fpga_top_debug.core_def.U_CPU_TRACE.U_CPU_TRACE_CH0_DDR] \
    -update

create_fpga -name b0.f3 \
    -cells [get_cells core_def/U_UVHS_UVW_AXI4_TO_DDR4] \
    -update
