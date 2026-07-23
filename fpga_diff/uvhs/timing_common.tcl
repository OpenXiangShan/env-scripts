################################################################################
# Shared UVHS timing constraints for fpga_diff.
# Keep this direct so UVHS sees the RTL ports without extra guards.
################################################################################

create_clock -name TMCLK -period 1000 [get_ports -rtl clk8_p]
create_clock -name ddr_ref_clk -period 12.5 [get_ports -rtl clk7_p]
set fpga_diff_cpu_clk_period_ns 40
if {[info exists ::env(UVHS_CPU_CLK_PERIOD_NS)] && $::env(UVHS_CPU_CLK_PERIOD_NS) ne ""} {
    set fpga_diff_cpu_clk_period_ns $::env(UVHS_CPU_CLK_PERIOD_NS)
}
set fpga_diff_cpu_debug_clk 1
if {[info exists ::env(UVHS_CPU_DEBUG_CLK)] && $::env(UVHS_CPU_DEBUG_CLK) ne ""} {
    set fpga_diff_cpu_debug_clk [expr {$::env(UVHS_CPU_DEBUG_CLK) eq "1"}]
}
if {$fpga_diff_cpu_debug_clk} {
    create_clock -name CPU_CLK_IN -period $fpga_diff_cpu_clk_period_ns [get_ports -rtl clk5_p]
} else {
    create_clock -name CPU_CLK_IN -period $fpga_diff_cpu_clk_period_ns [get_ports -rtl clk6_p]
    create_clock -name DEBUG_CLK_IN -period 40 [get_ports -rtl clk5_p]
}
create_clock -name jtag_vclk -period 83.333 [get_ports -rtl JTAG_TCK]
create_clock -name pcie_ep_refclk -period 10 [get_ports -rtl pcie_ep_gt_ref_clk_p]

source [file normalize [file join [file dirname [info script]] async_clocks.tcl]]
