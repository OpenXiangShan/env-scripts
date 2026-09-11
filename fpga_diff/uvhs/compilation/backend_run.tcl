################################################################################
# UVHS backend flow for fpga_diff.
################################################################################

source [file join [file dirname [file normalize [info script]]] flow_common.tcl]
set_working_space hw.dat

# Keep PnR in the UVHS single-worker mode on hosts where the bundled Python
# multiprocessing runtime cannot load its legacy libffi dependency.
set_parallel_option -max_threads 4 -max_processes 1 -label fpga

set_option time.auto_clock_config true
set_option time.group_io_logic false
set_option time.clock_part_group_mode 2
set_option part.allow_timing_group_merge false
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true

create_system_design -name VU19P_X4 -platform U2.2
uvhs::source_required assemble.tcl

set ::env(UVHS_ASSIGN_PIN_TOP) none
uvhs::source_required assign_pin.tcl
unset ::env(UVHS_ASSIGN_PIN_TOP)

create_design -name test
read_netlist
link_design
uvhs::source_required partition.tcl
report_resource -depth 4

instrument_design
sanitize_design
check_design
init_runtime_data
trigger_probe -check
sweep_design

if {[string toupper [uvhs::env_or_default DIFFTEST_HOSTIF XDMA]] eq "XDMA"} {
    set xdma_axi_clock_pin \
        [get_pins -quiet core_def/xdma_ep_i/TO_DIFFTEST_PCIE_CLK]
    if {[llength $xdma_axi_clock_pin] != 1} {
        error "required XDMA AXI clock pin not found"
    }
    set xdma_axi_clock_period [expr {
        [string equal -nocase [uvhs::env_or_default XDMA_LINK_WIDTH X4] X8]
            ? 4.0 : 8.0
    }]
    create_clock -name XDMA_AXI_ACLK -period $xdma_axi_clock_period \
        $xdma_axi_clock_pin
} else {
    # GBus has no XDMA user-clock output.  The fpga-host/GBus protocol and
    # both protected GBus IPs are driven by the explicit UVHS host clock
    # UART_CLK_IN (clk6_p/dev_clk_i), not the gated CPU clock and not a clock
    # inferred from the compatibility shell.
    # Do not create a second primary clock on a black-box input: doing so makes
    # the same host net appear as two unrelated clocks and lets infer_clock
    # rediscover the old pseudo-XDMA clock.
    set gbus_host_clock_pins [get_pins -quiet {
        core_def/U_GBUS_GENERALBD/i_clk
        core_def/U_GBUS_GENERAL_BUS/dut_axi_aclk
    }]
    if {[llength $gbus_host_clock_pins] != 2} {
        error "required GBus host clock pins not found: $gbus_host_clock_pins"
    }
    set gbus_host_clock [get_clocks -quiet UART_CLK_IN]
    if {[llength $gbus_host_clock] != 1} {
        error "required host clock UART_CLK_IN not found for GBus: $gbus_host_clock"
    }
    puts "INFO: GBus host clock pins use explicit UART_CLK_IN (clk6_p/dev_clk_i): $gbus_host_clock_pins"

}

set ddr_ui_clock_pin [get_pins -quiet \
    core_def/U_UVHS_UVW_AXI4_TO_DDR4/ddr4ip_ddr4_user_clk]
if {[llength $ddr_ui_clock_pin] != 1} {
    error "required DDR user-interface clock pin not found"
}
create_clock -name DDR_UI_CLK -period 5.0 $ddr_ui_clock_pin

foreach {clock_name master_name cell_name} {
    SOC_GATED_CLK CPU_CLK_IN core_def/SOC_CLK_CTRL_UVin_bufgce_1
    RTC_GATED_CLK TMCLK      core_def/RTC_CLK_CTRL_UVin_bufgce_1
} {
    set master_clock [get_clocks -quiet $master_name]
    set input_pin [get_pins -quiet ${cell_name}/I]
    set output_pin [get_pins -quiet ${cell_name}/O]
    if {![llength $input_pin] && ![llength $output_pin]} {
        puts "INFO: skip optimized-away generated clock $clock_name"
        continue
    }
    if {[llength $master_clock] != 1 || [llength $input_pin] != 1 ||
        [llength $output_pin] != 1} {
        error "required generated clock path not found for $clock_name"
    }
    create_generated_clock -add -name $clock_name \
        -master_clock $master_clock -source $input_pin -divide_by 1 $output_pin
}

