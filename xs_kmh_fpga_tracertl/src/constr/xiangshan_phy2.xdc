####### Main board
#clk


set_property PACKAGE_PIN Y52 [get_ports clk7_p]
set_property PACKAGE_PIN Y53 [get_ports clk7_n]

set_property PACKAGE_PIN AY50 [get_ports clk8_p]
set_property PACKAGE_PIN BA50 [get_ports clk8_n]

set_property PACKAGE_PIN R42 [get_ports clk6_p]
set_property PACKAGE_PIN R43 [get_ports clk6_n]

set_property PACKAGE_PIN C35 [get_ports clk5_p]
set_property PACKAGE_PIN C36 [get_ports clk5_n]

set_property PACKAGE_PIN BA11 [get_ports refclk_p]
set_property PACKAGE_PIN BA10 [get_ports refclk_n]

#set_property PACKAGE_PIN CA36 [get_ports clk4_p]
#set_property PACKAGE_PIN CA37 [get_ports clk4_n]

#set_property PACKAGE_PIN BY38 [get_ports clk3_p]
#set_property PACKAGE_PIN BY39 [get_ports clk3_n]

#set_property PACKAGE_PIN CB19 [get_ports clk2_p]
#set_property PACKAGE_PIN CB18 [get_ports clk2_n]

#set_property PACKAGE_PIN CA17 [get_ports clk1_p]
#set_property PACKAGE_PIN CA16 [get_ports clk1_n]

#reset
set_property PACKAGE_PIN E47 [get_ports rstn_sw6]
set_property PACKAGE_PIN BY53 [get_ports rstn_sw5]
set_property PACKAGE_PIN CA39 [get_ports rstn_sw4]

#uart
set_property PACKAGE_PIN AD13 [get_ports uart0_sout]

set_property PACKAGE_PIN AE13 [get_ports uart0_sin]

set_property PACKAGE_PIN AE14 [get_ports uart1_sout]

set_property PACKAGE_PIN AE15 [get_ports uart1_sin]

set_property PACKAGE_PIN V16 [get_ports uart2_sout]

set_property PACKAGE_PIN W15 [get_ports uart2_sin]
#pcie

