################################################################################
# Pin assignment for fpga_diff on the U2.2 VU19P platform.
#
# CPU, PCIe, and low-speed I/O use b0.f2. DDR-owned status follows the user DDR
# controller on b0.f0.
################################################################################

proc pin_name {top port} {
    if {$top eq "" || $top eq "none"} {
        return $port
    }
    return "${top}.${port}"
}

set top [uvhs::env_or_default UVHS_ASSIGN_PIN_TOP fpga_top_debug]
set xdma_link_width [string toupper [string trim [uvhs::env_or_default XDMA_LINK_WIDTH X4]]]
if {$xdma_link_width ni {X4 X8}} {
    error "XDMA_LINK_WIDTH must be one of X4/X8, got '$xdma_link_width'"
}
set xdma_lane_count [expr {$xdma_link_width eq "X8" ? 8 : 4}]

set apc16_indices {
    101 102 104 105 114 115 117 57
    81 82 84 85 94 95 97 98
    61 62 64 65 74 75 77 78
    118 58 54 55 44 45 41 42
}

proc apc16_pin {port slot} {
    global apc16_indices
    global top
    assign_pin -port [pin_name $top $port] -connector b0.F2_APC16 -index [lindex $apc16_indices $slot]
}

# Low-speed debug/control pins on the unused F2 APC16 connector.
# rstn_sw* are exported as UVHS global resets and must not also be assign_pin'd.
apc16_pin led0 3
apc16_pin led2 4
apc16_pin led3 5

# UART0 defaults to the F2 APC16 sideband connector.  A two-FPGA build can
# route it through the F1 UV_FMCH_FLASH USB-UART with FMC indices 311/270.
set uvhs_uart0_connector [uvhs::env_or_default UVHS_UART0_CONNECTOR b0.F2_APC16]
set uvhs_uart0_tx_index [uvhs::env_or_default UVHS_UART0_TX_INDEX [lindex $apc16_indices 6]]
set uvhs_uart0_rx_index [uvhs::env_or_default UVHS_UART0_RX_INDEX [lindex $apc16_indices 7]]
puts "INFO: UART0 pins: TX ${uvhs_uart0_connector}\[$uvhs_uart0_tx_index\], RX ${uvhs_uart0_connector}\[$uvhs_uart0_rx_index\]"
assign_pin -port [pin_name $top uart0_sout] -connector $uvhs_uart0_connector -index $uvhs_uart0_tx_index
assign_pin -port [pin_name $top uart0_sin] -connector $uvhs_uart0_connector -index $uvhs_uart0_rx_index
apc16_pin uart1_sout 8
apc16_pin uart1_sin 9
apc16_pin uart2_sout 10
apc16_pin uart2_sin 11

apc16_pin JTAG_TCK 12
apc16_pin JTAG_TMS 13
apc16_pin JTAG_TDI 14
apc16_pin JTAG_TDO 15
apc16_pin JTAG_TRSTn 16

apc16_pin SD_CLK 17
apc16_pin SD_CMD 18
apc16_pin SD_DATA0 19
apc16_pin SD_DATA1 20
apc16_pin SD_DATA2 21
apc16_pin SD_DATA3 22
apc16_pin SD_DECT 23

# U2 global clocks on F2 use the package pins declared by the board file.
assign_pin -port [pin_name $top clk6_p] -fpga b0.f2 -pin CA39
assign_pin -port [pin_name $top clk6_n] -fpga b0.f2 -pin CA40
assign_pin -port [pin_name $top clk8_p] -fpga b0.f2 -pin G36
assign_pin -port [pin_name $top clk8_n] -fpga b0.f2 -pin F36
assign_pin -port [pin_name $top clk5_p] -fpga b0.f2 -pin AW17
assign_pin -port [pin_name $top clk5_n] -fpga b0.f2 -pin AY17

assign_pin -port [pin_name $top pcie_ep_lnk_up] -connector b0.F2_APC16 -index 58

# XDMA endpoint signals. X4 uses the HGC7 lane group from the Hejian official
# XDMA EP example; bind HGC6 only when X8 is explicitly selected.
puts "INFO: assign XDMA PCIe pins for $xdma_link_width"
assign_pin -port [pin_name $top pcie_ep_gt_ref_clk_p] -connector b0.F2_HGC7 -index 29
assign_pin -port [pin_name $top pcie_ep_gt_ref_clk_n] -connector b0.F2_HGC7 -index 30
assign_pin -port [pin_name $top pcie_ep_perstn] -connector b0.F2_APC16 -index 118

set xdma_rx_connectors {b0.F2_HGC7 b0.F2_HGC7 b0.F2_HGC7 b0.F2_HGC7 b0.F2_HGC6 b0.F2_HGC6 b0.F2_HGC6 b0.F2_HGC6}
set xdma_tx_connectors {b0.F2_HGC7 b0.F2_HGC7 b0.F2_HGC7 b0.F2_HGC7 b0.F2_HGC6 b0.F2_HGC6 b0.F2_HGC6 b0.F2_HGC6}
set xdma_rxp_indices {16 13 4 1 16 13 4 1}
set xdma_rxn_indices {17 14 5 2 17 14 5 2}
set xdma_txp_indices {35 32 23 20 35 32 23 20}
set xdma_txn_indices {36 33 24 21 36 33 24 21}
for {set i 0} {$i < $xdma_lane_count} {incr i} {
    assign_pin -port [pin_name $top [format {pci_ep_rxp[%d]} $i]] -connector [lindex $xdma_rx_connectors $i] -index [lindex $xdma_rxp_indices $i]
    assign_pin -port [pin_name $top [format {pci_ep_rxn[%d]} $i]] -connector [lindex $xdma_rx_connectors $i] -index [lindex $xdma_rxn_indices $i]
    assign_pin -port [pin_name $top [format {pci_ep_txp[%d]} $i]] -connector [lindex $xdma_tx_connectors $i] -index [lindex $xdma_txp_indices $i]
    assign_pin -port [pin_name $top [format {pci_ep_txn[%d]} $i]] -connector [lindex $xdma_tx_connectors $i] -index [lindex $xdma_txn_indices $i]
}

# The vendor DDR DCP declares its PDDR4DME binding through UV_HW_IP metadata.
# UVHS owns those physical pins; assigning clk7 or DDR4_DIMM ports here would
# double-constrain the same daughter-card pads.
puts "INFO: vendor uvw_axi4_to_ddr4 IP owns the PDDR4DME DDR pin assignment"
