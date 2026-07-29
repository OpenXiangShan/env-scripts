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

  wire [33:0] ddr_awaddr;
  wire [33:0] ddr_araddr;
  wire [13:0] ddr_bid;
  wire [13:0] ddr_rid;
  wire        ddr_user_rst;

`ifdef CPU_NUTSHELL
  assign ddr_awaddr = {1'b0, s_axi_awaddr};
  assign ddr_araddr = {1'b0, s_axi_araddr};
`else
  assign ddr_awaddr = s_axi_awaddr[33:0];
  assign ddr_araddr = s_axi_araddr[33:0];
`endif

  assign s_axi_bid = {4'b0, ddr_bid};
  assign s_axi_rid = {4'b0, ddr_rid};
  assign calib_complete = rstn & ~ddr_user_rst;

  // The selected vendor DCP must match the source AXI data width: NutShell
  // uses a native 64-bit DCP while the XiangShan path uses a 256-bit DCP.
  uvw_axi4_to_ddr4 ddr4_ip (
    .ddr4ip_dut_axi_aclk(clk),
    .ddr4ip_dut_axi_aresetn(rstn),
    .ddr4ip_dut_axi_awaddr(ddr_awaddr),
    .ddr4ip_dut_axi_awburst(s_axi_awburst),
    .ddr4ip_dut_axi_awcache(s_axi_awcache),
    .ddr4ip_dut_axi_awid(s_axi_awid[13:0]),
    .ddr4ip_dut_axi_awlen(s_axi_awlen),
    .ddr4ip_dut_axi_awlock(s_axi_awlock),
    .ddr4ip_dut_axi_awprot(s_axi_awprot),
    .ddr4ip_dut_axi_awqos(s_axi_awqos),
    .ddr4ip_dut_axi_awready(s_axi_awready),
    .ddr4ip_dut_axi_awregion(s_axi_awregion),
    .ddr4ip_dut_axi_awsize(s_axi_awsize),
    .ddr4ip_dut_axi_awvalid(s_axi_awvalid),
    .ddr4ip_dut_axi_wdata(s_axi_wdata),
    .ddr4ip_dut_axi_wlast(s_axi_wlast),
    .ddr4ip_dut_axi_wready(s_axi_wready),
    .ddr4ip_dut_axi_wstrb(s_axi_wstrb),
    .ddr4ip_dut_axi_wvalid(s_axi_wvalid),
    .ddr4ip_dut_axi_bid(ddr_bid),
    .ddr4ip_dut_axi_bready(s_axi_bready),
    .ddr4ip_dut_axi_bresp(s_axi_bresp),
    .ddr4ip_dut_axi_bvalid(s_axi_bvalid),
    .ddr4ip_dut_axi_araddr(ddr_araddr),
    .ddr4ip_dut_axi_arburst(s_axi_arburst),
    .ddr4ip_dut_axi_arcache(s_axi_arcache),
    .ddr4ip_dut_axi_arid(s_axi_arid[13:0]),
    .ddr4ip_dut_axi_arlen(s_axi_arlen),
    .ddr4ip_dut_axi_arlock(s_axi_arlock),
    .ddr4ip_dut_axi_arprot(s_axi_arprot),
    .ddr4ip_dut_axi_arqos(s_axi_arqos),
    .ddr4ip_dut_axi_arready(s_axi_arready),
    .ddr4ip_dut_axi_arregion(s_axi_arregion),
    .ddr4ip_dut_axi_arsize(s_axi_arsize),
    .ddr4ip_dut_axi_arvalid(s_axi_arvalid),
    .ddr4ip_dut_axi_rdata(s_axi_rdata),
    .ddr4ip_dut_axi_rid(ddr_rid),
    .ddr4ip_dut_axi_rlast(s_axi_rlast),
    .ddr4ip_dut_axi_rready(s_axi_rready),
    .ddr4ip_dut_axi_rresp(s_axi_rresp),
    .ddr4ip_dut_axi_rvalid(s_axi_rvalid),
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
