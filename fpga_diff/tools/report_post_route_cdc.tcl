# Post-route CDC diagnostics for an existing Vivado DCP.
#
# Usage:
#   vivado -mode batch -source report_post_route_cdc.tcl \
#     -tclargs <routed.dcp> <out-dir>
#
# The script is intentionally read-only with respect to the checkpoint.  It
# writes report files and small Tcl-generated summaries under <out-dir>.

if {![info exists ::argv] || [llength $::argv] < 2} {
    puts "ERROR: usage: report_post_route_cdc.tcl <routed.dcp> <out-dir>"
    exit 1
}

set dcp_file [file normalize [lindex $::argv 0]]
set out_dir [file normalize [lindex $::argv 1]]

if {![file exists $dcp_file]} {
    puts "ERROR: routed DCP not found: $dcp_file"
    exit 1
}

file mkdir $out_dir

proc write_text_file {path text} {
    set fh [open $path w]
    puts -nonewline $fh $text
    close $fh
}

proc append_line {fh line} {
    puts $fh $line
}

proc try_report {description args} {
    puts "INFO: $description"
    if {[catch {uplevel #0 $args} err]} {
        puts "WARNING: $description failed: $err"
        return 0
    }
    return 1
}

proc remove_if_exists {path} {
    if {[file exists $path]} {
        file delete -force $path
    }
    return $path
}

proc safe_get_property {prop object} {
    if {[catch {set value [get_property $prop $object]}] || $value eq ""} {
        return ""
    }
    return $value
}

proc clock_or_empty {clock_name} {
    return [get_clocks -quiet $clock_name]
}

proc count_objects {objects} {
    if {$objects eq ""} {
        return 0
    }
    return [llength $objects]
}

proc safe_current_design {} {
    if {[catch {current_design} design] || $design eq ""} {
        return "unknown"
    }
    return $design
}

proc safe_design_part {} {
    set design [safe_current_design]
    if {$design ne "unknown"} {
        foreach prop {PART DEVICE} {
            if {![catch {set value [get_property $prop $design]}] && $value ne ""} {
                return $value
            }
        }
    }
    return "unknown"
}

proc write_clock_pair_summary {fh from_clock to_clock} {
    set from [clock_or_empty $from_clock]
    set to [clock_or_empty $to_clock]
    append_line $fh ""
    append_line $fh "### $from_clock -> $to_clock"
    append_line $fh "from_clock_count=[count_objects $from] to_clock_count=[count_objects $to]"
    if {![llength $from] || ![llength $to]} {
        append_line $fh "missing_clock=1"
        return
    }

    set paths [get_timing_paths -quiet -from $from -to $to -max_paths 20]
    append_line $fh "timing_path_count=[count_objects $paths]"
    foreach path $paths {
        set startpoint [get_property STARTPOINT_PIN $path]
        set endpoint [get_property ENDPOINT_PIN $path]
        set slack [get_property SLACK $path]
        append_line $fh "path slack=$slack start=$startpoint end=$endpoint"
    }

    set from_cells [get_cells -quiet -hierarchical -filter "NAME =~ *${from_clock}*"]
    set to_cells [get_cells -quiet -hierarchical -filter "NAME =~ *${to_clock}*"]
    append_line $fh "name_match_from_cells=[count_objects $from_cells]"
    foreach cell [lrange $from_cells 0 19] {
        append_line $fh "  from_cell=$cell ref=[get_property REF_NAME $cell]"
    }
    append_line $fh "name_match_to_cells=[count_objects $to_cells]"
    foreach cell [lrange $to_cells 0 19] {
        append_line $fh "  to_cell=$cell ref=[get_property REF_NAME $cell]"
    }
}

open_checkpoint $dcp_file

set summary_file [file join $out_dir cdc_diagnostics_summary.txt]
set fh [open $summary_file w]
append_line $fh "dcp=$dcp_file"
append_line $fh "part=[safe_design_part]"
append_line $fh "design=[safe_current_design]"
append_line $fh "vivado=[version -short]"
append_line $fh ""
append_line $fh "## Clocks"
foreach clk [lsort [get_clocks -quiet *]] {
    set period [safe_get_property PERIOD $clk]
    set waveform [safe_get_property WAVEFORM $clk]
    set master [safe_get_property MASTER_CLOCK $clk]
    append_line $fh "clock=$clk period=$period waveform={$waveform} master=$master"
}

append_line $fh ""
append_line $fh "## Native wrapper markers"
foreach pattern {
    *core_def_native*
    *native*
    *native_rstn_sync*
    *uvhs_axi64_to_axi256*
    *uvhs_debug*
    *simtop_cfg_axilite*
} {
    set cells [get_cells -quiet -hierarchical -filter "NAME =~ $pattern"]
    append_line $fh "pattern=$pattern count=[count_objects $cells]"
    foreach cell [lrange $cells 0 49] {
        append_line $fh "  cell=$cell ref=[get_property REF_NAME $cell]"
    }
}

append_line $fh ""
append_line $fh "## CDC critical clock-pair probes"
set critical_pairs {
    {mmcm_clkout0 CPU_CLK_IN}
    {s_clk_out0 FP_CLK_200M_P}
    {s_clk_out1 FP_CLK_200M_P}
    {uvw_sbus_GTYE4_CHANNEL_RXOUTCLK0 clk_out4_uvw_ctrl_pll}
    {uvw_sbus_GTYE4_CHANNEL_TXOUTCLK0 clk_out4_uvw_ctrl_pll}
    {uvw_sbus_sysclk0 clk_out4_uvw_ctrl_pll}
    {uvw_sbus_sysclk1 clk_out4_uvw_ctrl_pll}
    {uvw_sbus_clk_i s_clk_out0}
    {uvw_sbus_clk_i s_clk_out1}
    {uvw_sbus_sysclk0 uvw_sbus_GTYE4_CHANNEL_TXOUTCLK0}
    {uvw_sbus_sysclk1 uvw_sbus_GTYE4_CHANNEL_TXOUTCLK0}
    {clk_out4_uvw_ctrl_pll uvw_sbus_sysclk0}
    {s_clk_out0 uvw_sbus_sysclk0}
    {s_clk_out1 uvw_sbus_sysclk0}
    {uvw_sbus_GTYE4_CHANNEL_TXOUTCLK0 uvw_sbus_sysclk0}
    {difftest_pcie_clock_bufg_n CPU_CLK_IN}
    {CPU_CLK_IN difftest_pcie_clock_bufg_n}
    {difftest_pcie_clock_bufg_n pipe_clk}
    {pipe_clk difftest_pcie_clock_bufg_n}
    {difftest_pcie_clock_bufg_n xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_30}
    {xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_30 difftest_pcie_clock_bufg_n}
    {pcie_ep_refclk difftest_pcie_clock_bufg_n}
    {difftest_pcie_clock_bufg_n pcie_ep_refclk}
    {pcie_ep_refclk pipe_clk}
    {pipe_clk pcie_ep_refclk}
    {pcie_ep_refclk xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_30}
    {xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_30 pcie_ep_refclk}
    {pipe_clk xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_30}
    {xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_30 pipe_clk}
}
foreach pair $critical_pairs {
    write_clock_pair_summary $fh [lindex $pair 0] [lindex $pair 1]
}
close $fh

try_report "write CDC summary" \
    report_cdc -file [remove_if_exists [file join $out_dir report_cdc_summary.rpt]]
if {![try_report "write CDC details" \
        report_cdc -details -file [remove_if_exists [file join $out_dir report_cdc_details.rpt]]]} {
    try_report "write CDC verbose fallback" \
        report_cdc -verbose -file [remove_if_exists [file join $out_dir report_cdc_verbose.rpt]]
}
try_report "write CDC details verbose" \
    report_cdc -details -verbose -file [remove_if_exists [file join $out_dir report_cdc_details_verbose.rpt]]
try_report "write clock interaction" \
    report_clock_interaction -file [remove_if_exists [file join $out_dir report_clock_interaction.rpt]]
try_report "write check timing" \
    check_timing -file [remove_if_exists [file join $out_dir check_timing.rpt]] -verbose
try_report "write bus skew" \
    report_bus_skew -file [remove_if_exists [file join $out_dir report_bus_skew.rpt]]
try_report "write route status" \
    report_route_status -file [remove_if_exists [file join $out_dir route_status.rpt]]

puts "INFO: wrote CDC diagnostics to $out_dir"
close_design
exit
