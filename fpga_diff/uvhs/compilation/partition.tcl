################################################################################
# Keep the DUT DDR controller on the FPGA and connector of the user DDR card.
################################################################################

set uvhs_ddr_cell \
    [get_cells -quiet {core_def/U_UVHS_UVW_AXI4_TO_DDR4}]
if {[llength $uvhs_ddr_cell] != 1} {
    error "expected one UVHS DUT DDR instance, got [llength $uvhs_ddr_cell]"
}
create_fpga -name b0.f0 -cells $uvhs_ddr_cell
set uvhs_ddr_connector b0.F0_FMC0
set_property -name connector -value $uvhs_ddr_connector \
    -objects $uvhs_ddr_cell
set uvhs_bound_ddr_connector \
    [get_property -name connector -objects $uvhs_ddr_cell]
if {$uvhs_bound_ddr_connector ne $uvhs_ddr_connector} {
    error "failed to constrain UVHS DUT DDR to $uvhs_ddr_connector"
}
puts "INFO: constrain UVHS DUT DDR to $uvhs_bound_ddr_connector"

# Keep the XiangShan instruction-fetch path with XDMA and the physical UART
# endpoint. Other CPUs do not contain these hierarchy paths and stay automatic.
set uvhs_fetch_path_names {
    core_def/U_CPU_TOP/u_XSTop/soc/core_with_l2
    core_def/U_CPU_TOP/u_XSTop/soc/nocMisc
    core_def/U_CPU_TOP/u_XSTop/soc/tl2axi4
    core_def/CFG_AXI_bridge_i
    core_def/U_UVHS_FLASH_GBUS
}
set uvhs_xiangshan_cell [get_cells -quiet {core_def/U_CPU_TOP/u_XSTop}]
if {[llength $uvhs_xiangshan_cell] == 1} {
    set uvhs_fetch_path_cells [get_cells -quiet $uvhs_fetch_path_names]
    if {[llength $uvhs_fetch_path_cells] != [llength $uvhs_fetch_path_names]} {
        error "incomplete XiangShan fetch path: expected [llength $uvhs_fetch_path_names] cells, got [llength $uvhs_fetch_path_cells]"
    }
    create_fpga -name b0.f2 -cells $uvhs_fetch_path_cells
    puts "INFO: constrain XiangShan fetch path to b0.f2: $uvhs_fetch_path_cells"
} elseif {[llength $uvhs_xiangshan_cell]} {
    error "expected at most one XiangShan top cell, got [llength $uvhs_xiangshan_cell]"
} else {
    puts "INFO: skip XiangShan fetch-path constraint for this CPU"
}
unset -nocomplain uvhs_fetch_path_names uvhs_fetch_path_cells uvhs_xiangshan_cell
