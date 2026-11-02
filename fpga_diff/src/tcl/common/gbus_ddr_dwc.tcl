##################################################################
# NutShell GBus DDR port: 64-bit AXI4 to the 256-bit vendor DDR IP.
#
# Exported as a synthesis checkpoint and imported by the UVHS frontend as a
# blackbox.  The converter has no master-side ID ports, so the CPU reaches the
# DDR as a single in-order master.
##################################################################

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
  create_project xs_v3 xs_v3 -part xcvu19p-fsva3824-2-e
  set_property target_language Verilog [current_project]
}

create_ip -name axi_dwidth_converter -vendor xilinx.com -library ip \
  -module_name gbus_ddr_dwc

set_property -dict [list \
  CONFIG.PROTOCOL {AXI4} \
  CONFIG.READ_WRITE_MODE {READ_WRITE} \
  CONFIG.ADDR_WIDTH {34} \
  CONFIG.SI_DATA_WIDTH {64} \
  CONFIG.MI_DATA_WIDTH {256} \
  CONFIG.SI_ID_WIDTH {14} \
] [get_ips gbus_ddr_dwc]

puts "INFO: configured gbus_ddr_dwc 64-bit to 256-bit AXI4"
