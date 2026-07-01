create_clock -name TMCLK          -per 1000   [get_ports xs_fpga_top_debug.clk8_p]
create_clock -name ddr_ref_clk    -per 12.5   [get_ports xs_fpga_top_debug.clk7_p]
create_clock -name CPU_CLK_IN     -per 5      [get_ports xs_fpga_top_debug.clk6_p]
create_clock -name DEBUG_CLK_IN   -per 40     [get_ports xs_fpga_top_debug.clk5_p]
create_clock -name jtag_vclk      -per 83.333 [get_ports xs_fpga_top_debug.JTAG_TCK]
create_clock -name pcie_ep_refclk -per 10     [get_ports xs_fpga_top_debug.pcie_ep_gt_ref_clk_p]

set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks TMCLK] \
    -group [get_clocks -include_generated_clocks ddr_ref_clk] \
    -group [get_clocks -include_generated_clocks CPU_CLK_IN] \
    -group [get_clocks -include_generated_clocks DEBUG_CLK_IN] \
    -group [get_clocks -include_generated_clocks jtag_vclk] \
    -group [get_clocks -include_generated_clocks pcie_ep_refclk]
