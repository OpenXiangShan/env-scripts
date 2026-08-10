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

proc uvhs_config_fill_rates {} {
    set lut_fill_rate [env_or_default UVHS_LUT_FILL_RATE none]
    set lut6_fill_rate [env_or_default UVHS_LUT6_FILL_RATE none]
    set args {}

    foreach {option value} [list -lut $lut_fill_rate -lut6 $lut6_fill_rate] {
        if {$value eq "none" || $value eq ""} {
            continue
        }
        if {![string is double -strict $value] || $value <= 0 || $value > 100} {
            error "$option fill rate must be in (0, 100], got '$value'"
        }
        lappend args $option $value
    }

    if {![llength $args]} {
        puts "INFO: keep platform default LUT fill rates"
        return
    }

    puts "INFO: set UVHS fill rates: $args"
    set_fill_rate {*}$args
}

proc uvhs_cpu_clk_period_ns {} {
    return [env_or_default UVHS_CPU_CLK_PERIOD_NS 40]
}

proc uvhs_cpu_debug_clk {} {
    return [expr {[env_or_default UVHS_CPU_DEBUG_CLK 1] eq "1"}]
}

proc uvhs_xdma_axi_clk_period_ns {} {
    return 8.000
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

proc uvhs_vivado_stage_hook_files {stage} {
    switch -- $stage {
        pre_opt { set rel_path user_pre_opt.tcl }
        pre_place { set rel_path user_pre_place.tcl }
        default {
            error "unsupported Vivado stage hook '$stage'"
        }
    }

    set files {}
    foreach pnr_dir [glob -nocomplain hw.dat/Compile/PnR/*/*] {
        set file [file join $pnr_dir $rel_path]
        if {[file exists $file]} {
            lappend files $file
        }
    }
    return $files
}

proc uvhs_xdma_gt_refclk_patch_script {stage} {
    return [string map [list __UVHS_STAGE__ $stage] {
puts "INFO: UVHS patch: keep XDMA GT refclk direct to IBUFDS_GTE4 before __UVHS_STAGE__"
set uvhs_xdma_refclk_ports {}
foreach uvhs_refclk_pattern {
    pcie_ep_gt_ref_clk_p_pad_net_*
    pcie_ep_gt_ref_clk_n_pad_net_*
    pcie_ep_gt_ref_clk_p
    pcie_ep_gt_ref_clk_n
} {
    foreach uvhs_port [get_ports -quiet $uvhs_refclk_pattern] {
        if {[lsearch -exact $uvhs_xdma_refclk_ports $uvhs_port] < 0} {
            lappend uvhs_xdma_refclk_ports $uvhs_port
        }
    }
}
if {[llength $uvhs_xdma_refclk_ports]} {
    catch {set_property IO_BUFFER_TYPE NONE $uvhs_xdma_refclk_ports} uvhs_iobuf_msg
    catch {set_property CLOCK_BUFFER_TYPE NONE $uvhs_xdma_refclk_ports} uvhs_clkbuf_msg
    puts "INFO: UVHS patch: XDMA GT refclk ports before __UVHS_STAGE__: $uvhs_xdma_refclk_ports"
} else {
    puts "WARNING: UVHS patch: XDMA GT refclk ports not found before __UVHS_STAGE__"
}

proc ::uvhs_xdma_gt_refclk_net_segments {uvhs_net} {
    set uvhs_segments {}
    if {$uvhs_net ne ""} {
        lappend uvhs_segments $uvhs_net
    }
    if {[catch {set uvhs_more_segments [get_nets -quiet -segments $uvhs_net]} uvhs_segment_msg]} {
        puts "WARNING: UVHS patch: get net segments for $uvhs_net failed: $uvhs_segment_msg"
    } else {
        foreach uvhs_segment $uvhs_more_segments {
            if {[lsearch -exact $uvhs_segments $uvhs_segment] < 0} {
                lappend uvhs_segments $uvhs_segment
            }
        }
    }
    return $uvhs_segments
}

proc ::uvhs_xdma_gt_refclk_input_pins {} {
    set uvhs_pins {}
    foreach uvhs_pattern {
        */core_def/xdma_ep_i/*IBUFDS_GTE4*/I
        */core_def/xdma_ep_i/*IBUFDS_GTE4_I/I
        */core_def/xdma_ep_i/util_ds_buf_0/*/I
    } {
        foreach uvhs_pin [get_pins -hier -quiet $uvhs_pattern] {
            if {[lsearch -exact $uvhs_pins $uvhs_pin] < 0} {
                lappend uvhs_pins $uvhs_pin
            }
        }
    }
    foreach uvhs_pin [get_pins -hier -quiet -filter {REF_PIN_NAME == I && NAME =~ */core_def/xdma_ep_i/*IBUFDS_GTE4*}] {
        if {[lsearch -exact $uvhs_pins $uvhs_pin] < 0} {
            lappend uvhs_pins $uvhs_pin
        }
    }
    return $uvhs_pins
}

proc ::uvhs_xdma_gt_refclk_pin_is_driven_by_bufg {uvhs_pin uvhs_bufg} {
    set uvhs_pin_net [lindex [get_nets -quiet -of_objects $uvhs_pin] 0]
    if {$uvhs_pin_net eq ""} {
        return 0
    }
    foreach uvhs_segment [::uvhs_xdma_gt_refclk_net_segments $uvhs_pin_net] {
        foreach uvhs_driver [get_pins -quiet -of_objects $uvhs_segment -filter {DIRECTION == OUT}] {
            set uvhs_driver_cell [lindex [get_cells -quiet -of_objects $uvhs_driver] 0]
            if {$uvhs_driver_cell eq $uvhs_bufg} {
                return 1
            }
        }
    }
    return 0
}

# DLP may insert a BUFGCE after opt_design, but IBUFDS_GTE4 must remain driven
# directly by the PCIe reference-clock port.  Repair only that generated path.
set uvhs_xdma_gt_input_pins [::uvhs_xdma_gt_refclk_input_pins]
if {[llength $uvhs_xdma_gt_input_pins]} {
    puts "INFO: UVHS patch: XDMA IBUFDS_GTE4 input pins before __UVHS_STAGE__: $uvhs_xdma_gt_input_pins"
} else {
    puts "WARNING: UVHS patch: no XDMA IBUFDS_GTE4 input pins found before __UVHS_STAGE__"
}
set uvhs_xdma_refclk_bufgs [get_cells -hier -quiet -filter {REF_NAME =~ BUFG* && NAME =~ *pcie_ep_gt_ref_clk*bufg*}]
if {[llength $uvhs_xdma_refclk_bufgs]} {
    puts "INFO: UVHS patch: found XDMA GT refclk BUFG cells before __UVHS_STAGE__: $uvhs_xdma_refclk_bufgs"
}
foreach uvhs_bufg $uvhs_xdma_refclk_bufgs {
    set uvhs_in_pins [get_pins -quiet ${uvhs_bufg}/I]
    set uvhs_out_pins [get_pins -quiet ${uvhs_bufg}/O]
    if {![llength $uvhs_in_pins] || ![llength $uvhs_out_pins]} {
        puts "WARNING: UVHS patch: skip $uvhs_bufg, missing I/O pins"
        continue
    }
    set uvhs_in_net [lindex [get_nets -quiet -of_objects [lindex $uvhs_in_pins 0]] 0]
    set uvhs_out_net [lindex [get_nets -quiet -of_objects [lindex $uvhs_out_pins 0]] 0]
    if {$uvhs_in_net eq "" || $uvhs_out_net eq ""} {
        puts "WARNING: UVHS patch: skip $uvhs_bufg, missing I/O nets"
        continue
    }

    set uvhs_gt_loads {}
    foreach uvhs_segment [::uvhs_xdma_gt_refclk_net_segments $uvhs_out_net] {
        foreach uvhs_load [get_pins -quiet -of_objects $uvhs_segment -filter {DIRECTION == IN}] {
            if {[string match *core_def/xdma_ep_i*IBUFDS_GTE4* $uvhs_load] || \
                [string match *core_def/xdma_ep_i/util_ds_buf_0* $uvhs_load]} {
                if {[lsearch -exact $uvhs_gt_loads $uvhs_load] < 0} {
                    lappend uvhs_gt_loads $uvhs_load
                }
            }
        }
    }
    foreach uvhs_gt_pin $uvhs_xdma_gt_input_pins {
        if {[::uvhs_xdma_gt_refclk_pin_is_driven_by_bufg $uvhs_gt_pin $uvhs_bufg] && \
            [lsearch -exact $uvhs_gt_loads $uvhs_gt_pin] < 0} {
            lappend uvhs_gt_loads $uvhs_gt_pin
        }
    }
    if {![llength $uvhs_gt_loads]} {
        puts "WARNING: UVHS patch: skip $uvhs_bufg, no XDMA IBUFDS_GTE4 loads on $uvhs_out_net"
        foreach uvhs_segment [::uvhs_xdma_gt_refclk_net_segments $uvhs_out_net] {
            puts "INFO: UVHS patch: pins on $uvhs_segment: [get_pins -quiet -of_objects $uvhs_segment]"
        }
        continue
    }

    foreach uvhs_load $uvhs_gt_loads {
        set uvhs_load_net [lindex [get_nets -quiet -of_objects $uvhs_load] 0]
        if {$uvhs_load_net eq ""} {
            puts "WARNING: UVHS patch: skip $uvhs_load, no connected net"
            continue
        }
        if {[catch {disconnect_net -net $uvhs_load_net -objects $uvhs_load} uvhs_disconnect_msg]} {
            puts "WARNING: UVHS patch: disconnect $uvhs_load_net -> $uvhs_load failed: $uvhs_disconnect_msg"
            continue
        }
        if {[catch {connect_net -hier -net $uvhs_in_net -objects $uvhs_load} uvhs_connect_msg]} {
            puts "WARNING: UVHS patch: connect $uvhs_in_net -> $uvhs_load failed: $uvhs_connect_msg"
        } else {
            puts "INFO: UVHS patch: rewired $uvhs_load from $uvhs_load_net to $uvhs_in_net"
        }
    }

    catch {disconnect_net -net $uvhs_in_net -objects [lindex $uvhs_in_pins 0]} uvhs_msg
    catch {disconnect_net -net $uvhs_out_net -objects [lindex $uvhs_out_pins 0]} uvhs_msg
    if {[info commands remove_cell] ne ""} {
        catch {remove_cell $uvhs_bufg} uvhs_remove_msg
    } elseif {[info commands delete_cells] ne ""} {
        catch {delete_cells $uvhs_bufg} uvhs_remove_msg
    }
    puts "INFO: UVHS patch: bypassed XDMA GT refclk BUFG $uvhs_bufg"
}
}]
}

proc uvhs_write_xdc_patch_script {} {
    set async_file [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]]
    set script [format {
proc ::uvhs_create_ddr_ui_clock_patch {} {
    foreach {uvhs_name uvhs_patterns} {
        DDR_UI_CLK {
            part_2/core_def/U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
            */U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
        }
        DDR_UI_CLK_TRACE_CH0 {
            part_2/core_def/U_CPU_TRACE/U_CPU_TRACE_CH0_DDR/ddr4ip_ddr4_user_clk
            */U_CPU_TRACE/U_CPU_TRACE_CH0_DDR/ddr4ip_ddr4_user_clk
        }
        DDR_UI_CLK_TRACE_CH1 {
            part_1/core_def/U_CPU_TRACE/U_CPU_TRACE_CH1_DDR/ddr4ip_ddr4_user_clk
            */U_CPU_TRACE/U_CPU_TRACE_CH1_DDR/ddr4ip_ddr4_user_clk
        }
    } {
        if {[llength [get_clocks -quiet $uvhs_name]] > 0} {
            continue
        }
        set uvhs_pins {}
        foreach uvhs_pattern $uvhs_patterns {
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
            create_clock -period 5.000 -name $uvhs_name -waveform {0.000 2.500} -add [lindex $uvhs_pins 0]
            puts "INFO: UVHS patch: create $uvhs_name on UVHS DDR user clock [lindex $uvhs_pins 0]"
        }
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

    if {[string match *pnr_timing_constraints_preopt.xdc $uvhs_xdc_file] || \
        [string match *pnr_timing_constraints.xdc $uvhs_xdc_file]} {
        # Partitioning can serialize a replicated SoC clock gate as an unrelated
        # primary clock.  Preserve its original CPU_CLK_IN relationship.
        set uvhs_lines {}
        foreach uvhs_line [split $uvhs_patched "\n"] {
            # UVHS temporarily falsifies slow DUT setup clocks while it
            # budgets the partition boundary.  Its generated constraint also
            # includes the source clock itself in the destination collection,
            # which hides every same-clock DUT setup path from Vivado PnR.
            # Keep only the intended DUT-to-virtual-boundary exception so the
            # CPU and other owned logic remain timing-driven and signoff-clean.
            if {[regexp {^[[:space:]]*set_false_path[[:space:]]+-setup[[:space:]]+-from[[:space:]]+\[get_clocks[[:space:]]+([^]]+)\][[:space:]]+-to[[:space:]]+\[get_clocks[[:space:]]+([^]]+)\][[:space:]]*$} \
                    $uvhs_line -> uvhs_setup_from uvhs_setup_to]} {
                set uvhs_setup_from [string trim $uvhs_setup_from " \t{}"]
                set uvhs_setup_to [string trim $uvhs_setup_to " \t{}"]
            }
            if {[info exists uvhs_setup_from] && \
                [lsearch -exact $uvhs_setup_to $uvhs_setup_from] >= 0} {
                if {$uvhs_setup_from eq "clock_vir_UV"} {
                    puts "INFO: UVHS patch: drop virtual-clock self setup false path"
                    continue
                }
                if {[lsearch -exact $uvhs_setup_to clock_vir_UV] >= 0} {
                    set uvhs_line [format {set_false_path -setup -from [get_clocks %%s] -to [get_clocks clock_vir_UV]} \
                        $uvhs_setup_from]
                    puts "INFO: UVHS patch: preserve $uvhs_setup_from same-clock setup timing"
                }
            }
            unset -nocomplain uvhs_setup_from uvhs_setup_to
            if {[string first {-name SOC_GATED_CLK} $uvhs_line] >= 0 && \
                [regexp {^create_clock[^\n]*\[get_pins[[:space:]]+([^]]+)/O\]} \
                    $uvhs_line -> uvhs_soc_bufg]} {
                # The replicated BUFG I is driven from a localized clock port,
                # so using it as -source makes Vivado serialize SOC_GATED_CLK
                # as an unrelated primary clock.  Anchor the generated clock
                # to CPU_CLK_IN's real partition input port instead.
                set uvhs_line [format {create_generated_clock -name SOC_GATED_CLK -source [get_ports [get_property SOURCE_PINS [get_clocks CPU_CLK_IN]]] -divide_by 1 -add -master_clock [get_clocks CPU_CLK_IN] [get_pins %%s/O]} \
                    $uvhs_soc_bufg]
                puts "INFO: UVHS patch: restore replicated SOC_GATED_CLK from CPU_CLK_IN source port on $uvhs_soc_bufg"
            }
            lappend uvhs_lines $uvhs_line
        }
        set uvhs_patched [join $uvhs_lines "\n"]

        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $uvhs_patched {create_clock -period __UVHS_XDMA_AXI_CLK_PERIOD_NS__ -name XDMA_AXI_ACLK -waveform [list 0 [expr __UVHS_XDMA_AXI_CLK_PERIOD_NS__ / 2.0]] -add [get_pins part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK]} uvhs_patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer} $uvhs_patched {XDMA_AXI_ACLK} uvhs_patched
        if {[string first {U_UVHS_UVW_AXI4_TO_DDR4} $uvhs_patched] >= 0 && \
            [string first {UVHS patch: create DDR_UI_CLK on UVHS DDR user clock} $uvhs_patched] < 0} {
            append uvhs_patched "\n::uvhs_create_ddr_ui_clock_patch\n"
        }
        if {[string first {set ::uvhs_async_clocks_loaded 1} $uvhs_patched] < 0} {
            append uvhs_patched "\nset ::uvhs_async_clocks_loaded 1\n"
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
            if {[string match *pnr_timing_constraints_preopt.xdc $uvhs_arg] || \
                [string match *pnr_timing_constraints.xdc $uvhs_arg]} {
                ::uvhs_patch_xdma_preopt_xdc $uvhs_arg
            }
            if {[string match *pnr_timing_constraints_preopt.xdc $uvhs_arg] && \
                ![info exists ::uvhs_preopt_timing_reloaded]} {
                # write_xdc serialized the complete pre-opt timing state, and
                # the patch above repaired clocks that partitioning emitted as
                # unrelated primary clocks.  Reload it once so the repaired
                # clock objects replace the stale in-memory objects before
                # opt_design; otherwise the fixed XDC only affects the file.
                set ::uvhs_preopt_timing_reloaded 1
                puts "INFO: UVHS patch: reload repaired pre-opt timing constraints from $uvhs_arg"
                reset_timing
                # The serialized file intentionally ends with our Tcl helpers
                # for DDR clocks and async clock groups.  `read_xdc` rejects
                # those commands; source executes both ordinary XDC commands
                # and the appended helpers in the same design context.
                uplevel #0 [list source $uvhs_arg]
            }
        }
        return -options $uvhs_options $uvhs_result
    }
    puts "INFO: UVHS patch: wrapped write_xdc to patch generated XDMA preopt constraints"
}
} $async_file $async_file $async_file]
    return [string map [list __UVHS_XDMA_AXI_CLK_PERIOD_NS__ [uvhs_xdma_axi_clk_period_ns]] $script]
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

