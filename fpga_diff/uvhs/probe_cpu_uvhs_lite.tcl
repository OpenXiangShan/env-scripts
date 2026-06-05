# Minimal UVHS probes for checking CPU/C2H liveness without wide capture.

proc uvhs_try_probe {clock signal} {
    if {[catch {probe_net -clock $clock -add [list $signal]} err]} {
        puts "WARNING: skip probe $signal: $err"
    }
}

proc uvhs_try_trigger {clock group signal} {
    if {[info exists ::env(UVHS_ENABLE_TRIGGER_NET)] && $::env(UVHS_ENABLE_TRIGGER_NET) eq "0"} {
        puts "INFO: skip trigger_net group $group because UVHS_ENABLE_TRIGGER_NET=0"
        return
    }
    if {[catch {trigger_net -add -group $group -clock $clock -signal [list $signal]} err]} {
        puts "WARNING: skip trigger $signal: $err"
    }
}

set core fpga_top_debug.core_def
set cpu ${core}.U_CPU_TOP
set sim ${cpu}.u_SimTop

set sys_clk ${core}.sys_clk_i
set cpu_clk ${core}.inter_soc_clk
set pcie_clk ${core}.difftest_pcie_clock

foreach signal {
    fpga_top_debug.core_def.sys_rstn_io
    fpga_top_debug.core_def.cpu_rstn_io
    fpga_top_debug.core_def.io_host_reset
    fpga_top_debug.core_def.io_host_diff_enable
    fpga_top_debug.core_def.xdma_link_up
    fpga_top_debug.core_def.difftest_stream_enable
    fpga_top_debug.core_def.difftest_startup_done
    fpga_top_debug.core_def.difftest_to_host_axis_valid_io
    fpga_top_debug.core_def.difftest_to_host_axis_ready_io
} {
    uvhs_try_probe $sys_clk $signal
}

foreach signal {
    fpga_top_debug.core_def.U_CPU_TOP.sys_rstn_i
    fpga_top_debug.core_def.U_CPU_TOP.global_reset
    fpga_top_debug.core_def.U_CPU_TOP.difftest_clock_enable
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_arvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_arready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._endpoint_fpgaIO_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._difftest_host_io_difftest_ready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.io_in_0_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.io_in_0_bits_cf_pc
} {
    uvhs_try_probe $cpu_clk $signal
}

foreach signal {
    fpga_top_debug.core_def.difftest_to_host_axis_ready
    fpga_top_debug.core_def.difftest_to_host_axis_valid
    fpga_top_debug.core_def.difftest_to_host_axis_bits_last
    fpga_top_debug.core_def.U_CPU_TOP.difftest_to_host_axis_ready
    fpga_top_debug.core_def.U_CPU_TOP.difftest_to_host_axis_valid
    fpga_top_debug.core_def.U_CPU_TOP.difftest_to_host_axis_bits_last
} {
    uvhs_try_probe $pcie_clk $signal
}

uvhs_try_trigger $sys_clk uvhs_lite fpga_top_debug.core_def.difftest_stream_enable
uvhs_try_trigger $pcie_clk uvhs_lite fpga_top_debug.core_def.difftest_to_host_axis_valid
