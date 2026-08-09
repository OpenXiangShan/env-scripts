# The XDMA host trigger is always available. Add temporary design-specific
# paths below when a build needs more probes or trigger sources.
set uvhs_ila_group_name uvhs_ila
# Sampling clock path for this probe/trigger group. Prefer the ungated parent
# clock so post-trigger samples can complete after the DUT clock stops.
set uvhs_ila_clock_path [string trim {
    fpga_top_debug.core_def.sys_clk_i
}]
# Probe signal paths, one per line.
set uvhs_ila_probe_paths {
    fpga_top_debug.core_def.io_host_ila_trigger
}
# Trigger signal paths, one per line.
set uvhs_ila_trigger_paths {
    fpga_top_debug.core_def.io_host_ila_trigger
}

if {$uvhs_ila_clock_path eq ""} {
    if {[llength $uvhs_ila_probe_paths] ||
        [llength $uvhs_ila_trigger_paths]} {
        error "UVHS ILA signals require a sampling clock path"
    }
} else {
    if {[llength $uvhs_ila_probe_paths]} {
        probe_net -clock $uvhs_ila_clock_path -add $uvhs_ila_probe_paths
    }
    if {[llength $uvhs_ila_trigger_paths]} {
        trigger_net -add -group $uvhs_ila_group_name \
            -clock $uvhs_ila_clock_path \
            -signal $uvhs_ila_trigger_paths
    }
}

unset uvhs_ila_group_name uvhs_ila_clock_path
unset uvhs_ila_probe_paths uvhs_ila_trigger_paths
