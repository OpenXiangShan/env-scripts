set constr_files [list \
  [file normalize ${constr_dir}/ddr.xdc] \
  [file normalize ${constr_dir}/fpga.xdc] \
  [file normalize ${constr_dir}/debug.xdc] \
]

set xdma_link_width X4
if {[info exists ::env(XDMA_LINK_WIDTH)] && [string trim $::env(XDMA_LINK_WIDTH)] ne ""} {
  set xdma_link_width [string trim $::env(XDMA_LINK_WIDTH)]
}
if {[lsearch -exact {X4 X8} $xdma_link_width] < 0} {
  error "XDMA_LINK_WIDTH must be one of X4/X8, got '$xdma_link_width'"
}
if {$xdma_link_width eq "X4"} {
  set xdma_lane_xdc xdma_x4_lanes.xdc
  lappend constr_files [file normalize ${constr_dir}/xdma_x4_lanes.xdc]
} else {
  set xdma_lane_xdc xdma_x8_lanes.xdc
  lappend constr_files [file normalize ${constr_dir}/xdma_x8_lanes.xdc]
}
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
