################################################################################
# Export Vivado IP/BD checkpoints for UVHS blackbox import.
################################################################################

set origin_dir "."
set out_dir "./uvhs_ip"
set vivado_version ""
set force 0
set jobs 8
set cpu "kmh"
set core_dir ""
set only ""
set skip_exports [list]

proc print_help {} {
    puts "Usage:"
    puts "  vivado -mode batch -source uvhs/export_vivado_ip.tcl -tclargs \\"
    puts "    --origin_dir <fpga_diff> --out_dir <uvhs_work_dir> \[--vivado_version <ver>\] \[--cpu <name>\] \[--core_dir <dir>\] \[--only <ip>\] \[--skip <ip>\] \[--force\] \[--jobs N\]"
    exit 0
}

for {set i 0} {$i < $::argc} {incr i} {
    set option [lindex $::argv $i]
    switch -- $option {
        "--origin_dir"     { incr i; set origin_dir [lindex $::argv $i] }
        "--out_dir"        { incr i; set out_dir [lindex $::argv $i] }
        "--vivado_version" { incr i; set vivado_version [lindex $::argv $i] }
        "--cpu"            { incr i; set cpu [lindex $::argv $i] }
        "--core_dir"       { incr i; set core_dir [lindex $::argv $i] }
        "--only"           { incr i; set only [lindex $::argv $i] }
        "--skip"           { incr i; lappend skip_exports [lindex $::argv $i] }
        "--force"          { set force 1 }
        "--jobs"           { incr i; set jobs [lindex $::argv $i] }
        "--help"           { print_help }
        default {
            puts "ERROR: unknown option $option"
            print_help
        }
    }
}

set origin_dir [file normalize $origin_dir]
set out_dir [file normalize $out_dir]
if {$core_dir ne ""} {
    set core_dir [file normalize $core_dir]
}
set tcl_dir [file join $origin_dir src tcl common]
set export_project_dir [file join $out_dir vivado_ip_export]
set export_project [file join $export_project_dir vivado_ip_export.xpr]

if {$vivado_version eq ""} {
    set vivado_version [version -short]
}
set ::vivado_version $vivado_version
set ::cpu $cpu
set ::core_dir $core_dir

if {$force && [file exists $export_project_dir]} {
    file delete -force $export_project_dir
}

file mkdir $out_dir
file mkdir [file join $out_dir rtl soc]
file mkdir [file join $out_dir rtl device pcie]
file mkdir $export_project_dir

if {[file exists $export_project]} {
    open_project $export_project
} else {
    create_project vivado_ip_export $export_project_dir -part xcvu19p-fsva3824-2-e
    set_property target_language Verilog [current_project]
    set_property simulator_language Mixed [current_project]
}

proc add_core_generated_headers {core_dir} {
    if {$core_dir eq "" || ![file isdirectory $core_dir]} {
        return
    }

    set header_candidates [list \
        [file join $core_dir build generated-src DifftestMacros.svh] \
        [file join $core_dir generated-src DifftestMacros.svh] \
        [file join $core_dir build rtl DifftestMacros.svh] \
        [file join $core_dir rtl DifftestMacros.svh] \
    ]
    foreach hdr $header_candidates {
        if {![file exists $hdr]} {
            continue
        }
        set hdr [file normalize $hdr]
        if {[llength [get_files -quiet $hdr]] == 0} {
            add_files -norecurse $hdr
        }
        set hdr_file [get_files -quiet $hdr]
        if {[llength $hdr_file] > 0} {
            set_property file_type {Verilog Header} $hdr_file
        }
        puts "INFO: added core generated header $hdr"
        return
    }
    puts "WARNING: DifftestMacros.svh not found under core_dir $core_dir"
}

add_core_generated_headers $core_dir

