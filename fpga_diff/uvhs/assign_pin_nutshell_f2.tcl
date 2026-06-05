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
set uvhs_mem_array_mode [expr {[env_or_default UVHS_MEM_ARRAY_DC none] eq "UV_MEM_ARRAY_F"}]
set uvhs_uvw_ddr4_mode [expr {
    [env_or_default UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP 0] eq "1"
    || [env_or_default UVHS_DDR_RTL_INST none] eq "${top}.core_def.U_UVHS_UVW_AXI4_TO_DDR4"
}]
set uvhs_mem_array_connector [env_or_default UVHS_MEM_ARRAY_CONNECTOR b0.F2_FMC1]

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

apc16_pin uart0_sout 6
apc16_pin uart0_sin 7
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

# Main-board clocks on the UVHS U2.2 F2 slot.
assign_pin -port [pin_name $top clk8_p] -connector b0.F2_APC2 -index 78
assign_pin -port [pin_name $top clk8_n] -connector b0.F2_APC2 -index 77
if {!$uvhs_mem_array_mode && !$uvhs_uvw_ddr4_mode} {
    # clk7 is the Vivado DDR reference clock. UVHS direct DDR uses FP_CLK_200M
    # on the same PDDR4DME pins, so do not assign both names to index 241/242.
    assign_pin -port [pin_name $top clk7_p] -connector b0.F2_FMC3 -index 241
    assign_pin -port [pin_name $top clk7_n] -connector b0.F2_FMC3 -index 242
}
assign_pin -port [pin_name $top clk6_p] -connector b0.F2_APC11 -index 78
assign_pin -port [pin_name $top clk6_n] -connector b0.F2_APC11 -index 77
assign_pin -port [pin_name $top clk5_p] -connector b0.F2_FMC0 -index 343
assign_pin -port [pin_name $top clk5_n] -connector b0.F2_FMC0 -index 344

assign_pin -port [pin_name $top pcie_ep_lnk_up] -connector b0.F2_APC16 -index 58

# XDMA endpoint signals. These pins must stay aligned with the native Hejian
# PCIe link example on F2, otherwise the host can enumerate a dead endpoint.
assign_pin -port [pin_name $top pcie_ep_gt_ref_clk_p] -connector b0.F2_HGC7 -index 29
assign_pin -port [pin_name $top pcie_ep_gt_ref_clk_n] -connector b0.F2_HGC7 -index 30
assign_pin -port [pin_name $top pcie_ep_perstn] -connector b0.F2_APC16 -index 118

assign_pin -port [pin_name $top {pci_ep_rxp[0]}] -connector b0.F2_HGC7 -index 16
assign_pin -port [pin_name $top {pci_ep_rxn[0]}] -connector b0.F2_HGC7 -index 17
assign_pin -port [pin_name $top {pci_ep_rxp[1]}] -connector b0.F2_HGC7 -index 13
assign_pin -port [pin_name $top {pci_ep_rxn[1]}] -connector b0.F2_HGC7 -index 14
assign_pin -port [pin_name $top {pci_ep_rxp[2]}] -connector b0.F2_HGC7 -index 4
assign_pin -port [pin_name $top {pci_ep_rxn[2]}] -connector b0.F2_HGC7 -index 5
assign_pin -port [pin_name $top {pci_ep_rxp[3]}] -connector b0.F2_HGC7 -index 1
assign_pin -port [pin_name $top {pci_ep_rxn[3]}] -connector b0.F2_HGC7 -index 2
assign_pin -port [pin_name $top {pci_ep_rxp[4]}] -connector b0.F2_HGC6 -index 16
assign_pin -port [pin_name $top {pci_ep_rxn[4]}] -connector b0.F2_HGC6 -index 17
assign_pin -port [pin_name $top {pci_ep_rxp[5]}] -connector b0.F2_HGC6 -index 13
assign_pin -port [pin_name $top {pci_ep_rxn[5]}] -connector b0.F2_HGC6 -index 14
assign_pin -port [pin_name $top {pci_ep_rxp[6]}] -connector b0.F2_HGC6 -index 4
assign_pin -port [pin_name $top {pci_ep_rxn[6]}] -connector b0.F2_HGC6 -index 5
assign_pin -port [pin_name $top {pci_ep_rxp[7]}] -connector b0.F2_HGC6 -index 1
assign_pin -port [pin_name $top {pci_ep_rxn[7]}] -connector b0.F2_HGC6 -index 2

