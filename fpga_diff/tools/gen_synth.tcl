########################################################################
# Run synthesis only: open project from -tclargs and launch/wait on synth_1
########################################################################

proc ensure_open_project {} {
    # If a project is already open, just return
    if {![catch {current_project}]} { return }

    # Expect first -tclargs as the .xpr path
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

    puts "ERROR: No project path passed. Use: make synth PRJ=/path/to/proj.xpr"
    exit 1
}

ensure_open_project

# Make sure synth_1 run exists
set synth_runs [get_runs synth_1]
if {[llength $synth_runs] == 0} {
    puts "ERROR: Run synth_1 not found in project. Please generate the project/runs first (e.g. make vivado ...)."
    exit 1
}

set synth_run [lindex $synth_runs 0]
set status [get_property STATUS $synth_run]
puts "INFO: synth_1 status: $status"

# Launch synthesis if not complete, then block until finished
if {$status ne "synth_design Complete"} {
    # Determine parallel jobs as half of system threads (min 1)
    set sys_threads 1
    if {![catch {exec nproc} _nproc_out]} {
        set _nproc_trim [string trim $_nproc_out]
        if {[scan $_nproc_trim "%d" sys_threads] != 1} { set sys_threads 1 }
    }
    set jobs [expr {int(ceil($sys_threads/2.0))}]
    if {$jobs < 1} { set jobs 1 }
    puts "INFO: Launching synth_1 with -jobs $jobs (system threads: $sys_threads)"
    launch_runs synth_1 -jobs $jobs
    wait_on_run $synth_run
} else {
    puts "INFO: synth_1 already complete."
}

puts "INFO: Synthesis flow finished."
