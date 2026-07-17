########################################################################
# Link synthesized partitions from leaves to the declared root module.
########################################################################

source [file normalize [file join [file dirname [info script]] defs.tcl]]
source [file normalize [file join [file dirname [info script]] sources.tcl]]

proc usage {} {
  puts "Usage:"
  puts "  vivado -mode batch -source tools/partition_synth/link.tcl -tclargs \\\\"
  puts "    --out-dir <partition_output_dir>"
  exit 1
}

proc parse_args {} {
  array set opt {--out-dir ""}
  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set key [lindex $::argv $i]
    switch -- $key {
      --out-dir {
        incr i
        if {$i >= [llength $::argv]} { usage }
        set opt($key) [lindex $::argv $i]
      }
      --help { usage }
      default {
        puts "ERROR: unknown argument '$key'"
        usage
      }
    }
  }
  if {$opt(--out-dir) eq ""} { usage }
  return [array get opt]
}

proc ps_write_blackbox_report {partition report_file} {
  set blackboxes [get_cells -hier -quiet -filter {IS_BLACKBOX}]
  set out [open $report_file w]
  puts $out "blackbox_count [llength $blackboxes]"
  foreach cell $blackboxes {
    puts $out "$cell [get_property REF_NAME $cell]"
  }
  close $out
  puts "INFO: linked partition $partition blackbox_count=[llength $blackboxes]"
  return [llength $blackboxes]
}

proc ps_export_partition {partition dcp edif report} {
  ps_require_file $dcp
  puts "INFO: exporting partition $partition: $dcp"
  open_checkpoint $dcp
  if {[ps_write_blackbox_report $partition $report] != 0} {
    error "leaf partition '$partition' still contains blackboxes"
  }
  write_edif -force $edif
  close_design
}

array set opt [parse_args]
set out_dir [file normalize $opt(--out-dir)]
set linked_dir [file normalize "$out_dir/linked"]
set linked_edif_dir [file normalize "$linked_dir/edif"]
set shell_edif_dir [file normalize "$linked_dir/shell_edif"]
file mkdir $linked_dir
file mkdir $linked_edif_dir
file mkdir $shell_edif_dir

ps_load_partitions
set part_name xcvu19p-fsva3824-2-e

foreach partition [ps_link_order] {
  set top [ps_partition_top $partition]
  set children [ps_partition_children $partition]
  set input_dcp [file normalize "$out_dir/${partition}.dcp"]
  set linked_dcp [file normalize "$linked_dir/${partition}.dcp"]
  set partition_edif_dir [file normalize "$linked_edif_dir/$partition"]
  file mkdir $partition_edif_dir
  set linked_edif [file normalize "$partition_edif_dir/${top}.edf"]
  set report [file normalize "$linked_dir/${partition}_blackboxes.rpt"]

  if {[llength $children] == 0} {
    ps_export_partition $partition $input_dcp $linked_edif $report
    continue
  }

  ps_require_file $input_dcp
  set partition_shell_dir [file normalize "$shell_edif_dir/$partition"]
  file mkdir $partition_shell_dir
  set shell_edif [file normalize "$partition_shell_dir/${top}.edf"]
  open_checkpoint $input_dcp
  write_edif -force $shell_edif
  close_design

  puts "INFO: linking partition $partition children=$children"
  create_project -in_memory -part $part_name
  set_property source_mgmt_mode None [current_project]
  read_edif $shell_edif
  foreach child $children {
    set child_top [ps_partition_top $child]
    set child_edif [file normalize "$linked_edif_dir/$child/${child_top}.edf"]
    ps_require_file $child_edif
    read_edif $child_edif
  }
  link_design -part $part_name -top $top -mode out_of_context
  if {[ps_write_blackbox_report $partition $report] != 0} {
    error "linked partition '$partition' still contains blackboxes"
  }
  report_utilization -file [file normalize "$linked_dir/${partition}_utilization.rpt"]
  write_checkpoint -force $linked_dcp
  write_edif -force $linked_edif
  close_design
  close_project
}

set root [ps_root_partition]
set root_dcp [file normalize "$linked_dir/${root}.dcp"]
if {![file isfile $root_dcp]} {
  set root_dcp [file normalize "$out_dir/${root}.dcp"]
}
set marker [open [file normalize "$linked_dir/root.txt"] w]
puts $marker "partition=$root"
puts $marker "module=[ps_partition_top $root]"
puts $marker "dcp=$root_dcp"
puts $marker "edif=[file normalize \"$linked_edif_dir/$root/[ps_partition_top $root].edf\"]"
close $marker
puts "INFO: partition link complete: root=$root module=[ps_partition_top $root]"
