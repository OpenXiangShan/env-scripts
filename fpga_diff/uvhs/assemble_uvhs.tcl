################################################################################
# UVHS-only board assembly overlay for fpga_diff.
################################################################################

proc uvhs_env_or_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc uvhs_env_if_exists_or_default {name default} {
    if {[info exists ::env($name)]} {
        return $::env($name)
    }
    return $default
}

set uvhs_base_assemble [uvhs_env_or_default UVHS_BASE_ASSEMBLE_FILE ./script/1B_4F_HGC_assemble.tcl]
set uvhs_uvw_ddr4_mode [expr {[uvhs_env_or_default UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP 0] eq "1"}]
set uvhs_default_mem_dc [expr {$uvhs_uvw_ddr4_mode ? "none" : "UV_MEM_ARRAY_F"}]
set uvhs_mem_dc [uvhs_env_or_default UVHS_MEM_ARRAY_DC $uvhs_default_mem_dc]
set uvhs_mem_inst [uvhs_env_or_default UVHS_MEM_ARRAY_INST mem_array_inst0]
set uvhs_mem_connector [uvhs_env_or_default UVHS_MEM_ARRAY_CONNECTOR b0.F2_FMC1]
set uvhs_replace_inst [uvhs_env_or_default UVHS_MEM_ARRAY_REPLACE_INST pddr4dme_inst2]
set uvhs_replace_connector [uvhs_env_or_default UVHS_MEM_ARRAY_REPLACE_CONNECTOR b0.F2_FMC3]
set uvhs_aux_ddr_dc [uvhs_env_if_exists_or_default UVHS_AUX_DDR_DC UV_FMCH_PDDR4DME]
set uvhs_aux_ddr_inst [uvhs_env_or_default UVHS_AUX_DDR_INST pddr4dme_f2_aux_inst]
set uvhs_aux_ddr_connector [uvhs_env_or_default UVHS_AUX_DDR_CONNECTOR b0.F2_FMC2]
set uvhs_aux_swap_base_connector [uvhs_env_or_default UVHS_AUX_DDR_SWAP_BASE_CONNECTOR ""]
set uvhs_target_fpga [string tolower [uvhs_env_or_default UVHS_TARGET_FPGA_LOWER b0.f2]]
set uvhs_known_fpgas {b0.f0 b0.f1 b0.f2 b0.f3}

if {![file exists $uvhs_base_assemble]} {
    error "missing base assembly file: $uvhs_base_assemble"
}

set uvhs_fh [open $uvhs_base_assemble r]
set uvhs_base_data [read $uvhs_fh]
close $uvhs_fh

set uvhs_remove_dc_instances {}
foreach uvhs_line [split $uvhs_base_data "\n"] {
    set uvhs_trimmed_line [string trim $uvhs_line]
    set uvhs_lower_line [string tolower $uvhs_trimmed_line]
    if {[regexp {^config_hw[ \t]+-connect_daughter_card[ \t]+\{([^ \t]+)[ \t]+([^ \t]+)\.FMC\}} $uvhs_trimmed_line -> uvhs_connector uvhs_instance]} {
        set uvhs_lower_connector [string tolower $uvhs_connector]
        set uvhs_touches_known_fpga 0
        foreach uvhs_fpga $uvhs_known_fpgas {
            if {[string first $uvhs_fpga $uvhs_lower_connector] == 0} {
                set uvhs_touches_known_fpga 1
                break
            }
        }
        if {$uvhs_touches_known_fpga && [string first $uvhs_target_fpga $uvhs_lower_connector] != 0} {
            lappend uvhs_remove_dc_instances $uvhs_instance
        }
    }
}

if {$uvhs_mem_dc ne "" && $uvhs_mem_dc ne "none" && $uvhs_replace_inst ne "" && $uvhs_replace_inst ne "none"} {
    set uvhs_remove_create "config_hw -create_daughter_card UV_FMCH_PDDR4DME -instance $uvhs_replace_inst"
    set uvhs_remove_connect "config_hw -connect_daughter_card \\{$uvhs_replace_connector $uvhs_replace_inst.FMC\\}"
    regsub -line -all "^$uvhs_remove_create\[ \t\]*\n" $uvhs_base_data "" uvhs_base_data
    regsub -line -all "^$uvhs_remove_connect\[ \t\]*\n" $uvhs_base_data "" uvhs_base_data
    puts "INFO: UVHS memory overlay: replace $uvhs_replace_inst on $uvhs_replace_connector"
}

