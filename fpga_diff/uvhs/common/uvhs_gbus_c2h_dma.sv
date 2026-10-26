`timescale 1ns/1ps

// Streaming GBus C2H frame FIFO.
//
// The CPU emits fixed 768-byte frames (24 x 256-bit beats, TLAST on the last
// beat).  Each complete frame is appended to a ring of FRAMES frames that the
// host reads through the GBus AXI aperture.  Nothing is frozen: the producer
// keeps writing behind the consumer for as long as the ring has room.
//
// The handoff gate is a pair of frame counters.  AVAILABLE reports how many
// complete frames the host may read; CONSUME advances the read pointer by a
// frame count once the host has copied them out.  Because only CONSUME moves
// the read pointer, the producer can never overwrite unread data, so a slow or
// stalled host DMA call costs throughput but never correctness.
//
// Frames are validated on the way in (24 beats, all byte enables, TLAST on the
// last beat).  A malformed frame is dropped instead of published and raises
// the sticky frame_error bit.
module uvhs_gbus_c2h_dma #(
    parameter integer AXIS_DATA_WIDTH = 256,
    // 340 frames = 261120 bytes = 255 KiB: the largest multiple of 768 that
    // fits below 0x0fffffff when the aperture starts at 0x0ffc0000.
    parameter integer FRAMES = 340
) (
    input wire clk,
    input wire rstn,
    // Capture-domain reset from the DiffTest stream enable.  While low it stops
    // capture and rejects aperture reads, and it clears the ring pointers: a
    // CPU reset restarts the trace from frame zero, so the buffered frames are
    // no longer meaningful.
    input wire stream_rstn,

    input wire [AXIS_DATA_WIDTH-1:0] s_tdata,
    input wire [AXIS_DATA_WIDTH/8-1:0] s_tkeep,
    input wire s_tlast,
    input wire s_tvalid,
    output wire s_tready,

    input wire cfg_wr_en,
    input wire [15:0] cfg_wr_addr,
    input wire [31:0] cfg_wdata,
    input wire cfg_rd_en,
    input wire [15:0] cfg_rd_addr,
    output reg [31:0] cfg_rdata,
    output reg cfg_rdata_vld,

    input wire [7:0] s_arid,
    input wire [31:0] s_araddr,
    input wire [3:0] s_arlen,
    input wire [2:0] s_arsize,
    input wire [1:0] s_arburst,
    input wire s_arvalid,
    output wire s_arready,
    output wire [7:0] s_rid,
    output wire [AXIS_DATA_WIDTH-1:0] s_rdata,
    output wire [1:0] s_rresp,
    output wire s_rlast,
    output wire s_rvalid,
    input wire s_rready
);
  localparam [31:0] APERTURE = 32'h0ffc_0000;
  localparam [31:0] ID_MAGIC = 32'h4742_4431;  // "GBD1"

  localparam integer FRAME_BEATS = 24;
  localparam integer BEAT_BYTES = 32;
  localparam integer FRAME_BYTES = FRAME_BEATS * BEAT_BYTES;  // 768
  localparam integer RING_BYTES = FRAMES * FRAME_BYTES;
  localparam integer RING_BEATS = FRAMES * FRAME_BEATS;
  localparam integer RING_AW = $clog2(RING_BEATS);
  localparam [5:0] LAST_BEAT = 6'd23;
  localparam [15:0] LAST_FRAME = 16'(FRAMES) - 16'd1;
  localparam [15:0] BEATS_PER_FRAME = 16'd24;

  initial begin
    if (AXIS_DATA_WIDTH != 256)
      $error("GBD1 streaming engine requires 256-bit stream data");
    if (FRAMES < 2 || FRAMES > 4096)
      $error("GBD1 streaming engine requires 2..4096 frames");
  end

  wire stream_on = rstn & stream_rstn;

  // ------------------------------------------------------------- producer side
  reg [31:0] wr_count;  // frames completed since stream reset
  reg [31:0] rd_count;  // frames released by CONSUME since stream reset
  reg [15:0] wr_phys;   // ring index 0..FRAMES-1 of the frame being written
  reg [15:0] rd_phys;   // ring index 0..FRAMES-1 of the oldest unread frame
  reg [5:0] wr_beat;    // beat index inside the frame being written
  reg enabled;
  reg frame_error;

  wire [31:0] available = wr_count - rd_count;
  // A frame keeps its slot until its last beat lands, so this test cannot
  // revoke room halfway through a frame.
  assign s_tready = stream_on && enabled && !frame_error && (available < FRAMES);

  wire take_beat = s_tvalid && s_tready;
  wire capture_last = (wr_beat[5:0] == LAST_BEAT);
  wire frame_good = (&s_tkeep) && (s_tlast == capture_last);
  wire frame_done = take_beat && capture_last && frame_good;
  wire frame_drop = take_beat && (!frame_good | (s_tlast != capture_last));

  reg [AXIS_DATA_WIDTH-1:0] stage_mem [0:RING_BEATS-1];
  wire [RING_AW+3:0] wr_prod = wr_phys * BEATS_PER_FRAME;
  wire [RING_AW-1:0] wr_index = wr_prod[RING_AW-1:0] + {7'b0, wr_beat};

  always @(posedge clk) begin
    if (take_beat)
      stage_mem[wr_index] <= s_tdata;
  end

  // Shadow of the oldest unread frame.  The host reads it through the config
  // window once per session to cross-check its DMA payload.  Keeping it in a
  // separate 768-byte array lets the main ring keep its single read port, so
  // the big array still maps to block RAM.
  reg [AXIS_DATA_WIDTH-1:0] shadow [0:FRAME_BEATS-1];

  always @(posedge clk) begin
    if (take_beat && (wr_count == rd_count))
      shadow[wr_beat[4:0]] <= s_tdata;
  end

  // CONSUME names a frame count; ACK (control bit 1) releases exactly one frame
  // so a host that predates the batch protocol still makes progress.
  wire control_wr = cfg_wr_en && (cfg_wr_addr == 16'h1204);
  wire feature_wr = cfg_wr_en && (cfg_wr_addr == 16'h1238);
  wire enable_req = control_wr && cfg_wdata[0];
  wire ack_req = control_wr && cfg_wdata[1];
  wire clear_error = control_wr && cfg_wdata[2];
  wire disable_req = control_wr && cfg_wdata[3];
  wire consume_req = cfg_wr_en && (cfg_wr_addr == 16'h123c) && stream_on;
  wire [31:0] requested = consume_req ? cfg_wdata : (ack_req ? 32'd1 : 32'd0);
  wire consume_ok = (requested != 0) && (requested <= available) &&
                    ((consume_req && stream_on) || (ack_req && stream_on));
  wire [31:0] stream_consume = consume_ok ? requested : 32'd0;
  wire [31:0] rd_phys_sum = {16'b0, rd_phys} + stream_consume;
  wire consume_illegal = (requested != 0) && stream_on && (requested > available);
  // The startup stream-reset window must not turn a control write into a fault:
  // the command is simply not acted on and is not replayed later.
  wire control_bad = stream_on &&
                     (consume_illegal || (control_wr && cfg_wdata[0] && cfg_wdata[1]));

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      wr_count <= 0;
      rd_count <= 0;
      wr_phys <= 0;
      rd_phys <= 0;
      wr_beat <= 0;
      enabled <= 1'b0;
      frame_error <= 1'b0;
    end else if (!stream_on) begin
      // A CPU reset restarts the trace: drop every pointer and any partial
      // frame, and require a fresh ENABLE before capturing again.
      wr_count <= 0;
      rd_count <= 0;
      wr_phys <= 0;
      rd_phys <= 0;
      wr_beat <= 0;
      enabled <= 1'b0;
      frame_error <= 1'b0;
    end else begin
      if (enable_req && !enabled)
        enabled <= 1'b1;
      if (disable_req)
        enabled <= 1'b0;

      if (take_beat) begin
        if (capture_last)
          wr_beat <= 0;
        else
          wr_beat <= wr_beat + 1'b1;
      end

      // A frame becomes visible only when its last beat was well formed.
      if (frame_done) begin
        wr_count <= wr_count + 1'b1;
        wr_phys <= (wr_phys == LAST_FRAME) ? 16'd0 : wr_phys + 16'd1;
      end
      if (frame_drop)
        frame_error <= 1'b1;

      if (stream_consume != 0) begin
        rd_count <= rd_count + stream_consume;
        // rd_phys + n < 2*FRAMES, so a single subtraction wraps it.
        rd_phys <= (rd_phys_sum >= FRAMES) ? (rd_phys_sum[15:0] - LAST_FRAME - 16'd1)
                                                        : rd_phys_sum[15:0];
      end
    end
  end

  // ---------------------------------------------------------------- AXI reads
  // Byte window the host may read: completed frames that CONSUME has not yet
  // released.  A burst may not cross the ring end; the host splits a wrapped
  // batch into two reads instead.
  wire [31:0] rd_byte = rd_phys * FRAME_BYTES;
  wire [31:0] wr_byte = wr_phys * FRAME_BYTES;
  wire [31:0] avail_bytes = available * FRAME_BYTES;
  wire [32:0] rd_window_start = {1'b0, APERTURE} + {1'b0, rd_byte};
  wire [32:0] rd_window_end = rd_window_start + {1'b0, avail_bytes};
  wire [32:0] ring_end = {1'b0, APERTURE} + RING_BYTES;

  wire [4:0] ar_beats = {1'b0, s_arlen} + 5'd1;
  wire [32:0] ar_span = (s_arburst == 2'b01)
                            ? ({28'b0, ar_beats} << s_arsize)
                            : ({32'b0, 1'b1} << s_arsize);
  wire [32:0] ar_end = {1'b0, s_araddr} + ar_span;
  wire [31:0] ar_step_mask = (32'd1 << s_arsize) - 32'd1;

  wire ar_legal = stream_on && enabled && !frame_error && (available != 0) &&
      (s_arsize == 3'd5) && ((s_arburst == 2'b00) || (s_arburst == 2'b01)) &&
      ((s_araddr & ar_step_mask) == 32'd0) &&
      ({1'b0, s_araddr} >= rd_window_start) && (ar_end <= rd_window_end) &&
      (ar_end <= ring_end);

  wire [31:0] start_byte = s_araddr - APERTURE;
  wire [RING_AW-1:0] start_index = start_byte[RING_AW+4:5];

  reg active;
  reg [7:0] read_id;
  reg read_error;
  reg [AXIS_DATA_WIDTH-1:0] rdata_q;
  reg rdata_valid;
  reg [4:0] beats_pending;  // beats still to fetch, excluding the held one
  reg [RING_AW-1:0] fetch_index;

  wire ar_take = s_arvalid && s_arready;
  wire r_fire = rdata_valid && s_rready;
  wire do_fetch = active && (!rdata_valid || r_fire) && (beats_pending != 0);
  wire ram_re = ar_take || do_fetch;
  wire [RING_AW-1:0] ram_addr = ar_take ? start_index : fetch_index;

  // Registered output: a single synchronous read port keeps the ring in block
  // RAM instead of spilling 2 Mbit into LUTRAM.
  always @(posedge clk) begin
    if (ram_re)
      rdata_q <= stage_mem[ram_addr];
  end

  assign s_arready = rstn && !active;
  assign s_rvalid = rdata_valid;
  assign s_rid = read_id;
  assign s_rdata = read_error ? {AXIS_DATA_WIDTH{1'b0}} : rdata_q;
  assign s_rresp = read_error ? 2'b10 : 2'b00;
  assign s_rlast = rdata_valid && (beats_pending == 0);

  // ------------------------------------------------------------------ evidence
  reg [31:0] dbg_ar_addr;
  reg [31:0] dbg_ar_attrs;
  reg [31:0] dbg_ar_count;
  reg [31:0] dbg_ctrl_count;
  reg [31:0] dbg_ctrl_data;
  reg dbg_bad_ctrl_valid;
  reg [31:0] dbg_bad_ctrl_data;
  reg [31:0] dbg_bad_ctrl_state;
  reg [31:0] dbg_bad_ctrl_count;
  reg protocol_error;

  wire [31:0] status_word = {
      1'b1,               // 31 present
      frame_error,        // 30
      protocol_error,     // 29
      12'b0,              // 28:17
      9'b0,               // 16:8  (streaming reports its length in 0x123c)
      enabled,            // 7
      s_tvalid,           // 6
      (available != 0),   // 5
      active,             // 4
      4'b0                // 3:0
  };

  // The AXI response state uses fabric reset only: an accepted response must
  // survive a stream reset, otherwise the host's burst is left hanging.
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      active <= 1'b0;
      read_id <= 0;
      read_error <= 0;
      rdata_valid <= 1'b0;
      beats_pending <= 0;
      fetch_index <= 0;
      dbg_ar_addr <= 0;
      dbg_ar_attrs <= 0;
      dbg_ar_count <= 0;
      dbg_ctrl_count <= 0;
      dbg_ctrl_data <= 0;
      dbg_bad_ctrl_valid <= 1'b0;
      dbg_bad_ctrl_data <= 0;
      dbg_bad_ctrl_state <= 0;
      dbg_bad_ctrl_count <= 0;
      protocol_error <= 1'b0;
    end else begin
      if (control_wr) begin
        dbg_ctrl_count <= dbg_ctrl_count + 1'b1;
        dbg_ctrl_data <= cfg_wdata;
      end
      if (clear_error)
        protocol_error <= 1'b0;
      if (control_bad || feature_wr)
        protocol_error <= 1'b1;
      if (control_bad && !dbg_bad_ctrl_valid) begin
        dbg_bad_ctrl_valid <= 1'b1;
        dbg_bad_ctrl_data <= cfg_wdata;
        dbg_bad_ctrl_state <= {22'b0, available[3:0], enabled, frame_error,
                               stream_on, active, s_tvalid, (available < FRAMES)};
        dbg_bad_ctrl_count <= dbg_ctrl_count + 1'b1;
      end

      if (ar_take) begin
        active <= 1'b1;
        read_id <= s_arid;
        read_error <= !ar_legal;
        rdata_valid <= 1'b1;
        fetch_index <= start_index + 1'b1;
        beats_pending <= ar_beats - 1'b1;
        dbg_ar_addr <= s_araddr;
        dbg_ar_attrs <= {s_arid, s_arburst, s_arsize, s_arlen, 15'b0};
        dbg_ar_count <= dbg_ar_count + 1'b1;
        if (!ar_legal)
          protocol_error <= 1'b1;
      end else if (active) begin
        if (do_fetch) begin
          rdata_valid <= 1'b1;
          fetch_index <= fetch_index + 1'b1;
          beats_pending <= beats_pending - 1'b1;
        end else if (r_fire) begin
          rdata_valid <= 1'b0;
        end
        if (r_fire && beats_pending == 0)
          active <= 1'b0;
      end
    end
  end

  // ------------------------------------------------------------ config window
  localparam [15:0] SHADOW_END = 16'h2000 + 16'(FRAME_BEATS * 32);
  wire shadow_hit = (cfg_rd_addr >= 16'h2000) && (cfg_rd_addr < SHADOW_END) &&
                    (cfg_rd_addr[1:0] == 2'b0);

  always @(posedge clk) begin
    cfg_rdata_vld <= cfg_rd_en;
    if (shadow_hit)
      cfg_rdata <= shadow[cfg_rd_addr[9:5]][cfg_rd_addr[4:2]*32 +: 32];
    else case (cfg_rd_addr)
      16'h1200: cfg_rdata <= status_word;
      16'h1204: cfg_rdata <= {30'b0, enabled, 1'b0};
      16'h1208: cfg_rdata <= ID_MAGIC;
      16'h120c: cfg_rdata <= wr_count;
      16'h1210: cfg_rdata <= APERTURE;
      16'h1214: cfg_rdata <= RING_BYTES;
      16'h1218: cfg_rdata <= dbg_ar_addr;
      16'h121c: cfg_rdata <= dbg_ar_attrs;
      16'h1220: cfg_rdata <= dbg_ar_count;
      16'h1224: cfg_rdata <= dbg_ctrl_count;
      16'h1228: cfg_rdata <= dbg_ctrl_data;
      16'h122c: cfg_rdata <= dbg_bad_ctrl_data;
      16'h1230: cfg_rdata <= {dbg_bad_ctrl_valid, dbg_bad_ctrl_state[30:0]};
      16'h1234: cfg_rdata <= dbg_bad_ctrl_count;
      16'h1238: cfg_rdata <= {29'b0, 1'b1, 1'b0, 1'b1};  // bit2 streaming, bit1 header (absent), bit0 present
      16'h123c: cfg_rdata <= available;
      16'h1240: cfg_rdata <= rd_byte;
      16'h1244: cfg_rdata <= wr_byte;
      default: cfg_rdata <= 0;
    endcase
  end
endmodule
