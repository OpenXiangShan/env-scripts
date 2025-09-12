`include "DifftestMacros.v"

module CoreTop_wrapper(
  input           sys_clk_i,    
  input           sys_rstn_i, 
  input           tmclk,

  input           global_reset,     //24MHz

  input  [3:0]    pll_bypass_sel,   //apb clk : 100MHz
  output          pll0_lock,
  output          pll0_clk_div_1024,
  output [11:0]   pll0_test_calout,

  input  [15:0]   soc_to_cpu,   // none
  output [15:0]   cpu_to_soc,   //none

  input  [63:0]   io_extIntrs,   // come from IPs, Max : 600MHz

  input  [15:0]   io_sram_config,  //apb clk : 100MHz

  input           io_systemjtag_jtag_TCK,         // come from gpio
  input           io_systemjtag_jtag_TMS,         // come from gpio
  input           io_systemjtag_jtag_TDI,         // come from gpio
  output          io_systemjtag_jtag_TDO_data,    // come from gpio
  output          io_systemjtag_jtag_TDO_driven,  // come from gpio
  input           io_systemjtag_reset,            // come from gpio

// peri bus   //400MHz
// dma bus    //800MHz
// mem bus    //800MHz

  (*mark_debug="true"*) output          dma_core_awready,
  (*mark_debug="true"*) input           dma_core_awvalid,
  (*mark_debug="true"*) input           dma_core_awid,
  (*mark_debug="true"*) input  [31:0]   dma_core_awaddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_awlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_awsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_awburst,
  (*mark_debug="true"*) input           dma_core_awlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_awcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_awprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_awqos,
  (*mark_debug="true"*) output          dma_core_wready,
  (*mark_debug="true"*) input           dma_core_wvalid,
  (*mark_debug="true"*) input  [63:0]   dma_core_wdata,
  (*mark_debug="true"*) input  [31:0]   dma_core_wstrb,
  (*mark_debug="true"*) input           dma_core_wlast,
  (*mark_debug="true"*) input           dma_core_bready,
  (*mark_debug="true"*) output          dma_core_bvalid,
  (*mark_debug="true"*) output          dma_core_bid,
  (*mark_debug="true"*) output [1:0]    dma_core_bresp,
  (*mark_debug="true"*) output          dma_core_arready,
  (*mark_debug="true"*) input           dma_core_arvalid,
  (*mark_debug="true"*) input           dma_core_arid,
  (*mark_debug="true"*) input  [31:0]   dma_core_araddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_arlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_arsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_arburst,
  (*mark_debug="true"*) input           dma_core_arlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_arcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_arprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_arqos,
  (*mark_debug="true"*) input           dma_core_rready,
  (*mark_debug="true"*) output          dma_core_rvalid,
  (*mark_debug="true"*) output          dma_core_rid,
  (*mark_debug="true"*) output [63:0]   dma_core_rdata,
  (*mark_debug="true"*) output [1:0]    dma_core_rresp,
  (*mark_debug="true"*) output          dma_core_rlast,
  
  (*mark_debug="true"*) input           peri_awready,
  (*mark_debug="true"*) output          peri_awvalid,
  (*mark_debug="true"*) output          peri_awid,
  (*mark_debug="true"*) output [31:0]   peri_awaddr,
  (*mark_debug="true"*) output [7:0]    peri_awlen,
  (*mark_debug="true"*) output [2:0]    peri_awsize,
  (*mark_debug="true"*) output [1:0]    peri_awburst,
  (*mark_debug="true"*) output          peri_awlock,
  (*mark_debug="true"*) output [3:0]    peri_awcache,
  (*mark_debug="true"*) output [2:0]    peri_awprot,
  (*mark_debug="true"*) output [3:0]    peri_awqos,
  (*mark_debug="true"*) input           peri_wready,
  (*mark_debug="true"*) output          peri_wvalid,
  (*mark_debug="true"*) output [63:0]   peri_wdata,
  (*mark_debug="true"*) output [7:0]    peri_wstrb,
  (*mark_debug="true"*) output          peri_wlast,
  (*mark_debug="true"*) output          peri_bready,
  (*mark_debug="true"*) input           peri_bvalid,
  (*mark_debug="true"*) input  [1:0]    peri_bid,
  (*mark_debug="true"*) input  [1:0]    peri_bresp,
  (*mark_debug="true"*) input           peri_arready,
  (*mark_debug="true"*) output          peri_arvalid,
  (*mark_debug="true"*) output          peri_arid,
  (*mark_debug="true"*) output [31:0]   peri_araddr,
  (*mark_debug="true"*) output [7:0]    peri_arlen,
  (*mark_debug="true"*) output [2:0]    peri_arsize,
  (*mark_debug="true"*) output [1:0]    peri_arburst,
  (*mark_debug="true"*) output          peri_arlock,
  (*mark_debug="true"*) output [3:0]    peri_arcache,
  (*mark_debug="true"*) output [2:0]    peri_arprot,
  (*mark_debug="true"*) output [3:0]    peri_arqos,
  (*mark_debug="true"*) output          peri_rready,
  (*mark_debug="true"*) input           peri_rvalid,
  (*mark_debug="true"*) input           peri_rid,
  (*mark_debug="true"*) input  [63:0]   peri_rdata,
  (*mark_debug="true"*) input  [1:0]    peri_rresp,
  (*mark_debug="true"*) input           peri_rlast,
  
  (*mark_debug="true"*) input           mem_core_awready,
  (*mark_debug="true"*) output          mem_core_awvalid,
  (*mark_debug="true"*) output [7:0]    mem_core_awid,
  (*mark_debug="true"*) output [31:0]   mem_core_awaddr,
  (*mark_debug="true"*) output [7:0]    mem_core_awlen,
  (*mark_debug="true"*) output [2:0]    mem_core_awsize,
  (*mark_debug="true"*) output [1:0]    mem_core_awburst,
  (*mark_debug="true"*) output          mem_core_awlock,
  (*mark_debug="true"*) output [3:0]    mem_core_awcache,
  (*mark_debug="true"*) output [2:0]    mem_core_awprot,
  (*mark_debug="true"*) output [3:0]    mem_core_awqos,
  (*mark_debug="true"*) input           mem_core_wready,
  (*mark_debug="true"*) output          mem_core_wvalid,
  (*mark_debug="true"*) output [63:0]   mem_core_wdata,
  (*mark_debug="true"*) output [7:0]    mem_core_wstrb,
  (*mark_debug="true"*) output          mem_core_wlast,
  (*mark_debug="true"*) output          mem_core_bready,
  (*mark_debug="true"*) input           mem_core_bvalid,
  (*mark_debug="true"*) input           mem_core_bid,
  (*mark_debug="true"*) input  [1:0]    mem_core_bresp,
  (*mark_debug="true"*) input           mem_core_arready,
  (*mark_debug="true"*) output          mem_core_arvalid,
  (*mark_debug="true"*) output          mem_core_arid,
  (*mark_debug="true"*) output [31:0]   mem_core_araddr,
  (*mark_debug="true"*) output [7:0]    mem_core_arlen,
  (*mark_debug="true"*) output [2:0]    mem_core_arsize,
  (*mark_debug="true"*) output [1:0]    mem_core_arburst,
  (*mark_debug="true"*) output          mem_core_arlock,
  (*mark_debug="true"*) output [3:0]    mem_core_arcache,
  (*mark_debug="true"*) output [2:0]    mem_core_arprot,
  (*mark_debug="true"*) output [3:0]    mem_core_arqos,
  (*mark_debug="true"*) output          mem_core_rready,
  (*mark_debug="true"*) input           mem_core_rvalid,
  (*mark_debug="true"*) input           mem_core_rid,
  (*mark_debug="true"*) input  [63:0]   mem_core_rdata,
  (*mark_debug="true"*) input  [1:0]    mem_core_rresp,
  (*mark_debug="true"*) input           mem_core_rlast,

  output [`CONFIG_DIFFTEST_BATCH_IO_WITDH - 1:0]gateway_out_data,
  output gateway_out_enable
);

