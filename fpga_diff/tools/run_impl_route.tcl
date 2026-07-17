########################################################################
# Open a project from -tclargs and launch/wait on impl_1 through route_design.
#
# Usage:
#   vivado -mode batch -source tools/run_impl_route.tcl \
#     -tclargs <project.xpr> [impl-run] [jobs]
########################################################################

proc usage {} {
  puts stderr "USAGE: vivado -mode batch -source tools/run_impl_route.tcl -tclargs <project.xpr> ?impl-run? ?jobs?"
}

if {[llength $::argv] < 1 || [llength $::argv] > 3} {
  usage
  exit 2
}

set proj_path [file normalize [lindex $::argv 0]]
set impl_run_name "impl_1"
if {[llength $::argv] >= 2 && [string trim [lindex $::argv 1]] ne ""} {
  set impl_run_name [string trim [lindex $::argv 1]]
}
set requested_jobs ""
if {[llength $::argv] >= 3 && [string trim [lindex $::argv 2]] ne ""} {
  set requested_jobs [string trim [lindex $::argv 2]]
} elseif {[info exists ::env(VIVADO_JOBS)] && [string trim $::env(VIVADO_JOBS)] ne ""} {
  set requested_jobs [string trim $::env(VIVADO_JOBS)]
}

if {![file exists $proj_path]} {
  puts stderr "ERROR: .xpr not found: $proj_path"
  exit 1
}
if {$requested_jobs ne "" && (![string is integer -strict $requested_jobs] || $requested_jobs < 1)} {
  puts stderr "ERROR: VIVADO_JOBS must be a positive integer, got '$requested_jobs'"
  exit 1
}

set jobs 1
if {$requested_jobs ne ""} {
  set jobs $requested_jobs
} elseif {![catch {exec nproc} nproc_out]} {
  set nproc_trim [string trim $nproc_out]
  if {[scan $nproc_trim "%d" jobs] != 1 || $jobs < 1} {
    set jobs 1
  } else {
    set jobs [expr {int(ceil($jobs / 2.0))}]
  }
}
if {$jobs < 1} {
  set jobs 1
}

puts "INFO: Opening project: $proj_path"
open_project $proj_path

set impl_runs [get_runs -quiet $impl_run_name]
if {[llength $impl_runs] == 0} {
  puts stderr "ERROR: implementation run not found: $impl_run_name"
  exit 1
}
set impl_run [lindex $impl_runs 0]
set status [get_property STATUS $impl_run]
puts "INFO: $impl_run_name status: $status"

if {![string match "route_design Complete*" $status] && ![string match "write_bitstream Complete*" $status]} {
  puts "INFO: Launching $impl_run_name to route_design with -jobs $jobs"
  launch_runs $impl_run -to_step route_design -jobs $jobs
  wait_on_run $impl_run
  set status [get_property STATUS $impl_run]
} else {
  puts "INFO: $impl_run_name already routed."
}

if {![string match "route_design Complete*" $status] && ![string match "write_bitstream Complete*" $status]} {
  puts stderr "ERROR: $impl_run_name did not route successfully: $status"
  exit 1
}

puts "INFO: Route flow finished."
