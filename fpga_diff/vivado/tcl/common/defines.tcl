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

# BUFGCE_DIV divides the 200MHz board clock; default to 50MHz (/4).
set core_clk_mhz 50
if {[info exists ::env(FPGA_CORE_CLK_MHZ)] &&
    [string trim $::env(FPGA_CORE_CLK_MHZ)] ne ""} {
  set core_clk_mhz [string trim $::env(FPGA_CORE_CLK_MHZ)]
}
if {[lsearch -exact {25 40 50 100} $core_clk_mhz] < 0} {
  error "FPGA_CORE_CLK_MHZ must be one of 25/40/50/100, got '$core_clk_mhz'"
}
lappend defines FPGA_CORE_CLK_DIV=[expr {200 / $core_clk_mhz}]
puts "INFO: FPGA_CORE_CLK_MHZ=$core_clk_mhz; core clock = clk6_p/[expr {200 / $core_clk_mhz}]"