proc create_ddr_ui_clocks_if_exist {} {
    foreach {name pin_patterns} {
        DDR_UI_CLK {
            core_def/U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
            */U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk
        }
        DDR_UI_CLK_TRACE_CH0 {
            core_def/U_CPU_TRACE/U_CPU_TRACE_CH0_DDR/ddr4ip_ddr4_user_clk
            */U_CPU_TRACE/U_CPU_TRACE_CH0_DDR/ddr4ip_ddr4_user_clk
        }
        DDR_UI_CLK_TRACE_CH1 {
            core_def/U_CPU_TRACE/U_CPU_TRACE_CH1_DDR/ddr4ip_ddr4_user_clk
            */U_CPU_TRACE/U_CPU_TRACE_CH1_DDR/ddr4ip_ddr4_user_clk
        }
    } {
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
            puts "INFO: skip create_clock $name, missing UVHS DDR user clock pin"
            continue
        }

        set pin [lindex $pins 0]
        set clocks [get_clocks -quiet -of_objects $pin]
        if {[llength $clocks]} {
            puts "INFO: DDR UI pin $pin already has clocks: $clocks"
            continue
        }

        run_or_warn "create_clock $name on $pin" \
            [list create_clock -name $name -per 5.000 $pin]
    }
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
        [list create_generated_clock -add -name $name -master_clock $master_clock -source $in_pins -divide_by 1 $out_pins]
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

