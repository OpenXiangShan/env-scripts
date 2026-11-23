namespace eval uvhs {
    # Parse the generated constraints as Tcl lists without executing them.
    proc partition_constraints {command} {
        set constraints [open hw.dat/Compile/Partition/part_cstr.tcl r]
        try {
            set commands {}
            foreach line [split [read $constraints] "\n"] {
                if {[regexp {^\s*(\S+)} $line match word] && $word eq $command} {
                    lappend commands $line
                }
            }
            return $commands
        } finally {
            close $constraints
        }
    }

    proc partition_option {command option} {
        set index [lsearch -exact $command $option]
        if {$index < 0} { return "" }
        return [lindex $command [expr {$index + 1}]]
    }

    proc verify_ddr_probe_group {group} {
        set partitions {}
        foreach command [partition_constraints create_partition] {
            if {$group in [partition_option $command -groups]} {
                lappend partitions [partition_option $command -name]
            }
        }
        set part [lindex $partitions 0]
        if {[llength $partitions] != 1 || $part eq ""} {
            error "Expected one partition for DDR probe group $group, found: $partitions"
        }
        set owners {}
        foreach command [partition_constraints create_fpga] {
            if {$part in [partition_option $command -parts]} {
                lappend owners [partition_option $command -name]
            }
        }
        if {$owners ne "b0.f0"} {
            error "DDR probe group $group is in $part on '$owners', expected b0.f0"
        }
    }
}

set ddr_probe_groups {}
foreach command [uvhs::partition_constraints create_group] {
    if {"core_def/U_UVHS_UVW_AXI4_TO_DDR4" ni [uvhs::partition_option $command -cells]} {
        continue
    }
    set name [uvhs::partition_option $command -name]
    set source [uvhs::partition_option $command -source]
    if {$source eq "probe"} {
        if {$name eq ""} { error "UVHS generated an unnamed DDR probe group" }
        lappend ddr_probe_groups $name
    } elseif {[string match bb_probe_group_* $name]} {
        error "Unexpected source '$source' for DDR probe group $name"
    }
}
if {[llength $ddr_probe_groups] > 1} {
    error "UVHS generated multiple DDR probe groups: $ddr_probe_groups"
}
set ddr_probe_group [lindex $ddr_probe_groups 0]
if {$ddr_probe_group ne ""} {
    puts "INFO: keep DDR probe group $ddr_probe_group on b0.f0"
    create_fpga -name b0.f0 -groups [list $ddr_probe_group] -update
}
