`timescale 1ns/1ps

// GBus C2H SRAM endpoint.  The sender and the existing 64-KiB async FIFO
// both run on the host clock.  FILL publishes up to 32 complete stream beats;
// TLAST checks the sender's 768-byte framing, but never terminates a fill.
// The host may reread the immutable bank until ACK releases it.
//
// Local registers:
//   1200 status: present[31], frame_error[30], protocol_error[29],
//               staged_words[16:8], filling[7], fifo_has_data[6],
//               frozen[5], AXI active[4]
//   1204 control: FILL[0], ACK[1], clear protocol_error[2]; read staged_words
//   1208 ID "GBD1", 120c publication sequence, 1210 AXI base, 1214 capacity
//   1218 last AR address, 121c last AR {id,burst,size,len}, 1220 AR count
//   2000..23fc frozen bank, little-endian 32-bit debug reads
// AXI3 reads decode a 4-KiB aperture, but only published bank bytes are valid.
module uvhs_gbus_c2h_dma #(
    parameter integer AXIS_DATA_WIDTH = 256,
    parameter integer FIFO_ADDR_WIDTH = 11,
    parameter integer STAGE_WORDS = 256
) (
    input  wire                       clk,
    input  wire                       rstn,
    input  wire                       stream_rstn,
    input  wire [AXIS_DATA_WIDTH-1:0]  s_tdata,
    input  wire [AXIS_DATA_WIDTH/8-1:0] s_tkeep,
    input  wire                       s_tlast,
    input  wire                       s_tvalid,
    output wire                       s_tready,
    input  wire                       cfg_wr_en,
    input  wire [15:0]                cfg_wr_addr,
    input  wire [31:0]                cfg_wdata,
    input  wire                       cfg_rd_en,
    input  wire [15:0]                cfg_rd_addr,
    output reg  [31:0]                cfg_rdata,
    output reg                        cfg_rdata_vld,
    input  wire [7:0]                 s_arid,
    input  wire [31:0]                s_araddr,
    input  wire [3:0]                 s_arlen,
    input  wire [2:0]                 s_arsize,
    input  wire [1:0]                 s_arburst,
    input  wire                       s_arvalid,
    output wire                       s_arready,
    output wire [7:0]                 s_rid,
    output wire [255:0]               s_rdata,
    output wire [1:0]                 s_rresp,
    output wire                       s_rlast,
    output wire                       s_rvalid,
    input  wire                       s_rready
);
  localparam integer STAGE_BEATS = 32;
  localparam [31:0] APERTURE = 32'h1000_0000;
  localparam [31:0] ID_MAGIC = 32'h4742_4431;
  // Parameters retained for existing instantiations; the host ABI is fixed.
  initial begin
    if (AXIS_DATA_WIDTH != 256 || STAGE_WORDS != 256)
      $error("GBD1 requires 256-bit stream data and a 256-word bank");
  end

  wire fifo_rstn = rstn & stream_rstn;
  wire [AXIS_DATA_WIDTH-1:0] fifo_tdata;
  wire fifo_tvalid, fifo_tready, fifo_has_data, fifo_s_ready;
  uvhs_axis_async_fifo #(
      .DATA_WIDTH(AXIS_DATA_WIDTH),
      .KEEP_WIDTH(AXIS_DATA_WIDTH / 8),
      .ADDR_WIDTH(FIFO_ADDR_WIDTH)
  ) u_c2h_fifo (
      .s_clk(clk), .s_rstn(fifo_rstn),
      .s_tdata(s_tdata), .s_tkeep(s_tkeep), .s_tlast(s_tlast),
      .s_tvalid(s_tvalid && fifo_rstn), .s_tready(fifo_s_ready), .s_has_data(),
      .m_clk(clk), .m_rstn(fifo_rstn),
      .m_tdata(fifo_tdata), .m_tkeep(), .m_tlast(),
      .m_tvalid(fifo_tvalid), .m_tready(fifo_tready),
      .m_has_data(fifo_has_data)
  );
  assign s_tready = fifo_rstn && fifo_s_ready;

  // ------------------------------------------------------------ frame check
  // Count accepted beats, not valid cycles or FIFO pops.  Once broken, framing
  // stays flagged until stream reset, including after a later correct TLAST.
  reg frame_error;
  reg [4:0] frame_beat;
  always @(posedge clk or negedge fifo_rstn) begin
    if (!fifo_rstn) begin
      frame_error <= 1'b0;
      frame_beat <= 0;
    end else if (s_tvalid && s_tready) begin
      if (!(&s_tkeep) || (s_tlast != (frame_beat == 5'd23)))
        frame_error <= 1'b1;
      frame_beat <= (frame_beat == 5'd23) ? 5'd0 : frame_beat + 1'b1;
    end
  end

  // --------------------------------------------------------------- staging
  reg [255:0] stage_mem [0:STAGE_BEATS-1];
  reg [5:0] staged_beats;
  reg filling, frozen;
  reg [31:0] sequence_q;
  reg protocol_error;
  wire [8:0] staged_words = {staged_beats, 3'b000};

  // AXI state follows fabric reset ONLY.  Stream reset invalidates the bank
  // metadata but never writes bank RAM.  An outstanding burst keeps reading
  // its original bytes, and active blocks all fills until its final handshake.
  reg active;
  reg [7:0] read_id;
  reg [4:0] read_left; // AXI3 LEN=15 means 16 beats, not zero
  reg [31:0] read_addr;
  reg [5:0] read_step;
  reg read_incr, read_error;
  wire ar_take = s_arvalid && s_arready;
  // Bring-up diagnostics.  The host makes every window resident at the same
  // absolute aperture, so if the DMA engine ignored the requested offset the
  // host could not tell from its own logs.  Recording what the endpoint was
  // actually asked for turns that failure into a single decisive log line.
  reg [31:0] dbg_ar_addr;
  reg [31:0] dbg_ar_count;
  reg [31:0] dbg_ar_attrs;

  wire ctrl_wr = cfg_wr_en && (cfg_wr_addr == 16'h1204);
  wire fill_request = ctrl_wr && cfg_wdata[0];
  wire ack_request = ctrl_wr && cfg_wdata[1];
  wire clear_error = ctrl_wr && cfg_wdata[2];
  // AR wins over control even when the requested read will return SLVERR.
  // In particular, ACK cannot revoke a bank accepted for reading this cycle.
  wire fill_ok = fill_request && !ack_request && fifo_rstn &&
                 !filling && !frozen && !active && !ar_take;
  wire ack_ok = ack_request && !fill_request && fifo_rstn &&
                frozen && !filling && !active && !ar_take;
  wire bad_control = (fill_request && !fill_ok) || (ack_request && !ack_ok);

  assign fifo_tready = fifo_rstn && filling && !frozen && !active;
  wire take_beat = fifo_tvalid && fifo_tready;
  wire bank_full = take_beat && (staged_beats == 6'd31);
  // m_has_data includes both unread SRAM and the output prefetch register.
  // !m_tvalid alone would mistake the prefetch latency for an empty FIFO.
  wire fifo_dry = filling && !fifo_has_data;

  always @(posedge clk or negedge fifo_rstn) begin
    if (!fifo_rstn) begin
      staged_beats <= 0;
      filling <= 1'b0;
      frozen <= 1'b0;
      sequence_q <= 0;
    end else begin
      if (fill_ok) begin
        filling <= 1'b1;
        staged_beats <= 0;
      end else if (ack_ok) begin
        frozen <= 1'b0;
        staged_beats <= 0;
      end
      if (take_beat) staged_beats <= staged_beats + 1'b1;
      if (bank_full || fifo_dry) begin
        filling <= 1'b0;
        // An empty fill completes idle, without a bank or a sequence bump.
        if (bank_full || (staged_beats != 0)) begin
          frozen <= 1'b1;
          sequence_q <= sequence_q + 1'b1;
        end
      end
    end
  end

  // No RAM reset: validity comes from frozen/published length.  This also
  // guarantees RDATA stability if stream reset arrives during a stalled read.
  always @(posedge clk) begin
    if (take_beat) stage_mem[staged_beats[4:0]] <= fifo_tdata;
  end

  // --------------------------------------------------------------- AXI read
  // Validate the entire burst with an extended exclusive end address, before
  // returning any data.  FIXED touches just one transfer regardless of ARLEN.
  //
  // Any AXI3 transfer size up to the 32-byte bus width is accepted, not only
  // full-width ones: the vendor DMA engine's choice of ARSIZE is not part of
  // the documented runtime contract, and a narrower read still addresses the
  // same bytes.  A 32-byte bank beat is returned whole, so the master samples
  // the lanes its transfer size selects.
  wire [5:0] ar_step = 6'd1 << s_arsize;
  wire [4:0] ar_beats = {1'b0, s_arlen} + 5'd1;
  wire [32:0] ar_span = (s_arburst == 2'b01) ? ({28'b0, ar_beats} << s_arsize)
                                             : {27'b0, ar_step};
  wire [32:0] ar_end = {1'b0, s_araddr} + ar_span;
  wire [32:0] published_end = {1'b0, APERTURE} + {22'b0, staged_beats, 5'b0};
  wire [31:0] ar_step_mask = {26'b0, ar_step} - 32'd1;
  wire ar_legal = fifo_rstn && frozen && !filling &&
      (s_araddr[31:12] == APERTURE[31:12]) &&
      ((s_araddr & ar_step_mask) == 32'd0) && (s_arsize <= 3'd5) &&
      ((s_arburst == 2'b00) || (s_arburst == 2'b01)) &&
      (ar_end <= published_end);

  assign s_arready = rstn && !active;
  assign s_rvalid = active;
  assign s_rid = read_id;
  assign s_rdata = read_error ? 256'b0 : stage_mem[read_addr[9:5]];
  assign s_rresp = read_error ? 2'b10 : 2'b00;
  assign s_rlast = (read_left == 5'd1);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      active <= 1'b0;
      read_id <= 0;
      read_left <= 0;
      read_addr <= 0;
      read_step <= 6'd1;
      read_incr <= 1'b0;
      read_error <= 1'b0;
      protocol_error <= 1'b0;
      dbg_ar_addr <= 0;
      dbg_ar_count <= 0;
      dbg_ar_attrs <= 0;
    end else begin
      if (clear_error) protocol_error <= 1'b0;
      // A fresh violation wins over clearing the sticky bit in the same cycle.
      if (bad_control || (ar_take && !ar_legal)) protocol_error <= 1'b1;
      if (ar_take) begin
        active <= 1'b1;
        read_id <= s_arid;
        read_left <= ar_beats;
        read_addr <= s_araddr;
        read_step <= ar_step;
        read_incr <= (s_arburst == 2'b01);
        read_error <= !ar_legal;
        dbg_ar_addr <= s_araddr;
        dbg_ar_attrs <= {s_arid, s_arburst, s_arsize, s_arlen, 15'b0};
        dbg_ar_count <= dbg_ar_count + 1'b1;
      end else if (active && s_rready) begin
        if (read_left == 5'd1) active <= 1'b0;
        else begin
          read_left <= read_left - 1'b1;
          if (read_incr) read_addr <= read_addr + {26'b0, read_step};
        end
      end
    end
  end

  // --------------------------------------------------------- register reads
  wire [31:0] status_word = {
      1'b1, frame_error, protocol_error, 12'b0, staged_words,
      filling, fifo_has_data, frozen, active, 4'b0
  };
  wire debug_valid = frozen && (cfg_rd_addr >= 16'h2000) &&
      (cfg_rd_addr < 16'h2400) && (cfg_rd_addr[1:0] == 0) &&
      ({1'b0, cfg_rd_addr[9:5]} < staged_beats);

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      cfg_rdata <= 0;
      cfg_rdata_vld <= 1'b0;
    end else begin
      cfg_rdata_vld <= cfg_rd_en;
      if (debug_valid)
        cfg_rdata <= stage_mem[cfg_rd_addr[9:5]][cfg_rd_addr[4:2]*32 +: 32];
      else case (cfg_rd_addr)
        16'h1200: cfg_rdata <= status_word;
        16'h1204: cfg_rdata <= {23'b0, staged_words};
        16'h1208: cfg_rdata <= ID_MAGIC;
        16'h120c: cfg_rdata <= sequence_q;
        16'h1210: cfg_rdata <= APERTURE;
        16'h1214: cfg_rdata <= 32'd1024;
        16'h1218: cfg_rdata <= dbg_ar_addr;
        16'h121c: cfg_rdata <= dbg_ar_attrs;
        16'h1220: cfg_rdata <= dbg_ar_count;
        default: cfg_rdata <= 0;
      endcase
    end
  end
endmodule
