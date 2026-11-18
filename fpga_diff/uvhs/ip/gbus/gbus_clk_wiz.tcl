##################################################################
# Dedicated GBus host clock: 100 MHz out.  The reference differs per CPU, so
# export_vivado_ip.tcl sets gbus_clk_wiz_in_freq before sourcing this file.
#
# XiangShan references 80 MHz clk7_p, the DDR clock the mainline XDMA flow also
# uses.  clk7_p carries no DUT timing paths, so UVHS leaves its period at
# 12.5 ns.  The original 50 MHz clk6_p reference hit PDRC-179 instead: clk6_p is
# the UART/peripheral clock, and a reset crossing between FPGAs makes UVHS relax
# its signoff period from 20 ns to ~35.7 ns.  The bitstream MMCM check recomputes
# the VCO from that relaxed period, so the 50 MHz-referenced 1200 MHz VCO fell
# to 672 MHz and the bitstream was rejected.
#
# NutShell keeps 50 MHz clk6_p: its DDR sits beside the CPU on b0.f2 and has no
# reason to depend on the DDR reference clock.
#
# Exported as a synthesis checkpoint and imported by the UVHS frontend as a
# blackbox.  The blackbox boundary is deliberate: a bare MMCME4_ADV primitive
# is inferred by UVHS as divide-by-1 with TCK-121, while a blackbox lets the
# backend constrain clk_out1 explicitly (see uvhs/compilation/backend_run.tcl).
##################################################################

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project xs_v3 xs_v3 -part xcvu19p-fsva3824-2-e
  set_property target_language Verilog [current_project]
}

if {![info exists gbus_clk_wiz_in_freq]} {
    set gbus_clk_wiz_in_freq 50.000
}
create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name gbus_clk_wiz

set_property -dict [list \
  CONFIG.PRIMITIVE {MMCM} \
  CONFIG.PRIM_IN_FREQ $gbus_clk_wiz_in_freq \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
  CONFIG.CLK_OUT1_PORT {clk_out1} \
  CONFIG.USE_RESET {true} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.RESET_PORT {resetn} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
] [get_ips gbus_clk_wiz]

puts "INFO: configured gbus_clk_wiz $gbus_clk_wiz_in_freq MHz to 100 MHz"
