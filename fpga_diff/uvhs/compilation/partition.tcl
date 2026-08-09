################################################################################
# Keep the DUT DDR controller on the FPGA and connector of the user DDR card.
################################################################################

set uvhs_ddr_cell \
    [get_cells -quiet {core_def/U_UVHS_UVW_AXI4_TO_DDR4}]
if {[llength $uvhs_ddr_cell] != 1} {
    error "expected one UVHS DUT DDR instance, got [llength $uvhs_ddr_cell]"
}

# Keep the XiangShan memory path with the user DDR. Keep the core and DiffTest
# host path with XDMA. UART pins remain on the physical F1 daughter card.
set uvhs_f0_cells $uvhs_ddr_cell
set uvhs_memory_path_names {
    core_def/U_CPU_TOP/u_XSTop/soc/chi_extllc_opt
    core_def/U_CPU_TOP/u_XSTop/soc/nocMisc
    core_def/U_CPU_TOP/u_XSTop/soc/imsic_bus_tops
    core_def/U_CPU_TOP/u_XSTop/soc/widget
    core_def/U_CPU_TOP/u_XSTop/soc/fragmenter
    core_def/U_CPU_TOP/u_XSTop/soc/tl2axi4
    core_def/U_CPU_TOP/u_XSTop/soc/axi4yank
    core_def/U_CPU_TOP/u_XSTop/soc/axi4buf
}
set uvhs_host_path_names {
    core_def/U_CPU_TOP/u_XSTop/soc/core_with_l2
    core_def/U_CPU_TOP/u_XSTop/endpoint
    core_def/U_CPU_TOP/u_XSTop/difftest_cfg
    core_def/U_CPU_TOP/u_XSTop/difftest_host
    core_def/U_CPU_TOP/u_XSTop/difftest_memCtrl
    core_def/xdma_ep_i
    core_def/CFG_AXI_bridge_i
    core_def/U_UVHS_FLASH_GBUS
}
set uvhs_xiangshan_cell [get_cells -quiet {core_def/U_CPU_TOP/u_XSTop}]
if {[llength $uvhs_xiangshan_cell] == 1} {
    set uvhs_memory_path_cells [get_cells -quiet $uvhs_memory_path_names]
    if {[llength $uvhs_memory_path_cells] != [llength $uvhs_memory_path_names]} {
        error [format "incomplete XiangShan memory path: expected %d cells, got %d" \
            [llength $uvhs_memory_path_names] \
            [llength $uvhs_memory_path_cells]]
    }
    set uvhs_host_path_cells [get_cells -quiet $uvhs_host_path_names]
    if {[llength $uvhs_host_path_cells] != [llength $uvhs_host_path_names]} {
        error [format "incomplete XiangShan host path: expected %d cells, got %d" \
            [llength $uvhs_host_path_names] \
            [llength $uvhs_host_path_cells]]
    }
    set uvhs_f0_cells [concat $uvhs_f0_cells $uvhs_memory_path_cells]
    create_fpga -name b0.f2 -cells $uvhs_host_path_cells
    puts "INFO: constrain XiangShan host path to b0.f2: $uvhs_host_path_cells"
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
}
if {[llength $uvhs_xiangshan_cell] == 1} {
    set uvhs_clock_enable_net \
        [get_nets -quiet {core_def/difftest_clock_gate_enable}]
    if {[llength $uvhs_clock_enable_net] != 1} {
        error "expected one DiffTest clock-enable net, got [llength $uvhs_clock_enable_net]"
    }
    assign_route -signals $uvhs_clock_enable_net -path {b0.f2 b0.f0}
    puts "INFO: constrain DiffTest clock enable to direct b0.f2-b0.f0 route"
}
unset -nocomplain uvhs_ddr_cell uvhs_ddr_connector \
    uvhs_bound_ddr_connector uvhs_f0_cells uvhs_memory_path_names \
    uvhs_memory_path_cells uvhs_host_path_names uvhs_host_path_cells \
    uvhs_xiangshan_cell uvhs_clock_enable_net