assign_pin -port [pin_name $top {pci_ep_txp[0]}] -connector b0.F2_HGC7 -index 35
assign_pin -port [pin_name $top {pci_ep_txn[0]}] -connector b0.F2_HGC7 -index 36
assign_pin -port [pin_name $top {pci_ep_txp[1]}] -connector b0.F2_HGC7 -index 32
assign_pin -port [pin_name $top {pci_ep_txn[1]}] -connector b0.F2_HGC7 -index 33
assign_pin -port [pin_name $top {pci_ep_txp[2]}] -connector b0.F2_HGC7 -index 23
assign_pin -port [pin_name $top {pci_ep_txn[2]}] -connector b0.F2_HGC7 -index 24
assign_pin -port [pin_name $top {pci_ep_txp[3]}] -connector b0.F2_HGC7 -index 20
assign_pin -port [pin_name $top {pci_ep_txn[3]}] -connector b0.F2_HGC7 -index 21
assign_pin -port [pin_name $top {pci_ep_txp[4]}] -connector b0.F2_HGC6 -index 35
assign_pin -port [pin_name $top {pci_ep_txn[4]}] -connector b0.F2_HGC6 -index 36
assign_pin -port [pin_name $top {pci_ep_txp[5]}] -connector b0.F2_HGC6 -index 32
assign_pin -port [pin_name $top {pci_ep_txn[5]}] -connector b0.F2_HGC6 -index 33
assign_pin -port [pin_name $top {pci_ep_txp[6]}] -connector b0.F2_HGC6 -index 23
assign_pin -port [pin_name $top {pci_ep_txn[6]}] -connector b0.F2_HGC6 -index 24
assign_pin -port [pin_name $top {pci_ep_txp[7]}] -connector b0.F2_HGC6 -index 20
assign_pin -port [pin_name $top {pci_ep_txn[7]}] -connector b0.F2_HGC6 -index 21

# UVHS memory array connector. This is not a PDDR4DME pinout; only the TDM
# pins exposed by UV_MEM_ARRAY_F are legal on the daughter-card side.
if {$uvhs_mem_array_mode} {
    assign_pin -port [pin_name $top uvw_mem_array_tdm_ref_clk_p] -connector $uvhs_mem_array_connector -index 241
    assign_pin -port [pin_name $top uvw_mem_array_tdm_ref_clk_n] -connector $uvhs_mem_array_connector -index 242
    assign_indexed_ports [pin_name $top uvw_mem_array_tdm_pin] 138 $uvhs_mem_array_connector {
        245 246 127 128 286 287 248 249 289 290 130 131 89 90 292 293
        251 252 133 134 93 94 295 296 283 284 254 255 136 137 97 98
        298 299 257 258 139 140 101 102 301 302 260 261 304 305 263 264
        142 143 307 308 266 267 145 146 105 106 310 311 269 270 313 314
        272 273 316 317 275 276 203 204 161 162 366 367 325 326 206 207
        165 166 369 370 328 329 209 210 168 169 372 373 331 332 212 213
        171 172 334 335 215 216 174 175 375 376 337 338 218 219 177 178
        378 379 363 364 321 322 340 341 381 382 384 385 343 344 221 222
        180 181 224 225 183 184 387 388 346 347
    }
    return
}

