source [file join [file dirname [file normalize [info script]]] flow_common.tcl]
set_working_space hw.dat
create_system_design -name VU19P_X4 -platform U2.2
uvhs::source_required assemble.tcl
set ::env(UVHS_ASSIGN_PIN_TOP) none
uvhs::source_required assign_pin.tcl
unset ::env(UVHS_ASSIGN_PIN_TOP)
create_design -name test
read_netlist
link_design
set p_exact [get_pins -quiet {core_def/U_GBUS_GENERAL_BUS/sysbus_ghbd_i[200]}]
set p_wild [get_pins -quiet -hierarchical {core_def/U_GBUS_GENERAL_BUS/sysbus_ghbd_i[*]}]
puts "DBG pins exact=$p_exact"
puts "DBG pins wildcard=$p_wild"
puts "DBG ports wildcard=[get_ports -quiet -hierarchical *sysbus_ghbd_i*]"
puts "DBG nets wildcard=[get_nets -quiet -hierarchical *sysbus_ghbd_i*]"
puts "DBG cells wildcard=[get_cells -quiet -hierarchical *U_GBUS_GENERAL_BUS*]"
puts "DBG all pins wildcard=[get_pins -quiet -hierarchical *U_GBUS_GENERAL_BUS*]"
exit