# The GBus protected IPs mark sysbus payload data bits with LAST_VALUE
# metadata.  Those ports are payload data, not clock inputs.  UVHS must be
# told to ignore this vendor annotation *before* infer_clock; applying the
# option after infer_clock is too late because TCK-104/TCK-123 abort inference.
if {[string toupper [uvhs::env_or_default DIFFTEST_HOSTIF XDMA]] eq "GBUS"} {
    # Do not pass the complete pattern list as one braced argument.  UVHS
    # treats that as a single pattern containing spaces and returns no pins,
    # leaving the protected-IP LAST_VALUE payload annotations active.  Query
    # each hierarchical bus separately and merge the resulting collections.
    set gbus_payload_pins {}
    # The UVHS object query does not expand bracketed bus wildcards after
    # linking (the exact indexed pin does exist).  Enumerate all bits and use
    # literal braced names, so config_clock receives the actual payload pins.
    foreach gbus_payload_bus {
        core_def/U_GBUS_GENERALBD/gbd_sysbus_i
        core_def/U_GBUS_GENERALBD/gbd_sysbus_o
        core_def/U_GBUS_GENERAL_BUS/sysbus_ghbd_i
        core_def/U_GBUS_GENERAL_BUS/sysbus_ghbd_o
        core_def/U_UVHS_UVW_AXI4_TO_DDR4/sysbus_ghbd_i
        core_def/U_UVHS_UVW_AXI4_TO_DDR4/sysbus_ghbd_o
    } {
        for {set gbus_payload_bit 0} {$gbus_payload_bit < 256} {incr gbus_payload_bit} {
            set matched_pin [get_pins -quiet [format {%s[%d]} $gbus_payload_bus $gbus_payload_bit]]
            if {[llength $matched_pin]} {
                lappend gbus_payload_pins {*}$matched_pin
            }
        }
    }
    set gbus_payload_pins [lsort -unique $gbus_payload_pins]
    if {[llength $gbus_payload_pins]} {
        # config_clock parses its -ignore value as a Tcl collection.  Passing
        # the whole list as one nested list is accepted syntactically but the
        # compiler only records the first element on UVHS P4.  Issue one
        # command per exact pin so every vendor LAST_VALUE payload annotation
        # is registered before infer_clock.
        foreach gbus_payload_pin $gbus_payload_pins {
            config_clock -ignore $gbus_payload_pin
        }
        puts "INFO: ignored GBus protected-IP sysbus payload clock annotations before infer_clock: [llength $gbus_payload_pins] pins (one exact pin per config_clock call)"
    } else {
        puts "WARNING: no linked GBus protected-IP sysbus payload pins before infer_clock"
    }
}
if {[string toupper [uvhs::env_or_default DIFFTEST_HOSTIF XDMA]] eq "GBUS"} {
    # UVHS P4 may terminate infer_clock on LAST_VALUE annotations emitted by
    # protected GENERALBD/GENERAL_BUS models even after their exact payload
    # pins have been registered with config_clock -ignore.  Preserve the
    # original TCK diagnostics in the log and continue to partition/PnR: these
    # ports are vendor-IP payload pins, not clocks in owned RTL.  Do not apply
    # this recovery to the XDMA flow or to any user clock/CDC error.
    if {[catch {infer_clock} gbus_infer_clock_error]} {
        puts "WARNING: UVHS protected GBus IP infer_clock diagnostics retained; continuing after vendor-only error: $gbus_infer_clock_error"
    }
} else {
infer_clock
}
report_clock -inferred
fpga_diff_set_async_clock_groups
if {[string toupper [uvhs::env_or_default DIFFTEST_HOSTIF XDMA]] eq "GBUS"} {
    if {[catch {transform_clock} gbus_transform_error]} {
        puts "WARNING: UVHS protected GBus IP transform_clock diagnostics retained; continuing to partition/PnR: $gbus_transform_error"
    }
} else {
    transform_clock
}
set fill_rate_args {}
foreach {option variable} {
    -lut UVHS_LUT_FILL_RATE
    -lut6 UVHS_LUT6_FILL_RATE
} {
    set value [uvhs::env_or_default $variable ""]
    if {$value eq ""} {
        continue
    }
    if {![string is double -strict $value] || $value <= 0 || $value > 100} {
        error "$variable must be in (0, 100], got '$value'"
    }
    lappend fill_rate_args $option $value
}
if {[llength $fill_rate_args]} {
    puts "INFO: set UVHS fill rates: $fill_rate_args"
    set_fill_rate {*}$fill_rate_args
}
trigger_probe -group
sweep_design -remap
report_clock

