# Download a completed UVHS database and retain the owning runtime session for
# reset and memory commands.

proc uvhs_hold_soc_for_download {} {
    reset -name rstn_sw6 -value 0
    reset -name rstn_sw5 -value 0
    reset -name rstn_sw4 -value 0
    query -reset
}

proc uvhs_release_soc_after_download {} {
    reset -name rstn_sw6 -value 0
    reset -name rstn_sw5 -value 0
    reset -name rstn_sw4 -value 0
    after 1000
    reset -name rstn_sw6 -value 1
    reset -name rstn_sw4 -value 1
    after 1000
    reset -name rstn_sw5 -value 1
    after 1000
    query -reset
}

proc uvhs_halt_soc {} {
    reset -name rstn_sw5 -value 0
    query -reset
}

proc uvhs_reset_cpu {} {
    reset -name rstn_sw5 -value 0
    after 500
    reset -name rstn_sw5 -value 1
    after 500
    query -reset
}

proc uvhs_hold_cpu_for_memory {} {
    reset -name rstn_sw5 -value 0
    after 100
}

proc uvhs_release_cpu_after_memory {} {
    reset -name rstn_sw5 -value 1
    after 500
    query -reset
}

proc uvhs_signal_runtime_ready {} {
    if {![info exists ::env(UVHS_RUNTIME_READY_FILE)] ||
        $::env(UVHS_RUNTIME_READY_FILE) eq ""} {
        return
    }
    set ready_file $::env(UVHS_RUNTIME_READY_FILE)
    file mkdir [file dirname $ready_file]
    set temp_file "${ready_file}.tmp.[pid]"
    set output [open $temp_file w]
    puts $output [pid]
    close $output
    file rename -force $temp_file $ready_file
    puts "INFO: UVHS runtime command service is ready"
}

proc uvhs_clear_runtime_ready {} {
    if {[info exists ::env(UVHS_RUNTIME_READY_FILE)] &&
        $::env(UVHS_RUNTIME_READY_FILE) ne ""} {
        file delete -force $::env(UVHS_RUNTIME_READY_FILE)
    }
}

proc uvhs_poll_command_file {} {
    if {![info exists ::env(UVHS_COMMAND_FILE)] || $::env(UVHS_COMMAND_FILE) eq ""} {
        after 500 uvhs_poll_command_file
        return
    }
    set command_file $::env(UVHS_COMMAND_FILE)
    if {[file exists $command_file]} {
        set running_file "${command_file}.running"
        set uvhs_result_file ""
        set command_status [catch {
            file rename -force $command_file $running_file
            puts "INFO: sourcing UVHS runtime command: $running_file"
            source $running_file
        } command_message]
        if {$command_status != 0} {
            set command_message "UVHS runtime command failed: $command_message"
        }
        catch {file delete -force $running_file}
        if {$uvhs_result_file ne ""} {
            set result_tmp "${uvhs_result_file}.tmp.[pid]"
            set result [open $result_tmp w]
            puts $result $command_status
            puts -nonewline $result $command_message
            close $result
            file rename -force $result_tmp $uvhs_result_file
        }
        if {$command_status != 0} {
            puts stderr "ERROR: $command_message"
        }
    }
    after 500 uvhs_poll_command_file
}

proc uvhs_serve_runtime_commands {} {
    set ::uvhs_keepalive 0
    uvhs_signal_runtime_ready
    uvhs_poll_command_file
    vwait ::uvhs_keepalive
    uvhs_clear_runtime_ready
}

query -user
query -fpgas -all
query -version

if {[info exists ::env(UVHS_DB_PATH)] && $::env(UVHS_DB_PATH) ne ""} {
    set uvhs_db_path $::env(UVHS_DB_PATH)
} else {
    set uvhs_db_path [file normalize [file join [pwd] .. hw.dat]]
}
puts "INFO: loading runtime database $uvhs_db_path"
load_db -db $uvhs_db_path

config -connector
query -connector -type fmc
query -voltage

# A release database can lack sign-off defaults. In that case the replay clock
# values already stored in the database remain active.
if {[catch {query -clock -default} uvhs_clock_error]} {
    puts "WARN: retaining database replay clocks: $uvhs_clock_error"
} else {
    config -clock -default
    config -clock -commit
    query -clock
}

uvhs_hold_soc_for_download
download
query -ipinfo
initialize
after 1000
uvhs_release_soc_after_download
query -fpgas -all

# Later commands must execute in the session that owns the downloaded database.
uvhs_serve_runtime_commands
