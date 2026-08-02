namespace eval uvhs {
    proc configure_fill_rates {} {
        set args {}
        foreach {option variable} {
            -lut UVHS_LUT_FILL_RATE
            -lut6 UVHS_LUT6_FILL_RATE
        } {
            set value [env_or_default $variable ""]
            if {$value eq ""} {
                continue
            }
            if {![string is double -strict $value] || $value <= 0 || $value > 100} {
                error "$variable must be in (0, 100], got '$value'"
            }
            lappend args $option $value
        }
        if {[llength $args]} {
            puts "INFO: set UVHS fill rates: $args"
            set_fill_rate {*}$args
        }
    }

    proc run_partition {} {
        check_design
        report_resource -depth 4
        report_system_resource
        list_partition_constraints -all
        partition_design -tdc -tdss true
        report_resource -depth 4
    }
}
