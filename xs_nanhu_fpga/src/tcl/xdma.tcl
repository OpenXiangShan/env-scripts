
################################################################
# This is a generated script based on design: xdma
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2020.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source xdma_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu19p-fsva3824-2-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name xdma

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:axi_apb_bridge:3.0\
xilinx.com:ip:axi_clock_converter:2.1\
xilinx.com:ip:axi_uart16550:2.0\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:xdma:4.1\
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set S00_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S00_AXI ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {31} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {2} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S00_AXI

  set SYS_CFG_APB [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:apb_rtl:1.0 SYS_CFG_APB ]

  set UART_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 UART_0 ]

  set frontbus_axi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 frontbus_axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {40} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.FREQ_HZ {50000000} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $frontbus_axi

  set pcie_mgt [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_mgt ]

  set pcie_mgt_2 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_mgt_2 ]

  set rom_axi [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 rom_axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $rom_axi


  # Create ports
  set aclk [ create_bd_port -dir I -type clk -freq_hz 50000000 aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {frontbus_axi:S00_AXI:rom_axi} \
 ] $aclk
  set aresetn [ create_bd_port -dir I -type rst aresetn ]
  set dma_axi_aclk [ create_bd_port -dir O -type clk dma_axi_aclk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {preset} \
   CONFIG.FREQ_HZ {125000000} \
 ] $dma_axi_aclk
  set interrupt_out [ create_bd_port -dir O -type intr interrupt_out ]
  set interrupt_out_2 [ create_bd_port -dir O -type intr interrupt_out_2 ]
  set interrupt_out_msi_vec0to31 [ create_bd_port -dir O -type intr interrupt_out_msi_vec0to31 ]
  set interrupt_out_msi_vec0to31_2 [ create_bd_port -dir O -type intr interrupt_out_msi_vec0to31_2 ]
  set interrupt_out_msi_vec32to63 [ create_bd_port -dir O -type intr interrupt_out_msi_vec32to63 ]
  set interrupt_out_msi_vec32to63_2 [ create_bd_port -dir O -type intr interrupt_out_msi_vec32to63_2 ]
  set preset [ create_bd_port -dir O -from 0 -to 0 -type rst preset ]
  set sys_clk [ create_bd_port -dir I -type clk sys_clk ]
  set sys_clk2 [ create_bd_port -dir I -type clk sys_clk2 ]
  set sys_clk2_gt [ create_bd_port -dir I -type clk sys_clk2_gt ]
  set sys_clk_gt [ create_bd_port -dir I -type clk sys_clk_gt ]
  set uart0_intc [ create_bd_port -dir O -type intr uart0_intc ]

  # Create instance: axi_apb_bridge_0, and set properties
  set axi_apb_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_apb_bridge:3.0 axi_apb_bridge_0 ]
  set_property -dict [ list \
   CONFIG.C_APB_NUM_SLAVES {1} \
   CONFIG.C_M_APB_PROTOCOL {apb3} \
 ] $axi_apb_bridge_0

  # Create instance: axi_clock_converter_0, and set properties
  set axi_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ID_WIDTH {7} \
 ] $axi_clock_converter_0

  # Create instance: axi_clock_converter_1, and set properties
  set axi_clock_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_1 ]

  # Create instance: axi_clock_converter_2, and set properties
  set axi_clock_converter_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_2 ]

  # Create instance: axi_clock_converter_3, and set properties
  set axi_clock_converter_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_3 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ID_WIDTH {7} \
 ] $axi_clock_converter_3

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {3} \
   CONFIG.S00_HAS_REGSLICE {3} \
 ] $axi_interconnect_0

  # Create instance: axi_interconnect_1, and set properties
  set axi_interconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {1} \
   CONFIG.S00_HAS_REGSLICE {3} \
   CONFIG.S01_HAS_REGSLICE {3} \
 ] $axi_interconnect_1

  # Create instance: axi_interconnect_2, and set properties
  set axi_interconnect_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_2 ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {0} \
   CONFIG.M00_HAS_DATA_FIFO {0} \
   CONFIG.M00_HAS_REGSLICE {3} \
   CONFIG.M00_SECURE {0} \
   CONFIG.NUM_MI {1} \
   CONFIG.NUM_SI {2} \
   CONFIG.S00_ARB_PRIORITY {0} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S01_ARB_PRIORITY {0} \
   CONFIG.S01_HAS_DATA_FIFO {2} \
   CONFIG.S01_HAS_REGSLICE {0} \
   CONFIG.STRATEGY {2} \
   CONFIG.XBAR_DATA_WIDTH {256} \
 ] $axi_interconnect_2

  # Create instance: axi_interconnect_3, and set properties
  set axi_interconnect_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_3 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {5} \
 ] $axi_interconnect_3

  # Create instance: axi_uart16550_0, and set properties
  set axi_uart16550_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550:2.0 axi_uart16550_0 ]

  # Create instance: ila_2, and set properties
  set ila_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_2 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: proc_sys_reset_1, and set properties
  set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {32} \
 ] $util_vector_logic_0

  # Create instance: util_vector_logic_1, and set properties
  set util_vector_logic_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {32} \
 ] $util_vector_logic_1

  # Create instance: util_vector_logic_2, and set properties
  set util_vector_logic_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_2 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {32} \
 ] $util_vector_logic_2

  # Create instance: util_vector_logic_3, and set properties
  set util_vector_logic_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_3 ]
  set_property -dict [ list \
   CONFIG.C_SIZE {32} \
 ] $util_vector_logic_3

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0 ]
  set_property -dict [ list \
   CONFIG.BASEADDR {0x00000000} \
   CONFIG.HIGHADDR {0x001FFFFF} \
   CONFIG.PF0_DEVICE_ID_mqdma {9134} \
   CONFIG.PF2_DEVICE_ID_mqdma {9134} \
   CONFIG.PF3_DEVICE_ID_mqdma {9134} \
   CONFIG.axi_addr_width {40} \
   CONFIG.axi_data_width {256_bit} \
   CONFIG.axibar2pciebar_0 {0x0000000020000000} \
   CONFIG.axisten_freq {125} \
   CONFIG.bar_indicator {BAR_1:0} \
   CONFIG.c_m_axi_num_write {16} \
   CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
   CONFIG.disable_gt_loc {true} \
   CONFIG.dma_reset_source_sel {Phy_Ready} \
   CONFIG.en_gt_selection {true} \
   CONFIG.enable_ibert {true} \
   CONFIG.functional_mode {AXI_Bridge} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.msi_rx_pin_en {TRUE} \
   CONFIG.pcie_blk_locn {PCIE4C_X0Y3} \
   CONFIG.pciebar2axibar_0 {0x0000000080000000} \
   CONFIG.pf0_bar0_64bit {true} \
   CONFIG.pf0_bar0_enabled {true} \
   CONFIG.pf0_bar0_scale {Gigabytes} \
   CONFIG.pf0_bar0_size {2} \
   CONFIG.pf0_bar0_type_mqdma {Memory} \
   CONFIG.pf0_base_class_menu {Bridge_device} \
   CONFIG.pf0_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf0_class_code {060400} \
   CONFIG.pf0_class_code_base {06} \
   CONFIG.pf0_class_code_base_mqdma {06} \
   CONFIG.pf0_class_code_interface {00} \
   CONFIG.pf0_class_code_mqdma {068000} \
   CONFIG.pf0_class_code_sub {04} \
   CONFIG.pf0_device_id {9134} \
   CONFIG.pf0_msix_cap_pba_bir {BAR_1:0} \
   CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
   CONFIG.pf0_sriov_bar0_type {Memory} \
   CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
   CONFIG.pf1_bar0_type_mqdma {Memory} \
   CONFIG.pf1_bar2_64bit {false} \
   CONFIG.pf1_bar2_enabled {false} \
   CONFIG.pf1_bar4_64bit {false} \
   CONFIG.pf1_bar4_enabled {false} \
   CONFIG.pf1_base_class_menu {Bridge_device} \
   CONFIG.pf1_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf1_class_code {060700} \
   CONFIG.pf1_class_code_base {06} \
   CONFIG.pf1_class_code_base_mqdma {06} \
   CONFIG.pf1_class_code_interface {00} \
   CONFIG.pf1_class_code_mqdma {068000} \
   CONFIG.pf1_class_code_sub {07} \
   CONFIG.pf1_sriov_bar0_type {Memory} \
   CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} \
   CONFIG.pf2_bar0_type_mqdma {Memory} \
   CONFIG.pf2_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf2_class_code_base_mqdma {06} \
   CONFIG.pf2_class_code_mqdma {068000} \
   CONFIG.pf2_sriov_bar0_type {Memory} \
   CONFIG.pf3_bar0_type_mqdma {Memory} \
   CONFIG.pf3_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf3_class_code_base_mqdma {06} \
   CONFIG.pf3_class_code_mqdma {068000} \
   CONFIG.pf3_sriov_bar0_type {Memory} \
   CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
   CONFIG.pl_link_cap_max_link_width {X4} \
   CONFIG.plltype {QPLL1} \
   CONFIG.select_quad {GTY_Quad_226} \
   CONFIG.type1_membase_memlimit_enable {Enabled} \
   CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
   CONFIG.xdma_axilite_slave {true} \
 ] $xdma_0

  # Create instance: xdma_1, and set properties
  set xdma_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_1 ]
  set_property -dict [ list \
   CONFIG.BASEADDR {0x00000000} \
   CONFIG.HIGHADDR {0x001FFFFF} \
   CONFIG.PF0_DEVICE_ID_mqdma {9134} \
   CONFIG.PF2_DEVICE_ID_mqdma {9134} \
   CONFIG.PF3_DEVICE_ID_mqdma {9134} \
   CONFIG.axi_addr_width {40} \
   CONFIG.axi_data_width {256_bit} \
   CONFIG.axibar2pciebar_0 {0x0000000040000000} \
   CONFIG.axisten_freq {125} \
   CONFIG.bar_indicator {BAR_1:0} \
   CONFIG.c_m_axi_num_write {16} \
   CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
   CONFIG.disable_gt_loc {true} \
   CONFIG.dma_reset_source_sel {Phy_Ready} \
   CONFIG.en_gt_selection {true} \
   CONFIG.enable_ibert {true} \
   CONFIG.functional_mode {AXI_Bridge} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.msi_rx_pin_en {TRUE} \
   CONFIG.pcie_blk_locn {PCIE4C_X0Y4} \
   CONFIG.pciebar2axibar_0 {0x0000000080000000} \
   CONFIG.pf0_bar0_64bit {true} \
   CONFIG.pf0_bar0_enabled {true} \
   CONFIG.pf0_bar0_scale {Gigabytes} \
   CONFIG.pf0_bar0_size {2} \
   CONFIG.pf0_bar0_type_mqdma {Memory} \
   CONFIG.pf0_base_class_menu {Bridge_device} \
   CONFIG.pf0_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf0_class_code {060400} \
   CONFIG.pf0_class_code_base {06} \
   CONFIG.pf0_class_code_base_mqdma {06} \
   CONFIG.pf0_class_code_interface {00} \
   CONFIG.pf0_class_code_mqdma {068000} \
   CONFIG.pf0_class_code_sub {04} \
   CONFIG.pf0_device_id {9134} \
   CONFIG.pf0_msix_cap_pba_bir {BAR_1:0} \
   CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
   CONFIG.pf0_sriov_bar0_type {Memory} \
   CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
   CONFIG.pf1_bar0_type_mqdma {Memory} \
   CONFIG.pf1_bar2_64bit {false} \
   CONFIG.pf1_bar2_enabled {false} \
   CONFIG.pf1_bar4_64bit {false} \
   CONFIG.pf1_bar4_enabled {false} \
   CONFIG.pf1_base_class_menu {Bridge_device} \
   CONFIG.pf1_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf1_class_code {060700} \
   CONFIG.pf1_class_code_base {06} \
   CONFIG.pf1_class_code_base_mqdma {06} \
   CONFIG.pf1_class_code_interface {00} \
   CONFIG.pf1_class_code_mqdma {068000} \
   CONFIG.pf1_class_code_sub {07} \
   CONFIG.pf1_sriov_bar0_type {Memory} \
   CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} \
   CONFIG.pf2_bar0_type_mqdma {Memory} \
   CONFIG.pf2_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf2_class_code_base_mqdma {06} \
   CONFIG.pf2_class_code_mqdma {068000} \
   CONFIG.pf2_sriov_bar0_type {Memory} \
   CONFIG.pf3_bar0_type_mqdma {Memory} \
   CONFIG.pf3_base_class_menu_mqdma {Bridge_device} \
   CONFIG.pf3_class_code_base_mqdma {06} \
   CONFIG.pf3_class_code_mqdma {068000} \
   CONFIG.pf3_sriov_bar0_type {Memory} \
   CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
   CONFIG.pl_link_cap_max_link_width {X4} \
   CONFIG.plltype {QPLL1} \
   CONFIG.select_quad {GTY_Quad_230} \
   CONFIG.type1_membase_memlimit_enable {Enabled} \
   CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
   CONFIG.xdma_axilite_slave {true} \
 ] $xdma_1

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0x00FFFFFF} \
   CONFIG.CONST_WIDTH {32} \
 ] $xlconstant_0

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_1

  # Create interface connections
  connect_bd_intf_net -intf_net S00_AXI_0_2 [get_bd_intf_ports S00_AXI] [get_bd_intf_pins axi_interconnect_3/S00_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_clock_converter_1/M_AXI] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
  connect_bd_intf_net -intf_net axi_apb_bridge_0_APB_M [get_bd_intf_ports SYS_CFG_APB] [get_bd_intf_pins axi_apb_bridge_0/APB_M]
  connect_bd_intf_net -intf_net axi_clock_converter_0_M_AXI [get_bd_intf_pins axi_clock_converter_0/M_AXI] [get_bd_intf_pins axi_interconnect_2/S01_AXI]
  connect_bd_intf_net -intf_net axi_clock_converter_2_M_AXI [get_bd_intf_pins axi_clock_converter_2/M_AXI] [get_bd_intf_pins axi_interconnect_1/S00_AXI]
  connect_bd_intf_net -intf_net axi_clock_converter_3_M_AXI [get_bd_intf_pins axi_clock_converter_3/M_AXI] [get_bd_intf_pins axi_interconnect_2/S00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins xdma_0/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI1 [get_bd_intf_pins axi_apb_bridge_0/AXI4_LITE] [get_bd_intf_pins axi_interconnect_3/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins xdma_0/S_AXI_B]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI1 [get_bd_intf_pins axi_interconnect_3/M01_AXI] [get_bd_intf_pins axi_uart16550_0/S_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins xdma_1/S_AXI_LITE]
  connect_bd_intf_net -intf_net axi_interconnect_0_M02_AXI1 [get_bd_intf_ports rom_axi] [get_bd_intf_pins axi_interconnect_3/M02_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_1_M00_AXI [get_bd_intf_pins axi_interconnect_1/M00_AXI] [get_bd_intf_pins xdma_1/S_AXI_B]
  connect_bd_intf_net -intf_net axi_interconnect_2_M00_AXI [get_bd_intf_ports frontbus_axi] [get_bd_intf_pins axi_interconnect_2/M00_AXI]
connect_bd_intf_net -intf_net [get_bd_intf_nets axi_interconnect_2_M00_AXI] [get_bd_intf_ports frontbus_axi] [get_bd_intf_pins ila_2/SLOT_0_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M03_AXI [get_bd_intf_pins axi_clock_converter_1/S_AXI] [get_bd_intf_pins axi_interconnect_3/M03_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_3_M04_AXI [get_bd_intf_pins axi_clock_converter_2/S_AXI] [get_bd_intf_pins axi_interconnect_3/M04_AXI]
  connect_bd_intf_net -intf_net axi_uart16550_0_UART [get_bd_intf_ports UART_0] [get_bd_intf_pins axi_uart16550_0/UART]
  connect_bd_intf_net -intf_net xdma_0_M_AXI_B [get_bd_intf_pins axi_clock_converter_0/S_AXI] [get_bd_intf_pins xdma_0/M_AXI_B]
  connect_bd_intf_net -intf_net xdma_0_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins xdma_0/pcie_mgt]
  connect_bd_intf_net -intf_net xdma_1_M_AXI_B [get_bd_intf_pins axi_clock_converter_3/S_AXI] [get_bd_intf_pins xdma_1/M_AXI_B]
  connect_bd_intf_net -intf_net xdma_1_pcie_mgt [get_bd_intf_ports pcie_mgt_2] [get_bd_intf_pins xdma_1/pcie_mgt]

  # Create port connections
  connect_bd_net -net M02_ARESETN_1 [get_bd_pins axi_interconnect_0/M02_ARESETN] [get_bd_pins xdma_1/axi_ctl_aresetn]
  connect_bd_net -net Net [get_bd_ports aresetn] [get_bd_pins axi_apb_bridge_0/s_axi_aresetn] [get_bd_pins axi_clock_converter_1/s_axi_aresetn] [get_bd_pins axi_clock_converter_2/s_axi_aresetn] [get_bd_pins axi_interconnect_3/ARESETN] [get_bd_pins axi_interconnect_3/M00_ARESETN] [get_bd_pins axi_interconnect_3/M01_ARESETN] [get_bd_pins axi_interconnect_3/M02_ARESETN] [get_bd_pins axi_interconnect_3/M03_ARESETN] [get_bd_pins axi_interconnect_3/M04_ARESETN] [get_bd_pins axi_interconnect_3/S00_ARESETN] [get_bd_pins axi_uart16550_0/s_axi_aresetn] [get_bd_pins proc_sys_reset_1/ext_reset_in] [get_bd_pins xdma_0/sys_rst_n] [get_bd_pins xdma_1/sys_rst_n]
  connect_bd_net -net Net2 [get_bd_pins axi_interconnect_1/M00_AXI_awaddr] [get_bd_pins xdma_1/s_axib_awaddr]
  connect_bd_net -net Net3 [get_bd_pins axi_interconnect_1/M00_AXI_wdata] [get_bd_pins xdma_1/s_axib_wdata]
  connect_bd_net -net Net4 [get_bd_pins axi_interconnect_0/M00_AXI_wdata] [get_bd_pins xdma_0/s_axil_wdata]
  connect_bd_net -net Net5 [get_bd_pins axi_interconnect_0/M01_AXI_araddr] [get_bd_pins xdma_0/s_axib_araddr]
  connect_bd_net -net Net6 [get_bd_pins axi_interconnect_0/M01_AXI_awaddr] [get_bd_pins xdma_0/s_axib_awaddr]
  connect_bd_net -net Net7 [get_bd_pins axi_interconnect_0/M01_AXI_wdata] [get_bd_pins xdma_0/s_axib_wdata]
  connect_bd_net -net S00_ACLK_0_1 [get_bd_ports aclk] [get_bd_pins axi_apb_bridge_0/s_axi_aclk] [get_bd_pins axi_clock_converter_0/m_axi_aclk] [get_bd_pins axi_clock_converter_1/s_axi_aclk] [get_bd_pins axi_clock_converter_2/s_axi_aclk] [get_bd_pins axi_clock_converter_3/m_axi_aclk] [get_bd_pins axi_interconnect_2/ACLK] [get_bd_pins axi_interconnect_2/M00_ACLK] [get_bd_pins axi_interconnect_2/S00_ACLK] [get_bd_pins axi_interconnect_2/S01_ACLK] [get_bd_pins axi_interconnect_3/ACLK] [get_bd_pins axi_interconnect_3/M00_ACLK] [get_bd_pins axi_interconnect_3/M01_ACLK] [get_bd_pins axi_interconnect_3/M02_ACLK] [get_bd_pins axi_interconnect_3/M03_ACLK] [get_bd_pins axi_interconnect_3/M04_ACLK] [get_bd_pins axi_interconnect_3/S00_ACLK] [get_bd_pins axi_uart16550_0/s_axi_aclk] [get_bd_pins ila_2/clk] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
  connect_bd_net -net axi_interconnect_0_M00_AXI_araddr [get_bd_pins axi_interconnect_0/M00_AXI_araddr] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net axi_interconnect_0_M00_AXI_awaddr [get_bd_pins axi_interconnect_0/M00_AXI_awaddr] [get_bd_pins util_vector_logic_1/Op1]
  connect_bd_net -net axi_interconnect_0_M02_AXI_araddr [get_bd_pins axi_interconnect_0/M02_AXI_araddr] [get_bd_pins util_vector_logic_2/Op1]
  connect_bd_net -net axi_interconnect_0_M02_AXI_awaddr [get_bd_pins axi_interconnect_0/M02_AXI_awaddr] [get_bd_pins util_vector_logic_3/Op1]
  connect_bd_net -net axi_uart16550_0_ip2intc_irpt [get_bd_ports uart0_intc] [get_bd_pins axi_uart16550_0/ip2intc_irpt]
  connect_bd_net -net m_axib_araddr [get_bd_pins axi_clock_converter_3/s_axi_araddr] [get_bd_pins xdma_1/m_axib_araddr]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_ports preset] [get_bd_pins proc_sys_reset_0/peripheral_reset]
  connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins axi_clock_converter_0/m_axi_aresetn] [get_bd_pins axi_clock_converter_3/m_axi_aresetn] [get_bd_pins axi_interconnect_2/ARESETN] [get_bd_pins axi_interconnect_2/M00_ARESETN] [get_bd_pins axi_interconnect_2/S00_ARESETN] [get_bd_pins axi_interconnect_2/S01_ARESETN] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
  connect_bd_net -net s_axi_rdata [get_bd_pins axi_clock_converter_3/s_axi_rdata] [get_bd_pins xdma_1/m_axib_rdata]
  connect_bd_net -net s_axil_rdata [get_bd_pins axi_interconnect_0/M00_AXI_rdata] [get_bd_pins xdma_0/s_axil_rdata]
  connect_bd_net -net sys_clk_0_1 [get_bd_ports sys_clk] [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net sys_clk_0_2 [get_bd_ports sys_clk2] [get_bd_pins xdma_1/sys_clk]
  connect_bd_net -net sys_clk_gt_0_1 [get_bd_ports sys_clk_gt] [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net sys_clk_gt_0_2 [get_bd_ports sys_clk2_gt] [get_bd_pins xdma_1/sys_clk_gt]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins xdma_0/s_axil_araddr]
  connect_bd_net -net util_vector_logic_1_Res [get_bd_pins util_vector_logic_1/Res] [get_bd_pins xdma_0/s_axil_awaddr]
  connect_bd_net -net util_vector_logic_2_Res [get_bd_pins util_vector_logic_2/Res] [get_bd_pins xdma_1/s_axil_araddr]
  connect_bd_net -net util_vector_logic_3_Res [get_bd_pins util_vector_logic_3/Res] [get_bd_pins xdma_1/s_axil_awaddr]
  connect_bd_net -net xdma_0_axi_aclk1 [get_bd_ports dma_axi_aclk] [get_bd_pins axi_clock_converter_0/s_axi_aclk] [get_bd_pins axi_clock_converter_1/m_axi_aclk] [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_interconnect_0/M01_ACLK] [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins xdma_0/axi_aclk]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_pins axi_clock_converter_0/s_axi_aresetn] [get_bd_pins axi_interconnect_0/ARESETN] [get_bd_pins axi_interconnect_0/M01_ARESETN] [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins xdma_0/axi_aresetn]
  connect_bd_net -net xdma_0_axi_ctl_aresetn [get_bd_pins axi_clock_converter_1/m_axi_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins xdma_0/axi_ctl_aresetn]
  connect_bd_net -net xdma_0_interrupt_out [get_bd_ports interrupt_out] [get_bd_pins xdma_0/interrupt_out]
  connect_bd_net -net xdma_0_interrupt_out_msi_vec0to31 [get_bd_ports interrupt_out_msi_vec0to31] [get_bd_pins xdma_0/interrupt_out_msi_vec0to31]
  connect_bd_net -net xdma_0_interrupt_out_msi_vec32to63 [get_bd_ports interrupt_out_msi_vec32to63] [get_bd_pins xdma_0/interrupt_out_msi_vec32to63]
  connect_bd_net -net xdma_0_s_axib_rdata [get_bd_pins axi_interconnect_0/M01_AXI_rdata] [get_bd_pins xdma_0/s_axib_rdata]
  connect_bd_net -net xdma_1_axi_aclk [get_bd_pins axi_clock_converter_2/m_axi_aclk] [get_bd_pins axi_clock_converter_3/s_axi_aclk] [get_bd_pins axi_interconnect_0/M02_ACLK] [get_bd_pins axi_interconnect_1/ACLK] [get_bd_pins axi_interconnect_1/M00_ACLK] [get_bd_pins axi_interconnect_1/S00_ACLK] [get_bd_pins xdma_1/axi_aclk]
  connect_bd_net -net xdma_1_axi_aresetn [get_bd_pins axi_clock_converter_2/m_axi_aresetn] [get_bd_pins axi_clock_converter_3/s_axi_aresetn] [get_bd_pins axi_interconnect_1/ARESETN] [get_bd_pins axi_interconnect_1/M00_ARESETN] [get_bd_pins axi_interconnect_1/S00_ARESETN] [get_bd_pins xdma_1/axi_aresetn]
  connect_bd_net -net xdma_1_interrupt_out [get_bd_ports interrupt_out_2] [get_bd_pins xdma_1/interrupt_out]
  connect_bd_net -net xdma_1_interrupt_out_msi_vec0to31 [get_bd_ports interrupt_out_msi_vec0to31_2] [get_bd_pins xdma_1/interrupt_out_msi_vec0to31]
  connect_bd_net -net xdma_1_interrupt_out_msi_vec32to63 [get_bd_ports interrupt_out_msi_vec32to63_2] [get_bd_pins xdma_1/interrupt_out_msi_vec32to63]
  connect_bd_net -net xdma_1_m_axib_awaddr [get_bd_pins axi_clock_converter_3/s_axi_awaddr] [get_bd_pins xdma_1/m_axib_awaddr]
  connect_bd_net -net xdma_1_m_axib_wdata [get_bd_pins axi_clock_converter_3/s_axi_wdata] [get_bd_pins xdma_1/m_axib_wdata]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins util_vector_logic_0/Op2] [get_bd_pins util_vector_logic_1/Op2] [get_bd_pins util_vector_logic_2/Op2] [get_bd_pins util_vector_logic_3/Op2] [get_bd_pins xlconstant_0/dout]
  connect_bd_net -net xlconstant_0_dout1 [get_bd_pins axi_uart16550_0/freeze] [get_bd_pins xlconstant_1/dout]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_B] [get_bd_addr_segs frontbus_axi/Reg] -force
  assign_bd_address -offset 0x80000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces xdma_1/M_AXI_B] [get_bd_addr_segs frontbus_axi/Reg] -force
  assign_bd_address -offset 0x31200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs SYS_CFG_APB/Reg] -force
  assign_bd_address -offset 0x310B0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs axi_uart16550_0/S_AXI/Reg] -force
  assign_bd_address -offset 0x10000000 -range 0x10000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs rom_axi/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x08000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs xdma_0/S_AXI_B/BAR0] -force
  assign_bd_address -offset 0x48000000 -range 0x02000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs xdma_0/S_AXI_LITE/CTL0] -force
  assign_bd_address -offset 0x60000000 -range 0x20000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs xdma_1/S_AXI_B/BAR0] -force
  assign_bd_address -offset 0x4C000000 -range 0x04000000 -target_address_space [get_bd_addr_spaces S00_AXI] [get_bd_addr_segs xdma_1/S_AXI_LITE/CTL0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


