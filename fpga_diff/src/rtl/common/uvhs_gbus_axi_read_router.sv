`timescale 1ns/1ps

// One-outstanding AXI3 read router. Requests in the local 4 KiB aperture are
// sent to c_ (the local SRAM endpoint); all other requests are sent to d_
// (the DDR adapter). Writes are outside this block.
module uvhs_gbus_axi_read_router (
  input  wire        clk,
  input  wire        rstn,

  input  wire [7:0]  s_arid,
  input  wire [31:0] s_araddr,
  input  wire [3:0]  s_arlen,
  input  wire [2:0]  s_arsize,
  input  wire [1:0]  s_arburst,
  input  wire [1:0]  s_arlock,
  input  wire [3:0]  s_arcache,
  input  wire [2:0]  s_arprot,
  input  wire [3:0]  s_arqos,
  input  wire        s_arvalid,
  output wire        s_arready,
  output wire [7:0]  s_rid,
  output wire [255:0] s_rdata,
  output wire [1:0]  s_rresp,
  output wire        s_rlast,
  output wire        s_rvalid,
  input  wire        s_rready,

  output wire [7:0]  d_arid,
  output wire [31:0] d_araddr,
  output wire [3:0]  d_arlen,
  output wire [2:0]  d_arsize,
  output wire [1:0]  d_arburst,
  output wire [1:0]  d_arlock,
  output wire [3:0]  d_arcache,
  output wire [2:0]  d_arprot,
  output wire [3:0]  d_arqos,
  output wire        d_arvalid,
  input  wire        d_arready,
  input  wire [7:0]  d_rid,
  input  wire [255:0] d_rdata,
  input  wire [1:0]  d_rresp,
  input  wire        d_rlast,
  input  wire        d_rvalid,
  output wire        d_rready,

  output wire [7:0]  c_arid,
  output wire [31:0] c_araddr,
  output wire [3:0]  c_arlen,
  output wire [2:0]  c_arsize,
  output wire [1:0]  c_arburst,
  output wire        c_arvalid,
  input  wire        c_arready,
  input  wire [7:0]  c_rid,
  input  wire [255:0] c_rdata,
  input  wire [1:0]  c_rresp,
  input  wire        c_rlast,
  input  wire        c_rvalid,
  output wire        c_rready
);
  reg busy;
  reg local_q;

  wire aperture_hit = (s_araddr >= 32'h1000_0000) &&
                       (s_araddr <= 32'h1000_0fff);
  wire ar_fire = s_arvalid && s_arready;

  assign s_arready = rstn && !busy && (aperture_hit ? c_arready : d_arready);

  assign d_arid    = s_arid;
  assign d_araddr  = s_araddr;
  assign d_arlen   = s_arlen;
  assign d_arsize  = s_arsize;
  assign d_arburst = s_arburst;
  assign d_arlock  = s_arlock;
  assign d_arcache = s_arcache;
  assign d_arprot  = s_arprot;
  assign d_arqos   = s_arqos;
  assign d_arvalid = rstn && !busy && s_arvalid && !aperture_hit;

  assign c_arid    = s_arid;
  assign c_araddr  = s_araddr;
  assign c_arlen   = s_arlen;
  assign c_arsize  = s_arsize;
  assign c_arburst = s_arburst;
  assign c_arvalid = rstn && !busy && s_arvalid && aperture_hit;

  assign s_rvalid = rstn && busy && (local_q ? c_rvalid : d_rvalid);
  assign s_rid    = local_q ? c_rid    : d_rid;
  assign s_rdata  = local_q ? c_rdata  : d_rdata;
  assign s_rresp  = local_q ? c_rresp  : d_rresp;
  assign s_rlast  = local_q ? c_rlast  : d_rlast;
  assign c_rready = rstn && busy && local_q && s_rready;
  assign d_rready = rstn && busy && !local_q && s_rready;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      busy   <= 1'b0;
      local_q <= 1'b0;
    end else begin
      if (ar_fire) begin
        busy    <= 1'b1;
        local_q <= aperture_hit;
      end
      if (busy && s_rvalid && s_rready && s_rlast)
        busy <= 1'b0;
    end
  end
endmodule