proc uvhs_guard_vendor_ip_false_paths {pre_opt} {
    set fh [open $pre_opt r]
    set data [read $fh]
    close $fh

    # The platform template can emit an IP-internal PCIe reset exception for
    # every FPGA even when that partition contains no PCIe instance. Vivado
    # treats set_false_path with an empty object set as an error. Guard only
    # these vendor-IP targets; do not weaken fpga_diff-owned RTL constraints.
    set uvhs_lines {}
    set uvhs_guarded_ip_false_paths 0
    foreach uvhs_line [split $data "\n"] {
        if {[regexp {^[[:space:]]*set_false_path[[:space:]]+-to[[:space:]]+\[get_pins[[:space:]]+([^]]*u_pcie_wrapper[^]]*)\][[:space:]]*$} \
                $uvhs_line -> uvhs_ip_pin_pattern]} {
            lappend uvhs_lines [format {set uvhs_ip_false_path_pins [get_pins -quiet {%s}]} $uvhs_ip_pin_pattern]
            lappend uvhs_lines {if {[llength $uvhs_ip_false_path_pins]} {
    set_false_path -to $uvhs_ip_false_path_pins
    puts "INFO: UVHS patch: applied vendor PCIe IP reset false path to $uvhs_ip_false_path_pins"
} else {
    puts "INFO: UVHS patch: skip absent vendor PCIe IP reset false-path target"
}}
            incr uvhs_guarded_ip_false_paths
        } else {
            lappend uvhs_lines $uvhs_line
        }
    }
    if {$uvhs_guarded_ip_false_paths} {
        set fh [open $pre_opt w]
        puts -nonewline $fh [join $uvhs_lines "\n"]
        close $fh
        puts "INFO: guarded $uvhs_guarded_ip_false_paths vendor PCIe IP false path(s): $pre_opt"
    }
}

