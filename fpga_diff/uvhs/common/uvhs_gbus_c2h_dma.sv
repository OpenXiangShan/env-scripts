`timescale 1ns/1ps

// The stream has already crossed into clk. Published bank bytes remain immutable
// until ACK; an accepted AXI response survives stream reset but not fabric reset.
module uvhs_gbus_c2h_dma #(
    parameter integer AXIS_DATA_WIDTH = 256,
    parameter integer STAGE_WORDS = 256
) (
    input wire clk,
    input wire rstn,
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
    output wire [255:0] s_rdata,
    output wire [1:0] s_rresp,
    output wire s_rlast,
    output wire s_rvalid,
    input wire s_rready
);
  localparam integer STAGE_BEATS = 32;
  // GBus reserves the upper four address bits for port selection.
  localparam [31:0] APERTURE = 32'h0fff_f000;
  localparam [31:0] ID_MAGIC = 32'h4742_4431;
  initial begin
    if (AXIS_DATA_WIDTH != 256 || STAGE_WORDS != 256)
      $error("GBD1 requires 256-bit stream data and a 256-word bank");
  end

  wire stream_resetn = rstn & stream_rstn;
  reg [255:0] stage_mem [0:STAGE_BEATS-1];
  reg [5:0] staged_beats;
  reg filling, frozen;
  reg [31:0] sequence_q;
  reg frame_error, protocol_error;
  reg [4:0] frame_beat;
  reg active;
  reg [7:0] read_id;
  reg [4:0] read_left;
  reg [31:0] read_addr;
  reg [5:0] read_step;
  reg read_incr, read_error;
  reg [31:0] dbg_ar_addr, dbg_ar_count, dbg_ar_attrs;
  reg [31:0] dbg_ctrl_count, dbg_ctrl_data;
  reg dbg_bad_ctrl_valid;
  reg [31:0] dbg_bad_ctrl_data, dbg_bad_ctrl_state, dbg_bad_ctrl_count;

  wire [8:0] staged_words = {staged_beats, 3'b000};
  wire ar_take = s_arvalid && s_arready;
  wire ctrl_wr = cfg_wr_en && (cfg_wr_addr == 16'h1204);
  wire fill_request = ctrl_wr && cfg_wdata[0];
  wire ack_request = ctrl_wr && cfg_wdata[1];
  wire clear_error = ctrl_wr && cfg_wdata[2];
  // AR wins over ACK/FILL, including a request that will return SLVERR.
  wire fill_ok = fill_request && !ack_request && stream_resetn &&
                 !filling && !frozen && !active && !ar_take;
  wire ack_ok = ack_request && !fill_request && stream_resetn &&
                frozen && !filling && !active && !ar_take;
  wire bad_control = stream_resetn &&
                     ((fill_request && !fill_ok) || (ack_request && !ack_ok));

  // First rejected control evidence survives stream reset and explicit error clear.
  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      dbg_ctrl_count <= 0;
      dbg_ctrl_data <= 0;
      dbg_bad_ctrl_valid <= 1'b0;
      dbg_bad_ctrl_data <= 0;
      dbg_bad_ctrl_state <= 0;
      dbg_bad_ctrl_count <= 0;
    end else begin
      if (ctrl_wr) begin
        dbg_ctrl_count <= dbg_ctrl_count + 1'b1;
        dbg_ctrl_data <= cfg_wdata;
      end
      if (bad_control && !dbg_bad_ctrl_valid) begin
        dbg_bad_ctrl_valid <= 1'b1;
        dbg_bad_ctrl_data <= cfg_wdata;
        dbg_bad_ctrl_state <= {16'b0, staged_beats, fill_ok, ack_ok,
                              s_tlast, ar_take, s_tvalid, stream_rstn,
                              active, frozen, filling, frame_error};
        dbg_bad_ctrl_count <= dbg_ctrl_count + 1'b1;
      end
    end
  end

  assign s_tready = stream_resetn && filling && !frozen && !active;
  wire take_beat = s_tvalid && s_tready;
  wire bank_full = take_beat && (staged_beats == 6'd31);
  wire frame_end = take_beat && s_tlast && (frame_beat == 5'd23) &&
                   (&s_tkeep) && !frame_error;

  always @(posedge clk or negedge stream_resetn) begin
    if (!stream_resetn) begin
      frame_error <= 1'b0;
      frame_beat <= 0;
    end else if (take_beat) begin
      if (!(&s_tkeep) || (s_tlast != (frame_beat == 5'd23)))
        frame_error <= 1'b1;
      frame_beat <= (frame_beat == 5'd23) ? 5'd0 : frame_beat + 1'b1;
    end
  end

  always @(posedge clk or negedge stream_resetn) begin
    if (!stream_resetn) begin
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
      // VALID gaps cannot release a partial frame. A finite valid TLAST can.
      if (bank_full || frame_end) begin
        filling <= 1'b0;
        frozen <= 1'b1;
        sequence_q <= sequence_q + 1'b1;
      end
    end
  end

  // Bank RAM is never reset; metadata gates visibility and active blocks reuse.
  always @(posedge clk) begin
    if (take_beat) stage_mem[staged_beats[4:0]] <= s_tdata;
  end

  wire [5:0] ar_step = 6'd1 << s_arsize;
  wire [4:0] ar_beats = {1'b0, s_arlen} + 5'd1;
  wire [32:0] ar_span = (s_arburst == 2'b01) ? ({28'b0, ar_beats} << s_arsize)
                                             : {27'b0, ar_step};
  wire [32:0] ar_end = {1'b0, s_araddr} + ar_span;
  wire [32:0] published_end = {1'b0, APERTURE} + {22'b0, staged_beats, 5'b0};
  wire [31:0] ar_step_mask = {26'b0, ar_step} - 32'd1;
  wire ar_legal = stream_resetn && frozen && !filling &&
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

  wire [31:0] status_word = {
      1'b1, frame_error, protocol_error, 12'b0, staged_words,
      filling, s_tvalid, frozen, active, 4'b0
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
        16'h1224: cfg_rdata <= dbg_ctrl_count;
        16'h1228: cfg_rdata <= dbg_ctrl_data;
        16'h122c: cfg_rdata <= dbg_bad_ctrl_data;
        16'h1230: cfg_rdata <= {dbg_bad_ctrl_valid, dbg_bad_ctrl_state[30:0]};
        16'h1234: cfg_rdata <= dbg_bad_ctrl_count;
        default: cfg_rdata <= 0;
      endcase
    end
  end
endmodule
