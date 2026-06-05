################################################################################
# UVHS backend flow for fpga_diff.
################################################################################

set ::fpga_diff_uvhs_dir [file dirname [info script]]

proc env_or_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc source_if_exists {file} {
    if {[file exists $file]} {
        puts "INFO: source $file"
        if {[catch {uplevel #0 [list source $file]} err]} {
            puts "WARNING: source $file failed: $err"
        }
    } else {
        puts "INFO: skip missing $file"
    }
}

proc run_or_warn {description command} {
    puts "INFO: $description"
    if {[catch {uplevel #0 $command} err]} {
        puts "WARNING: $description failed: $err"
    }
}

proc uvhs_config_probe_group_resource {} {
    set probe_group_resource [env_or_default UVHS_PROBE_GROUP_RESOURCE 35]
    if {$probe_group_resource eq "none" || $probe_group_resource eq "0"} {
        puts "INFO: skip Probe-Group resource override"
        return
    }

    run_or_warn "restore Probe-Group system resource to $probe_group_resource" \
        [list config_hw -set_resource $probe_group_resource -type Probe-Group]
}

proc uvhs_cpu_clk_period_ns {} {
    return [env_or_default UVHS_CPU_CLK_PERIOD_NS 5]
}

proc uvhs_clean_stale_partition_runtime {} {
    set partition_dir [file normalize hw.dat/Compile/Partition]
    foreach stale_file {
        partition_0bk.tcl
    } {
        set path [file join $partition_dir $stale_file]
        if {[file exists $path]} {
            file delete -force $path
            puts "INFO: removed stale partition runtime file $path"
        }
    }
}

proc uvhs_async_clock_patch_script {} {
    set async_file [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]]
    return [format {
puts "INFO: UVHS patch: source async clock groups after Vivado clocks are available"
if {[file exists {%s}]} {
    source {%s}
} else {
    puts "WARNING: UVHS patch: missing async clock file %s"
}
} $async_file $async_file $async_file]
}

proc uvhs_write_xdc_patch_script {} {
    set async_file [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]]
    return [format {
proc ::uvhs_create_ddr_ui_clock_patch {} {
    if {[llength [get_clocks -quiet DDR_UI_CLK]] > 0} {
        return
    }
    set uvhs_pins {}
    foreach uvhs_pattern {
        part_2/core_def/U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
        */U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
    } {
        foreach uvhs_pin [get_pins -quiet $uvhs_pattern] {
            if {[lsearch -exact $uvhs_pins $uvhs_pin] < 0} {
                lappend uvhs_pins $uvhs_pin
            }
        }
        foreach uvhs_pin [get_pins -hierarchical -quiet -filter "NAME =~ $uvhs_pattern"] {
            if {[lsearch -exact $uvhs_pins $uvhs_pin] < 0} {
                lappend uvhs_pins $uvhs_pin
            }
        }
    }
    if {[llength $uvhs_pins]} {
        create_clock -period 5.000 -name DDR_UI_CLK -waveform {0.000 2.500} -add [lindex $uvhs_pins 0]
        puts "INFO: UVHS patch: create DDR_UI_CLK on UVHS DDR user clock [lindex $uvhs_pins 0]"
    }
}

proc ::uvhs_patch_xdma_preopt_xdc {uvhs_xdc_file} {
    if {![file exists $uvhs_xdc_file]} {
        return
    }

    set uvhs_fh [open $uvhs_xdc_file r]
    set uvhs_data [read $uvhs_fh]
    close $uvhs_fh
    set uvhs_patched $uvhs_data

    if {[string match *pnr_physical_constraints_preopt.xdc $uvhs_xdc_file] || \
        [string match *pnr_timing_constraints_preopt.xdc $uvhs_xdc_file]} {
        regsub -all {set_property CLKIN1_PERIOD 1\.6([0-9]*)? \[get_cells -hier -quiet -filter \{NAME =~ \*/core_def/xdma_ep_i/clk_wiz_0/inst/mmcme\*_adv_inst\}\]} \
            $uvhs_patched {set_property CLKIN1_PERIOD 4.000 [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/inst/mmcme*_adv_inst}]} uvhs_patched
    }

    if {[string match *pnr_timing_constraints_preopt.xdc $uvhs_xdc_file] || \
        [string match *pnr_timing_constraints.xdc $uvhs_xdc_file]} {
        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $uvhs_patched {create_clock -period 10.000 -name DIFFTEST_PCIE_CLK -waveform {0.000 5.000} -add [get_pins part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK]} uvhs_patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer} $uvhs_patched {DIFFTEST_PCIE_CLK} uvhs_patched
        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0_c0_ddr4_ui_clk_infer[^\n]*c0_ddr4_ui_clk[^\n]*} \
            $uvhs_patched {create_clock -period 5.000 -name core_def_U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0_c0_ddr4_ui_clk_infer -waveform {0.000 2.500} -add [get_pins part_2/core_def/U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0/c0_ddr4_ui_clk]} uvhs_patched
        if {[string first {U_UVHS_UVW_AXI4_TO_DDR4} $uvhs_patched] >= 0 && \
            [string first {UVHS patch: create DDR_UI_CLK on UVHS DDR user clock} $uvhs_patched] < 0} {
            append uvhs_patched "\n::uvhs_create_ddr_ui_clock_patch\n"
        }
        if {[string first {UVHS patch: source fpga_diff async clock constraints in final Vivado timing context} $uvhs_patched] < 0} {
            append uvhs_patched "\n# UVHS patch: source fpga_diff async clock constraints in final Vivado timing context.\n"
            append uvhs_patched "if {\[file exists {%s}\]} {\n    source {%s}\n} else {\n    puts \"WARNING: UVHS patch: missing async clock file %s\"\n}\n"
        }
    }

    if {$uvhs_patched ne $uvhs_data} {
        set uvhs_fh [open $uvhs_xdc_file w]
        puts -nonewline $uvhs_fh $uvhs_patched
        close $uvhs_fh
        puts "INFO: UVHS patch: patched generated preopt XDC $uvhs_xdc_file"
    }
}

if {[info commands ::uvhs_vivado_write_xdc] eq "" && [info commands ::write_xdc] ne ""} {
    rename ::write_xdc ::uvhs_vivado_write_xdc
    proc ::write_xdc {args} {
        set uvhs_rc [catch {uplevel 1 [linsert $args 0 ::uvhs_vivado_write_xdc]} uvhs_result uvhs_options]
        foreach uvhs_arg $args {
            if {[string match *pnr_physical_constraints_preopt.xdc $uvhs_arg] || \
                [string match *pnr_timing_constraints_preopt.xdc $uvhs_arg] || \
                [string match *pnr_timing_constraints.xdc $uvhs_arg]} {
                ::uvhs_patch_xdma_preopt_xdc $uvhs_arg
            }
        }
        return -options $uvhs_options $uvhs_result
    }
    puts "INFO: UVHS patch: wrapped write_xdc to patch generated XDMA preopt constraints"
}
} $async_file $async_file $async_file]
}

