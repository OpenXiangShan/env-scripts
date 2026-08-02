################################################################################
# UVHS backend flow for fpga_diff.
################################################################################

source [file join [file dirname [file normalize [info script]]] flow_common.tcl]
set_working_space hw.dat

set fpga_threads [uvhs::env_or_default UVHS_FPGA_THREADS 8]
set fpga_processes [uvhs::env_or_default UVHS_FPGA_PROCESSES 16]
set_parallel_option -max_threads $fpga_threads \
    -max_processes $fpga_processes -label fpga

set_option time.auto_clock_config true
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true

set platform [uvhs::env_or_default PLATFORM U2.2]
create_system_design -name VU19P_X4 -platform $platform
uvhs::source_required assemble_uvhs.tcl

set ::env(UVHS_ASSIGN_PIN_TOP) none
uvhs::source_required assign_pin_u22_f2.tcl
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
uvhs::source_required async_clocks.tcl
uvhs::source_required partition.tcl
uvhs::configure_fill_rates
trigger_probe -group
sweep_design -remap
report_clock

uvhs::run_partition

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
    [uvhs::env_or_default UVHS_COMPILE_STRATEGY uv_high_fanout_explore]
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
