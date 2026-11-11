`include "DifftestMacros.svh"

module SimTop_wrapper(
  input           inter_soc_clk,
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
  (*mark_debug="true"*) input  [13:0]   dma_core_awid,
  (*mark_debug="true"*) input  [35:0]   dma_core_awaddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_awlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_awsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_awburst,
  (*mark_debug="true"*) input           dma_core_awlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_awcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_awprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_awqos,
  (*mark_debug="true"*) output          dma_core_wready,
  (*mark_debug="true"*) input           dma_core_wvalid,
  (*mark_debug="true"*) input  [255:0]  dma_core_wdata,
  (*mark_debug="true"*) input  [31:0]   dma_core_wstrb,
  (*mark_debug="true"*) input           dma_core_wlast,
  (*mark_debug="true"*) input           dma_core_bready,
  (*mark_debug="true"*) output          dma_core_bvalid,
  (*mark_debug="true"*) output [13:0]   dma_core_bid,
  (*mark_debug="true"*) output [1:0]    dma_core_bresp,
  (*mark_debug="true"*) output          dma_core_arready,
  (*mark_debug="true"*) input           dma_core_arvalid,
  (*mark_debug="true"*) input  [13:0]   dma_core_arid,
  (*mark_debug="true"*) input  [35:0]   dma_core_araddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_arlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_arsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_arburst,
  (*mark_debug="true"*) input           dma_core_arlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_arcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_arprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_arqos,
  (*mark_debug="true"*) input           dma_core_rready,
  (*mark_debug="true"*) output          dma_core_rvalid,
  (*mark_debug="true"*) output [13:0]   dma_core_rid,
  (*mark_debug="true"*) output [255:0]  dma_core_rdata,
  (*mark_debug="true"*) output [1:0]    dma_core_rresp,
  (*mark_debug="true"*) output          dma_core_rlast,

  (*mark_debug="true"*) input           peri_awready,
  (*mark_debug="true"*) output          peri_awvalid,
  (*mark_debug="true"*) output [1:0]    peri_awid,
  (*mark_debug="true"*) output [30:0]   peri_awaddr,
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
  (*mark_debug="true"*) output [1:0]    peri_arid,
  (*mark_debug="true"*) output [30:0]   peri_araddr,
  (*mark_debug="true"*) output [7:0]    peri_arlen,
  (*mark_debug="true"*) output [2:0]    peri_arsize,
  (*mark_debug="true"*) output [1:0]    peri_arburst,
  (*mark_debug="true"*) output          peri_arlock,
  (*mark_debug="true"*) output [3:0]    peri_arcache,
  (*mark_debug="true"*) output [2:0]    peri_arprot,
  (*mark_debug="true"*) output [3:0]    peri_arqos,
  (*mark_debug="true"*) output          peri_rready,
  (*mark_debug="true"*) input           peri_rvalid,
  (*mark_debug="true"*) input  [1:0]    peri_rid,
  (*mark_debug="true"*) input  [63:0]   peri_rdata,
  (*mark_debug="true"*) input  [1:0]    peri_rresp,
  (*mark_debug="true"*) input           peri_rlast,

  (*mark_debug="true"*) input           mem_core_awready,
  (*mark_debug="true"*) output          mem_core_awvalid,
  (*mark_debug="true"*) output [13:0]   mem_core_awid,
  (*mark_debug="true"*) output [35:0]   mem_core_awaddr,
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
  (*mark_debug="true"*) input  [17:0]   mem_core_bid,
  (*mark_debug="true"*) input  [1:0]    mem_core_bresp,
  (*mark_debug="true"*) input           mem_core_arready,
  (*mark_debug="true"*) output          mem_core_arvalid,
  (*mark_debug="true"*) output [13:0]   mem_core_arid,
  (*mark_debug="true"*) output [35:0]   mem_core_araddr,
  (*mark_debug="true"*) output [7:0]    mem_core_arlen,
  (*mark_debug="true"*) output [2:0]    mem_core_arsize,
  (*mark_debug="true"*) output [1:0]    mem_core_arburst,
  (*mark_debug="true"*) output          mem_core_arlock,
  (*mark_debug="true"*) output [3:0]    mem_core_arcache,
  (*mark_debug="true"*) output [2:0]    mem_core_arprot,
  (*mark_debug="true"*) output [3:0]    mem_core_arqos,
  (*mark_debug="true"*) output          mem_core_rready,
  (*mark_debug="true"*) input           mem_core_rvalid,
  (*mark_debug="true"*) input  [17:0]   mem_core_rid,
  (*mark_debug="true"*) input  [63:0]   mem_core_rdata,
  (*mark_debug="true"*) input  [1:0]    mem_core_rresp,
  (*mark_debug="true"*) input           mem_core_rlast,

input          difftest_ref_clock,
               difftest_ref_reset,
               difftest_pcie_clock,
input          difftest_to_host_axis_tready,
output         difftest_to_host_axis_tvalid,
output [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_to_host_axis_tdata,
output [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_to_host_axis_tkeep,
output         difftest_to_host_axis_tlast,
output         difftest_from_host_axis_tready,
input          difftest_from_host_axis_tvalid,
input  [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_from_host_axis_tdata,
input  [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_from_host_axis_tkeep,
input          difftest_from_host_axis_tlast,
output         difftest_clock_enable,
               difftest_hostCtrl_reset,
               difftest_hostCtrl_diffEnable,
               difftest_hostCtrl_ilaTrigger,
               difftest_hostCtrl_enableSquash,

input  [31:0]  difftest_cfg_axilite_awaddr,
input          difftest_cfg_axilite_awvalid,
output         difftest_cfg_axilite_awready,
input  [31:0]  difftest_cfg_axilite_wdata,
input  [3:0]   difftest_cfg_axilite_wstrb,
input          difftest_cfg_axilite_wvalid,
output         difftest_cfg_axilite_wready,
output [1:0]   difftest_cfg_axilite_bresp,
output         difftest_cfg_axilite_bvalid,
input          difftest_cfg_axilite_bready,
input  [31:0]  difftest_cfg_axilite_araddr,
input          difftest_cfg_axilite_arvalid,
output         difftest_cfg_axilite_arready,
output [31:0]  difftest_cfg_axilite_rdata,
output [1:0]   difftest_cfg_axilite_rresp,
output         difftest_cfg_axilite_rvalid,
input          difftest_cfg_axilite_rready
);


// BOOM FPGA wrapper: memory AXI to DDR, MMIO AXI to the board 16550.
// DMA/JTAG are unused by the BOOM configuration and are tied off.
assign cpu_to_soc             = 16'b0;
assign pll0_lock              = 1'b0;
assign pll0_clk_div_1024      = 1'b0;
assign pll0_test_calout       = 12'b0;
assign io_systemjtag_jtag_TDO_data   = 1'b0;
assign io_systemjtag_jtag_TDO_driven = 1'b0;

// DMA is not used by BOOM: return an always-ready/empty slave response.
assign dma_core_awready = 1'b1;
assign dma_core_wready  = 1'b1;
assign dma_core_bvalid  = 1'b0;
assign dma_core_bid     = 14'b0;
assign dma_core_bresp   = 2'b0;
assign dma_core_arready = 1'b1;
assign dma_core_rvalid  = 1'b0;
assign dma_core_rid     = 14'b0;
assign dma_core_rdata   = 256'b0;
assign dma_core_rresp   = 2'b0;
assign dma_core_rlast   = 1'b0;

assign mem_core_awaddr[35:32] = 4'b0;
assign mem_core_araddr[35:32] = 4'b0;
assign mem_core_awid[13:4]    = 10'b0;
assign mem_core_arid[13:4]    = 10'b0;

wire [29:0] boom_mmio_awaddr, boom_mmio_araddr;
wire [1:0]  boom_mmio_awid, boom_mmio_arid;
assign peri_awaddr[30]   = 1'b0;
assign peri_awaddr[29:0] = boom_mmio_awaddr;
assign peri_araddr[30]   = 1'b0;
assign peri_araddr[29:0] = boom_mmio_araddr;
assign peri_awid         = boom_mmio_awid;
assign peri_arid         = boom_mmio_arid;

SimTop u_SimTop (
    .clock                          (inter_soc_clk),
    .reset                          (~sys_rstn_i),

    .difftest_exit                  (),
    .difftest_step                  (),
    .difftest_perfCtrl_clean        (1'b0),
    .difftest_perfCtrl_dump         (1'b0),
    .difftest_logCtrl_begin         (64'b0),
    .difftest_logCtrl_end           (64'b0),
    .difftest_logCtrl_level         (64'b0),
    .difftest_uart_out_valid        (),
    .difftest_uart_out_ch           (),
    .difftest_uart_in_valid         (),
    .difftest_uart_in_ch            (8'b0),

    // The XDMAConfigBar/host endpoint must run on the free-running board
    // reference clock.  Using the gated CPU clock (inter_soc_clk) leaves the
    // PCIe config BAR unclocked until DiffTest is enabled, so xdma-chr cannot
    // probe it.
    .difftest_ref_clock             (difftest_ref_clock),
    .difftest_ref_reset             (difftest_ref_reset),
    .difftest_pcie_clock            (difftest_pcie_clock),

    .difftest_to_host_axis_tready   (difftest_to_host_axis_tready),
    .difftest_to_host_axis_tvalid   (difftest_to_host_axis_tvalid),
    .difftest_to_host_axis_tdata    (difftest_to_host_axis_tdata),
    .difftest_to_host_axis_tkeep    (difftest_to_host_axis_tkeep),
    .difftest_to_host_axis_tlast    (difftest_to_host_axis_tlast),
    .difftest_from_host_axis_tready (difftest_from_host_axis_tready),
    .difftest_from_host_axis_tvalid (difftest_from_host_axis_tvalid),
    .difftest_from_host_axis_tdata  (difftest_from_host_axis_tdata),
    .difftest_from_host_axis_tkeep  (difftest_from_host_axis_tkeep),
    .difftest_from_host_axis_tlast  (difftest_from_host_axis_tlast),
    .difftest_clock_enable          (difftest_clock_enable),
    .difftest_hostCtrl_reset        (difftest_hostCtrl_reset),
    .difftest_hostCtrl_diffEnable   (difftest_hostCtrl_diffEnable),
    .difftest_hostCtrl_ilaTrigger   (difftest_hostCtrl_ilaTrigger),
    .difftest_hostCtrl_enableSquash (difftest_hostCtrl_enableSquash),
    .difftest_hostCtrl_squashMaxFused (),

    .difftest_cfg_axilite_awready   (difftest_cfg_axilite_awready),
    .difftest_cfg_axilite_awvalid   (difftest_cfg_axilite_awvalid),
    .difftest_cfg_axilite_awaddr    (difftest_cfg_axilite_awaddr),
    .difftest_cfg_axilite_wready    (difftest_cfg_axilite_wready),
    .difftest_cfg_axilite_wvalid    (difftest_cfg_axilite_wvalid),
    .difftest_cfg_axilite_wdata     (difftest_cfg_axilite_wdata),
    .difftest_cfg_axilite_wstrb     (difftest_cfg_axilite_wstrb),
    .difftest_cfg_axilite_bready    (difftest_cfg_axilite_bready),
    .difftest_cfg_axilite_bvalid    (difftest_cfg_axilite_bvalid),
    .difftest_cfg_axilite_bresp     (difftest_cfg_axilite_bresp),
    .difftest_cfg_axilite_arready   (difftest_cfg_axilite_arready),
    .difftest_cfg_axilite_arvalid   (difftest_cfg_axilite_arvalid),
    .difftest_cfg_axilite_araddr    (difftest_cfg_axilite_araddr),
    .difftest_cfg_axilite_rready    (difftest_cfg_axilite_rready),
    .difftest_cfg_axilite_rvalid    (difftest_cfg_axilite_rvalid),
    .difftest_cfg_axilite_rdata     (difftest_cfg_axilite_rdata),
    .difftest_cfg_axilite_rresp     (difftest_cfg_axilite_rresp),

    // Memory AXI: 32-bit address / 64-bit data / 4-bit ID to the DDR path.
    .difftest_mem_awready       (mem_core_awready),
    .difftest_mem_awvalid       (mem_core_awvalid),
    .difftest_mem_awaddr        (mem_core_awaddr[31:0]),
    .difftest_mem_awid          (mem_core_awid[3:0]),
    .difftest_mem_awlen         (mem_core_awlen),
    .difftest_mem_awsize        (mem_core_awsize),
    .difftest_mem_awburst       (mem_core_awburst),
    .difftest_mem_awlock        (mem_core_awlock),
    .difftest_mem_awcache       (mem_core_awcache),
    .difftest_mem_awprot        (mem_core_awprot),
    .difftest_mem_awqos         (mem_core_awqos),
    .difftest_mem_awuser        (),
    .difftest_mem_wready        (mem_core_wready),
    .difftest_mem_wvalid        (mem_core_wvalid),
    .difftest_mem_wdata         (mem_core_wdata),
    .difftest_mem_wstrb         (mem_core_wstrb),
    .difftest_mem_wlast         (mem_core_wlast),
    .difftest_mem_bready        (mem_core_bready),
    .difftest_mem_bvalid        (mem_core_bvalid),
    .difftest_mem_bresp         (mem_core_bresp),
    .difftest_mem_bid           (mem_core_bid[3:0]),
    .difftest_mem_buser         (1'b0),
    .difftest_mem_arready       (mem_core_arready),
    .difftest_mem_arvalid       (mem_core_arvalid),
    .difftest_mem_araddr        (mem_core_araddr[31:0]),
    .difftest_mem_arid          (mem_core_arid[3:0]),
    .difftest_mem_arlen         (mem_core_arlen),
    .difftest_mem_arsize        (mem_core_arsize),
    .difftest_mem_arburst       (mem_core_arburst),
    .difftest_mem_arlock        (mem_core_arlock),
    .difftest_mem_arcache       (mem_core_arcache),
    .difftest_mem_arprot        (mem_core_arprot),
    .difftest_mem_arqos         (mem_core_arqos),
    .difftest_mem_aruser        (),
    .difftest_mem_rready        (mem_core_rready),
    .difftest_mem_rvalid        (mem_core_rvalid),
    .difftest_mem_rdata         (mem_core_rdata),
    .difftest_mem_rresp         (mem_core_rresp),
    .difftest_mem_rlast         (mem_core_rlast),
    .difftest_mem_rid           (mem_core_rid[3:0]),
    .difftest_mem_ruser         (1'b0),

    // MMIO AXI: 30-bit address / 64-bit data / 2-bit ID to the board 16550.
    .peri_aw_ready                   (peri_awready),
    .peri_aw_valid                   (peri_awvalid),
    .peri_aw_bits_id                 (boom_mmio_awid),
    .peri_aw_bits_addr               (boom_mmio_awaddr),
    .peri_aw_bits_len                (peri_awlen),
    .peri_aw_bits_size               (peri_awsize),
    .peri_aw_bits_burst              (peri_awburst),
    .peri_aw_bits_lock               (peri_awlock),
    .peri_aw_bits_cache              (peri_awcache),
    .peri_aw_bits_prot               (peri_awprot),
    .peri_aw_bits_qos                (peri_awqos),
    .peri_w_ready                    (peri_wready),
    .peri_w_valid                    (peri_wvalid),
    .peri_w_bits_data                (peri_wdata),
    .peri_w_bits_strb                (peri_wstrb),
    .peri_w_bits_last                (peri_wlast),
    .peri_b_ready                    (peri_bready),
    .peri_b_valid                    (peri_bvalid),
    .peri_b_bits_id                  (peri_bid),
    .peri_b_bits_resp                (peri_bresp),
    .peri_ar_ready                   (peri_arready),
    .peri_ar_valid                   (peri_arvalid),
    .peri_ar_bits_id                 (boom_mmio_arid),
    .peri_ar_bits_addr               (boom_mmio_araddr),
    .peri_ar_bits_len                (peri_arlen),
    .peri_ar_bits_size               (peri_arsize),
    .peri_ar_bits_burst              (peri_arburst),
    .peri_ar_bits_lock               (peri_arlock),
    .peri_ar_bits_cache              (peri_arcache),
    .peri_ar_bits_prot               (peri_arprot),
    .peri_ar_bits_qos                (peri_arqos),
    .peri_r_ready                    (peri_rready),
    .peri_r_valid                    (peri_rvalid),
    .peri_r_bits_id                  (peri_rid),
    .peri_r_bits_data                (peri_rdata),
    .peri_r_bits_resp                (peri_rresp),
    .peri_r_bits_last                (peri_rlast)
);
endmodule
