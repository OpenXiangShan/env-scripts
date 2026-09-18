`timescale 1ns/1ps

// Full AXI4 clock-domain bridge for the GBus build.  Each AXI channel crosses
// through an independent ready/valid FIFO; ordering within every channel is
// preserved and backpressure may stop either clock without losing a transfer.
module uvhs_axi_async_bridge #(
    parameter integer ADDR_WIDTH = 34,
    parameter integer ID_WIDTH = 14,
    parameter integer DATA_WIDTH = 256,
    parameter integer FIFO_ADDR_WIDTH = 3
) (
    input wire s_clk, input wire s_rstn,
    input wire [ID_WIDTH-1:0] s_awid, input wire [ADDR_WIDTH-1:0] s_awaddr,
    input wire [7:0] s_awlen, input wire [2:0] s_awsize, input wire [1:0] s_awburst,
    input wire s_awlock, input wire [3:0] s_awcache, input wire [2:0] s_awprot,
    input wire [3:0] s_awqos, input wire [3:0] s_awregion, input wire s_awvalid,
    output wire s_awready, input wire [DATA_WIDTH-1:0] s_wdata,
    input wire [DATA_WIDTH/8-1:0] s_wstrb, input wire s_wlast, input wire s_wvalid,
    output wire s_wready, output wire [ID_WIDTH-1:0] s_bid, output wire [1:0] s_bresp,
    output wire s_bvalid, input wire s_bready, input wire [ID_WIDTH-1:0] s_arid,
    input wire [ADDR_WIDTH-1:0] s_araddr, input wire [7:0] s_arlen,
    input wire [2:0] s_arsize, input wire [1:0] s_arburst, input wire s_arlock,
    input wire [3:0] s_arcache, input wire [2:0] s_arprot, input wire [3:0] s_arqos,
    input wire [3:0] s_arregion, input wire s_arvalid, output wire s_arready,
    output wire [ID_WIDTH-1:0] s_rid, output wire [DATA_WIDTH-1:0] s_rdata,
    output wire [1:0] s_rresp, output wire s_rlast, output wire s_rvalid, input wire s_rready,

    input wire m_clk, input wire m_rstn,
    output wire [ID_WIDTH-1:0] m_awid, output wire [ADDR_WIDTH-1:0] m_awaddr,
    output wire [7:0] m_awlen, output wire [2:0] m_awsize, output wire [1:0] m_awburst,
    output wire m_awlock, output wire [3:0] m_awcache, output wire [2:0] m_awprot,
    output wire [3:0] m_awqos, output wire [3:0] m_awregion, output wire m_awvalid,
    input wire m_awready, output wire [DATA_WIDTH-1:0] m_wdata,
    output wire [DATA_WIDTH/8-1:0] m_wstrb, output wire m_wlast, output wire m_wvalid,
    input wire m_wready, input wire [ID_WIDTH-1:0] m_bid, input wire [1:0] m_bresp,
    input wire m_bvalid, output wire m_bready, output wire [ID_WIDTH-1:0] m_arid,
    output wire [ADDR_WIDTH-1:0] m_araddr, output wire [7:0] m_arlen,
    output wire [2:0] m_arsize, output wire [1:0] m_arburst, output wire m_arlock,
    output wire [3:0] m_arcache, output wire [2:0] m_arprot, output wire [3:0] m_arqos,
    output wire [3:0] m_arregion, output wire m_arvalid, input wire m_arready,
    input wire [ID_WIDTH-1:0] m_rid, input wire [DATA_WIDTH-1:0] m_rdata,
    input wire [1:0] m_rresp, input wire m_rlast, input wire m_rvalid, output wire m_rready
);
  localparam integer STRB_WIDTH = DATA_WIDTH / 8;
  localparam integer AW_WIDTH = ID_WIDTH + ADDR_WIDTH + 8 + 3 + 2 + 1 + 4 + 3 + 4 + 4;
  localparam integer W_WIDTH = DATA_WIDTH + STRB_WIDTH + 1;
  localparam integer B_WIDTH = ID_WIDTH + 2;
  localparam integer AR_WIDTH = AW_WIDTH;
  localparam integer R_WIDTH = ID_WIDTH + DATA_WIDTH + 2 + 1;

  wire [AW_WIDTH-1:0] s_aw_payload = {s_awid, s_awaddr, s_awlen, s_awsize,
      s_awburst, s_awlock, s_awcache, s_awprot, s_awqos, s_awregion};
  wire [AW_WIDTH-1:0] m_aw_payload;
  assign {m_awid, m_awaddr, m_awlen, m_awsize, m_awburst, m_awlock,
      m_awcache, m_awprot, m_awqos, m_awregion} = m_aw_payload;
  uvhs_async_fifo #(.WIDTH(AW_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) aw_fifo (
      .s_clk(s_clk), .s_rstn(s_rstn), .s_data(s_aw_payload), .s_valid(s_awvalid),
      .s_ready(s_awready), .m_clk(m_clk), .m_rstn(m_rstn), .m_data(m_aw_payload),
      .m_valid(m_awvalid), .m_ready(m_awready));

  wire [W_WIDTH-1:0] s_w_payload = {s_wdata, s_wstrb, s_wlast};
  wire [W_WIDTH-1:0] m_w_payload;
  assign {m_wdata, m_wstrb, m_wlast} = m_w_payload;
  uvhs_async_fifo #(.WIDTH(W_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) w_fifo (
      .s_clk(s_clk), .s_rstn(s_rstn), .s_data(s_w_payload), .s_valid(s_wvalid),
      .s_ready(s_wready), .m_clk(m_clk), .m_rstn(m_rstn), .m_data(m_w_payload),
      .m_valid(m_wvalid), .m_ready(m_wready));

  wire [B_WIDTH-1:0] m_b_payload = {m_bid, m_bresp};
  wire [B_WIDTH-1:0] s_b_payload;
  assign {s_bid, s_bresp} = s_b_payload;
  uvhs_async_fifo #(.WIDTH(B_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) b_fifo (
      .s_clk(m_clk), .s_rstn(m_rstn), .s_data(m_b_payload), .s_valid(m_bvalid),
      .s_ready(m_bready), .m_clk(s_clk), .m_rstn(s_rstn), .m_data(s_b_payload),
      .m_valid(s_bvalid), .m_ready(s_bready));

  wire [AR_WIDTH-1:0] s_ar_payload = {s_arid, s_araddr, s_arlen, s_arsize,
      s_arburst, s_arlock, s_arcache, s_arprot, s_arqos, s_arregion};
  wire [AR_WIDTH-1:0] m_ar_payload;
  assign {m_arid, m_araddr, m_arlen, m_arsize, m_arburst, m_arlock,
      m_arcache, m_arprot, m_arqos, m_arregion} = m_ar_payload;
  uvhs_async_fifo #(.WIDTH(AR_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) ar_fifo (
      .s_clk(s_clk), .s_rstn(s_rstn), .s_data(s_ar_payload), .s_valid(s_arvalid),
      .s_ready(s_arready), .m_clk(m_clk), .m_rstn(m_rstn), .m_data(m_ar_payload),
      .m_valid(m_arvalid), .m_ready(m_arready));

  wire [R_WIDTH-1:0] m_r_payload = {m_rid, m_rdata, m_rresp, m_rlast};
  wire [R_WIDTH-1:0] s_r_payload;
  assign {s_rid, s_rdata, s_rresp, s_rlast} = s_r_payload;
  uvhs_async_fifo #(.WIDTH(R_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) r_fifo (
      .s_clk(m_clk), .s_rstn(m_rstn), .s_data(m_r_payload), .s_valid(m_rvalid),
      .s_ready(m_rready), .m_clk(s_clk), .m_rstn(s_rstn), .m_data(s_r_payload),
      .m_valid(s_rvalid), .m_ready(s_rready));
endmodule
