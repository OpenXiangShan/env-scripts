`timescale 1ns/1ps

module uvhs_ddr4_wrapper (
  input  wire         clk,
  input  wire         rstn,
  output wire         calib_complete,

  input  wire [17:0]  s_axi_awid,
`ifdef CPU_NUTSHELL
  input  wire [32:0]  s_axi_awaddr,
`else
  input  wire [39:0]  s_axi_awaddr,
`endif
  input  wire [7:0]   s_axi_awlen,
  input  wire [2:0]   s_axi_awsize,
  input  wire [1:0]   s_axi_awburst,
  input  wire         s_axi_awlock,
  input  wire [3:0]   s_axi_awcache,
  input  wire [2:0]   s_axi_awprot,
  input  wire [3:0]   s_axi_awqos,
  input  wire [3:0]   s_axi_awregion,
  input  wire         s_axi_awvalid,
  output wire         s_axi_awready,
`ifdef CPU_NUTSHELL
  input  wire [63:0]  s_axi_wdata,
  input  wire [7:0]   s_axi_wstrb,
`else
  input  wire [255:0] s_axi_wdata,
  input  wire [31:0]  s_axi_wstrb,
`endif
  input  wire         s_axi_wlast,
  input  wire         s_axi_wvalid,
  output wire         s_axi_wready,
  output wire [17:0]  s_axi_bid,
  output wire [1:0]   s_axi_bresp,
  output wire         s_axi_bvalid,
  input  wire         s_axi_bready,

  input  wire [17:0]  s_axi_arid,
`ifdef CPU_NUTSHELL
  input  wire [32:0]  s_axi_araddr,
`else
  input  wire [39:0]  s_axi_araddr,
`endif
  input  wire [7:0]   s_axi_arlen,
  input  wire [2:0]   s_axi_arsize,
  input  wire [1:0]   s_axi_arburst,
  input  wire         s_axi_arlock,
  input  wire [3:0]   s_axi_arcache,
  input  wire [2:0]   s_axi_arprot,
  input  wire [3:0]   s_axi_arqos,
  input  wire [3:0]   s_axi_arregion,
  input  wire         s_axi_arvalid,
  output wire         s_axi_arready,
  output wire [17:0]  s_axi_rid,
`ifdef CPU_NUTSHELL
  output wire [63:0]  s_axi_rdata,
`else
  output wire [255:0] s_axi_rdata,
