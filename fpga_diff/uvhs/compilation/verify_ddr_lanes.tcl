# Check the MIG connections. Both vendor modes expose a 72-bit wrapper.
proc uvhs_verify_ddr_lanes {checkpoint} {
    open_checkpoint $checkpoint
    set mig [get_cells -hierarchical -filter {NAME =~ "*/ddr4_0"}]
    if {[llength $mig] != 1} {
        error "Expected one DDR4 MIG in $checkpoint, found: $mig"
    }
    foreach {external internal first last} {
        DDR4_DIMM_DQ    c0_ddr4_dq     64 71
        DDR4_DIMM_DQS_P c0_ddr4_dqs_t   8  8
        DDR4_DIMM_DQS_N c0_ddr4_dqs_c   8  8
    } {
        for {set bit $first} {$bit <= $last} {incr bit} {
            set port [get_ports -quiet [format {%s[%d]} $external $bit]]
            set pin [get_pins -quiet [format {%s/%s[%d]} $mig $internal $bit]]
            if {[llength $port] != 1 || [llength $pin] != 1} {
                error "Missing DDR ECC lane ${external}\[$bit\] in $checkpoint"
            }
            set segments [get_property NAME [get_nets -segments -of_objects $port]]
            set net [get_property NAME [get_nets -of_objects $pin]]
            if {$net eq "" || $net ni $segments} {
                error "DDR ECC lane $port does not reach $pin in $checkpoint"
            }
        }
    }
    close_design
    puts "INFO: verified DDR ECC DQ and DQS lane connectivity"
}
