# UVHS bring-up probes for NutShell CPU execution and DiffTest host streaming.
# Keep each probe independent so one stale hierarchy path does not disable all probes.

proc uvhs_try_probe {clock signal} {
    if {[catch {probe_net -clock $clock -add [list $signal]} err]} {
        puts "WARNING: skip probe $signal: $err"
    }
}

proc uvhs_try_trigger {clock group signal} {
    if {[catch {trigger_net -add -group $group -clock $clock -signal [list $signal]} err]} {
        puts "WARNING: skip trigger $signal: $err"
    }
}

proc uvhs_probe_signals {clock signals} {
    foreach signal $signals {
        uvhs_try_probe $clock $signal
    }
}

proc uvhs_trigger_signals {clock group signals} {
    if {[info exists ::env(UVHS_ENABLE_TRIGGER_NET)] && $::env(UVHS_ENABLE_TRIGGER_NET) eq "0"} {
        puts "INFO: skip trigger_net group $group because UVHS_ENABLE_TRIGGER_NET=0"
        return
    }
    foreach signal $signals {
        uvhs_try_trigger $clock $group $signal
    }
}

set top fpga_top_debug
set core ${top}.core_def
set cpu ${core}.U_CPU_TOP
set sim ${cpu}.u_SimTop
set nut ${sim}.cpu
set nutcore ${nut}.nutcore
set backend ${nutcore}.backend
set host ${sim}.difftest_host
set diff2axis ${host}.diff2axis

set sys_clk ${core}.sys_clk_i
set cpu_clk ${core}.inter_soc_clk
set pcie_clk ${core}.difftest_pcie_clock

set uvhs_sys_signals {
    fpga_top_debug.sys_rstn
    fpga_top_debug.cpu_rstn
    fpga_top_debug.vio_sw6
    fpga_top_debug.vio_sw5
    fpga_top_debug.vio_sw4
    fpga_top_debug.core_def.sys_rstn_io
    fpga_top_debug.core_def.cpu_rstn_io
    fpga_top_debug.core_def.io_host_reset
    fpga_top_debug.core_def.io_host_diff_enable
    fpga_top_debug.core_def.io_host_ila_trigger
    fpga_top_debug.core_def.xdma_link_up
    fpga_top_debug.core_def.difftest_stream_enable
    fpga_top_debug.core_def.difftest_startup_done
    fpga_top_debug.core_def.difftest_startup_wait
    fpga_top_debug.core_def.difftest_c2h_rstn
    fpga_top_debug.core_def.difftest_to_host_axis_ready_io
    fpga_top_debug.core_def.difftest_to_host_axis_valid_io
}
uvhs_probe_signals $sys_clk $uvhs_sys_signals
uvhs_trigger_signals $sys_clk uvhs_sys $uvhs_sys_signals

set uvhs_cpu_signals {
    fpga_top_debug.core_def.U_CPU_TOP.sys_rstn_i
    fpga_top_debug.core_def.U_CPU_TOP.global_reset
    fpga_top_debug.core_def.U_CPU_TOP.difftest_clock_enable
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_arvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_arready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_araddr
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rdata
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_awvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_awready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_awaddr
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_wvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_wready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_wdata
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_bvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_bready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._endpoint_fpgaIO_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._difftest_host_io_difftest_ready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._endpoint_step
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.io_in_0_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.io_in_0_bits_cf_pc
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.wbu_io_in_bits_rdecode_cf_pc
}
set uvhs_cpu_trigger_signals {
    fpga_top_debug.core_def.U_CPU_TOP.sys_rstn_i
    fpga_top_debug.core_def.U_CPU_TOP.global_reset
    fpga_top_debug.core_def.U_CPU_TOP.difftest_clock_enable
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_arvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_arready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_rready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_awvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_awready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_wvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_wready
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_bvalid
    fpga_top_debug.core_def.U_CPU_TOP.mem_core_bready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._endpoint_fpgaIO_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._difftest_host_io_difftest_ready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop._endpoint_step
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.io_in_0_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.io_in_0_bits_cf_pc
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.cpu.nutcore.backend.wbu_io_in_bits_rdecode_cf_pc
}
uvhs_probe_signals $cpu_clk $uvhs_cpu_signals
uvhs_trigger_signals $cpu_clk uvhs_cpu $uvhs_cpu_trigger_signals

set uvhs_axis_signals {
    fpga_top_debug.core_def.difftest_to_host_axis_ready
    fpga_top_debug.core_def.difftest_to_host_axis_valid
    fpga_top_debug.core_def.difftest_to_host_axis_bits_last
    fpga_top_debug.core_def.U_CPU_TOP.difftest_to_host_axis_ready
    fpga_top_debug.core_def.U_CPU_TOP.difftest_to_host_axis_valid
    fpga_top_debug.core_def.U_CPU_TOP.difftest_to_host_axis_bits_last
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host._diff2axis_io_difftest_ready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.diff2axis.io_axis_ready
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.diff2axis.io_axis_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.diff2axis.io_axis_bits_last
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.diff2axis.wr_cnt
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.diff2axis.rd_cnt
    fpga_top_debug.core_def.U_CPU_TOP.u_SimTop.difftest_host.diff2axis.inTransfer
}
uvhs_probe_signals $pcie_clk $uvhs_axis_signals
uvhs_trigger_signals $pcie_clk uvhs_axis $uvhs_axis_signals
