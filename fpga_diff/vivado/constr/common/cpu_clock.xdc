# CPU/SoC master clock: clk6_p is the board 200MHz system clock.
# Loaded before fpga.xdc/xdma.xdc so that the optional generated core clock
# (core_clock.xdc, created by constraints.tcl from FPGA_CORE_CLK_MHZ) is
# picked up by their -include_generated_clocks clock groups.
create_clock -period 5.000 -name CPU_CLK_IN [get_ports clk6_p]
