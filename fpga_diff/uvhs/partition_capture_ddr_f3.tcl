# Dedicated two-FPGA partition for the standard UVHS waveform build.
#
# F2 owns the CPU, XDMA, UART, and the single probe/trigger instrumentation
# path.  Hejian UHD therefore binds its capture backend to the physical
# PDDR4DME on F2/FMC3.  Move only the complete business AXI-to-DDR black box
# to F3, where it can bind the independent physical PDDR4DME on F3/FMC3.
# The partition boundary is outside the SoC DDR implementation and does not
# alter the functional AXI interface or RTL connectivity.
create_fpga -name b0.f3 \
    -cells [get_cells core_def/U_UVHS_UVW_AXI4_TO_DDR4] \
    -update