proc uvhs_guard_vendor_pcie_pblock {pre_place} {
    set fh [open $pre_place r]
    set data [read $fh]
    close $fh

    set uvhs_get_cells {[get_cells [list part_3/xs_core_def/u_pcie_wrapper/inst/u_xilinx_pcie_phy_x4]]}
    if {[string first $uvhs_get_cells $data] < 0 ||
        [string first {set uvhs_vendor_pcie_cells [get_cells -quiet} $data] >= 0} {
        return
    }
    set uvhs_patched $data
    set uvhs_lines {}
    set uvhs_vendor_if_line [format {if {$current_fpga == "b0.f3"} %s} "\{"]
    foreach uvhs_line [split $uvhs_patched "\n"] {
        if {[string trim $uvhs_line] eq $uvhs_vendor_if_line} {
            lappend uvhs_lines {set uvhs_vendor_pcie_cells [get_cells -quiet {part_3/xs_core_def/u_pcie_wrapper/inst/u_xilinx_pcie_phy_x4}]}
            lappend uvhs_lines [format {if {$current_fpga == "b0.f3" && [llength $uvhs_vendor_pcie_cells]} %s} "\{"]
        } else {
            lappend uvhs_lines [string map \
                [list $uvhs_get_cells {$uvhs_vendor_pcie_cells}] $uvhs_line]
        }
    }
    set uvhs_patched [join $uvhs_lines "\n"]
    set fh [open $pre_place w]
    puts -nonewline $fh $uvhs_patched
    close $fh
    puts "INFO: guarded absent vendor PCIe IP pblock target: $pre_place"
}

proc patch_vivado_pre_opt {} {
    set write_xdc_patch_script [uvhs_write_xdc_patch_script]
    set xdma_cdc_script {
puts "INFO: UVHS patch: source XDMA CDC attributes before opt_design"
set uvhs_xdma_cdc_script [file join $FILE_DIR xdma_cdc_attributes.tcl]
if {[file exists $uvhs_xdma_cdc_script]} {
    source $uvhs_xdma_cdc_script
} else {
    puts "WARNING: UVHS patch: missing XDMA CDC attribute script $uvhs_xdma_cdc_script"
    }
}
    set async_script [uvhs_async_clock_patch_script]
    foreach platform_pre_opt [glob -nocomplain \
            hw.dat/Compile/PnR/*/*/user_stage_tcl/preOpt_pre_opt.tcl] {
        uvhs_guard_vendor_ip_false_paths $platform_pre_opt
    }
    foreach pre_opt [uvhs_vivado_stage_hook_files pre_opt] {
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
        if {[string first "UVHS patch: source XDMA CDC attributes before opt_design" $data] < 0} {
            set fh [open $pre_opt a]
            puts $fh ""
            puts $fh $xdma_cdc_script
            close $fh
            append data "\n" $xdma_cdc_script
            puts "INFO: patched Vivado pre-opt XDMA CDC attributes: $pre_opt"
        }
        if {[string first "UVHS patch: source async clock groups" $data] < 0} {
            set fh [open $pre_opt a]
            puts $fh ""
            puts $fh $async_script
            close $fh
            puts "INFO: patched Vivado pre-opt async clocks: $pre_opt"
        }
    }
}

proc patch_vivado_pre_place {} {
    set refclk_patch_script [uvhs_xdma_gt_refclk_patch_script "place"]
    set script {
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
puts "INFO: UVHS patch: fix known bitstream DRCs"
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
}
    append script "\n" $refclk_patch_script
    append script [uvhs_async_clock_patch_script]
    foreach platform_pre_place [glob -nocomplain \
            hw.dat/Compile/PnR/*/*/user_stage_tcl/prePlace_pre_place.tcl] {
        uvhs_guard_vendor_pcie_pblock $platform_pre_place
    }
    foreach pre_place [uvhs_vivado_stage_hook_files pre_place] {
        set fh [open $pre_place r]
        set data [read $fh]
        close $fh
        if {[string first "UVHS patch: set XDMA PCIe hard block" $data] < 0} {
            set fh [open $pre_place a]
            puts $fh ""
            puts $fh $script
            close $fh
            puts "INFO: patched Vivado pre-place constraints: $pre_place"
        }
    }
}

proc patch_vivado_before_route {} {
    set script ""
    set hold_expn_bailout [env_or_default UVHS_ROUTE_ENABLE_HOLD_EXPN_BAILOUT ""]
    if {$hold_expn_bailout ne ""} {
        if {$hold_expn_bailout ni {0 1}} {
            error "UVHS_ROUTE_ENABLE_HOLD_EXPN_BAILOUT must be empty, 0, or 1; got '$hold_expn_bailout'"
        }
        append script "\nputs \"INFO: UVHS patch: set route.enableHoldExpnBailout=$hold_expn_bailout before route\"\n"
        append script "set_param route.enableHoldExpnBailout $hold_expn_bailout\n"
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
        if {[string first "UVHS patch: source async clock groups" $data] < 0} {
            set fh [open $before_route a]
            puts $fh ""
            puts $fh $script
            close $fh
            puts "INFO: patched Vivado before-route settings: $before_route"
        }
    }
}

proc patch_timing_constraint_files {} {
    set xdma_axi_clk_period [uvhs_xdma_axi_clk_period_ns]
    set xdma_axi_clk_half_period [format %.3f [expr {$xdma_axi_clk_period / 2.0}]]
    set xdma_blackbox_clock_replacement [format {
create_clock -period %.3f -name XDMA_AXI_ACLK -waveform {0.000 %.3f} -add [get_pins part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK]} \
        $xdma_axi_clk_period $xdma_axi_clk_half_period]
    set difftest_clock_token_pattern {(^|[^[:alnum:]_])DIFFTEST_PCIE_CLK([^[:alnum:]_]|$)}
    set async_xdc_block [format {

set ::uvhs_async_clocks_loaded 1
if {[file exists {%s}]} {
    source {%s}
} else {
    puts "WARNING: UVHS patch: missing async clock file %s"
}
} [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]] \
  [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]] \
  [file normalize [file join $::fpga_diff_uvhs_dir async_clocks.tcl]]]

    foreach file [glob -nocomplain hw.dat/Compile/PnR/*/*/timing_settings.tcl] {
        set fh [open $file r]
        set data [read $fh]
        close $fh
        set patched $data
        set old_block {foreach clk [get_clocks $falsifyDutClocks] {
            set_false_path -setup -from [get_clocks $clk] -to [get_clocks "$clk clock_vir_UV"]
        }}
        set new_block {foreach clk [get_clocks $falsifyDutClocks] {
            # Keep DUT-to-virtual partition budgeting, but never falsify the
            # owned DUT's same-clock setup paths.
            if {$clk eq "clock_vir_UV"} {
                continue
            }
            set_false_path -setup -from [get_clocks $clk] -to [get_clocks clock_vir_UV]
        }}
        if {[string first $old_block $patched] >= 0} {
            set patched [string map [list $old_block $new_block] $patched]
        }
        if {$patched ne $data} {
            set fh [open $file w]
            puts -nonewline $fh $patched
            close $fh
            puts "INFO: patched UVHS DUT same-clock setup timing constraints: $file"
        }
    }

    foreach file [glob -nocomplain hw.dat/Compile/PnR/*/*/timing_constraints.tcl] {
        set fh [open $file r]
        set data [read $fh]
        close $fh
        set patched $data

        set xdma_axi_primary_clock [format {
puts "WARNING: \[APS CSTR-1\] primary clock is defined on blackbox boundary which may cause inaccurate skew analysis."
create_clock -add -name XDMA_AXI_ACLK -period [expr $uvCstrRatio * %.3f + $uvCstrMargin] -waveform [list 0 [expr ($uvCstrRatio + $uvCstrMargin / %.3f) * %.3f]] [get_pins { part_2/core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK }]
variable XDMA_AXI_ACLK_name [get_property NAME [get_clocks XDMA_AXI_ACLK]]
} $xdma_axi_clk_period $xdma_axi_clk_period $xdma_axi_clk_half_period]
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
                $patched $xdma_axi_primary_clock patched
        }
        regsub -all {create_clock[^\n]*-name[^\n]*DIFFTEST_PCIE_CLK[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $patched $xdma_axi_primary_clock patched
        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $patched $xdma_axi_primary_clock patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer_name} $patched {XDMA_AXI_ACLK_name} patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer} $patched {XDMA_AXI_ACLK} patched
        regsub -all {DIFFTEST_PCIE_CLK_name} $patched {XDMA_AXI_ACLK_name} patched
        regsub -all $difftest_clock_token_pattern $patched {\1XDMA_AXI_ACLK\2} patched
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

        regsub -all {create_clock[^\n]*-name[^\n]*DIFFTEST_PCIE_CLK[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $patched $xdma_blackbox_clock_replacement patched
        regsub -all {create_generated_clock[^\n]*-name[^\n]*core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer[^\n]*TO_DIFFTEST_PCIE_CLK[^\n]*} \
            $patched $xdma_blackbox_clock_replacement patched
        regsub -all {core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer} $patched {XDMA_AXI_ACLK} patched
        regsub -all $difftest_clock_token_pattern $patched {\1XDMA_AXI_ACLK\2} patched
        if {[string first {set ::uvhs_async_clocks_loaded 1} $patched] < 0} {
            append patched $async_xdc_block
        }
        if {$patched ne $data} {
            set fh [open $file w]
            puts -nonewline $fh $patched
            close $fh
            puts "INFO: patched Vivado DIFFTEST PCIe / DDR UI clock timing constraints: $file"
        }
    }

}