proc create_clock_if_port_exists {name period port} {
    if {[llength [get_clocks -quiet $name]] > 0} {
        puts "INFO: skip create_clock $name, already exists"
        return
    }
    set ports [get_ports -quiet $port]
    if {[llength $ports] > 0} {
        run_or_warn "create_clock $name on $port" [list create_clock -name $name -per $period $ports]
    } else {
        puts "INFO: skip create_clock $name, missing port $port"
    }
}

proc create_clock_if_pin_exists {name period pin} {
    if {[llength [get_clocks -quiet $name]] > 0} {
        puts "INFO: skip create_clock $name, already exists"
        return
    }
    set pins [get_pins -quiet $pin]
    if {[llength $pins] == 0} {
        set pins [get_pins -hierarchical -quiet -filter "NAME =~ */$pin || NAME == $pin"]
    }
    if {[llength $pins] > 0} {
        run_or_warn "create_clock $name on $pin" [list create_clock -name $name -per $period $pins]
    } else {
        puts "INFO: skip create_clock $name, missing pin $pin"
    }
}

proc create_blackbox_output_clock_if_pin_exists {name period pin} {
    set pins [get_pins -quiet $pin]
    if {[llength $pins] == 0} {
        set pins [get_pins -hierarchical -quiet -filter "NAME =~ */$pin || NAME == $pin"]
    }
    if {[llength $pins] == 0} {
        puts "INFO: skip create_clock $name, missing blackbox output pin $pin"
        return
    }

    set clocks [get_clocks -quiet -of_objects $pins]
    if {[llength $clocks] > 0} {
        puts "INFO: skip create_clock $name, blackbox output pin $pin already has clocks: $clocks"
        return
    }

    run_or_warn "create_clock $name on blackbox output $pin" \
        [list create_clock -name $name -per $period $pins]
}

proc create_ddr_ui_clock_if_exists {} {
    # The default Vivado flow uses jtag_ddr_subsys/c0_ddr4_ui_clk.  The UVHS
    # flow uses uvw_axi4_to_ddr4/ddr4ip_ddr4_user_clk.  Both are 200 MHz user
    # AXI domains; constrain whichever implementation is present.
    set use_uvw_ddr [expr {[env_or_default UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP 0] eq "1"}]
    if {$use_uvw_ddr} {
        set pin_patterns {
            core_def/U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
            */U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
        }
        set clock_description "UVHS DDR ddr4ip_ddr4_user_clk"
    } else {
        set pin_patterns {
            core_def/U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0/c0_ddr4_ui_clk
            */U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0/c0_ddr4_ui_clk
            */jtag_ddr_subsys_i_UVin_ddr4_0/c0_ddr4_ui_clk
            */ddr4_0/c0_ddr4_ui_clk
        }
        set clock_description "Vivado DDR c0_ddr4_ui_clk"
    }
    set pins {}
    foreach pin_pattern $pin_patterns {
        foreach pin [get_pins -quiet $pin_pattern] {
            if {[lsearch -exact $pins $pin] < 0} {
                lappend pins $pin
            }
        }
        foreach pin [get_pins -hierarchical -quiet -filter "NAME =~ $pin_pattern"] {
            if {[lsearch -exact $pins $pin] < 0} {
                lappend pins $pin
            }
        }
    }
    if {![llength $pins]} {
        puts "INFO: skip create_clock DDR_UI_CLK, missing $clock_description pin"
        return
    }

    set pin [lindex $pins 0]
    set clocks [get_clocks -quiet -of_objects $pin]
    if {[llength $clocks]} {
        puts "INFO: DDR UI pin $pin already has clocks: $clocks"
        return
    }

    run_or_warn "create_clock DDR_UI_CLK on $clock_description" \
        [list create_clock -name DDR_UI_CLK -per 5.000 $pin]
}

