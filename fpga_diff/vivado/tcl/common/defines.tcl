set defines [list \
  XIANGSHAN_FPGA \
  DDR4_16G_X8 \
  DQ64 \
  DDR4_2400 \
  DQ=64 \
  MICRON_DDR \
  DDR4_16Gbx8 \
  DDR4 \
  SRAM_SYN \
]

# BUFGCE_DIV divides the 200MHz board clock.
set core_clk_mhz 50
if {[info exists cpu] && [lsearch -exact {boom nutshell} $cpu] >= 0} {
  set core_clk_mhz 100
}
if {[info exists ::env(FPGA_CORE_CLK_MHZ)] &&
    [string trim $::env(FPGA_CORE_CLK_MHZ)] ne ""} {
  set core_clk_mhz [string trim $::env(FPGA_CORE_CLK_MHZ)]
}
if {[lsearch -exact {25 40 50 100} $core_clk_mhz] < 0} {
  error "FPGA_CORE_CLK_MHZ must be one of 25/40/50/100, got '$core_clk_mhz'"
}
lappend defines FPGA_CORE_CLK_DIV=[expr {200 / $core_clk_mhz}]
puts "INFO: FPGA_CORE_CLK_MHZ=$core_clk_mhz; core clock = clk6_p/[expr {200 / $core_clk_mhz}]"

set timing_core_clk_mhz 25
if {[info exists cpu] && [lsearch -exact {boom nutshell} $cpu] >= 0} {
  set timing_core_clk_mhz $core_clk_mhz
}
if {[info exists ::env(TIMING_CORE_CLK_MHZ)] &&
    [string trim $::env(TIMING_CORE_CLK_MHZ)] ne ""} {
  set timing_core_clk_mhz [string trim $::env(TIMING_CORE_CLK_MHZ)]
}
if {[lsearch -exact {25 40 50 100} $timing_core_clk_mhz] < 0} {
  error "TIMING_CORE_CLK_MHZ must be one of 25/40/50/100, got '$timing_core_clk_mhz'"
}
puts "INFO: TIMING_CORE_CLK_MHZ=$timing_core_clk_mhz"