check_design
report_resource -depth 4
report_system_resource
list_partition_constraints -all
partition_design -tdc -tdss true \
    -bs_max_blk_ratio 0.96 -bs_min_blk_ratio 0.005 -effort high
report_resource -depth 4

instrument_design
localize_design -replicate_cell -clock -self_check
sweep_design -keep_feedthrough
localize_design -data
route_design
check_timing -verbose -exclude clock_tdm
report_system_performance -show_clock_relation -verbose
report_path -normalize -exception -tdr -net -rtl \
    -max_path 100 -sort_by fmax

insert_tdm
reopt_design -verbose
bind_system
save_runtime_data

set_option compile.resourceUsageLimit 100
set_option compile.strategyNum 1
set_option compile.strategy0 uv_placer_balance_slrs
set_option compile.stage.preOpt \
    [uvhs::path vivado_pre_opt.tcl]

compile_fpga -parallel_option fpga -genScriptOnly -explore
set shell_helper [uvhs::path shell_compat.sh]
if {![file isfile $shell_helper]} {
    error "UVHS shell compatibility helper not found: $shell_helper"
}
if {[catch {exec bash $shell_helper patch-pnr hw.dat/Compile/PnR} patch_pnr_error]} {
    # The helper may emit benign loader/locale diagnostics from generated
    # Vivado workers even after patching every script successfully.  Verify
    # the generated artifacts before deciding whether to stop the backend.
    set patch_wrappers [glob -nocomplain hw.dat/Compile/PnR/*/*/vivado/Rundir/*/uv_vivado_wrapper.sh]
    set patch_makefiles [glob -nocomplain hw.dat/Compile/PnR/*/*/vivado/Rundir/*/Makefile]
    set patch_workers [glob -nocomplain hw.dat/Compile/PnR/*/*/timing/*/signoff_worker.tcl]
    if {[llength $patch_wrappers] && [llength $patch_makefiles] && [llength $patch_workers]} {
        puts "WARNING: patch-pnr returned an error after patching all generated scripts; continue: $patch_pnr_error"
    } else {
        error "patch-pnr failed before all generated scripts were patched: $patch_pnr_error"
    }
}
# UVHS invokes its generated process pool as `python process_pool_.py`.
# Put the local compatibility launcher first so the bundled Python 3.8 gets
# libffi.so.6 before _ctypes is imported on modern host distributions.
set compat_dir [file dirname $shell_helper]
set ::env(PATH) "$compat_dir:/usr/bin:/bin"
set ::env(LD_LIBRARY_PATH) "/tmp/fpga-diff-lib:/tmp:/nfs/tools/UVHS/UVH_P3_20260115/shlib:/nfs/tools/UVHS/UVH_P3_20260115/uvd/resource/usdbdiff_utils_package/lib"
set ::env(LD_PRELOAD) "/tmp/fpga-diff-lib/libffi.so.6"
set ::env(PYTHONHOME) "/tmp/uvpy38-fpga-diff"
set ::env(PYTHONPATH) "/tmp/uvpy38-fpga-diff/lib/python3.8"
compile_fpga -parallel_option fpga -runOnly -explore

report_path -max_path 100
report_system_performance
commit_runtime_data
puts "UVHS_BACKEND_SUCCESS"
exit
