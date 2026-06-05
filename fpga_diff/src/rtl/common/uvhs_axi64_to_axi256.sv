`timescale 1ns/1ps

module uvhs_axi64_to_axi256 (
  input  wire         clk,
  input  wire         rstn,

  input  wire [13:0]  s_axi_awid,
  input  wire [39:0]  s_axi_awaddr,
  input  wire [7:0]   s_axi_awlen,
  input  wire [2:0]   s_axi_awsize,
  input  wire [1:0]   s_axi_awburst,
  input  wire         s_axi_awlock,
  input  wire [3:0]   s_axi_awcache,
  input  wire [2:0]   s_axi_awprot,
  input  wire [3:0]   s_axi_awqos,
  input  wire         s_axi_awvalid,
  output wire         s_axi_awready,
  input  wire [63:0]  s_axi_wdata,
  input  wire [7:0]   s_axi_wstrb,
  input  wire         s_axi_wlast,
  input  wire         s_axi_wvalid,
  output wire         s_axi_wready,
  output wire [13:0]  s_axi_bid,
  output wire [1:0]   s_axi_bresp,
  output wire         s_axi_bvalid,
  input  wire         s_axi_bready,

  input  wire [13:0]  s_axi_arid,
  input  wire [39:0]  s_axi_araddr,
  input  wire [7:0]   s_axi_arlen,
  input  wire [2:0]   s_axi_arsize,
  input  wire [1:0]   s_axi_arburst,
  input  wire         s_axi_arlock,
  input  wire [3:0]   s_axi_arcache,
  input  wire [2:0]   s_axi_arprot,
  input  wire [3:0]   s_axi_arqos,
  input  wire         s_axi_arvalid,
  output wire         s_axi_arready,
  output wire [13:0]  s_axi_rid,
  output wire [63:0]  s_axi_rdata,
  output wire [1:0]   s_axi_rresp,
  output wire         s_axi_rlast,
  output wire         s_axi_rvalid,
  input  wire         s_axi_rready,

  output wire [13:0]  m_axi_awid,
  output wire [33:0]  m_axi_awaddr,
  output wire [7:0]   m_axi_awlen,
  output wire [2:0]   m_axi_awsize,
  output wire [1:0]   m_axi_awburst,
  output wire [0:0]   m_axi_awlock,
  output wire [3:0]   m_axi_awcache,
  output wire [2:0]   m_axi_awprot,
  output wire [3:0]   m_axi_awqos,
  output wire [3:0]   m_axi_awregion,
  output wire         m_axi_awvalid,
  input  wire         m_axi_awready,
  output wire [255:0] m_axi_wdata,
  output wire [31:0]  m_axi_wstrb,
  output wire         m_axi_wlast,
  output wire         m_axi_wvalid,
  input  wire         m_axi_wready,
  input  wire [13:0]  m_axi_bid,
  input  wire [1:0]   m_axi_bresp,
  input  wire         m_axi_bvalid,
  output wire         m_axi_bready,

  output wire [13:0]  m_axi_arid,
  output wire [33:0]  m_axi_araddr,
  output wire [7:0]   m_axi_arlen,
  output wire [2:0]   m_axi_arsize,
  output wire [1:0]   m_axi_arburst,
  output wire [0:0]   m_axi_arlock,
  output wire [3:0]   m_axi_arcache,
  output wire [2:0]   m_axi_arprot,
  output wire [3:0]   m_axi_arqos,
  output wire [3:0]   m_axi_arregion,
  output wire         m_axi_arvalid,
  input  wire         m_axi_arready,
  input  wire [13:0]  m_axi_rid,
  input  wire [255:0] m_axi_rdata,
  input  wire [1:0]   m_axi_rresp,
  input  wire         m_axi_rlast,
  input  wire         m_axi_rvalid,
  output wire         m_axi_rready
);

  reg       write_active;
  reg       write_resp_pending;
  reg [1:0] write_lane;
  reg [2:0] write_size;
  reg [1:0] write_burst;

  reg       read_active;
  reg [1:0] read_lane;
  reg [2:0] read_size;
  reg [1:0] read_burst;

  wire [4:0] write_shift = {write_lane, 3'b000};
  wire [4:0] read_shift  = {read_lane, 3'b000};

  assign m_axi_awid     = s_axi_awid;
  assign m_axi_awaddr   = s_axi_awaddr[33:0];
  assign m_axi_awlen    = s_axi_awlen;
  assign m_axi_awsize   = s_axi_awsize;
  assign m_axi_awburst  = s_axi_awburst;
  assign m_axi_awlock   = s_axi_awlock;
  assign m_axi_awcache  = s_axi_awcache;
  assign m_axi_awprot   = s_axi_awprot;
  assign m_axi_awqos    = s_axi_awqos;
  assign m_axi_awregion = 4'b0;
  assign m_axi_awvalid  = s_axi_awvalid & ~write_active & ~write_resp_pending;
  assign s_axi_awready  = m_axi_awready & ~write_active & ~write_resp_pending;

  assign m_axi_wdata  = {192'b0, s_axi_wdata} << (write_shift * 8);
  assign m_axi_wstrb  = {24'b0, s_axi_wstrb} << write_shift;
  assign m_axi_wlast  = s_axi_wlast;
  assign m_axi_wvalid = s_axi_wvalid & write_active;
  assign s_axi_wready = m_axi_wready & write_active;

  assign s_axi_bid    = m_axi_bid;
  assign s_axi_bresp  = m_axi_bresp;
  assign s_axi_bvalid = m_axi_bvalid;
  assign m_axi_bready = s_axi_bready;

  assign m_axi_arid     = s_axi_arid;
  assign m_axi_araddr   = s_axi_araddr[33:0];
  assign m_axi_arlen    = s_axi_arlen;
  assign m_axi_arsize   = s_axi_arsize;
  assign m_axi_arburst  = s_axi_arburst;
  assign m_axi_arlock   = s_axi_arlock;
  assign m_axi_arcache  = s_axi_arcache;
  assign m_axi_arprot   = s_axi_arprot;
  assign m_axi_arqos    = s_axi_arqos;
  assign m_axi_arregion = 4'b0;
  assign m_axi_arvalid  = s_axi_arvalid & ~read_active;
  assign s_axi_arready  = m_axi_arready & ~read_active;

  assign s_axi_rid     = m_axi_rid;
  assign s_axi_rdata   = m_axi_rdata >> (read_shift * 8);
  assign s_axi_rresp   = m_axi_rresp;
  assign s_axi_rlast   = m_axi_rlast;
  assign s_axi_rvalid  = m_axi_rvalid & read_active;
  assign m_axi_rready  = s_axi_rready & read_active;

  function automatic [1:0] next_lane(input [1:0] lane, input [2:0] size, input [1:0] burst);
    begin
      if (burst == 2'b01 && size >= 3'd3) begin
        next_lane = lane + (2'b01 << (size - 3'd3));
      end else begin
        next_lane = lane;
      end
    end
  endfunction

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      write_active       <= 1'b0;
      write_resp_pending <= 1'b0;
      write_lane         <= 2'b0;
      write_size         <= 3'b0;
      write_burst        <= 2'b0;
    end else begin
      if (s_axi_awvalid && s_axi_awready) begin
        write_active       <= 1'b1;
        write_resp_pending <= 1'b0;
        write_lane         <= s_axi_awaddr[4:3];
        write_size         <= s_axi_awsize;
        write_burst        <= s_axi_awburst;
      end else if (s_axi_wvalid && s_axi_wready) begin
        if (s_axi_wlast) begin
          write_active       <= 1'b0;
          write_resp_pending <= 1'b1;
        end else begin
          write_lane <= next_lane(write_lane, write_size, write_burst);
        end
      end

      if (s_axi_bvalid && s_axi_bready) begin
        write_resp_pending <= 1'b0;
      end
    end
  end

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      read_active <= 1'b0;
      read_lane   <= 2'b0;
      read_size   <= 3'b0;
      read_burst  <= 2'b0;
    end else begin
      if (s_axi_arvalid && s_axi_arready) begin
        read_active <= 1'b1;
        read_lane   <= s_axi_araddr[4:3];
        read_size   <= s_axi_arsize;
        read_burst  <= s_axi_arburst;
      end else if (s_axi_rvalid && s_axi_rready) begin
        if (s_axi_rlast) begin
          read_active <= 1'b0;
        end else begin
          read_lane <= next_lane(read_lane, read_size, read_burst);
        end
      end
    end
  end

endmodule
