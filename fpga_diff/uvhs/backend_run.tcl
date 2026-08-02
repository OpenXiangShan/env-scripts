################################################################################
# UVHS backend flow for fpga_diff.
################################################################################

proc env_or_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc source_required {file} {
    if {![file exists $file]} {
        error "required UVHS flow file not found: $file"
    }
    puts "INFO: source $file"
    uplevel #0 [list source $file]
}

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

set uvhs_script_dir [file dirname [file normalize [info script]]]
set_working_space hw.dat

set fpga_threads [env_or_default UVHS_FPGA_THREADS 8]
set fpga_processes [env_or_default UVHS_FPGA_PROCESSES 16]
set_parallel_option -max_threads $fpga_threads \
    -max_processes $fpga_processes -label fpga

set_option time.auto_clock_config true
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true

set platform [env_or_default PLATFORM U2.2]
create_system_design -name VU19P_X4 -platform $platform
source_required [file join $uvhs_script_dir assemble_uvhs.tcl]

set ::env(UVHS_ASSIGN_PIN_TOP) none
source_required [file join $uvhs_script_dir assign_pin_u22_f2.tcl]
unset ::env(UVHS_ASSIGN_PIN_TOP)

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

infer_clock
report_clock -inferred
transform_clock
source_required [file join $uvhs_script_dir async_clocks.tcl]
configure_fill_rates
trigger_probe -group
sweep_design -remap
report_clock

check_design
report_resource -depth 4
report_system_resource
list_partition_constraints -all
partition_design -tdc -tdss true
report_resource -depth 4

instrument_design
localize_design -replicate_cell -clock -self_check
sweep_design -keep_feedthrough
localize_design -data
route_design
check_timing -verbose
report_system_performance -show_clock_relation -verbose
report_path -normalize -exception -tdr -net -rtl \
    -max_path 100 -sort_by fmax

insert_tdm
reopt_design -verbose
bind_system
save_runtime_data

set_option compile.resourceUsageLimit 100
set_option compile.strategyNum 1
set_option compile.strategy0 \
    [env_or_default UVHS_COMPILE_STRATEGY uv_high_fanout_explore]
set_option compile.stage.preOpt \
    [file join $uvhs_script_dir vivado_pre_opt.tcl]

compile_fpga -parallel_option fpga -genScriptOnly -explore
set shell_helper [file join $uvhs_script_dir shell_compat.sh]
if {![file isfile $shell_helper]} {
    error "UVHS shell compatibility helper not found: $shell_helper"
}
exec bash $shell_helper patch-pnr hw.dat/Compile/PnR
compile_fpga -parallel_option fpga -runOnly -explore

report_path -max_path 100
report_system_performance
commit_runtime_data
puts "UVHS_BACKEND_SUCCESS"
exit
