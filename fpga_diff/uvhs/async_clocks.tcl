################################################################################
# UVHS asynchronous clock constraints.
# This file is intentionally separate from src/constr/common/async_clocks.xdc,
# which is used by the Vivado flow. Keep XDMA-internal clock relationships
# visible unless the crossing is implemented by a CDC IP.
################################################################################

proc fpga_diff_collect_clocks {patterns} {
    set result {}
    foreach pattern $patterns {
        foreach clock [get_clocks -quiet $pattern] {
            if {[lsearch -exact $result $clock] < 0} {
                lappend result $clock
            }
        }
    }
    return $result
}

proc fpga_diff_set_async_pair {name from_clocks to_clocks} {
    if {![llength $from_clocks] || ![llength $to_clocks]} {
        puts "INFO: fpga_diff UVHS async skip $name, missing clocks"
        return
    }

    puts "INFO: fpga_diff UVHS async false paths $name: $from_clocks <-> $to_clocks"
    set_false_path -from $from_clocks -to $to_clocks
    set_false_path -from $to_clocks -to $from_clocks
}

proc fpga_diff_set_async_clock_groups {name from_clocks to_clocks} {
    if {![llength $from_clocks] || ![llength $to_clocks]} {
        puts "INFO: fpga_diff UVHS async clock-group skip $name, missing clocks"
        return
    }

    puts "INFO: fpga_diff UVHS async clock groups $name: $from_clocks <-> $to_clocks"
    set_clock_groups -asynchronous -group $from_clocks -group $to_clocks
}

proc fpga_diff_set_false_path_to_pins {name from_clocks to_pins} {
    if {![llength $from_clocks] || ![llength $to_pins]} {
        puts "INFO: fpga_diff UVHS async pin-path skip $name, missing clocks or pins: clocks=[llength $from_clocks] pins=[llength $to_pins]"
        return
    }

    puts "INFO: fpga_diff UVHS async false path $name: $from_clocks -> $to_pins"
    set_false_path -from $from_clocks -to $to_pins
}

proc fpga_diff_collect_pins_by_name {patterns} {
    set result {}
    foreach pattern $patterns {
        foreach pin [get_pins -quiet -hierarchical -filter "NAME =~ $pattern"] {
            if {[lsearch -exact $result $pin] < 0} {
                lappend result $pin
            }
        }
    }
    return $result
}

set fpga_diff_tm_clocks [fpga_diff_collect_clocks {TMCLK RTC_GATED_CLK}]
set fpga_diff_cpu_clocks [fpga_diff_collect_clocks {CPU_CLK_IN}]
set fpga_diff_debug_clocks [fpga_diff_collect_clocks {DEBUG_CLK_IN SOC_GATED_CLK}]
set fpga_diff_ddr_clocks [fpga_diff_collect_clocks {
    DDR_UI_CLK
    ddr_ref_clk
    clk7_p_pad_net*
    *c0_ddr4_ui_clk*
    *ddr4_ui_clk*
    mmcm_clkout*
    pll_clk*
}]
set fpga_diff_jtag_clocks [fpga_diff_collect_clocks {jtag_vclk *INTERNAL_TCK*}]
set fpga_diff_pcie_ref_clocks [fpga_diff_collect_clocks {pcie_ep_refclk}]
set fpga_diff_pcie_gt_clocks [fpga_diff_collect_clocks {
    qpll*outrefclk*
    qpll*outclk*
    GTYE4_CHANNEL_TXOUTCLK*
    */GTYE4_CHANNEL_PRIM_INST/TXOUTCLK
    *bufg_gt_txoutclkmon_inst/O
    xdma_ep_xdma_0_0_pcie4c_ip_gt_top_i_n_*
}]
set fpga_diff_xdma_pipe_clocks [fpga_diff_collect_clocks {
    pipe_clk
    */xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_intclk/O
}]
set fpga_diff_xdma_axi_clocks [fpga_diff_collect_clocks {M00_AXIS_ACLK* XDMA_AXI_ACLK}]
set fpga_diff_difftest_pcie_blackbox_clocks [fpga_diff_collect_clocks {
    DIFFTEST_PCIE_CLK
    core_def_xdma_ep_i_TO_DIFFTEST_PCIE_CLK_infer
    *TO_DIFFTEST_PCIE_CLK*infer*
}]
set fpga_diff_difftest_pcie_wiz_clocks [fpga_diff_collect_clocks {
    clk_out*_xdma_ep_clk_wiz*
}]
set fpga_diff_difftest_pcie_clocks [concat \
    $fpga_diff_difftest_pcie_blackbox_clocks \
    $fpga_diff_difftest_pcie_wiz_clocks]
set fpga_diff_uvw_sbus_readback_source_clocks [fpga_diff_collect_clocks {
    uvw_sbus_sysclk0
    s_clk_out1
}]
set fpga_diff_uvw_sbus_readback_pins [fpga_diff_collect_pins_by_name {
    *U_UVHS_UVW_AXI4_TO_DDR4/u_uvw_axi4_to_ddr4/u_sbus_bridge*/u_sbus3_ip_intf/u_uvw_ur_alp_if/u_uvw_sbus_alp_if_regs/reg_rd_data_reg*/D
    *u_sbus_bridge*/u_sbus3_ip_intf/u_uvw_ur_alp_if/u_uvw_sbus_alp_if_regs/reg_rd_data_reg*/D
}]

set fpga_diff_external_async_domains [list \
    [list tm $fpga_diff_tm_clocks] \
    [list cpu $fpga_diff_cpu_clocks] \
    [list debug $fpga_diff_debug_clocks] \
    [list ddr $fpga_diff_ddr_clocks] \
    [list jtag $fpga_diff_jtag_clocks] \
    [list pcie_ref $fpga_diff_pcie_ref_clocks]]

