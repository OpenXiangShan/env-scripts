########################################################################
# Synthesize the FPGA top shell and insert the linked root partition DCP.
########################################################################

source [file normalize [file join [file dirname [info script]] sources.tcl]]

proc usage {} {
  puts "Usage:"
  puts {  vivado -mode batch -source tools/partition_synth/project_link.tcl -tclargs}
  puts {    --project <project.xpr> --out-dir <partition_output_dir> [--jobs <n>]}
  exit 1
}

proc parse_args {} {
  array set opt {--project "" --out-dir "" --jobs ""}
  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set key [lindex $::argv $i]
    switch -- $key {
      --project -
      --out-dir -
      --jobs {
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
  if {$opt(--project) eq "" || $opt(--out-dir) eq ""} { usage }
  if {$opt(--jobs) ne "" &&
      (![string is integer -strict $opt(--jobs)] || $opt(--jobs) < 1)} {
    error "--jobs must be a positive integer"
  }
  return [array get opt]
}

proc default_jobs {} {
  set threads 1
  if {![catch {exec nproc} output] &&
      [scan [string trim $output] "%d" threads] != 1} {
    set threads 1
  }
  return [expr {max(1, int(ceil($threads / 2.0)))}]
}

proc ps_read_link_marker {path} {
  set marker [open $path r]
  array set data {}
  while {[gets $marker line] >= 0} {
    if {$line eq ""} {
      continue
    }
    if {![regexp {^([^=]+)=(.*)$} $line -> key value]} {
      error "invalid link marker entry: $line"
    }
    set data($key) $value
  }
  close $marker
  foreach key {partition module dcp} {
    if {![info exists data($key)] || $data($key) eq ""} {
      error "link marker is missing '$key': $path"
    }
  }
  return [array get data]
}

array set opt [parse_args]
set project [file normalize $opt(--project)]
set out_dir [file normalize $opt(--out-dir)]
set linked_dir [file normalize "$out_dir/linked"]
set marker [file normalize "$linked_dir/root.txt"]
ps_require_file $project
ps_require_file $marker
array set root_info [ps_read_link_marker $marker]
set root_module $root_info(module)
set root_dcp [file normalize $root_info(dcp)]
ps_require_file $root_dcp

open_project $project
set project_top [get_property TOP [get_filesets sources_1]]
if {$project_top eq ""} {
  error "project sources_1 has no top module"
}
set synth_runs [get_runs synth_1]
if {[llength $synth_runs] != 1} {
  error "project must contain one synth_1 run"
}
set synth_run [lindex $synth_runs 0]
set synth_run_dir [file normalize [get_property DIRECTORY $synth_run]]
set final_dcp [file normalize "$synth_run_dir/${project_top}.dcp"]
set utilization_rpt [file normalize "$synth_run_dir/${project_top}_utilization_synth.rpt"]
set utilization_pb [file normalize "$synth_run_dir/${project_top}_utilization_synth.pb"]
set clocks_rpt [file normalize "$linked_dir/${project_top}_clocks.rpt"]
set clock_interaction_rpt [file normalize "$linked_dir/${project_top}_clock_interaction.rpt"]
set cdc_rpt [file normalize "$linked_dir/${project_top}_cdc.rpt"]
set check_timing_rpt [file normalize "$linked_dir/${project_top}_check_timing.rpt"]
set timing_summary_rpt [file normalize "$linked_dir/${project_top}_timing_summary_synth.rpt"]

ps_prepare_project_shell $root_module $out_dir
set_property INCREMENTAL_CHECKPOINT {} $synth_run
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $synth_run
reset_run $synth_run

set jobs $opt(--jobs)
if {$jobs eq ""} { set jobs [default_jobs] }
puts "INFO: launching top shell synth_1 with -jobs $jobs"
launch_runs $synth_run -jobs $jobs
wait_on_run $synth_run

set status [get_property STATUS $synth_run]
if {![string match "synth_design Complete*" $status]} {
  error "top shell synthesis failed with status: $status"
}
ps_require_file $final_dcp
close_project

open_checkpoint $final_dcp
set root_cells [get_cells -hier -quiet -filter "REF_NAME == $root_module && IS_BLACKBOX"]
if {[llength $root_cells] != 1} {
  error "top shell must contain one $root_module blackbox, found [llength $root_cells]"
}
set shell_blackbox_count [llength [get_cells -hier -quiet -filter {IS_BLACKBOX}]]
puts "INFO: linking root checkpoint $root_dcp at [lindex $root_cells 0]"
read_checkpoint -cell [lindex $root_cells 0] $root_dcp

set report_file [file normalize "$linked_dir/${project_top}_blackboxes.rpt"]
set report [open $report_file w]
set blackboxes [get_cells -hier -quiet -filter {IS_BLACKBOX}]
puts $report "blackbox_count [llength $blackboxes]"
foreach cell $blackboxes {
  puts $report "$cell [get_property REF_NAME $cell]"
}
close $report
set unresolved_root [get_cells -hier -quiet -filter "REF_NAME == $root_module && IS_BLACKBOX"]
if {[llength $unresolved_root] != 0} {
  error "root module $root_module remains a blackbox after project link"
}
if {[llength $blackboxes] != ($shell_blackbox_count - 1)} {
  error "project link changed the OOC IP blackbox count; see $report_file"
}

set final_tmp "${final_dcp}.partition_linked"
set utilization_rpt_tmp "${utilization_rpt}.partition_linked"
set utilization_pb_tmp "${utilization_pb}.partition_linked"
write_checkpoint -force $final_tmp
report_utilization -file $utilization_rpt_tmp -pb $utilization_pb_tmp
report_clocks -file $clocks_rpt
report_clock_interaction -file $clock_interaction_rpt
report_cdc -file $cdc_rpt
check_timing -file $check_timing_rpt
report_timing_summary -file $timing_summary_rpt
close_design
file rename -force $final_tmp $final_dcp
file rename -force $utilization_rpt_tmp $utilization_rpt
file rename -force $utilization_pb_tmp $utilization_pb

set final_marker [open [file normalize "$linked_dir/final.txt"] w]
puts $final_marker "project=$project"
puts $final_marker "top=$project_top"
puts $final_marker "dcp=$final_dcp"
puts $final_marker "blackbox_report=$report_file"
puts $final_marker "clocks_report=$clocks_rpt"
puts $final_marker "clock_interaction_report=$clock_interaction_rpt"
puts $final_marker "cdc_report=$cdc_rpt"
puts $final_marker "check_timing_report=$check_timing_rpt"
puts $final_marker "timing_summary_report=$timing_summary_rpt"
close $final_marker
puts "INFO: project link complete: $final_dcp"
