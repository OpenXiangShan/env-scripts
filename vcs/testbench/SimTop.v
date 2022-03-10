module SimTop(
  input         clock,
  input         reset,
  input  [63:0] io_logCtrl_log_begin,
  input  [63:0] io_logCtrl_log_end,
  input  [63:0] io_logCtrl_log_level,
  input         io_perfInfo_clean,
  input         io_perfInfo_dump,
  output        io_uart_out_valid,
  output [7:0]  io_uart_out_ch,
  output        io_uart_in_valid,
  input  [7:0]  io_uart_in_ch
);
  wire  l_soc_dma_0_awready; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_awvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_dma_0_awid; // @[SimTop.scala 37:19]
  wire [35:0] l_soc_dma_0_awaddr; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_dma_0_awlen; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_dma_0_awsize; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_dma_0_awburst; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_awlock; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_dma_0_awcache; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_dma_0_awprot; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_dma_0_awqos; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_wready; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_wvalid; // @[SimTop.scala 37:19]
  wire [255:0] l_soc_dma_0_wdata; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_dma_0_wstrb; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_wlast; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_bready; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_bvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_dma_0_bid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_dma_0_bresp; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_arready; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_arvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_dma_0_arid; // @[SimTop.scala 37:19]
  wire [35:0] l_soc_dma_0_araddr; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_dma_0_arlen; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_dma_0_arsize; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_dma_0_arburst; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_arlock; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_dma_0_arcache; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_dma_0_arprot; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_dma_0_arqos; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_rready; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_rvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_dma_0_rid; // @[SimTop.scala 37:19]
  wire [255:0] l_soc_dma_0_rdata; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_dma_0_rresp; // @[SimTop.scala 37:19]
  wire  l_soc_dma_0_rlast; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_awready; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_awvalid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_awid; // @[SimTop.scala 37:19]
  wire [30:0] l_soc_peripheral_0_awaddr; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_peripheral_0_awlen; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_peripheral_0_awsize; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_awburst; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_awlock; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_peripheral_0_awcache; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_peripheral_0_awprot; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_peripheral_0_awqos; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_wready; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_wvalid; // @[SimTop.scala 37:19]
  wire [63:0] l_soc_peripheral_0_wdata; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_peripheral_0_wstrb; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_wlast; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_bready; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_bvalid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_bid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_bresp; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_arready; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_arvalid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_arid; // @[SimTop.scala 37:19]
  wire [30:0] l_soc_peripheral_0_araddr; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_peripheral_0_arlen; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_peripheral_0_arsize; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_arburst; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_arlock; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_peripheral_0_arcache; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_peripheral_0_arprot; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_peripheral_0_arqos; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_rready; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_rvalid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_rid; // @[SimTop.scala 37:19]
  wire [63:0] l_soc_peripheral_0_rdata; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_peripheral_0_rresp; // @[SimTop.scala 37:19]
  wire  l_soc_peripheral_0_rlast; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_awready; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_awvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_memory_0_awid; // @[SimTop.scala 37:19]
  wire [35:0] l_soc_memory_0_awaddr; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_memory_0_awlen; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_memory_0_awsize; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_memory_0_awburst; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_awlock; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_memory_0_awcache; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_memory_0_awprot; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_memory_0_awqos; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_wready; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_wvalid; // @[SimTop.scala 37:19]
  wire [255:0] l_soc_memory_0_wdata; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_memory_0_wstrb; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_wlast; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_bready; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_bvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_memory_0_bid; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_memory_0_bresp; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_arready; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_arvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_memory_0_arid; // @[SimTop.scala 37:19]
  wire [35:0] l_soc_memory_0_araddr; // @[SimTop.scala 37:19]
  wire [7:0] l_soc_memory_0_arlen; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_memory_0_arsize; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_memory_0_arburst; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_arlock; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_memory_0_arcache; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_memory_0_arprot; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_memory_0_arqos; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_rready; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_rvalid; // @[SimTop.scala 37:19]
  wire [13:0] l_soc_memory_0_rid; // @[SimTop.scala 37:19]
  wire [255:0] l_soc_memory_0_rdata; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_memory_0_rresp; // @[SimTop.scala 37:19]
  wire  l_soc_memory_0_rlast; // @[SimTop.scala 37:19]
  wire  l_soc_io_clock; // @[SimTop.scala 37:19]
  wire  l_soc_io_reset; // @[SimTop.scala 37:19]
  wire [15:0] l_soc_io_sram_config; // @[SimTop.scala 37:19]
  wire [63:0] l_soc_io_extIntrs; // @[SimTop.scala 37:19]
  wire  l_soc_io_pll0_lock; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_io_pll0_ctrl_0; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_io_pll0_ctrl_1; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_io_pll0_ctrl_2; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_io_pll0_ctrl_3; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_io_pll0_ctrl_4; // @[SimTop.scala 37:19]
  wire [31:0] l_soc_io_pll0_ctrl_5; // @[SimTop.scala 37:19]
  wire  l_soc_io_systemjtag_jtag_TCK; // @[SimTop.scala 37:19]
  wire  l_soc_io_systemjtag_jtag_TMS; // @[SimTop.scala 37:19]
  wire  l_soc_io_systemjtag_jtag_TDI; // @[SimTop.scala 37:19]
  wire  l_soc_io_systemjtag_jtag_TDO_data; // @[SimTop.scala 37:19]
  wire  l_soc_io_systemjtag_jtag_TDO_driven; // @[SimTop.scala 37:19]
  wire  l_soc_io_systemjtag_reset; // @[SimTop.scala 37:19]
  wire [10:0] l_soc_io_systemjtag_mfr_id; // @[SimTop.scala 37:19]
  wire [15:0] l_soc_io_systemjtag_part_number; // @[SimTop.scala 37:19]
  wire [3:0] l_soc_io_systemjtag_version; // @[SimTop.scala 37:19]
  wire  l_soc_io_debug_reset; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_req_0_valid; // @[SimTop.scala 37:19]
  wire [35:0] l_soc_io_cacheable_check_req_0_bits_addr; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_io_cacheable_check_req_0_bits_size; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_io_cacheable_check_req_0_bits_cmd; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_req_1_valid; // @[SimTop.scala 37:19]
  wire [35:0] l_soc_io_cacheable_check_req_1_bits_addr; // @[SimTop.scala 37:19]
  wire [1:0] l_soc_io_cacheable_check_req_1_bits_size; // @[SimTop.scala 37:19]
  wire [2:0] l_soc_io_cacheable_check_req_1_bits_cmd; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_0_ld; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_0_st; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_0_instr; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_0_mmio; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_1_ld; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_1_st; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_1_instr; // @[SimTop.scala 37:19]
  wire  l_soc_io_cacheable_check_resp_1_mmio; // @[SimTop.scala 37:19]
  wire  l_simMMIO_clock; // @[SimTop.scala 42:23]
  wire  l_simMMIO_reset; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_awready; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_awvalid; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_awid; // @[SimTop.scala 42:23]
  wire [30:0] l_simMMIO_io_axi4_0_awaddr; // @[SimTop.scala 42:23]
  wire [7:0] l_simMMIO_io_axi4_0_awlen; // @[SimTop.scala 42:23]
  wire [2:0] l_simMMIO_io_axi4_0_awsize; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_awburst; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_awlock; // @[SimTop.scala 42:23]
  wire [3:0] l_simMMIO_io_axi4_0_awcache; // @[SimTop.scala 42:23]
  wire [2:0] l_simMMIO_io_axi4_0_awprot; // @[SimTop.scala 42:23]
  wire [3:0] l_simMMIO_io_axi4_0_awqos; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_wready; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_wvalid; // @[SimTop.scala 42:23]
  wire [63:0] l_simMMIO_io_axi4_0_wdata; // @[SimTop.scala 42:23]
  wire [7:0] l_simMMIO_io_axi4_0_wstrb; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_wlast; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_bready; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_bvalid; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_bid; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_bresp; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_arready; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_arvalid; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_arid; // @[SimTop.scala 42:23]
  wire [30:0] l_simMMIO_io_axi4_0_araddr; // @[SimTop.scala 42:23]
  wire [7:0] l_simMMIO_io_axi4_0_arlen; // @[SimTop.scala 42:23]
  wire [2:0] l_simMMIO_io_axi4_0_arsize; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_arburst; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_arlock; // @[SimTop.scala 42:23]
  wire [3:0] l_simMMIO_io_axi4_0_arcache; // @[SimTop.scala 42:23]
  wire [2:0] l_simMMIO_io_axi4_0_arprot; // @[SimTop.scala 42:23]
  wire [3:0] l_simMMIO_io_axi4_0_arqos; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_rready; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_rvalid; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_rid; // @[SimTop.scala 42:23]
  wire [63:0] l_simMMIO_io_axi4_0_rdata; // @[SimTop.scala 42:23]
  wire [1:0] l_simMMIO_io_axi4_0_rresp; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_axi4_0_rlast; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_uart_out_valid; // @[SimTop.scala 42:23]
  wire [7:0] l_simMMIO_io_uart_out_ch; // @[SimTop.scala 42:23]
  wire  l_simMMIO_io_uart_in_valid; // @[SimTop.scala 42:23]
  wire [7:0] l_simMMIO_io_uart_in_ch; // @[SimTop.scala 42:23]
  wire [63:0] l_simMMIO_io_interrupt_intrVec; // @[SimTop.scala 42:23]
  wire  l_simAXIMem_clock; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_reset; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_awready; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_awvalid; // @[SimTop.scala 49:27]
  wire [13:0] l_simAXIMem_io_axi4_0_awid; // @[SimTop.scala 49:27]
  wire [35:0] l_simAXIMem_io_axi4_0_awaddr; // @[SimTop.scala 49:27]
  wire [7:0] l_simAXIMem_io_axi4_0_awlen; // @[SimTop.scala 49:27]
  wire [2:0] l_simAXIMem_io_axi4_0_awsize; // @[SimTop.scala 49:27]
  wire [1:0] l_simAXIMem_io_axi4_0_awburst; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_awlock; // @[SimTop.scala 49:27]
  wire [3:0] l_simAXIMem_io_axi4_0_awcache; // @[SimTop.scala 49:27]
  wire [2:0] l_simAXIMem_io_axi4_0_awprot; // @[SimTop.scala 49:27]
  wire [3:0] l_simAXIMem_io_axi4_0_awqos; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_wready; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_wvalid; // @[SimTop.scala 49:27]
  wire [255:0] l_simAXIMem_io_axi4_0_wdata; // @[SimTop.scala 49:27]
  wire [31:0] l_simAXIMem_io_axi4_0_wstrb; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_wlast; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_bready; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_bvalid; // @[SimTop.scala 49:27]
  wire [13:0] l_simAXIMem_io_axi4_0_bid; // @[SimTop.scala 49:27]
  wire [1:0] l_simAXIMem_io_axi4_0_bresp; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_arready; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_arvalid; // @[SimTop.scala 49:27]
  wire [13:0] l_simAXIMem_io_axi4_0_arid; // @[SimTop.scala 49:27]
  wire [35:0] l_simAXIMem_io_axi4_0_araddr; // @[SimTop.scala 49:27]
  wire [7:0] l_simAXIMem_io_axi4_0_arlen; // @[SimTop.scala 49:27]
  wire [2:0] l_simAXIMem_io_axi4_0_arsize; // @[SimTop.scala 49:27]
  wire [1:0] l_simAXIMem_io_axi4_0_arburst; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_arlock; // @[SimTop.scala 49:27]
  wire [3:0] l_simAXIMem_io_axi4_0_arcache; // @[SimTop.scala 49:27]
  wire [2:0] l_simAXIMem_io_axi4_0_arprot; // @[SimTop.scala 49:27]
  wire [3:0] l_simAXIMem_io_axi4_0_arqos; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_rready; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_rvalid; // @[SimTop.scala 49:27]
  wire [13:0] l_simAXIMem_io_axi4_0_rid; // @[SimTop.scala 49:27]
  wire [255:0] l_simAXIMem_io_axi4_0_rdata; // @[SimTop.scala 49:27]
  wire [1:0] l_simAXIMem_io_axi4_0_rresp; // @[SimTop.scala 49:27]
  wire  l_simAXIMem_io_axi4_0_rlast; // @[SimTop.scala 49:27]
  wire  SimJTAG_clock; // @[SimTop.scala 61:20]
  wire  SimJTAG_reset; // @[SimTop.scala 61:20]
  wire  SimJTAG_jtag_TRSTn; // @[SimTop.scala 61:20]
  wire  SimJTAG_jtag_TCK; // @[SimTop.scala 61:20]
  wire  SimJTAG_jtag_TMS; // @[SimTop.scala 61:20]
  wire  SimJTAG_jtag_TDI; // @[SimTop.scala 61:20]
  wire  SimJTAG_jtag_TDO_data; // @[SimTop.scala 61:20]
  wire  SimJTAG_jtag_TDO_driven; // @[SimTop.scala 61:20]
  wire  SimJTAG_enable; // @[SimTop.scala 61:20]
  wire  SimJTAG_init_done; // @[SimTop.scala 61:20]
  wire [31:0] SimJTAG_exit; // @[SimTop.scala 61:20]
  XSTop l_soc ( // @[SimTop.scala 37:19]
    .dma_0_awready(l_soc_dma_0_awready),
    .dma_0_awvalid(l_soc_dma_0_awvalid),
    .dma_0_awid(l_soc_dma_0_awid),
    .dma_0_awaddr(l_soc_dma_0_awaddr),
    .dma_0_awlen(l_soc_dma_0_awlen),
    .dma_0_awsize(l_soc_dma_0_awsize),
    .dma_0_awburst(l_soc_dma_0_awburst),
    .dma_0_awlock(l_soc_dma_0_awlock),
    .dma_0_awcache(l_soc_dma_0_awcache),
    .dma_0_awprot(l_soc_dma_0_awprot),
    .dma_0_awqos(l_soc_dma_0_awqos),
    .dma_0_wready(l_soc_dma_0_wready),
    .dma_0_wvalid(l_soc_dma_0_wvalid),
    .dma_0_wdata(l_soc_dma_0_wdata),
    .dma_0_wstrb(l_soc_dma_0_wstrb),
    .dma_0_wlast(l_soc_dma_0_wlast),
    .dma_0_bready(l_soc_dma_0_bready),
    .dma_0_bvalid(l_soc_dma_0_bvalid),
    .dma_0_bid(l_soc_dma_0_bid),
    .dma_0_bresp(l_soc_dma_0_bresp),
    .dma_0_arready(l_soc_dma_0_arready),
    .dma_0_arvalid(l_soc_dma_0_arvalid),
    .dma_0_arid(l_soc_dma_0_arid),
    .dma_0_araddr(l_soc_dma_0_araddr),
    .dma_0_arlen(l_soc_dma_0_arlen),
    .dma_0_arsize(l_soc_dma_0_arsize),
    .dma_0_arburst(l_soc_dma_0_arburst),
    .dma_0_arlock(l_soc_dma_0_arlock),
    .dma_0_arcache(l_soc_dma_0_arcache),
    .dma_0_arprot(l_soc_dma_0_arprot),
    .dma_0_arqos(l_soc_dma_0_arqos),
    .dma_0_rready(l_soc_dma_0_rready),
    .dma_0_rvalid(l_soc_dma_0_rvalid),
    .dma_0_rid(l_soc_dma_0_rid),
    .dma_0_rdata(l_soc_dma_0_rdata),
    .dma_0_rresp(l_soc_dma_0_rresp),
    .dma_0_rlast(l_soc_dma_0_rlast),
    .peripheral_0_awready(l_soc_peripheral_0_awready),
    .peripheral_0_awvalid(l_soc_peripheral_0_awvalid),
    .peripheral_0_awid(l_soc_peripheral_0_awid),
    .peripheral_0_awaddr(l_soc_peripheral_0_awaddr),
    .peripheral_0_awlen(l_soc_peripheral_0_awlen),
    .peripheral_0_awsize(l_soc_peripheral_0_awsize),
    .peripheral_0_awburst(l_soc_peripheral_0_awburst),
    .peripheral_0_awlock(l_soc_peripheral_0_awlock),
    .peripheral_0_awcache(l_soc_peripheral_0_awcache),
    .peripheral_0_awprot(l_soc_peripheral_0_awprot),
    .peripheral_0_awqos(l_soc_peripheral_0_awqos),
    .peripheral_0_wready(l_soc_peripheral_0_wready),
    .peripheral_0_wvalid(l_soc_peripheral_0_wvalid),
    .peripheral_0_wdata(l_soc_peripheral_0_wdata),
    .peripheral_0_wstrb(l_soc_peripheral_0_wstrb),
    .peripheral_0_wlast(l_soc_peripheral_0_wlast),
    .peripheral_0_bready(l_soc_peripheral_0_bready),
    .peripheral_0_bvalid(l_soc_peripheral_0_bvalid),
    .peripheral_0_bid(l_soc_peripheral_0_bid),
    .peripheral_0_bresp(l_soc_peripheral_0_bresp),
    .peripheral_0_arready(l_soc_peripheral_0_arready),
    .peripheral_0_arvalid(l_soc_peripheral_0_arvalid),
    .peripheral_0_arid(l_soc_peripheral_0_arid),
    .peripheral_0_araddr(l_soc_peripheral_0_araddr),
    .peripheral_0_arlen(l_soc_peripheral_0_arlen),
    .peripheral_0_arsize(l_soc_peripheral_0_arsize),
    .peripheral_0_arburst(l_soc_peripheral_0_arburst),
    .peripheral_0_arlock(l_soc_peripheral_0_arlock),
    .peripheral_0_arcache(l_soc_peripheral_0_arcache),
    .peripheral_0_arprot(l_soc_peripheral_0_arprot),
    .peripheral_0_arqos(l_soc_peripheral_0_arqos),
    .peripheral_0_rready(l_soc_peripheral_0_rready),
    .peripheral_0_rvalid(l_soc_peripheral_0_rvalid),
    .peripheral_0_rid(l_soc_peripheral_0_rid),
    .peripheral_0_rdata(l_soc_peripheral_0_rdata),
    .peripheral_0_rresp(l_soc_peripheral_0_rresp),
    .peripheral_0_rlast(l_soc_peripheral_0_rlast),
    .memory_0_awready(l_soc_memory_0_awready),
    .memory_0_awvalid(l_soc_memory_0_awvalid),
    .memory_0_awid(l_soc_memory_0_awid),
    .memory_0_awaddr(l_soc_memory_0_awaddr),
    .memory_0_awlen(l_soc_memory_0_awlen),
    .memory_0_awsize(l_soc_memory_0_awsize),
    .memory_0_awburst(l_soc_memory_0_awburst),
    .memory_0_awlock(l_soc_memory_0_awlock),
    .memory_0_awcache(l_soc_memory_0_awcache),
    .memory_0_awprot(l_soc_memory_0_awprot),
    .memory_0_awqos(l_soc_memory_0_awqos),
    .memory_0_wready(l_soc_memory_0_wready),
    .memory_0_wvalid(l_soc_memory_0_wvalid),
    .memory_0_wdata(l_soc_memory_0_wdata),
    .memory_0_wstrb(l_soc_memory_0_wstrb),
    .memory_0_wlast(l_soc_memory_0_wlast),
    .memory_0_bready(l_soc_memory_0_bready),
    .memory_0_bvalid(l_soc_memory_0_bvalid),
    .memory_0_bid(l_soc_memory_0_bid),
    .memory_0_bresp(l_soc_memory_0_bresp),
    .memory_0_arready(l_soc_memory_0_arready),
    .memory_0_arvalid(l_soc_memory_0_arvalid),
    .memory_0_arid(l_soc_memory_0_arid),
    .memory_0_araddr(l_soc_memory_0_araddr),
    .memory_0_arlen(l_soc_memory_0_arlen),
    .memory_0_arsize(l_soc_memory_0_arsize),
    .memory_0_arburst(l_soc_memory_0_arburst),
    .memory_0_arlock(l_soc_memory_0_arlock),
    .memory_0_arcache(l_soc_memory_0_arcache),
    .memory_0_arprot(l_soc_memory_0_arprot),
    .memory_0_arqos(l_soc_memory_0_arqos),
    .memory_0_rready(l_soc_memory_0_rready),
    .memory_0_rvalid(l_soc_memory_0_rvalid),
    .memory_0_rid(l_soc_memory_0_rid),
    .memory_0_rdata(l_soc_memory_0_rdata),
    .memory_0_rresp(l_soc_memory_0_rresp),
    .memory_0_rlast(l_soc_memory_0_rlast),
    .io_clock(l_soc_io_clock),
    .io_reset(l_soc_io_reset),
    .io_sram_config(l_soc_io_sram_config),
    .io_extIntrs(l_soc_io_extIntrs),
    .io_pll0_lock(l_soc_io_pll0_lock),
    .io_pll0_ctrl_0(l_soc_io_pll0_ctrl_0),
    .io_pll0_ctrl_1(l_soc_io_pll0_ctrl_1),
    .io_pll0_ctrl_2(l_soc_io_pll0_ctrl_2),
    .io_pll0_ctrl_3(l_soc_io_pll0_ctrl_3),
    .io_pll0_ctrl_4(l_soc_io_pll0_ctrl_4),
    .io_pll0_ctrl_5(l_soc_io_pll0_ctrl_5),
    .io_systemjtag_jtag_TCK(l_soc_io_systemjtag_jtag_TCK),
    .io_systemjtag_jtag_TMS(l_soc_io_systemjtag_jtag_TMS),
    .io_systemjtag_jtag_TDI(l_soc_io_systemjtag_jtag_TDI),
    .io_systemjtag_jtag_TDO_data(l_soc_io_systemjtag_jtag_TDO_data),
    .io_systemjtag_jtag_TDO_driven(l_soc_io_systemjtag_jtag_TDO_driven),
    .io_systemjtag_reset(l_soc_io_systemjtag_reset),
    .io_systemjtag_mfr_id(l_soc_io_systemjtag_mfr_id),
    .io_systemjtag_part_number(l_soc_io_systemjtag_part_number),
    .io_systemjtag_version(l_soc_io_systemjtag_version),
    .io_debug_reset(l_soc_io_debug_reset),
    .io_cacheable_check_req_0_valid(l_soc_io_cacheable_check_req_0_valid),
    .io_cacheable_check_req_0_bits_addr(l_soc_io_cacheable_check_req_0_bits_addr),
    .io_cacheable_check_req_0_bits_size(l_soc_io_cacheable_check_req_0_bits_size),
    .io_cacheable_check_req_0_bits_cmd(l_soc_io_cacheable_check_req_0_bits_cmd),
    .io_cacheable_check_req_1_valid(l_soc_io_cacheable_check_req_1_valid),
    .io_cacheable_check_req_1_bits_addr(l_soc_io_cacheable_check_req_1_bits_addr),
    .io_cacheable_check_req_1_bits_size(l_soc_io_cacheable_check_req_1_bits_size),
    .io_cacheable_check_req_1_bits_cmd(l_soc_io_cacheable_check_req_1_bits_cmd),
    .io_cacheable_check_resp_0_ld(l_soc_io_cacheable_check_resp_0_ld),
    .io_cacheable_check_resp_0_st(l_soc_io_cacheable_check_resp_0_st),
    .io_cacheable_check_resp_0_instr(l_soc_io_cacheable_check_resp_0_instr),
    .io_cacheable_check_resp_0_mmio(l_soc_io_cacheable_check_resp_0_mmio),
    .io_cacheable_check_resp_1_ld(l_soc_io_cacheable_check_resp_1_ld),
    .io_cacheable_check_resp_1_st(l_soc_io_cacheable_check_resp_1_st),
    .io_cacheable_check_resp_1_instr(l_soc_io_cacheable_check_resp_1_instr),
    .io_cacheable_check_resp_1_mmio(l_soc_io_cacheable_check_resp_1_mmio)
  );
  SimMMIO l_simMMIO ( // @[SimTop.scala 42:23]
    .clock(l_simMMIO_clock),
    .reset(l_simMMIO_reset),
    .io_axi4_0_awready(l_simMMIO_io_axi4_0_awready),
    .io_axi4_0_awvalid(l_simMMIO_io_axi4_0_awvalid),
    .io_axi4_0_awid(l_simMMIO_io_axi4_0_awid),
    .io_axi4_0_awaddr(l_simMMIO_io_axi4_0_awaddr),
    .io_axi4_0_awlen(l_simMMIO_io_axi4_0_awlen),
    .io_axi4_0_awsize(l_simMMIO_io_axi4_0_awsize),
    .io_axi4_0_awburst(l_simMMIO_io_axi4_0_awburst),
    .io_axi4_0_awlock(l_simMMIO_io_axi4_0_awlock),
    .io_axi4_0_awcache(l_simMMIO_io_axi4_0_awcache),
    .io_axi4_0_awprot(l_simMMIO_io_axi4_0_awprot),
    .io_axi4_0_awqos(l_simMMIO_io_axi4_0_awqos),
    .io_axi4_0_wready(l_simMMIO_io_axi4_0_wready),
    .io_axi4_0_wvalid(l_simMMIO_io_axi4_0_wvalid),
    .io_axi4_0_wdata(l_simMMIO_io_axi4_0_wdata),
    .io_axi4_0_wstrb(l_simMMIO_io_axi4_0_wstrb),
    .io_axi4_0_wlast(l_simMMIO_io_axi4_0_wlast),
    .io_axi4_0_bready(l_simMMIO_io_axi4_0_bready),
    .io_axi4_0_bvalid(l_simMMIO_io_axi4_0_bvalid),
    .io_axi4_0_bid(l_simMMIO_io_axi4_0_bid),
    .io_axi4_0_bresp(l_simMMIO_io_axi4_0_bresp),
    .io_axi4_0_arready(l_simMMIO_io_axi4_0_arready),
    .io_axi4_0_arvalid(l_simMMIO_io_axi4_0_arvalid),
    .io_axi4_0_arid(l_simMMIO_io_axi4_0_arid),
    .io_axi4_0_araddr(l_simMMIO_io_axi4_0_araddr),
    .io_axi4_0_arlen(l_simMMIO_io_axi4_0_arlen),
    .io_axi4_0_arsize(l_simMMIO_io_axi4_0_arsize),
    .io_axi4_0_arburst(l_simMMIO_io_axi4_0_arburst),
    .io_axi4_0_arlock(l_simMMIO_io_axi4_0_arlock),
    .io_axi4_0_arcache(l_simMMIO_io_axi4_0_arcache),
    .io_axi4_0_arprot(l_simMMIO_io_axi4_0_arprot),
    .io_axi4_0_arqos(l_simMMIO_io_axi4_0_arqos),
    .io_axi4_0_rready(l_simMMIO_io_axi4_0_rready),
    .io_axi4_0_rvalid(l_simMMIO_io_axi4_0_rvalid),
    .io_axi4_0_rid(l_simMMIO_io_axi4_0_rid),
    .io_axi4_0_rdata(l_simMMIO_io_axi4_0_rdata),
    .io_axi4_0_rresp(l_simMMIO_io_axi4_0_rresp),
    .io_axi4_0_rlast(l_simMMIO_io_axi4_0_rlast),
    .io_uart_out_valid(l_simMMIO_io_uart_out_valid),
    .io_uart_out_ch(l_simMMIO_io_uart_out_ch),
    .io_uart_in_valid(l_simMMIO_io_uart_in_valid),
    .io_uart_in_ch(l_simMMIO_io_uart_in_ch),
    .io_interrupt_intrVec(l_simMMIO_io_interrupt_intrVec)
  );
  AXI4RAMWrapper l_simAXIMem ( // @[SimTop.scala 49:27]
    .clock(l_simAXIMem_clock),
    .reset(l_simAXIMem_reset),
    .io_axi4_0_awready(l_simAXIMem_io_axi4_0_awready),
    .io_axi4_0_awvalid(l_simAXIMem_io_axi4_0_awvalid),
    .io_axi4_0_awid(l_simAXIMem_io_axi4_0_awid),
    .io_axi4_0_awaddr(l_simAXIMem_io_axi4_0_awaddr),
    .io_axi4_0_awlen(l_simAXIMem_io_axi4_0_awlen),
    .io_axi4_0_awsize(l_simAXIMem_io_axi4_0_awsize),
    .io_axi4_0_awburst(l_simAXIMem_io_axi4_0_awburst),
    .io_axi4_0_awlock(l_simAXIMem_io_axi4_0_awlock),
    .io_axi4_0_awcache(l_simAXIMem_io_axi4_0_awcache),
    .io_axi4_0_awprot(l_simAXIMem_io_axi4_0_awprot),
    .io_axi4_0_awqos(l_simAXIMem_io_axi4_0_awqos),
    .io_axi4_0_wready(l_simAXIMem_io_axi4_0_wready),
    .io_axi4_0_wvalid(l_simAXIMem_io_axi4_0_wvalid),
    .io_axi4_0_wdata(l_simAXIMem_io_axi4_0_wdata),
    .io_axi4_0_wstrb(l_simAXIMem_io_axi4_0_wstrb),
    .io_axi4_0_wlast(l_simAXIMem_io_axi4_0_wlast),
    .io_axi4_0_bready(l_simAXIMem_io_axi4_0_bready),
    .io_axi4_0_bvalid(l_simAXIMem_io_axi4_0_bvalid),
    .io_axi4_0_bid(l_simAXIMem_io_axi4_0_bid),
    .io_axi4_0_bresp(l_simAXIMem_io_axi4_0_bresp),
    .io_axi4_0_arready(l_simAXIMem_io_axi4_0_arready),
    .io_axi4_0_arvalid(l_simAXIMem_io_axi4_0_arvalid),
    .io_axi4_0_arid(l_simAXIMem_io_axi4_0_arid),
    .io_axi4_0_araddr(l_simAXIMem_io_axi4_0_araddr),
    .io_axi4_0_arlen(l_simAXIMem_io_axi4_0_arlen),
    .io_axi4_0_arsize(l_simAXIMem_io_axi4_0_arsize),
    .io_axi4_0_arburst(l_simAXIMem_io_axi4_0_arburst),
    .io_axi4_0_arlock(l_simAXIMem_io_axi4_0_arlock),
    .io_axi4_0_arcache(l_simAXIMem_io_axi4_0_arcache),
    .io_axi4_0_arprot(l_simAXIMem_io_axi4_0_arprot),
    .io_axi4_0_arqos(l_simAXIMem_io_axi4_0_arqos),
    .io_axi4_0_rready(l_simAXIMem_io_axi4_0_rready),
    .io_axi4_0_rvalid(l_simAXIMem_io_axi4_0_rvalid),
    .io_axi4_0_rid(l_simAXIMem_io_axi4_0_rid),
    .io_axi4_0_rdata(l_simAXIMem_io_axi4_0_rdata),
    .io_axi4_0_rresp(l_simAXIMem_io_axi4_0_rresp),
    .io_axi4_0_rlast(l_simAXIMem_io_axi4_0_rlast)
  );
  SimJTAG #(.TICK_DELAY(3)) SimJTAG ( // @[SimTop.scala 61:20]
    .clock(SimJTAG_clock),
    .reset(SimJTAG_reset),
    .jtag_TRSTn(SimJTAG_jtag_TRSTn),
    .jtag_TCK(SimJTAG_jtag_TCK),
    .jtag_TMS(SimJTAG_jtag_TMS),
    .jtag_TDI(SimJTAG_jtag_TDI),
    .jtag_TDO_data(SimJTAG_jtag_TDO_data),
    .jtag_TDO_driven(SimJTAG_jtag_TDO_driven),
    .enable(SimJTAG_enable),
    .init_done(SimJTAG_init_done),
    .exit(SimJTAG_exit)
  );
  assign io_uart_out_valid = l_simMMIO_io_uart_out_valid; // @[SimTop.scala 74:19]
  assign io_uart_out_ch = l_simMMIO_io_uart_out_ch; // @[SimTop.scala 74:19]
  assign io_uart_in_valid = l_simMMIO_io_uart_in_valid; // @[SimTop.scala 74:19]
  assign l_soc_dma_0_awvalid = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awid = 14'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awaddr = 36'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awlen = 8'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awsize = 3'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awburst = 2'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awlock = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awcache = 4'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awprot = 3'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_awqos = 4'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_wvalid = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_wdata = 256'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_wstrb = 32'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_wlast = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_bready = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arvalid = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arid = 14'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_araddr = 36'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arlen = 8'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arsize = 3'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arburst = 2'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arlock = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arcache = 4'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arprot = 3'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_arqos = 4'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_dma_0_rready = 1'h0; // @[SimTop.scala 39:{35,35}]
  assign l_soc_peripheral_0_awready = l_simMMIO_io_axi4_0_awready; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_wready = l_simMMIO_io_axi4_0_wready; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_bvalid = l_simMMIO_io_axi4_0_bvalid; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_bid = l_simMMIO_io_axi4_0_bid; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_bresp = l_simMMIO_io_axi4_0_bresp; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_arready = l_simMMIO_io_axi4_0_arready; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_rvalid = l_simMMIO_io_axi4_0_rvalid; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_rid = l_simMMIO_io_axi4_0_rid; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_rdata = l_simMMIO_io_axi4_0_rdata; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_rresp = l_simMMIO_io_axi4_0_rresp; // @[SimTop.scala 43:21]
  assign l_soc_peripheral_0_rlast = l_simMMIO_io_axi4_0_rlast; // @[SimTop.scala 43:21]
  assign l_soc_memory_0_awready = l_simAXIMem_io_axi4_0_awready; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_wready = l_simAXIMem_io_axi4_0_wready; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_bvalid = l_simAXIMem_io_axi4_0_bvalid; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_bid = l_simAXIMem_io_axi4_0_bid; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_bresp = l_simAXIMem_io_axi4_0_bresp; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_arready = l_simAXIMem_io_axi4_0_arready; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_rvalid = l_simAXIMem_io_axi4_0_rvalid; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_rid = l_simAXIMem_io_axi4_0_rid; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_rdata = l_simAXIMem_io_axi4_0_rdata; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_rresp = l_simAXIMem_io_axi4_0_rresp; // @[SimTop.scala 50:25]
  assign l_soc_memory_0_rlast = l_simAXIMem_io_axi4_0_rlast; // @[SimTop.scala 50:25]
  assign l_soc_io_clock = clock; // @[SimTop.scala 53:25]
  assign l_soc_io_reset = reset; // @[SimTop.scala 54:25]
  assign l_soc_io_sram_config = 16'h0; // @[SimTop.scala 56:22]
  assign l_soc_io_extIntrs = l_simMMIO_io_interrupt_intrVec; // @[SimTop.scala 55:19]
  assign l_soc_io_pll0_lock = 1'h1; // @[SimTop.scala 57:20]
  assign l_soc_io_systemjtag_jtag_TCK = SimJTAG_jtag_TCK; // @[RocketDebugWrapper.scala 126:15]
  assign l_soc_io_systemjtag_jtag_TMS = SimJTAG_jtag_TMS; // @[RocketDebugWrapper.scala 127:15]
  assign l_soc_io_systemjtag_jtag_TDI = SimJTAG_jtag_TDI; // @[RocketDebugWrapper.scala 128:15]
  assign l_soc_io_systemjtag_reset = reset; // @[SimTop.scala 62:27]
  assign l_soc_io_systemjtag_mfr_id = 11'h0; // @[SimTop.scala 63:28]
  assign l_soc_io_systemjtag_part_number = 16'h0; // @[SimTop.scala 64:33]
  assign l_soc_io_systemjtag_version = 4'h0; // @[SimTop.scala 65:29]
  assign l_soc_io_cacheable_check_req_0_valid = 1'h0;
  assign l_soc_io_cacheable_check_req_0_bits_addr = 36'h0;
  assign l_soc_io_cacheable_check_req_0_bits_size = 2'h0;
  assign l_soc_io_cacheable_check_req_0_bits_cmd = 3'h0;
  assign l_soc_io_cacheable_check_req_1_valid = 1'h0;
  assign l_soc_io_cacheable_check_req_1_bits_addr = 36'h0;
  assign l_soc_io_cacheable_check_req_1_bits_size = 2'h0;
  assign l_soc_io_cacheable_check_req_1_bits_cmd = 3'h0;
  assign l_simMMIO_clock = clock;
  assign l_simMMIO_reset = reset;
  assign l_simMMIO_io_axi4_0_awvalid = l_soc_peripheral_0_awvalid; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awid = l_soc_peripheral_0_awid; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awaddr = l_soc_peripheral_0_awaddr; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awlen = l_soc_peripheral_0_awlen; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awsize = l_soc_peripheral_0_awsize; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awburst = l_soc_peripheral_0_awburst; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awlock = l_soc_peripheral_0_awlock; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awcache = l_soc_peripheral_0_awcache; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awprot = l_soc_peripheral_0_awprot; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_awqos = l_soc_peripheral_0_awqos; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_wvalid = l_soc_peripheral_0_wvalid; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_wdata = l_soc_peripheral_0_wdata; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_wstrb = l_soc_peripheral_0_wstrb; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_wlast = l_soc_peripheral_0_wlast; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_bready = l_soc_peripheral_0_bready; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arvalid = l_soc_peripheral_0_arvalid; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arid = l_soc_peripheral_0_arid; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_araddr = l_soc_peripheral_0_araddr; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arlen = l_soc_peripheral_0_arlen; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arsize = l_soc_peripheral_0_arsize; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arburst = l_soc_peripheral_0_arburst; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arlock = l_soc_peripheral_0_arlock; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arcache = l_soc_peripheral_0_arcache; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arprot = l_soc_peripheral_0_arprot; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_arqos = l_soc_peripheral_0_arqos; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_axi4_0_rready = l_soc_peripheral_0_rready; // @[SimTop.scala 43:21]
  assign l_simMMIO_io_uart_in_ch = io_uart_in_ch; // @[SimTop.scala 74:19]
  assign l_simAXIMem_clock = clock;
  assign l_simAXIMem_reset = reset;
  assign l_simAXIMem_io_axi4_0_awvalid = l_soc_memory_0_awvalid; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awid = l_soc_memory_0_awid; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awaddr = l_soc_memory_0_awaddr; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awlen = l_soc_memory_0_awlen; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awsize = l_soc_memory_0_awsize; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awburst = l_soc_memory_0_awburst; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awlock = l_soc_memory_0_awlock; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awcache = l_soc_memory_0_awcache; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awprot = l_soc_memory_0_awprot; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_awqos = l_soc_memory_0_awqos; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_wvalid = l_soc_memory_0_wvalid; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_wdata = l_soc_memory_0_wdata; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_wstrb = l_soc_memory_0_wstrb; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_wlast = l_soc_memory_0_wlast; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_bready = l_soc_memory_0_bready; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arvalid = l_soc_memory_0_arvalid; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arid = l_soc_memory_0_arid; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_araddr = l_soc_memory_0_araddr; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arlen = l_soc_memory_0_arlen; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arsize = l_soc_memory_0_arsize; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arburst = l_soc_memory_0_arburst; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arlock = l_soc_memory_0_arlock; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arcache = l_soc_memory_0_arcache; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arprot = l_soc_memory_0_arprot; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_arqos = l_soc_memory_0_arqos; // @[SimTop.scala 50:25]
  assign l_simAXIMem_io_axi4_0_rready = l_soc_memory_0_rready; // @[SimTop.scala 50:25]
  assign SimJTAG_clock = clock; // @[RocketDebugWrapper.scala 131:11]
  assign SimJTAG_reset = reset; // @[SimTop.scala 61:95]
  assign SimJTAG_jtag_TDO_data = l_soc_io_systemjtag_jtag_TDO_data; // @[RocketDebugWrapper.scala 129:14]
  assign SimJTAG_jtag_TDO_driven = l_soc_io_systemjtag_jtag_TDO_driven; // @[RocketDebugWrapper.scala 129:14]
  assign SimJTAG_enable = 1'h1; // @[RocketDebugWrapper.scala 134:15]
  assign SimJTAG_init_done = ~reset; // @[SimTop.scala 61:103]
endmodule

