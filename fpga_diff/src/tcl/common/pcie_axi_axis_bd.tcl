
################################################################
# This is a generated script based on design: pcie_axi_axis_bridge
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
# source pcie_axi_axis_bridge_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu19p-fsva3824-2-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name pcie_axi_axis_bridge

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
xilinx.com:ip:axi_mm2s_mapper:1.1\
xilinx.com:ip:axis_clock_converter:1.1\
xilinx.com:ip:util_vector_logic:2.0\
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
  set cfg_pcie_s [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 cfg_pcie_s ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {40} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.FREQ_HZ {50000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {15} \
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
   ] $cfg_pcie_s

  set m_axis_rq [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rq ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $m_axis_rq

  set pcie_bridge_m [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 pcie_bridge_m ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {40} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.FREQ_HZ {50000000} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $pcie_bridge_m

  set s_axis_cq [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_cq ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {16} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $s_axis_cq


  # Create ports
  set main_clk [ create_bd_port -dir I -type clk -freq_hz 50000000 main_clk ]
  set main_rst_n [ create_bd_port -dir I -type rst main_rst_n ]
  set user_clk [ create_bd_port -dir I -type clk -freq_hz 125000000 user_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {s_axis_cq:m_axis_rq} \
 ] $user_clk
  set user_reset [ create_bd_port -dir I -from 0 -to 0 user_reset ]

  # Create instance: axi_mm2s_mapper_0, and set properties
  set axi_mm2s_mapper_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_mm2s_mapper:1.1 axi_mm2s_mapper_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {40} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.ID_WIDTH {15} \
   CONFIG.TDATA_NUM_BYTES {16} \
 ] $axi_mm2s_mapper_0

  # Create instance: axis_clock_converter_0, and set properties
  set axis_clock_converter_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {16} \
 ] $axis_clock_converter_0

  # Create instance: axis_clock_converter_1, and set properties
  set axis_clock_converter_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_1 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.TDATA_NUM_BYTES {16} \
 ] $axis_clock_converter_1

  # Create instance: logic_not, and set properties
  set logic_not [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 logic_not ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_notgate.png} \
 ] $logic_not

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_0_1 [get_bd_intf_ports s_axis_cq] [get_bd_intf_pins axis_clock_converter_0/S_AXIS]
  connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_ports cfg_pcie_s] [get_bd_intf_pins axi_mm2s_mapper_0/S_AXI]
  connect_bd_intf_net -intf_net axi_mm2s_mapper_0_M_AXI [get_bd_intf_ports pcie_bridge_m] [get_bd_intf_pins axi_mm2s_mapper_0/M_AXI]
  connect_bd_intf_net -intf_net axi_mm2s_mapper_0_M_AXIS [get_bd_intf_pins axi_mm2s_mapper_0/M_AXIS] [get_bd_intf_pins axis_clock_converter_1/S_AXIS]
  connect_bd_intf_net -intf_net axis_clock_converter_0_M_AXIS [get_bd_intf_pins axi_mm2s_mapper_0/S_AXIS] [get_bd_intf_pins axis_clock_converter_0/M_AXIS]
  connect_bd_intf_net -intf_net axis_clock_converter_1_M_AXIS [get_bd_intf_ports m_axis_rq] [get_bd_intf_pins axis_clock_converter_1/M_AXIS]

  # Create port connections
  connect_bd_net -net Op1_0_1 [get_bd_ports user_reset] [get_bd_pins logic_not/Op1]
  connect_bd_net -net aclk_0_1 [get_bd_ports main_clk] [get_bd_pins axi_mm2s_mapper_0/aclk] [get_bd_pins axis_clock_converter_0/m_axis_aclk] [get_bd_pins axis_clock_converter_1/s_axis_aclk]
  connect_bd_net -net aresetn_0_1 [get_bd_ports main_rst_n] [get_bd_pins axi_mm2s_mapper_0/aresetn] [get_bd_pins axis_clock_converter_0/m_axis_aresetn] [get_bd_pins axis_clock_converter_1/s_axis_aresetn]
  connect_bd_net -net logic_not_Res [get_bd_pins axis_clock_converter_0/s_axis_aresetn] [get_bd_pins axis_clock_converter_1/m_axis_aresetn] [get_bd_pins logic_not/Res]
  connect_bd_net -net m_axis_aclk_0_1 [get_bd_ports user_clk] [get_bd_pins axis_clock_converter_0/s_axis_aclk] [get_bd_pins axis_clock_converter_1/m_axis_aclk]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces axi_mm2s_mapper_0/Bridge] [get_bd_addr_segs pcie_bridge_m/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x40000000 -target_address_space [get_bd_addr_spaces cfg_pcie_s] [get_bd_addr_segs axi_mm2s_mapper_0/S_AXI/Reg] -force


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


