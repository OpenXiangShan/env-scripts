# Capture command fragment for an already attached hw_run_download.tcl runtime.
# This consumes the single probe/trigger definition in uvhs/probe_template.tcl;
# it does not declare another instrumentation or DDR path.

proc uvhs_uhd_env {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

set uvhs_uhd_script_dir [file dirname [file normalize [info script]]]
set uvhs_uhd_workdir [uvhs_uhd_env UVHS_RUNTIME_WORKDIR [pwd]]
set uvhs_uhd_ini [file normalize [uvhs_uhd_env UVHS_UHD_TRIGGER_INI \
    [file join $uvhs_uhd_script_dir uhd_c2h.ini]]]
set uvhs_uhd_clock [uvhs_uhd_env UVHS_UHD_GATED_CLOCK \
    b0/f2/part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK]
set uvhs_uhd_frequency [uvhs_uhd_env UVHS_UHD_GATED_CLOCK_HZ 125000000]
set uvhs_uhd_position [uvhs_uhd_env UVHS_UHD_TRIGGER_POSITION 50]
set uvhs_uhd_depth [uvhs_uhd_env UVHS_UHD_CAPTURE_DEPTH 20000]
set uvhs_uhd_wait [uvhs_uhd_env UVHS_UHD_TRIGGER_WAIT_SEC 420]
set uvhs_uhd_out [uvhs_uhd_env UVHS_UHD_OUTPUT uvhs_c2h_capture]
set uvhs_uhd_bindir [file normalize [file join $uvhs_uhd_workdir UHD $uvhs_uhd_out]]

if {![file isfile $uvhs_uhd_ini]} {
    error "UVHS UHD trigger condition file not found: $uvhs_uhd_ini"
}
if {![regexp {^[A-Za-z0-9][A-Za-z0-9_.-]*$} $uvhs_uhd_out] ||
        $uvhs_uhd_out in {. ..}} {
    error "UVHS_UHD_OUTPUT must be a relative run name using A-Z, a-z, 0-9, '.', '_' or '-': '$uvhs_uhd_out'"
}
foreach {name value} [list \
        UVHS_UHD_GATED_CLOCK_HZ $uvhs_uhd_frequency \
        UVHS_UHD_TRIGGER_POSITION $uvhs_uhd_position \
        UVHS_UHD_CAPTURE_DEPTH $uvhs_uhd_depth \
        UVHS_UHD_TRIGGER_WAIT_SEC $uvhs_uhd_wait] {
    if {![string is integer -strict $value] || $value <= 0} {
        error "$name must be a positive integer, got '$value'"
    }
}

puts "UVHS_UHD_CAPTURE_BEGIN [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
puts "UVHS_UHD_TRIGGER_INI $uvhs_uhd_ini"
puts "UVHS_UHD_OUTPUT $uvhs_uhd_bindir"
query -capture
query -trigger
trigger -ini_check $uvhs_uhd_ini
trigger -set -gatedclk $uvhs_uhd_clock \
    -frequency $uvhs_uhd_frequency -polarity H
trigger -set -condition $uvhs_uhd_ini -position $uvhs_uhd_position
capture -enable
trigger -enable
puts "UVHS_UHD_CAPTURE_ARMED [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
trigger -status -wait 1 -timeout $uvhs_uhd_wait
puts "UVHS_UHD_CAPTURE_TRIGGERED [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
upload_uhd -depth $uvhs_uhd_depth -position $uvhs_uhd_position \
    -out $uvhs_uhd_out -force_overwrite -timeout 300
puts "UVHS_UHD_CAPTURE_UPLOADED $uvhs_uhd_bindir"
wavegen -bindir $uvhs_uhd_bindir
puts "UVHS_UHD_WAVEFORM [file join $uvhs_uhd_bindir UvData.usdb]"
puts "UVHS_UHD_CAPTURE_END [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
