################################################################################
# Partition the UVHS design at the CPU/DDR asynchronous bridge.
#
# U_CPU_DDR_CDC is the only CPU-to-DDR clock-domain crossing: its source side
# runs on the CPU/SoC clock, its destination side on the free-running device
# clock that feeds the user DDR controller.  The bridge therefore defines the
# partition boundary:
#
#   b0.f2  CPU/SoC hierarchy, configuration path, DiffTest host endpoint, and
#          the complete bridge.
#   b0.f0  Physical user-DDR controller on its FMC connector.
#
# The DDR AXI crossing the connector is synchronous to the free-running device
# clock, so the DDR controller keeps running while DiffTest stops the CPU.
################################################################################

set uvhs_ddr_cell \
    [get_cells -quiet {core_def/U_UVHS_UVW_AXI4_TO_DDR4}]
if {[llength $uvhs_ddr_cell] != 1} {
    error "expected one UVHS DUT DDR instance, got [llength $uvhs_ddr_cell]"
}
set uvhs_cpu_ddr_bridge [get_cells -quiet {core_def/U_CPU_DDR_CDC}]
if {[llength $uvhs_cpu_ddr_bridge] != 1} {
    error "expected one CPU/DDR async bridge, got [llength $uvhs_cpu_ddr_bridge]"
}

# Optional cells may be flattened, optimized away or absent in other host
# configurations, so keep whichever survive instead of failing the build.
proc uvhs_existing_cells {names} {
    set cells {}
    foreach name $names {
        set matches [get_cells -quiet $name]
        if {[llength $matches] == 1} {
            lappend cells [lindex $matches 0]
        } elseif {[llength $matches] > 1} {
            puts "WARNING: candidate cell $name matched multiple cells; skip ambiguous match"
        } else {
            puts "INFO: optional cell not present after optimization: $name"
        }
    }
    return $cells
}

set uvhs_f0_cells $uvhs_ddr_cell
set uvhs_f2_cells $uvhs_cpu_ddr_bridge

# Keep the complete CPU/SoC hierarchy on the source side of the bridge.  Every
# memory-path clock then belongs to the CPU partition and only the DDR AXI
# crosses to the user card.
set uvhs_cpu_top [get_cells -quiet {core_def/U_CPU_TOP}]
if {[llength $uvhs_cpu_top] == 1} {
    lappend uvhs_f2_cells [lindex $uvhs_cpu_top 0]
} elseif {[llength $uvhs_cpu_top] > 1} {
    error "expected at most one CPU top cell, got [llength $uvhs_cpu_top]"
} else {
    puts "INFO: no core_def/U_CPU_TOP hierarchy; leave the CPU logic to automatic partitioning"
}

# Configuration path and DiffTest host endpoint are instantiated directly in
# core_def, outside the CPU hierarchy.
set uvhs_f2_cells [concat $uvhs_f2_cells [uvhs_existing_cells {
    core_def/CFG_AXI_bridge_i
    core_def/U_UVHS_FLASH_GBUS
    core_def/U_SYS_CFG
    core_def/u_rom
    core_def/xdma_ep_i
    core_def/U_GBUS_HOST
}]]

create_fpga -name b0.f2 -cells $uvhs_f2_cells
create_fpga -name b0.f0 -cells $uvhs_f0_cells

set uvhs_ddr_connector b0.F0_FMC0
set_property -name connector -value $uvhs_ddr_connector \
    -objects $uvhs_ddr_cell
set uvhs_bound_ddr_connector \
    [get_property -name connector -objects $uvhs_ddr_cell]
if {$uvhs_bound_ddr_connector ne $uvhs_ddr_connector} {
    error "failed to constrain UVHS DUT DDR to $uvhs_ddr_connector"
}
puts "INFO: async bridge [lindex $uvhs_cpu_ddr_bridge 0] defines the b0.f2/b0.f0 boundary"
puts "INFO: CPU/SoC source domain on b0.f2: $uvhs_f2_cells"
puts "INFO: user DDR controller on b0.f0: $uvhs_f0_cells"
puts "INFO: constrain UVHS DUT DDR to $uvhs_bound_ddr_connector"

unset -nocomplain uvhs_ddr_cell uvhs_cpu_ddr_bridge uvhs_f0_cells \
    uvhs_f2_cells uvhs_cpu_top uvhs_ddr_connector uvhs_bound_ddr_connector
