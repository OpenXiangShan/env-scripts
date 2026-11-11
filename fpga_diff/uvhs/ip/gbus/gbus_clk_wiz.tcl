##################################################################
# Dedicated GBus host clock: 50 MHz in (clk6_p) to 100 MHz out.
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

create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name gbus_clk_wiz

set_property -dict [list \
  CONFIG.PRIMITIVE {MMCM} \
  CONFIG.PRIM_IN_FREQ {50.000} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {100.000} \
  CONFIG.CLK_OUT1_PORT {clk_out1} \
  CONFIG.USE_RESET {true} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.RESET_PORT {resetn} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.PRIM_SOURCE {Single_ended_clock_capable_pin} \
] [get_ips gbus_clk_wiz]

puts "INFO: configured gbus_clk_wiz 50 MHz to 100 MHz"
