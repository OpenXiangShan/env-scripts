`timescale 1ns/1ps

// Adapted from the generated Difftest2AXIs module.
// Converts an arbitrary-width input record into contiguous AXI4 write bursts.
module Difftest2AXI4 #(
  parameter integer INPUT_WIDTH = 16000,
  parameter integer AXI_DATA_WIDTH = 512,
  parameter integer AXI_ADDR_WIDTH = 64,
  parameter integer AXI_ID_WIDTH = 4,
  parameter [AXI_ADDR_WIDTH-1:0] BASE_ADDR = {AXI_ADDR_WIDTH{1'b0}},
  parameter integer FIFO_DEPTH = 128,
  parameter integer MAX_BURST_LEN = 256
) (
  input  wire                         in_clk,
  input  wire                         in_ctrl_clk,
  input  wire                         in_resetn,
  input  wire [INPUT_WIDTH-1:0]       in_data,
  input  wire                         in_valid,
  output wire                         in_ready,

  input  wire                         axi_clk,
  input  wire                         axi_resetn,
  output wire [AXI_ID_WIDTH-1:0]      m_axi_awid,
  output wire [AXI_ADDR_WIDTH-1:0]    m_axi_awaddr,
  output wire [7:0]                   m_axi_awlen,
  output wire [2:0]                   m_axi_awsize,
  output wire [1:0]                   m_axi_awburst,
  output wire                         m_axi_awlock,
  output wire [3:0]                   m_axi_awcache,
  output wire [2:0]                   m_axi_awprot,
  output wire [3:0]                   m_axi_awqos,
  output wire                         m_axi_awvalid,
  input  wire                         m_axi_awready,
  output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
  output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_wstrb,
  output wire                         m_axi_wlast,
  output wire                         m_axi_wvalid,
  input  wire                         m_axi_wready,
  input  wire [AXI_ID_WIDTH-1:0]      m_axi_bid,
  input  wire [1:0]                   m_axi_bresp,
  input  wire                         m_axi_bvalid,
  output wire                         m_axi_bready
);

  localparam integer AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;
  localparam integer AXI_SIZE = $clog2(AXI_STRB_WIDTH);
  localparam integer TOTAL_BEATS =
    (INPUT_WIDTH + AXI_DATA_WIDTH - 1) / AXI_DATA_WIDTH;
  localparam integer PADDED_WIDTH = TOTAL_BEATS * AXI_DATA_WIDTH;
  localparam integer BEAT_COUNT_WIDTH =
    (TOTAL_BEATS <= 1) ? 1 : $clog2(TOTAL_BEATS + 1);
  localparam integer BEAT_INDEX_WIDTH =
    (TOTAL_BEATS <= 1) ? 1 : $clog2(TOTAL_BEATS);
  localparam integer LAST_VALID_BITS =
    INPUT_WIDTH - (TOTAL_BEATS - 1) * AXI_DATA_WIDTH;
  localparam integer LAST_VALID_BYTES =
    (LAST_VALID_BITS + 7) / 8;
  localparam [AXI_STRB_WIDTH-1:0] LAST_WSTRB =
    {AXI_STRB_WIDTH{1'b1}} >> (AXI_STRB_WIDTH - LAST_VALID_BYTES);

  localparam [2:0] ST_LOAD = 3'd0;
  localparam [2:0] ST_WRITE = 3'd1;
  localparam [2:0] ST_B = 3'd2;

  wire [INPUT_WIDTH-1:0] fifo_out_data;
  wire                   fifo_out_valid;
  wire                   fifo_out_ready;
  wire [PADDED_WIDTH-1:0] fifo_out_padded =
    {{(PADDED_WIDTH-INPUT_WIDTH){1'b0}}, fifo_out_data};

  reg [2:0]                  state;
  reg [AXI_DATA_WIDTH-1:0]   packet_beats [0:TOTAL_BEATS-1];
  reg [BEAT_INDEX_WIDTH-1:0] beat_index;
  reg [BEAT_COUNT_WIDTH-1:0] beats_remaining;
  reg [8:0]                  burst_beats;
  reg [8:0]                  burst_beats_left;
  reg [AXI_ADDR_WIDTH-1:0]   current_addr;
  reg                        aw_done;
  reg                        w_done;
  integer                    packet_idx;

  function automatic [8:0] calculate_burst_beats;
    input [AXI_ADDR_WIDTH-1:0] addr;
    input [BEAT_COUNT_WIDTH-1:0] beats_left;
    integer limited_beats;
    integer bytes_to_4k;
    integer beats_to_4k;
    begin
      limited_beats = 0;
      limited_beats[BEAT_COUNT_WIDTH-1:0] = beats_left;
      if (limited_beats > MAX_BURST_LEN)
        limited_beats = MAX_BURST_LEN;

      bytes_to_4k = 4096 - {20'b0, addr[11:0]};
      beats_to_4k = bytes_to_4k / AXI_STRB_WIDTH;
      if (beats_to_4k < 1)
        beats_to_4k = 1;
      if (limited_beats > beats_to_4k)
        limited_beats = beats_to_4k;

      calculate_burst_beats = limited_beats[8:0];
    end
  endfunction

  function automatic [AXI_ADDR_WIDTH-1:0] beat_count_to_bytes;
    input [8:0] beats;
    begin
      beat_count_to_bytes = '0;
      beat_count_to_bytes[8:0] = beats;
      beat_count_to_bytes = beat_count_to_bytes << AXI_SIZE;
    end
  endfunction

  wire [AXI_ADDR_WIDTH-1:0] next_burst_addr =
    current_addr + beat_count_to_bytes(burst_beats);

  assign fifo_out_ready = axi_resetn && (state == ST_LOAD);

  assign m_axi_awid = {AXI_ID_WIDTH{1'b0}};
  assign m_axi_awaddr = current_addr;
  assign m_axi_awlen = burst_beats[7:0] - 1'b1;
  assign m_axi_awsize = AXI_SIZE[2:0];
  assign m_axi_awburst = 2'b01;
  assign m_axi_awlock = 1'b0;
  assign m_axi_awcache = 4'b0011;
  assign m_axi_awprot = 3'b000;
  assign m_axi_awqos = 4'b0000;
  assign m_axi_awvalid = (state == ST_WRITE) && !aw_done;

  assign m_axi_wdata = packet_beats[beat_index];
  assign m_axi_wstrb =
    (beats_remaining == {{(BEAT_COUNT_WIDTH-1){1'b0}}, 1'b1})
      ? LAST_WSTRB
      : {AXI_STRB_WIDTH{1'b1}};
  assign m_axi_wlast =
    (state == ST_WRITE) && !w_done && (burst_beats_left == 9'd1);
  assign m_axi_wvalid = (state == ST_WRITE) && !w_done;
  assign m_axi_bready = state == ST_B;

  wire aw_handshake = m_axi_awvalid && m_axi_awready;
  wire w_handshake = m_axi_wvalid && m_axi_wready;

  always @(posedge axi_clk) begin
    if (!axi_resetn) begin
      state <= ST_LOAD;
      beat_index <= {BEAT_INDEX_WIDTH{1'b0}};
      beats_remaining <= {BEAT_COUNT_WIDTH{1'b0}};
      burst_beats <= 9'd1;
      burst_beats_left <= 9'd0;
      current_addr <= BASE_ADDR;
      aw_done <= 1'b0;
      w_done <= 1'b0;
      for (packet_idx = 0; packet_idx < TOTAL_BEATS; packet_idx = packet_idx + 1)
        packet_beats[packet_idx] <= {AXI_DATA_WIDTH{1'b0}};
    end else begin
      case (state)
        ST_LOAD: begin
          if (fifo_out_valid) begin
            for (packet_idx = 0; packet_idx < TOTAL_BEATS; packet_idx = packet_idx + 1)
              packet_beats[packet_idx] <=
                fifo_out_padded[packet_idx*AXI_DATA_WIDTH +: AXI_DATA_WIDTH];
            beat_index <= {BEAT_INDEX_WIDTH{1'b0}};
            beats_remaining <= TOTAL_BEATS[BEAT_COUNT_WIDTH-1:0];
            burst_beats <= calculate_burst_beats(
              current_addr,
              TOTAL_BEATS[BEAT_COUNT_WIDTH-1:0]
            );
            burst_beats_left <= calculate_burst_beats(
              current_addr,
              TOTAL_BEATS[BEAT_COUNT_WIDTH-1:0]
            );
            aw_done <= 1'b0;
            w_done <= 1'b0;
            state <= ST_WRITE;
          end
        end

        ST_WRITE: begin
          if (aw_handshake)
            aw_done <= 1'b1;

          if (w_handshake) begin
            beats_remaining <= beats_remaining - 1'b1;
            burst_beats_left <= burst_beats_left - 1'b1;
            if (beats_remaining == {{(BEAT_COUNT_WIDTH-1){1'b0}}, 1'b1})
              beat_index <= {BEAT_INDEX_WIDTH{1'b0}};
            else
              beat_index <= beat_index + 1'b1;
            if (burst_beats_left == 9'd1)
              w_done <= 1'b1;
          end

          if ((aw_done || aw_handshake) &&
              (w_done || (w_handshake && (burst_beats_left == 9'd1))))
            state <= ST_B;
        end

        ST_B: begin
          if (m_axi_bvalid) begin
            current_addr <= next_burst_addr;
            if (beats_remaining == {BEAT_COUNT_WIDTH{1'b0}}) begin
              state <= ST_LOAD;
            end else begin
              burst_beats <= calculate_burst_beats(
                next_burst_addr,
                beats_remaining
              );
              burst_beats_left <= calculate_burst_beats(
                next_burst_addr,
                beats_remaining
              );
              aw_done <= 1'b0;
              w_done <= 1'b0;
              state <= ST_WRITE;
            end
          end
        end

        default: begin
          state <= ST_LOAD;
          beat_index <= {BEAT_INDEX_WIDTH{1'b0}};
          beats_remaining <= {BEAT_COUNT_WIDTH{1'b0}};
          burst_beats <= 9'd1;
          burst_beats_left <= 9'd0;
          current_addr <= BASE_ADDR;
          aw_done <= 1'b0;
          w_done <= 1'b0;
        end
      endcase
    end
  end

  Difftest2AXI4AsyncFIFO #(
    .DATA_WIDTH (INPUT_WIDTH),
    .BANK_WIDTH (AXI_DATA_WIDTH),
    .DEPTH      (FIFO_DEPTH)
  ) u_async_fifo (
    .wr_clk    (in_clk),
    .wr_ctrl_clk (in_ctrl_clk),
    .wr_resetn (in_resetn),
    .wr_data   (in_data),
    .wr_valid  (in_valid),
    .wr_ready  (in_ready),
    .rd_clk    (axi_clk),
    .rd_resetn (axi_resetn),
    .rd_data   (fifo_out_data),
    .rd_valid  (fifo_out_valid),
    .rd_ready  (fifo_out_ready)
  );

`ifndef SYNTHESIS
  initial begin
    if (INPUT_WIDTH < 1)
      $error("INPUT_WIDTH must be positive");
    if ((AXI_DATA_WIDTH < 8) || ((AXI_DATA_WIDTH % 8) != 0))
      $error("AXI_DATA_WIDTH must be a positive multiple of 8");
    if ((AXI_STRB_WIDTH & (AXI_STRB_WIDTH - 1)) != 0)
      $error("AXI_DATA_WIDTH must contain a power-of-two number of bytes");
    if (AXI_STRB_WIDTH > 128)
      $error("AXI4 supports at most 128 bytes per beat");
    if (AXI_ADDR_WIDTH < 12)
      $error("AXI_ADDR_WIDTH must be at least 12");
    if ((BASE_ADDR % AXI_ADDR_WIDTH'(AXI_STRB_WIDTH)) != 0)
      $error("BASE_ADDR must be aligned to the AXI beat size");
    if ((MAX_BURST_LEN < 1) || (MAX_BURST_LEN > 256))
      $error("MAX_BURST_LEN must be between 1 and 256");
  end
`endif

  wire _unused_ok = &{1'b0, m_axi_bid, m_axi_bresp};

endmodule
