########################################################################
# Synthesize the FPGA top shell and link the complete root partition into it.
########################################################################

source [file normalize [file join [file dirname [info script]] defs.tcl]]
source [file normalize [file join [file dirname [info script]] sources.tcl]]

proc usage {} {
  puts "Usage:"
  puts "  vivado -mode batch -source tools/partition_synth/project_link.tcl -tclargs"
  puts {    --project <project.xpr> --out-dir <partition_output_dir> [--jobs <n>]}
  puts {    [--reuse-shell-dcp <fpga_top.dcp>]}
  exit 1
}

proc parse_args {} {
  array set opt {--project "" --out-dir "" --jobs "" --reuse-shell-dcp ""}
  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set key [lindex $::argv $i]
    switch -- $key {
      --project -
      --out-dir -
      --jobs -
      --reuse-shell-dcp {
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

array set opt [parse_args]
set project [file normalize $opt(--project)]
set out_dir [file normalize $opt(--out-dir)]
ps_require_file $project
if {$opt(--reuse-shell-dcp) ne ""} {
  set opt(--reuse-shell-dcp) [file normalize $opt(--reuse-shell-dcp)]
  ps_require_file $opt(--reuse-shell-dcp)
}
ps_load_partitions

set root [ps_root_partition]
set root_module [ps_partition_top $root]
set linked_dir [file normalize "$out_dir/linked"]
set project_shell_dir [file normalize "$linked_dir/project_shell"]
set root_dcp [file normalize "$linked_dir/${root}.dcp"]
if {![file isfile $root_dcp]} {
  set root_dcp [file normalize "$out_dir/${root}.dcp"]
}
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

if {$opt(--reuse-shell-dcp) eq ""} {
  ps_prepare_project_shell $root_module $out_dir
  # Do not reuse a previous monolithic checkpoint for the generated shell.
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
} else {
  puts "INFO: reusing top shell checkpoint $opt(--reuse-shell-dcp)"
}

close_project

file mkdir $project_shell_dir
if {$opt(--reuse-shell-dcp) eq ""} {
  set shell_dcp [file normalize "$project_shell_dir/${project_top}.dcp"]
  file copy -force $final_dcp $shell_dcp
} else {
  set shell_dcp $opt(--reuse-shell-dcp)
}
open_checkpoint $shell_dcp
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
# Project-managed OOC IPs remain blackboxes in a synthesis DCP. Only the
# partition root is expected to disappear after the checkpoint is inserted.
if {[llength $blackboxes] != ($shell_blackbox_count - 1)} {
  error "project link changed the OOC IP blackbox count; see $report_file"
}

set final_tmp "${final_dcp}.partition_linked"
set utilization_rpt_tmp "${utilization_rpt}.partition_linked"
set utilization_pb_tmp "${utilization_pb}.partition_linked"
write_checkpoint -force $final_tmp
report_utilization -file $utilization_rpt_tmp -pb $utilization_pb_tmp
close_design
file rename -force $final_tmp $final_dcp
file rename -force $utilization_rpt_tmp $utilization_rpt
file rename -force $utilization_pb_tmp $utilization_pb

open_project $project
set impl_run [get_runs -quiet impl_1]
if {[llength $impl_run] > 0} {
  reset_run $impl_run
  puts "INFO: reset impl_1 after replacing the synthesis checkpoint"
}
close_project

set marker [open [file normalize "$linked_dir/final.txt"] w]
puts $marker "project=$project"
puts $marker "top=$project_top"
puts $marker "dcp=$final_dcp"
puts $marker "blackbox_report=$report_file"
close $marker
puts "INFO: project link complete: $final_dcp"
