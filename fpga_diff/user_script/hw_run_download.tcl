# UVHS runtime download flow. A release database is sufficient for programming,
# reset control, and runtime memory operations. H2C remains available to the
# host flow after download.

set uvhs_script_dir [file dirname [file normalize [info script]]]
if {[info exists ::env(UVHS_RUNTIME_CONTROL_SCRIPT)] &&
    $::env(UVHS_RUNTIME_CONTROL_SCRIPT) ne ""} {
    set uvhs_control_script $::env(UVHS_RUNTIME_CONTROL_SCRIPT)
} else {
    set uvhs_control_script \
        [file normalize [file join $uvhs_script_dir .. uvhs runtime_control.tcl]]
}
if {![file exists $uvhs_control_script]} {
    error "UVHS runtime control script not found: $uvhs_control_script"
}
source $uvhs_control_script

query -user
query -fpgas -all
query -version

# uv_shell runtime invocation does not guarantee the script directory as the
# current working directory. Prefer an explicit override, otherwise assume the
# staged hw.dat sits next to user_script/ in the runtime directory.
if {[info exists ::env(UVHS_DB_PATH)] && $::env(UVHS_DB_PATH) ne ""} {
    set uvhs_db_path $::env(UVHS_DB_PATH)
} else {
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

# Keep all reset sequencing in runtime_control.tcl so download and standalone
# reset commands use the same named operations.
uvhs_hold_soc_for_download

download

query -ipinfo
initialize
after 1000

uvhs_release_soc_after_download
query -fpgas -all

# The launcher detaches this service after programming. Runtime commands still
# execute in the same UVHS session that owns the downloaded database.
uvhs_serve_runtime_commands
