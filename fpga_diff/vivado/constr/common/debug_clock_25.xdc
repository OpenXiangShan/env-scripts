# Debug clock input: clk5_p is the 25MHz board debug clock (default).
# Selected by TIMING_DEBUG_CLK_PERIOD_NS (40.000) in constraints.tcl.
create_clock -period 40.000 -name DEBUG_CLK_IN [get_ports clk5_p]
