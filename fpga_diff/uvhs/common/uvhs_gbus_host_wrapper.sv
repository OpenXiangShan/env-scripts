`ifndef NO_DIFF
`include "DifftestMacros.svh"
`endif

// GBus DiffTest host wrapper.
//
// This is the GBus host interface extracted from core_def so the shared core
// keeps a single DiffTest host instance.  GBus is opt-in through
// DIFFTEST_HOST_GBUS and XDMA is the default host; nothing here is CPU-family
// specific.
//
// The GBus C2H stream is parked in on-chip SRAM and drained through the GBS1
// register window.  H2C converts GeneralBus AXI3 writes into the existing
// DifftestMemCtrl AXI-stream engine.  The generated dma_core_* slave stays idle
// in core_def, so the two hostifs remain exclusive owners of their inbound
// masters.
module uvhs_gbus_host_wrapper (
    input  wire        sys_clk_i,
    input  wire        sys_rstn,
    // Always-running GBus host clock (dev_clk_i / clk6_p) and its reset.
    input  wire        gbus_host_clk,
    input  wire        rstn_sw4,
    // Gated CPU clock domain used by the C2H staging FIFO and the H2C CDC.
    input  wire        inter_soc_clk,
    input  wire        inter_soc_sync_rstn,
    // Host startup state from the shared core startup synchronizer.
    input  wire        cpu_rstn_pcie,
    input  wire        difftest_stream_enable_pcie,

    // DiffTest C2H stream from the generated SimTop sender.
    input  wire        difftest_to_host_axis_tvalid_io,
    input  wire [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_to_host_axis_tdata,
    input  wire [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_to_host_axis_tkeep,
    input  wire        difftest_to_host_axis_tlast,
    output wire        difftest_to_host_axis_tready_io,

    // DiffTest H2C stream into the generated SimTop receiver.
    input  wire        difftest_from_host_axis_tready,
    output wire        difftest_from_host_axis_tvalid,
    output wire [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_from_host_axis_tdata,
    output wire [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_from_host_axis_tkeep,
    output wire        difftest_from_host_axis_tlast,

    // DiffTest configuration AXI-Lite into the generated SimTop config slave.
    output wire [31:0] difftest_cfg_axilite_awaddr,
    output wire        difftest_cfg_axilite_awvalid,
    input  wire        difftest_cfg_axilite_awready,
    output wire [31:0] difftest_cfg_axilite_wdata,
    output wire [3:0]  difftest_cfg_axilite_wstrb,
    output wire        difftest_cfg_axilite_wvalid,
    input  wire        difftest_cfg_axilite_wready,
    input  wire [1:0]  difftest_cfg_axilite_bresp,
    input  wire        difftest_cfg_axilite_bvalid,
    output wire        difftest_cfg_axilite_bready,
    output wire [31:0] difftest_cfg_axilite_araddr,
    output wire        difftest_cfg_axilite_arvalid,
    input  wire        difftest_cfg_axilite_arready,
    input  wire [31:0] difftest_cfg_axilite_rdata,
    input  wire [1:0]  difftest_cfg_axilite_rresp,
    input  wire        difftest_cfg_axilite_rvalid,
    output wire        difftest_cfg_axilite_rready
);

  // Host-clock AXI-Lite emitted by the GeneralBD register bridge.  It carries
  // the DiffTest configuration BAR and crosses to sys_clk_i before SimTop.
  wire [31:0] XDMA_AXI_LITE_awaddr;
  wire [2:0]  XDMA_AXI_LITE_awprot;
  wire        XDMA_AXI_LITE_awvalid;
  wire        XDMA_AXI_LITE_awready;
  wire [31:0] XDMA_AXI_LITE_wdata;
  wire [3:0]  XDMA_AXI_LITE_wstrb;
  wire        XDMA_AXI_LITE_wvalid;
  wire        XDMA_AXI_LITE_wready;
  wire [1:0]  XDMA_AXI_LITE_bresp;
  wire        XDMA_AXI_LITE_bvalid;
  wire        XDMA_AXI_LITE_bready;
  wire [31:0] XDMA_AXI_LITE_araddr;
  wire [2:0]  XDMA_AXI_LITE_arprot;
  wire        XDMA_AXI_LITE_arvalid;
  wire        XDMA_AXI_LITE_arready;
  wire [31:0] XDMA_AXI_LITE_rdata;
  wire [1:0]  XDMA_AXI_LITE_rresp;
  wire        XDMA_AXI_LITE_rvalid;
  wire        XDMA_AXI_LITE_rready;

  wire difftest_c2h_rstn = cpu_rstn_pcie & difftest_stream_enable_pcie;
  wire gbus_cfg_wr_en;
  wire [15:0] gbus_cfg_wr_addr;
  wire [31:0] gbus_cfg_wdata;
  wire gbus_cfg_rd_en;
  wire [15:0] gbus_cfg_rd_addr;
  wire [31:0] gbus_cfg_rdata;
  wire gbus_cfg_rdata_vld;
  wire [15:0] gbus_cfg_local_wr_addr;
  wire [15:0] gbus_cfg_local_rd_addr;
  wire [31:0] gbus_c2h_cfg_rdata;
  wire gbus_c2h_cfg_rdata_vld;
  wire [31:0] gbus_axil_cfg_rdata;
  wire gbus_axil_cfg_rdata_vld;
  wire [7:0] gbus_axi_awid;
  wire [31:0] gbus_axi_awaddr;
  wire [3:0] gbus_axi_awlen;
  wire [2:0] gbus_axi_awsize;
  wire [1:0] gbus_axi_awburst, gbus_axi_awlock;
  wire [3:0] gbus_axi_awcache, gbus_axi_awqos;
  wire [2:0] gbus_axi_awprot;
  wire gbus_axi_awvalid, gbus_axi_awready;
  wire [7:0] gbus_axi_wid;
  wire [255:0] gbus_axi_wdata;
  wire [31:0] gbus_axi_wstrb;
  wire gbus_axi_wlast, gbus_axi_wvalid, gbus_axi_wready;
  wire [7:0] gbus_axi_bid;
  wire [1:0] gbus_axi_bresp;
  wire gbus_axi_bvalid, gbus_axi_bready;
  wire [7:0] gbus_axi_arid;
  wire [31:0] gbus_axi_araddr;
  wire [3:0] gbus_axi_arlen;
  wire [2:0] gbus_axi_arsize;
  wire [1:0] gbus_axi_arburst, gbus_axi_arlock;
  wire [3:0] gbus_axi_arcache, gbus_axi_arqos;
  wire [2:0] gbus_axi_arprot;
  wire gbus_axi_arvalid, gbus_axi_arready;
  wire [7:0] gbus_axi_rid;
  wire [255:0] gbus_axi_rdata;
  wire [1:0] gbus_axi_rresp;
  wire gbus_axi_rlast, gbus_axi_rvalid, gbus_axi_rready;

  wire gbus_c2h_sready;
  wire gbus_h2c_axis_tvalid;
  wire gbus_h2c_axis_tready;
  wire gbus_h2c_axis_tlast;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] gbus_h2c_axis_tdata;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] gbus_h2c_axis_tkeep;
  wire [255:0] gbus_sysbus_to_generalbus;
  wire [255:0] gbus_sysbus_to_generalbd;

  assign difftest_to_host_axis_tready_io = gbus_c2h_sready;
  assign gbus_cfg_local_wr_addr = gbus_cfg_wr_addr - 16'h1000;
  assign gbus_cfg_local_rd_addr = gbus_cfg_rd_addr - 16'h1000;

`ifdef UVHS_GBUS_C2H_DMA
  // GBD1: one control register, the diagnostic registers through 0x1220, and a
  // 1 KiB published bank.
  wire gbus_c2h_cfg_wr_en =
      gbus_cfg_wr_en && (gbus_cfg_local_wr_addr == 16'h1204);
  wire gbus_c2h_cfg_rd_en =
      gbus_cfg_rd_en &&
      (((gbus_cfg_local_rd_addr >= 16'h1200) && (gbus_cfg_local_rd_addr <= 16'h1220)) ||
       ((gbus_cfg_local_rd_addr >= 16'h2000) && (gbus_cfg_local_rd_addr <= 16'h23fc)));
`else
  wire gbus_c2h_cfg_wr_en =
      gbus_cfg_wr_en && (gbus_cfg_local_wr_addr >= 16'h1200) && (gbus_cfg_local_wr_addr <= 16'h1208);
  wire gbus_c2h_cfg_rd_en =
      gbus_cfg_rd_en &&
      (((gbus_cfg_local_rd_addr >= 16'h1200) && (gbus_cfg_local_rd_addr <= 16'h1208)) ||
       ((gbus_cfg_local_rd_addr >= 16'h2000) && (gbus_cfg_local_rd_addr <= 16'h2ffc)));
`endif
  wire gbus_axil_cfg_wr_en = gbus_cfg_wr_en && (gbus_cfg_local_wr_addr <= 16'h0030);
  wire gbus_axil_cfg_rd_en = gbus_cfg_rd_en && (gbus_cfg_local_rd_addr <= 16'h0030);

`ifdef UVHS_GBUS_C2H_DMA
  // C2H DMA version.  The host drains the published bank with AXI3 DMA reads
  // instead of 32-bit register reads; the read router sends reads inside the
  // 4 KiB aperture here and every other read to the H2C converter's existing
  // DECERR responder.  H2C writes keep using the DifftestMemCtrl stream path.
  wire [7:0]   gbus_local_arid, gbus_local_rid;
  wire [31:0]  gbus_local_araddr;
  wire [3:0]   gbus_local_arlen;
  wire [2:0]   gbus_local_arsize;
  wire [1:0]   gbus_local_arburst, gbus_local_rresp;
  wire         gbus_local_arvalid, gbus_local_arready;
  wire [255:0] gbus_local_rdata;
  wire         gbus_local_rlast, gbus_local_rvalid, gbus_local_rready;
  wire [7:0]   gbus_routed_arid, gbus_routed_rid;
  wire [31:0]  gbus_routed_araddr;
  wire [3:0]   gbus_routed_arlen, gbus_routed_arcache, gbus_routed_arqos;
  wire [2:0]   gbus_routed_arsize, gbus_routed_arprot;
  wire [1:0]   gbus_routed_arburst, gbus_routed_arlock, gbus_routed_rresp;
  wire         gbus_routed_arvalid, gbus_routed_arready;
  wire [255:0] gbus_routed_rdata;
  wire         gbus_routed_rlast, gbus_routed_rvalid, gbus_routed_rready;

  uvhs_gbus_axi_read_router U_GBUS_C2H_READ_ROUTER (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .s_arid(gbus_axi_arid), .s_araddr(gbus_axi_araddr), .s_arlen(gbus_axi_arlen),
    .s_arsize(gbus_axi_arsize), .s_arburst(gbus_axi_arburst), .s_arlock(gbus_axi_arlock),
    .s_arcache(gbus_axi_arcache), .s_arprot(gbus_axi_arprot), .s_arqos(gbus_axi_arqos),
    .s_arvalid(gbus_axi_arvalid), .s_arready(gbus_axi_arready),
    .s_rid(gbus_axi_rid), .s_rdata(gbus_axi_rdata), .s_rresp(gbus_axi_rresp),
    .s_rlast(gbus_axi_rlast), .s_rvalid(gbus_axi_rvalid), .s_rready(gbus_axi_rready),
    .c_arid(gbus_local_arid), .c_araddr(gbus_local_araddr), .c_arlen(gbus_local_arlen),
    .c_arsize(gbus_local_arsize), .c_arburst(gbus_local_arburst),
    .c_arvalid(gbus_local_arvalid), .c_arready(gbus_local_arready),
    .c_rid(gbus_local_rid), .c_rdata(gbus_local_rdata), .c_rresp(gbus_local_rresp),
    .c_rlast(gbus_local_rlast), .c_rvalid(gbus_local_rvalid), .c_rready(gbus_local_rready),
    .d_arid(gbus_routed_arid), .d_araddr(gbus_routed_araddr), .d_arlen(gbus_routed_arlen),
    .d_arsize(gbus_routed_arsize), .d_arburst(gbus_routed_arburst), .d_arlock(gbus_routed_arlock),
    .d_arcache(gbus_routed_arcache), .d_arprot(gbus_routed_arprot), .d_arqos(gbus_routed_arqos),
    .d_arvalid(gbus_routed_arvalid), .d_arready(gbus_routed_arready),
    .d_rid(gbus_routed_rid), .d_rdata(gbus_routed_rdata), .d_rresp(gbus_routed_rresp),
    .d_rlast(gbus_routed_rlast), .d_rvalid(gbus_routed_rvalid), .d_rready(gbus_routed_rready)
  );

  uvhs_gbus_c2h_dma #(
      .AXIS_DATA_WIDTH(`CONFIG_DIFFTEST_HOST_AXIS_WIDTH)
  ) U_GBUS_C2H_FIFO (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .stream_rstn(difftest_c2h_rstn),
    .s_tdata(difftest_to_host_axis_tdata), .s_tkeep(difftest_to_host_axis_tkeep),
    .s_tlast(difftest_to_host_axis_tlast), .s_tvalid(difftest_to_host_axis_tvalid_io),
    .s_tready(gbus_c2h_sready),
    .cfg_wr_en(gbus_c2h_cfg_wr_en), .cfg_wr_addr(gbus_cfg_local_wr_addr),
    .cfg_wdata(gbus_cfg_wdata), .cfg_rd_en(gbus_c2h_cfg_rd_en),
    .cfg_rd_addr(gbus_cfg_local_rd_addr), .cfg_rdata(gbus_c2h_cfg_rdata),
    .cfg_rdata_vld(gbus_c2h_cfg_rdata_vld),
    .s_arid(gbus_local_arid), .s_araddr(gbus_local_araddr), .s_arlen(gbus_local_arlen),
    .s_arsize(gbus_local_arsize), .s_arburst(gbus_local_arburst),
    .s_arvalid(gbus_local_arvalid), .s_arready(gbus_local_arready),
    .s_rid(gbus_local_rid), .s_rdata(gbus_local_rdata), .s_rresp(gbus_local_rresp),
    .s_rlast(gbus_local_rlast), .s_rvalid(gbus_local_rvalid), .s_rready(gbus_local_rready)
  );
`else
  uvhs_gbus_c2h_fifo #(
      .AXIS_DATA_WIDTH(`CONFIG_DIFFTEST_HOST_AXIS_WIDTH)
  ) U_GBUS_C2H_FIFO (
    .s_clk(inter_soc_clk), .s_rstn(inter_soc_sync_rstn),
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .stream_rstn(difftest_c2h_rstn),
    .s_tdata(difftest_to_host_axis_tdata), .s_tkeep(difftest_to_host_axis_tkeep),
    .s_tlast(difftest_to_host_axis_tlast), .s_tvalid(difftest_to_host_axis_tvalid_io),
    .s_tready(gbus_c2h_sready),
    .cfg_wr_en(gbus_c2h_cfg_wr_en), .cfg_wr_addr(gbus_cfg_local_wr_addr),
    .cfg_wdata(gbus_cfg_wdata), .cfg_rd_en(gbus_c2h_cfg_rd_en),
    .cfg_rd_addr(gbus_cfg_local_rd_addr), .cfg_rdata(gbus_c2h_cfg_rdata),
    .cfg_rdata_vld(gbus_c2h_cfg_rdata_vld)
  );