set uvhs_filtered_lines [list]
foreach uvhs_line [split $uvhs_base_data "\n"] {
    set uvhs_trimmed_line [string trim $uvhs_line]
    if {[regexp {^config_hw[ \t]+-create_(daughter_card|peripheral)[ \t]+[^ \t]+[ \t]+-instance[ \t]+([^ \t]+)} $uvhs_trimmed_line -> uvhs_create_type uvhs_instance] &&
        [lsearch -exact $uvhs_remove_dc_instances $uvhs_instance] >= 0} {
        puts "INFO: UVHS single-FPGA overlay: remove non-target daughter-card instance: $uvhs_trimmed_line"
        continue
    }
    if {[regexp {^config_hw[ \t]+-connect_daughter_card[ \t]+\{([^ \t]+)[ \t]+([^ \t]+)\.FMC\}} $uvhs_trimmed_line -> uvhs_connector uvhs_instance]} {
        set uvhs_lower_connector [string tolower $uvhs_connector]
        set uvhs_touches_known_fpga 0
        foreach uvhs_fpga $uvhs_known_fpgas {
            if {[string first $uvhs_fpga $uvhs_lower_connector] == 0} {
                set uvhs_touches_known_fpga 1
                break
            }
        }
        if {$uvhs_touches_known_fpga && [string first $uvhs_target_fpga $uvhs_lower_connector] != 0} {
            puts "INFO: UVHS single-FPGA overlay: remove non-target daughter-card link: $uvhs_trimmed_line"
            continue
        }
    }
    if {[string match "config_hw -connect_fpga *" $uvhs_trimmed_line]} {
        set uvhs_lower_line [string tolower $uvhs_trimmed_line]
        set uvhs_touches_target [expr {[string first $uvhs_target_fpga $uvhs_lower_line] >= 0}]
        set uvhs_touches_other 0
        foreach uvhs_fpga $uvhs_known_fpgas {
            if {$uvhs_fpga ne $uvhs_target_fpga && [string first $uvhs_fpga $uvhs_lower_line] >= 0} {
                set uvhs_touches_other 1
                break
            }
        }
        if {$uvhs_touches_other || !$uvhs_touches_target} {
            puts "INFO: UVHS single-FPGA overlay: remove non-target FPGA link: $uvhs_trimmed_line"
            continue
        }
    }
    if {$uvhs_mem_dc ne "" && $uvhs_mem_dc ne "none" &&
        [string match "config_hw -connect_fpga *" $uvhs_trimmed_line] &&
        [string match "*$uvhs_mem_connector*" $uvhs_trimmed_line]} {
        puts "INFO: UVHS memory overlay: remove connector conflict: $uvhs_trimmed_line"
        continue
    }
    lappend uvhs_filtered_lines $uvhs_line
}
set uvhs_base_data [join $uvhs_filtered_lines "\n"]

set uvhs_unplug_overlay ""
foreach uvhs_fpga $uvhs_known_fpgas {
    if {$uvhs_fpga eq $uvhs_target_fpga} {
        append uvhs_unplug_overlay "#config_hw -unplug_fpga $uvhs_fpga\n"
    } else {
        append uvhs_unplug_overlay "puts \"INFO: UVHS single-FPGA overlay: unplug $uvhs_fpga, keep $uvhs_target_fpga\"\n"
        append uvhs_unplug_overlay "config_hw -unplug_fpga $uvhs_fpga\n"
    }
}
set uvhs_create_board_replacements [regsub -line {^(config_hw[ \t]+-create_board_instance[ \t]+1[ \t]*)$} \
    $uvhs_base_data "\\1\n$uvhs_unplug_overlay" uvhs_base_data]