proc create_generated_clock_if_bufgce_exists {name master_clock cell_patterns} {
    if {[llength [get_clocks -quiet $name]] > 0} {
        puts "INFO: skip create_generated_clock $name, already exists"
        return
    }
    if {[llength [get_clocks -quiet $master_clock]] == 0} {
        puts "WARNING: skip create_generated_clock $name, missing master clock $master_clock"
        return
    }
    set cells {}
    foreach cell_pattern $cell_patterns {
        set matches [get_cells -hierarchical -quiet -filter "NAME =~ $cell_pattern"]
        foreach match $matches {
            if {[lsearch -exact $cells $match] < 0} {
                lappend cells $match
            }
        }
    }
    if {[llength $cells] == 0} {
        set bufgce_cells [get_cells -hierarchical -quiet -filter "REF_NAME =~ BUFGCE"]
        puts "WARNING: skip create_generated_clock $name, missing BUFGCE cell patterns $cell_patterns; visible BUFGCE cells: $bufgce_cells"
        return
    }
    if {[llength $cells] > 1} {
        puts "WARNING: create_generated_clock $name matched multiple cells, using [lindex $cells 0]: $cells"
    }
    set cell [lindex $cells 0]
    set in_pins [get_pins -quiet $cell/I]
    set out_pins [get_pins -quiet $cell/O]
    if {[llength $in_pins] == 0 || [llength $out_pins] == 0} {
        puts "WARNING: skip create_generated_clock $name, missing I/O pins on $cell"
        return
    }
    run_or_warn "create_generated_clock $name on $cell/O" \
        [list create_generated_clock -name $name -master_clock $master_clock -source $in_pins -divide_by 1 $out_pins]
}

proc patch_vivado_wrappers {} {
    set patterns {
        hw.dat/Compile/PnR/*/*/vivado/Script/uv_vivado_wrapper.sh
        hw.dat/Compile/PnR/*/*/vivado/Rundir/*/uv_vivado_wrapper.sh
    }
    foreach pattern $patterns {
        foreach wrapper [glob -nocomplain $pattern] {
            if {![file exists $wrapper]} {
                continue
            }
            set fh [open $wrapper r]
            set data [read $fh]
            close $fh
            if {[string match "#!/bin/sh*" $data]} {
                regsub {^#!/bin/sh} $data {#!/bin/bash} data
                set fh [open $wrapper w]
                puts -nonewline $fh $data
                close $fh
                file attributes $wrapper -permissions u=rwx,g=rx,o=rx
                puts "INFO: patched Vivado wrapper shell to bash: $wrapper"
            }
        }
    }
}

proc patch_vivado_pre_opt {} {
    set write_xdc_patch_script [uvhs_write_xdc_patch_script]
    set script {
puts "INFO: UVHS patch: constrain XDMA clk_wiz input period for Vivado MMCM DRC"
set uvhs_xdma_clk_in [get_pins -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/clk_in1}]
if {[llength $uvhs_xdma_clk_in]} {
    set uvhs_xdma_clk_in [lindex $uvhs_xdma_clk_in 0]
    set uvhs_xdma_clocks [get_clocks -quiet -of_objects $uvhs_xdma_clk_in]
    if {![llength $uvhs_xdma_clocks]} {
        catch {create_clock -name XDMA_AXI_ACLK -period 4.000 $uvhs_xdma_clk_in} uvhs_create_clk_msg
        puts "INFO: UVHS patch: XDMA_AXI_ACLK create_clock result: $uvhs_create_clk_msg"
    } else {
        puts "INFO: UVHS patch: XDMA clk_wiz input clocks: $uvhs_xdma_clocks"
        if {[lsearch -exact $uvhs_xdma_clocks XDMA_AXI_ACLK] >= 0} {
            puts "INFO: UVHS patch: XDMA_AXI_ACLK already exists"
        } else {
            catch {create_clock -name XDMA_AXI_ACLK -period 4.000 $uvhs_xdma_clk_in} uvhs_create_clk_msg
            puts "INFO: UVHS patch: XDMA_AXI_ACLK override_clock result: $uvhs_create_clk_msg"
        }
    }
} else {
    puts "WARNING: UVHS patch: XDMA clk_wiz clk_in1 pin not found"
}
set uvhs_difftest_pcie_pin [get_pins -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK}]
if {[llength $uvhs_difftest_pcie_pin]} {
    set uvhs_difftest_pcie_pin [lindex $uvhs_difftest_pcie_pin 0]
    set uvhs_difftest_pcie_clocks [get_clocks -quiet -of_objects $uvhs_difftest_pcie_pin]
    if {![llength $uvhs_difftest_pcie_clocks]} {
        catch {create_clock -name DIFFTEST_PCIE_CLK -period 10.000 $uvhs_difftest_pcie_pin} uvhs_create_difftest_msg
        puts "INFO: UVHS patch: DIFFTEST_PCIE_CLK create_clock result: $uvhs_create_difftest_msg"
    } else {
        puts "INFO: UVHS patch: TO_DIFFTEST_PCIE_CLK already has clocks: $uvhs_difftest_pcie_clocks"
    }
} else {
    puts "WARNING: UVHS patch: TO_DIFFTEST_PCIE_CLK pin not found"
}
set uvhs_xdma_mmcms [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/inst/mmcme*_adv_inst}]
if {[llength $uvhs_xdma_mmcms]} {
    set_property CLKIN1_PERIOD 4.000 $uvhs_xdma_mmcms
    puts "INFO: UVHS patch: set CLKIN1_PERIOD=4.000 on $uvhs_xdma_mmcms"
} else {
    puts "WARNING: UVHS patch: XDMA clk_wiz MMCM cell not found"
}
set uvhs_xdma_intclks [get_clocks -quiet */xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O]
set uvhs_pcie_refclks [get_clocks -quiet pcie_ep_refclk]
if {[llength $uvhs_xdma_intclks] && [llength $uvhs_pcie_refclks]} {
    set_false_path -from $uvhs_xdma_intclks -to $uvhs_pcie_refclks
    puts "INFO: UVHS patch: false path XDMA GT internal clock -> pcie_ep_refclk"
}
set uvhs_lnk_up_src [get_pins -hier -quiet -filter {NAME =~ */xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/user_lnk_up_reg/C}]
set uvhs_lnk_up_dsts [concat \
    [get_pins -hier -quiet -filter {NAME =~ */u_capt*/captured_signal_p1_reg*/D}] \
    [get_pins -hier -quiet -filter {NAME =~ */user_lnk_up*_trigger_pipeline*/D}]]
if {[llength $uvhs_lnk_up_src] && [llength $uvhs_lnk_up_dsts]} {
    set_false_path -from $uvhs_lnk_up_src -to $uvhs_lnk_up_dsts
    puts "INFO: UVHS patch: false path XDMA user_lnk_up debug trigger paths"
}
}
    append script [uvhs_async_clock_patch_script]
    foreach pre_opt [glob -nocomplain hw.dat/Compile/PnR/*/*/user_stage_tcl/pre_opt.tcl] {
        set fh [open $pre_opt r]
        set data [read $fh]
        close $fh
        if {[string first "UVHS patch: wrapped write_xdc to patch generated XDMA preopt constraints" $data] < 0} {
            set fh [open $pre_opt a]
            puts $fh ""
            puts $fh $write_xdc_patch_script
            close $fh
            append data "\n" $write_xdc_patch_script
            puts "INFO: patched Vivado pre-opt write_xdc wrapper: $pre_opt"
        }
        if {[string first "UVHS patch: constrain XDMA clk_wiz input period" $data] < 0} {
            set fh [open $pre_opt a]
            puts $fh ""
            puts $fh $script
            close $fh
            puts "INFO: patched Vivado pre-opt XDMA clk_wiz input period: $pre_opt"
        }
    }
}

