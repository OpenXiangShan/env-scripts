# Minimal Hejian runtime bringup flow.
# Keep this script free of RTDB/readback/debug dependencies so a release DB is
# enough for programming and reset validation on the programming host.

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

# This DB does not expose runtime-configurable clocks. Board clocks are handled
# by the synthesized timing constraints and the platform default clock setup.

# Hold the top-level resets low across download, then release them in the
# same order used by the checked-in runtime scripts for this design. The host
# keeps CPU execution stopped later through HOST_IO_RESET while DDR is written.
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

    set uvhs_command_file $::env(UVHS_COMMAND_FILE)
    if {[file exists $uvhs_command_file]} {
        set uvhs_running_file "${uvhs_command_file}.running"
        if {[catch {
            file rename -force $uvhs_command_file $uvhs_running_file
            source $uvhs_running_file
        } uvhs_command_error]} {
            puts stderr "ERROR: UVHS command file failed: $uvhs_command_error"
        }
        catch {file delete -force $uvhs_running_file}
    }
    after 500 uvhs_poll_command_file
}

# Hejian runtime must stay attached after download; terminate the uv_shell
# process manually when the board is no longer needed.
set ::uvhs_keepalive 0
uvhs_poll_command_file
vwait ::uvhs_keepalive