# The UVHS uvw_axi4_to_ddr4 IP declares:
#   (* UV_HW_IP = "... toFPGA:<UV_FMCH_PDDR4DME>" *)
# In that mode the UVHS daughter-card/IP binding owns the PDDR4DME DDR pins and
# emits the required *_pad_net_* constraints. Hand-assigning the naked
# FP_CLK_200M_* or DDR4_DIMM_* top ports here double-constrains the same pads
# and causes Vivado "pad already occupied" plus UCIO failures.
if {$uvhs_uvw_ddr4_mode} {
    puts "INFO: skip manual PDDR4DME DDR pin assignment for UVHS uvw_axi4_to_ddr4 IP"
    return
}

# DDR4 PDDR4DME daughter card connected to b0.F2_FMC3 by 1B_4F_HGC_assemble.tcl.
assign_pin -port [pin_name $top FP_CLK_200M_P]    -connector b0.F2_FMC3 -index 241
assign_pin -port [pin_name $top FP_CLK_200M_N]    -connector b0.F2_FMC3 -index 242
assign_pin -port [pin_name $top {DDR4_DIMM_CK_P[0]}]  -connector b0.F2_FMC3 -index 269
assign_pin -port [pin_name $top {DDR4_DIMM_CK_P[1]}]  -connector b0.F2_FMC3 -index 313
assign_pin -port [pin_name $top {DDR4_DIMM_CK_N[0]}]  -connector b0.F2_FMC3 -index 270
assign_pin -port [pin_name $top {DDR4_DIMM_CK_N[1]}]  -connector b0.F2_FMC3 -index 314
assign_pin -port [pin_name $top DDR4_DIMM_RST_B]   -connector b0.F2_FMC3 -index 227 -attribute {DRIVE:8}
assign_pin -port [pin_name $top {DDR4_DIMM_CKE[0]}]   -connector b0.F2_FMC3 -index 169
assign_pin -port [pin_name $top {DDR4_DIMM_CKE[1]}]   -connector b0.F2_FMC3 -index 329
assign_pin -port [pin_name $top {DDR4_DIMM_CS_N[0]}]  -connector b0.F2_FMC3 -index 165
assign_pin -port [pin_name $top {DDR4_DIMM_CS_N[1]}]  -connector b0.F2_FMC3 -index 206
assign_pin -port [pin_name $top {DDR4_DIMM_ODT[0]}]   -connector b0.F2_FMC3 -index 325
assign_pin -port [pin_name $top {DDR4_DIMM_ODT[1]}]   -connector b0.F2_FMC3 -index 366
assign_pin -port [pin_name $top DDR4_DIMM_ACT_N]   -connector b0.F2_FMC3 -index 328

assign_indexed_ports [pin_name $top DDR4_DIMM_DQ] 72 b0.F2_FMC3 {
    263 101 301 305 304 102 302 264
    307 105 267 310 311 106 308 266
    257 136 254 258 298 137 255 299
    181 225 388 387 180 346 347 224
    177 178 338 375 337 379 378 376
    216 334 213 212 215 335 332 331
    292 295 94 251 296 293 93 252
    286 289 127 131 290 287 130 128
    344 343 341 340 385 384 321 322
}
assign_indexed_ports [pin_name $top DDR4_DIMM_DM] 9 b0.F2_FMC3 {139 142 283 221 174 372 89 245 363}
assign_indexed_ports [pin_name $top DDR4_DIMM_DQS_P] 9 b0.F2_FMC3 {260 145 97 183 218 171 133 248 381}
assign_indexed_ports [pin_name $top DDR4_DIMM_DQS_N] 9 b0.F2_FMC3 {261 146 98 184 219 172 134 249 382}
assign_indexed_ports [pin_name $top DDR4_DIMM_A] 17 b0.F2_FMC3 {
    275 391 276 273 317 316 390 369 272
    370 326 207 168 203 166 162 204
}
assign_indexed_ports [pin_name $top DDR4_DIMM_BA] 2 b0.F2_FMC3 {161 367}
assign_indexed_ports [pin_name $top DDR4_DIMM_BG] 2 b0.F2_FMC3 {209 210}
