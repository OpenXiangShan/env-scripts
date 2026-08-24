################################################################################
# Vivado constraints that must be applied after the UVHS netlist is linked.
################################################################################

set fpga_diff_refclk_ports {}
foreach pattern {
    pcie_ep_gt_ref_clk_p_pad_net_*
    pcie_ep_gt_ref_clk_n_pad_net_*
    pcie_ep_gt_ref_clk_p
    pcie_ep_gt_ref_clk_n
} {
    foreach port [get_ports -quiet $pattern] {
        if {[lsearch -exact $fpga_diff_refclk_ports $port] < 0} {
            lappend fpga_diff_refclk_ports $port
        }
    }
}
if {[llength $fpga_diff_refclk_ports]} {
    # The imported XDMA IP owns the IBUFDS_GTE4. Prevent Vivado from inserting
    # a fabric input/clock buffer in front of that primitive.
    set_property IO_BUFFER_TYPE NONE $fpga_diff_refclk_ports
    set_property CLOCK_BUFFER_TYPE NONE $fpga_diff_refclk_ports
    puts "INFO: kept XDMA GT refclk pads unbuffered: $fpga_diff_refclk_ports"
}

proc fpga_diff_mark_async_regs {label patterns} {
    set cells {}
    foreach pattern $patterns {
        foreach cell [get_cells -hier -quiet \
            -filter "IS_SEQUENTIAL && NAME =~ $pattern"] {
            if {[lsearch -exact $cells $cell] < 0} {
                lappend cells $cell
            }
        }
    }
    if {[llength $cells]} {
        set_property ASYNC_REG TRUE $cells
    }
    puts "INFO: XDMA CDC $label ASYNC_REG count=[llength $cells]"
    return $cells
}

set fpga_diff_xdma_cdc_cells {}
foreach {label patterns} {
    axi_clock_converter {
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/gen_clock_conv.gen_async_lite_conv*/clock_conv_lite_*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/gen_clock_conv.gen_async_lite_conv*/clock_conv_lite_*/handshake/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*clock_conv_lite*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*handshake*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*cdc*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*sync*/*_reg*
    }
    axi_xpm_cdc {
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/*xpm_cdc*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/inst/*xpm_cdc*/inst/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*xpm_cdc*/*_reg*
        */core_def/xdma_ep_i/axi_interconnect_0/*/auto_cc/*xpm_cdc*/inst/*_reg*
    }
    xdma_reset_and_link {
        */core_def/xdma_ep_i/xdma_0/inst/*/*cdc*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/*cdc*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/xpm_cdc*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/xpm_cdc*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/arststages_ff_reg*
        */core_def/xdma_ep_i/xdma_0/inst/*/*user_rst*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/udma_wrapper/dma_top/user_rst*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/udma_wrapper/dma_top/*user_rst*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*cdc*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*cdc*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*sync*/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*sync*/inst/*_reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*rst*sync*reg*
        */core_def/xdma_ep_i/xdma_0/inst/pcie4c_ip_i/inst/*/*reset*sync*reg*
    }
} {
    foreach cell [fpga_diff_mark_async_regs $label $patterns] {
        if {[lsearch -exact $fpga_diff_xdma_cdc_cells $cell] < 0} {
            lappend fpga_diff_xdma_cdc_cells $cell
        }
    }
}
puts "INFO: XDMA CDC total ASYNC_REG count=[llength $fpga_diff_xdma_cdc_cells]"

# UVHS emits replicated clock cones as primary clocks in each FPGA constraint
# file. Rebuild their source relationship after Vivado links the partition so
# CDC signoff still recognizes the original master clock.
foreach {fpga_diff_clock fpga_diff_master fpga_diff_gate} {
    SOC_GATED_CLK CPU_CLK_IN SOC_CLK_CTRL_UVin_bufgce_1
    RTC_GATED_CLK TMCLK      RTC_CLK_CTRL_UVin_bufgce_1
} {
    set fpga_diff_gate_input [get_pins -hierarchical -quiet -filter \
        "NAME =~ */UV_REPLICATED_CLOCKCONE/${fpga_diff_gate}/I"]
    set fpga_diff_gate_output [get_pins -hierarchical -quiet -filter \
        "NAME =~ */UV_REPLICATED_CLOCKCONE/${fpga_diff_gate}/O"]
    if {![llength $fpga_diff_gate_input] && ![llength $fpga_diff_gate_output]} {
        continue
    }
    set fpga_diff_master_clock [get_clocks -quiet $fpga_diff_master]
    if {[llength $fpga_diff_master_clock] != 1 ||
        [llength $fpga_diff_gate_input] != 1 ||
        [llength $fpga_diff_gate_output] != 1} {
        error "required replicated clock path not found for $fpga_diff_clock"
    }
    create_generated_clock -add -name $fpga_diff_clock \
        -master_clock $fpga_diff_master_clock -source $fpga_diff_gate_input \
        -divide_by 1 $fpga_diff_gate_output
}

set fpga_diff_async_groups [list]
foreach fpga_diff_clock {TMCLK ddr_ref_clk CPU_CLK_IN jtag_vclk pcie_ep_refclk} {
    lappend fpga_diff_async_groups -group \
        [get_clocks -include_generated_clocks $fpga_diff_clock]
}
set_clock_groups -asynchronous {*}$fpga_diff_async_groups

# The DDR reset controller is clocked by the MIG MMCM. When partitioning puts
# its peripheral_aresetn consumer on another FPGA, UVHS inserts a TDM input
# synchronizer clocked by the GT TX clock. The MIG clock is not a DUT clock, so
# the generated DUT-to-TDM exceptions do not cover this reset-only crossing.
set fpga_diff_ddr_reset_regs [get_cells -hier -quiet -filter {
    IS_SEQUENTIAL &&
    NAME =~ */core_def/U_UVHS_UVW_AXI4_TO_DDR4/*/proc_sys_reset_0/U0/ACTIVE_LOW_PR_OUT_DFF*
}]
if {[llength $fpga_diff_ddr_reset_regs]} {
    set fpga_diff_tdm_tx_sync_candidates [get_pins -hier -quiet -filter {
        REF_PIN_NAME == D &&
        NAME =~ */uvtdm_tx_ctrl_inst/sync_flop_0_reg*/D
    }]
    set fpga_diff_tdm_tx_sync_d_pins {}
    if {[llength $fpga_diff_tdm_tx_sync_candidates]} {
        set fpga_diff_ddr_reset_endpoints \
            [all_fanout -flat -endpoints_only -from $fpga_diff_ddr_reset_regs]
        foreach fpga_diff_pin $fpga_diff_tdm_tx_sync_candidates {
            if {[lsearch -exact $fpga_diff_ddr_reset_endpoints $fpga_diff_pin] >= 0} {
                lappend fpga_diff_tdm_tx_sync_d_pins $fpga_diff_pin
            }
        }
    }
    if {[llength $fpga_diff_tdm_tx_sync_d_pins]} {
        set_false_path -from $fpga_diff_ddr_reset_regs \
            -to $fpga_diff_tdm_tx_sync_d_pins
        puts "INFO: constrained DDR reset-to-TDM CDC: \
            sources=[llength $fpga_diff_ddr_reset_regs] \
            destinations=[llength $fpga_diff_tdm_tx_sync_d_pins]"
    } else {
        puts "INFO: no DDR reset-to-TDM CDC endpoints on this FPGA"
    }
} else {
    puts "INFO: no DDR reset-to-TDM CDC sources on this FPGA"
}
