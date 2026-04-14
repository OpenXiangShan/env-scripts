
################################################################
# This is a generated script based on design: jtag_ddr_subsys
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
set scripts_vivado_version $::vivado_version
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
# source jtag_ddr_subsys_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu19p-fsva3824-2-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name jtag_ddr_subsys

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
xilinx.com:ip:ddr4:2.2\
xilinx.com:ip:jtag_axi:1.2\
xilinx.com:ip:axi_datamover:5.1\
xilinx.com:ip:axis_clock_converter:1.1\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:proc_sys_reset:5.0\
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

proc ensure_h2c_s2mm_bridge_module {} {
  variable script_folder

  set rtl_file [file normalize [file join $script_folder ../../rtl/common/h2c_s2mm_bridge.v]]
  if {![file exists $rtl_file]} {
     error "Unable to find RTL file for module reference: $rtl_file"
  }

  set src_fileset [get_filesets -quiet sources_1]
  if {$src_fileset eq ""} {
     error "Unable to find sources_1 fileset while preparing h2c_s2mm_bridge module reference"
  }

  if {[get_projects -quiet] ne ""} {
     set_property source_mgmt_mode All [current_project]
  }

  set rtl_file_obj [get_files -quiet $rtl_file]
  if {[llength $rtl_file_obj] == 0} {
     add_files -norecurse -fileset $src_fileset $rtl_file
     set rtl_file_obj [get_files -quiet $rtl_file]
  }

  if {[llength $rtl_file_obj] == 0} {
     error "Failed to add RTL file for module reference: $rtl_file"
  }

  set_property -name file_type -value {Verilog} -objects $rtl_file_obj
  update_compile_order -fileset $src_fileset
}



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
  set DDR4 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddr4_rtl:1.0 DDR4 ]

  set OSC_SYS_CLK [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 OSC_SYS_CLK ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {80000000} \
   ] $OSC_SYS_CLK

   if { $::cpu == "nutshell" } {
      set SOC_M_AXI_DATA_WIDTH 64
   } else {
      set SOC_M_AXI_DATA_WIDTH 256
   }

  set SOC_M_AXI [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 SOC_M_AXI ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {33} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH $SOC_M_AXI_DATA_WIDTH \
   CONFIG.FREQ_HZ {25000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {18} \
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
   ] $SOC_M_AXI

  set S_AXIS_H2C [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_H2C ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {32} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S_AXIS_H2C


  # Create ports
  set H2C_CLK [ create_bd_port -dir I -type clk -freq_hz 250000000 H2C_CLK ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S_AXIS_H2C} \
   CONFIG.ASSOCIATED_RESET {h2c_rstn} \
 ] $H2C_CLK
  set SOC_CLK [ create_bd_port -dir I -type clk -freq_hz 25000000 SOC_CLK ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {SOC_M_AXI} \
 ] $SOC_CLK
  set calib_complete [ create_bd_port -dir O calib_complete ]
  set ddr_rstn [ create_bd_port -dir I -type rst ddr_rstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $ddr_rstn
  set h2c_rstn [ create_bd_port -dir I -type rst h2c_rstn ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $h2c_rstn
  set soc_rstn [ create_bd_port -dir I -type rst soc_rstn ]

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property -dict [list \
    CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
    CONFIG.M00_HAS_DATA_FIFO {2} \
    CONFIG.M00_HAS_REGSLICE {3} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {3} \
    CONFIG.S00_HAS_DATA_FIFO {2} \
    CONFIG.S00_HAS_REGSLICE {4} \
    CONFIG.S01_HAS_DATA_FIFO {2} \
    CONFIG.S01_HAS_REGSLICE {4} \
    CONFIG.S02_HAS_DATA_FIFO {2} \
    CONFIG.S02_HAS_REGSLICE {4} \
    CONFIG.STRATEGY {2} \
  ] $axi_interconnect_0
  # Create instance: axi_datamover_0, and set properties
  set axi_datamover_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover_0 ]
  set_property -dict [ list \
   CONFIG.c_addr_width {33} \
   CONFIG.c_enable_mm2s {0} \
   CONFIG.c_enable_s2mm {1} \
   CONFIG.c_include_s2mm {Full} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_m_axi_s2mm_data_width {256} \
   CONFIG.c_s2mm_burst_size {16} \
   CONFIG.c_s2mm_support_indet_btt {1} \
   CONFIG.c_s_axis_s2mm_tdata_width {256} \
   ] $axi_datamover_0
  # Create instance: axis_clock_converter_0
  set axis_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_0 ]
  # Create instance: ddr4_0, and set properties
  set ddr4_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0 ]
  set_property -dict [list \
    CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {None} \
    CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {None} \
    CONFIG.ADDN_UI_CLKOUT3_FREQ_HZ {None} \
    CONFIG.ADDN_UI_CLKOUT4_FREQ_HZ {None} \
    CONFIG.C0.DDR4_AxiAddressWidth {33} \
    CONFIG.C0.DDR4_AxiDataWidth {64} \
    CONFIG.C0.DDR4_CLKFBOUT_MULT {15} \
    CONFIG.C0.DDR4_CLKOUT0_DIVIDE {6} \
    CONFIG.C0.DDR4_CasLatency {11} \
    CONFIG.C0.DDR4_CasWriteLatency {11} \
    CONFIG.C0.DDR4_DataWidth {64} \
    CONFIG.C0.DDR4_InputClockPeriod {12500} \
    CONFIG.C0.DDR4_MemoryPart {MTA8ATF1G64HZ-2G3} \
    CONFIG.C0.DDR4_MemoryType {SODIMMs} \
    CONFIG.C0.DDR4_TimePeriod {1250} \
  ] $ddr4_0
  # Create instance: jtag_axi_0, and set properties
  set jtag_axi_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:jtag_axi:1.2 jtag_axi_0 ]
  set_property -dict [list \
    CONFIG.M_AXI_ID_WIDTH {1} \
    CONFIG.M_HAS_BURST {0} \
    CONFIG.RD_TXN_QUEUE_LENGTH {8} \
    CONFIG.WR_TXN_QUEUE_LENGTH {8} \
  ] $jtag_axi_0
  # Create instance: h2c_s2mm_bridge_0
  ensure_h2c_s2mm_bridge_module
  set h2c_s2mm_bridge_0 [ create_bd_cell -type module -reference h2c_s2mm_bridge h2c_s2mm_bridge_0 ]
  # Create instance: logic_not, and set properties
  set logic_not [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 logic_not ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $logic_not
  # Create instance: rst_ddr4_200M, and set properties
  set rst_ddr4_200M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ddr4_200M ]

  # Create interface connections
  connect_bd_intf_net -intf_net C0_SYS_CLK_0_1 [get_bd_intf_ports OSC_SYS_CLK] [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  connect_bd_intf_net -intf_net S_AXIS_H2C_0_1 [get_bd_intf_ports S_AXIS_H2C] [get_bd_intf_pins axis_clock_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins jtag_axi_0/M_AXI]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_S2MM [get_bd_intf_pins axi_datamover_0/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_0/S02_AXI]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axis_clock_converter_0/M_AXIS] [get_bd_intf_pins h2c_s2mm_bridge_0/S_AXIS]
  connect_bd_intf_net -intf_net h2c_s2mm_bridge_0_M_AXIS [get_bd_intf_pins h2c_s2mm_bridge_0/M_AXIS] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net h2c_s2mm_bridge_0_M_AXIS_S2MM_CMD [get_bd_intf_pins h2c_s2mm_bridge_0/M_AXIS_S2MM_CMD] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_S2MM_STS [get_bd_intf_pins axi_datamover_0/M_AXIS_S2MM_STS] [get_bd_intf_pins h2c_s2mm_bridge_0/S_AXIS_S2MM_STS]
  connect_bd_intf_net -intf_net SOC_M_AXI_1 [get_bd_intf_ports SOC_M_AXI] [get_bd_intf_pins axi_interconnect_0/S01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  connect_bd_intf_net -intf_net ddr4_0_C0_DDR4 [get_bd_intf_ports DDR4] [get_bd_intf_pins ddr4_0/C0_DDR4]

  # Create port connections
  connect_bd_net -net H2C_CLK_1 [get_bd_ports H2C_CLK] [get_bd_pins axis_clock_converter_0/s_axis_aclk]
  connect_bd_net -net M00_ACLK_1  [get_bd_pins ddr4_0/c0_ddr4_ui_clk] \
  [get_bd_pins axi_datamover_0/m_axi_s2mm_aclk] \
  [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_awclk] \
  [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins axi_interconnect_0/M00_ACLK] \
  [get_bd_pins axi_interconnect_0/S00_ACLK] \
  [get_bd_pins axi_interconnect_0/S02_ACLK] \
  [get_bd_pins axis_clock_converter_0/m_axis_aclk] \
  [get_bd_pins h2c_s2mm_bridge_0/clk] \
  [get_bd_pins jtag_axi_0/aclk] \
  [get_bd_pins rst_ddr4_200M/slowest_sync_clk]
  connect_bd_net -net SOC_CLK_1  [get_bd_ports SOC_CLK] \
  [get_bd_pins axi_interconnect_0/S01_ACLK]
  connect_bd_net -net ddr4_0_c0_ddr4_ui_clk_sync_rst  [get_bd_pins ddr4_0/c0_ddr4_ui_clk_sync_rst] \
  [get_bd_pins rst_ddr4_200M/ext_reset_in]
  connect_bd_net -net ddr4_0_c0_init_calib_complete1  [get_bd_pins ddr4_0/c0_init_calib_complete] \
  [get_bd_ports calib_complete] \
  [get_bd_pins rst_ddr4_200M/dcm_locked]
  connect_bd_net -net ddr_rst_1  [get_bd_ports ddr_rstn] \
  [get_bd_pins logic_not/Op1]
  connect_bd_net -net h2c_rstn_1 [get_bd_ports h2c_rstn] [get_bd_pins axis_clock_converter_0/s_axis_aresetn]
  connect_bd_net -net rst_ddr4_0_200M_interconnect_aresetn  [get_bd_pins rst_ddr4_200M/interconnect_aresetn] \
  [get_bd_pins axi_interconnect_0/ARESETN] \
  [get_bd_pins axi_interconnect_0/M00_ARESETN] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN] \
  [get_bd_pins axi_interconnect_0/S02_ARESETN]
  connect_bd_net -net rst_ddr4_0_200M_peripheral_aresetn  [get_bd_pins rst_ddr4_200M/peripheral_aresetn] \
  [get_bd_pins ddr4_0/c0_ddr4_aresetn] \
  [get_bd_pins jtag_axi_0/aresetn] \
  [get_bd_pins axi_datamover_0/m_axi_s2mm_aresetn] \
  [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_aresetn] \
  [get_bd_pins axis_clock_converter_0/m_axis_aresetn] \
  [get_bd_pins h2c_s2mm_bridge_0/rstn]
  connect_bd_net -net soc_rstn_1  [get_bd_ports soc_rstn] \
  [get_bd_pins axi_interconnect_0/S01_ARESETN]
  connect_bd_net -net util_vector_logic_0_Res  [get_bd_pins logic_not/Res] \
  [get_bd_pins ddr4_0/sys_rst]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces axi_datamover_0/Data_S2MM] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x000100000000 -target_address_space [get_bd_addr_spaces jtag_axi_0/Data] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force
  assign_bd_address -offset 0x00000000 -range 0x000200000000 -target_address_space [get_bd_addr_spaces SOC_M_AXI] [get_bd_addr_segs ddr4_0/C0_DDR4_MEMORY_MAP/C0_DDR4_ADDRESS_BLOCK] -force


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
