# Debug clock input: clk5_p driven at 50MHz (TIMING_DEBUG_CLK_PERIOD_NS=20.000).
create_clock -period 20.000 -name DEBUG_CLK_IN [get_ports clk5_p]
