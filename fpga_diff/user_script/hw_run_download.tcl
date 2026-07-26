# UVHS runtime download flow. A release database is sufficient for programming
# and reset release; host software loads the workload through H2C afterwards.

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

# Keep the runtime attached after download. Terminate uv_shell when the board
# is no longer needed.
set ::uvhs_keepalive 0
vwait ::uvhs_keepalive
