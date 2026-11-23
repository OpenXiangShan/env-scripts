# Read the generated constraints as Tcl lists without executing them.
set constraints [open hw.dat/Compile/Partition/part_cstr.tcl r]
set ddr_probe_groups {}
while {[gets $constraints line] >= 0} {
    if {[lindex $line 0] ne "create_group"} { continue }
    set source [lsearch -exact $line -source]
    set cells [lsearch -exact $line -cells]
    if {$source < 0 || $cells < 0 ||
        [lindex $line [expr {$source + 1}]] ne "probe"} {
        continue
    }
    if {"core_def/U_UVHS_UVW_AXI4_TO_DDR4" ni [lindex $line [expr {$cells + 1}]]} {
        continue
    }
    set name [lsearch -exact $line -name]
    if {$name < 0 || [lindex $line [expr {$name + 1}]] eq ""} {
        error "UVHS generated an unnamed DDR probe group"
    }
    lappend ddr_probe_groups [lindex $line [expr {$name + 1}]]
}
close $constraints
if {[llength $ddr_probe_groups] > 1} {
    error "UVHS generated multiple DDR probe groups: $ddr_probe_groups"
}
set ddr_probe_group [lindex $ddr_probe_groups 0]
if {$ddr_probe_group ne ""} {
    puts "INFO: keep DDR probe group $ddr_probe_group on b0.f0"
    create_fpga -name b0.f0 -groups [list $ddr_probe_group] -update
}
