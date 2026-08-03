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
