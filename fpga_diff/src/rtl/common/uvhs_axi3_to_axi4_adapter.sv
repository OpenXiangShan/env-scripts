`timescale 1ns/1ps

// Width/protocol shim for the U2.2 uvw_general_bus AXI3 user port and the
// existing UVHS DDR AXI4 blackbox.  The general-bus IP emits at most 16-beat
// AXI3 bursts; AXI4 accepts the same burst semantics with widened metadata.
module uvhs_axi3_to_axi4_adapter #(
    parameter integer ADDR_WIDTH = 34,
    parameter integer ID_WIDTH = 14,
    parameter integer AXI3_ID_WIDTH = 8,
    parameter integer DATA_WIDTH = 256
) (
    input wire clk,
    input wire rstn,
    input wire [AXI3_ID_WIDTH-1:0] s_awid,
    input wire [ADDR_WIDTH-1:0] s_awaddr,
    input wire [3:0] s_awlen,
    input wire [2:0] s_awsize,
    input wire [1:0] s_awburst,
    input wire [1:0] s_awlock,
    input wire [3:0] s_awcache,
    input wire [2:0] s_awprot,
    input wire [3:0] s_awqos,
    input wire s_awvalid,
    output wire s_awready,
    input wire [AXI3_ID_WIDTH-1:0] s_wid,
    input wire [DATA_WIDTH-1:0] s_wdata,
    input wire [DATA_WIDTH/8-1:0] s_wstrb,
    input wire s_wlast,
    input wire s_wvalid,
    output wire s_wready,
    output wire [AXI3_ID_WIDTH-1:0] s_bid,
    output wire [1:0] s_bresp,
    output wire s_bvalid,
    input wire s_bready,
    input wire [AXI3_ID_WIDTH-1:0] s_arid,
    input wire [ADDR_WIDTH-1:0] s_araddr,
    input wire [3:0] s_arlen,
    input wire [2:0] s_arsize,
    input wire [1:0] s_arburst,
    input wire [1:0] s_arlock,
    input wire [3:0] s_arcache,
    input wire [2:0] s_arprot,
    input wire [3:0] s_arqos,
    input wire s_arvalid,
    output wire s_arready,
    output wire [AXI3_ID_WIDTH-1:0] s_rid,
    output wire [DATA_WIDTH-1:0] s_rdata,
    output wire [1:0] s_rresp,
    output wire s_rlast,
    output wire s_rvalid,
    input wire s_rready,
    output wire [ID_WIDTH-1:0] m_awid,
    output wire [ADDR_WIDTH-1:0] m_awaddr,
    output wire [7:0] m_awlen,
    output wire [2:0] m_awsize,
    output wire [1:0] m_awburst,
    output wire m_awlock,
    output wire [3:0] m_awcache,
    output wire [2:0] m_awprot,
    output wire [3:0] m_awqos,
    output wire [3:0] m_awregion,
    output wire m_awvalid,
    input wire m_awready,
    output wire [DATA_WIDTH-1:0] m_wdata,
    output wire [DATA_WIDTH/8-1:0] m_wstrb,
    output wire m_wlast,
    output wire m_wvalid,
    input wire m_wready,
    input wire [ID_WIDTH-1:0] m_bid,
    input wire [1:0] m_bresp,
    input wire m_bvalid,
    output wire m_bready,
    output wire [ID_WIDTH-1:0] m_arid,
    output wire [ADDR_WIDTH-1:0] m_araddr,
    output wire [7:0] m_arlen,
    output wire [2:0] m_arsize,
    output wire [1:0] m_arburst,
    output wire m_arlock,
    output wire [3:0] m_arcache,
    output wire [2:0] m_arprot,
    output wire [3:0] m_arqos,
    output wire [3:0] m_arregion,
    output wire m_arvalid,
    input wire m_arready,
    input wire [ID_WIDTH-1:0] m_rid,
    input wire [DATA_WIDTH-1:0] m_rdata,
    input wire [1:0] m_rresp,
    input wire m_rlast,
    input wire m_rvalid,
    output wire m_rready
);
    assign m_awid = {{(ID_WIDTH-AXI3_ID_WIDTH){1'b0}}, s_awid};
    assign m_awaddr = s_awaddr;
    assign m_awlen = {4'b0, s_awlen};
    assign m_awsize = s_awsize;
    assign m_awburst = s_awburst;
    assign m_awlock = s_awlock[0];
    assign m_awcache = s_awcache;
    assign m_awprot = s_awprot;
    assign m_awqos = s_awqos;
    assign m_awregion = 4'b0;
    assign m_awvalid = s_awvalid;
    assign s_awready = m_awready;

    assign m_wdata = s_wdata;
    assign m_wstrb = s_wstrb;
    assign m_wlast = s_wlast;
    assign m_wvalid = s_wvalid;
    assign s_wready = m_wready;
    assign s_bid = m_bid[AXI3_ID_WIDTH-1:0];
    assign s_bresp = m_bresp;
    assign s_bvalid = m_bvalid;
    assign m_bready = s_bready;

    assign m_arid = {{(ID_WIDTH-AXI3_ID_WIDTH){1'b0}}, s_arid};
    assign m_araddr = s_araddr;
    assign m_arlen = {4'b0, s_arlen};
    assign m_arsize = s_arsize;
    assign m_arburst = s_arburst;
    assign m_arlock = s_arlock[0];
    assign m_arcache = s_arcache;
    assign m_arprot = s_arprot;
    assign m_arqos = s_arqos;
    assign m_arregion = 4'b0;
    assign m_arvalid = s_arvalid;
    assign s_arready = m_arready;
    assign s_rid = m_rid[AXI3_ID_WIDTH-1:0];
    assign s_rdata = m_rdata;
    assign s_rresp = m_rresp;
    assign s_rlast = m_rlast;
    assign s_rvalid = m_rvalid;
    assign m_rready = s_rready;

    wire _unused = &{1'b0, clk, rstn, s_wid};
endmodule
