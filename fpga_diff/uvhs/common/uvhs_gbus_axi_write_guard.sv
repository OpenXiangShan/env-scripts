`timescale 1ns/1ps

// One outstanding AXI3 write; the SRAM publication page is read-only.
module uvhs_gbus_axi_write_guard (
  input wire clk,
  input wire rstn,
  input wire [7:0] s_awid,
  input wire [31:0] s_awaddr,
  input wire [3:0] s_awlen,
  input wire [2:0] s_awsize,
  input wire [1:0] s_awburst,
  input wire [1:0] s_awlock,
  input wire [3:0] s_awcache,
  input wire [2:0] s_awprot,
  input wire [3:0] s_awqos,
  input wire s_awvalid,
  output wire s_awready,
  input wire [7:0] s_wid,
  input wire [255:0] s_wdata,
  input wire [31:0] s_wstrb,
  input wire s_wlast,
  input wire s_wvalid,
  output wire s_wready,
  output wire [7:0] s_bid,
  output wire [1:0] s_bresp,
  output wire s_bvalid,
  input wire s_bready,
  output wire [7:0] d_awid,
  output wire [31:0] d_awaddr,
  output wire [3:0] d_awlen,
  output wire [2:0] d_awsize,
  output wire [1:0] d_awburst,
  output wire [1:0] d_awlock,
  output wire [3:0] d_awcache,
  output wire [2:0] d_awprot,
  output wire [3:0] d_awqos,
  output wire d_awvalid,
  input wire d_awready,
  output wire [7:0] d_wid,
  output wire [255:0] d_wdata,
  output wire [31:0] d_wstrb,
  output wire d_wlast,
  output wire d_wvalid,
  input wire d_wready,
  input wire [7:0] d_bid,
  input wire [1:0] d_bresp,
  input wire d_bvalid,
  output wire d_bready
);
  localparam [32:0] APERTURE = 33'h0_0ffff000;
  localparam [32:0] PORT_END = 33'h0_10000000;

  reg active, reject_q, aw_sent, data_done, data_error;
  reg [7:0] id_q;
  reg [31:0] addr_q;
  reg [3:0] len_q, cache_q, qos_q;
  reg [2:0] size_q, prot_q;
  reg [1:0] burst_q, lock_q;
  reg [4:0] beats_left;

  wire [32:0] transfer_bytes = 33'd1 << s_awsize;
  wire [32:0] burst_bytes = ({29'b0, s_awlen} + 33'd1) << s_awsize;
  wire wrap = (s_awburst == 2'b10);
  wire [32:0] first_byte = wrap ? ({1'b0, s_awaddr} & ~(burst_bytes - 33'd1)) :
                                               {1'b0, s_awaddr};
  wire [32:0] last_byte_exclusive = first_byte +
      ((s_awburst == 2'b00) ? transfer_bytes : burst_bytes);
  wire wrap_length_ok = (s_awlen == 4'd1) || (s_awlen == 4'd3) ||
                        (s_awlen == 4'd7) || (s_awlen == 4'd15);
  wire write_legal = (s_awsize <= 3'd5) && (s_awburst != 2'b11) &&
      (!wrap || wrap_length_ok) &&
      (({1'b0, s_awaddr} & (transfer_bytes - 33'd1)) == 33'd0) &&
      (last_byte_exclusive <= APERTURE);
  wire aw_take = s_awvalid && s_awready;
  wire w_take = s_wvalid && s_wready;

  assign s_awready = rstn && !active;
  assign d_awvalid = rstn && active && !reject_q && !aw_sent;
  assign d_awid = id_q;
  assign d_awaddr = addr_q;
  assign d_awlen = len_q;
  assign d_awsize = size_q;
  assign d_awburst = burst_q;
  assign d_awlock = lock_q;
  assign d_awcache = cache_q;
  assign d_awprot = prot_q;
  assign d_awqos = qos_q;

  assign s_wready = rstn && active && !data_done &&
                    (reject_q || (aw_sent && d_wready));
  assign d_wvalid = rstn && active && !reject_q && aw_sent && !data_done && s_wvalid;
  assign d_wid = id_q;
  assign d_wdata = s_wdata;
  assign d_wstrb = s_wstrb;
  assign d_wlast = (beats_left == 5'd1);
  assign s_bid = id_q;
  assign s_bvalid = rstn && active && data_done && (reject_q || d_bvalid);
  assign s_bresp = (reject_q || data_error || (d_bid != id_q)) ? 2'b10 : d_bresp;
  assign d_bready = rstn && active && !reject_q && data_done && s_bready;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      active <= 1'b0;
      reject_q <= 1'b0;
      aw_sent <= 1'b0;
      data_done <= 1'b0;
      data_error <= 1'b0;
      id_q <= 0;
      addr_q <= 0;
      len_q <= 0;
      size_q <= 0;
      burst_q <= 0;
      lock_q <= 0;
      cache_q <= 0;
      prot_q <= 0;
      qos_q <= 0;
      beats_left <= 0;
    end else begin
      if (aw_take) begin
        active <= 1'b1;
        reject_q <= !write_legal || (first_byte >= PORT_END);
        aw_sent <= 1'b0;
        data_done <= 1'b0;
        data_error <= 1'b0;
        id_q <= s_awid;
        addr_q <= s_awaddr;
        len_q <= s_awlen;
        size_q <= s_awsize;
        burst_q <= s_awburst;
        lock_q <= s_awlock;
        cache_q <= s_awcache;
        prot_q <= s_awprot;
        qos_q <= s_awqos;
        beats_left <= {1'b0, s_awlen} + 5'd1;
      end
      if (d_awvalid && d_awready) aw_sent <= 1'b1;
      if (w_take) begin
        if ((s_wid != id_q) || (s_wlast != (beats_left == 5'd1)))
          data_error <= 1'b1;
        if (beats_left == 5'd1) data_done <= 1'b1;
        else beats_left <= beats_left - 1'b1;
      end
      if (s_bvalid && s_bready) active <= 1'b0;
    end
  end
endmodule
