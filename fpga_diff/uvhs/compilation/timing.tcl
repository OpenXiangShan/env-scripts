################################################################################
# Shared UVHS timing constraints for fpga_diff.
# UVHS records constraints before RTL elaboration, so protected ports need the
# elaborated top-level scope.
################################################################################

set fpga_diff_top fpga_top_debug
proc fpga_diff_top_port {name} {
    return "${::fpga_diff_top}.${name}"
}

create_clock -name TMCLK -period 1000 [get_ports [fpga_diff_top_port clk8_p]]
create_clock -name ddr_ref_clk -period 12.5 [get_ports [fpga_diff_top_port clk7_p]]
create_clock -name CPU_CLK_IN -period 40 [get_ports [fpga_diff_top_port clk5_p]]
create_clock -name jtag_vclk -period 83.333 [get_ports [fpga_diff_top_port JTAG_TCK]]
create_clock -name pcie_ep_refclk -period 10 [get_ports [fpga_diff_top_port pcie_ep_gt_ref_clk_p]]

source [file join [file dirname [file normalize [info script]]] async_clocks.tcl]
