# Optional J5 GMAC/RGMII constraints. These only apply when XS_GMAC exposes
# the RGMII top-level ports.

set gmac_ports {
  MDC
  MDIO
  PHY_RESET_B
  RGMII_RXCLK
  RGMII_RXDV
  RGMII_RXD0
  RGMII_RXD1
  RGMII_RXD2
  RGMII_RXD3
  RGMII_TXCLK
  RGMII_TXEN
  RGMII_TXD0
  RGMII_TXD1
  RGMII_TXD2
  RGMII_TXD3
}

if {[llength [get_ports -quiet RGMII_RXCLK]] == 0} {
  puts "INFO: GMAC/RGMII ports are not present; skipping gmac_j5.xdc"
} else {
  set missing_gmac_ports {}
  foreach port $gmac_ports {
    if {[llength [get_ports -quiet $port]] == 0} {
      lappend missing_gmac_ports $port
    }
  }
  if {[llength $missing_gmac_ports] != 0} {
    error "Incomplete GMAC/RGMII top-level ports for gmac_j5.xdc: $missing_gmac_ports"
  }

  puts "INFO: GMAC/RGMII ports detected; applying J5 GMAC constraints"

  set_property PACKAGE_PIN AV58 [get_ports MDC]
  set_property PACKAGE_PIN AU58 [get_ports MDIO]
  set_property PACKAGE_PIN AM61 [get_ports RGMII_RXCLK]
  set_property PACKAGE_PIN AN63 [get_ports RGMII_RXDV]
  set_property PACKAGE_PIN AP63 [get_ports RGMII_RXD0]
  set_property PACKAGE_PIN AN60 [get_ports RGMII_RXD1]
  set_property PACKAGE_PIN AN61 [get_ports RGMII_RXD2]
  set_property PACKAGE_PIN AM62 [get_ports RGMII_RXD3]
  set_property PACKAGE_PIN AR62 [get_ports RGMII_TXCLK]
  set_property PACKAGE_PIN AR63 [get_ports RGMII_TXEN]
  set_property PACKAGE_PIN AP60 [get_ports RGMII_TXD0]
  set_property PACKAGE_PIN AP61 [get_ports RGMII_TXD1]
  set_property PACKAGE_PIN AT62 [get_ports RGMII_TXD2]
  set_property PACKAGE_PIN AP62 [get_ports RGMII_TXD3]
  set_property PACKAGE_PIN AR60 [get_ports PHY_RESET_B]

  set gmac_iob_ports {
    MDC
    MDIO
    RGMII_RXCLK
    RGMII_RXDV
    RGMII_RXD0
    RGMII_RXD1
    RGMII_RXD2
    RGMII_RXD3
    RGMII_TXCLK
    RGMII_TXEN
    RGMII_TXD0
    RGMII_TXD1
    RGMII_TXD2
    RGMII_TXD3
  }
  set_property IOB TRUE [get_ports $gmac_iob_ports]

  create_clock -period 40.000 -name mac_rx_clk [get_ports RGMII_RXCLK]
  create_clock -period 40.000 -name mac_tx_clk [get_ports RGMII_TXCLK]
  set_clock_groups -asynchronous -group [get_clocks mac_rx_clk -include_generated_clocks]
  create_clock -period 40.000 -name rgmii_rx_vclk_1
  set_false_path -setup -rise_from [get_clocks rgmii_rx_vclk_1] -fall_to [get_clocks mac_rx_clk]
  set_false_path -setup -fall_from [get_clocks rgmii_rx_vclk_1] -rise_to [get_clocks mac_rx_clk]
  set_false_path -hold -rise_from [get_clocks rgmii_rx_vclk_1] -rise_to [get_clocks mac_rx_clk]
  set_false_path -hold -fall_from [get_clocks rgmii_rx_vclk_1] -fall_to [get_clocks mac_rx_clk]
  set_multicycle_path -setup -from [get_clocks rgmii_rx_vclk_1] -to [get_clocks mac_rx_clk] 0
  set_multicycle_path -hold -from [get_clocks rgmii_rx_vclk_1] -to [get_clocks mac_rx_clk] -1

  set gmac_rx_data_ports {RGMII_RXD0 RGMII_RXD1 RGMII_RXD2 RGMII_RXD3 RGMII_RXDV}
  set gmac_tx_data_ports {RGMII_TXD0 RGMII_TXD1 RGMII_TXD2 RGMII_TXD3 RGMII_TXEN}
  set_input_delay -clock [get_clocks rgmii_rx_vclk_1] -max 5.000 [get_ports $gmac_rx_data_ports]
  set_input_delay -clock [get_clocks rgmii_rx_vclk_1] -min 4.500 [get_ports $gmac_rx_data_ports]
  set_input_delay -clock [get_clocks rgmii_rx_vclk_1] -clock_fall -max -add_delay 5.000 [get_ports $gmac_rx_data_ports]
  set_input_delay -clock [get_clocks rgmii_rx_vclk_1] -clock_fall -min -add_delay 4.500 [get_ports $gmac_rx_data_ports]
  set_output_delay -clock [get_clocks mac_tx_clk] -max 12.750 [get_ports $gmac_tx_data_ports]
  set_output_delay -clock [get_clocks mac_tx_clk] -min 11.500 [get_ports $gmac_tx_data_ports]
  set_output_delay -clock [get_clocks mac_tx_clk] -clock_fall -max -add_delay 12.750 [get_ports $gmac_tx_data_ports]
  set_output_delay -clock [get_clocks mac_tx_clk] -clock_fall -min -add_delay 11.500 [get_ports $gmac_tx_data_ports]

  set gmac_lvcmos18_ports {
    MDC
    MDIO
    PHY_RESET_B
    RGMII_RXCLK
    RGMII_RXDV
    RGMII_RXD0
    RGMII_RXD1
    RGMII_RXD2
    RGMII_RXD3
    RGMII_TXCLK
    RGMII_TXEN
    RGMII_TXD0
    RGMII_TXD1
    RGMII_TXD2
    RGMII_TXD3
  }
  set_property IOSTANDARD LVCMOS18 [get_ports $gmac_lvcmos18_ports]
  create_clock -period 400.000 -name mdc_clk [get_ports MDC]
  set_property PULLUP true [get_ports {MDC MDIO}]
}
