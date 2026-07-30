################################################################################
# Reduce the vendor four-FPGA assembly template to the selected UVHS FPGA.
################################################################################

proc uvhs_env_or_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

set uvhs_base_assemble ./script/1B_4F_HGC_assemble.tcl
set uvhs_target_fpga [string tolower [uvhs_env_or_default UVHS_TARGET_FPGA_LOWER b0.f2]]
set uvhs_known_fpgas {b0.f0 b0.f1 b0.f2 b0.f3}
set uvhs_keep_fpgas {}
foreach uvhs_fpga [split [uvhs_env_or_default UVHS_KEEP_FPGAS $uvhs_target_fpga]] {
    set uvhs_fpga [string tolower [string trim $uvhs_fpga]]
    if {$uvhs_fpga ne "" && [lsearch -exact $uvhs_keep_fpgas $uvhs_fpga] < 0} {
        lappend uvhs_keep_fpgas $uvhs_fpga
    }
}
if {[lsearch -exact $uvhs_keep_fpgas $uvhs_target_fpga] < 0} {
    lappend uvhs_keep_fpgas $uvhs_target_fpga
}
foreach uvhs_fpga $uvhs_keep_fpgas {
    if {[lsearch -exact $uvhs_known_fpgas $uvhs_fpga] < 0} {
        error "UVHS_KEEP_FPGAS contains unknown FPGA '$uvhs_fpga'"
    }
}

if {![file exists $uvhs_base_assemble]} {
    error "missing base assembly file: $uvhs_base_assemble"
}

set uvhs_fh [open $uvhs_base_assemble r]
set uvhs_base_data [read $uvhs_fh]
close $uvhs_fh

# Record daughter cards attached only to FPGAs that will be unplugged. Their
# create commands must be removed together with their connector commands.
set uvhs_remove_dc_instances {}
foreach uvhs_line [split $uvhs_base_data "\n"] {
    set uvhs_trimmed_line [string trim $uvhs_line]
    if {[regexp {^config_hw[ \t]+-connect_daughter_card[ \t]+\{([^ \t]+)[ \t]+([^ \t]+)\.FMC\}} $uvhs_trimmed_line -> uvhs_connector uvhs_instance]} {
        set uvhs_lower_connector [string tolower $uvhs_connector]
        foreach uvhs_fpga $uvhs_known_fpgas {
            if {[string first $uvhs_fpga $uvhs_lower_connector] == 0 &&
                [lsearch -exact $uvhs_keep_fpgas $uvhs_fpga] < 0} {
                lappend uvhs_remove_dc_instances $uvhs_instance
                break
            }
        }
    }
}

set uvhs_filtered_lines [list]
foreach uvhs_line [split $uvhs_base_data "\n"] {
    set uvhs_trimmed_line [string trim $uvhs_line]
    if {[regexp {^config_hw[ \t]+-create_(daughter_card|peripheral)[ \t]+[^ \t]+[ \t]+-instance[ \t]+([^ \t]+)} $uvhs_trimmed_line -> uvhs_create_type uvhs_instance] &&
        [lsearch -exact $uvhs_remove_dc_instances $uvhs_instance] >= 0} {
        puts "INFO: UVHS selected-FPGA overlay: remove unused daughter-card instance: $uvhs_trimmed_line"
        continue
    }
    if {[regexp {^config_hw[ \t]+-unplug_fpga[ \t]+([^ \t]+)} $uvhs_trimmed_line -> uvhs_unplug_fpga]} {
        set uvhs_unplug_fpga [string tolower $uvhs_unplug_fpga]
        if {[lsearch -exact $uvhs_keep_fpgas $uvhs_unplug_fpga] >= 0} {
            puts "INFO: UVHS selected-FPGA overlay: ignore base unplug for kept FPGA $uvhs_unplug_fpga"
            continue
        }
    }
    if {[regexp {^config_hw[ \t]+-connect_daughter_card[ \t]+\{([^ \t]+)[ \t]+([^ \t]+)\.FMC\}} $uvhs_trimmed_line -> uvhs_connector uvhs_instance]} {
        set uvhs_lower_connector [string tolower $uvhs_connector]
        set uvhs_remove_link 0
        foreach uvhs_fpga $uvhs_known_fpgas {
            if {[string first $uvhs_fpga $uvhs_lower_connector] == 0 &&
                [lsearch -exact $uvhs_keep_fpgas $uvhs_fpga] < 0} {
                set uvhs_remove_link 1
                break
            }
        }
        if {$uvhs_remove_link} {
            puts "INFO: UVHS selected-FPGA overlay: remove unused daughter-card link: $uvhs_trimmed_line"
            continue
        }
    }
    if {[string match "config_hw -connect_fpga *" $uvhs_trimmed_line]} {
        set uvhs_lower_line [string tolower $uvhs_trimmed_line]
        set uvhs_touches_kept 0
        set uvhs_touches_unused 0
        foreach uvhs_fpga $uvhs_known_fpgas {
            if {[string first $uvhs_fpga $uvhs_lower_line] >= 0} {
                if {[lsearch -exact $uvhs_keep_fpgas $uvhs_fpga] >= 0} {
                    set uvhs_touches_kept 1
                } else {
                    set uvhs_touches_unused 1
                }
            }
        }
        if {$uvhs_touches_unused || !$uvhs_touches_kept} {
            puts "INFO: UVHS selected-FPGA overlay: remove unused FPGA link: $uvhs_trimmed_line"
            continue
        }
    }
    lappend uvhs_filtered_lines $uvhs_line
}
set uvhs_base_data [join $uvhs_filtered_lines "\n"]

set uvhs_unplug_overlay ""
foreach uvhs_fpga $uvhs_known_fpgas {
    if {[lsearch -exact $uvhs_keep_fpgas $uvhs_fpga] >= 0} {
        append uvhs_unplug_overlay "#config_hw -unplug_fpga $uvhs_fpga\n"
    } else {
        append uvhs_unplug_overlay "puts \"INFO: UVHS selected-FPGA overlay: unplug $uvhs_fpga, keep $uvhs_keep_fpgas\"\n"
        append uvhs_unplug_overlay "config_hw -unplug_fpga $uvhs_fpga\n"
    }
}
set uvhs_create_board_replacements [regsub -line {^(config_hw[ \t]+-create_board_instance[ \t]+1[ \t]*)$} \
    $uvhs_base_data "\\1\n$uvhs_unplug_overlay" uvhs_base_data]
if {$uvhs_create_board_replacements != 1} {
    puts "WARN: UVHS selected-FPGA overlay: failed to insert unplug commands after create_board_instance; prepend overlay"
    set uvhs_base_data "$uvhs_unplug_overlay\n$uvhs_base_data"
}

set uvhs_overlay_file [file join [pwd] script .uvhs_assemble.tcl]
set uvhs_fh [open $uvhs_overlay_file w]
puts -nonewline $uvhs_fh $uvhs_base_data
close $uvhs_fh

puts "INFO: source UVHS assembly overlay $uvhs_overlay_file"
source $uvhs_overlay_file
