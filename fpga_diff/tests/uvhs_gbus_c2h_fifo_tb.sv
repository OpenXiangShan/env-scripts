`timescale 1ns/1ps

// Functional test for the GBus C2H SRAM staging window.
//
// The real sender is Difftest2AXIs, which emits eight 96-byte packets per range
// as 24 beats of 32 bytes with tlast on the last beat.  This bench plays that
// stream in, then acts as the GBus host: poll status, start a fill, read the
// staging window, and check the reassembled bytes against the bytes that went
// in.  It covers two cases the host depends on:
//
//   1. a full window (24 beats in one go, 768 bytes out of 1 KiB)
//   2. a fragmented range (beats arrive in two bursts, so the fill ends early
//      on FIFO-dry and the host has to concatenate across fills)
//
// plus a negative case: tlast on the wrong beat must raise the sticky
// frame_error bit instead of silently shifting the host's range framing.
//
// All TB stimulus is driven on the falling edge and read back on the falling
// edge, so it never races the DUT's non-blocking updates.
module uvhs_gbus_c2h_fifo_tb;
  localparam integer DATA_WIDTH = 256;
  localparam integer KEEP_WIDTH = DATA_WIDTH / 8;
  localparam integer PACKET_BEATS = 24;
  localparam integer RANGE_BYTES = PACKET_BEATS * (DATA_WIDTH / 8);

  localparam [15:0] REG_STATUS = 16'h1200;
  localparam [15:0] REG_CTRL = 16'h1204;
  localparam [15:0] REG_ID = 16'h1208;
  localparam [15:0] REG_DATA = 16'h2000;
  localparam [31:0] ID_MAGIC = 32'h47425331;

  reg clk = 1'b0;
  reg rstn = 1'b0;
  reg stream_rstn = 1'b0;
  always #5 clk = ~clk; // 100 MHz

  reg  [DATA_WIDTH-1:0] s_tdata = '0;
  reg  [KEEP_WIDTH-1:0] s_tkeep = '1;
  reg                   s_tlast = 1'b0;
  reg                   s_tvalid = 1'b0;
  wire                  s_tready;

  reg         cfg_wr_en = 1'b0;
  reg  [15:0] cfg_wr_addr = 16'b0;
  reg  [31:0] cfg_wdata = 32'b0;
  reg         cfg_rd_en = 1'b0;
  reg  [15:0] cfg_rd_addr = 16'b0;
  wire [31:0] cfg_rdata;
  wire        cfg_rdata_vld;

  uvhs_gbus_c2h_fifo #(
      .AXIS_DATA_WIDTH(DATA_WIDTH),
      .PACKET_BEATS(PACKET_BEATS)
  ) dut (
      .clk(clk), .rstn(rstn), .stream_rstn(stream_rstn),
      .s_tdata(s_tdata), .s_tkeep(s_tkeep), .s_tlast(s_tlast), .s_tvalid(s_tvalid), .s_tready(s_tready),
      .cfg_wr_en(cfg_wr_en), .cfg_wr_addr(cfg_wr_addr), .cfg_wdata(cfg_wdata),
      .cfg_rd_en(cfg_rd_en), .cfg_rd_addr(cfg_rd_addr),
      .cfg_rdata(cfg_rdata), .cfg_rdata_vld(cfg_rdata_vld)
  );

  integer errors = 0;

  // The range content is a pure function of position, so a reassembled range
  // can be checked byte by byte without carrying an expected copy around.
  function automatic [7:0] expected_byte;
    input integer index;
    begin
      expected_byte = 8'((index * 7 + 3) & 32'hff);
    end
  endfunction

  function automatic [DATA_WIDTH-1:0] range_beat;
    input integer byte_offset;
    integer b;
    begin
      range_beat = '0;
      for (b = 0; b < KEEP_WIDTH; b = b + 1)
        range_beat[b*8 +: 8] = expected_byte(byte_offset + b);
    end
  endfunction

  task automatic read_reg;
    input  [15:0] addr;
    output [31:0] value;
    begin
      @(negedge clk);
      cfg_rd_addr = addr;
      cfg_rd_en = 1'b1;
      @(posedge clk);
      @(negedge clk);
      cfg_rd_en = 1'b0;
      value = cfg_rdata;
    end
  endtask

  task automatic write_ctrl;
    input [31:0] value;
    begin
      @(negedge clk);
      cfg_wr_addr = REG_CTRL;
      cfg_wdata = value;
      cfg_wr_en = 1'b1;
      @(posedge clk);
      @(negedge clk);
      cfg_wr_en = 1'b0;
    end
  endtask

  task automatic send_beats;
    input integer first_beat;
    input integer beat_count;
    input integer last_beat_of_range;
    integer i;
    reg accepted;
    begin
      for (i = 0; i < beat_count; i = i + 1) begin
        @(negedge clk);
        s_tdata = range_beat((first_beat + i) * KEEP_WIDTH);
        s_tvalid = 1'b1;
        s_tlast = ((first_beat + i) == last_beat_of_range);
        // s_tready depends only on FIFO pointers, so its value at this falling
        // edge is the value the DUT will see at the next rising edge.
        accepted = s_tready;
        @(posedge clk);
        while (!accepted) begin
          @(negedge clk);
          accepted = s_tready;
          @(posedge clk);
        end
      end
      @(negedge clk);
      s_tvalid = 1'b0;
      s_tlast = 1'b0;
    end
  endtask

  // Host side: drain whatever is staged, appending little-endian words, until
  // `wanted_bytes` have arrived.  Mirrors c2h_drain_sram_fifo().
  integer collected_bytes;
  reg [7:0] collected[0:4*RANGE_BYTES-1];
  integer fill_rounds;

  task automatic drain_until;
    input integer wanted_bytes;
    reg [31:0] st;
    reg [31:0] word;
    integer words;
    integer i;
    integer guard;
    begin
      guard = 0;
      while (collected_bytes < wanted_bytes && guard < 500) begin
        guard = guard + 1;
        read_reg(REG_STATUS, st);
        if (st[7]) // a fill is in progress
          continue;
        if (!st[6]) // nothing buffered yet
          continue;
        write_ctrl(32'h1);
        read_reg(REG_STATUS, st);
        while (st[7]) read_reg(REG_STATUS, st);
        words = (st >> 8) & 32'h1ff;
        for (i = 0; i < words; i = i + 1) begin
          read_reg(REG_DATA + 16'(i * 4), word);
          collected[collected_bytes]     = word[7:0];
          collected[collected_bytes + 1] = word[15:8];
          collected[collected_bytes + 2] = word[23:16];
          collected[collected_bytes + 3] = word[31:24];
          collected_bytes = collected_bytes + 4;
        end
        fill_rounds = fill_rounds + 1;
      end
    end
  endtask

  task automatic check_range;
    input string tag;
    integer i;
    integer bad;
    begin
      bad = 0;
      for (i = 0; i < RANGE_BYTES; i = i + 1)
        if (collected[i] !== expected_byte(i)) bad = bad + 1;
      if (bad == 0)
        $display("PASS %0s: %0d bytes reassembled byte-exact across %0d fill(s)", tag, RANGE_BYTES, fill_rounds);
      else begin
        $display("FAIL %0s: %0d/%0d bytes wrong", tag, bad, RANGE_BYTES);
        bad = 0;
        for (i = 0; i < RANGE_BYTES; i = i + 1)
          if (collected[i] !== expected_byte(i)) begin
            if (bad < 24) $display("  byte[%0d] got=%02x want=%02x", i, collected[i], expected_byte(i));
            bad = bad + 1;
          end
        errors = errors + 1;
      end
    end
  endtask

  reg [31:0] st;
  initial begin
    repeat (4) @(posedge clk);
    rstn = 1'b1;
    stream_rstn = 1'b1;
    repeat (4) @(posedge clk);

    read_reg(REG_STATUS, st);
    if (st[31] !== 1'b1) begin
      $display("FAIL: status[31] present is not set (status=0x%08x)", st);
      errors = errors + 1;
    end

    // The ID word is how the host tells "this window is decoded" from "this
    // window reads as zero".  Without it a decode mistake is invisible.
    read_reg(REG_ID, st);
    if (st !== ID_MAGIC) begin
      $display("FAIL: ID register read 0x%08x, expected 0x%08x", st, ID_MAGIC);
      errors = errors + 1;
    end else begin
      $display("PASS id: ID register reports 0x%08x", st);
    end

    // --- case 1: whole 24-beat range offered at once -----------------------
    collected_bytes = 0;
    fill_rounds = 0;
    fork
      send_beats(0, PACKET_BEATS, PACKET_BEATS - 1);
      drain_until(RANGE_BYTES);
    join
    check_range("full-window");

    // --- case 2: same range split across two bursts ------------------------
    // The second burst arrives after the host has already drained the first, so
    // the range has to be reassembled across fills.
    collected_bytes = 0;
    fill_rounds = 0;
    fork
      begin
        send_beats(0, 10, PACKET_BEATS - 1);
        repeat (200) @(posedge clk);
        send_beats(10, PACKET_BEATS - 10, PACKET_BEATS - 1);
      end
      drain_until(RANGE_BYTES);
    join
    check_range("fragmented-range");

    // --- case 3: tlast on the wrong beat must be reported ------------------
    read_reg(REG_STATUS, st);
    if (st[30] !== 1'b0) begin
      $display("FAIL: frame_error unexpectedly set after two good ranges (status=0x%08x)", st);
      errors = errors + 1;
    end
    send_beats(0, 4, 3); // tlast on beat 4 instead of beat 24
    read_reg(REG_STATUS, st);
    if (st[30] !== 1'b1) begin
      $display("FAIL: tlast on the wrong beat did not raise frame_error (status=0x%08x)", st);
      errors = errors + 1;
    end else begin
      $display("PASS frame-error: tlast on beat 4 raised the sticky frame_error bit");
    end

    // --- case 4: a stream reset mid-range must not poison the next range ----
    // The DiffTest stream enable drops whenever the host clears DIFFTEST_ENABLE,
    // which resets this module along with the FIFO.  A stale beat counter would
    // make the first range after re-enable look like a framing error.
    send_beats(0, 6, PACKET_BEATS - 1); // abandon a range halfway
    @(negedge clk);
    stream_rstn = 1'b0;
    repeat (4) @(posedge clk);
    @(negedge clk);
    stream_rstn = 1'b1;
    repeat (4) @(posedge clk);

    collected_bytes = 0;
    fill_rounds = 0;
    fork
      send_beats(0, PACKET_BEATS, PACKET_BEATS - 1);
      drain_until(RANGE_BYTES);
    join
    read_reg(REG_STATUS, st);
    if (st[30] !== 1'b0 || st[7] !== 1'b0) begin
      $display("FAIL: stream reset left stale state (status=0x%08x)", st);
      errors = errors + 1;
    end else if (collected_bytes == RANGE_BYTES) begin
      $display("PASS stream-reset: range after re-enable reassembled cleanly");
    end
    check_range("after-stream-reset");

    if (errors == 0) $display("ALL PASS");
    else $display("%0d FAILURES", errors);
    $finish;
  end

  // The bench must never hang on a stalled stream.
  initial begin
    #2000000;
    $display("FAIL: timeout");
    $finish;
  end
endmodule
