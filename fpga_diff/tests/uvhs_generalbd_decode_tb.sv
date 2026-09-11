`timescale 1ns/1ps
`define CONFIG_DIFFTEST_HOST_AXIS_WIDTH 256

// The include is generated verbatim from core_def_xdma.sv on EVERY test run.
// Stimulus enters at GeneralBD's raw host-address outputs, never at FIFO ports.
// The only mock is the AXI-Lite BAR slave; the bridge and C2H FIFO are real RTL.
module uvhs_generalbd_decode_tb;
  reg gbus_host_clk = 0;
  always #5 gbus_host_clk = ~gbus_host_clk;
  reg rstn_sw4 = 0, difftest_c2h_rstn = 0;
  reg [255:0] difftest_to_host_axis_tdata = 0;
  reg [31:0] difftest_to_host_axis_tkeep = '1;
  reg difftest_to_host_axis_tlast = 0, difftest_to_host_axis_tvalid_io = 0;
  wire gbus_c2h_sready;
  reg gbus_cfg_wr_en = 0, gbus_cfg_rd_en = 0;
  reg [15:0] gbus_cfg_wr_addr = 0, gbus_cfg_rd_addr = 0;
  reg [31:0] gbus_cfg_wdata = 0;
  wire [15:0] gbus_cfg_local_wr_addr, gbus_cfg_local_rd_addr;
  wire [31:0] gbus_cfg_rdata, gbus_c2h_cfg_rdata, gbus_axil_cfg_rdata;
  wire gbus_cfg_rdata_vld, gbus_c2h_cfg_rdata_vld, gbus_axil_cfg_rdata_vld;
  wire [31:0] XDMA_AXI_LITE_awaddr, XDMA_AXI_LITE_wdata, XDMA_AXI_LITE_araddr;
  wire [3:0] XDMA_AXI_LITE_wstrb;
  wire [2:0] XDMA_AXI_LITE_awprot, XDMA_AXI_LITE_arprot;
  wire XDMA_AXI_LITE_awvalid, XDMA_AXI_LITE_wvalid, XDMA_AXI_LITE_bready;
  wire XDMA_AXI_LITE_arvalid, XDMA_AXI_LITE_rready;
  wire XDMA_AXI_LITE_awready = 1, XDMA_AXI_LITE_wready = 1;
  wire XDMA_AXI_LITE_arready = 1, XDMA_AXI_LITE_bvalid = 1;
  wire [1:0] XDMA_AXI_LITE_bresp = 0, XDMA_AXI_LITE_rresp = 0;
  reg [31:0] XDMA_AXI_LITE_rdata = 0;
  reg XDMA_AXI_LITE_rvalid = 0;

  `include "core_generalbd_under_test.svh"

  reg [31:0] bar[0:12];
  integer bar_reads = 0, bar_writes = 0;
  integer errors = 0, hole_responses = 0, hole_side_effects = 0;
  integer response_count = 0;
  always @(posedge gbus_host_clk) begin
    if (rstn_sw4) begin
      if (gbus_cfg_rdata_vld) response_count <= response_count + 1;
      if (gbus_c2h_cfg_rdata_vld && gbus_axil_cfg_rdata_vld)
        $fatal(1, "response collision between C2H and BAR");
      if (XDMA_AXI_LITE_awvalid && XDMA_AXI_LITE_wvalid) begin
        if (XDMA_AXI_LITE_awaddr > 32'h30 || XDMA_AXI_LITE_awaddr[1:0] != 0)
          $fatal(1, "BAR write address translation failed: %h", XDMA_AXI_LITE_awaddr);
        if (XDMA_AXI_LITE_wstrb != 4'hf) $fatal(1, "BAR byte strobes incorrect");
        bar[XDMA_AXI_LITE_awaddr >> 2] <= XDMA_AXI_LITE_wdata;
        bar_writes <= bar_writes + 1;
      end
      if (XDMA_AXI_LITE_rvalid && XDMA_AXI_LITE_rready) XDMA_AXI_LITE_rvalid <= 0;
      if (XDMA_AXI_LITE_arvalid) begin
        if (XDMA_AXI_LITE_araddr > 32'h30 || XDMA_AXI_LITE_araddr[1:0] != 0)
          $fatal(1, "BAR read address translation failed: %h", XDMA_AXI_LITE_araddr);
        XDMA_AXI_LITE_rdata <= bar[XDMA_AXI_LITE_araddr >> 2];
        XDMA_AXI_LITE_rvalid <= 1;
        bar_reads <= bar_reads + 1;
      end
    end
  end

  task automatic check(input bit ok, input string label_text);
    if (!ok) begin
      errors++;
      if (errors <= 20) $display("FAIL %s", label_text);
    end
  endtask

  // Count responses, including delayed/duplicate ones. Sampling falling edges
  // observes completed NBA updates. No unbounded waits, even on broken decode.
  task automatic read_raw(input logic [15:0] addr, input bit expect_response,
                          output logic [31:0] value);
    integer seen;
    begin
      seen = 0;
      value = 0;
      @(negedge gbus_host_clk);
      gbus_cfg_rd_addr = addr;
      gbus_cfg_rd_en = 1;
      repeat (12) begin
        @(negedge gbus_host_clk);
        gbus_cfg_rd_en = 0;
        if (gbus_cfg_rdata_vld) begin
          value = gbus_cfg_rdata;
          seen++;
        end
      end
      if (!expect_response && seen != 0) hole_responses++;
      check(seen == (expect_response ? 1 : 0),
            $sformatf("raw read %04h responses=%0d expected=%0d", addr, seen, expect_response));
    end
  endtask

  task automatic write_raw(input logic [15:0] addr, input logic [31:0] value);
    integer before_responses;
    begin
      @(negedge gbus_host_clk);
      before_responses = response_count;
      gbus_cfg_wr_addr = addr;
      gbus_cfg_wdata = value;
      gbus_cfg_wr_en = 1;
      @(negedge gbus_host_clk);
      gbus_cfg_wr_en = 0;
      repeat (10) @(negedge gbus_host_clk);
      check(response_count == before_responses, "write unexpectedly produced a read response");
    end
  endtask

  // Position-dependent 32-bit mixing avoids the old bench's 256-byte periodic
  // pattern, which could hide loss/repetition/reordering of whole stream chunks.
  function automatic [7:0] expected_byte(input integer position);
    reg [31:0] x;
    begin
      x = 32'(position) + 32'h9e3779b9;
      x = (x ^ (x >> 16)) * 32'h85ebca6b;
      x = (x ^ (x >> 13)) * 32'hc2b2ae35;
      x = x ^ (x >> 16);
      expected_byte = x[7:0];
    end
  endfunction

  task automatic send_beats(input integer first, input integer count);
    integer waited;
    begin
      for (integer n = first; n < first + count; n++) begin
        @(negedge gbus_host_clk);
        for (integer b = 0; b < 32; b++)
          difftest_to_host_axis_tdata[b*8 +: 8] = expected_byte(n*32+b);
        difftest_to_host_axis_tvalid_io = 1;
        difftest_to_host_axis_tlast = (n % 24 == 23);
        waited = 0;
        // Ready depends on pointers, not valid; wait before the accepting edge.
        while (!gbus_c2h_sready && waited < 1000) begin
          @(negedge gbus_host_clk);
          waited++;
        end
        if (!gbus_c2h_sready) $fatal(1, "stream acceptance timeout");
        @(posedge gbus_host_clk);
      end
      @(negedge gbus_host_clk);
      difftest_to_host_axis_tvalid_io = 0;
      difftest_to_host_axis_tlast = 0;
      repeat (12) @(negedge gbus_host_clk);
    end
  endtask

  integer checked_bytes = 0;
  task automatic fill_and_check(input integer expected_words, input integer byte_offset);
    reg [31:0] status_value, word_value;
    integer polls;
    begin
      write_raw(16'h2204, 1);
      read_raw(16'h2200, 1, status_value);
      polls = 0;
      while (status_value[7] && polls < 100) begin
        read_raw(16'h2200, 1, status_value);
        polls++;
      end
      check(!status_value[7], "fill completion timeout");
      check(status_value[16:8] == 9'(expected_words),
            $sformatf("fill word count got=%0d expected=%0d", status_value[16:8], expected_words));
      check(!status_value[30], "unexpected frame error across packet boundary");
      read_raw(16'h2204, 1, word_value);
      check(word_value == 32'(expected_words), "control readback staged count");
      for (integer w = 0; w < expected_words; w++) begin
        read_raw(16'h3000 + 16'(w*4), 1, word_value);
        for (integer b = 0; b < 4; b++) begin
          check(word_value[b*8 +: 8] == expected_byte(byte_offset + w*4 + b),
                $sformatf("byte order/content at %0d got=%02h expected=%02h",
                          byte_offset+w*4+b, word_value[b*8 +: 8], expected_byte(byte_offset+w*4+b)));
          checked_bytes++;
        end
      end
    end
  endtask

  // Host uses aligned 32-bit transactions. Sweep all 16-bit aligned raw
  // addresses, including underflow, old local aliases, and both window edges.
  function automatic bit mapped(input integer addr);
    mapped = ((addr >= 'h1000 && addr <= 'h1030) ||
              addr == 'h2200 || addr == 'h2204 || addr == 'h2208 ||
              (addr >= 'h3000 && addr <= 'h33fc));
  endfunction

  reg [31:0] value, before_status;
  integer checkpoint, saved_reads, saved_writes;
  initial begin
    for (integer i = 0; i < 13; i++) bar[i] = 32'hb0000000 + 32'(i);
    repeat (4) @(negedge gbus_host_clk);
    rstn_sw4 = 1;
    difftest_c2h_rstn = 1;
    repeat (4) @(negedge gbus_host_clk);
    checkpoint = errors;
    read_raw(16'h2208, 1, value);
    check(value == 32'h47425331, "raw ID 0x2208 magic (legacy GBS1)");
    read_raw(16'h2200, 1, value);
    check(value == 32'h80000000, "raw status reset/present");
    read_raw(16'h2204, 1, value);
    check(value == 0, "raw control reset count");
    if (errors == checkpoint) $display("PASS raw status/control/ID 2200/2204/2208");

    checkpoint = errors;
    for (integer i = 0; i < 13; i++) begin
      write_raw(16'h1000 + 16'(i*4), 32'hca000000 + 32'(i));
      read_raw(16'h1000 + 16'(i*4), 1, value);
      check(value == 32'hca000000 + 32'(i), "BAR write/read and local address translation");
    end
    check(bar_writes == 13 && bar_reads == 13, "all 13 BAR words reached bridge");
    if (errors == checkpoint) $display("PASS BAR 1000..1030 reads/writes through actual bridge");

    checkpoint = errors;
    send_beats(0, 48); // Two complete 768-byte tlast ranges; 16 DiffTest packets.
    read_raw(16'h2200, 1, value);
    check(value[6] && value[16:8] == 0, "payload buffered before control start");
    write_raw(16'h2200, 3); // Read-only status and ID must not start/drain.
    write_raw(16'h2208, 3);
    write_raw(16'h2204, 0);
    read_raw(16'h2200, 1, value);
    check(value[6] && !value[7] && value[16:8] == 0, "read-only/zero control writes have no effect");
    fill_and_check(256, 0); // Bit 16 must represent 256, not truncate to zero.
    read_raw(16'h2200, 1, value);
    check(value[6], "second range remainder retained after full fill");
    fill_and_check(128, 1024); // Crosses range 2's boundary across two fills.
    read_raw(16'h2200, 1, value);
    check(!value[6] && !value[7] && !value[30], "two ranges completely consumed without frame errors");
    check(checked_bytes == 1536, "exactly two ranges checked");
    if (errors == checkpoint) $display("PASS 1536 distinct bytes, 2 ranges, 256+128 words across fills");

    checkpoint = errors;
    send_beats(48, 24);
    write_raw(16'h2204, 2);
    repeat (60) @(negedge gbus_host_clk);
    read_raw(16'h2200, 1, value);
    check(value == 32'h80000000, "drain discards payload, clears count, and terminates");
    fill_and_check(0, 0);
    send_beats(72, 24);
    fill_and_check(192, 2304);
    if (errors == checkpoint) $display("PASS drain control, empty fill, clean next range");

    // Current top-level intentionally decodes the reserved 3400..3ffc region
    // as zero. Keep strict no-response assertions by default, but allow valid
    // host-address functionality to be tested independently during a build.
    if ($test$plusargs("functional_only")) begin
      if (errors != 0) $fatal(1, "GeneralBD functional regression: %0d assertion failures", errors);
      $display("ALL PASS GeneralBD functional regression (strict holes SKIPPED)");
      $finish;
    end
    checkpoint = errors;
    read_raw(16'h2200, 1, before_status);
    saved_reads = bar_reads;
    saved_writes = bar_writes;
    for (integer addr = 0; addr <= 'hfffc; addr += 4) begin
      if (!mapped(addr)) begin
        read_raw(16'(addr), 0, value);
        // Catch enable leakage even if the downstream module ignores a write.
        @(negedge gbus_host_clk);
        gbus_cfg_wr_addr = 16'(addr);
        gbus_cfg_wdata = 3;
        gbus_cfg_wr_en = 1;
        #1;
        if (gbus_c2h_cfg_wr_en || gbus_axil_cfg_wr_en) begin
          hole_side_effects++;
          check(0, $sformatf("hole write enabled a target at %04h", addr));
        end
        @(negedge gbus_host_clk);
        gbus_cfg_wr_en = 0;
        repeat (10) @(negedge gbus_host_clk);
      end
    end
    check(bar_reads == saved_reads && bar_writes == saved_writes, "holes must not reach BAR");
    read_raw(16'h2200, 1, value);
    check(value == before_status, "hole writes must not change C2H state");
    $display("Aligned address sweep: %0d hole addresses responded, %0d hole write enables",
             hole_responses, hole_side_effects);
    if (errors == checkpoint) $display("PASS all aligned holes and boundaries have no responses/side effects");
    if (errors) $fatal(1, "GeneralBD decode regression: %0d assertion failures", errors);
    $display("ALL PASS GeneralBD decode regression");
    $finish;
  end

  initial begin
    #20000000;
    $fatal(1, "GeneralBD decode regression watchdog timeout");
  end
endmodule
