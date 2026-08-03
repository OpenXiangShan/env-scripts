################################################################################
# Keep the DUT DDR controller on the FPGA connected to the user DDR card.
################################################################################

set uvhs_ddr_cell \
    [get_cells -quiet {core_def/U_UVHS_UVW_AXI4_TO_DDR4}]
if {[llength $uvhs_ddr_cell] != 1} {
    error "expected one UVHS DUT DDR instance, got [llength $uvhs_ddr_cell]"
}
create_fpga -name b0.f0 -cells $uvhs_ddr_cell
