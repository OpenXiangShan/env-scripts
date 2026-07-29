# UVHS runtime download flow. A release database is sufficient for programming,
# reset control, and runtime memory operations. H2C remains available to the
# host flow after download.

query -user
query -fpgas -all
query -version

# uv_shell runtime invocation does not guarantee the script directory as the
# current working directory. Prefer an explicit override, otherwise assume the
# staged hw.dat sits next to user_script/ in the runtime directory.
if {[info exists ::env(UVHS_DB_PATH)] && $::env(UVHS_DB_PATH) ne ""} {
    set uvhs_db_path $::env(UVHS_DB_PATH)
} else {
    set uvhs_script_dir [file dirname [file normalize [info script]]]
    set uvhs_db_path [file normalize [file join $uvhs_script_dir .. hw.dat]]
}
puts "INFO: loading runtime database $uvhs_db_path"
load_db -db $uvhs_db_path

config -connector
query -connector -type fmc
query -voltage

# Some release databases carry replay clock values without UVHS sign-off
# frequencies.  Configure defaults when available; otherwise retain the
# database replay clocks, as the x4 runtime template does.
if {[catch {query -clock -default} uvhs_clock_error]} {
    puts "WARN: no sign-off default clock; retaining database replay clocks: $uvhs_clock_error"
} else {
    config -clock -default
    config -clock -commit
    query -clock
}

# Hold the top-level resets low across download, then release them in the
# same order used by the checked-in runtime scripts for this design. Runtime
# memory commands hold rstn_sw5 low while DDR is written.
reset -name rstn_sw6 -value 0
reset -name rstn_sw5 -value 0
reset -name rstn_sw4 -value 0
query -reset

download

query -ipinfo
initialize
after 1000

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
query -fpgas -all

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

# Keep the runtime attached after download. Other Make targets enqueue commands
# through UVHS_COMMAND_FILE; uvhs_runtime_stop ends this session cleanly.
set ::uvhs_keepalive 0
uvhs_poll_command_file
vwait ::uvhs_keepalive