proc patch_vivado_debug_file {} {
    set debug_file [env_or_default UVHS_VIVADO_DEBUG_FILE ""]
    if {$debug_file eq "" || $debug_file eq "none"} {
        return
    }

    set debug_file [file normalize $debug_file]
    if {![file exists $debug_file]} {
        puts "WARNING: UVHS patch: missing Vivado debug file $debug_file"
        return
    }

    set marker "UVHS patch: source Vivado debug file $debug_file"
    set script [format {
puts "INFO: UVHS patch: source Vivado debug file %s"
if {[file exists {%s}]} {
    source {%s}
} else {
    puts "WARNING: UVHS patch: missing Vivado debug file %s"
}
} $debug_file $debug_file $debug_file $debug_file]

    foreach pre_opt [glob -nocomplain hw.dat/Compile/PnR/*/*/user_stage_tcl/pre_opt.tcl] {
        set fh [open $pre_opt r]
        set data [read $fh]
        close $fh
        if {[string first $marker $data] < 0} {
            set fh [open $pre_opt a]
            puts $fh ""
            puts $fh $script
            close $fh
            puts "INFO: patched Vivado debug file into pre-opt stage: $pre_opt"
        }
    }
}

proc patch_vivado_pre_place {} {
    set script {
puts "INFO: UVHS patch: re-apply XDMA clk_wiz input period before place/route DRC"
set uvhs_xdma_clk_in [get_pins -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/clk_in1}]
if {[llength $uvhs_xdma_clk_in]} {
    set uvhs_xdma_clk_in [lindex $uvhs_xdma_clk_in 0]
    set uvhs_xdma_clocks [get_clocks -quiet -of_objects $uvhs_xdma_clk_in]
    if {![llength $uvhs_xdma_clocks]} {
        catch {create_clock -name XDMA_AXI_ACLK -period 4.000 $uvhs_xdma_clk_in} uvhs_create_clk_msg
        puts "INFO: UVHS patch: XDMA_AXI_ACLK create_clock before place result: $uvhs_create_clk_msg"
    } else {
        puts "INFO: UVHS patch: XDMA clk_wiz input clocks before place: $uvhs_xdma_clocks"
        if {[lsearch -exact $uvhs_xdma_clocks XDMA_AXI_ACLK] >= 0} {
            puts "INFO: UVHS patch: XDMA_AXI_ACLK already exists before place"
        } else {
            catch {create_clock -name XDMA_AXI_ACLK -period 4.000 $uvhs_xdma_clk_in} uvhs_create_clk_msg
            puts "INFO: UVHS patch: XDMA_AXI_ACLK override_clock before place result: $uvhs_create_clk_msg"
        }
    }
} else {
    puts "WARNING: UVHS patch: XDMA clk_wiz clk_in1 pin not found before place"
}
set uvhs_difftest_pcie_pin [get_pins -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK}]
if {[llength $uvhs_difftest_pcie_pin]} {
    set uvhs_difftest_pcie_pin [lindex $uvhs_difftest_pcie_pin 0]
    set uvhs_difftest_pcie_clocks [get_clocks -quiet -of_objects $uvhs_difftest_pcie_pin]
    if {![llength $uvhs_difftest_pcie_clocks]} {
        catch {create_clock -name DIFFTEST_PCIE_CLK -period 10.000 $uvhs_difftest_pcie_pin} uvhs_create_difftest_msg
        puts "INFO: UVHS patch: DIFFTEST_PCIE_CLK create_clock before place result: $uvhs_create_difftest_msg"
    } else {
        puts "INFO: UVHS patch: TO_DIFFTEST_PCIE_CLK clocks before place: $uvhs_difftest_pcie_clocks"
    }
} else {
    puts "WARNING: UVHS patch: TO_DIFFTEST_PCIE_CLK pin not found before place"
}
set uvhs_xdma_mmcms [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/inst/mmcme*_adv_inst}]
if {[llength $uvhs_xdma_mmcms]} {
    set_property CLKIN1_PERIOD 4.000 $uvhs_xdma_mmcms
    puts "INFO: UVHS patch: set CLKIN1_PERIOD=4.000 on $uvhs_xdma_mmcms before place"
} else {
    puts "WARNING: UVHS patch: XDMA clk_wiz MMCM cell not found before place"
}
set uvhs_xdma_pcie_cells [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*pcie_4_c_e4_inst}]
if {[llength $uvhs_xdma_pcie_cells]} {
    set_property LOC PCIE4CE4_X0Y6 $uvhs_xdma_pcie_cells
    puts "INFO: UVHS patch: set XDMA PCIe hard block LOC=PCIE4CE4_X0Y6"
} else {
    puts "WARNING: UVHS patch: XDMA PCIe hard block cell not found for LOC override"
}
puts "INFO: UVHS patch: rewire Vivado debug hub clock if it is attached to an undriven net"
if {[llength [get_debug_cores -quiet dbg_hub]]} {
    set uvhs_dbg_clk [get_nets -quiet clk5_p_pad_net_7_bufg_n]
    if {![llength $uvhs_dbg_clk]} {
        set uvhs_dbg_clk [get_nets -quiet clk5_p_pad_net_6]
    }
    if {[llength $uvhs_dbg_clk]} {
        catch {disconnect_debug_port dbg_hub/clk}
        connect_debug_port dbg_hub/clk [lindex $uvhs_dbg_clk 0]
        puts "INFO: UVHS patch: dbg_hub/clk -> [lindex $uvhs_dbg_clk 0]"
    } else {
        puts "WARNING: UVHS patch: no clk5 debug clock net found for dbg_hub"
    }
}
puts "INFO: UVHS patch: fix known bring-up bitstream DRCs"
set uvhs_ila_rams [get_cells -hier -quiet -filter {NAME =~ *system_ila_0*trace_block_memory*ram/DEVICE_8SERIES*ram}]
if {[llength $uvhs_ila_rams]} {
    set_property CLOCK_DOMAINS INDEPENDENT $uvhs_ila_rams
    puts "INFO: UVHS patch: set CLOCK_DOMAINS INDEPENDENT on [llength $uvhs_ila_rams] system ILA RAM cells"
}
set uvhs_ddr_ck_ports {}
foreach uvhs_pat {DDR0_CK_C_pad_net_* DDR0_CK_T_pad_net_*} {
    set uvhs_ddr_ck_ports [concat $uvhs_ddr_ck_ports [get_ports -quiet $uvhs_pat]]
}
if {[llength $uvhs_ddr_ck_ports]} {
    set_property IOSTANDARD DIFF_SSTL12_DCI $uvhs_ddr_ck_ports
    puts "INFO: UVHS patch: set differential IOSTANDARD on generated DDR CK pad ports: $uvhs_ddr_ck_ports"
}
foreach uvhs_check {AVAL-245 IOSTDTYPE-1} {
    set uvhs_drc [get_drc_checks -quiet $uvhs_check]
    if {[llength $uvhs_drc]} {
        set_property SEVERITY Warning $uvhs_drc
        puts "INFO: UVHS patch: downgrade DRC $uvhs_check to Warning"
    }
}
set uvhs_pdrc_179 [get_drc_checks -quiet PDRC-179]
if {[llength $uvhs_pdrc_179]} {
    set_property SEVERITY Warning $uvhs_pdrc_179
    puts "INFO: UVHS patch: downgrade DRC PDRC-179 to Warning"
}
}
    append script [uvhs_async_clock_patch_script]
    foreach pre_place [glob -nocomplain hw.dat/Compile/PnR/*/*/user_stage_tcl/pre_place.tcl] {
        set fh [open $pre_place r]
        set data [read $fh]
        close $fh
        if {[string first "UVHS patch: re-apply XDMA clk_wiz input period before place/route DRC" $data] < 0} {
            set fh [open $pre_place a]
            puts $fh ""
            puts $fh $script
            close $fh
            puts "INFO: patched Vivado pre-place debug hub clock: $pre_place"
        }
    }
}