if {$uvhs_create_board_replacements != 1} {
    puts "WARN: UVHS single-FPGA overlay: failed to insert unplug commands after create_board_instance; prepend overlay"
    set uvhs_base_data "$uvhs_unplug_overlay\n$uvhs_base_data"
}

set uvhs_late_overlay ""
if {$uvhs_mem_dc ne "" && $uvhs_mem_dc ne "none"} {
    append uvhs_late_overlay [format {
puts "INFO: UVHS memory overlay: create %s as %s"
config_hw -create_daughter_card %s -instance %s
puts "INFO: UVHS memory overlay: connect %s to %s.FMC"
config_hw -connect_daughter_card {%s %s.FMC}
} $uvhs_mem_dc $uvhs_mem_inst $uvhs_mem_dc $uvhs_mem_inst $uvhs_mem_connector $uvhs_mem_inst $uvhs_mem_connector $uvhs_mem_inst]
}

set uvhs_patched_data $uvhs_base_data
if {$uvhs_aux_ddr_dc ne "" && $uvhs_aux_ddr_dc ne "none"} {
    if {$uvhs_aux_swap_base_connector ne "" && $uvhs_aux_swap_base_connector ne "none"} {
        set uvhs_base_connect_anchor "^config_hw -connect_daughter_card \\{$uvhs_replace_connector $uvhs_replace_inst.FMC\\}\[ \t\]*$"
        set uvhs_base_connect_replacement "config_hw -connect_daughter_card {$uvhs_aux_swap_base_connector $uvhs_replace_inst.FMC}"
        set uvhs_base_connect_replacements [regsub -line $uvhs_base_connect_anchor $uvhs_patched_data $uvhs_base_connect_replacement uvhs_patched_data]
        if {$uvhs_base_connect_replacements != 1} {
            error "failed to move $uvhs_replace_inst from $uvhs_replace_connector to $uvhs_aux_swap_base_connector"
        }
        puts "INFO: UVHS memory overlay: move $uvhs_replace_inst from $uvhs_replace_connector to $uvhs_aux_swap_base_connector"
    }

    set uvhs_aux_overlay [format {
puts "INFO: UVHS memory overlay: create auxiliary DDR %s as %s"
config_hw -create_daughter_card %s -instance %s
puts "INFO: UVHS memory overlay: connect %s to %s.FMC"
config_hw -connect_daughter_card {%s %s.FMC}
} $uvhs_aux_ddr_dc $uvhs_aux_ddr_inst $uvhs_aux_ddr_dc $uvhs_aux_ddr_inst $uvhs_aux_ddr_connector $uvhs_aux_ddr_inst $uvhs_aux_ddr_connector $uvhs_aux_ddr_inst]

    # UVHS UHD consumes the first usable F2 PDDR4DME-class resource during
    # binding. Keep the board's F2/FMC3 DDR as the later resource so the user
    # uvw_axi4_to_ddr4 IP binds to the physical DDR that initializes on board.
    set uvhs_aux_anchor "^config_hw -create_daughter_card UV_FMCH_PDDR4DME -instance $uvhs_replace_inst\[ \t\]*$"
    set uvhs_aux_replacements [regsub -line $uvhs_aux_anchor $uvhs_patched_data "$uvhs_aux_overlay\n&" uvhs_patched_data]
    if {$uvhs_aux_replacements != 1} {
        puts "WARN: UVHS memory overlay: failed to insert auxiliary DDR before $uvhs_replace_inst; append before assemble"
        append uvhs_late_overlay $uvhs_aux_overlay
    }
}

set uvhs_replacements [regsub -line {^config_hw[ \t]+-assemble[ \t]*$} $uvhs_patched_data "$uvhs_late_overlay\nconfig_hw -assemble" uvhs_patched_data]
if {$uvhs_replacements != 1} {
    error "failed to patch assembly file before config_hw -assemble: $uvhs_base_assemble"
}

set uvhs_overlay_file [file join [pwd] script .uvhs_assemble_with_mem_array.tcl]
set uvhs_fh [open $uvhs_overlay_file w]
puts -nonewline $uvhs_fh $uvhs_patched_data
close $uvhs_fh

puts "INFO: source UVHS assembly overlay $uvhs_overlay_file"
source $uvhs_overlay_file
