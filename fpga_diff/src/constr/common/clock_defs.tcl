########################################################################
# Shared primary-clock definitions for top-level and OOC synthesis.
########################################################################

set fpga_primary_clock_specs {
  {PCIE_EP_CLK_IN 10.000 pcie_ep_gt_ref_clk_p}
  {mac_rx_clk     40.000 RGMII_RXCLK}
  {mac_tx_clk     40.000 RGMII_TXCLK}
  {mdc_clk       400.000 MDC}
  {CPU_CLK_IN      5.000 clk6_p}
  {TMCLK        1000.000 clk8_p}
  {DEBUG_CLK_IN   40.000 clk5_p}
  {PCIE_CLK_IN    10.000 refclk_p}
  {PCIE2_CLK_IN   10.000 refclk2_p}
  {jtag_vclk      83.333 JTAG_TCK}
}

proc fpga_clock_spec {clock_name} {
  global fpga_primary_clock_specs

  foreach spec $fpga_primary_clock_specs {
    if {[lindex $spec 0] eq $clock_name} {
      return $spec
    }
  }
  error "unknown FPGA primary clock '$clock_name'"
}

proc fpga_clock_period {clock_name} {
  return [lindex [fpga_clock_spec $clock_name] 1]
}

proc fpga_create_clock {clock_name objects} {
  create_clock -period [fpga_clock_period $clock_name] -name $clock_name $objects
}

proc fpga_create_top_clock {clock_name} {
  set spec [fpga_clock_spec $clock_name]
  fpga_create_clock $clock_name [get_ports [lindex $spec 2]]
}