proc patch_vivado_before_route {} {
    set script {
puts "INFO: UVHS patch: re-apply XDMA clk_wiz input period before route DRC"
set uvhs_xdma_clk_in [get_pins -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/clk_in1}]
if {[llength $uvhs_xdma_clk_in]} {
    set uvhs_xdma_clk_in [lindex $uvhs_xdma_clk_in 0]
    set uvhs_xdma_clocks [get_clocks -quiet -of_objects $uvhs_xdma_clk_in]
    if {![llength $uvhs_xdma_clocks]} {
        catch {create_clock -name XDMA_AXI_ACLK -period 4.000 $uvhs_xdma_clk_in} uvhs_create_clk_msg
        puts "INFO: UVHS patch: XDMA_AXI_ACLK create_clock before route result: $uvhs_create_clk_msg"
    } else {
        puts "INFO: UVHS patch: XDMA clk_wiz input clocks before route: $uvhs_xdma_clocks"
        if {[lsearch -exact $uvhs_xdma_clocks XDMA_AXI_ACLK] >= 0} {
            puts "INFO: UVHS patch: XDMA_AXI_ACLK already exists before route"
        } else {
            catch {create_clock -name XDMA_AXI_ACLK -period 4.000 $uvhs_xdma_clk_in} uvhs_create_clk_msg
            puts "INFO: UVHS patch: XDMA_AXI_ACLK override_clock before route result: $uvhs_create_clk_msg"
        }
    }
} else {
    puts "WARNING: UVHS patch: XDMA clk_wiz clk_in1 pin not found before route"
}
set uvhs_difftest_pcie_pin [get_pins -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK}]
if {[llength $uvhs_difftest_pcie_pin]} {
    set uvhs_difftest_pcie_pin [lindex $uvhs_difftest_pcie_pin 0]
    set uvhs_difftest_pcie_clocks [get_clocks -quiet -of_objects $uvhs_difftest_pcie_pin]
    if {![llength $uvhs_difftest_pcie_clocks]} {
        catch {create_clock -name DIFFTEST_PCIE_CLK -period 10.000 $uvhs_difftest_pcie_pin} uvhs_create_difftest_msg
        puts "INFO: UVHS patch: DIFFTEST_PCIE_CLK create_clock before route result: $uvhs_create_difftest_msg"
    } else {
        puts "INFO: UVHS patch: TO_DIFFTEST_PCIE_CLK clocks before route: $uvhs_difftest_pcie_clocks"
    }
} else {
    puts "WARNING: UVHS patch: TO_DIFFTEST_PCIE_CLK pin not found before route"
}
set uvhs_xdma_mmcms [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/inst/mmcme*_adv_inst}]
if {[llength $uvhs_xdma_mmcms]} {
    set_property CLKIN1_PERIOD 4.000 $uvhs_xdma_mmcms
    puts "INFO: UVHS patch: set CLKIN1_PERIOD=4.000 on $uvhs_xdma_mmcms before route"
    catch {update_timing} uvhs_update_timing_msg
    puts "INFO: UVHS patch: update_timing before route result: $uvhs_update_timing_msg"
} else {
    puts "WARNING: UVHS patch: XDMA clk_wiz MMCM cell not found before route"
}
set uvhs_pdrc_179 [get_drc_checks -quiet PDRC-179]
if {[llength $uvhs_pdrc_179]} {
    set_property SEVERITY Warning $uvhs_pdrc_179
    puts "INFO: UVHS patch: downgrade DRC PDRC-179 to Warning before route"
}
}
    append script [uvhs_async_clock_patch_script]
    foreach pnr_dir [glob -nocomplain hw.dat/Compile/PnR/*/*] {
        set before_route [file join $pnr_dir before_route.tcl]
        set data ""
        if {[file exists $before_route]} {
            set fh [open $before_route r]
            set data [read $fh]
            close $fh
        }
        if {[string first "UVHS patch: re-apply XDMA clk_wiz input period before route DRC" $data] < 0} {
            set fh [open $before_route a]
            puts $fh ""
            puts $fh $script
            close $fh
            puts "INFO: patched Vivado before-route XDMA clk_wiz input period: $before_route"
        }
    }
}

proc patch_timing_constraint_files {} {
    set async_xdc_block [format {

# UVHS patch: source fpga_diff async clock constraints in final Vivado timing context.
if {[file exists {%s}]} {
    source {%s}
} else {
    puts "WARNING: UVHS patch: missing async clock file %s"
}
} [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]] \
  [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]] \
  [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]]]

    foreach file [glob -nocomplain hw.dat/Compile/PnR/*/*/timing_constraints.tcl] {
        set fh [open $file r]
        set data [read $fh]
        close $fh
        set patched $data

        # UVHS infers the XDMA clk_wiz output from the PCIe GT refclk because
        # TO_DIFFTEST_PCIE_CLK exits a black-box boundary. The real source is
        # clk_wiz_0/clk_out1, so treat it as a 100 MHz primary clock for PnR.
        set difftest_primary_clock {
puts "WARNING: \[APS CSTR-1\] primary clock is defined on blackbox boundary which may cause inaccurate skew analysis."
create_clock -add -name DIFFTEST_PCIE_CLK -period [expr $uvCstrRatio * 10.000 + $uvCstrMargin] -waveform [list 0 [expr ($uvCstrRatio + $uvCstrMargin / 10.000) * 5.000]] [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]
variable DIFFTEST_PCIE_CLK_name [get_property NAME [get_clocks DIFFTEST_PCIE_CLK]]
}
        set difftest_generated_block {set DIFFTEST_PCIE_CLK_master [get_clocks -of_objects [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]]
set DIFFTEST_PCIE_CLK_source ""
if {$DIFFTEST_PCIE_CLK_master!=""} {
    set DIFFTEST_PCIE_CLK_source [get_property SOURCE_PINS $DIFFTEST_PCIE_CLK_master]
}
if {[llength $DIFFTEST_PCIE_CLK_master] == 1 && [llength $DIFFTEST_PCIE_CLK_source] == 1} {
    set DIFFTEST_PCIE_CLK_source [get_pins $DIFFTEST_PCIE_CLK_source]
    if {$DIFFTEST_PCIE_CLK_source==""} {
        set DIFFTEST_PCIE_CLK_source [get_ports [get_property SOURCE_PINS $DIFFTEST_PCIE_CLK_master]]
    }
    set driver [get_nets -top_net_of_hierarchical_group -segments -of_objects $DIFFTEST_PCIE_CLK_source]
    if {[get_nets -top_net_of_hierarchical_group -segments -of_objects [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]]==$driver} {
        variable DIFFTEST_PCIE_CLK_name [get_property NAME $DIFFTEST_PCIE_CLK_master]
        dict set uvRenameClocks DIFFTEST_PCIE_CLK [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]
    } else {
        create_generated_clock -add -name DIFFTEST_PCIE_CLK -divide_by 1 -source $DIFFTEST_PCIE_CLK_source -master_clock $DIFFTEST_PCIE_CLK_master [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]
        variable DIFFTEST_PCIE_CLK_name [get_property NAME [get_clocks DIFFTEST_PCIE_CLK]]
    }
} else {
    puts "WARNING: \[APS CSTR-1\] primary clock is defined on blackbox boundary which may cause inaccurate skew analysis."
    create_clock -add -name DIFFTEST_PCIE_CLK -period [expr $uvCstrRatio * 10.00 + $uvCstrMargin]  [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]
variable DIFFTEST_PCIE_CLK_name [get_property NAME [get_clocks DIFFTEST_PCIE_CLK]]
}}
        if {[string first $difftest_generated_block $patched] >= 0} {
            regsub [string map {\\ \\\\ \[ \\[ \] \\] \$ \\$ \( \\( \) \\) \{ \\{ \} \\} \. \\. \* \\* \+ \\+ \? \\? \^ \\^} $difftest_generated_block] \
                $patched $difftest_primary_clock patched
        }
        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $patched {create_clock -add -name DIFFTEST_PCIE_CLK -period [expr $uvCstrRatio * 10.000 + $uvCstrMargin] -waveform [list 0 [expr ($uvCstrRatio + $uvCstrMargin / 10.000) * 5.000]] [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]} patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer_name} $patched {DIFFTEST_PCIE_CLK_name} patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer} $patched {DIFFTEST_PCIE_CLK} patched
        if {![env_or_default UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP 0]} {
            regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0_c0_ddr4_ui_clk_infer[^\n]*c0_ddr4_ui_clk[^\n]*} \
                $patched {create_clock -add -name core_def_U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0_c0_ddr4_ui_clk_infer -period [expr $uvCstrRatio * 5.000 + $uvCstrMargin] -waveform [list 0 [expr ($uvCstrRatio + $uvCstrMargin / 5.000) * 2.500]] [get_pins { part_2/core_def/U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0/c0_ddr4_ui_clk }]} patched
        }
        if {$patched ne $data} {
            set fh [open $file w]
            puts -nonewline $fh $patched
            close $fh
            puts "INFO: patched UVHS DIFFTEST PCIe / DDR UI clock timing constraints: $file"
        }
    }

    foreach file [concat \
        [glob -nocomplain hw.dat/Compile/PnR/*/*/vivado/Rundir/*/bitstream/pnr_timing_constraints_preopt.xdc] \
        [glob -nocomplain hw.dat/Compile/PnR/*/*/vivado/Rundir/*/bitstream/pnr_timing_constraints.xdc]] {
        set fh [open $file r]
        set data [read $fh]
        close $fh
        set patched $data

        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $patched {create_clock -period 10.000 -name DIFFTEST_PCIE_CLK -waveform {0.000 5.000} -add [get_pins part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK]} patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer} $patched {DIFFTEST_PCIE_CLK} patched
        if {![env_or_default UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP 0]} {
            regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0_c0_ddr4_ui_clk_infer[^\n]*c0_ddr4_ui_clk[^\n]*} \
                $patched {create_clock -period 5.000 -name core_def_U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0_c0_ddr4_ui_clk_infer -waveform {0.000 2.500} -add [get_pins part_2/core_def/U_JTAG_DDR_SUBSYS_UVin_jtag_ddr_subsys_i_UVin_ddr4_0/c0_ddr4_ui_clk]} patched
        }
        regsub -all {set_property CLKIN1_PERIOD 1\.6([0-9]*)? \[get_cells -hier -quiet -filter \{NAME =~ \*/core_def/xdma_ep_i/clk_wiz_0/inst/mmcme\*_adv_inst\}\]} \
            $patched {set_property CLKIN1_PERIOD 4.000 [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/inst/mmcme*_adv_inst}]} patched
        if {[string first "UVHS patch: source fpga_diff async clock constraints in final Vivado timing context" $patched] < 0} {
            append patched $async_xdc_block
        }
        if {$patched ne $data} {
            set fh [open $file w]
            puts -nonewline $fh $patched
            close $fh
            puts "INFO: patched Vivado DIFFTEST PCIe / DDR UI clock timing constraints: $file"
        }
    }

    foreach file [glob -nocomplain hw.dat/Compile/PnR/*/*/vivado/Rundir/*/bitstream/pnr_physical_constraints_preopt.xdc] {
        set fh [open $file r]
        set data [read $fh]
        close $fh
        set patched $data

        regsub -all {set_property CLKIN1_PERIOD 1\.6([0-9]*)? \[get_cells -hier -quiet -filter \{NAME =~ \*/core_def/xdma_ep_i/clk_wiz_0/inst/mmcme\*_adv_inst\}\]} \
            $patched {set_property CLKIN1_PERIOD 4.000 [get_cells -hier -quiet -filter {NAME =~ */core_def/xdma_ep_i/clk_wiz_0/inst/mmcme*_adv_inst}]} patched
        if {$patched ne $data} {
            set fh [open $file w]
            puts -nonewline $fh $patched
            close $fh
            puts "INFO: patched Vivado XDMA clk_wiz physical constraints: $file"
        }
    }
}

