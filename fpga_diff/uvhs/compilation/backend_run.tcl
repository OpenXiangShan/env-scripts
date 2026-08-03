################################################################################
# UVHS backend flow for fpga_diff.
################################################################################

source [file join [file dirname [file normalize [info script]]] flow_common.tcl]
set_working_space hw.dat

set_parallel_option -max_threads 4 -max_processes 8 -label fpga

set_option time.auto_clock_config true
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true

create_system_design -name VU19P_X4 -platform U2.2
uvhs::source_required topology.tcl

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

infer_clock
report_clock -inferred
transform_clock
fpga_diff_set_async_clock_groups
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
    -bs_max_blk_ratio 0.96 -bs_min_blk_ratio 0.005
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
set_option compile.strategy0 uv_high_fanout_explore
set_option compile.stage.preOpt \
    [uvhs::path vivado_pre_opt.tcl]

compile_fpga -parallel_option fpga -genScriptOnly -explore
set shell_helper [uvhs::path shell_compat.sh]
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
