set core_clock_xdc [file normalize ${proj_dir}/core_clock.xdc]
set core_clock_fd [open $core_clock_xdc w]
puts $core_clock_fd {create_clock -period 5.000 -name CPU_CLK_IN [get_ports clk6_p]}
if {$timing_core_clk_mhz != $core_clk_mhz} {
  set core_clk_div [expr {200 / $core_clk_mhz}]
  set core_period [expr {1000.0 / $timing_core_clk_mhz}]
  # Scale the period without changing the physical divider's duty cycle.
  set core_high_time [expr {$core_period * ($core_clk_div / 2) / $core_clk_div}]
  puts $core_clock_fd [format {create_generated_clock -name CORE_CLK -source [get_ports clk6_p] -edges {1 2 3} -edge_shift {0 %.9f %.9f} [get_pins bufg_core_clk/O]} \
    [expr {$core_high_time - 2.5}] [expr {$core_period - 5.0}]]
}
close $core_clock_fd

# Define the CPU clock family before fpga.xdc and xdma.xdc group it.
set constr_files [list \
  $core_clock_xdc \
  [file normalize ${constr_dir}/ddr.xdc] \
  [file normalize ${constr_dir}/fpga.xdc] \
  [file normalize ${constr_dir}/debug.xdc] \
]

if {!$::no_diff} {
  lappend constr_files [file normalize ${constr_dir}/xdma.xdc]
  puts "INFO: adding common XDMA/PCIe constraints: xdma.xdc"

  set xdma_link_width X4
  if {[info exists ::env(XDMA_LINK_WIDTH)] && [string trim $::env(XDMA_LINK_WIDTH)] ne ""} {
    set xdma_link_width [string trim $::env(XDMA_LINK_WIDTH)]
  }
  if {[lsearch -exact {X4 X8} $xdma_link_width] < 0} {
    error "XDMA_LINK_WIDTH must be one of X4/X8, got '$xdma_link_width'"
  }
  if {$xdma_link_width eq "X4"} {
    set xdma_lane_xdc xdma_x4_lanes.xdc
  } else {
    set xdma_lane_xdc xdma_x8_lanes.xdc
  }
  lappend constr_files [file normalize ${constr_dir}/$xdma_lane_xdc]
  puts "INFO: XDMA_LINK_WIDTH=$xdma_link_width; selected $xdma_lane_xdc"

  set enable_ila 0
  if {[info exists ::env(ENABLE_ILA)]} {
    set enable_ila_value [string tolower [string trim $::env(ENABLE_ILA)]]
    if {[lsearch -exact {1 true yes on} $enable_ila_value] >= 0} {
      set enable_ila 1
    }
  }
  if {$enable_ila} {
    puts "INFO: ENABLE_ILA=$::env(ENABLE_ILA); adding host-trigger ILA XDC"
    lappend constr_files [file normalize ${constr_dir}/xdma_ila.xdc]
  } else {
    puts "INFO: ENABLE_ILA disabled; skipping host-trigger ILA XDC"
  }
} else {
  puts "INFO: NO_DIFF=1; skipping common XDMA/PCIe, lane, and host-trigger ILA XDC"
}