proc patch_vivado_makefiles {} {
    if {[info exists ::env(UV_SHELL)] && $::env(UV_SHELL) ne ""} {
        set uv_shell $::env(UV_SHELL)
    } elseif {[info exists ::env(UV_ROOT)] && $::env(UV_ROOT) ne ""} {
        set uv_shell [file join $::env(UV_ROOT) bin uv_shell]
    } else {
        set uv_shell uv_shell
    }
    set replacement "bash $uv_shell"
    foreach makefile [glob -nocomplain hw.dat/Compile/PnR/*/*/vivado/Rundir/*/Makefile] {
        set fh [open $makefile r]
        set data [read $fh]
        close $fh
        set patched $data
        regsub -all {(^|[[:space:]&;])uv_shell([[:space:]])} \
            $patched "\\1$replacement\\2" patched
        regsub -all {(^|[[:space:]&;])(/[^[:space:]]+/uv_shell)([[:space:]])} \
            $patched "\\1$replacement\\3" patched
        regsub -all {(^|[[:space:]&;(@])(bash[[:space:]]+)+(/[^[:space:]]+/uv_shell)} \
            $patched "\\1$replacement" patched
        regsub -all {(^|[[:space:]])@uv_shell([[:space:]])} \
            $patched "\\1@$replacement\\2" patched
        if {$patched ne $data} {
            set fh [open $makefile w]
            puts -nonewline $fh $patched
            close $fh
            puts "INFO: patched UVHS Makefile uv_shell invocation: $makefile"
        }
    }
}

set_working_space hw.dat

set fpga_threads [env_or_default UVHS_FPGA_THREADS 8]
set fpga_processes [env_or_default UVHS_FPGA_PROCESSES 16]
if {[env_or_default UVHS_USE_LSF 1]} {
    set_parallel_option -max_threads $fpga_threads -max_processes $fpga_processes -submit_command {bsub -R "rusage[mem=80000]"} -terminate_command bkill -label fpga
} else {
    set_parallel_option -max_threads $fpga_threads -max_processes $fpga_processes -label fpga
}

set_option time.auto_clock_config true
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true

set design_name [env_or_default UVHS_DESIGN_NAME VU19P_X4]
set platform [env_or_default PLATFORM U2.2]
create_system_design -name $design_name -platform $platform
set assemble_file [env_or_default UVHS_ASSEMBLE_FILE ./script/1B_4F_HGC_assemble.tcl]
if {$assemble_file eq "none"} {
    puts "INFO: skip board assembly"
} else {
    source_if_exists $assemble_file
}
set skip_board_constraints [env_or_default UVHS_SKIP_BOARD_CONSTRAINTS 0]
if {$skip_board_constraints} {
    puts "INFO: skip board pin constraints"
} else {
    set assign_pin_file [env_or_default UVHS_ASSIGN_PIN_FILE ./script/assign_pin.tcl]
    if {[file exists $assign_pin_file]} {
        set ::env(UVHS_ASSIGN_PIN_TOP) none
        source_if_exists $assign_pin_file
        unset -nocomplain ::env(UVHS_ASSIGN_PIN_TOP)
    } else {
        puts "INFO: skip missing $assign_pin_file"
    }
    source_if_exists [env_or_default UVHS_PIN_OVERRIDE_FILE none]
}

create_design -name test
uvhs_clean_stale_partition_runtime
read_netlist
link_design
report_resource -depth 4

instrument_design
sanitize_design
if {$skip_board_constraints} {
    run_or_warn "check_design" {check_design}
} else {
    check_design
}
init_runtime_data
trigger_probe -check
sweep_design

create_clock_if_port_exists TMCLK 1000 clk8_p
create_clock_if_port_exists ddr_ref_clk 12.5 clk7_p
create_clock_if_port_exists CPU_CLK_IN [uvhs_cpu_clk_period_ns] clk6_p
create_clock_if_port_exists DEBUG_CLK_IN 40 clk5_p
create_clock_if_port_exists jtag_vclk 83.333 JTAG_TCK
create_clock_if_port_exists pcie_ep_refclk 10 pcie_ep_gt_ref_clk_p
create_generated_clock_if_bufgce_exists SOC_GATED_CLK DEBUG_CLK_IN {
    *SOC_CLK_CTRL*u_bufgce
    *inter_soc_clk*
}
create_generated_clock_if_bufgce_exists RTC_GATED_CLK TMCLK {
    *RTC_CLK_CTRL*u_bufgce
    *inter_rtc_clk*
}
create_blackbox_output_clock_if_pin_exists DIFFTEST_PCIE_CLK 10 core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK
create_ddr_ui_clock_if_exists
create_clock_if_pin_exists XDMA_AXI_ACLK 4 core_def/xdma_ep_i/clk_wiz_0/clk_in1
run_or_warn "infer_clock" {infer_clock}
run_or_warn "report_clock -inferred" {report_clock -inferred}
source_if_exists [file normalize [file join [file dirname [info script]] async_clocks.tcl]]
run_or_warn "transform_clock" {transform_clock}
source_if_exists [file normalize [file join [file dirname [info script]] async_clocks.tcl]]
trigger_probe -group
uvhs_config_probe_group_resource
sweep_design -remap
report_clock

if {$skip_board_constraints} {
    run_or_warn "check_design" {check_design}
} else {
    check_design
}
report_resource -depth 4
report_system_resource
list_partition_constraints -all
if {$skip_board_constraints} {
    run_or_warn "partition_design" {partition_design -tdc -tdss true}
} else {
    partition_design -tdc -tdss true
}
report_resource -depth 4

if {[env_or_default UVHS_STOP_AFTER_PARTITION 0]} {
    puts "INFO: UVHS_STOP_AFTER_PARTITION is set, stop before localization/route/FPGA compile"
    commit_runtime_data
    exit
}

instrument_design
localize_design -replicate_cell -clock -self_check
sweep_design -keep_feedthrough
localize_design -data
route_design
check_timing -verbose
report_system_performance -show_clock_relation -verbose
report_path -normalize -exception -tdr -net -rtl -max_path 100 -sort_by fmax

insert_tdm
reopt_design -verbose
bind_system
save_runtime_data

set_option compile.resourceUsageLimit [env_or_default UVHS_RESOURCE_USAGE_LIMIT 100]
set_option compile.strategyNumRetry [env_or_default UVHS_STRATEGY_NUM_RETRY 1]
set_option compile.strategy0 uv_placer_extra_timing_opt
set_option compile.strategy1 uv_placer_balance_slrs
set_option compile.strategy2 uv_high_fanout_explore
set_option compile.stage.preOpt ./script/pre_opt.tcl
set_option compile.stage.prePlace ./script/pre_place.tcl

compile_fpga -parallel_option fpga -genScriptOnly -explore
patch_timing_constraint_files
patch_vivado_wrappers
patch_vivado_makefiles
patch_vivado_pre_opt
patch_vivado_debug_file
patch_vivado_pre_place
patch_vivado_before_route
if {[env_or_default UVHS_STOP_AFTER_GENSCRIPT 0]} {
    puts "INFO: UVHS_STOP_AFTER_GENSCRIPT is set, stop after generated Vivado scripts are patched"
    exit
}
compile_fpga -parallel_option fpga -runOnly -explore

report_path -max_path 100
report_system_performance
commit_runtime_data
exit
