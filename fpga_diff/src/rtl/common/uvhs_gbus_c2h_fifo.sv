`timescale 1ns/1ps

// GBus C2H interface layer.
//
// In XDMA builds the shared DiffTest sender (`Difftest2AXIs` inside the
// generated SimTop) buffers formatted batches in an on-chip SRAM AsyncClockFIFO,
// packs them into 768-byte ranges, and streams those ranges straight into the
// XDMA IP.  Nothing is staged in DDR.
//
// The GBus build keeps that sender untouched and replaces only the interface
// layer underneath it: GBus has no host-directed stream, only a register /
// backdoor bus.  So this module parks the same 256-bit AXI-stream in an on-chip
// SRAM FIFO and exposes a small register window the GBus host drains with
// ordinary register reads.
//
// That removes the DDR ring -- and with it the inter-FPGA link hop and the whole
// AXI master / arbiter path -- from the C2H direction, so XDMA and GBus differ
// only in this interface layer and the host-side reassembly.
//
// Register window (GeneralBD local addresses, i.e. after removing 0x1000):
//
//   0x1200  R  status
//              [31]    window present, reads as 1
//              [30]    frame_error sticky: an AXI-stream tlast did not land on
//                      beat PACKET_BEATS-1, so the 768-byte range framing the
//                      host reassembles is shifted
//              [29]    draining
//              [16:8]  staged_words: valid 32-bit words in the staging window
//              [7]     filling: a staging fill is in progress
//              [6]     has_data: payload is still buffered (FIFO or holding reg)
//   0x1204  W  control
//              [0]     start a staging fill (up to STAGE_WORDS 32-bit words)
//              [1]     drain: discard buffered payload without staging it
//   0x1204  R  {23'b0, staged_words}
//   0x1208  R  ID_MAGIC, a fixed word proving this window is reachable
//   0x2000.. R  staging window: STAGE_WORDS 32-bit words, little-endian byte
//               order inside each word, matching the byte order the XDMA build
//               delivers over PCIe.
//
// The ID register exists because a window that is not decoded at all is
// indistinguishable from an idle one: every read returns zero either way.  A
// host that checks this word first reports "the C2H window is not reachable"
// instead of looping on a staged_words that will never move.
//
// A fill ends either when the staging window is full or when the FIFO runs dry;
// the host appends whatever it read to the 768-byte range it is reassembling and
// issues another control write if the range is still short.
module uvhs_gbus_c2h_fifo #(
    parameter integer AXIS_DATA_WIDTH = 256,
    parameter integer AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH / 8,
    // 2048 x 256-bit = 64 KiB of payload buffering, so a host drain pause does
    // not immediately stall the CPU through the DiffTest ready gate.
    parameter integer FIFO_ADDR_WIDTH = 11,
    // 1 KiB staging window: one control write loads it, then the host reads the
    // whole window in one burst where the runtime supports multi-word reads.
    parameter integer STAGE_WORDS = 256,
    // One range is eight 96-byte packets, i.e. 24 beats of 32 bytes.
    parameter integer PACKET_BEATS = 24
) (
    input  wire                       clk,
    input  wire                       rstn,
    // C2H stream enable from the DiffTest reset gate.  Both clocks are the
    // always-running GBus host clock today, so one combined reset keeps the FIFO
    // pointers consistent; the async FIFO below still carries the Gray CDC
    // structure so the clock binding can move later without a rewrite.
    input  wire                       stream_rstn,

    input  wire [AXIS_DATA_WIDTH-1:0] s_tdata,
    input  wire [AXIS_KEEP_WIDTH-1:0] s_tkeep,
    input  wire                       s_tlast,
    input  wire                       s_tvalid,
    output wire                       s_tready,

    input  wire                       cfg_wr_en,
    input  wire [15:0]                cfg_wr_addr,
    input  wire [31:0]                cfg_wdata,
    input  wire                       cfg_rd_en,
    input  wire [15:0]                cfg_rd_addr,
    output reg  [31:0]                cfg_rdata,
    output reg                        cfg_rdata_vld
);
  localparam integer LANES = AXIS_DATA_WIDTH / 32;
  localparam integer LANE_WIDTH = (LANES <= 1) ? 1 : $clog2(LANES);
  localparam integer STAGE_IDX_WIDTH = (STAGE_WORDS <= 1) ? 1 : $clog2(STAGE_WORDS);
  localparam integer STAGE_CNT_WIDTH = (STAGE_WORDS <= 1) ? 1 : $clog2(STAGE_WORDS + 1);

  localparam [15:0] REG_STATUS = 16'h1200;
  localparam [15:0] REG_CTRL = 16'h1204;
  localparam [15:0] REG_ID = 16'h1208;
  localparam [15:0] REG_DATA = 16'h2000;
  localparam [15:0] REG_DATA_LAST = REG_DATA + 16'(STAGE_WORDS * 4 - 1);
  // ASCII "GBS1": recognisable in a hex dump, and not a value an undecoded or
  // unwritten register would happen to return.
  localparam [31:0] ID_MAGIC = 32'h4742_5331;

  wire fifo_rstn = rstn & stream_rstn;

  wire [AXIS_DATA_WIDTH-1:0] fifo_tdata;
  wire [AXIS_KEEP_WIDTH-1:0] fifo_tkeep;
  wire fifo_tlast, fifo_tvalid, fifo_tready, fifo_has_data;
  wire fifo_s_has_data;

  uvhs_axis_async_fifo #(
      .DATA_WIDTH(AXIS_DATA_WIDTH),
      .KEEP_WIDTH(AXIS_KEEP_WIDTH),
      .ADDR_WIDTH (FIFO_ADDR_WIDTH)
  ) u_c2h_fifo (
      .s_clk(clk), .s_rstn(fifo_rstn),
      .s_tdata(s_tdata), .s_tkeep(s_tkeep), .s_tlast(s_tlast),
      .s_tvalid(s_tvalid), .s_tready(s_tready), .s_has_data(fifo_s_has_data),
      .m_clk(clk), .m_rstn(fifo_rstn),
      .m_tdata(fifo_tdata), .m_tkeep(fifo_tkeep), .m_tlast(fifo_tlast),
      .m_tvalid(fifo_tvalid), .m_tready(fifo_tready),
      .m_has_data(fifo_has_data)
  );

  // --------------------------------------------------------------- staging
  // One 256-bit FIFO entry is unpacked into LANES consecutive 32-bit staging
  // words, so the host can read the payload with plain register reads.
  //
  // The pop is registered on this side: a beat is held in `hold_data` for the
  // LANES cycles it takes to unpack, so `fifo_tready` is asserted only on the
  // cycle the beat is taken into the holding register.
  reg [31:0] stage_mem[0:STAGE_WORDS-1];
  reg [STAGE_CNT_WIDTH-1:0] staged_words;
  reg filling, drain_mode;
  reg [AXIS_DATA_WIDTH-1:0] hold_data;
  reg hold_valid;
  reg [LANE_WIDTH-1:0] hold_lane;

  // ------------------------------------------------------------ frame check
  // The sender contract is exactly PACKET_BEATS beats per tlast.  An early or
  // missing boundary shifts the 768-byte range framing, so make it a sticky,
  // host-visible error instead of silent corruption.
  reg frame_error;
  reg [7:0] beat_count;

  wire last_lane = (hold_lane == LANE_WIDTH'(LANES - 1));
  wire window_has_room = (staged_words != STAGE_CNT_WIDTH'(STAGE_WORDS));

  wire take_beat = filling && !drain_mode && !hold_valid && fifo_tvalid && window_has_room;
  wire unpack_lane = filling && !drain_mode && hold_valid;
  // STAGE_WORDS must be a multiple of LANES so the window fills exactly on a
  // beat boundary; otherwise the last beat would be half written when the fill
  // stops.  STAGE_WORDS=256 and LANES=8 satisfy this.
  wire window_filled = unpack_lane && last_lane &&
                       (staged_words + 1'b1 == STAGE_CNT_WIDTH'(STAGE_WORDS));
  // Drain mode only discards what is already buffered; the instant the FIFO is
  // empty the drain ends so the host is not left polling a permanently busy FSM.
  wire drain_beat = filling && drain_mode && fifo_tvalid;
  wire drain_done = filling && drain_mode && !fifo_tvalid;

  // A beat is popped exactly once, on the cycle it is latched into the holding
  // register.  The FIFO's output stage is already registered, so latching
  // m_tdata and asserting m_tready in the same cycle is a normal consumer
  // handshake; asserting m_tready again when the last lane is written out would
  // consume the next entry without ever latching it.
  assign fifo_tready = take_beat | drain_beat;

  wire ctrl_wr = cfg_wr_en && (cfg_wr_addr == REG_CTRL);
  wire start_fill = ctrl_wr && cfg_wdata[0];
  wire start_drain = ctrl_wr && cfg_wdata[1];
  wire has_data = fifo_has_data | hold_valid;

  // A fill ends when the staging window is full, or when the FIFO has run dry.
  // The host observes the end through status[7] going low and reads
  // status[16:8] to learn how many words landed.
  wire stream_dry = filling && !drain_mode && !hold_valid && !fifo_tvalid;

  integer k;
  // The staging FSM and the frame counter follow the stream reset, not just the
  // fabric reset.  The DiffTest stream enable drops whenever the host clears
  // DIFFTEST_ENABLE, and the FIFO is cleared with it; if beat_count survived
  // that, the first range after re-enable would look like a framing error.
  always @(posedge clk or negedge fifo_rstn) begin
    if (!fifo_rstn) begin
      staged_words <= 0;
      filling <= 1'b0;
      drain_mode <= 1'b0;
      hold_data <= 0;
      hold_valid <= 1'b0;
      hold_lane <= 0;
      frame_error <= 1'b0;
      beat_count <= 8'd0;
      for (k = 0; k < STAGE_WORDS; k = k + 1) stage_mem[k] <= 32'b0;
    end else begin
      if (s_tvalid && s_tready) begin
        if (s_tlast != (beat_count == 8'(PACKET_BEATS - 1))) frame_error <= 1'b1;
        beat_count <= s_tlast ? 8'd0 : (beat_count + 8'd1);
      end

      if (start_fill || start_drain) begin
        filling <= 1'b1;
        drain_mode <= start_drain;
        staged_words <= 0;
        hold_valid <= 1'b0;
        hold_lane <= 0;
      end else begin
        // Pop one FIFO beat into the holding register; take_beat requires
        // !hold_valid, so this never collides with the unpack below.
        if (take_beat) begin
          hold_data <= fifo_tdata;
          hold_valid <= 1'b1;
          hold_lane <= 0;
        end

        // Unpack the holding beat into LANES consecutive 32-bit window words.
        if (unpack_lane) begin
          stage_mem[staged_words[STAGE_IDX_WIDTH-1:0]] <= hold_data[hold_lane*32 +: 32];
          staged_words <= staged_words + 1'b1;
          if (last_lane) begin
            hold_valid <= 1'b0;
            hold_lane <= 0;
          end else begin
            hold_lane <= hold_lane + 1'b1;
          end
          if (window_filled) filling <= 1'b0;
        end

        // Nothing left to stage (or nothing left to discard).
        if (stream_dry || drain_done) begin
          filling <= 1'b0;
          drain_mode <= 1'b0;
          hold_valid <= 1'b0;
          hold_lane <= 0;
        end
      end
    end
  end

  // --------------------------------------------------------- register reads
  wire [31:0] status_word = {
      1'b1,                        // [31]   window present
      frame_error,                 // [30]   sticky framing error
      drain_mode,                  // [29]   drain in progress
      12'b0,                       // [28:17]
      staged_words,                // [16:8] valid staging words
      filling,                     // [7]    staging fill in progress
      has_data,                    // [6]    payload still buffered
      6'b0                         // [5:0]
  };

  wire [STAGE_IDX_WIDTH-1:0] rd_stage_idx = cfg_rd_addr[STAGE_IDX_WIDTH+1:2];
  wire in_data_window = (cfg_rd_addr >= REG_DATA) && (cfg_rd_addr <= REG_DATA_LAST);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cfg_rdata <= 32'b0;
      cfg_rdata_vld <= 1'b0;
    end else begin
      cfg_rdata_vld <= cfg_rd_en;
      if (in_data_window) cfg_rdata <= stage_mem[rd_stage_idx];
      else
        case (cfg_rd_addr)
          REG_STATUS: cfg_rdata <= status_word;
          REG_CTRL: cfg_rdata <= {23'b0, staged_words};
          REG_ID: cfg_rdata <= ID_MAGIC;
          default: cfg_rdata <= 32'b0;
        endcase
    end
  end
endmodule