`endif

  uvhs_generalbd_axilite_bridge U_GBUS_CONFIG_BRIDGE (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .gbd_wr_en(gbus_axil_cfg_wr_en), .gbd_wr_addr(gbus_cfg_local_wr_addr),
    .gbd_wdata(gbus_cfg_wdata), .gbd_rd_en(gbus_axil_cfg_rd_en),
    .gbd_rd_addr(gbus_cfg_local_rd_addr), .gbd_rdata(gbus_axil_cfg_rdata),
    .gbd_rdata_vld(gbus_axil_cfg_rdata_vld),
    .axil_awaddr(XDMA_AXI_LITE_awaddr), .axil_awvalid(XDMA_AXI_LITE_awvalid),
    .axil_awready(XDMA_AXI_LITE_awready), .axil_wdata(XDMA_AXI_LITE_wdata),
    .axil_wstrb(XDMA_AXI_LITE_wstrb), .axil_wvalid(XDMA_AXI_LITE_wvalid),
    .axil_wready(XDMA_AXI_LITE_wready), .axil_bresp(XDMA_AXI_LITE_bresp),
    .axil_bvalid(XDMA_AXI_LITE_bvalid), .axil_bready(XDMA_AXI_LITE_bready),
    .axil_araddr(XDMA_AXI_LITE_araddr), .axil_arvalid(XDMA_AXI_LITE_arvalid),
    .axil_arready(XDMA_AXI_LITE_arready), .axil_rdata(XDMA_AXI_LITE_rdata),
    .axil_rresp(XDMA_AXI_LITE_rresp), .axil_rvalid(XDMA_AXI_LITE_rvalid),
    .axil_rready(XDMA_AXI_LITE_rready)
  );
  assign XDMA_AXI_LITE_awprot = 3'b0;
  assign XDMA_AXI_LITE_arprot = 3'b0;
  assign gbus_cfg_rdata = gbus_axil_cfg_rdata_vld ? gbus_axil_cfg_rdata : gbus_c2h_cfg_rdata;
  assign gbus_cfg_rdata_vld = gbus_axil_cfg_rdata_vld | gbus_c2h_cfg_rdata_vld;

  generalBD U_GBUS_GENERALBD (
    .i_clk        (gbus_host_clk),
    .i_rstn       (rstn_sw4),
    .i_clk_en     (1'b1),
    .o_wr_en      (gbus_cfg_wr_en),
    .o_wr_addr    (gbus_cfg_wr_addr),
    .o_wdata      (gbus_cfg_wdata),
    .o_rd_en      (gbus_cfg_rd_en),
    .o_rd_addr    (gbus_cfg_rd_addr),
    .i_rdata      (gbus_cfg_rdata),
    .i_rdata_vld  (gbus_cfg_rdata_vld),
    .gbd_sysbus_i (gbus_sysbus_to_generalbd),
    .gbd_sysbus_o (gbus_sysbus_to_generalbus)
  );

  uvw_general_bus U_GBUS_GENERAL_BUS (
    .dut_axi_aclk    (gbus_host_clk),
    .dut_axi_aclk_en (1'b1),
    .dut_axi_aresetn (rstn_sw4),
    .dut_axi_awid    (gbus_axi_awid), .dut_axi_awaddr(gbus_axi_awaddr), .dut_axi_awlen(gbus_axi_awlen),
    .dut_axi_awsize  (gbus_axi_awsize), .dut_axi_awburst(gbus_axi_awburst), .dut_axi_awlock(gbus_axi_awlock),
    .dut_axi_awcache(gbus_axi_awcache), .dut_axi_awprot(gbus_axi_awprot), .dut_axi_awqos(gbus_axi_awqos),
    .dut_axi_awvalid(gbus_axi_awvalid), .dut_axi_awready(gbus_axi_awready), .dut_axi_wid(gbus_axi_wid),
    .dut_axi_wdata(gbus_axi_wdata), .dut_axi_wstrb(gbus_axi_wstrb), .dut_axi_wlast(gbus_axi_wlast),
    .dut_axi_wvalid(gbus_axi_wvalid), .dut_axi_wready(gbus_axi_wready), .dut_axi_bid(gbus_axi_bid),
    .dut_axi_bresp(gbus_axi_bresp), .dut_axi_bvalid(gbus_axi_bvalid), .dut_axi_bready(gbus_axi_bready),
    .dut_axi_arid(gbus_axi_arid), .dut_axi_araddr(gbus_axi_araddr), .dut_axi_arlen(gbus_axi_arlen),
    .dut_axi_arsize(gbus_axi_arsize), .dut_axi_arburst(gbus_axi_arburst), .dut_axi_arlock(gbus_axi_arlock),
    .dut_axi_arcache(gbus_axi_arcache), .dut_axi_arprot(gbus_axi_arprot), .dut_axi_arqos(gbus_axi_arqos),
    .dut_axi_arvalid(gbus_axi_arvalid), .dut_axi_arready(gbus_axi_arready), .dut_axi_rid(gbus_axi_rid),
    .dut_axi_rdata(gbus_axi_rdata), .dut_axi_rresp(gbus_axi_rresp), .dut_axi_rlast(gbus_axi_rlast),
    .dut_axi_rvalid(gbus_axi_rvalid), .dut_axi_rready(gbus_axi_rready),
    .sysbus_ghbd_o (gbus_sysbus_to_generalbd),
    .sysbus_ghbd_i (gbus_sysbus_to_generalbus)
  );

  uvhs_gbus_axi_to_axis #(
      .ID_WIDTH(8), .DATA_WIDTH(256)
  ) U_GBUS_H2C_AXIS (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .s_awid(gbus_axi_awid), .s_awvalid(gbus_axi_awvalid),
    .s_awready(gbus_axi_awready),
    .s_wdata(gbus_axi_wdata), .s_wstrb(gbus_axi_wstrb),
    .s_wlast(gbus_axi_wlast), .s_wvalid(gbus_axi_wvalid),
    .s_wready(gbus_axi_wready), .s_bid(gbus_axi_bid),
    .s_bresp(gbus_axi_bresp), .s_bvalid(gbus_axi_bvalid),
    .s_bready(gbus_axi_bready),
`ifdef UVHS_GBUS_C2H_DMA
    .s_arid(gbus_routed_arid),
    .s_arvalid(gbus_routed_arvalid), .s_arready(gbus_routed_arready),
    .s_rid(gbus_routed_rid), .s_rdata(gbus_routed_rdata),
    .s_rresp(gbus_routed_rresp), .s_rlast(gbus_routed_rlast),
    .s_rvalid(gbus_routed_rvalid), .s_rready(gbus_routed_rready),
