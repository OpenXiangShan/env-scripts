
################################################################
# This is a generated script based on design: xdma_ep
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
# source xdma_ep_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvu19p-fsva3824-2-e
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name xdma_ep

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
proc pick_ip_vlnv {base} {
    set defs [get_ipdefs -all xilinx.com:ip:${base}:*]
    if { $defs eq "" } {
      return xilinx.com:ip:${base}
    }
    return [lindex $defs end]
}
proc read_difftest_macro_value {macro_name} {
  set hdrs [get_files -quiet *DifftestMacros.svh]
  if {[llength $hdrs] == 0} {
    error "DifftestMacros.svh not found in Vivado sources. Regenerate CPU RTL before creating xdma_ep."
  }

  set hdr [lindex $hdrs 0]
  set fp [open $hdr r]
  set value ""
  set pattern [format {^\s*`define\s+%s\s+([0-9]+)\s*$} $macro_name]
  while {[gets $fp line] >= 0} {
    if {[regexp $pattern $line match macro_value]} {
      set value $macro_value
      break
    }
  }
  close $fp

  if {$value eq ""} {
    error "$macro_name not found in $hdr. Regenerate CPU RTL with a difftest that emits host AXIS macros."
  }
  return $value
}
proc check_difftest_host_axis_bytes {axis_bytes} {
  set difftest_axis_bytes [read_difftest_macro_value CONFIG_DIFFTEST_HOST_AXIS_BYTES]
  if {![string is integer -strict $difftest_axis_bytes] || $difftest_axis_bytes <= 0} {
    error "CONFIG_DIFFTEST_HOST_AXIS_BYTES must be a positive integer, got '$difftest_axis_bytes'"
  }
  if {$difftest_axis_bytes != $axis_bytes} {
    error "Difftest host AXIS bytes mismatch: Tcl=$axis_bytes, Difftest=$difftest_axis_bytes"
  }
  puts "INFO: DiffTest host AXIS bytes match Tcl XDMA config: ${axis_bytes}"
}

proc env_choice {name default allowed} {
  set value $default
  if {[info exists ::env($name)] && [string trim $::env($name)] ne ""} {
    set value [string trim $::env($name)]
  }
  if {[lsearch -exact $allowed $value] < 0} {
    error "$name must be one of {$allowed}, got '$value'"
  }
  puts "INFO: $name=$value"
  return $value
}

if { $bCheckIPs == 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2058 -severity "INFO" "Current scripts_vivado_version value: '$::vivado_version'"
  
  set xdma_vlnv [pick_ip_vlnv xdma]
  set util_vlnv [pick_ip_vlnv util_ds_buf]
  set list_check_ips [list \
    $util_vlnv\
    $xdma_vlnv\
   ]

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
  variable xdma_vlnv
  variable util_vlnv
  set xdma_link_width [env_choice XDMA_LINK_WIDTH X4 {X4 X8}]
  set xdma_lane_count [string range $xdma_link_width 1 end]
  set xdma_lane_msb [expr {$xdma_lane_count - 1}]
  if {$xdma_link_width eq "X4"} {
    set xdma_axisten_freq 125
  } else {
    set xdma_axisten_freq 250
  }
  puts "INFO: XDMA axisten_freq=$xdma_axisten_freq for $xdma_link_width"

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
  set difftest_host_axis_bytes 32
  check_difftest_host_axis_bytes $difftest_host_axis_bytes


  # Create interface ports
  set S00_AXIS_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 S00_AXIS_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES $difftest_host_axis_bytes \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $S00_AXIS_0

  set M00_AXIS_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 M00_AXIS_0 ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES $difftest_host_axis_bytes \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $M00_AXIS_0

  set XDMA_AXI_LITE [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 XDMA_AXI_LITE ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {25000000} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $XDMA_AXI_LITE

  set pcie_ep_gt_ref [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_ep_gt_ref ]


  # Create ports
  set cpu_rstn [ create_bd_port -dir I -type rst cpu_rstn ]
  set pci_exp_rxn [ create_bd_port -dir I -from $xdma_lane_msb -to 0 pci_exp_rxn ]
  set pci_exp_rxp [ create_bd_port -dir I -from $xdma_lane_msb -to 0 pci_exp_rxp ]
  set pci_exp_txn [ create_bd_port -dir O -from $xdma_lane_msb -to 0 pci_exp_txn ]
  set pci_exp_txp [ create_bd_port -dir O -from $xdma_lane_msb -to 0 pci_exp_txp ]
  set pcie_ep_lnk_up [ create_bd_port -dir O pcie_ep_lnk_up ]
  set pcie_ep_perstn [ create_bd_port -dir I -type rst pcie_ep_perstn ]
  set TO_DIFFTEST_PCIE_CLK [ create_bd_port -dir O -type clk TO_DIFFTEST_PCIE_CLK ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {S00_AXIS_0:M00_AXIS_0} \
 ] $TO_DIFFTEST_PCIE_CLK
  set cpu_clk [ create_bd_port -dir I -type clk -freq_hz 25000000 cpu_clk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {XDMA_AXI_LITE} \
   CONFIG.ASSOCIATED_RESET {cpu_rstn} \
 ] $cpu_clk

  # Create instance: axi_interconnect_0, and set properties
  set axi_interconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0 ]
  set_property CONFIG.NUM_MI {1} $axi_interconnect_0

  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv $util_vlnv util_ds_buf_0 ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf_0

  # Create instance: xdma_0, and set properties
  set xdma_0 [ create_bd_cell -type ip -vlnv $xdma_vlnv xdma_0 ]
  # Configure based on XDMA IP version
  if { [string match "*4.2" $xdma_vlnv] } {
    set_property -dict [list \
      CONFIG.PF0_DEVICE_ID_mqdma {9048} \
      CONFIG.PF0_SRIOV_VF_DEVICE_ID {A048} \
      CONFIG.PF2_DEVICE_ID_mqdma {9248} \
      CONFIG.PF3_DEVICE_ID_mqdma {9348} \
      CONFIG.axi_data_width {256_bit} \
      CONFIG.axilite_master_en {true} \
      CONFIG.axilite_master_scale {Megabytes} \
      CONFIG.axilite_master_size {1} \
      CONFIG.axisten_freq $xdma_axisten_freq \
      CONFIG.bar0_indicator {1} \
      CONFIG.bar1_indicator {0} \
      CONFIG.bar_indicator {BAR_0} \
      CONFIG.cfg_mgmt_if {false} \
      CONFIG.copy_pf0 {true} \
      CONFIG.dma_reset_source_sel {Phy_Ready} \
      CONFIG.en_gt_selection {true} \
      CONFIG.enable_gtwizard {false} \
      CONFIG.mode_selection {Advanced} \
      CONFIG.pcie_blk_locn {PCIE4C_X0Y6} \
      CONFIG.pf0_bar0_64bit {false} \
      CONFIG.pf0_bar0_enabled {true} \
      CONFIG.pf0_bar0_scale {Kilobytes} \
      CONFIG.pf0_bar0_size {128} \
      CONFIG.pf0_bar0_type_mqdma {DMA} \
      CONFIG.pf0_bar1_enabled {false} \
      CONFIG.pf0_base_class_menu {Memory_controller} \
      CONFIG.pf0_base_class_menu_mqdma {Memory_controller} \
      CONFIG.pf0_class_code {058000} \
      CONFIG.pf0_class_code_base {05} \
      CONFIG.pf0_class_code_base_mqdma {05} \
      CONFIG.pf0_class_code_interface {00} \
      CONFIG.pf0_class_code_interface_mqdma {00} \
      CONFIG.pf0_class_code_mqdma {058000} \
      CONFIG.pf0_class_code_sub {80} \
      CONFIG.pf0_class_code_sub_mqdma {80} \
      CONFIG.pf0_device_id {9048} \
      CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
      CONFIG.pl_link_cap_max_link_width $xdma_link_width \
      CONFIG.plltype {QPLL1} \
      CONFIG.runbit_fix {false} \
      CONFIG.select_quad {GTY_Quad_236} \
      CONFIG.xdma_axi_intf_mm {AXI_Stream} \
    ] $xdma_0
  } elseif { [string match "*4.1" $xdma_vlnv] } {
    set_property -dict [list \
      CONFIG.PF0_DEVICE_ID_mqdma {9048} \
      CONFIG.PF2_DEVICE_ID_mqdma {9048} \
      CONFIG.PF3_DEVICE_ID_mqdma {9048} \
      CONFIG.axi_data_width {256_bit} \
      CONFIG.axilite_master_en {true} \
      CONFIG.axilite_master_scale {Megabytes} \
      CONFIG.axilite_master_size {1} \
      CONFIG.axisten_freq $xdma_axisten_freq \
      CONFIG.bar0_indicator {1} \
      CONFIG.bar1_indicator {0} \
      CONFIG.bar_indicator {BAR_0} \
      CONFIG.cfg_mgmt_if {false} \
      CONFIG.coreclk_freq {500} \
      CONFIG.dma_reset_source_sel {Phy_Ready} \
      CONFIG.en_gt_selection {true} \
      CONFIG.mode_selection {Advanced} \
      CONFIG.pcie_blk_locn {PCIE4C_X0Y6} \
      CONFIG.pf0_bar0_64bit {false} \
      CONFIG.pf0_bar0_enabled {true} \
      CONFIG.pf0_bar0_scale {Kilobytes} \
      CONFIG.pf0_bar0_size {128} \
      CONFIG.pf0_bar0_type_mqdma {DMA} \
      CONFIG.pf0_bar1_enabled {false} \
      CONFIG.pf0_base_class_menu {Memory_controller} \
      CONFIG.pf0_base_class_menu_mqdma {Memory_controller} \
      CONFIG.pf0_class_code {058000} \
      CONFIG.pf0_class_code_base {05} \
      CONFIG.pf0_class_code_base_mqdma {05} \
      CONFIG.pf0_class_code_interface {00} \
      CONFIG.pf0_class_code_interface_mqdma {00} \
      CONFIG.pf0_class_code_mqdma {058000} \
      CONFIG.pf0_class_code_sub {80} \
      CONFIG.pf0_class_code_sub_mqdma {80} \
      CONFIG.pf0_device_id {9048} \
      CONFIG.pf0_msix_cap_pba_bir {BAR_1} \
      CONFIG.pf0_msix_cap_table_bir {BAR_1} \
      CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
      CONFIG.pl_link_cap_max_link_width $xdma_link_width \
      CONFIG.plltype {QPLL1} \
      CONFIG.select_quad {GTY_Quad_236} \
      CONFIG.xdma_axi_intf_mm {AXI_Stream} \
    ] $xdma_0
  } else {
    error "Unsupported XDMA IP version: $xdma_vlnv (only 4.1 or 4.2 supported)"
  }

  puts "INFO: wiring XDMA ST interfaces directly on axi_aclk"

  # Create interface connections
  connect_bd_intf_net -intf_net CLK_IN_D_0_1 [get_bd_intf_ports pcie_ep_gt_ref] [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_ports XDMA_AXI_LITE] [get_bd_intf_pins axi_interconnect_0/M00_AXI]
  connect_bd_intf_net -intf_net S00_AXIS_0_1 [get_bd_intf_ports S00_AXIS_0] [get_bd_intf_pins xdma_0/S_AXIS_C2H_0]
  connect_bd_intf_net -intf_net M00_AXIS_0_1 [get_bd_intf_ports M00_AXIS_0] [get_bd_intf_pins xdma_0/M_AXIS_H2C_0]
  connect_bd_intf_net -intf_net xdma_0_M_AXI_LITE [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins xdma_0/M_AXI_LITE]

  # Create port connections
  connect_bd_net -net ARESETN_1  [get_bd_pins xdma_0/axi_aresetn] \
  [get_bd_pins axi_interconnect_0/ARESETN] \
  [get_bd_pins axi_interconnect_0/S00_ARESETN]
  connect_bd_net -net M00_AXIS_ACLK_1  [get_bd_pins xdma_0/axi_aclk] \
  [get_bd_pins axi_interconnect_0/ACLK] \
  [get_bd_pins axi_interconnect_0/S00_ACLK] \
  [get_bd_ports TO_DIFFTEST_PCIE_CLK]
  connect_bd_net -net cpu_clk_1  [get_bd_ports cpu_clk] \
  [get_bd_pins axi_interconnect_0/M00_ACLK]
  connect_bd_net -net m_axis_c2h_aresetn_0_1  [get_bd_ports cpu_rstn] \
  [get_bd_pins axi_interconnect_0/M00_ARESETN]
  connect_bd_net -net pci_exp_rxn_0_1  [get_bd_ports pci_exp_rxn] \
  [get_bd_pins xdma_0/pci_exp_rxn]
  connect_bd_net -net pci_exp_rxp_0_1  [get_bd_ports pci_exp_rxp] \
  [get_bd_pins xdma_0/pci_exp_rxp]
  connect_bd_net -net sys_rst_n_0_1  [get_bd_ports pcie_ep_perstn] \
  [get_bd_pins xdma_0/sys_rst_n]
  connect_bd_net -net util_ds_buf_0_IBUF_DS_ODIV2  [get_bd_pins util_ds_buf_0/IBUF_DS_ODIV2] \
  [get_bd_pins xdma_0/sys_clk]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT  [get_bd_pins util_ds_buf_0/IBUF_OUT] \
  [get_bd_pins xdma_0/sys_clk_gt]
  connect_bd_net -net xdma_0_pci_exp_txn  [get_bd_pins xdma_0/pci_exp_txn] \
  [get_bd_ports pci_exp_txn]
  connect_bd_net -net xdma_0_pci_exp_txp  [get_bd_pins xdma_0/pci_exp_txp] \
  [get_bd_ports pci_exp_txp]
  connect_bd_net -net xdma_0_user_lnk_up  [get_bd_pins xdma_0/user_lnk_up] \
  [get_bd_ports pcie_ep_lnk_up]

  # Create address segments
  assign_bd_address -offset 0x00000000 -range 0x00100000 -target_address_space [get_bd_addr_spaces xdma_0/M_AXI_LITE] [get_bd_addr_segs XDMA_AXI_LITE/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."
