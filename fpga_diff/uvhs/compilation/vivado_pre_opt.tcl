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

set fpga_diff_async_groups [list]
foreach fpga_diff_clock {TMCLK ddr_ref_clk CPU_CLK_IN jtag_vclk pcie_ep_refclk} {
    lappend fpga_diff_async_groups -group \
        [get_clocks -include_generated_clocks $fpga_diff_clock]
}
set_clock_groups -asynchronous {*}$fpga_diff_async_groups