`else
    .s_arid(gbus_axi_arid),
    .s_arvalid(gbus_axi_arvalid), .s_arready(gbus_axi_arready),
    .s_rid(gbus_axi_rid), .s_rdata(gbus_axi_rdata),
    .s_rresp(gbus_axi_rresp), .s_rlast(gbus_axi_rlast),
    .s_rvalid(gbus_axi_rvalid), .s_rready(gbus_axi_rready),
`endif
    .m_tvalid(gbus_h2c_axis_tvalid),
    .m_tdata(gbus_h2c_axis_tdata),
    .m_tkeep(gbus_h2c_axis_tkeep),
    .m_tlast(gbus_h2c_axis_tlast),
    .m_tready(gbus_h2c_axis_tready)
  );
  // DifftestMemCtrl H2C ignores AXI addresses and burst metadata.
  wire _unused_gbus_axi3 = &{1'b0,
      gbus_axi_awaddr, gbus_axi_awlen, gbus_axi_awsize, gbus_axi_awburst,
      gbus_axi_awlock, gbus_axi_awcache, gbus_axi_awprot, gbus_axi_awqos,
      gbus_axi_wid, gbus_axi_araddr, gbus_axi_arlen, gbus_axi_arsize,
      gbus_axi_arburst, gbus_axi_arlock, gbus_axi_arcache, gbus_axi_arprot,
      gbus_axi_arqos};

  // GeneralBus H2C is on the free-running host clock.  DifftestMemCtrl's
  // AXIS engine is on the gated CPU clock, so cross before SimTop.
  uvhs_axis_async_fifo #(
      .DATA_WIDTH(`CONFIG_DIFFTEST_HOST_AXIS_WIDTH),
      .KEEP_WIDTH(`CONFIG_DIFFTEST_HOST_AXIS_BYTES),
      .ADDR_WIDTH(4)
  ) U_GBUS_H2C_CDC (
      .s_clk(gbus_host_clk),
      .s_rstn(rstn_sw4),
      .s_tdata(gbus_h2c_axis_tdata),
      .s_tkeep(gbus_h2c_axis_tkeep),
      .s_tlast(gbus_h2c_axis_tlast),
      .s_tvalid(gbus_h2c_axis_tvalid),
      .s_tready(gbus_h2c_axis_tready),
      .s_has_data(),
      .m_clk(inter_soc_clk),
      .m_rstn(inter_soc_sync_rstn),
      .m_tdata(difftest_from_host_axis_tdata),
      .m_tkeep(difftest_from_host_axis_tkeep),
      .m_tlast(difftest_from_host_axis_tlast),
      .m_tvalid(difftest_from_host_axis_tvalid),
      .m_tready(difftest_from_host_axis_tready),
      .m_has_data()
  );

  // GeneralBD AXI-Lite is on the free-running GBus host clock.  The DiffTest
  // config slave is on sys_clk_i, so cross only in the GBus build.
  uvhs_axilite_cdc_bridge #(
      .ADDR_WIDTH (32),
      .DATA_WIDTH (32)
  ) difftest_cfg_axilite_cdc (
      .s_clk      (gbus_host_clk),
      .s_resetn   (sys_rstn),
      .s_awaddr   (XDMA_AXI_LITE_awaddr),
      .s_awprot   (XDMA_AXI_LITE_awprot),
      .s_awvalid  (XDMA_AXI_LITE_awvalid),
      .s_awready  (XDMA_AXI_LITE_awready),
      .s_wdata    (XDMA_AXI_LITE_wdata),
      .s_wstrb    (XDMA_AXI_LITE_wstrb),
      .s_wvalid   (XDMA_AXI_LITE_wvalid),
      .s_wready   (XDMA_AXI_LITE_wready),
      .s_bresp    (XDMA_AXI_LITE_bresp),
      .s_bvalid   (XDMA_AXI_LITE_bvalid),
      .s_bready   (XDMA_AXI_LITE_bready),
      .s_araddr   (XDMA_AXI_LITE_araddr),
      .s_arprot   (XDMA_AXI_LITE_arprot),
      .s_arvalid  (XDMA_AXI_LITE_arvalid),
      .s_arready  (XDMA_AXI_LITE_arready),
      .s_rdata    (XDMA_AXI_LITE_rdata),
      .s_rresp    (XDMA_AXI_LITE_rresp),
      .s_rvalid   (XDMA_AXI_LITE_rvalid),
      .s_rready   (XDMA_AXI_LITE_rready),

      .m_clk      (sys_clk_i),
      .m_resetn   (sys_rstn),
      .m_awaddr   (difftest_cfg_axilite_awaddr),
      .m_awprot   (),
      .m_awvalid  (difftest_cfg_axilite_awvalid),
      .m_awready  (difftest_cfg_axilite_awready),
      .m_wdata    (difftest_cfg_axilite_wdata),
      .m_wstrb    (difftest_cfg_axilite_wstrb),
      .m_wvalid   (difftest_cfg_axilite_wvalid),
      .m_wready   (difftest_cfg_axilite_wready),
      .m_bresp    (difftest_cfg_axilite_bresp),
      .m_bvalid   (difftest_cfg_axilite_bvalid),
      .m_bready   (difftest_cfg_axilite_bready),
      .m_araddr   (difftest_cfg_axilite_araddr),
      .m_arprot   (),
      .m_arvalid  (difftest_cfg_axilite_arvalid),
      .m_arready  (difftest_cfg_axilite_arready),
      .m_rdata    (difftest_cfg_axilite_rdata),
      .m_rresp    (difftest_cfg_axilite_rresp),
      .m_rvalid   (difftest_cfg_axilite_rvalid),
      .m_rready   (difftest_cfg_axilite_rready)
  );
endmodule
