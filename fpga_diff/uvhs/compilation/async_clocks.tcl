################################################################################
# UVHS asynchronous clock constraints.
#
# backend_run.tcl and the Vivado pre-opt stage load this after generated clocks
# are available.
################################################################################

set fpga_diff_async_groups [list]
foreach fpga_diff_clock {TMCLK ddr_ref_clk CPU_CLK_IN jtag_vclk pcie_ep_refclk} {
    lappend fpga_diff_async_groups -group [get_clocks -include_generated_clocks $fpga_diff_clock]
}
eval [linsert $fpga_diff_async_groups 0 set_clock_groups -asynchronous]