proc patch_xdma_gt_refclk_pad_constraints {} {
    foreach file [concat \
        [glob -nocomplain hw.dat/Compile/PnR/*/*/pin_assign.xdc] \
        [glob -nocomplain hw.dat/Compile/PnR/*/*/dlp.xdc]] {
        set fh [open $file r]
        set data [read $fh]
        close $fh
        if {[string first {set ::uvhs_xdma_gt_refclk_pad_constraints 1} $data] >= 0} {
            continue
        }

        set p_ports [regexp -inline -all {pcie_ep_gt_ref_clk_p_pad_net_[0-9]+} $data]
        set n_ports [regexp -inline -all {pcie_ep_gt_ref_clk_n_pad_net_[0-9]+} $data]
        set refclk_ports {}
        foreach port [concat $p_ports $n_ports] {
            if {[lsearch -exact $refclk_ports $port] < 0} {
                lappend refclk_ports $port
            }
        }
        if {![llength $refclk_ports]} {
            continue
        }

        set block "\nset ::uvhs_xdma_gt_refclk_pad_constraints 1\n"
        foreach port $refclk_ports {
            append block "set_property IO_BUFFER_TYPE NONE \[get_ports -quiet {$port}\]\n"
            append block "set_property CLOCK_BUFFER_TYPE NONE \[get_ports -quiet {$port}\]\n"
        }
        set patched $data
        if {[regexp {set_property PACKAGE_PIN [^\n]+pcie_ep_gt_ref_clk_[pn]_pad_net_[0-9]+[^\n]*} $patched first_refclk_line]} {
            set idx [string first $first_refclk_line $patched]
            set patched [string range $patched 0 [expr {$idx - 1}]]
            append patched $block $first_refclk_line
            append patched [string range $data [expr {$idx + [string length $first_refclk_line]}] end]
        } else {
            append patched $block
        }
        set fh [open $file w]
        puts -nonewline $fh $patched
        close $fh
        puts "INFO: patched XDMA GT refclk pad constraints: $file"
    }
}

