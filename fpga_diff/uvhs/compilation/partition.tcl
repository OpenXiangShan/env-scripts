################################################################################
# Keep the DUT DDR controller on the FPGA and connector of the user DDR card.
################################################################################

set uvhs_ddr_cell \
    [get_cells -quiet {core_def/U_UVHS_UVW_AXI4_TO_DDR4}]
if {[llength $uvhs_ddr_cell] != 1} {
    error "expected one UVHS DUT DDR instance, got [llength $uvhs_ddr_cell]"
}

# Keep the XiangShan memory and configuration paths with the user DDR. Keep the
# core and DiffTest host path with XDMA. UART pins remain on the physical F1
# daughter card.
set uvhs_f0_cells $uvhs_ddr_cell
set uvhs_memory_path_names {
    core_def/U_CPU_TOP/u_XSTop/soc/chi_extllc_opt
    core_def/U_CPU_TOP/u_XSTop/soc/imsic_bus_tops
    core_def/U_CPU_TOP/u_XSTop/soc/widget
    core_def/U_CPU_TOP/u_XSTop/soc/fragmenter
    core_def/U_CPU_TOP/u_XSTop/soc/tl2axi4
    core_def/U_CPU_TOP/u_XSTop/soc/axi4yank
    core_def/U_CPU_TOP/u_XSTop/soc/axi4buf
}
set uvhs_nocmisc_path core_def/U_CPU_TOP/u_XSTop/soc/nocMisc
set uvhs_nocmisc_f0_children {
    axi4xbar
    axi4buf
    axi4buf_1
    axi4buf_2
    axi4yank
    axi4deint
    xbar_1
    axi4yank_1
    axi4buf_3
    axi4buf_4
    axi4buf_5
    axi4buf_6
    axi4yank_2
    error
    axi4deint_1_nodeIn_r_deq_q
    tl2axi4
    llc_to_peripheral_buffer_0
    llc_to_peripheral_buffer_1
    fixer
    widget
    axi42tl
    axi4yank_3
    xbar_2
    plic
    aplic
    timer
    tl2axi4_1
    fragmenter
    widget_1
    debugModule
    pma
    buffers
    buffers_1
    buffers_2
    buffers_3
    out_back_q
}
foreach uvhs_nocmisc_child $uvhs_nocmisc_f0_children {
    lappend uvhs_memory_path_names \
        ${uvhs_nocmisc_path}/${uvhs_nocmisc_child}
}
set uvhs_config_path_names {
    core_def/CFG_AXI_bridge_i
    core_def/U_UVHS_FLASH_GBUS
    core_def/U_SYS_CFG
    core_def/u_rom
}
set uvhs_host_path_names {
    core_def/U_CPU_TOP/u_XSTop/soc/core_with_l2
    core_def/U_CPU_TOP/u_XSTop/endpoint
    core_def/U_CPU_TOP/u_XSTop/difftest_cfg
    core_def/U_CPU_TOP/u_XSTop/difftest_host
    core_def/U_CPU_TOP/u_XSTop/difftest_memCtrl
    core_def/U_CPU_TOP/u_XSTop/soc/nocMisc/syscnt
    core_def/U_CPU_TOP/u_XSTop/soc/nocMisc/time_source
    core_def/U_CPU_TOP/u_XSTop/soc/time_sink
    core_def/xdma_ep_i
}
set uvhs_xiangshan_cell [get_cells -quiet {core_def/U_CPU_TOP/u_XSTop}]
if {[llength $uvhs_xiangshan_cell] == 1} {
    set uvhs_memory_path_cells [get_cells -quiet $uvhs_memory_path_names]
    if {[llength $uvhs_memory_path_cells] != [llength $uvhs_memory_path_names]} {
        error [format "incomplete XiangShan memory path: expected %d cells, got %d" \
            [llength $uvhs_memory_path_names] \
            [llength $uvhs_memory_path_cells]]
    }
    set uvhs_config_path_cells [get_cells -quiet $uvhs_config_path_names]
    if {[llength $uvhs_config_path_cells] != [llength $uvhs_config_path_names]} {
        error [format "incomplete XiangShan configuration path: expected %d cells, got %d" \
            [llength $uvhs_config_path_names] \
            [llength $uvhs_config_path_cells]]
    }
    set uvhs_host_path_cells [get_cells -quiet $uvhs_host_path_names]
    if {[llength $uvhs_host_path_cells] != [llength $uvhs_host_path_names]} {
        error [format "incomplete XiangShan host path: expected %d cells, got %d" \
            [llength $uvhs_host_path_names] \
            [llength $uvhs_host_path_cells]]
    }
    set uvhs_f0_cells [concat $uvhs_f0_cells $uvhs_memory_path_cells \
        $uvhs_config_path_cells]
    create_fpga -name b0.f2 -cells $uvhs_host_path_cells
    puts "INFO: constrain XiangShan host path to b0.f2: $uvhs_host_path_cells"
    puts "INFO: keep the complete timer on b0.f0 and the RTC CDC path on b0.f2"
} elseif {[llength $uvhs_xiangshan_cell]} {
    error "expected at most one XiangShan top cell, got [llength $uvhs_xiangshan_cell]"
} else {
    puts "INFO: skip XiangShan partition constraints for this CPU"
}
create_fpga -name b0.f0 -cells $uvhs_f0_cells
set uvhs_ddr_connector b0.F0_FMC0
set_property -name connector -value $uvhs_ddr_connector \
    -objects $uvhs_ddr_cell