proc source_ip_tcl {script} {
    if {![file exists $script]} {
        puts "WARNING: missing IP script $script"
        return 0
    }
    puts "INFO: source $script"
    set rc [catch {uplevel #0 [list source $script]} err opts]
    if {$rc != 0} {
        puts "ERROR: failed to source $script"
        puts $err
        return -options $opts $err
    }
    return 1
}

proc run_and_copy_dcp {run_name out_file jobs force} {
    if {[file exists $out_file] && !$force} {
        puts "INFO: reuse existing $out_file"
        return
    }

    set run [get_runs -quiet $run_name]
    if {[llength $run] == 0} {
        error "run $run_name not found"
    }

    reset_run $run
    clear_auto_incremental_imports $run_name
    launch_runs $run -jobs $jobs
    wait_on_run $run

    set status [get_property STATUS $run]
    puts "INFO: $run_name status: $status"

    set run_dir [get_property DIRECTORY $run]
    set dcps [glob -nocomplain [file join $run_dir *.dcp]]
    if {[llength $dcps] == 0} {
        if {![string match "*Complete*" $status]} {
            error "$run_name did not complete: $status"
        }
        error "no DCP generated in $run_dir"
    }

    file mkdir [file dirname $out_file]
    file copy -force [lindex $dcps 0] $out_file
    puts "INFO: exported $out_file"
}

proc run_and_write_opened_dcp {run_name out_file jobs force} {
    if {[file exists $out_file] && !$force} {
        puts "INFO: reuse existing $out_file"
        return
    }

    set run [get_runs -quiet $run_name]
    if {[llength $run] == 0} {
        error "run $run_name not found"
    }

    reset_run $run
    clear_auto_incremental_imports $run_name
    launch_runs $run -jobs $jobs
    wait_on_run $run

    set status [get_property STATUS $run]
    puts "INFO: $run_name status: $status"
    if {![string match "*Complete*" $status]} {
        error "$run_name did not complete: $status"
    }

    catch {close_design}
    open_run $run_name
    file mkdir [file dirname $out_file]
    write_checkpoint -force $out_file
    puts "INFO: exported stitched checkpoint $out_file"
}

proc clear_auto_incremental_imports {run_name} {
    global export_project_dir

    set run [get_runs -quiet $run_name]
    if {[llength $run] > 0} {
        set props [list_property $run]
        foreach {prop value} {
            AUTO_INCREMENTAL_CHECKPOINT 0
            INCREMENTAL_CHECKPOINT {}
            STEPS.SYNTH_DESIGN.ARGS.INCREMENTAL_MODE off
        } {
            if {[lsearch -exact $props $prop] >= 0} {
                set rc [catch {set_property $prop $value $run} err]
                if {$rc == 0} {
                    puts "INFO: cleared auto-incremental property $prop on run $run_name"
                } else {
                    puts "WARNING: failed to clear auto-incremental property $prop on run $run_name: $err"
                }
            }
        }
    }

    foreach imports_dir [glob -nocomplain [file join $export_project_dir *.srcs utils_1 imports $run_name]] {
        file delete -force $imports_dir
        puts "INFO: removed stale auto-incremental checkpoint imports for $run_name: $imports_dir"
    }
}

proc verify_checkpoint {label dcp} {
    open_checkpoint $dcp
    set cell_count [llength [get_cells -hier -quiet]]
    if {$cell_count == 0} {
        close_design
        error "$label synthesized to an empty design"
    }
    set blackbox_cells [get_cells -hier -quiet -filter {IS_BLACKBOX == 1}]
    set blackbox_names [list]
    if {[llength $blackbox_cells] > 0} {
        set blackbox_names [get_property NAME $blackbox_cells]
    }
    close_design
    set unexpected_blackboxes [list]
    foreach blackbox $blackbox_names {
        if {$blackbox eq "dbg_hub"} {
            puts "INFO: $label keeps Vivado debug hub blackbox $blackbox"
        } else {
            lappend unexpected_blackboxes $blackbox
        }
    }
    if {[llength $unexpected_blackboxes] > 0} {
        error "$label still has blackbox cells after checkpoint export: $unexpected_blackboxes"
    }
}

proc launch_run_list {run_list jobs} {
    if {[llength $run_list] == 0} {
        return
    }

    foreach run $run_list {
        reset_run $run
    }
    launch_runs $run_list -jobs $jobs
    foreach run $run_list {
        wait_on_run $run
    }

    foreach run $run_list {
        set status [get_property STATUS $run]
        puts "INFO: $run status: $status"
        if {![string match "*Complete*" $status] && ![string match "*cached IP results*" $status]} {
            error "IP run $run did not complete: $status"
        }
    }
}

proc create_and_launch_bd_ip_runs {bd jobs} {
    catch {create_ip_run $bd}
    set bd_name [file rootname [file tail $bd]]
    set run_list [get_runs -quiet ${bd_name}_*_synth_1]
    launch_run_list $run_list $jobs
    return $run_list
}

proc export_xci_ip {name script out_file jobs force} {
    if {[llength [get_ips -quiet $name]] == 0} {
        source_ip_tcl $script
    }

    set ip [get_ips -quiet $name]
    if {[llength $ip] == 0} {
        error "IP $name was not created by $script"
    }

    set ip_file [get_property IP_FILE $ip]
    if {$ip_file ne ""} {
        set ip_file_obj [get_files -quiet $ip_file]
        if {[llength $ip_file_obj] > 0} {
            set_property GENERATE_SYNTH_CHECKPOINT true $ip_file_obj
        }
    }
    generate_target all $ip
    catch {create_ip_run $ip}
    run_and_copy_dcp ${name}_synth_1 $out_file $jobs $force
    verify_checkpoint "IP $name" $out_file
}

proc export_bd_ip {name script out_file jobs force} {
    if {[llength [get_files -quiet ${name}.bd]] == 0} {
        source_ip_tcl $script
    }

    set bd [get_files -quiet ${name}.bd]
    if {[llength $bd] == 0} {
        error "BD $name was not created by $script"
    }

    open_bd_design $bd
    current_bd_design $name
    validate_bd_design
    save_bd_design
    generate_target all $bd
    catch {make_wrapper -files $bd -top}

    if {[file exists $out_file] && !$force} {
        puts "INFO: reuse existing $out_file"
        return
    }

    # Build child IP OOC runs first, then synthesize the BD top as one
    # checkpoint.  This keeps the exported artifact as a single DCP while
    # letting Vivado handle encrypted or packaged IP internals through their
    # generated runs instead of compiling raw shared sources.
    create_and_launch_bd_ip_runs $bd $jobs
    set_property top $name [current_fileset]
    update_compile_order -fileset sources_1
    run_and_write_opened_dcp synth_1 $out_file $jobs $force
    verify_checkpoint "BD $name" $out_file
}

set exports [list \
    [list xci blk_mem_gen_0 [file join $tcl_dir blk_mem_gen_0.tcl] [file join $out_dir rtl soc blk_mem_gen_0.dcp]] \
    [list bd  AXI_bridge    [file join $tcl_dir AXI_bridge.tcl]    [file join $out_dir rtl soc AXI_bridge.dcp]] \
    [list bd  data_bridge   [file join $tcl_dir data_bridge.tcl]   [file join $out_dir rtl soc data_bridge.dcp]] \
    [list xci vio_0         [file join $tcl_dir vio_0.tcl]         [file join $out_dir rtl soc vio_0.dcp]] \
    [list bd  xdma_ep       [file join $tcl_dir xdma_ep.tcl]       [file join $out_dir rtl device pcie xdma_ep.dcp]] \
    [list bd  jtag_ddr_subsys [file join $tcl_dir jtag_ddr_subsys.tcl] [file join $out_dir rtl soc jtag_ddr_subsys.dcp]] \
]

set failed_exports [list]
foreach item $exports {
    lassign $item kind name script out_file
    if {$only ne "" && $name ne $only} {
        puts "INFO: skip $name because --only $only is set"
        continue
    }
    if {[lsearch -exact $skip_exports $name] >= 0} {
        puts "INFO: skip $name because --skip requested"
        continue
    }
    puts "INFO: exporting $kind $name"
    set rc [catch {
        if {$kind eq "xci"} {
            export_xci_ip $name $script $out_file $jobs $force
        } else {
            export_bd_ip $name $script $out_file $jobs $force
        }
    } err opts]
    if {$rc != 0} {
        catch {close_design}
        lappend failed_exports $name
        puts "ERROR: failed to export $name"
        puts "ERROR: $err"
    }
}

if {[llength $failed_exports] > 0} {
    error "Vivado IP/BD DCP export failed for: $failed_exports"
}

close_project
puts "INFO: Vivado IP export finished."
