########################################################################
# open .xpr from -tclargs then launch and wait on impl_1
########################################################################

proc ensure_open_project {} {
	# If project is already open, return
	if {![catch {current_project}]} { return }

	# Get .xpr from argv
	if {[info exists ::argv] && [llength $::argv] > 0} {
		set proj_path [lindex $::argv 0]
		if {[file exists $proj_path]} {
			puts "INFO: Opening project: $proj_path"
			open_project $proj_path
			return
		} else {
			puts "ERROR: .xpr not found: $proj_path"
			exit 1
		}
	}

	puts "ERROR: No project path passed. Use: make bitstream PRJ=/path/to/proj.xpr"
	exit 1
}

ensure_open_project

set impl_runs [get_runs impl_1]
if {[llength $impl_runs] == 0} {
	puts "ERROR: Run impl_1 not found in project. Please ensure runs are created."
	exit 1
}
set impl_run [lindex $impl_runs 0]
set status [get_property STATUS $impl_run]
puts "INFO: impl_1 status: $status"

set requested_jobs ""
if {[info exists ::argv] && [llength $::argv] > 2} {
	set requested_jobs [string trim [lindex $::argv 2]]
}
if {$requested_jobs eq "" && [info exists ::env(VIVADO_JOBS)]} {
	set requested_jobs [string trim $::env(VIVADO_JOBS)]
}

if {![string match "write_bitstream Complete*" $status]} {
	# Determine parallel jobs as half of system threads (min 1)
	set sys_threads 1
	if {![catch {exec nproc} _nproc_out]} {
		set _nproc_trim [string trim $_nproc_out]
		if {[scan $_nproc_trim "%d" sys_threads] != 1} { set sys_threads 1 }
	}
	set jobs [expr {int(ceil($sys_threads/2.0))}]
	if {$requested_jobs ne ""} {
		if {![string is integer -strict $requested_jobs] || $requested_jobs < 1} {
			puts "ERROR: VIVADO_JOBS must be a positive integer, got '$requested_jobs'"
			exit 1
		}
		set jobs $requested_jobs
	}
	if {$jobs < 1} { set jobs 1 }
	puts "INFO: Launching impl_1 to write_bitstream with -jobs $jobs (system threads: $sys_threads)"
	launch_runs impl_1 -to_step write_bitstream -jobs $jobs
	wait_on_run $impl_run
} else {
	puts "INFO: impl_1 already complete."
}

puts "INFO: Bitstream generation flow finished."
