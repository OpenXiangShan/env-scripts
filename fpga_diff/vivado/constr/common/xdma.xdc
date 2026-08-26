# XDMA/PCIe constraints. This file is not added to NO_DIFF projects.

# PCIe reference clocks
set_property PACKAGE_PIN BA11 [get_ports refclk_p]
set_property PACKAGE_PIN BA10 [get_ports refclk_n]
set_property PACKAGE_PIN AR11 [get_ports refclk2_p]
set_property PACKAGE_PIN AR10 [get_ports refclk2_n]

# XDMA endpoint
set_property PACKAGE_PIN BY22 [get_ports pcie_ep_perstn]
set_property PACKAGE_PIN AU11 [get_ports pcie_ep_gt_ref_clk_p]
set_property PACKAGE_PIN AD15 [get_ports pcie_ep_lnk_up]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_ep_lnk_up]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_ep_perstn]
create_clock -name PCIE_EP_CLK_IN -period 10.000 [get_ports pcie_ep_gt_ref_clk_p]

# PCIe resets
set_property PACKAGE_PIN CB13 [get_ports PERST_N]
set_property PACKAGE_PIN CB23 [get_ports PERST2_N]
set_property IOSTANDARD LVCMOS18 [get_ports PERST_N]
set_property IOSTANDARD LVCMOS18 [get_ports PERST2_N]

# PCIe clocks and asynchronous clock groups
create_clock -period 10.000 -name PCIE_CLK_IN [get_ports refclk_p]
create_clock -period 10.000 -name PCIE2_CLK_IN [get_ports refclk2_p]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks difftest_pcie_clock] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks CPU_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks [list clk7_p mmcm_clkout0 mmcm_clkout1 mmcm_clkout2 mmcm_clkout3 mmcm_clkout4 mmcm_clkout5 mmcm_clkout6 {pll_clk[0]} {pll_clk[1]} {pll_clk[2]} {pll_clk[0]_DIV} {pll_clk[2]_DIV} {pll_clk[1]_DIV}]] -group [get_clocks -include_generated_clocks PCIE_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks jtag_vclk] -group [get_clocks -include_generated_clocks PCIE_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks jtag_vclk]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks CPU_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks -include_generated_clocks PCIE_CLK_IN]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks PCIE2_CLK_IN] -group [get_clocks [list clk7_p mmcm_clkout0 mmcm_clkout1 mmcm_clkout2 mmcm_clkout3 mmcm_clkout4 mmcm_clkout5 mmcm_clkout6 {pll_clk[0]} {pll_clk[1]} {pll_clk[2]} {pll_clk[0]_DIV} {pll_clk[2]_DIV} {pll_clk[1]_DIV}]]

# XDMA and DDR clock-domain false paths
set_false_path -from [get_clocks -of_objects [get_pins xs_core_def/u0_xdma/xdma_0/inst/pcie4c_ip_i/inst/xdma_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -to [get_clocks -of_objects [get_pins xs_core_def/U_JTAG_DDR_SUBSYS/jtag_ddr_subsys_i/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins xs_core_def/U_JTAG_DDR_SUBSYS/jtag_ddr_subsys_i/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT1]] -to [get_clocks {xs_core_def/u0_xdma/xdma_0/inst/pcie4c_ip_i/inst/xdma_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/gt_wizard.gtwizard_top_i/xdma_xdma_0_0_pcie4c_ip_gt_i/inst/gen_gtwizard_gtye4_top.xdma_xdma_0_0_pcie4c_ip_gt_gtwizard_gtye4_inst/gen_gtwizard_gtye4.gen_channel_container[7].gen_enabled_channel.gtye4_channel_wrapper_inst/channel_inst/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST/TXOUTCLK}]
set_false_path -from [get_clocks -of_objects [get_pins xs_core_def/U_JTAG_DDR_SUBSYS/jtag_ddr_subsys_i/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins xs_core_def/u0_xdma/xdma_0/inst/pcie4c_ip_i/inst/xdma_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]