set fpga_diff_domain_count [llength $fpga_diff_external_async_domains]
for {set fpga_diff_i 0} {$fpga_diff_i < $fpga_diff_domain_count} {incr fpga_diff_i} {
    set fpga_diff_from [lindex $fpga_diff_external_async_domains $fpga_diff_i]
    for {set fpga_diff_j [expr {$fpga_diff_i + 1}]} {$fpga_diff_j < $fpga_diff_domain_count} {incr fpga_diff_j} {
        set fpga_diff_to [lindex $fpga_diff_external_async_domains $fpga_diff_j]
        fpga_diff_set_async_pair \
            "[lindex $fpga_diff_from 0]_to_[lindex $fpga_diff_to 0]" \
            [lindex $fpga_diff_from 1] \
            [lindex $fpga_diff_to 1]
    }
}

# XDMA AXI is 250 MHz, TO_DIFFTEST_PCIE_CLK is the clk_wiz 100 MHz output that
# feeds the async AXIS clock converter S clock. Constrain external crossings and
# the explicit AXIS clock-converter CDC boundary, but keep XDMA/PCIe-internal
# paths visible so PCIe IP timing is still checked.
set fpga_diff_xdma_s_axis_clocks $fpga_diff_difftest_pcie_clocks
set fpga_diff_xdma_m_axis_clocks $fpga_diff_xdma_axi_clocks
set fpga_diff_xdma_external_domains [concat \
    $fpga_diff_tm_clocks \
    $fpga_diff_cpu_clocks \
    $fpga_diff_debug_clocks \
    $fpga_diff_ddr_clocks \
    $fpga_diff_jtag_clocks \
    $fpga_diff_pcie_ref_clocks]

fpga_diff_set_async_pair xdma_difftest_to_external \
    $fpga_diff_xdma_s_axis_clocks \
    $fpga_diff_xdma_external_domains
fpga_diff_set_async_pair xdma_axi_to_external \
    $fpga_diff_xdma_m_axis_clocks \
    $fpga_diff_xdma_external_domains
fpga_diff_set_async_pair xdma_axis_clock_converter \
    $fpga_diff_xdma_s_axis_clocks \
    $fpga_diff_xdma_m_axis_clocks
fpga_diff_set_async_clock_groups xdma_axis_clock_converter \
    $fpga_diff_xdma_s_axis_clocks \
    $fpga_diff_xdma_m_axis_clocks
fpga_diff_set_async_pair xdma_difftest_to_gt_pipe \
    $fpga_diff_xdma_s_axis_clocks \
    [concat $fpga_diff_pcie_gt_clocks $fpga_diff_xdma_pipe_clocks]
fpga_diff_set_async_clock_groups xdma_difftest_to_gt_pipe \
    $fpga_diff_xdma_s_axis_clocks \
    [concat $fpga_diff_pcie_gt_clocks $fpga_diff_xdma_pipe_clocks]
fpga_diff_set_async_pair xdma_axi_to_gt_pipe \
    $fpga_diff_xdma_m_axis_clocks \
    [concat $fpga_diff_pcie_gt_clocks $fpga_diff_xdma_pipe_clocks]
fpga_diff_set_async_clock_groups xdma_axi_to_gt_pipe \
    $fpga_diff_xdma_m_axis_clocks \
    [concat $fpga_diff_pcie_gt_clocks $fpga_diff_xdma_pipe_clocks]

# UVHS may expose the same XDMA clk_wiz 100 MHz user clock twice: once as the
# real Vivado clk_wiz output and once as the xdma_ep black-box boundary output.
# Treating those as separate timed clocks creates large false hold violations
# through the XPM async FIFO write RAM. Keep the real CDC boundary constrained
# above, but suppress timing between these aliases.
fpga_diff_set_async_pair xdma_difftest_clock_alias \
    $fpga_diff_difftest_pcie_blackbox_clocks \
    $fpga_diff_difftest_pcie_wiz_clocks

fpga_diff_set_false_path_to_pins uvw_sbus_bridge_alp_readback \
    $fpga_diff_uvw_sbus_readback_source_clocks \
    $fpga_diff_uvw_sbus_readback_pins

unset -nocomplain fpga_diff_tm_clocks fpga_diff_cpu_clocks fpga_diff_debug_clocks
unset -nocomplain fpga_diff_ddr_clocks fpga_diff_jtag_clocks fpga_diff_pcie_ref_clocks
unset -nocomplain fpga_diff_pcie_gt_clocks fpga_diff_xdma_pipe_clocks
unset -nocomplain fpga_diff_xdma_axi_clocks fpga_diff_difftest_pcie_clocks
unset -nocomplain fpga_diff_difftest_pcie_blackbox_clocks fpga_diff_difftest_pcie_wiz_clocks
unset -nocomplain fpga_diff_uvw_sbus_readback_source_clocks
unset -nocomplain fpga_diff_uvw_sbus_readback_pins
unset -nocomplain fpga_diff_external_async_domains fpga_diff_domain_count
unset -nocomplain fpga_diff_i fpga_diff_j fpga_diff_from fpga_diff_to
unset -nocomplain fpga_diff_xdma_s_axis_clocks fpga_diff_xdma_m_axis_clocks
unset -nocomplain fpga_diff_xdma_external_domains
rename fpga_diff_collect_clocks {}
rename fpga_diff_collect_pins_by_name {}
rename fpga_diff_set_async_pair {}
rename fpga_diff_set_async_clock_groups {}
rename fpga_diff_set_false_path_to_pins {}
