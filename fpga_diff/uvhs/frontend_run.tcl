################################################################################
# UVHS frontend flow for fpga_diff.
################################################################################

source [file join [file dirname [file normalize [info script]]] flow_common.tcl]

proc uvhs::import_blackbox {module dcp args} {
    if {![file exists $dcp] || [file size $dcp] == 0} {
        error "required blackbox DCP missing or empty for $module: $dcp"
    }

    puts "INFO: set_blackbox $module $dcp"
    uplevel #0 [concat [list set_blackbox -module $module -source_file $dcp] $args]
}

proc uvhs::import_ip {module dcp stub args} {
    foreach {kind file} [list DCP $dcp stub $stub] {
        if {![file exists $file] || [file size $file] == 0} {
            error "required $module $kind missing or empty: $file"
        }
    }

    puts "INFO: set_ip $module $dcp"
    uplevel #0 [concat [list set_ip -module $module -source_file $dcp] $args]
    puts "INFO: read_verilog $stub"
    read_verilog $stub
}

proc uvhs::append_option_once {file line} {
    set data ""
    if {[file exists $file]} {
        set input [open $file r]
        set data [read $input]
        close $input
        foreach existing [split $data "\n"] {
            if {[string trim $existing] eq $line} {
                return
            }
        }
    }

    set output [open $file a]
    if {$data ne "" && ![string match *\n $data]} {
        puts $output ""
    }
    puts $output $line
    close $output
}

# UVHS runtime writemem discovers backdoor instances from these database files;
# the installed release does not expose an equivalent frontend Tcl command.
proc uvhs::register_runtime_memory {working_space inst_path} {
    if {$inst_path eq "" || $inst_path eq "none"} {
        return
    }
    set option_dir [file join $working_space DB Options]
    file mkdir $option_dir
    set option "add_rtl_inst -inst_name $inst_path"
    append_option_once [file join $option_dir option.add_rtl_inst.txt] $option
    append_option_once [file join $option_dir option.txt] $option
    puts "INFO: registered UVHS runtime memory instance $inst_path"
}

proc uvhs::start_frontend_shell_compat {} {
    set helper [uvhs::path shell_compat.sh]
    if {![file isfile $helper]} {
        error "UVHS shell compatibility helper not found: $helper"
    }
    set module_makefile [file join [pwd] hw.dat Synthesis Uvsyn Script module.makefile]
    exec bash $helper wait-module $module_makefile &
    puts "INFO: started UVHS frontend shell compatibility helper"
}

create_working_space hw.dat
set_option syn.computeFeCheckSum true

set_parallel_option -max_threads 4 -max_processes 16 -label frontend

set_option global.log.label MEMORY
set_option syn.checkMultiDriver false
set_option syn.multipleDriverConflict WOR
set_option syn.engine uvsyn
set_option time.auto_clock_config true
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true
set_option signal.uhd.sampling_clock.allow_local_clock true

set platform [uvhs::env_or_default PLATFORM U2.2]
set design_top fpga_top_debug
set ddr_inst_path ${design_top}.core_def.U_UVHS_UVW_AXI4_TO_DDR4
create_system_design -name VU19P_X4 -platform $platform

uvhs::source_required topology.tcl
uvhs::source_required assign_pin.tcl
set_constraint_files [uvhs::path timing_common.tcl]
foreach reset_port {rstn_sw6 rstn_sw5 rstn_sw4} {
    create_reset -port ${design_top}.${reset_port} -active 0
}

uvhs::import_blackbox blk_mem_gen_0 ./rtl/soc/blk_mem_gen_0.dcp
uvhs::import_blackbox AXI_bridge ./rtl/soc/AXI_bridge.dcp
uvhs::import_blackbox data_bridge ./rtl/soc/data_bridge.dcp
uvhs::import_blackbox xdma_ep ./rtl/device/pcie/xdma_ep.dcp
uvhs::import_blackbox uvw_general_bus \
    ./rtl/soc/uvw_general_bus/uvw_general_bus.dcp \
    -clock_enable_pairs {dut_axi_aclk dut_axi_aclk_en 1}
uvhs::import_ip uvw_axi4_to_ddr4 ./rtl/soc/uvw_axi4_to_ddr4.dcp \
    ./rtl/soc/uvw_axi4_to_ddr4_Stub.v \
    -clock_enable_pairs {ddr4ip_dut_axi_aclk ddr4ip_dut_axi_aclk_en 1} \
    -script_file {prePlace ./script/uvw_axi4_to_ddr4_pblock.tcl}

set filelist ./rtl/filelist.f
if {![file exists $filelist]} {
    error "required UVHS RTL file list not found: $filelist"
}
read_verilog -f $filelist -mfcu
elaborate_design $design_top
uvhs::start_frontend_shell_compat
synthesize_design -parallel_option frontend
save_working_space
uvhs::register_runtime_memory hw.dat $ddr_inst_path
puts "UVHS_FRONTEND_SUCCESS"
exit
