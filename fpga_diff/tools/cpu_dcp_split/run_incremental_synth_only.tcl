########################################################################
# Run only synthesis with a Vivado incremental-synthesis checkpoint.
#
# Usage:
#   vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/run_incremental_synth_only.tcl \
#     -tclargs <project.xpr> <reference-synth.dcp> [synth-run] [jobs] [mode]
########################################################################

proc usage {} {
  puts stderr "USAGE: vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/run_incremental_synth_only.tcl -tclargs <project.xpr> <reference-synth.dcp> ?synth-run? ?jobs? ?quick|default|aggressive|off?"
}

source [file join [file dirname [info script]] vivado_common.tcl]

if {[llength $::argv] < 2 || [llength $::argv] > 5} {
  usage
  exit 2
}

set proj_path [file normalize [lindex $::argv 0]]
set reference_synth_dcp [file normalize [lindex $::argv 1]]
set synth_run_name "synth_1"
if {[llength $::argv] >= 3 && [string trim [lindex $::argv 2]] ne ""} {
  set synth_run_name [string trim [lindex $::argv 2]]
}
set jobs_arg ""
if {[llength $::argv] >= 4 && [string trim [lindex $::argv 3]] ne ""} {
  set jobs_arg [string trim [lindex $::argv 3]]
}
set synth_incremental_mode "default"
if {[llength $::argv] >= 5 && [string trim [lindex $::argv 4]] ne ""} {
  set synth_incremental_mode [string trim [lindex $::argv 4]]
}

flow_require_file $proj_path "project"
flow_require_file $reference_synth_dcp "reference synthesis checkpoint"
flow_require_positive_int $jobs_arg "jobs"
flow_require_choice $synth_incremental_mode {quick default aggressive off} "synth_incremental_mode"
set jobs [flow_default_jobs $jobs_arg]

puts "INFO: Opening project: $proj_path"
open_project $proj_path

set synth_obj [get_runs -quiet $synth_run_name]
if {[llength $synth_obj] == 0} {
  puts stderr "ERROR: synthesis run not found: $synth_run_name"
  exit 1
}
set synth_obj [lindex $synth_obj 0]

set utils_ok 0
set synth_checkpoint_ok 0
set synth_mode_ok 0
if {$synth_incremental_mode eq "off"} {
  puts "INFO: Synthesis incremental mode is off; reference synthesis checkpoint will not be used."
} else {
  puts "INFO: Setting synthesis incremental checkpoint on $synth_run_name: $reference_synth_dcp"
  set utils_ok [flow_ensure_utils_file $reference_synth_dcp]
  set synth_checkpoint_ok [flow_set_optional_property INCREMENTAL_CHECKPOINT $reference_synth_dcp $synth_obj]
  set synth_mode_ok [flow_set_optional_property STEPS.SYNTH_DESIGN.ARGS.INCREMENTAL_MODE $synth_incremental_mode $synth_obj]
}
set write_inc_synth_ok [flow_set_optional_property WRITE_INCREMENTAL_SYNTH_CHECKPOINT 1 $synth_obj]

set report_dir [file normalize [file join [get_property DIRECTORY [current_project]] incremental-synth-only $synth_run_name]]
file mkdir $report_dir
set setup_report [open [file join $report_dir incremental_synth_setup.txt] w]
puts $setup_report "project=$proj_path"
puts $setup_report "synth_run=$synth_run_name"
puts $setup_report "reference_synth_dcp=$reference_synth_dcp"
puts $setup_report "synth_incremental_mode=$synth_incremental_mode"
puts $setup_report "utils_file_set=$utils_ok"
puts $setup_report "synthesis_incremental_checkpoint_set=$synth_checkpoint_ok"
puts $setup_report "synthesis_incremental_mode_property_set=$synth_mode_ok"
puts $setup_report "write_incremental_synth_checkpoint_property_set=$write_inc_synth_ok"
puts $setup_report "jobs=$jobs"
close $setup_report

if {$synth_incremental_mode ne "off" && !$synth_checkpoint_ok} {
  puts stderr "ERROR: could not set synthesis incremental checkpoint"
  exit 1
}

puts "INFO: Resetting synthesis run: $synth_run_name"
reset_run $synth_obj
puts "INFO: Launching $synth_run_name with -jobs $jobs"
launch_runs $synth_obj -jobs $jobs
wait_on_run $synth_obj

set status [get_property STATUS $synth_obj]
puts "INFO: $synth_run_name status: $status"
if {![string match "*Complete*" $status]} {
  puts stderr "ERROR: synthesis did not complete"
  exit 1
}

puts "INFO: Incremental synthesis-only run completed."
puts "INFO: Setup report: [file join $report_dir incremental_synth_setup.txt]"