proc patch_xdma_cdc_attribute_constraints {} {
    foreach pnr_dir [glob -nocomplain hw.dat/Compile/PnR/*/*] {
        set script [file join $pnr_dir xdma_cdc_attributes.tcl]
        set fh [open $script w]
        puts $fh {
# These patterns cover synchronizers owned by the fixed XDMA IP.  They do not
# suppress or false-path CDC issues in fpga_diff-owned RTL.
proc ::uvhs_xdma_mark_cdc_cells {uvhs_label uvhs_patterns} {
    set uvhs_cells {}
    foreach uvhs_pattern $uvhs_patterns {
        foreach uvhs_cell [get_cells -hier -quiet -filter "IS_SEQUENTIAL && NAME =~ $uvhs_pattern"] {
            if {[lsearch -exact $uvhs_cells $uvhs_cell] < 0} {
                lappend uvhs_cells $uvhs_cell
            }
        }
    }
    if {[llength $uvhs_cells]} {
        set_property ASYNC_REG TRUE $uvhs_cells
    }
    puts "INFO: UVHS patch: XDMA CDC category $uvhs_label ASYNC_REG count=[llength $uvhs_cells]"
    return $uvhs_cells
}

set uvhs_xdma_cdc_cells {}
foreach {uvhs_label uvhs_patterns} {
    auto_cc_clock_conv_lite {
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/gen_clock_conv.gen_async_lite_conv*/clock_conv_lite_*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/gen_clock_conv.gen_async_lite_conv*/clock_conv_lite_*/handshake/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*clock_conv_lite*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*handshake*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*cdc*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*sync*/*_reg*
    }
    auto_cc_xpm_cdc {
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/*xpm_cdc*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/*xpm_cdc*/inst/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*xpm_cdc*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*xpm_cdc*/inst/*_reg*
    }
    xdma_reset_and_link {
        */core_def/xdma_ep_i/xdma_0/inst/*/*cdc*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/*cdc*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/xpm_cdc*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/xpm_cdc*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/arststages_ff_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/*user_rst*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/udma_wrapper/dma_top/user_rst*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/udma_wrapper/dma_top/*user_rst*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*cdc*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*cdc*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*sync*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*sync*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*rst*sync*reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*reset*sync*reg*
    }
} {
    foreach uvhs_cell [::uvhs_xdma_mark_cdc_cells $uvhs_label $uvhs_patterns] {
        if {[lsearch -exact $uvhs_xdma_cdc_cells $uvhs_cell] < 0} {
            lappend uvhs_xdma_cdc_cells $uvhs_cell
        }
    }
}

if {[llength $uvhs_xdma_cdc_cells]} {
    set_property ASYNC_REG TRUE $uvhs_xdma_cdc_cells
    puts "INFO: UVHS patch: marked XDMA CDC cells ASYNC_REG count=[llength $uvhs_xdma_cdc_cells]"
} else {
    puts "INFO: UVHS patch: no XDMA CDC cells matched for ASYNC_REG annotation"
}
}
        close $fh
        puts "INFO: wrote XDMA CDC attribute script: $script"

        foreach hook_name {before_link.tcl pre_link.tcl} {
            set hook [file join $pnr_dir $hook_name]
            if {![file exists $hook]} {
                continue
            }
            set fh [open $hook r]
            set data [read $fh]
            close $fh
            set patched $data
            regsub -all {\nadd_file \$FILE_DIR/xdma_cdc_attributes\.xdc} $patched "" patched
            regsub -all {\nsource \$FILE_DIR/xdma_cdc_attributes\.tcl} $patched "" patched
            if {$patched ne $data} {
                set fh [open $hook w]
                puts -nonewline $fh $patched
                close $fh
                puts "INFO: removed pre-link XDMA CDC attribute hook: $hook"
            }
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
set uvhs_time_group_io_logic [env_or_default UVHS_TIME_GROUP_IO_LOGIC default]
if {$uvhs_time_group_io_logic ne "default"} {
    if {$uvhs_time_group_io_logic ni {0 1 false true}} {
        error "UVHS_TIME_GROUP_IO_LOGIC must be one of default/0/1/false/true, got '$uvhs_time_group_io_logic'"
    }
    puts "INFO: set time.group_io_logic=$uvhs_time_group_io_logic"
    set_option time.group_io_logic $uvhs_time_group_io_logic
}

set design_name [env_or_default UVHS_DESIGN_NAME VU19P_X4]
set platform [env_or_default PLATFORM U2.2]
create_system_design -name $design_name -platform $platform
source_if_exists [env_or_default UVHS_ASSEMBLE_FILE ./script/1B_4F_HGC_assemble.tcl]
set assign_pin_file [env_or_default UVHS_ASSIGN_PIN_FILE ./script/assign_pin.tcl]
if {[file exists $assign_pin_file]} {
    set ::env(UVHS_ASSIGN_PIN_TOP) none
    source_if_exists $assign_pin_file
    unset -nocomplain ::env(UVHS_ASSIGN_PIN_TOP)
} else {
    error "missing pin assignment file: $assign_pin_file"
}
source_if_exists [env_or_default UVHS_PIN_OVERRIDE_FILE none]

create_design -name test
read_netlist
link_design
report_resource -depth 4

instrument_design
sanitize_design
check_design
init_runtime_data
trigger_probe -check
sweep_design

create_clock_if_port_exists TMCLK 1000 clk8_p
create_clock_if_port_exists ddr_ref_clk 12.5 clk7_p
if {[uvhs_cpu_debug_clk]} {
    create_clock_if_port_exists CPU_CLK_IN [uvhs_cpu_clk_period_ns] clk5_p
} else {
    create_clock_if_port_exists CPU_CLK_IN [uvhs_cpu_clk_period_ns] clk6_p
    create_clock_if_port_exists DEBUG_CLK_IN 40 clk5_p
}
create_clock_if_port_exists jtag_vclk 83.333 JTAG_TCK
create_clock_if_port_exists pcie_ep_refclk 10 pcie_ep_gt_ref_clk_p
create_generated_clock_if_bufgce_exists SOC_GATED_CLK CPU_CLK_IN {
    *SOC_CLK_CTRL*bufgce*
    *inter_soc_clk*
}
create_generated_clock_if_bufgce_exists RTC_GATED_CLK TMCLK {
    *RTC_CLK_CTRL*bufgce*
    *inter_rtc_clk*
}
create_blackbox_output_clock_if_pin_exists XDMA_AXI_ACLK [uvhs_xdma_axi_clk_period_ns] core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK
create_ddr_ui_clocks_if_exist
foreach uvhs_localize_clock [split [env_or_default UVHS_LOCALIZE_CLOCKS ""]] {
    set uvhs_localize_clock [string trim $uvhs_localize_clock]
    if {$uvhs_localize_clock eq ""} {
        continue
    }
    set uvhs_localize_clock_obj [get_clocks -quiet $uvhs_localize_clock]
    if {[llength $uvhs_localize_clock_obj] != 1} {
        error "UVHS_LOCALIZE_CLOCKS entry must resolve to exactly one clock, got [llength $uvhs_localize_clock_obj]: '$uvhs_localize_clock'"
    }
    puts "INFO: localize cross-FPGA clock network: $uvhs_localize_clock_obj"
    config_clock -localize $uvhs_localize_clock_obj
}
config_clock -check
run_or_warn "infer_clock" {infer_clock}
run_or_warn "report_clock -inferred" {report_clock -inferred}
source_if_exists [file normalize [file join [file dirname [info script]] async_clocks.tcl]]
run_or_warn "transform_clock" {transform_clock}
source_if_exists [file normalize [file join [file dirname [info script]] async_clocks.tcl]]
uvhs_config_fill_rates
uvhs_config_probe_group_resource
trigger_probe -group
sweep_design -remap
report_clock

check_design
report_resource -depth 4
report_system_resource
list_partition_constraints -all
partition_design -tdc -tdss true
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
set strategy_num_retry [env_or_default UVHS_STRATEGY_NUM_RETRY none]
if {$strategy_num_retry eq "none" || $strategy_num_retry eq "0"} {
    puts "INFO: skip compile.strategyNumRetry"
} else {
    run_or_warn "set_option compile.strategyNumRetry" \
        [list set_option compile.strategyNumRetry $strategy_num_retry]
}

set compile_strategy_num [env_or_default UVHS_COMPILE_STRATEGY_NUM 1]
if {![string is integer -strict $compile_strategy_num] || $compile_strategy_num < 1} {
    error "UVHS_COMPILE_STRATEGY_NUM must be a positive integer, got '$compile_strategy_num'"
}
set_option compile.strategyNum $compile_strategy_num
set default_compile_strategies {
    uv_high_fanout_explore
    uv_placer_balance_slrs
    uv_placer_extra_timing_opt
}
for {set i 0} {$i < $compile_strategy_num} {incr i} {
    set default_strategy ""
    if {$i < [llength $default_compile_strategies]} {
        set default_strategy [lindex $default_compile_strategies $i]
    }
    set strategy [env_or_default [format {UVHS_COMPILE_STRATEGY%d} $i] $default_strategy]
    if {$strategy eq "" || $strategy eq "none"} {
        error "missing compile strategy $i; set UVHS_COMPILE_STRATEGY$i"
    }
    puts "INFO: UVHS compile.strategy$i=$strategy"
    set_option [format {compile.strategy%d} $i] $strategy
}
set_option compile.stage.preOpt ./script/pre_opt.tcl
set_option compile.stage.prePlace ./script/pre_place.tcl

compile_fpga -parallel_option fpga -genScriptOnly -explore
# The Hejian flow emits the final Vivado hooks only after genScriptOnly.
# Patch those generated files before starting the implementation run.
patch_timing_constraint_files
patch_xdma_gt_refclk_pad_constraints
patch_xdma_cdc_attribute_constraints
patch_vivado_wrappers
patch_vivado_makefiles
patch_vivado_pre_opt
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
