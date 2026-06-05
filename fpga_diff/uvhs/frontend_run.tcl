################################################################################
# UVHS frontend flow for fpga_diff.
################################################################################

proc env_or_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc split_words {value} {
    set out [list]
    foreach item $value {
        if {$item ne ""} {
            lappend out $item
        }
    }
    return $out
}

set required_dcp_modules [split_words [env_or_default UVHS_REQUIRED_DCP_MODULES {blk_mem_gen_0 AXI_bridge data_bridge vio_0 xdma_ep jtag_ddr_subsys uvw_axi4_to_ddr4}]]

proc source_if_exists {file} {
    if {$file eq "none"} {
        puts "INFO: skip $file"
        return
    }
    if {[file exists $file]} {
        puts "INFO: source $file"
        if {[catch {uplevel #0 [list source $file]} err]} {
            puts "WARNING: source $file failed: $err"
        }
    } else {
        puts "INFO: skip missing $file"
    }
}

proc set_blackbox_if_exists {module dcp args} {
    if {[file exists $dcp]} {
        puts "INFO: set_blackbox $module $dcp"
        set command [list set_blackbox -module $module -source_file $dcp]
        if {[llength $args] > 0} {
            set command [concat $command $args]
        }
        uplevel #0 $command
    } else {
        if {[lsearch -exact $::required_dcp_modules $module] >= 0} {
            error "required blackbox DCP missing for $module: $dcp"
        }
        puts "INFO: skip blackbox $module, missing $dcp"
    }
}

proc set_ip_if_exists {module dcp stub args} {
    if {![file exists $dcp]} {
        if {[lsearch -exact $::required_dcp_modules $module] >= 0} {
            error "required IP DCP missing for $module: $dcp"
        }
        puts "INFO: skip set_ip $module, missing $dcp"
        return
    }
    if {![file exists $stub]} {
        if {[lsearch -exact $::required_dcp_modules $module] >= 0} {
            error "required IP stub missing for $module: $stub"
        }
        puts "INFO: skip set_ip $module, missing stub $stub"
        return
    }

    puts "INFO: set_ip $module $dcp"
    set command [list set_ip -module $module -source_file $dcp]
    if {[llength $args] > 0} {
        set command [concat $command $args]
    }
    uplevel #0 $command
    set read_stub [env_or_default [string toupper UVHS_${module}_READ_STUB] 1]
    if {$read_stub eq "0"} {
        puts "INFO: skip read_verilog $stub because UVHS_[string toupper ${module}]_READ_STUB=0"
    } else {
        puts "INFO: read_verilog $stub"
        uplevel #0 [list read_verilog $stub]
    }
}

proc require_file_for_uvhs_ip {description file} {
    if {![file exists $file] || [file size $file] == 0} {
        error "required UVHS DDR IP $description missing or empty: $file"
    }
    puts "INFO: found UVHS DDR IP $description: $file"
}

proc read_verilog_if_exists {description file} {
    if {![file exists $file] || [file size $file] == 0} {
        error "required Verilog $description missing or empty: $file"
    }
    puts "INFO: read_verilog $file"
    uplevel #0 [list read_verilog $file]
}

proc run_or_warn {description command} {
    puts "INFO: $description"
    if {[catch {uplevel #0 $command} err]} {
        puts "WARNING: $description failed: $err"
    }
}

proc append_line_if_missing {file line} {
    if {$file eq "" || $line eq ""} {
        return
    }
    set existing ""
    if {[file exists $file]} {
        set fh [open $file r]
        set existing [read $fh]
        close $fh
        foreach entry [split $existing "\n"] {
            if {[string trim $entry] eq $line} {
                puts "INFO: keep existing option line in $file: $line"
                return
            }
        }
    }
    set fh [open $file a]
    if {$existing ne "" && ![string match *\n $existing]} {
        puts $fh ""
    }
    puts $fh $line
    close $fh
    puts "INFO: appended option line to $file: $line"
}

proc remove_line_if_present {file line} {
    if {$file eq "" || $line eq "" || ![file exists $file]} {
        return
    }
    set fh [open $file r]
    set existing [read $fh]
    close $fh

    set changed 0
    set kept [list]
    foreach entry [split $existing "\n"] {
        if {[string trim $entry] eq $line} {
            set changed 1
        } else {
            lappend kept $entry
        }
    }
    if {!$changed} {
        return
    }

    set fh [open $file w]
    puts -nonewline $fh [join $kept "\n"]
    close $fh
    puts "INFO: removed stale option line from $file: $line"
}

proc patch_option_add_rtl_inst {working_space inst_path} {
    if {$inst_path eq "" || $inst_path eq "none"} {
        puts "INFO: skip option.add_rtl_inst patch"
        return
    }
    set option_dir [file join $working_space DB Options]
    file mkdir $option_dir
    set add_inst_line "add_rtl_inst -inst_name $inst_path"
    append_line_if_missing [file join $option_dir option.add_rtl_inst.txt] $add_inst_line
    append_line_if_missing [file join $option_dir option.txt] $add_inst_line
}

proc patch_option_mem {working_space ref_name} {
    if {$ref_name eq "" || $ref_name eq "none"} {
        puts "INFO: skip option.mem patch"
        return
    }
    set option_dir [file join $working_space DB Options]
    file mkdir $option_dir
    set legacy_mem_line "set_option -mem.externalMemory.refName $ref_name"
    append_line_if_missing [file join $option_dir option.mem.txt] $legacy_mem_line
    append_line_if_missing [file join $option_dir option.txt] $legacy_mem_line
}

proc start_uvsyn_shell_patch_watcher {} {
    set module_makefile [file join [pwd] hw.dat Synthesis Uvsyn Script module.makefile]
    set patch_script [file normalize [file join [file dirname [info script]] patch_uvsyn_shell.sh]]
    if {![file exists $patch_script]} {
        puts "WARNING: missing uvsyn shell patch helper: $patch_script"
        return
    }
    if {[catch {exec bash $patch_script $module_makefile &} err]} {
        puts "WARNING: start uvsyn shell patch watcher failed: $err"
    } else {
        puts "INFO: started uvsyn shell patch watcher for $module_makefile"
    }
}

create_working_space hw.dat
set_option syn.computeFeCheckSum true

set frontend_threads [env_or_default UVHS_FRONTEND_THREADS 16]
set frontend_processes [env_or_default UVHS_FRONTEND_PROCESSES 64]
set fpga_threads [env_or_default UVHS_FPGA_THREADS 8]
set fpga_processes [env_or_default UVHS_FPGA_PROCESSES 32]

if {[env_or_default UVHS_USE_LSF 1]} {
    set_parallel_option -max_threads $frontend_threads -max_processes $frontend_processes -submit_command bsub -terminate_command bkill -label frontend
    set_parallel_option -max_threads $fpga_threads -max_processes $fpga_processes -submit_command {bsub -R "rusage[mem=80000]"} -terminate_command bkill -label fpga
} else {
    set_parallel_option -max_threads $frontend_threads -max_processes $frontend_processes -label frontend
    set_parallel_option -max_threads $fpga_threads -max_processes $fpga_processes -label fpga
}

set_option global.msg.maxerror 1000000
config_message -name VERI-1180 -severity WARN
config_message -name VERI-1930 -severity WARN

set_option global.log.label MEMORY
set_option syn.checkMultiDriver false
set_option syn.multipleDriverConflict WOR
set_option time.auto_clock_config true
set_option clock.transform_clock.multi_iteration true
set_option clock.glitch.force_transform true
set_option clock.async_control.force_accept true
set_option time.enable_sign_off true
set_option time.incremental_sign_off true
set_option signal.uhd.sampling_clock.allow_local_clock true
set_option syn.logicFillingRateThreshold 0.001

set design_name [env_or_default UVHS_DESIGN_NAME VU19P_X4]
set platform [env_or_default PLATFORM U2.2]
set design_top [env_or_default UVHS_TOP fpga_top_debug]
set ddr_inst_path [env_or_default UVHS_DDR_RTL_INST ${design_top}.core_def.U_JTAG_DDR_SUBSYS]
set option_mem_refname [env_or_default UVHS_OPTION_MEM_REFNAME none]
set blackbox_jtag_ddr_subsys [env_or_default UVHS_BLACKBOX_JTAG_DDR_SUBSYS 1]
set use_uvw_axi4_to_ddr4_set_ip [env_or_default UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP 0]
set use_cpu_liveness_gbd [env_or_default UVHS_CPU_LIVENESS_GBD 0]
set reset_ports [split_words [env_or_default UVHS_RESET_PORTS {rstn_sw6 rstn_sw5 rstn_sw4}]]
create_system_design -name $design_name -platform $platform

set assemble_file [env_or_default UVHS_ASSEMBLE_FILE ./script/1B_4F_HGC_assemble.tcl]
if {$assemble_file eq "none"} {
    puts "INFO: skip board assembly"
} else {
    source_if_exists $assemble_file
}
set skip_board_constraints [env_or_default UVHS_SKIP_BOARD_CONSTRAINTS 0]

if {$skip_board_constraints} {
    puts "INFO: skip board probe/pin/timing/partition constraints"
} else {
    source_if_exists [env_or_default UVHS_PROBE_FILE ./script/probe.tcl]
    source_if_exists [env_or_default UVHS_ASSIGN_PIN_FILE ./script/assign_pin.tcl]
    set timing_file [env_or_default UVHS_TIMING_FILE none]
    if {$timing_file eq "none"} {
        puts "INFO: skip timing constraints"
    } else {
        run_or_warn "set_constraint_files" [list set_constraint_files $timing_file]
    }
    set partition_file [env_or_default UVHS_PARTITION_FILE ./script/partition.tcl]
    if {$partition_file eq "none"} {
        puts "INFO: skip partition constraints"
    } else {
        run_or_warn "set_partition_constraint_file" [list set_partition_constraint_file $partition_file]
    }
    foreach reset_port $reset_ports {
        set reset_net ${design_top}.${reset_port}
        run_or_warn "create_reset $reset_net" [list create_reset -port $reset_net -active 0]
    }
}

set_blackbox_if_exists blk_mem_gen_0 ./rtl/soc/blk_mem_gen_0.dcp
set_blackbox_if_exists AXI_bridge ./rtl/soc/AXI_bridge.dcp
set_blackbox_if_exists data_bridge ./rtl/soc/data_bridge.dcp
set_blackbox_if_exists vio_0 ./rtl/soc/vio_0.dcp
set_blackbox_if_exists xdma_ep ./rtl/device/pcie/xdma_ep.dcp
if {$blackbox_jtag_ddr_subsys} {
    set_blackbox_if_exists jtag_ddr_subsys ./rtl/soc/jtag_ddr_subsys.dcp
} else {
    puts "INFO: skip blackbox jtag_ddr_subsys because UVHS_BLACKBOX_JTAG_DDR_SUBSYS=$blackbox_jtag_ddr_subsys"
}
if {$use_uvw_axi4_to_ddr4_set_ip} {
    require_file_for_uvhs_ip DCP ./rtl/soc/uvw_axi4_to_ddr4.dcp
    require_file_for_uvhs_ip stub ./rtl/soc/uvw_axi4_to_ddr4_Stub.v
    require_file_for_uvhs_ip pblock ./script/uvw_axi4_to_ddr4_pblock.tcl
    set_ip_if_exists uvw_axi4_to_ddr4 ./rtl/soc/uvw_axi4_to_ddr4.dcp ./rtl/soc/uvw_axi4_to_ddr4_Stub.v -clock_enable_pairs {ddr4ip_dut_axi_aclk ddr4ip_dut_axi_aclk_en 1} -script_file {prePlace ./script/uvw_axi4_to_ddr4_pblock.tcl}
} else {
    require_file_for_uvhs_ip stub ./rtl/soc/uvw_axi4_to_ddr4_Stub.v
    set_blackbox_if_exists uvw_axi4_to_ddr4 ./rtl/soc/uvw_axi4_to_ddr4.dcp -clock_enable_pairs {ddr4ip_dut_axi_aclk ddr4ip_dut_axi_aclk_en 1} -script_file {prePlace ./script/uvw_axi4_to_ddr4_pblock.tcl}
    puts "INFO: read_verilog ./rtl/soc/uvw_axi4_to_ddr4_Stub.v"
    read_verilog ./rtl/soc/uvw_axi4_to_ddr4_Stub.v
}
if {$use_cpu_liveness_gbd eq "1"} {
    require_file_for_uvhs_ip generalBD_DCP ./rtl/soc/generalBD/generalBD.dcp
    require_file_for_uvhs_ip generalBD_stub ./rtl/soc/generalBD/generalBD_stub.vp
    set_ip -module generalBD -source_file ./rtl/soc/generalBD/generalBD.dcp -clock_enable_pairs {dut_clk dut_clk_en 1} -generalbd
    read_verilog ./rtl/soc/generalBD/generalBD_stub.vp
}

set filelist [env_or_default UVHS_FILELIST ./rtl/filelist.f]
puts "INFO: read_verilog -f $filelist"
read_verilog -f $filelist -mfcu

puts "INFO: elaborate_design $design_top"
elaborate_design $design_top
start_uvsyn_shell_patch_watcher
synthesize_design -parallel_option frontend
save_working_space
patch_option_add_rtl_inst hw.dat $ddr_inst_path
patch_option_mem hw.dat $option_mem_refname
exit
