open_checkpoint [lindex $argv 0]
set out [lindex $argv 1]
set fh [open $out w]
foreach p [lsort [get_ports *]] {
    puts $fh [format "%-48s %s" $p [get_property DIRECTION $p]]
}
close $fh
