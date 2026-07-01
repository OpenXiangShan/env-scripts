################################################################################
# UVHS frontend flow for UVHS DDR integration.
################################################################################

if {![info exists ::env(UVHS_BLACKBOX_JTAG_DDR_SUBSYS)] || $::env(UVHS_BLACKBOX_JTAG_DDR_SUBSYS) eq ""} {
    set ::env(UVHS_BLACKBOX_JTAG_DDR_SUBSYS) 0
}

if {![info exists ::env(UVHS_REQUIRED_DCP_MODULES)] || $::env(UVHS_REQUIRED_DCP_MODULES) eq ""} {
    set ::env(UVHS_REQUIRED_DCP_MODULES) {blk_mem_gen_0 AXI_bridge data_bridge vio_0 xdma_ep uvw_axi4_to_ddr4}
}

if {![info exists ::env(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP)] || $::env(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP) eq ""} {
    set ::env(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP) 1
}

source [file join [file dirname [info script]] frontend_run.tcl]