`endif
  output wire [1:0]   s_axi_rresp,
  output wire         s_axi_rlast,
  output wire         s_axi_rvalid,
  input  wire         s_axi_rready
);

  wire [13:0]  ddr_awid;
  wire [33:0]  ddr_awaddr;
  wire [7:0]   ddr_awlen;
  wire [2:0]   ddr_awsize;
  wire [1:0]   ddr_awburst;
  wire [0:0]   ddr_awlock;
  wire [3:0]   ddr_awcache;
  wire [2:0]   ddr_awprot;
  wire [3:0]   ddr_awqos;
  wire [3:0]   ddr_awregion;
  wire         ddr_awvalid;
  wire         ddr_awready;
  wire [255:0] ddr_wdata;
  wire [31:0]  ddr_wstrb;
  wire         ddr_wlast;
  wire         ddr_wvalid;
  wire         ddr_wready;
  wire [13:0]  ddr_bid;
  wire [1:0]   ddr_bresp;
  wire         ddr_bvalid;
  wire         ddr_bready;
  wire [13:0]  ddr_arid;
  wire [33:0]  ddr_araddr;
  wire [7:0]   ddr_arlen;
  wire [2:0]   ddr_arsize;
  wire [1:0]   ddr_arburst;
  wire [0:0]   ddr_arlock;
  wire [3:0]   ddr_arcache;
  wire [2:0]   ddr_arprot;
  wire [3:0]   ddr_arqos;
  wire [3:0]   ddr_arregion;
  wire         ddr_arvalid;
  wire         ddr_arready;
  wire [255:0] ddr_rdata;
  wire [13:0]  ddr_rid;
  wire [1:0]   ddr_rresp;
  wire         ddr_rlast;
  wire         ddr_rvalid;
  wire         ddr_rready;
  wire         ddr_user_rst;

`ifdef CPU_NUTSHELL
  wire [13:0] s_axi_bid_64;
  wire [13:0] s_axi_rid_64;
  wire [63:0] s_axi_rdata_64;

  assign s_axi_bid = {4'b0, s_axi_bid_64};
  assign s_axi_rid = {4'b0, s_axi_rid_64};
  assign s_axi_rdata = s_axi_rdata_64;

  uvhs_axi64_to_axi256 width_adapter (
    .clk(clk),
    .rstn(rstn),
    .s_axi_awid(s_axi_awid[13:0]),
    .s_axi_awaddr({7'b0, s_axi_awaddr}),
    .s_axi_awlen(s_axi_awlen),
    .s_axi_awsize(s_axi_awsize),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awlock(s_axi_awlock),
    .s_axi_awcache(s_axi_awcache),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awqos(s_axi_awqos),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata[63:0]),
    .s_axi_wstrb(s_axi_wstrb[7:0]),
    .s_axi_wlast(s_axi_wlast),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bid(s_axi_bid_64),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_arid(s_axi_arid[13:0]),
    .s_axi_araddr({7'b0, s_axi_araddr}),
    .s_axi_arlen(s_axi_arlen),
    .s_axi_arsize(s_axi_arsize),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arlock(s_axi_arlock),
    .s_axi_arcache(s_axi_arcache),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arqos(s_axi_arqos),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rid(s_axi_rid_64),
    .s_axi_rdata(s_axi_rdata_64),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rlast(s_axi_rlast),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .m_axi_awid(ddr_awid),
    .m_axi_awaddr(ddr_awaddr),
    .m_axi_awlen(ddr_awlen),
    .m_axi_awsize(ddr_awsize),
    .m_axi_awburst(ddr_awburst),
    .m_axi_awlock(ddr_awlock),
    .m_axi_awcache(ddr_awcache),
    .m_axi_awprot(ddr_awprot),
    .m_axi_awqos(ddr_awqos),
    .m_axi_awregion(ddr_awregion),
    .m_axi_awvalid(ddr_awvalid),
    .m_axi_awready(ddr_awready),
    .m_axi_wdata(ddr_wdata),
    .m_axi_wstrb(ddr_wstrb),
    .m_axi_wlast(ddr_wlast),
    .m_axi_wvalid(ddr_wvalid),
    .m_axi_wready(ddr_wready),
    .m_axi_bid(ddr_bid),
    .m_axi_bresp(ddr_bresp),
    .m_axi_bvalid(ddr_bvalid),
    .m_axi_bready(ddr_bready),
    .m_axi_arid(ddr_arid),
    .m_axi_araddr(ddr_araddr),
    .m_axi_arlen(ddr_arlen),
    .m_axi_arsize(ddr_arsize),
    .m_axi_arburst(ddr_arburst),
    .m_axi_arlock(ddr_arlock),
    .m_axi_arcache(ddr_arcache),
    .m_axi_arprot(ddr_arprot),
    .m_axi_arqos(ddr_arqos),
    .m_axi_arregion(ddr_arregion),
    .m_axi_arvalid(ddr_arvalid),
    .m_axi_arready(ddr_arready),
    .m_axi_rid(ddr_rid),
    .m_axi_rdata(ddr_rdata),
    .m_axi_rresp(ddr_rresp),
    .m_axi_rlast(ddr_rlast),
    .m_axi_rvalid(ddr_rvalid),
    .m_axi_rready(ddr_rready)
  );
`else
  assign ddr_awid = s_axi_awid[13:0];
  assign ddr_awaddr = s_axi_awaddr[33:0];
  assign ddr_awlen = s_axi_awlen;
  assign ddr_awsize = s_axi_awsize;
  assign ddr_awburst = s_axi_awburst;
  assign ddr_awlock = s_axi_awlock;
  assign ddr_awcache = s_axi_awcache;
  assign ddr_awprot = s_axi_awprot;
  assign ddr_awqos = s_axi_awqos;
  assign ddr_awregion = s_axi_awregion;
  assign ddr_awvalid = s_axi_awvalid;
  assign s_axi_awready = ddr_awready;
  assign ddr_wdata = s_axi_wdata;
  assign ddr_wstrb = s_axi_wstrb;
  assign ddr_wlast = s_axi_wlast;
  assign ddr_wvalid = s_axi_wvalid;
  assign s_axi_wready = ddr_wready;
  assign s_axi_bid = {4'b0, ddr_bid};
  assign s_axi_bresp = ddr_bresp;
  assign s_axi_bvalid = ddr_bvalid;
  assign ddr_bready = s_axi_bready;
  assign ddr_arid = s_axi_arid[13:0];
  assign ddr_araddr = s_axi_araddr[33:0];
  assign ddr_arlen = s_axi_arlen;
  assign ddr_arsize = s_axi_arsize;
  assign ddr_arburst = s_axi_arburst;
  assign ddr_arlock = s_axi_arlock;
  assign ddr_arcache = s_axi_arcache;
  assign ddr_arprot = s_axi_arprot;
  assign ddr_arqos = s_axi_arqos;
  assign ddr_arregion = s_axi_arregion;
  assign ddr_arvalid = s_axi_arvalid;
  assign s_axi_arready = ddr_arready;
  assign s_axi_rid = {4'b0, ddr_rid};
  assign s_axi_rdata = ddr_rdata;
  assign s_axi_rresp = ddr_rresp;
  assign s_axi_rlast = ddr_rlast;
  assign s_axi_rvalid = ddr_rvalid;
  assign ddr_rready = s_axi_rready;
`endif

  assign calib_complete = rstn & ~ddr_user_rst;

  uvw_axi4_to_ddr4 ddr4_ip (
    .ddr4ip_dut_axi_aclk(clk),
    .ddr4ip_dut_axi_aresetn(rstn),
    .ddr4ip_dut_axi_awaddr(ddr_awaddr),
    .ddr4ip_dut_axi_awburst(ddr_awburst),
    .ddr4ip_dut_axi_awcache(ddr_awcache),
    .ddr4ip_dut_axi_awid(ddr_awid),
    .ddr4ip_dut_axi_awlen(ddr_awlen),
    .ddr4ip_dut_axi_awlock(ddr_awlock),
    .ddr4ip_dut_axi_awprot(ddr_awprot),
    .ddr4ip_dut_axi_awqos(ddr_awqos),
    .ddr4ip_dut_axi_awready(ddr_awready),
    .ddr4ip_dut_axi_awregion(ddr_awregion),
    .ddr4ip_dut_axi_awsize(ddr_awsize),
    .ddr4ip_dut_axi_awvalid(ddr_awvalid),
    .ddr4ip_dut_axi_wdata(ddr_wdata),
    .ddr4ip_dut_axi_wlast(ddr_wlast),
    .ddr4ip_dut_axi_wready(ddr_wready),
    .ddr4ip_dut_axi_wstrb(ddr_wstrb),
    .ddr4ip_dut_axi_wvalid(ddr_wvalid),
    .ddr4ip_dut_axi_bid(ddr_bid),
    .ddr4ip_dut_axi_bready(ddr_bready),
    .ddr4ip_dut_axi_bresp(ddr_bresp),
    .ddr4ip_dut_axi_bvalid(ddr_bvalid),
    .ddr4ip_dut_axi_araddr(ddr_araddr),
    .ddr4ip_dut_axi_arburst(ddr_arburst),
    .ddr4ip_dut_axi_arcache(ddr_arcache),
    .ddr4ip_dut_axi_arid(ddr_arid),
    .ddr4ip_dut_axi_arlen(ddr_arlen),
    .ddr4ip_dut_axi_arlock(ddr_arlock),
    .ddr4ip_dut_axi_arprot(ddr_arprot),
    .ddr4ip_dut_axi_arqos(ddr_arqos),
    .ddr4ip_dut_axi_arready(ddr_arready),
    .ddr4ip_dut_axi_arregion(ddr_arregion),
    .ddr4ip_dut_axi_arsize(ddr_arsize),
    .ddr4ip_dut_axi_arvalid(ddr_arvalid),
    .ddr4ip_dut_axi_rdata(ddr_rdata),
    .ddr4ip_dut_axi_rid(ddr_rid),
    .ddr4ip_dut_axi_rlast(ddr_rlast),
    .ddr4ip_dut_axi_rready(ddr_rready),
    .ddr4ip_dut_axi_rresp(ddr_rresp),
    .ddr4ip_dut_axi_rvalid(ddr_rvalid),
    .ddr4ip_dut_axi_aclk_en(1'b1),
    .ddr4ip_ddr4_user_clk(),
    .ddr4ip_ddr4_user_rst(ddr_user_rst),
    .sysbus_ghbd_i(256'b0),
    .sysbus_ghbd_o(),
    .FP_CLK_200M_P(),
    .FP_CLK_200M_N(),
    .DDR4_DIMM_ACT_N(),
    .DDR4_DIMM_A(),
    .DDR4_DIMM_BA(),
    .DDR4_DIMM_BG(),
    .DDR4_DIMM_CK_N(),
    .DDR4_DIMM_CK_P(),
    .DDR4_DIMM_CKE(),
    .DDR4_DIMM_CS_N(),
    .DDR4_DIMM_ODT(),
    .DDR4_DIMM_RST_B(),
    .DDR4_DIMM_DM(),
    .DDR4_DIMM_DQ(),
    .DDR4_DIMM_DQS_N(),
    .DDR4_DIMM_DQS_P()
  );

endmodule
