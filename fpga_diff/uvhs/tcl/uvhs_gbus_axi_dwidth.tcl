##################################################################
# UVHS GBus AXI data-width converter
##################################################################

set scripts_vivado_version $::vivado_version
set current_vivado_version [version -short]
if {[string first $scripts_vivado_version $current_vivado_version] == -1} {
  error "uvhs_gbus_axi_dwidth requires Vivado $scripts_vivado_version, got $current_vivado_version"
}

set list_projs [get_projects -quiet]
if {$list_projs eq ""} {
  create_project uvhs_gbus_axi_dwidth uvhs_gbus_axi_dwidth \
    -part xcvu19p-fsva3824-2-e
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
}

set ip_vlnv xilinx.com:ip:axi_dwidth_converter:2.1
if {[get_ipdefs -all $ip_vlnv] eq ""} {
  error "required IP not found: $ip_vlnv"
}

if {[llength [get_ips -quiet uvhs_gbus_axi_dwidth]] == 0} {
  create_ip -name axi_dwidth_converter -vendor xilinx.com \
    -library ip -version 2.1 -module_name uvhs_gbus_axi_dwidth
}
set converter [get_ips uvhs_gbus_axi_dwidth]
set_property -dict {
  CONFIG.PROTOCOL {AXI4}
  CONFIG.READ_WRITE_MODE {READ_WRITE}
  CONFIG.ADDR_WIDTH {36}
  CONFIG.SI_ID_WIDTH {14}
  CONFIG.SI_DATA_WIDTH {256}
  CONFIG.MI_DATA_WIDTH {64}
  CONFIG.MAX_SPLIT_BEATS {256}
  CONFIG.PACKING_LEVEL {1}
  CONFIG.FIFO_MODE {0}
  CONFIG.ACLK_ASYNC {0}
} $converter