SimTop u_XSTop (
    .clock                      (sys_clk_i),
    .reset                      (~sys_rstn_i),

    // AXI4 MEMORY
    .io_mem_aw_ready            (mem_core_awready),
    .io_mem_aw_valid            (mem_core_awvalid),
    .io_mem_aw_bits_addr        (mem_core_awaddr[31:0]), //32BIT
    .io_mem_aw_bits_prot        (mem_core_awprot),
    .io_mem_aw_bits_id          (mem_core_awid),
    .io_mem_aw_bits_user        (/* TODO */),
    .io_mem_aw_bits_len         (mem_core_awlen),
    .io_mem_aw_bits_size        (mem_core_awsize),
    .io_mem_aw_bits_burst       (mem_core_awburst),
    .io_mem_aw_bits_lock        (mem_core_awlock),
    .io_mem_aw_bits_cache       (mem_core_awcache),
    .io_mem_aw_bits_qos         (mem_core_awqos),

    .io_mem_w_ready             (mem_core_wready),
    .io_mem_w_valid             (mem_core_wvalid),
    .io_mem_w_bits_data         (mem_core_wdata[63:0]), // 取低64位
    .io_mem_w_bits_strb         (mem_core_wstrb[7:0]),  // 取低8位
    .io_mem_w_bits_last         (mem_core_wlast),

    .io_mem_b_ready             (mem_core_bready),
    .io_mem_b_valid             (mem_core_bvalid),
    .io_mem_b_bits_resp         (mem_core_bresp),
    .io_mem_b_bits_id           (mem_core_bid),
    .io_mem_b_bits_user         (/* TODO */),

    .io_mem_ar_ready            (mem_core_arready),
    .io_mem_ar_valid            (mem_core_arvalid),
    .io_mem_ar_bits_addr        (mem_core_araddr[31:0]), // 取低32位
    .io_mem_ar_bits_prot        (mem_core_arprot),
    .io_mem_ar_bits_id          (mem_core_arid),
    .io_mem_ar_bits_user        (/* TODO */),
    .io_mem_ar_bits_len         (mem_core_arlen),
    .io_mem_ar_bits_size        (mem_core_arsize),
    .io_mem_ar_bits_burst       (mem_core_arburst),
    .io_mem_ar_bits_lock        (mem_core_arlock),
    .io_mem_ar_bits_cache       (mem_core_arcache),
    .io_mem_ar_bits_qos         (mem_core_arqos),

    .io_mem_r_ready             (mem_core_rready),
    .io_mem_r_valid             (mem_core_rvalid),
    .io_mem_r_bits_resp         (mem_core_rresp),
    .io_mem_r_bits_data         (mem_core_rdata[63:0]), // 取低64位
    .io_mem_r_bits_last         (mem_core_rlast),
    .io_mem_r_bits_id           (mem_core_rid),
    .io_mem_r_bits_user         (/* TODO */),

    // AXI4 MMIO
    .io_mmio_aw_ready           (peri_awready),
    .io_mmio_aw_valid           (peri_awvalid),
    .io_mmio_aw_bits_addr       (peri_awaddr[31:0]), // 取低32位
    .io_mmio_aw_bits_prot       (peri_awprot),
    .io_mmio_aw_bits_id         (peri_awid),
    .io_mmio_aw_bits_user       (/* TODO */),
    .io_mmio_aw_bits_len        (peri_awlen),
    .io_mmio_aw_bits_size       (peri_awsize),
    .io_mmio_aw_bits_burst      (peri_awburst),
    .io_mmio_aw_bits_lock       (peri_awlock),
    .io_mmio_aw_bits_cache      (peri_awcache),
    .io_mmio_aw_bits_qos        (peri_awqos),

    .io_mmio_w_ready            (peri_wready),
    .io_mmio_w_valid            (peri_wvalid),
    .io_mmio_w_bits_data        (peri_wdata),
    .io_mmio_w_bits_strb        (peri_wstrb),
    .io_mmio_w_bits_last        (peri_wlast),

    .io_mmio_b_ready            (peri_bready),
    .io_mmio_b_valid            (peri_bvalid),
    .io_mmio_b_bits_resp        (peri_bresp),
    .io_mmio_b_bits_id          (peri_bid),
    .io_mmio_b_bits_user        (/* TODO */),

    .io_mmio_ar_ready           (peri_arready),
    .io_mmio_ar_valid           (peri_arvalid),
    .io_mmio_ar_bits_addr       (peri_araddr[31:0]), // 取低32位
    .io_mmio_ar_bits_prot       (peri_arprot),
    .io_mmio_ar_bits_id         (peri_arid),
    .io_mmio_ar_bits_user       (/* TODO */),
    .io_mmio_ar_bits_len        (peri_arlen),
    .io_mmio_ar_bits_size       (peri_arsize),
    .io_mmio_ar_bits_burst      (peri_arburst),
    .io_mmio_ar_bits_lock       (peri_arlock),
    .io_mmio_ar_bits_cache      (peri_arcache),
    .io_mmio_ar_bits_qos        (peri_arqos),

    .io_mmio_r_ready            (peri_rready),
    .io_mmio_r_valid            (peri_rvalid),
    .io_mmio_r_bits_resp        (peri_rresp),
    .io_mmio_r_bits_data        (peri_rdata),
    .io_mmio_r_bits_last        (peri_rlast),
    .io_mmio_r_bits_id          (peri_rid),
    .io_mmio_r_bits_user        (/* TODO */),

    // AXI4 DMA
    .io_frontend_aw_ready       (dma_core_awready),
    .io_frontend_aw_valid       (dma_core_awvalid),
    .io_frontend_aw_bits_addr   (dma_core_awaddr[31:0]), // 取低32位
    .io_frontend_aw_bits_prot   (dma_core_awprot),
    .io_frontend_aw_bits_id     (dma_core_awid),
    .io_frontend_aw_bits_user   (/* TODO */),
    .io_frontend_aw_bits_len    (dma_core_awlen),
    .io_frontend_aw_bits_size   (dma_core_awsize),
    .io_frontend_aw_bits_burst  (dma_core_awburst),
    .io_frontend_aw_bits_lock   (dma_core_awlock),
    .io_frontend_aw_bits_cache  (dma_core_awcache),
    .io_frontend_aw_bits_qos    (dma_core_awqos),

    .io_frontend_w_ready        (dma_core_wready),
    .io_frontend_w_valid        (dma_core_wvalid),
    .io_frontend_w_bits_data    (dma_core_wdata[63:0]), // 取低64位
    .io_frontend_w_bits_strb    (dma_core_wstrb[7:0]),  // 取低8位
    .io_frontend_w_bits_last    (dma_core_wlast),

    .io_frontend_b_ready        (dma_core_bready),
    .io_frontend_b_valid        (dma_core_bvalid),
    .io_frontend_b_bits_resp    (dma_core_bresp),
    .io_frontend_b_bits_id      (dma_core_bid),
    .io_frontend_b_bits_user    (/* TODO */),

    .io_frontend_ar_ready       (dma_core_arready),
    .io_frontend_ar_valid       (dma_core_arvalid),
    .io_frontend_ar_bits_addr   (dma_core_araddr[31:0]), // 取低32位
    .io_frontend_ar_bits_prot   (dma_core_arprot),
    .io_frontend_ar_bits_id     (dma_core_arid),
    .io_frontend_ar_bits_user   (/* TODO */),
    .io_frontend_ar_bits_len    (dma_core_arlen),
    .io_frontend_ar_bits_size   (dma_core_arsize),
    .io_frontend_ar_bits_burst  (dma_core_arburst),
    .io_frontend_ar_bits_lock   (dma_core_arlock),
    .io_frontend_ar_bits_cache  (dma_core_arcache),
    .io_frontend_ar_bits_qos    (dma_core_arqos),

    .io_frontend_r_ready        (dma_core_rready),
    .io_frontend_r_valid        (dma_core_rvalid),
    .io_frontend_r_bits_resp    (dma_core_rresp),
    .io_frontend_r_bits_data    (dma_core_rdata[63:0]), // 取低64位
    .io_frontend_r_bits_last    (dma_core_rlast),
    .io_frontend_r_bits_id      (dma_core_rid),
    .io_frontend_r_bits_user    (/* TODO */),

    // MIP
    .io_meip                    (io_extIntrs[1:0]),

    // difftest
    .difftest_io_data           (gateway_out_data),
    .difftest_io_enable         (gateway_out_enable),
    .difftest_exit              (/* TODO */),
    .difftest_step              (/* TODO */),
    .difftest_perfCtrl_clean    (/* TODO */),
    .difftest_perfCtrl_dump     (/* TODO */),
    .difftest_logCtrl_begin     (/* TODO */),
    .difftest_logCtrl_end       (/* TODO */),
    .difftest_logCtrl_level     (/* TODO */),
    .difftest_uart_out_valid    (/* TODO */),
    .difftest_uart_out_ch       (/* TODO */),
    .difftest_uart_in_valid     (/* TODO */),
    .difftest_uart_in_ch        (/* TODO */)
);
endmodule
