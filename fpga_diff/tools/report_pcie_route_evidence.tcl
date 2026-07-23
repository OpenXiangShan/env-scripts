if {$argc != 2} {
    puts stderr "usage: vivado -mode batch -source report_pcie_route_evidence.tcl -tclargs <routed.dcp> <output.txt>"
    exit 64
}

set dcp [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
open_checkpoint $dcp

set fh [open $out w]

proc prop_or_dash {obj prop} {
    if {[catch {set value [get_property $prop $obj]}]} {
        return "-"
    }
    if {$value eq ""} {
        return "-"
    }
    return $value
}

proc emit_objects {fh label objects props} {
    puts $fh "## $label count=[llength $objects]"
    foreach obj [lsort $objects] {
        set fields [list "name=$obj"]
        foreach prop $props {
            lappend fields "${prop}=[prop_or_dash $obj $prop]"
        }
        puts $fh [join $fields " | "]
    }
}

puts $fh "## checkpoint"
puts $fh "dcp=$dcp"
puts $fh "design=[current_design]"
puts $fh "part=[get_property PART [current_design]]"

set pcie_ports {}
foreach pattern {
    *pcie* *PCIE* *pci_ep* *PCI_EP* *diff_clock* *reset_rtl*
} {
    foreach port [get_ports -quiet $pattern] {
        if {[lsearch -exact $pcie_ports $port] < 0} {
            lappend pcie_ports $port
        }
    }
}
emit_objects $fh ports $pcie_ports {
    DIRECTION PACKAGE_PIN LOC IOSTANDARD DIFF_TERM
    IO_BUFFER_TYPE CLOCK_BUFFER_TYPE PULLTYPE
}

puts $fh "## port connectivity"
foreach port [lsort $pcie_ports] {
    set nets [get_nets -quiet -segments -of_objects $port]
    set pins [get_pins -quiet -leaf -of_objects $nets]
    puts $fh "port=$port"
    puts $fh "  nets=[join [lsort $nets] { }]"
    puts $fh "  pins=[join [lsort $pins] { }]"
}

set pcie_cells {}
foreach pattern {
    *pcie_4_c_e4_inst* *PCIE4CE4* *pcie4c_ip_i*
} {
    foreach cell [get_cells -hierarchical -quiet $pattern] {
        if {[lsearch -exact $pcie_cells $cell] < 0} {
            lappend pcie_cells $cell
        }
    }
}
emit_objects $fh pcie_cells $pcie_cells {REF_NAME PRIMITIVE_TYPE LOC BEL IS_LOC_FIXED}

set gt_cells {}
foreach cell [get_cells -hierarchical -quiet -filter {
    REF_NAME =~ IBUFDS_GTE* ||
    REF_NAME =~ GTYE4_CHANNEL* ||
    REF_NAME =~ GTYE4_COMMON* ||
    PRIMITIVE_TYPE =~ *GTYE4* ||
    PRIMITIVE_TYPE =~ *IBUFDS_GTE*
}] {
    lappend gt_cells $cell
}
emit_objects $fh gt_and_refclk_cells $gt_cells {REF_NAME PRIMITIVE_TYPE LOC BEL IS_LOC_FIXED}

puts $fh "## GT/refclk cell connectivity"
foreach cell [lsort $gt_cells] {
    puts $fh "cell=$cell"
    foreach pin [lsort [get_pins -quiet -of_objects $cell]] {
        set nets [get_nets -quiet -segments -of_objects $pin]
        if {[llength $nets]} {
            puts $fh "  pin=$pin | DIR=[prop_or_dash $pin DIRECTION] | nets=[join $nets { }]"
        }
    }
}

close $fh
close_design
puts "INFO: wrote PCIe routed evidence to $out"
