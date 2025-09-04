
################################################################
# This is a generated script based on design: xdma_trace
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
# source xdma_trace_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu19p-fsva3824-2-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name xdma_trace

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
xilinx.com:ip:util_ds_buf:2.1\
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
  set M00_AXIS_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS_0 ]

  set S00_AXIS_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {64} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S00_AXIS_0

  set pcie_ep_gt_ref [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_ep_gt_ref ]


  # Create ports
  set cpu_clk [ create_bd_port -dir I -type clk cpu_clk ]
  set cpu_rstn [ create_bd_port -dir I -type rst cpu_rstn ]
  set pci_exp_rxn [ create_bd_port -dir I -from 7 -to 0 pci_exp_rxn ]
  set pci_exp_rxp [ create_bd_port -dir I -from 7 -to 0 pci_exp_rxp ]
  set pci_exp_txn [ create_bd_port -dir O -from 7 -to 0 pci_exp_txn ]
  set pci_exp_txp [ create_bd_port -dir O -from 7 -to 0 pci_exp_txp ]
  set pcie_ep_lnk_up [ create_bd_port -dir O pcie_ep_lnk_up ]
  set pcie_ep_perstn [ create_bd_port -dir I -type rst pcie_ep_perstn ]

  # Create instance: cpu_axis_rx_interconnect, and set properties
  set cpu_axis_rx_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 cpu_axis_rx_interconnect ]
  set_property -dict [ list \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_HAS_REGSLICE {1} \
 ] $cpu_axis_rx_interconnect

  # Create instance: cpu_axis_tx_interconnect, and set properties
  set cpu_axis_tx_interconnect [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect:2.1 cpu_axis_tx_interconnect ]
  set_property -dict [ list \
   CONFIG.M00_HAS_REGSLICE {0} \
   CONFIG.NUM_MI {1} \
   CONFIG.S00_HAS_REGSLICE {1} \
 ] $cpu_axis_tx_interconnect

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.1 util_ds_buf_0 ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $util_ds_buf_0

  # Create instance: xdma, and set properties
  set xdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma ]
  set_property -dict [ list \
   CONFIG.PF0_DEVICE_ID_mqdma {9048} \
   CONFIG.PF2_DEVICE_ID_mqdma {9048} \
   CONFIG.PF3_DEVICE_ID_mqdma {9048} \
   CONFIG.axi_data_width {512_bit} \
   CONFIG.axisten_freq {250} \
   CONFIG.cfg_mgmt_if {false} \
   CONFIG.coreclk_freq {500} \
   CONFIG.en_gt_selection {true} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.pcie_blk_locn {PCIE4C_X0Y4} \
   CONFIG.pf0_device_id {9048} \
   CONFIG.pl_link_cap_max_link_speed {16.0_GT/s} \
   CONFIG.pl_link_cap_max_link_width {X8} \
   CONFIG.plltype {QPLL0} \
   CONFIG.select_quad {GTY_Quad_231} \
   CONFIG.xdma_axi_intf_mm {AXI_Stream} \
   CONFIG.xdma_axilite_slave {false} \
 ] $xdma

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $xlconstant_0

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports pcie_ep_gt_ref] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net S00_AXIS_0_1 [get_bd_intf_ports S00_AXIS_0] [get_bd_intf_pins cpu_axis_tx_interconnect/S00_AXIS]
  connect_bd_intf_net -intf_net axis_interconnect_0_M00_AXIS [get_bd_intf_ports M00_AXIS_0] [get_bd_intf_pins cpu_axis_rx_interconnect/M00_AXIS]
  connect_bd_intf_net -intf_net cpu_axis_tx_interconnect1_M00_AXIS [get_bd_intf_pins cpu_axis_tx_interconnect/M00_AXIS] [get_bd_intf_pins xdma/S_AXIS_C2H_0]
  connect_bd_intf_net -intf_net xdma_0_M_AXIS_H2C_0 [get_bd_intf_pins cpu_axis_rx_interconnect/S00_AXIS] [get_bd_intf_pins xdma/M_AXIS_H2C_0]

  # Create port connections
  connect_bd_net -net M00_AXIS_ACLK_0_1 [get_bd_ports cpu_clk] [get_bd_pins cpu_axis_rx_interconnect/M00_AXIS_ACLK] [get_bd_pins cpu_axis_tx_interconnect/ACLK] [get_bd_pins cpu_axis_tx_interconnect/S00_AXIS_ACLK]
  connect_bd_net -net M00_AXIS_ARESETN_0_1 [get_bd_ports cpu_rstn] [get_bd_pins cpu_axis_rx_interconnect/M00_AXIS_ARESETN] [get_bd_pins cpu_axis_tx_interconnect/ARESETN] [get_bd_pins cpu_axis_tx_interconnect/S00_AXIS_ARESETN]
  connect_bd_net -net pci_exp_rxn_0_1 [get_bd_ports pci_exp_rxn] [get_bd_pins xdma/pci_exp_rxn]
  connect_bd_net -net pci_exp_rxp_0_1 [get_bd_ports pci_exp_rxp] [get_bd_pins xdma/pci_exp_rxp]
  connect_bd_net -net sys_rst_n_0_1 [get_bd_ports pcie_ep_perstn] [get_bd_pins xdma/sys_rst_n]
  connect_bd_net -net util_ds_buf_0_IBUF_DS_ODIV2 [get_bd_pins util_ds_buf_0/IBUF_DS_ODIV2] [get_bd_pins xdma/sys_clk]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins util_ds_buf_0/IBUF_OUT] [get_bd_pins xdma/sys_clk_gt]
  connect_bd_net -net xdma_0_axi_aclk [get_bd_pins cpu_axis_rx_interconnect/ACLK] [get_bd_pins cpu_axis_rx_interconnect/S00_AXIS_ACLK] [get_bd_pins cpu_axis_tx_interconnect/M00_AXIS_ACLK] [get_bd_pins xdma/axi_aclk]
  connect_bd_net -net xdma_0_axi_aresetn [get_bd_pins cpu_axis_rx_interconnect/ARESETN] [get_bd_pins cpu_axis_rx_interconnect/S00_AXIS_ARESETN] [get_bd_pins cpu_axis_tx_interconnect/M00_AXIS_ARESETN] [get_bd_pins xdma/axi_aresetn]
  connect_bd_net -net xdma_0_pci_exp_txn [get_bd_ports pci_exp_txn] [get_bd_pins xdma/pci_exp_txn]
  connect_bd_net -net xdma_0_pci_exp_txp [get_bd_ports pci_exp_txp] [get_bd_pins xdma/pci_exp_txp]
  connect_bd_net -net xdma_0_user_lnk_up [get_bd_ports pcie_ep_lnk_up] [get_bd_pins xdma/user_lnk_up]
  connect_bd_net -net xlconstant_0_dout [get_bd_pins xdma/usr_irq_req] [get_bd_pins xlconstant_0/dout]

  # Create address segments


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


