########################################################################
# Link OOC partition checkpoints into a complete root-partition DCP.
########################################################################

source [file normalize [file join [file dirname [info script]] defs.tcl]]
source [file normalize [file join [file dirname [info script]] sources.tcl]]

proc usage {} {
  puts "Usage:"
  puts {  vivado -mode batch -source tools/partition_synth/link.tcl -tclargs}
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

proc ps_link_visit {partition} {
  global ps_link_children ps_link_order ps_link_visit_state

  if {[info exists ps_link_visit_state($partition)]} {
    if {$ps_link_visit_state($partition) eq "visiting"} {
      error "cycle detected at partition '$partition'"
    }
    return
  }

  set ps_link_visit_state($partition) visiting
  foreach child $ps_link_children($partition) {
    ps_link_visit $child
  }
  set ps_link_visit_state($partition) done
  lappend ps_link_order $partition
}

proc ps_build_link_graph {} {
  global ps_partitions ps_link_children ps_link_order ps_link_visit_state

  array set top_to_partition {}
  foreach partition $ps_partitions {
    set top [ps_partition_top $partition]
    if {[info exists top_to_partition($top)]} {
      error "module '$top' is the top of more than one partition"
    }
    set top_to_partition($top) $partition
  }

  unset -nocomplain ps_link_children ps_link_order ps_link_visit_state
  array set ps_link_children {}
  array set referenced {}
  foreach partition $ps_partitions {
    set children {}
    foreach module [ps_partition_blackboxes $partition] {
      if {![info exists top_to_partition($module)]} {
        error "partition '$partition' has no child partition for module '$module'"
      }
      set child $top_to_partition($module)
      if {$child eq $partition} {
        error "partition '$partition' cannot contain itself"
      }
      lappend children $child
      set referenced($child) 1
    }
    set ps_link_children($partition) $children
  }

  set roots {}
  foreach partition $ps_partitions {
    if {![info exists referenced($partition)]} {
      lappend roots $partition
    }
  }
  if {[llength $roots] != 1} {
    error "partition link requires one root, found: $roots"
  }

  set root [lindex $roots 0]
  set ps_link_order {}
  array set ps_link_visit_state {}
  ps_link_visit $root
  if {[llength $ps_link_order] != [llength $ps_partitions]} {
    error "some partitions are disconnected from root '$root'"
  }
  return [list $root $ps_link_order]
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
lassign [ps_build_link_graph] root link_order
set part_name xcvu19p-fsva3824-2-e

foreach partition $link_order {
  set top [ps_partition_top $partition]
  set children $ps_link_children($partition)
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

set root_top [ps_partition_top $root]
set root_dcp [file normalize "$linked_dir/${root}.dcp"]
if {![file isfile $root_dcp]} {
  set root_dcp [file normalize "$out_dir/${root}.dcp"]
}
set root_edif [file normalize "$linked_edif_dir/$root/${root_top}.edf"]
set marker [open [file normalize "$linked_dir/root.txt"] w]
puts $marker "partition=$root"
puts $marker "module=$root_top"
puts $marker "dcp=$root_dcp"
puts $marker "edif=$root_edif"
close $marker
puts "INFO: partition link complete: root=$root module=$root_top"
