####################################################################################
# XDMA / Host-trigger instrumentation ILA
# Keep this file as plain XDC commands only; Vivado XDC parsing does not support
# Tcl proc definitions here.
####################################################################################

if {![info exists ::env(ILA_DEPTH)] || ![string is integer -strict $::env(ILA_DEPTH)] || $::env(ILA_DEPTH) <= 0} {
  error "ILA_DEPTH must be set to a positive integer"
}
set ila_depth $::env(ILA_DEPTH)

create_debug_core u_ila_xdma_ctrl ila
set_property C_DATA_DEPTH $ila_depth [get_debug_cores u_ila_xdma_ctrl]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_xdma_ctrl]
connect_debug_port u_ila_xdma_ctrl/clk [get_nets -of_objects [get_pins core_def/sys_clk_i]]

set_property port_width 1 [get_debug_ports u_ila_xdma_ctrl/probe0]
connect_debug_port u_ila_xdma_ctrl/probe0 [get_nets {core_def/io_host_ila_trigger}]
