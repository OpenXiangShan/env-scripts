# Timer-path probe profile for the XiangShan timer-island partition experiment.
# Keep the host trigger on a free-running clock so capture can stop after the
# gated RTC or SoC clock has stopped.
probe_net -clock {fpga_top_debug.core_def.sys_clk_i} -add {
    fpga_top_debug.core_def.io_host_ila_trigger
}

# SYSCNT and the AsyncQueue source are in the RTC clock domain.
probe_net -clock {fpga_top_debug.core_def.inter_rtc_clk} -add {
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.syscnt.io_time_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.syscnt.io_time_bits
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_enq_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_enq_bits
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_async_ridx
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_async_widx
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_async_safe_ridx_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_async_safe_widx_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_async_safe_source_reset_n
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.time_source.io_async_safe_sink_reset_n
}

# The AsyncQueue sink, timer interrupts, and architectural time consumers use
# the gated SoC/CPU clock.
probe_net -clock {fpga_top_debug.core_def.inter_soc_clk} -add {
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_deq_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_deq_bits
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_async_ridx
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_async_widx
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_async_safe_ridx_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_async_safe_widx_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_async_safe_source_reset_n
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.time_sink.io_async_safe_sink_reset_n
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.auto_timer_int_out_0
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.nocMisc.auto_timer_int_out_1
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.core_with_l2.core.backend.inner_intExuBlock.exus_7.csr.csrMod.time_0.updated
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.core_with_l2.core.backend.inner_intExuBlock.exus_7.csr.csrMod.time_0.mHPM_time_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.core_with_l2.core.backend.inner_intExuBlock.exus_7.csr.csrMod.time_0.mHPM_time_bits
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.core_with_l2.core.backend.inner_intExuBlock.exus_7.csr.csrMod.sstcIRGen.i_stime_valid
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.core_with_l2.core.backend.inner_intExuBlock.exus_7.csr.csrMod.sstcIRGen.i_stime_bits
    fpga_top_debug.core_def.U_CPU_TOP.u_XSTop.soc.core_with_l2.core.backend.inner_intExuBlock.exus_7.csr.csrMod.sstcIRGen.o_STIP
}

trigger_net -add -group test0 \
    -clock fpga_top_debug.core_def.sys_clk_i \
    -signal {
        fpga_top_debug.core_def.io_host_ila_trigger
    }
