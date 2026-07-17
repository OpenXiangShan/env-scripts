########################################################################
# Save a Vivado checkpoint from an existing FpgaDiff run.
#
# Usage:
#   vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/write_run_checkpoint.tcl \
#     -tclargs <project.xpr> <run-name> <out.dcp> [normal|incremental_synth]
########################################################################

proc usage {} {
  puts stderr "USAGE: vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/write_run_checkpoint.tcl -tclargs <project.xpr> <run-name> <out.dcp> ?normal|incremental_synth?"
}

source [file join [file dirname [info script]] vivado_common.tcl]

if {[llength $::argv] < 3 || [llength $::argv] > 4} {
  usage
  exit 2
}

set proj_path [file normalize [lindex $::argv 0]]
set run_name [string trim [lindex $::argv 1]]
set out_dcp [file normalize [lindex $::argv 2]]
set checkpoint_mode "normal"
if {[llength $::argv] >= 4 && [string trim [lindex $::argv 3]] ne ""} {
  set checkpoint_mode [string trim [lindex $::argv 3]]
}

flow_require_file $proj_path "project"
if {$run_name eq ""} {
  puts stderr "ERROR: run-name is empty"
  exit 1
}
flow_require_choice $checkpoint_mode {normal incremental_synth} "checkpoint mode"

file mkdir [file dirname $out_dcp]

puts "INFO: Opening project: $proj_path"
open_project $proj_path

set run_obj [get_runs -quiet $run_name]
if {[llength $run_obj] == 0} {
  puts stderr "ERROR: run not found: $run_name"
  exit 1
}

puts "INFO: Opening run: $run_name"
open_run $run_name
if {$checkpoint_mode eq "incremental_synth"} {
  puts "INFO: Writing incremental synthesis checkpoint"
  flow_write_checkpoint_with_mode $out_dcp incremental_synth
} else {
  flow_write_checkpoint_with_mode $out_dcp normal 0
}
puts "INFO: Wrote checkpoint: $out_dcp"
