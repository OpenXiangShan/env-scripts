####################################################################################
# Shared Vivado asynchronous clock constraints.
# Keep this file free of UVHS-specific DCP-internal clock names.
####################################################################################

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks CPU_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks CPU_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks TMCLK] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks CPU_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks ddr_ref_clk] -group [get_clocks -include_generated_clocks CPU_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks ddr_ref_clk] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks ddr_ref_clk] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks ddr_ref_clk] -group [get_clocks -include_generated_clocks PCIE_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks jtag_vclk] -group [get_clocks -include_generated_clocks CPU_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks jtag_vclk] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks jtag_vclk] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks jtag_vclk] -group [get_clocks -include_generated_clocks PCIE_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks jtag_vclk] -group [get_clocks -include_generated_clocks ddr_ref_clk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks jtag_vclk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks CPU_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks PCIE_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks ddr_ref_clk]

set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks pcie_ep_refclk] -group [get_clocks -include_generated_clocks {CPU_CLK_IN TMCLK DEBUG_CLK_IN PCIE_CLK_IN PCIE2_CLK_IN ddr_ref_clk jtag_vclk}]
