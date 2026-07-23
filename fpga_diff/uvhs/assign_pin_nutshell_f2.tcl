################################################################################
# Pin assignment for NutShell fpga_diff on a single U2.2 VU19P FPGA (b0.f2).
#
# This file is intended for UVHS flow bring-up on the current lab machine.  The
# reference flow keeps only b0.f2 plugged in, so all user-visible top ports must
# bind to b0.F2_* connectors instead of the original mixed F0/F1/F2 template.
################################################################################

proc assign_indexed_ports {prefix count connector indices} {
    for {set i 0} {$i < $count} {incr i} {
        set port [format {%s[%d]} $prefix $i]
        assign_pin -port $port -connector $connector -index [lindex $indices $i]
    }
}

proc pin_name {top port} {
    if {$top eq "" || $top eq "none"} {
        return $port
    }
    return "${top}.${port}"
}

set top [env_or_default UVHS_ASSIGN_PIN_TOP [env_or_default UVHS_TOP fpga_top_debug]]
set uvhs_skip_pcie_pins [expr {[env_or_default UVHS_SKIP_PCIE_PINS 0] eq "1"}]
set xdma_link_width [string toupper [string trim [env_or_default XDMA_LINK_WIDTH X4]]]
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

# Low-speed debug/control pins on the unused f2 APC16 connector.
# rstn_sw* are exported as UVHS global resets and must not also be assign_pin'd.
apc16_pin led0 3
apc16_pin led2 4
apc16_pin led3 5

# UART0 defaults to the F2 APC16 sideband connector.  A two-FPGA build can
# route it through the F1 UV_FMCH_FLASH USB-UART with FMC indices 311/270.
set uvhs_uart0_connector [env_or_default UVHS_UART0_CONNECTOR b0.F2_APC16]
set uvhs_uart0_tx_index [env_or_default UVHS_UART0_TX_INDEX [lindex $apc16_indices 6]]
set uvhs_uart0_rx_index [env_or_default UVHS_UART0_RX_INDEX [lindex $apc16_indices 7]]
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

# U2 ClockHub global clocks on F2.  Keep the three unrelated frequencies in
# separate ClockHub groups: gclk0 (0..4), gclk5 (5..9), gclk10 (10..14).
# Package pins are the F2 GlobalClk pins declared by the U2.2 board file.
assign_pin -port [pin_name $top clk6_p] -fpga b0.f2 -pin CA39
assign_pin -port [pin_name $top clk6_n] -fpga b0.f2 -pin CA40
assign_pin -port [pin_name $top clk8_p] -fpga b0.f2 -pin G36
assign_pin -port [pin_name $top clk8_n] -fpga b0.f2 -pin F36
assign_pin -port [pin_name $top clk5_p] -fpga b0.f2 -pin AW17
assign_pin -port [pin_name $top clk5_n] -fpga b0.f2 -pin AY17
if {$uvhs_skip_pcie_pins} {
    puts "INFO: skip PCIe/XDMA pin assignment because UVHS_SKIP_PCIE_PINS=1"
} else {
    assign_pin -port [pin_name $top pcie_ep_lnk_up] -connector b0.F2_APC16 -index 58

    # XDMA endpoint signals. X4 uses the HGC7 lane group from the Hejian
    # official XDMA EP example; bind HGC6 only when X8 is explicitly selected.
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
}

# The UVHS uvw_axi4_to_ddr4 IP declares:
#   (* UV_HW_IP = "... toFPGA:<UV_FMCH_PDDR4DME>" *)
# In that mode the UVHS daughter-card/IP binding owns the PDDR4DME DDR pins and
# emits the required *_pad_net_* constraints. Hand-assigning the naked
# FP_CLK_200M_* or DDR4_DIMM_* top ports here double-constrains the same pads
# and causes Vivado "pad already occupied" plus UCIO failures.
puts "INFO: UVHS uvw_axi4_to_ddr4 owns the PDDR4DME DDR pin assignment"
