`timescale 1ns/1ps

// The complete narrow burst is buffered before a DDR write address is issued.
// Session reset may abandon the producer, but cannot abandon a DDR transaction.
module uvhs_axi64_to_axi256 (
  input  wire         clk,
  input  wire         rstn,
  input  wire         session_resetn,

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
  localparam [3:0] IDLE = 4'd0, READ_ADDR = 4'd1, READ_FETCH = 4'd2,
      READ_OUT = 4'd3, WRITE_COLLECT = 4'd4, WRITE_ADDR = 4'd5,
      WRITE_DATA = 4'd6, WRITE_REPLY = 4'd7, WRITE_OUT = 4'd8;

  function automatic [40:0] span(input [7:0] len, input [2:0] size);
    span = ({33'b0, len} + 41'd1) << size;
  endfunction

  function automatic [40:0] window_start(
      input [39:0] address, input [7:0] len,
      input [2:0] size, input [1:0] burst);
    reg [40:0] first;
    begin
      first = {1'b0, address};
      if (burst == 2'b10)
        first = first & ~(span(len, size) - 41'd1);
      window_start = first & ~41'd31;
    end
  endfunction

  function automatic [40:0] window_last(
      input [39:0] address, input [7:0] len,
      input [2:0] size, input [1:0] burst);
    reg [40:0] first, bytes;
    begin
      first = {1'b0, address};
      bytes = span(len, size);
      if (burst == 2'b00)
        bytes = 41'd1 << size;
      if (burst == 2'b10)
        first = first & ~(bytes - 41'd1);
      window_last = first + bytes - 41'd1;
    end
  endfunction

  // Unaligned and exclusive transfers are not emitted by the NutShell DDR port.
  function automatic request_ok(
      input [39:0] address, input [7:0] len,
      input [2:0] size, input [1:0] burst, input lock);
    reg [40:0] last;
    begin
      last = window_last(address, len, size, burst);
      request_ok = size <= 3 && !lock && burst != 2'b11 &&
          (({1'b0, address} & ((41'd1 << size) - 41'd1)) == 0) &&
          address[39:34] == 0 && last < 41'h400000000 &&
          (last >> 12) == ({1'b0, address} >> 12) &&
          (burst != 2'b00 || len <= 15) &&
          (burst != 2'b10 || len == 1 || len == 3 || len == 7 || len == 15);
    end
  endfunction

  wire [40:0] aw_first = window_start(s_axi_awaddr, s_axi_awlen, s_axi_awsize, s_axi_awburst);
  wire [40:0] ar_first = window_start(s_axi_araddr, s_axi_arlen, s_axi_arsize, s_axi_arburst);
  wire [6:0] aw_lines = 7'(((window_last(s_axi_awaddr, s_axi_awlen, s_axi_awsize, s_axi_awburst) - aw_first) >> 5) + 41'd1);
  wire [6:0] ar_lines = 7'(((window_last(s_axi_araddr, s_axi_arlen, s_axi_arsize, s_axi_arburst) - ar_first) >> 5) + 41'd1);
  wire [33:0] aw_wrap_mask = 34'(span(s_axi_awlen, s_axi_awsize) - 41'd1);
  wire [33:0] ar_wrap_mask = 34'(span(s_axi_arlen, s_axi_arsize) - 41'd1);

  reg [3:0] state;
  reg cancelled, error;
  reg [13:0] id;
  reg [33:0] base_addr, beat_addr, stride, wrap_mask;
  reg [1:0] burst;
  reg [2:0] size;
  reg [3:0] cache, qos;
  reg [2:0] prot;
  reg [8:0] beats_left;
  reg [6:0] line_count, line_index;
  reg [1:0] bresp;
  reg [255:0] line_data [0:64];
  reg [31:0] line_strb [0:64];
  reg [1:0] line_resp [0:64];

  wire [6:0] beat_line = 7'((beat_addr - base_addr) >> 5);
  wire [33:0] increment_addr = beat_addr + stride;
  wire [33:0] next_addr = burst == 2'b00 ? beat_addr :
      burst == 2'b10 ? ((beat_addr & ~wrap_mask) | (increment_addr & wrap_mask)) : increment_addr;
  wire [7:0] legal_lanes = 8'(((16'd1 << (16'd1 << size)) - 16'd1) << beat_addr[2:0]);
  wire bad_w = s_axi_wlast != (beats_left == 9'd1) ||
      ((s_axi_wstrb & ~legal_lanes) != 0);
  wire response_enabled = rstn && session_resetn && !cancelled;
  assign s_axi_awready = response_enabled && state == IDLE;
  assign s_axi_arready = response_enabled && state == IDLE && !s_axi_awvalid;
  assign s_axi_wready = response_enabled && state == WRITE_COLLECT;
  assign s_axi_bid = id;
  assign s_axi_bresp = bresp;
  assign s_axi_bvalid = response_enabled && state == WRITE_OUT;
  assign s_axi_rid = id;
  assign s_axi_rdata = error ? 64'b0 : line_data[beat_line][{beat_addr[4:3], 6'b0} +: 64];
  assign s_axi_rresp = error ? 2'b10 : line_resp[beat_line];
  assign s_axi_rlast = beats_left == 9'd1;
  assign s_axi_rvalid = response_enabled && state == READ_OUT;

  assign m_axi_awid = id;
  assign m_axi_awaddr = base_addr;
  assign m_axi_awlen = {1'b0, line_count} - 8'd1;
  assign m_axi_awsize = 3'd5;
  assign m_axi_awburst = 2'b01;
  assign m_axi_awlock = 1'b0;
  assign m_axi_awcache = cache;
  assign m_axi_awprot = prot;
  assign m_axi_awqos = qos;
  assign m_axi_awregion = 4'b0;
  assign m_axi_awvalid = rstn && state == WRITE_ADDR;
  assign m_axi_wdata = line_data[line_index];
  assign m_axi_wstrb = line_strb[line_index];
  assign m_axi_wlast = line_index + 7'd1 == line_count;
  assign m_axi_wvalid = rstn && state == WRITE_DATA;
  assign m_axi_bready = rstn && state == WRITE_REPLY;
  assign m_axi_arid = id;
  assign m_axi_araddr = base_addr;
  assign m_axi_arlen = {1'b0, line_count} - 8'd1;
  assign m_axi_arsize = 3'd5;
  assign m_axi_arburst = 2'b01;
  assign m_axi_arlock = 1'b0;
  assign m_axi_arcache = cache;
  assign m_axi_arprot = prot;
  assign m_axi_arqos = qos;
  assign m_axi_arregion = 4'b0;
  assign m_axi_arvalid = rstn && state == READ_ADDR;
  assign m_axi_rready = rstn && state == READ_FETCH;

  integer row, lane;
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      state <= IDLE;
      cancelled <= 1'b0;
      error <= 1'b0;
      id <= 0;
      base_addr <= 0;
      beat_addr <= 0;
      stride <= 0;
      wrap_mask <= 0;
      burst <= 0;
      size <= 0;
      cache <= 0;
      prot <= 0;
      qos <= 0;
      beats_left <= 0;
      line_count <= 0;
      line_index <= 0;
      bresp <= 0;
    end else begin
      if (!session_resetn && state != IDLE)
        cancelled <= 1'b1;
      case (state)
        IDLE: begin
          cancelled <= 1'b0;
          line_index <= 0;
          if (s_axi_awvalid && s_axi_awready) begin
            id <= s_axi_awid;
            base_addr <= aw_first[33:0];
            beat_addr <= s_axi_awaddr[33:0];
            stride <= 34'd1 << s_axi_awsize;
            wrap_mask <= aw_wrap_mask[33:0];
            burst <= s_axi_awburst;
            size <= s_axi_awsize;
            cache <= s_axi_awcache;
            prot <= s_axi_awprot;
            qos <= s_axi_awqos;
            beats_left <= {1'b0, s_axi_awlen} + 9'd1;
            line_count <= aw_lines[6:0];
            error <= !request_ok(s_axi_awaddr, s_axi_awlen, s_axi_awsize, s_axi_awburst, s_axi_awlock);
            for (row = 0; row < 65; row = row + 1)
              line_strb[row] <= 0;
            state <= WRITE_COLLECT;
          end else if (s_axi_arvalid && s_axi_arready) begin
            id <= s_axi_arid;
            base_addr <= ar_first[33:0];
            beat_addr <= s_axi_araddr[33:0];
            stride <= 34'd1 << s_axi_arsize;
            wrap_mask <= ar_wrap_mask[33:0];
            burst <= s_axi_arburst;
            cache <= s_axi_arcache;
            prot <= s_axi_arprot;
            qos <= s_axi_arqos;
            beats_left <= {1'b0, s_axi_arlen} + 9'd1;
            line_count <= ar_lines[6:0];
            error <= !request_ok(s_axi_araddr, s_axi_arlen, s_axi_arsize, s_axi_arburst, s_axi_arlock);
            state <= request_ok(s_axi_araddr, s_axi_arlen, s_axi_arsize, s_axi_arburst, s_axi_arlock) ? READ_ADDR : READ_OUT;
          end
        end
        READ_ADDR: if (m_axi_arready) state <= READ_FETCH;
        READ_FETCH: if (m_axi_rvalid) begin
          line_data[line_index] <= m_axi_rdata;
          line_resp[line_index] <= m_axi_rresp;
          if (m_axi_rid != id || m_axi_rlast != (line_index + 7'd1 == line_count))
            error <= 1'b1;
          if (line_index + 7'd1 == line_count)
            state <= cancelled || !session_resetn ? IDLE : READ_OUT;
          else
            line_index <= line_index + 7'd1;
        end
        READ_OUT: begin
          if (cancelled || !session_resetn)
            state <= IDLE;
          else if (s_axi_rready) begin
            beats_left <= beats_left - 9'd1;
            beat_addr <= next_addr;
            if (beats_left == 9'd1)
              state <= IDLE;
          end
        end
        WRITE_COLLECT: begin
          if (cancelled || !session_resetn)
            state <= IDLE;
          else if (s_axi_wvalid) begin
            if (!error) begin
              for (lane = 0; lane < 8; lane = lane + 1) begin
                if (s_axi_wstrb[lane]) begin
                  line_data[beat_line][(int'(beat_addr[4:3]) * 8 + lane) * 8 +: 8] <= s_axi_wdata[lane*8 +: 8];
                  line_strb[beat_line][int'(beat_addr[4:3]) * 8 + lane] <= 1'b1;
                end
              end
            end
            error <= error || bad_w;
            beats_left <= beats_left - 9'd1;
            beat_addr <= next_addr;
            if (beats_left == 9'd1) begin
              bresp <= 2'b10;
              state <= error || bad_w ? WRITE_OUT : WRITE_ADDR;
            end
          end
        end
        WRITE_ADDR: if (m_axi_awready) state <= WRITE_DATA;
        WRITE_DATA: if (m_axi_wready) begin
          if (m_axi_wlast)
            state <= WRITE_REPLY;
          else
            line_index <= line_index + 7'd1;
        end
        WRITE_REPLY: if (m_axi_bvalid) begin
          bresp <= m_axi_bid != id ? 2'b10 : m_axi_bresp;
          state <= cancelled || !session_resetn ? IDLE : WRITE_OUT;
        end
        WRITE_OUT: if (cancelled || !session_resetn || s_axi_bready) state <= IDLE;
        default: state <= IDLE;
      endcase
    end
  end
endmodule
