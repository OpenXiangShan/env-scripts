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

# Optional CPU/SoC clock derived from clk6_p (200MHz).  FPGA_CORE_CLK_MHZ is the
# target frequency in MHz and must divide 200 evenly (100, 50, 40, 25, 20, ...).
# FPGA_CORE_CLK_100M=1 is kept as a legacy alias for FPGA_CORE_CLK_MHZ=100.
set _core_clk_mhz ""
if {[info exists ::env(FPGA_CORE_CLK_MHZ)] &&
    [string trim $::env(FPGA_CORE_CLK_MHZ)] ne ""} {
  set _core_clk_mhz [string trim $::env(FPGA_CORE_CLK_MHZ)]
} elseif {[info exists ::env(FPGA_CORE_CLK_100M)] &&
          [string trim $::env(FPGA_CORE_CLK_100M)] eq "1"} {
  set _core_clk_mhz 100
}
if {$_core_clk_mhz ne ""} {
  if {![string is integer -strict $_core_clk_mhz] || $_core_clk_mhz <= 0} {
    error "FPGA_CORE_CLK_MHZ must be a positive integer, got '$_core_clk_mhz'"
  }
  if {200 % $_core_clk_mhz != 0} {
    error "FPGA_CORE_CLK_MHZ must divide the 200MHz board clock evenly, got '$_core_clk_mhz'"
  }
  if {$_core_clk_mhz < 25 || $_core_clk_mhz > 100} {
    error "FPGA_CORE_CLK_MHZ must be between 25 and 100 (clk6_p/2 .. clk6_p/8, BUFGCE_DIV range), got '$_core_clk_mhz'"
  }
  set _core_clk_div [expr {200 / $_core_clk_mhz}]
  lappend defines FPGA_CORE_CLK_MHZ=$_core_clk_mhz
  lappend defines FPGA_CORE_CLK_DIV=$_core_clk_div
  puts "INFO: FPGA_CORE_CLK_MHZ=$_core_clk_mhz; sys_clk_i = clk6_p/$_core_clk_div"
}
