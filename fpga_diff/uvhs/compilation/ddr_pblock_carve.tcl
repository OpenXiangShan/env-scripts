# Appended by uvhs/compilation/prepare_ip.sh to the DDR prePlace script that
# ships with the vendor checkpoint.
#
# The vendor system-bus script (uvw_sbus_after_link.tcl, sourced after link)
# pins the FMC2/FMC1 Aurora fabric to CLOCKREGION_X7Y10:CLOCKREGION_X8Y19.  On
# b0.f2 that range contains the whole column the user DDR needs, and two
# exclusive pblocks cannot share area: the DDR is pushed into the single X6
# column and its internal mmcm_clkout0 reset distribution then misses setup by
# about 1.2 ns (UVHS reports APS TSO-5 and refuses the bitstream).
#
# Carve the DDR rows out of the system-bus pblock so both keep exclusive area.
# The carve is a no-op when the two pblocks do not overlap, which is the case
# for the default topology with the DDR on b0.f0.
if {[llength [get_pblocks -quiet DDR_BA0_loc]] == 1 &&
    [llength [get_pblocks -quiet pblock_uvw_sbus_0]] == 1} {
    set uvhs_ddr_range [get_property GRID_RANGES [get_pblocks DDR_BA0_loc]]
    if {[regexp {CLOCKREGION_X(\d+)Y(\d+):CLOCKREGION_X(\d+)Y(\d+)} $uvhs_ddr_range -> \
            uvhs_ddr_x0 uvhs_ddr_y0 uvhs_ddr_x1 uvhs_ddr_y1]} {
        set uvhs_ddr_rows "CLOCKREGION_X${uvhs_ddr_x0}Y${uvhs_ddr_y0}:CLOCKREGION_X${uvhs_ddr_x1}Y${uvhs_ddr_y1}"
        resize_pblock [get_pblocks pblock_uvw_sbus_0] -remove $uvhs_ddr_rows
        puts "INFO: carved $uvhs_ddr_rows out of pblock_uvw_sbus_0 (now [get_property GRID_RANGES [get_pblocks pblock_uvw_sbus_0]])"
        unset uvhs_ddr_x0 uvhs_ddr_y0 uvhs_ddr_x1 uvhs_ddr_y1 uvhs_ddr_rows
    } else {
        puts "WARNING: unexpected DDR pblock range '$uvhs_ddr_range'; system-bus pblock left unchanged"
    }
    unset uvhs_ddr_range
} else {
    puts "INFO: DDR and system-bus pblocks do not both exist; no carve needed"
}
