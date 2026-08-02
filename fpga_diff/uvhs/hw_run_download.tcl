# Download a completed UVHS database and retain the owning runtime session for
# reset and memory commands.

set uvhs_script_dir [file dirname [file normalize [info script]]]
set uvhs_control_script [file join $uvhs_script_dir runtime_control.tcl]
if {![file exists $uvhs_control_script]} {
    error "UVHS runtime control script not found: $uvhs_control_script"
}
source $uvhs_control_script

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
