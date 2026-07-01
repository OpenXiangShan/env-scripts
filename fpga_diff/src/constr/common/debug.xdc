
####################################################################################
# Constraints from file : 'jtag_ddr_subsys_s01_data_fifo_0_clocks.xdc'
####################################################################################

set_false_path -from [get_clocks -of_objects [get_pins xs_core_def/U_JTAG_DDR_SUBSYS/jtag_ddr_subsys_i/ddr4_0/inst/u_ddr4_infrastructure/gen_mmcme4.u_mmcme_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins xs_core_def/u0_xdma/xdma_0/inst/pcie4c_ip_i/inst/xdma_xdma_0_0_pcie4c_ip_gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
