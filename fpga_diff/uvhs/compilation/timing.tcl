################################################################################
# Shared UVHS timing constraints for fpga_diff.
# UVHS records constraints before RTL elaboration, so protected ports need the
# elaborated top-level scope.
################################################################################

set fpga_diff_top fpga_top_debug
proc fpga_diff_top_port {name} {
    set scoped_name "${::fpga_diff_top}.${name}"
    if {[llength [get_ports -quiet $scoped_name]] == 1} {
        return $scoped_name
    }
    return $name
}

create_clock -name TMCLK -period 1000 [get_ports [fpga_diff_top_port clk8_p]]
create_clock -name ddr_ref_clk -period 12.5 [get_ports [fpga_diff_top_port clk7_p]]
create_clock -name CPU_CLK_IN -period 40 [get_ports [fpga_diff_top_port clk5_p]]
create_clock -name UART_CLK_IN -period 20 [get_ports [fpga_diff_top_port clk6_p]]
create_clock -name jtag_vclk -period 83.333 [get_ports [fpga_diff_top_port JTAG_TCK]]
create_clock -name pcie_ep_refclk -period 10 [get_ports [fpga_diff_top_port pcie_ep_gt_ref_clk_p]]

proc fpga_diff_set_async_clock_groups {} {
    set groups [list]
    foreach clock {TMCLK ddr_ref_clk CPU_CLK_IN UART_CLK_IN jtag_vclk} {
        lappend groups -group [get_clocks -include_generated_clocks $clock]
    }
    set pcie_clocks [concat \
        [get_clocks -include_generated_clocks pcie_ep_refclk] \
        [get_clocks -quiet XDMA_AXI_ACLK]]
    lappend groups -group [lsort -unique $pcie_clocks]
    set_clock_groups -asynchronous {*}$groups
}
