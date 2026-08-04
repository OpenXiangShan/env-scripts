# Standard CPU-independent probe and trigger template for fpga_diff UVHS builds.
# Enabling probe_net instantiates the Hejian UHD capture path, so use this only
# for a dedicated waveform bitstream with the required capture DDR available.
# trigger_net declares runtime-configurable trigger signals; it does not hardcode
# a trigger condition or arm capture during the build.

proc uvhs_probe_env_bool {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        set value $::env($name)
    } else {
        set value $default
    }
    if {$value ni {0 1}} {
        error "$name must be 0 or 1, got '$value'"
    }
    return $value
}

proc uvhs_add_probe_group {clock group signals} {
    set added 0
    foreach signal $signals {
        if {[catch {probe_net -clock $clock -add [list $signal]} err]} {
            puts "WARNING: UVHS probe template: skip probe $signal: $err"
        } else {
            incr added
        }
    }
    puts "INFO: UVHS probe template: group=$group probes=$added clock=$clock"
    if {$added != [llength $signals]} {
        error "UVHS probe template: group $group added $added of [llength $signals] required probes"
    }
    return $added
}

proc uvhs_add_trigger_group {clock group signals} {
    if {[catch {
        trigger_net -add -group $group -clock $clock -signal $signals
    } err]} {
        error "UVHS probe template: failed to add trigger group $group: $err"
    }
    puts "INFO: UVHS probe template: trigger group=$group signals=[llength $signals] clock=$clock"
    return 1
}

if {![uvhs_probe_env_bool UVHS_ENABLE_PROBE_NET 0]} {
    puts "INFO: UVHS probe template disabled; set UVHS_ENABLE_PROBE_NET=1 for a waveform build"
    return
}

set uvhs_probe_top fpga_top_debug
if {[info exists ::env(UVHS_PROBE_TOP)] && $::env(UVHS_PROBE_TOP) ne ""} {
    set uvhs_probe_top $::env(UVHS_PROBE_TOP)
}
set uvhs_probe_core ${uvhs_probe_top}.core_def
set uvhs_sys_clock ${uvhs_probe_core}.sys_clk_i
set uvhs_pcie_clock ${uvhs_probe_core}.difftest_pcie_clock

set uvhs_control_signals [list \
    ${uvhs_probe_core}.sys_rstn_io \
    ${uvhs_probe_core}.cpu_rstn_io \
    ${uvhs_probe_core}.io_host_reset \
    ${uvhs_probe_core}.io_host_diff_enable \
    ${uvhs_probe_core}.xdma_link_up]

set uvhs_c2h_signals [list \
    ${uvhs_probe_core}.cpu_rstn_pcie \
    ${uvhs_probe_core}.io_host_diff_enable_pcie \
    ${uvhs_probe_core}.xdma_link_up_pcie \
    ${uvhs_probe_core}.difftest_startup_ready_pcie \
    ${uvhs_probe_core}.difftest_startup_done_pcie \
    ${uvhs_probe_core}.difftest_stream_enable_pcie \
    ${uvhs_probe_core}.difftest_c2h_rstn \
    ${uvhs_probe_core}.difftest_to_host_axis_tready_io \
    ${uvhs_probe_core}.difftest_to_host_axis_tvalid_io \
    ${uvhs_probe_core}.difftest_to_host_axis_tlast]

set uvhs_probe_count 0
incr uvhs_probe_count [uvhs_add_probe_group \
    $uvhs_sys_clock uvhs_control $uvhs_control_signals]
incr uvhs_probe_count [uvhs_add_probe_group \
    $uvhs_pcie_clock uvhs_c2h $uvhs_c2h_signals]
if {$uvhs_probe_count == 0} {
    error "UVHS probe template did not add any probes; check UVHS_PROBE_TOP and RTL hierarchy"
}

if {[uvhs_probe_env_bool UVHS_ENABLE_TRIGGER_NET 1]} {
    uvhs_add_trigger_group $uvhs_sys_clock uvhs_control $uvhs_control_signals
    uvhs_add_trigger_group $uvhs_pcie_clock uvhs_c2h $uvhs_c2h_signals
} else {
    puts "INFO: UVHS probe template: trigger groups disabled by UVHS_ENABLE_TRIGGER_NET=0"
}
