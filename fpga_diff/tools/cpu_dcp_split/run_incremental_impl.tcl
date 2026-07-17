########################################################################
# FpgaDiff Vivado incremental implementation helper.
#
# Expected use:
#   vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/run_incremental_impl.tcl \
#     -tclargs <project.xpr> <reference-routed.dcp> [impl-run] [jobs] \
#              [reference-synth.dcp] [synth-incremental-mode] [route|bitstream] \
#              [Default|RuntimeOptimized]
#
# The script opens an existing fpga_diff project, points the implementation
# run at checkpoints from a baseline build, resets the target runs, launches
# synthesis and implementation, and emits reuse/timing/util reports.
########################################################################

proc usage {} {
  puts stderr "USAGE: vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/run_incremental_impl.tcl -tclargs <project.xpr> <reference-routed.dcp> ?impl_run? ?jobs? ?reference_synth.dcp? ?synth_incremental_mode? ?route|bitstream? ?Default|RuntimeOptimized?"
}

source [file join [file dirname [info script]] vivado_common.tcl]

if {[llength $::argv] < 2 || [llength $::argv] > 8} {
  usage
  exit 2
}

set proj_path [file normalize [lindex $::argv 0]]
set reference_dcp [file normalize [lindex $::argv 1]]
set impl_run [expr {[llength $::argv] >= 3 && [string trim [lindex $::argv 2]] ne "" ? [lindex $::argv 2] : "impl_1"}]
set jobs_arg [expr {[llength $::argv] >= 4 ? [string trim [lindex $::argv 3]] : ""}]
set reference_synth_dcp ""
if {[llength $::argv] >= 5 && [string trim [lindex $::argv 4]] ne ""} {
  set reference_synth_dcp [file normalize [lindex $::argv 4]]
}
set synth_incremental_mode "default"
if {[llength $::argv] >= 6 && [string trim [lindex $::argv 5]] ne ""} {
  set synth_incremental_mode [string trim [lindex $::argv 5]]
}
set final_step "bitstream"
if {[llength $::argv] >= 7 && [string trim [lindex $::argv 6]] ne ""} {
  set final_step [string trim [lindex $::argv 6]]
}
set impl_directive "RuntimeOptimized"
if {[llength $::argv] >= 8 && [string trim [lindex $::argv 7]] ne ""} {
  set impl_directive [string trim [lindex $::argv 7]]
}

flow_require_file $proj_path "project"
flow_require_file $reference_dcp "reference checkpoint"
if {$reference_synth_dcp ne ""} {
  flow_require_file $reference_synth_dcp "reference synthesis checkpoint"
}
flow_require_positive_int $jobs_arg "jobs"
flow_require_choice $synth_incremental_mode {quick default aggressive off} "synth_incremental_mode"
flow_require_choice $final_step {route bitstream} "final step"
flow_require_choice $impl_directive {Default RuntimeOptimized} "implementation directive"
set jobs [flow_default_jobs $jobs_arg]

puts "INFO: Opening project: $proj_path"
open_project $proj_path

set impl_obj [get_runs -quiet $impl_run]
if {[llength $impl_obj] == 0} {
  puts stderr "ERROR: implementation run not found: $impl_run"
  exit 1
}
set impl_obj [lindex $impl_obj 0]
set synth_obj [get_runs -quiet [get_property PARENT $impl_obj]]
if {[llength $synth_obj] == 0} {
  puts stderr "ERROR: synthesis parent run not found for $impl_run"
  exit 1
}
set synth_obj [lindex $synth_obj 0]

puts "INFO: Setting incremental checkpoint on $impl_run: $reference_dcp"
flow_ensure_utils_file $reference_dcp
flow_set_optional_property AUTO_INCREMENTAL_CHECKPOINT 0 $impl_obj
flow_set_optional_property INCREMENTAL_CHECKPOINT.DIRECTIVE $impl_directive $impl_obj
set_property INCREMENTAL_CHECKPOINT $reference_dcp $impl_obj

set report_dir [file normalize [file join [get_property DIRECTORY [current_project]] incremental-reports $impl_run]]
file mkdir $report_dir