#set_property PACKAGE_PIN BD4 [get_ports {PCIE_RXP[0]}]
#set_property PACKAGE_PIN BD3 [get_ports {PCIE_RXN[0]}]
#set_property PACKAGE_PIN BF9 [get_ports {PCIE_TXP[0]}]
#set_property PACKAGE_PIN BF8 [get_ports {PCIE_TXN[0]}]
#set_property PACKAGE_PIN BC2 [get_ports {PCIE_RXP[1]}]
#set_property PACKAGE_PIN BC1 [get_ports {PCIE_RXN[1]}]
#set_property PACKAGE_PIN BE7 [get_ports {PCIE_TXP[1]}]
#set_property PACKAGE_PIN BE6 [get_ports {PCIE_TXN[1]}]
#set_property PACKAGE_PIN BB4 [get_ports {PCIE_RXP[2]}]
#set_property PACKAGE_PIN BB3 [get_ports {PCIE_RXN[2]}]
#set_property PACKAGE_PIN BD9 [get_ports {PCIE_TXP[2]}]
#set_property PACKAGE_PIN BD8 [get_ports {PCIE_TXN[2]}]
#set_property PACKAGE_PIN BA2 [get_ports {PCIE_RXP[3]}]
#set_property PACKAGE_PIN BA1 [get_ports {PCIE_RXN[3]}]
#set_property PACKAGE_PIN BC7 [get_ports {PCIE_TXP[3]}]
#set_property PACKAGE_PIN BC6 [get_ports {PCIE_TXN[3]}]
#
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXP[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXN[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXP[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXN[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXP[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXN[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXP[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXN[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXP[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXN[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXP[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXN[2]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXP[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_RXN[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXP[3]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {PCIE_TXN[3]}]

#gpio
#set_property PACKAGE_PIN AA15 [get_ports GPIO_O0]

#set_property PACKAGE_PIN AA16 [get_ports GPIO_O1]
#j5#
# set_property PACKAGE_PIN AL51 [get_ports SD_CLK]
#
# set_property PACKAGE_PIN AK49 [get_ports SD_CMD]
#
# set_property PACKAGE_PIN AL52 [get_ports SD_DATA0]
#
# set_property PACKAGE_PIN AK50 [get_ports SD_DATA1]
#
# set_property PACKAGE_PIN AM49 [get_ports SD_DATA2]
#
# set_property PACKAGE_PIN AK45 [get_ports SD_DATA3]
#
# set_property PACKAGE_PIN AN49 [get_ports SD_DECT]
#



####### J1
set_property PACKAGE_PIN CC39 [get_ports led0]

#set_property PACKAGE_PIN CB39 [get_ports led1]

set_property PACKAGE_PIN CB36 [get_ports led2]

set_property PACKAGE_PIN CC35 [get_ports led3]

#J7# # set_property PACKAGE_PIN BK40 [get_ports QSPI_CS]
#
# set_property PACKAGE_PIN BN40 [get_ports QSPI_CLK]
#
# set_property PACKAGE_PIN BP41 [get_ports QSPI_DAT_0]
#
# set_property PACKAGE_PIN BK39 [get_ports QSPI_DAT_1]
#
# set_property PACKAGE_PIN BP40 [get_ports QSPI_DAT_2]
#
# set_property PACKAGE_PIN BG39 [get_ports QSPI_DAT_3]
#
# ##
# set_property PACKAGE_PIN BL32 [get_ports SD_CLK]
#
# set_property PACKAGE_PIN BJ33 [get_ports SD_CMD]
#
# set_property PACKAGE_PIN BM32 [get_ports SD_DATA0]
#
# set_property PACKAGE_PIN BK33 [get_ports SD_DATA1]
#
# set_property PACKAGE_PIN BJ31 [get_ports SD_DATA2]
#
# set_property PACKAGE_PIN BG33 [get_ports SD_DATA3]
#
# set_property PACKAGE_PIN BJ30 [get_ports SD_DECT]
#
##
# set_property PACKAGE_PIN J5 [get_ports QSPI_CS]
#
# set_property PACKAGE_PIN J1 [get_ports QSPI_CLK]
#
# set_property PACKAGE_PIN J2 [get_ports QSPI_DAT_0]
#
# set_property PACKAGE_PIN J6 [get_ports QSPI_DAT_1]
#
# set_property PACKAGE_PIN H1 [get_ports QSPI_DAT_2]
#
# set_property PACKAGE_PIN K3 [get_ports QSPI_DAT_3]
#
# ##
set_property PACKAGE_PIN K9 [get_ports SD_CLK]

set_property PACKAGE_PIN H10 [get_ports SD_CMD]

set_property PACKAGE_PIN K8 [get_ports SD_DATA0]

set_property PACKAGE_PIN H9 [get_ports SD_DATA1]

set_property PACKAGE_PIN G11 [get_ports SD_DATA2]

set_property PACKAGE_PIN C8 [get_ports SD_DATA3]

set_property PACKAGE_PIN F11 [get_ports SD_DECT]

#set_property IOSTANDARD LVCMOS18 [get_ports SD_WP]
#set_property PACKAGE_PIN B8 [get_ports SD_WP]


####### J3 phy2
set_property PACKAGE_PIN D27 [get_ports MDC]
set_property PACKAGE_PIN D28 [get_ports MDIO]
set_property PACKAGE_PIN F32 [get_ports RGMII_RXCLK]
set_property PACKAGE_PIN B33 [get_ports RGMII_RXDV]
set_property PACKAGE_PIN B32 [get_ports RGMII_RXD0]
set_property PACKAGE_PIN D32 [get_ports RGMII_RXD1]
set_property PACKAGE_PIN D31 [get_ports RGMII_RXD2]
set_property PACKAGE_PIN E32 [get_ports RGMII_RXD3]
set_property PACKAGE_PIN D33 [get_ports RGMII_TXCLK]
set_property PACKAGE_PIN B31 [get_ports RGMII_TXEN]
set_property PACKAGE_PIN A32 [get_ports RGMII_TXD0]
set_property PACKAGE_PIN A31 [get_ports RGMII_TXD1]
set_property PACKAGE_PIN C33 [get_ports RGMII_TXD2]
set_property PACKAGE_PIN C31 [get_ports RGMII_TXD3]
set_property PACKAGE_PIN B27 [get_ports PHY_RESET_B]

create_clock -period 40.00 -name mac_rx_clk [get_ports RGMII_RXCLK]
create_clock -period 40.00 -name mac_tx_clk [get_ports RGMII_TXCLK]
set_output_delay -clock mac_tx_clk -max -add_delay 9.200 [get_ports {RGMII_TXD0 RGMII_TXD1 RGMII_TXD2 RGMII_TXD3 RGMII_TXEN}]
set_output_delay -clock mac_tx_clk -min -add_delay 0.800 [get_ports {RGMII_TXD0 RGMII_TXD1 RGMII_TXD2 RGMII_TXD3 RGMII_TXEN}]
set_output_delay -clock mac_tx_clk -clock_fall -max -add_delay 9.200 [get_ports {RGMII_TXD0 RGMII_TXD1 RGMII_TXD2 RGMII_TXD3 RGMII_TXEN}]
set_output_delay -clock mac_tx_clk -clock_fall -min -add_delay 0.800 [get_ports {RGMII_TXD0 RGMII_TXD1 RGMII_TXD2 RGMII_TXD3 RGMII_TXEN}]
set_input_delay -clock mac_rx_clk -max -add_delay 9.200 [get_ports {RGMII_RXD0 RGMII_RXD1 RGMII_RXD2 RGMII_RXD3 RGMII_RXDV}]
set_input_delay -clock mac_rx_clk -min -add_delay 0.700 [get_ports {RGMII_RXD0 RGMII_RXD1 RGMII_RXD2 RGMII_RXD3 RGMII_RXDV}]
set_input_delay -clock mac_rx_clk -clock_fall -max -add_delay 9.200 [get_ports {RGMII_RXD0 RGMII_RXD1 RGMII_RXD2 RGMII_RXD3 RGMII_RXDV}]
set_input_delay -clock mac_rx_clk -clock_fall -min -add_delay 0.700 [get_ports {RGMII_RXD0 RGMII_RXD1 RGMII_RXD2 RGMII_RXD3 RGMII_RXDV}]
set_property DRIVE 12 [get_ports RGMII_TXCLK]
set_property DRIVE 12 [get_ports RGMII_TXEN]
set_property DRIVE 12 [get_ports RGMII_TXD0]
set_property DRIVE 12 [get_ports RGMII_TXD1]
set_property DRIVE 12 [get_ports RGMII_TXD2]
set_property DRIVE 12 [get_ports RGMII_TXD3]

#####################################################################################
# JX1-- PCIe x16 slot PCIe1
# board connector --  PCIe Gen2 x4
# phy_ip --  x1 Gen3
# set_property PACKAGE_PIN BF8 [get_ports PCIE_TXN]
# set_property PACKAGE_PIN BF9 [get_ports PCIE_TXP]
# set_property PACKAGE_PIN BD3 [get_ports PCIE_RXN]
# set_property PACKAGE_PIN BD4 [get_ports PCIE_RXP]
set_property PACKAGE_PIN CB13 [get_ports PERST_N]

#####################################################################################



####################################################################################
# Constraints from file : 'ddr.xdc'
####################################################################################

# set_property IOSTANDARD LVDS [get_ports clk1_p]
# set_property IOSTANDARD LVDS [get_ports clk1_n]
# set_property IOSTANDARD LVDS [get_ports clk2_p]
# set_property IOSTANDARD LVDS [get_ports clk2_n]
# set_property IOSTANDARD LVDS [get_ports clk3_p]
# set_property IOSTANDARD LVDS [get_ports clk3_n]
# set_property IOSTANDARD LVDS [get_ports clk4_p]
# set_property IOSTANDARD LVDS [get_ports clk4_n]

set_property IOSTANDARD LVDS [get_ports refclk_p]
set_property IOSTANDARD LVDS [get_ports refclk_n]
set_property IOSTANDARD LVDS [get_ports clk7_p]
set_property IOSTANDARD LVDS [get_ports clk7_n]
set_property IOSTANDARD LVDS [get_ports clk8_p]
set_property IOSTANDARD LVDS [get_ports clk8_n]
set_property IOSTANDARD LVDS [get_ports clk6_p]
set_property IOSTANDARD LVDS [get_ports clk6_n]
set_property IOSTANDARD LVDS [get_ports clk5_p]
set_property IOSTANDARD LVDS [get_ports clk5_n]
set_property IOSTANDARD LVCMOS18 [get_ports PERST_N]
set_property IOSTANDARD LVCMOS18 [get_ports rstn_sw6]
set_property IOSTANDARD LVCMOS18 [get_ports rstn_sw5]
set_property IOSTANDARD LVCMOS18 [get_ports rstn_sw4]
set_property IOSTANDARD LVCMOS33 [get_ports uart0_sout]
set_property IOSTANDARD LVCMOS33 [get_ports uart0_sin]
set_property IOSTANDARD LVCMOS33 [get_ports uart1_sout]
set_property IOSTANDARD LVCMOS33 [get_ports uart1_sin]
set_property IOSTANDARD LVCMOS33 [get_ports uart2_sout]
set_property IOSTANDARD LVCMOS33 [get_ports uart2_sin]
#set_property IOSTANDARD LVCMOS33 [get_ports GPIO_O0]
#set_property IOSTANDARD LVCMOS33 [get_ports GPIO_O1]
set_property IOSTANDARD LVCMOS18 [get_ports led0]
#set_property IOSTANDARD LVCMOS18 [get_ports led1]
set_property IOSTANDARD LVCMOS18 [get_ports led2]
set_property IOSTANDARD LVCMOS18 [get_ports led3]
#set_property IOSTANDARD LVCMOS18 [get_ports QSPI_CS]
#set_property IOSTANDARD LVCMOS18 [get_ports QSPI_CLK]
#set_property IOSTANDARD LVCMOS18 [get_ports QSPI_DAT_0]
#set_property IOSTANDARD LVCMOS18 [get_ports QSPI_DAT_1]
#set_property IOSTANDARD LVCMOS18 [get_ports QSPI_DAT_2]
#set_property IOSTANDARD LVCMOS18 [get_ports QSPI_DAT_3]
set_property IOSTANDARD LVCMOS18 [get_ports SD_CLK]
set_property IOSTANDARD LVCMOS18 [get_ports SD_CMD]
set_property IOSTANDARD LVCMOS18 [get_ports SD_DATA0]
set_property IOSTANDARD LVCMOS18 [get_ports SD_DATA1]
set_property IOSTANDARD LVCMOS18 [get_ports SD_DATA2]
set_property IOSTANDARD LVCMOS18 [get_ports SD_DATA3]
set_property IOSTANDARD LVCMOS18 [get_ports SD_DECT]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_RXCLK]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_RXDV]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_RXD0]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_RXD1]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_RXD2]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_RXD3]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_TXCLK]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_TXEN]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_TXD0]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_TXD1]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_TXD2]
set_property IOSTANDARD LVCMOS18 [get_ports RGMII_TXD3]
set_property IOSTANDARD LVCMOS18 [get_ports MDC]
set_property IOSTANDARD LVCMOS18 [get_ports MDIO]
set_property IOSTANDARD LVCMOS18 [get_ports PHY_RESET_B]
create_clock -period 5.000 -name CPU_CLK_IN [get_pins ibufgds_tmclk_200MHz/O]
create_clock -period 1000.000 -name TMCLK [get_pins ibufgds_tmclk_1MHz/O]
create_clock -period 20.000 -name DEBUG_CLK_IN [get_pins ibufgds_dbgclk_50MHz/O]
create_clock -period 10.000 -name PCIE_CLK_IN [get_pins refclk_ibuf/ODIV2]
create_clock -name MMCM_CLK_OUT [get_nets xs_core_def/U_JTAG_DDR_SUBSYS/jtag_ddr_subsys_i/ddr4_0/inst/u_ddr4_infrastructure/addn_ui_clkout1]

set_clock_groups -group [get_clocks -include_generated_clocks CPU_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks CPU_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks CPU_CLK_IN] -group [get_clocks -include_generated_clocks MMCM_CLK_OUT] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks TMCLK] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks TMCLK] -group [get_clocks -include_generated_clocks MMCM_CLK_OUT] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks DEBUG_CLK_IN] -group [get_clocks -include_generated_clocks MMCM_CLK_OUT] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks MMCM_CLK_OUT] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks DEBUG_CLK_IN] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks TMCLK] -asynchronous 
set_clock_groups -group [get_clocks -include_generated_clocks PCIE_CLK_IN] -group [get_clocks -include_generated_clocks CPU_CLK_IN] -asynchronous 


set_property PULLUP true [get_ports SD_CMD]
set_property PULLUP true [get_ports SD_DATA0]
set_property PULLUP true [get_ports SD_DATA1]
set_property PULLUP true [get_ports SD_DATA2]
set_property PULLUP true [get_ports SD_DATA3]
set_property PULLUP true [get_ports MDC]
set_property PULLUP true [get_ports MDIO]

####################################################################################
# Constraints from file : 'constraints.xdc'
####################################################################################






