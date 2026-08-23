proc require_single {objs label} {
  if {[llength $objs] != 1} {
    puts stderr "ERROR: expected exactly one object for $label, got [llength $objs]"
    exit 2
  }
  return [lindex $objs 0]
}

proc try_set_property {prop value obj} {
  if {[catch {set_property $prop $value $obj} err]} {
    puts "WARN: skip set_property $prop=$value on $obj : $err"
  }
}

proc find_hw_ila {hw_device cell_name} {
  return [lindex [get_hw_ilas -of_objects $hw_device -filter "CELL_NAME =~ $cell_name"] 0]
}

proc find_hw_probe {hw_ila probe_name} {
  set exact_match [get_hw_probes -of_objects $hw_ila -filter "NAME == $probe_name"]
  if {[llength $exact_match] > 0} {
    return [lindex $exact_match 0]
  }

  set prefix_match [get_hw_probes -of_objects $hw_ila -filter "NAME =~ ${probe_name}*"]
  if {[llength $prefix_match] > 0} {
    return [lindex $prefix_match 0]
  }

  return ""
}

proc configure_hw_ila {hw_ila probe_name compare_value tag} {
  reset_hw_ila $hw_ila

  set depth ""
  if {[catch {set depth [get_property CONTROL.DATA_DEPTH $hw_ila]}]} {
    set depth ""
  }
  if {$depth eq ""} {
    set depth 1024
  }

  try_set_property CONTROL.DATA_DEPTH $depth $hw_ila
  try_set_property CONTROL.WINDOW_COUNT 1 $hw_ila
  try_set_property CONTROL.TRIGGER_POSITION [expr {$depth - 1}] $hw_ila
  try_set_property CONTROL.TRIGGER_MODE BASIC_ONLY $hw_ila
  try_set_property CONTROL.TRIGGER_CONDITION AND $hw_ila
  try_set_property CONTROL.CAPTURE_MODE ALWAYS $hw_ila

  set hw_probe [find_hw_probe $hw_ila $probe_name]
  if {$hw_probe eq ""} {
    return -code error "probe $probe_name not found for $tag"
  }
  set_property TRIGGER_COMPARE_VALUE $compare_value $hw_probe
  puts "CONFIGURED_ILA=$tag PROBE=$probe_name VALUE=$compare_value"
}

if {[llength $argv] < 2} {
  puts stderr "Usage: vivado -mode tcl -source dump_ila.tcl -tclargs <ltx_path> <out_dir> ?timeout_min?"
  exit 1
}

set ltx_path [lindex $argv 0]
set out_dir [lindex $argv 1]
set timeout_min 2
if {[llength $argv] >= 3} {
  set timeout_min [lindex $argv 2]
}

file mkdir $out_dir

open_hw_manager
connect_hw_server
open_hw_target

set hw_device [require_single [get_hw_devices *] "hw_device"]
current_hw_device $hw_device
set_property PROBES.FILE $ltx_path $hw_device
set_property FULL_PROBES.FILE $ltx_path $hw_device
refresh_hw_device $hw_device

set hw_ila [find_hw_ila $hw_device u_ila_xdma_ctrl]
if {$hw_ila eq ""} {
  puts stderr "ERROR: required ILA u_ila_xdma_ctrl not found on hardware"
  exit 3
}

if {[catch {configure_hw_ila $hw_ila core_def/io_host_ila_trigger {eq1'b1} u_ila_xdma_ctrl} err]} {
  puts stderr "ERROR: failed to configure u_ila_xdma_ctrl : $err"
  exit 3
}

if {[catch {run_hw_ila $hw_ila} err]} {
  puts stderr "ERROR: failed to arm u_ila_xdma_ctrl : $err"
  exit 4
}

puts "ARMED_ILA=u_ila_xdma_ctrl"

if {[catch {wait_on_hw_ila -timeout $timeout_min $hw_ila} err]} {
  puts stderr "ERROR: wait_on_hw_ila failed: $err"
  exit 6
}

set data_obj [upload_hw_ila_data $hw_ila]
write_hw_ila_data -force "${out_dir}/u_ila_xdma_ctrl.ila" $data_obj
write_hw_ila_data -force -csv_file "${out_dir}/u_ila_xdma_ctrl.csv" $data_obj
write_hw_ila_data -force -vcd_file "${out_dir}/u_ila_xdma_ctrl.vcd" $data_obj
puts "DUMP_DONE=$out_dir"
exit