set setup_report [open [file join $report_dir incremental_setup.txt] w]
puts $setup_report "project=$proj_path"
puts $setup_report "impl_run=$impl_run"
puts $setup_report "reference_impl_dcp=$reference_dcp"
puts $setup_report "reference_synth_dcp=$reference_synth_dcp"
puts $setup_report "synth_incremental_mode=$synth_incremental_mode"
puts $setup_report "final_step=$final_step"
puts $setup_report "implementation_directive=$impl_directive"
puts $setup_report "jobs=$jobs"

if {$reference_synth_dcp ne ""} {
  puts "INFO: Setting synthesis incremental checkpoint on [get_property NAME $synth_obj]: $reference_synth_dcp"
  flow_ensure_utils_file $reference_synth_dcp
  set synth_checkpoint_ok 1
  if {$synth_incremental_mode eq "off"} {
    set synth_checkpoint_ok 0
    puts "INFO: Synthesis incremental mode is off; reference synthesis checkpoint will not be used."
  } elseif {![flow_set_optional_property INCREMENTAL_CHECKPOINT $reference_synth_dcp $synth_obj]} {
    set synth_checkpoint_ok 0
  }
  set synth_mode_ok 0
  if {$synth_incremental_mode ne "off"} {
    set synth_mode_ok [flow_set_optional_property STEPS.SYNTH_DESIGN.ARGS.INCREMENTAL_MODE $synth_incremental_mode $synth_obj]
  }
  set write_inc_synth_ok [flow_set_optional_property WRITE_INCREMENTAL_SYNTH_CHECKPOINT 1 $synth_obj]
  puts $setup_report "synthesis_incremental_checkpoint_set=$synth_checkpoint_ok"
  puts $setup_report "synthesis_incremental_mode_property_set=$synth_mode_ok"
  puts $setup_report "write_incremental_synth_checkpoint_property_set=$write_inc_synth_ok"
  puts $setup_report "synthesis_incremental_property_set=$synth_checkpoint_ok"
} else {
  puts "INFO: No synthesis checkpoint supplied; synthesis will run normally."
  puts $setup_report "synthesis_incremental_checkpoint_set=0"
  puts $setup_report "synthesis_incremental_mode_property_set=0"
  puts $setup_report "write_incremental_synth_checkpoint_property_set=0"
  puts $setup_report "synthesis_incremental_property_set=0"
}
close $setup_report

puts "INFO: Resetting runs: [get_property NAME $synth_obj], $impl_run"
reset_run $synth_obj
reset_run $impl_obj

puts "INFO: Launching synthesis with -jobs $jobs"
launch_runs $synth_obj -jobs $jobs
wait_on_run $synth_obj
set synth_status [get_property STATUS $synth_obj]
puts "INFO: Synthesis status: $synth_status"
if {![string match "*Complete*" $synth_status]} {
  puts stderr "ERROR: synthesis did not complete"
  exit 1
}

set vivado_final_step [expr {$final_step eq "route" ? "route_design" : "write_bitstream"}]
puts "INFO: Launching incremental implementation to $vivado_final_step with directive $impl_directive and -jobs $jobs"
launch_runs $impl_obj -to_step $vivado_final_step -jobs $jobs
wait_on_run $impl_obj
set impl_status [get_property STATUS $impl_obj]
puts "INFO: Implementation status: $impl_status"
if {![string match "*Complete*" $impl_status]} {
  puts stderr "ERROR: implementation did not complete"
  exit 1
}

puts "INFO: Opening implemented design for reports"
open_run $impl_run -name implemented_design

set reuse_report [file join $report_dir report_incremental_reuse.rpt]
if {![catch {report_incremental_reuse -file $reuse_report} err]} {
  puts "INFO: Wrote $reuse_report"
} else {
  puts "WARNING: report_incremental_reuse failed: $err"
}

report_timing_summary -file [file join $report_dir timing_summary.rpt]
report_utilization -file [file join $report_dir utilization.rpt]
report_route_status -file [file join $report_dir route_status.rpt]

set post_impl_dcp [file join $report_dir post_route.dcp]
write_checkpoint -force $post_impl_dcp
puts "INFO: Wrote post-route checkpoint: $post_impl_dcp"
puts "INFO: Reports are under: $report_dir"
