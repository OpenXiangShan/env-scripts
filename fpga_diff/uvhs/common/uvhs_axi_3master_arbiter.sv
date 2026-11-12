`timescale 1ns/1ps

// Small AXI4 arbiter used only by the native UVHS GBus build.  The existing
// CPU path remains the only master in XDMA builds.  A write owner is held from
// AW through B and a read owner from AR through the final R beat, so an AXI
// burst can never be interleaved with another master.
module uvhs_axi_3master_arbiter #(
    parameter integer ADDR_WIDTH = 34,
    parameter integer ID_WIDTH = 14,
    parameter integer DATA_WIDTH = 256
) (
    input wire clk, input wire rstn,
    input wire [ID_WIDTH-1:0] s0_awid, input wire [ADDR_WIDTH-1:0] s0_awaddr,
    input wire [7:0] s0_awlen, input wire [2:0] s0_awsize, input wire [1:0] s0_awburst,
    input wire s0_awlock, input wire [3:0] s0_awcache, input wire [2:0] s0_awprot,
    input wire [3:0] s0_awqos, input wire [3:0] s0_awregion, input wire s0_awvalid,
    output wire s0_awready, input wire [DATA_WIDTH-1:0] s0_wdata,
    input wire [DATA_WIDTH/8-1:0] s0_wstrb, input wire s0_wlast, input wire s0_wvalid,
    output wire s0_wready, output wire [ID_WIDTH-1:0] s0_bid, output wire [1:0] s0_bresp,
    output wire s0_bvalid, input wire s0_bready, input wire [ID_WIDTH-1:0] s0_arid,
    input wire [ADDR_WIDTH-1:0] s0_araddr, input wire [7:0] s0_arlen,
    input wire [2:0] s0_arsize, input wire [1:0] s0_arburst, input wire s0_arlock,
    input wire [3:0] s0_arcache, input wire [2:0] s0_arprot, input wire [3:0] s0_arqos,
    input wire [3:0] s0_arregion, input wire s0_arvalid, output wire s0_arready,
    output wire [ID_WIDTH-1:0] s0_rid, output wire [DATA_WIDTH-1:0] s0_rdata,
    output wire [1:0] s0_rresp, output wire s0_rlast, output wire s0_rvalid, input wire s0_rready,

    input wire [ID_WIDTH-1:0] s1_awid, input wire [ADDR_WIDTH-1:0] s1_awaddr,
    input wire [7:0] s1_awlen, input wire [2:0] s1_awsize, input wire [1:0] s1_awburst,
    input wire s1_awlock, input wire [3:0] s1_awcache, input wire [2:0] s1_awprot,
    input wire [3:0] s1_awqos, input wire [3:0] s1_awregion, input wire s1_awvalid,
    output wire s1_awready, input wire [DATA_WIDTH-1:0] s1_wdata,
    input wire [DATA_WIDTH/8-1:0] s1_wstrb, input wire s1_wlast, input wire s1_wvalid,
    output wire s1_wready, output wire [ID_WIDTH-1:0] s1_bid, output wire [1:0] s1_bresp,
    output wire s1_bvalid, input wire s1_bready, input wire [ID_WIDTH-1:0] s1_arid,
    input wire [ADDR_WIDTH-1:0] s1_araddr, input wire [7:0] s1_arlen,
    input wire [2:0] s1_arsize, input wire [1:0] s1_arburst, input wire s1_arlock,
    input wire [3:0] s1_arcache, input wire [2:0] s1_arprot, input wire [3:0] s1_arqos,
    input wire [3:0] s1_arregion, input wire s1_arvalid, output wire s1_arready,
    output wire [ID_WIDTH-1:0] s1_rid, output wire [DATA_WIDTH-1:0] s1_rdata,
    output wire [1:0] s1_rresp, output wire s1_rlast, output wire s1_rvalid, input wire s1_rready,

    input wire [ID_WIDTH-1:0] s2_awid, input wire [ADDR_WIDTH-1:0] s2_awaddr,
    input wire [7:0] s2_awlen, input wire [2:0] s2_awsize, input wire [1:0] s2_awburst,
    input wire s2_awlock, input wire [3:0] s2_awcache, input wire [2:0] s2_awprot,
    input wire [3:0] s2_awqos, input wire [3:0] s2_awregion, input wire s2_awvalid,
    output wire s2_awready, input wire [DATA_WIDTH-1:0] s2_wdata,
    input wire [DATA_WIDTH/8-1:0] s2_wstrb, input wire s2_wlast, input wire s2_wvalid,
    output wire s2_wready, output wire [ID_WIDTH-1:0] s2_bid, output wire [1:0] s2_bresp,
    output wire s2_bvalid, input wire s2_bready, input wire [ID_WIDTH-1:0] s2_arid,
    input wire [ADDR_WIDTH-1:0] s2_araddr, input wire [7:0] s2_arlen,
    input wire [2:0] s2_arsize, input wire [1:0] s2_arburst, input wire s2_arlock,
    input wire [3:0] s2_arcache, input wire [2:0] s2_arprot, input wire [3:0] s2_arqos,
    input wire [3:0] s2_arregion, input wire s2_arvalid, output wire s2_arready,
    output wire [ID_WIDTH-1:0] s2_rid, output wire [DATA_WIDTH-1:0] s2_rdata,
    output wire [1:0] s2_rresp, output wire s2_rlast, output wire s2_rvalid, input wire s2_rready,

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
  reg wr_busy, rd_busy;
  reg wr_select_pending, rd_select_pending;
  reg [1:0] wr_owner, rd_owner;
  reg [1:0] wr_select_owner, rd_select_owner;
  wire [2:0] aw_valids = {s2_awvalid, s1_awvalid, s0_awvalid};
  wire [2:0] ar_valids = {s2_arvalid, s1_arvalid, s0_arvalid};
  wire [1:0] aw_sel = s2_awvalid ? 2'd2 : (s1_awvalid ? 2'd1 : 2'd0);
  wire [1:0] ar_sel = s2_arvalid ? 2'd2 : (s1_arvalid ? 2'd1 : 2'd0);
  wire aw_fire = m_awvalid && m_awready;
  wire b_fire = m_bvalid && m_bready;
  wire ar_fire = m_arvalid && m_arready;
  wire r_fire = m_rvalid && m_rready;
  wire [1:0] aw_mux_sel = wr_busy ? wr_owner : (wr_select_pending ? wr_select_owner : aw_sel);
  wire [1:0] ar_mux_sel = rd_busy ? rd_owner : (rd_select_pending ? rd_select_owner : ar_sel);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      wr_busy <= 1'b0; rd_busy <= 1'b0;
      wr_select_pending <= 1'b0; rd_select_pending <= 1'b0;
      wr_owner <= 0; rd_owner <= 0;
      wr_select_owner <= 0; rd_select_owner <= 0;
    end
    else begin
      if (!wr_busy && !wr_select_pending && m_awvalid && !m_awready) begin
        wr_select_pending <= 1'b1;
        wr_select_owner <= aw_sel;
      end
      if (!wr_busy && aw_fire) begin
        wr_busy <= 1'b1;
        wr_owner <= aw_mux_sel;
        wr_select_pending <= 1'b0;
      end
      else if (wr_busy && b_fire) wr_busy <= 1'b0;
      if (!rd_busy && !rd_select_pending && m_arvalid && !m_arready) begin
        rd_select_pending <= 1'b1;
        rd_select_owner <= ar_sel;
      end
      if (!rd_busy && ar_fire) begin
        rd_busy <= 1'b1;
        rd_owner <= ar_mux_sel;
        rd_select_pending <= 1'b0;
      end
      else if (rd_busy && r_fire && m_rlast) rd_busy <= 1'b0;
    end
  end

  assign m_awvalid = !wr_busy && (|aw_valids);
  assign m_awid = aw_mux_sel == 2 ? s2_awid : (aw_mux_sel == 1 ? s1_awid : s0_awid);
  assign m_awaddr = aw_mux_sel == 2 ? s2_awaddr : (aw_mux_sel == 1 ? s1_awaddr : s0_awaddr);
  assign m_awlen = aw_mux_sel == 2 ? s2_awlen : (aw_mux_sel == 1 ? s1_awlen : s0_awlen);
  assign m_awsize = aw_mux_sel == 2 ? s2_awsize : (aw_mux_sel == 1 ? s1_awsize : s0_awsize);
  assign m_awburst = aw_mux_sel == 2 ? s2_awburst : (aw_mux_sel == 1 ? s1_awburst : s0_awburst);
  assign m_awlock = aw_mux_sel == 2 ? s2_awlock : (aw_mux_sel == 1 ? s1_awlock : s0_awlock);
  assign m_awcache = aw_mux_sel == 2 ? s2_awcache : (aw_mux_sel == 1 ? s1_awcache : s0_awcache);
  assign m_awprot = aw_mux_sel == 2 ? s2_awprot : (aw_mux_sel == 1 ? s1_awprot : s0_awprot);
  assign m_awqos = aw_mux_sel == 2 ? s2_awqos : (aw_mux_sel == 1 ? s1_awqos : s0_awqos);
  assign m_awregion = aw_mux_sel == 2 ? s2_awregion : (aw_mux_sel == 1 ? s1_awregion : s0_awregion);
  assign s0_awready = !wr_busy && aw_mux_sel == 0 && m_awready;
  assign s1_awready = !wr_busy && aw_mux_sel == 1 && m_awready;
  assign s2_awready = !wr_busy && aw_mux_sel == 2 && m_awready;

  assign m_wvalid = wr_busy && (wr_owner == 2 ? s2_wvalid : (wr_owner == 1 ? s1_wvalid : s0_wvalid));
  assign m_wdata = wr_owner == 2 ? s2_wdata : (wr_owner == 1 ? s1_wdata : s0_wdata);
  assign m_wstrb = wr_owner == 2 ? s2_wstrb : (wr_owner == 1 ? s1_wstrb : s0_wstrb);
  assign m_wlast = wr_owner == 2 ? s2_wlast : (wr_owner == 1 ? s1_wlast : s0_wlast);
  assign s0_wready = wr_busy && wr_owner == 0 && m_wready;
  assign s1_wready = wr_busy && wr_owner == 1 && m_wready;
  assign s2_wready = wr_busy && wr_owner == 2 && m_wready;
  assign m_bready = wr_busy && (wr_owner == 2 ? s2_bready : (wr_owner == 1 ? s1_bready : s0_bready));
  assign s0_bvalid = wr_busy && wr_owner == 0 && m_bvalid; assign s1_bvalid = wr_busy && wr_owner == 1 && m_bvalid; assign s2_bvalid = wr_busy && wr_owner == 2 && m_bvalid;
  assign s0_bid = m_bid; assign s1_bid = m_bid; assign s2_bid = m_bid;
  assign s0_bresp = m_bresp; assign s1_bresp = m_bresp; assign s2_bresp = m_bresp;

  assign m_arvalid = !rd_busy && (|ar_valids);
  assign m_arid = ar_mux_sel == 2 ? s2_arid : (ar_mux_sel == 1 ? s1_arid : s0_arid);
  assign m_araddr = ar_mux_sel == 2 ? s2_araddr : (ar_mux_sel == 1 ? s1_araddr : s0_araddr);
  assign m_arlen = ar_mux_sel == 2 ? s2_arlen : (ar_mux_sel == 1 ? s1_arlen : s0_arlen);
  assign m_arsize = ar_mux_sel == 2 ? s2_arsize : (ar_mux_sel == 1 ? s1_arsize : s0_arsize);
  assign m_arburst = ar_mux_sel == 2 ? s2_arburst : (ar_mux_sel == 1 ? s1_arburst : s0_arburst);
  assign m_arlock = ar_mux_sel == 2 ? s2_arlock : (ar_mux_sel == 1 ? s1_arlock : s0_arlock);
  assign m_arcache = ar_mux_sel == 2 ? s2_arcache : (ar_mux_sel == 1 ? s1_arcache : s0_arcache);
  assign m_arprot = ar_mux_sel == 2 ? s2_arprot : (ar_mux_sel == 1 ? s1_arprot : s0_arprot);
  assign m_arqos = ar_mux_sel == 2 ? s2_arqos : (ar_mux_sel == 1 ? s1_arqos : s0_arqos);
  assign m_arregion = ar_mux_sel == 2 ? s2_arregion : (ar_mux_sel == 1 ? s1_arregion : s0_arregion);
  assign s0_arready = !rd_busy && ar_mux_sel == 0 && m_arready; assign s1_arready = !rd_busy && ar_mux_sel == 1 && m_arready; assign s2_arready = !rd_busy && ar_mux_sel == 2 && m_arready;
  assign m_rready = rd_busy && (rd_owner == 2 ? s2_rready : (rd_owner == 1 ? s1_rready : s0_rready));
  assign s0_rvalid = rd_busy && rd_owner == 0 && m_rvalid; assign s1_rvalid = rd_busy && rd_owner == 1 && m_rvalid; assign s2_rvalid = rd_busy && rd_owner == 2 && m_rvalid;
  assign s0_rid = m_rid; assign s1_rid = m_rid; assign s2_rid = m_rid;
  assign s0_rdata = m_rdata; assign s1_rdata = m_rdata; assign s2_rdata = m_rdata;
  assign s0_rresp = m_rresp; assign s1_rresp = m_rresp; assign s2_rresp = m_rresp;
  assign s0_rlast = m_rlast; assign s1_rlast = m_rlast; assign s2_rlast = m_rlast;
endmodule
