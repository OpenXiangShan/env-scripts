`timescale 1ns/1ps

module cpu_trace_axi_write_ram #(
  parameter integer DATA_WIDTH = 256,
  parameter integer ADDR_WIDTH = 34,
  parameter integer ID_WIDTH = 14,
  parameter integer MEM_WORDS = 4096,
  parameter integer STALL_PHASE = 0,
  parameter bit HEAVY_STALL = 1'b0
) (
  input  wire                        clk,
  input  wire                        rst_n,
  input  wire [ID_WIDTH-1:0]         s_axi_awid,
  input  wire [ADDR_WIDTH-1:0]       s_axi_awaddr,
  input  wire [7:0]                  s_axi_awlen,
  input  wire [2:0]                  s_axi_awsize,
  input  wire [1:0]                  s_axi_awburst,
  input  wire                        s_axi_awvalid,
  output wire                        s_axi_awready,
  input  wire [DATA_WIDTH-1:0]       s_axi_wdata,
  input  wire [DATA_WIDTH/8-1:0]     s_axi_wstrb,
  input  wire                        s_axi_wlast,
  input  wire                        s_axi_wvalid,
  output wire                        s_axi_wready,
  output reg  [ID_WIDTH-1:0]         s_axi_bid,
  output reg  [1:0]                  s_axi_bresp,
  output reg                         s_axi_bvalid,
  input  wire                        s_axi_bready
);
  localparam integer DATA_BYTES = DATA_WIDTH / 8;
  reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];
  reg [ADDR_WIDTH-1:0] write_addr;
  reg [8:0] beats_left;
  reg write_active;
  integer unsigned cycle_count;
  integer byte_idx;
  integer word_idx;

  assign s_axi_awready = rst_n && !write_active && !s_axi_bvalid &&
                         (HEAVY_STALL ?
                          (((cycle_count + STALL_PHASE) % 32) == 0) :
                          (((cycle_count + STALL_PHASE) % 7) != 2));
  assign s_axi_wready = rst_n && write_active &&
                        (HEAVY_STALL ?
                         (((cycle_count + STALL_PHASE) % 16) == 0) :
                         (((cycle_count + STALL_PHASE) % 5) != 1));

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_addr <= {ADDR_WIDTH{1'b0}};
      beats_left <= 9'd0;
      write_active <= 1'b0;
      s_axi_bid <= {ID_WIDTH{1'b0}};
      s_axi_bresp <= 2'b00;
      s_axi_bvalid <= 1'b0;
      cycle_count <= 0;
      for (word_idx = 0; word_idx < MEM_WORDS; word_idx = word_idx + 1)
        mem[word_idx] <= {DATA_WIDTH{1'b0}};
    end else begin
      cycle_count <= cycle_count + 1;
      if (s_axi_bvalid && s_axi_bready)
        s_axi_bvalid <= 1'b0;

      if (s_axi_awvalid && s_axi_awready) begin
        if (s_axi_awsize != 3'($clog2(DATA_BYTES)) || s_axi_awburst != 2'b01)
          $fatal(1, "bad DDR AXI command size=%0d burst=%0d", s_axi_awsize, s_axi_awburst);
        write_addr <= s_axi_awaddr;
        beats_left <= {1'b0, s_axi_awlen} + 9'd1;
        write_active <= 1'b1;
        s_axi_bid <= s_axi_awid;
      end

      if (s_axi_wvalid && s_axi_wready) begin
        if (!write_active)
          $fatal(1, "DDR W without AW");
        if (s_axi_wlast != (beats_left == 9'd1))
          $fatal(1, "DDR WLAST mismatch beats_left=%0d", beats_left);
        word_idx = int'(write_addr >> $clog2(DATA_BYTES));
        if (word_idx >= MEM_WORDS)
          $fatal(1, "DDR write address out of model range: %h", write_addr);
        for (byte_idx = 0; byte_idx < DATA_BYTES; byte_idx = byte_idx + 1)
          if (s_axi_wstrb[byte_idx])
            mem[word_idx][byte_idx*8 +: 8] <= s_axi_wdata[byte_idx*8 +: 8];
        write_addr <= write_addr + ADDR_WIDTH'(DATA_BYTES);
        beats_left <= beats_left - 9'd1;
        if (beats_left == 9'd1) begin
          write_active <= 1'b0;
          s_axi_bresp <= 2'b00;
          s_axi_bvalid <= 1'b1;
        end
      end
    end
  end
endmodule

module cpu_trace_axi_ddr_tb;
  localparam integer RECORD_WIDTH = 692;
  localparam integer AXI_DATA_WIDTH = 256;
  localparam integer ADDR_WIDTH = 34;
  localparam integer ID_WIDTH = 14;
  localparam integer RECORDS = 12;
  localparam [ADDR_WIDTH-1:0] META_BASE = 34'h0001_0000;
  localparam integer META_WORD_INDEX = 2048;

  reg in_clk = 1'b0;
  reg in_ctrl_clk = 1'b0;
  reg axi_clk = 1'b0;
  reg ddr_clk = 1'b0;
  reg in_resetn = 1'b0;
  reg axi_resetn = 1'b0;
  reg ddr_resetn = 1'b0;
  reg [RECORD_WIDTH-1:0] in_data;
  reg in_valid;
  wire in_ready;

  always #20 in_clk = ~in_clk;
  always #20 in_ctrl_clk = ~in_ctrl_clk;
  always #5 axi_clk = ~axi_clk;
  always #2.5 ddr_clk = ~ddr_clk;

  wire [ID_WIDTH-1:0] cvt_awid;
  wire [ADDR_WIDTH-1:0] cvt_awaddr;
  wire [7:0] cvt_awlen;
  wire [2:0] cvt_awsize;
  wire [1:0] cvt_awburst;
  wire cvt_awlock;
  wire [3:0] cvt_awcache;
  wire [2:0] cvt_awprot;
  wire [3:0] cvt_awqos;
  wire cvt_awvalid;
  wire cvt_awready;
  wire [511:0] cvt_wdata;
  wire [63:0] cvt_wstrb;
  wire cvt_wlast;
  wire cvt_wvalid;
  wire cvt_wready;
  wire [ID_WIDTH-1:0] cvt_bid;
  wire [1:0] cvt_bresp;
  wire cvt_bvalid;
  wire cvt_bready;

  wire [ID_WIDTH-1:0] m0_awid, m1_awid;
  wire [ADDR_WIDTH-1:0] m0_awaddr, m1_awaddr;
  wire [7:0] m0_awlen, m1_awlen;
  wire [2:0] m0_awsize, m1_awsize;
  wire [1:0] m0_awburst, m1_awburst;
  wire m0_awlock, m1_awlock;
  wire [3:0] m0_awcache, m1_awcache;
  wire [2:0] m0_awprot, m1_awprot;
  wire [3:0] m0_awqos, m1_awqos;
  wire m0_awvalid, m1_awvalid, m0_awready, m1_awready;
  wire [255:0] m0_wdata, m1_wdata;
  wire [31:0] m0_wstrb, m1_wstrb;
  wire m0_wlast, m1_wlast, m0_wvalid, m1_wvalid, m0_wready, m1_wready;
  wire [ID_WIDTH-1:0] m0_bid, m1_bid;
  wire [1:0] m0_bresp, m1_bresp;
  wire m0_bvalid, m1_bvalid, m0_bready, m1_bready;

  Difftest2AXI4 #(
    .INPUT_WIDTH(RECORD_WIDTH), .AXI_DATA_WIDTH(512),
    .AXI_ADDR_WIDTH(ADDR_WIDTH), .AXI_ID_WIDTH(ID_WIDTH),
    .BASE_ADDR(0), .FIFO_DEPTH(8), .MAX_BURST_LEN(1)
  ) u_converter (
    .in_clk(in_clk), .in_ctrl_clk(in_ctrl_clk), .in_resetn(in_resetn),
    .in_data(in_data), .in_valid(in_valid), .in_ready(in_ready),
    .axi_clk(axi_clk), .axi_resetn(axi_resetn),
    .m_axi_awid(cvt_awid), .m_axi_awaddr(cvt_awaddr), .m_axi_awlen(cvt_awlen),
    .m_axi_awsize(cvt_awsize), .m_axi_awburst(cvt_awburst), .m_axi_awlock(cvt_awlock),
    .m_axi_awcache(cvt_awcache), .m_axi_awprot(cvt_awprot), .m_axi_awqos(cvt_awqos),
    .m_axi_awvalid(cvt_awvalid), .m_axi_awready(cvt_awready),
    .m_axi_wdata(cvt_wdata), .m_axi_wstrb(cvt_wstrb), .m_axi_wlast(cvt_wlast),
    .m_axi_wvalid(cvt_wvalid), .m_axi_wready(cvt_wready),
    .m_axi_bid(cvt_bid), .m_axi_bresp(cvt_bresp), .m_axi_bvalid(cvt_bvalid),
    .m_axi_bready(cvt_bready)
  );

  ddr_memtest_cpu_axi_passive_top #(
    .AXI_DATA_WIDTH(AXI_DATA_WIDTH), .CPU_AXI_DATA_WIDTH(512),
    .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH), .FIFO_DEPTH(4),
    .BURST_LEN(4), .FLUSH_IDLE_CYCLES(16),
    .CH0_BASE_ADDR(0), .CH1_BASE_ADDR(0), .STROBE_META_BASE_ADDR(META_BASE),
    .CH0_AXI_ID(0), .CH1_AXI_ID(1), .STROBE_META_AXI_ID(2)
  ) u_backend (
    .clk1(axi_clk), .rst1_n(axi_resetn), .clk2(ddr_clk), .rst2_n(ddr_resetn),
    .enable(1'b1), .cfg_partial_wstrb({41'd0, 23'h7fffff}),
    .cfg_base_addr_load(1'b0), .cfg_ch0_base_addr(0), .cfg_ch1_base_addr(0),
    .cfg_strobe_meta_base_addr(META_BASE),
    .s_cpu_axi_awid(cvt_awid), .s_cpu_axi_awaddr(cvt_awaddr),
    .s_cpu_axi_awlen(cvt_awlen), .s_cpu_axi_awsize(cvt_awsize),
    .s_cpu_axi_awburst(cvt_awburst), .s_cpu_axi_awvalid(cvt_awvalid),
    .s_cpu_axi_awready(cvt_awready), .s_cpu_axi_wdata(cvt_wdata),
    .s_cpu_axi_wstrb(cvt_wstrb), .s_cpu_axi_wlast(cvt_wlast),
    .s_cpu_axi_wvalid(cvt_wvalid), .s_cpu_axi_wready(cvt_wready),
    .s_cpu_axi_bid(cvt_bid), .s_cpu_axi_bresp(cvt_bresp),
    .s_cpu_axi_bvalid(cvt_bvalid), .s_cpu_axi_bready(cvt_bready),
    .m0_axi_awid(m0_awid), .m0_axi_awaddr(m0_awaddr), .m0_axi_awlen(m0_awlen),
    .m0_axi_awsize(m0_awsize), .m0_axi_awburst(m0_awburst), .m0_axi_awlock(m0_awlock),
    .m0_axi_awcache(m0_awcache), .m0_axi_awprot(m0_awprot), .m0_axi_awqos(m0_awqos),
    .m0_axi_awvalid(m0_awvalid), .m0_axi_awready(m0_awready),
    .m0_axi_wdata(m0_wdata), .m0_axi_wstrb(m0_wstrb), .m0_axi_wlast(m0_wlast),
    .m0_axi_wvalid(m0_wvalid), .m0_axi_wready(m0_wready), .m0_axi_bid(m0_bid),
    .m0_axi_bresp(m0_bresp), .m0_axi_bvalid(m0_bvalid), .m0_axi_bready(m0_bready),
    .m1_axi_awid(m1_awid), .m1_axi_awaddr(m1_awaddr), .m1_axi_awlen(m1_awlen),
    .m1_axi_awsize(m1_awsize), .m1_axi_awburst(m1_awburst), .m1_axi_awlock(m1_awlock),
    .m1_axi_awcache(m1_awcache), .m1_axi_awprot(m1_awprot), .m1_axi_awqos(m1_awqos),
    .m1_axi_awvalid(m1_awvalid), .m1_axi_awready(m1_awready),
    .m1_axi_wdata(m1_wdata), .m1_axi_wstrb(m1_wstrb), .m1_axi_wlast(m1_wlast),
    .m1_axi_wvalid(m1_wvalid), .m1_axi_wready(m1_wready), .m1_axi_bid(m1_bid),
    .m1_axi_bresp(m1_bresp), .m1_axi_bvalid(m1_bvalid), .m1_axi_bready(m1_bready)
  );

  cpu_trace_axi_write_ram #(.STALL_PHASE(0)) ram0 (
    .clk(ddr_clk), .rst_n(ddr_resetn), .s_axi_awid(m0_awid), .s_axi_awaddr(m0_awaddr),
    .s_axi_awlen(m0_awlen), .s_axi_awsize(m0_awsize), .s_axi_awburst(m0_awburst),
    .s_axi_awvalid(m0_awvalid), .s_axi_awready(m0_awready), .s_axi_wdata(m0_wdata),
    .s_axi_wstrb(m0_wstrb), .s_axi_wlast(m0_wlast), .s_axi_wvalid(m0_wvalid),
    .s_axi_wready(m0_wready), .s_axi_bid(m0_bid), .s_axi_bresp(m0_bresp),
    .s_axi_bvalid(m0_bvalid), .s_axi_bready(m0_bready)
  );
  cpu_trace_axi_write_ram #(.STALL_PHASE(3), .HEAVY_STALL(1)) ram1 (
    .clk(ddr_clk), .rst_n(ddr_resetn), .s_axi_awid(m1_awid), .s_axi_awaddr(m1_awaddr),
    .s_axi_awlen(m1_awlen), .s_axi_awsize(m1_awsize), .s_axi_awburst(m1_awburst),
    .s_axi_awvalid(m1_awvalid), .s_axi_awready(m1_awready), .s_axi_wdata(m1_wdata),
    .s_axi_wstrb(m1_wstrb), .s_axi_wlast(m1_wlast), .s_axi_wvalid(m1_wvalid),
    .s_axi_wready(m1_wready), .s_axi_bid(m1_bid), .s_axi_bresp(m1_bresp),
    .s_axi_bvalid(m1_bvalid), .s_axi_bready(m1_bready)
  );

  function automatic [RECORD_WIDTH-1:0] make_record(input integer n);
    integer bit_idx;
    begin
      for (bit_idx = 0; bit_idx < RECORD_WIDTH; bit_idx = bit_idx + 1)
        make_record[bit_idx] =
          ((bit_idx * 13 + n * 17 + (bit_idx >> 3)) % 2) != 0;
    end
  endfunction

  task automatic send_record(input integer n);
    begin
      @(negedge in_clk);
      in_data = make_record(n);
      in_valid = 1'b1;
      while (!in_ready) @(negedge in_clk);
      @(negedge in_clk);
      in_valid = 1'b0;
    end
  endtask

  integer rec;
  reg [RECORD_WIDTH-1:0] expected;
  reg [255:0] expected_tail;
  reg [255:0] meta;
  integer timeout_cycles;
  integer meta_word;
  integer meta_slot;
  integer meta_code_count;
  integer meta_words_written;
  reg [1:0] observed_meta_code;
  reg saw_remote_backpressure = 1'b0;
  always @(posedge ddr_clk)
    if (u_backend.ch1_remote_valid && !u_backend.ch1_remote_ready)
      saw_remote_backpressure <= 1'b1;

  initial begin
    in_data = 0;
    in_valid = 0;
    repeat (8) @(posedge ddr_clk);
    ddr_resetn = 1'b1;
    repeat (3) @(posedge axi_clk);
    axi_resetn = 1'b1;
    repeat (3) @(posedge in_ctrl_clk);
    in_resetn = 1'b1;

    for (rec = 0; rec < RECORDS; rec = rec + 1)
      send_record(rec);

    timeout_cycles = 0;
    while ((u_backend.u_ch0_chunk_fifo.count != 0 ||
            u_backend.u_ch1_remote_source.tx_valid ||
            u_backend.u_strobe_meta_fifo.count != 0 ||
            u_backend.u_ch0_write_stream.state != 0 ||
            u_backend.u_ch1_remote_sink.u_write_stream.state != 0 ||
            u_backend.u_strobe_meta_write_stream.state != 0 ||
            u_backend.u_ch0_write_stream.buf_count != 0 ||
            u_backend.u_ch1_remote_sink.u_write_stream.buf_count != 0 ||
            u_backend.u_strobe_meta_write_stream.buf_count != 0 ||
            u_backend.u_ch0_write_stream.rd_pending ||
            u_backend.u_ch1_remote_sink.u_write_stream.rd_pending ||
            u_backend.u_strobe_meta_write_stream.rd_pending ||
            u_backend.u_ch0_write_stream.outstanding_count != 0 ||
            u_backend.u_ch1_remote_sink.u_write_stream.outstanding_count != 0 ||
            u_backend.u_strobe_meta_write_stream.outstanding_count != 0 ||
            u_backend.meta_fifo_wr_en ||
            u_backend.u_strobe_code_packer.code_count != 0) && timeout_cycles < 20000) begin
      @(posedge ddr_clk);
      timeout_cycles = timeout_cycles + 1;
    end
    if (timeout_cycles >= 20000)
      $fatal(1, "timeout draining combined trace pipeline");
    if (!saw_remote_backpressure)
      $fatal(1, "remote CH1 link backpressure was not exercised");

    for (rec = 0; rec < RECORDS; rec = rec + 1) begin
      expected = make_record(rec);
      expected_tail = 256'd0;
      expected_tail[179:0] = expected[691:512];
      if (ram0.mem[rec*2] !== expected[255:0])
        $fatal(1, "CH0 low mismatch record=%0d", rec);
      if (ram1.mem[rec*2] !== expected[511:256])
        $fatal(1, "CH1 high mismatch record=%0d", rec);
      if (ram0.mem[rec*2+1] !== expected_tail)
        $fatal(1, "CH0 tail mismatch record=%0d", rec);
      if (ram1.mem[rec*2+1] !== 256'd0)
        $fatal(1, "CH1 padding was written record=%0d", rec);
    end

    // Backpressure may make the packer flush a partial metadata word.  Decode
    // its explicit INVALID padding exactly as the board-side decoder does.
    meta_code_count = 0;
    meta_words_written = u_backend.u_strobe_meta_fifo.wr_count;
    if (meta_words_written < 1)
      $fatal(1, "no metadata words were written");
    for (meta_word = META_WORD_INDEX;
         meta_word < META_WORD_INDEX + meta_words_written;
         meta_word = meta_word + 1) begin
      meta = ram0.mem[meta_word];
      for (meta_slot = 0; meta_slot < 128; meta_slot = meta_slot + 1) begin
        observed_meta_code = meta[meta_slot*2 +: 2];
        if (observed_meta_code != 2'b10) begin
          if (meta_code_count >= RECORDS*2)
            $fatal(1, "unexpected extra metadata code=%b", observed_meta_code);
          if ((meta_code_count % 2) == 0 && observed_meta_code !== 2'b11)
            $fatal(1, "metadata full code mismatch index=%0d", meta_code_count);
          if ((meta_code_count % 2) == 1 && observed_meta_code !== 2'b00)
            $fatal(1, "metadata partial code mismatch index=%0d", meta_code_count);
          meta_code_count = meta_code_count + 1;
        end
      end
    end
    if (meta_code_count != RECORDS*2)
      $fatal(1, "metadata code count mismatch got=%0d expected=%0d",
             meta_code_count, RECORDS*2);

    $display("PASS cpu_trace_axi_ddr records=%0d metadata=%h", RECORDS, meta);
    $finish;
  end
endmodule