set uvhs_bound_ddr_connector \
    [get_property -name connector -objects $uvhs_ddr_cell]
if {$uvhs_bound_ddr_connector ne $uvhs_ddr_connector} {
    error "failed to constrain UVHS DUT DDR to $uvhs_ddr_connector"
}
puts "INFO: constrain UVHS DUT DDR to $uvhs_bound_ddr_connector"
if {[info exists uvhs_memory_path_cells]} {
    puts "INFO: constrain XiangShan memory path to b0.f0: $uvhs_memory_path_cells"
    puts "INFO: constrain XiangShan configuration path to b0.f0: $uvhs_config_path_cells"
}
if {[llength $uvhs_xiangshan_cell] == 1} {
    set uvhs_clock_enable_net \
        [get_nets -quiet {core_def/difftest_clock_gate_enable}]
    if {[llength $uvhs_clock_enable_net] != 1} {
        error "expected one DiffTest clock-enable net, got [llength $uvhs_clock_enable_net]"
    }
    assign_route -signals $uvhs_clock_enable_net -path {b0.f2 b0.f0}
    puts "INFO: constrain DiffTest clock enable to direct b0.f2-b0.f0 route"

    set uvhs_syscnt_path core_def/U_CPU_TOP/u_XSTop/soc/nocMisc/syscnt
    set uvhs_syscnt_time_nets [concat \
        [get_nets -quiet ${uvhs_syscnt_path}/time_0*] \
        [get_nets -quiet ${uvhs_syscnt_path}/time_en]]
    if {[llength $uvhs_syscnt_time_nets] != 65} {
        error "expected 65 syscnt time nets, got [llength $uvhs_syscnt_time_nets]"
    }
    assign_route -signals $uvhs_syscnt_time_nets -path {b0.f2 b0.f0}
    puts "INFO: constrain syscnt time bus to direct b0.f2-b0.f0 route"
}
unset -nocomplain uvhs_ddr_cell uvhs_ddr_connector \
    uvhs_bound_ddr_connector uvhs_f0_cells uvhs_memory_path_names \
    uvhs_memory_path_cells uvhs_config_path_names uvhs_config_path_cells \
    uvhs_host_path_names uvhs_host_path_cells \
    uvhs_nocmisc_path uvhs_nocmisc_f0_children uvhs_nocmisc_child \
    uvhs_xiangshan_cell uvhs_clock_enable_net uvhs_syscnt_path \
    uvhs_syscnt_time_nets
