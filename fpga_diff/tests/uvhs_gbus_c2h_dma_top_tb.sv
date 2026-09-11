`timescale 1ns/1ps
`define CONFIG_DIFFTEST_HOST_AXIS_WIDTH 256

// Generated include contains the ACTUAL core decode, response mux, endpoint,
// router and complete DDR adapter instance. Only protected-IP host stimulus,
// an AXI-Lite BAR slave, and the DDR slave are modeled here.
module uvhs_gbus_c2h_dma_top_tb;
  reg gbus_host_clk = 0;
  always #5 gbus_host_clk = ~gbus_host_clk;
  wire uvhs_ddr_transport_clk = gbus_host_clk;
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

  reg [7:0] gbus_axi_arid = 0;
  reg [31:0] gbus_axi_araddr = 0;
  reg [3:0] gbus_axi_arlen = 0, gbus_axi_arcache = 0, gbus_axi_arqos = 0;
  reg [2:0] gbus_axi_arsize = 5, gbus_axi_arprot = 0;
  reg [1:0] gbus_axi_arburst = 1, gbus_axi_arlock = 0;
  reg gbus_axi_arvalid = 0, gbus_axi_rready = 0;
  wire gbus_axi_arready, gbus_axi_rvalid, gbus_axi_rlast;
  wire [7:0] gbus_axi_rid;
  wire [255:0] gbus_axi_rdata;
  wire [1:0] gbus_axi_rresp;

  // Tie off only stimulus on the unexercised write channel; its actual core
  // connections remain in the extracted adapter instance.
  wire [7:0] gbus_axi_awid = 0, gbus_axi_wid = 0;
  wire [31:0] gbus_axi_awaddr = 0, gbus_axi_wstrb = 0;
  wire [3:0] gbus_axi_awlen = 0, gbus_axi_awcache = 0, gbus_axi_awqos = 0;
  wire [2:0] gbus_axi_awsize = 5, gbus_axi_awprot = 0;
  wire [1:0] gbus_axi_awburst = 1, gbus_axi_awlock = 0;
  wire [255:0] gbus_axi_wdata = 0;
  wire gbus_axi_awvalid = 0, gbus_axi_wvalid = 0, gbus_axi_wlast = 0, gbus_axi_bready = 1;
  wire gbus_axi_awready, gbus_axi_wready, gbus_axi_bvalid;
  wire [7:0] gbus_axi_bid;
  wire [1:0] gbus_axi_bresp;
  wire [13:0] gbus_ddr_awid, gbus_ddr_arid;
  wire [33:0] gbus_ddr_awaddr, gbus_ddr_araddr;
  wire [7:0] gbus_ddr_awlen, gbus_ddr_arlen;
  wire [2:0] gbus_ddr_awsize, gbus_ddr_arsize, gbus_ddr_awprot, gbus_ddr_arprot;
  wire [1:0] gbus_ddr_awburst, gbus_ddr_arburst;
  wire gbus_ddr_awlock, gbus_ddr_arlock;
  wire [3:0] gbus_ddr_awcache, gbus_ddr_arcache, gbus_ddr_awqos, gbus_ddr_arqos;
  wire [3:0] gbus_ddr_awregion, gbus_ddr_arregion;
  wire gbus_ddr_awvalid, gbus_ddr_wlast, gbus_ddr_wvalid, gbus_ddr_bready;
  wire [255:0] gbus_ddr_wdata;
  wire [31:0] gbus_ddr_wstrb;
  wire gbus_ddr_awready = 1, gbus_ddr_wready = 1, gbus_ddr_bvalid = 0;
  wire [13:0] gbus_ddr_bid = 0;
  wire [1:0] gbus_ddr_bresp = 0;
  wire gbus_ddr_arvalid, gbus_ddr_rready;
  reg gbus_ddr_arready = 0, gbus_ddr_rlast = 0, gbus_ddr_rvalid = 0;
  reg [13:0] gbus_ddr_rid = 0;
  reg [255:0] gbus_ddr_rdata = 0;
  reg [1:0] gbus_ddr_rresp = 0;

  `include "core_generalbd_under_test.svh"

  integer errors = 0, axi_beats = 0, ddr_requests = 0;
  reg [31:0] bar[0:12];
  always @(posedge gbus_host_clk) if (rstn_sw4) begin
    if (gbus_c2h_cfg_rdata_vld && gbus_axil_cfg_rdata_vld)
      $fatal(1, "config response collision");
    if (XDMA_AXI_LITE_awvalid && XDMA_AXI_LITE_wvalid)
      bar[XDMA_AXI_LITE_awaddr[5:2]] <= XDMA_AXI_LITE_wdata;
    if (XDMA_AXI_LITE_rvalid && XDMA_AXI_LITE_rready) XDMA_AXI_LITE_rvalid <= 0;
    if (XDMA_AXI_LITE_arvalid) begin
      XDMA_AXI_LITE_rdata <= bar[XDMA_AXI_LITE_araddr[5:2]];
      XDMA_AXI_LITE_rvalid <= 1;
    end
    if (gbus_ddr_arvalid && gbus_ddr_arready) ddr_requests <= ddr_requests + 1;
    if (gbus_axi_rvalid && gbus_axi_rready) axi_beats <= axi_beats + 1;
  end

  task automatic check(input bit ok, input string text);
    if (!ok) begin
      errors++;
      if (errors <= 40) $display("FAIL %s", text);
    end
  endtask

  function automatic [255:0] payload(input integer beat);
    for (integer lane = 0; lane < 8; lane++)
      payload[lane*32 +: 32] = 32'ha5190000 ^ (32'(beat)*32'h10201) ^ (32'(lane)*32'h1234567);
  endfunction

  task automatic read_raw(input logic [15:0] addr, input bit expected,
                          output logic [31:0] value);
    integer seen;
    begin
      seen = 0; value = 0;
      @(negedge gbus_host_clk);
      gbus_cfg_rd_addr = addr; gbus_cfg_rd_en = 1;
      repeat (12) begin
        @(negedge gbus_host_clk);
        gbus_cfg_rd_en = 0;
        if (gbus_cfg_rdata_vld) begin seen++; value = gbus_cfg_rdata; end
      end
      check(seen == int'(expected), $sformatf("raw read %04h responses=%0d expected=%0d", addr, seen, expected));
    end
  endtask

  task automatic write_raw(input logic [15:0] addr, input logic [31:0] value);
    @(negedge gbus_host_clk);
    gbus_cfg_wr_addr = addr; gbus_cfg_wdata = value; gbus_cfg_wr_en = 1;
    @(negedge gbus_host_clk); gbus_cfg_wr_en = 0;
    // GeneralBD has no write-ready signal; wait for the AXI-Lite bridge's
    // serialized AW/W/B transaction before issuing the next command.
    repeat (10) @(negedge gbus_host_clk);
  endtask

  task automatic expect_reg(input logic [15:0] addr, input logic [31:0] wanted);
    reg [31:0] v;
    read_raw(addr, 1, v);
    check(v == wanted, $sformatf("raw register %04h got=%08h expected=%08h", addr, v, wanted));
  endtask

  task automatic send_frames;
    for (integer n = 0; n < 48; n++) begin
      @(negedge gbus_host_clk);
      difftest_to_host_axis_tdata = payload(n);
      difftest_to_host_axis_tvalid_io = 1;
      difftest_to_host_axis_tlast = (n % 24 == 23);
      #1;
      if (!gbus_c2h_sready) $fatal(1, "unexpected stream stall");
      @(posedge gbus_host_clk);
    end
    @(negedge gbus_host_clk);
    difftest_to_host_axis_tvalid_io = 0;
    repeat (5) @(negedge gbus_host_clk);
  endtask

  task automatic fill(input integer words);
    reg [31:0] v;
    integer polls;
    write_raw(16'h2204, 1);
    read_raw(16'h2200, 1, v);
    polls = 0;
    while (v[7] && polls < 100) begin read_raw(16'h2200, 1, v); polls++; end
    check(!v[7], "fill timeout");
    check(v[16:8] == 9'(words), $sformatf("fill word count got=%0d expected=%0d", v[16:8], words));
    check(v[5] == (words != 0) && !v[30], "publication frozen/framing status");
    expect_reg(16'h2204, 32'(words));
  endtask

  task automatic start_read(input logic [31:0] addr, input integer len,
                            input logic [1:0] burst, input logic [7:0] id);
    integer guard;
    @(negedge gbus_host_clk);
    gbus_axi_araddr = addr; gbus_axi_arlen = 4'(len); gbus_axi_arburst = burst;
    gbus_axi_arid = id; gbus_axi_arvalid = 1;
    guard = 0; #1;
    while (!gbus_axi_arready && guard < 100) begin
      @(negedge gbus_host_clk); #1; guard++;
    end
    if (!gbus_axi_arready) $fatal(1, "AR timeout");
    @(negedge gbus_host_clk); gbus_axi_arvalid = 0;
  endtask

  task automatic drain_read(input integer len, input logic [7:0] id,
                            input integer first, input bit fixed_burst,
                            input bit error_response);
    reg [255:0] wanted;
    integer before_beats;
    before_beats = axi_beats;
    for (integer n = 0; n <= len; n++) begin
      wanted = error_response ? 256'b0 : payload(first + (fixed_burst ? 0 : n));
      // Check every stalled cycle, including final RLAST, before handshake.
      repeat (3) begin
        @(negedge gbus_host_clk);
        check(gbus_axi_rvalid && gbus_axi_rid == id && gbus_axi_rlast == (n == len) &&
              gbus_axi_rresp == (error_response ? 2'b10 : 2'b00) && gbus_axi_rdata == wanted,
              $sformatf("AXI response/stability beat %0d", n));
      end
      gbus_axi_rready = 1;
      @(negedge gbus_host_clk); gbus_axi_rready = 0;
    end
    check(axi_beats - before_beats == len + 1, "exact AXI response count");
    check(!gbus_axi_rvalid, "extra AXI response");
  endtask

  task automatic local_read(input logic [31:0] addr, input integer len,
                            input integer first, input bit fixed_burst, input bit bad);
    integer saved_ddr;
    saved_ddr = ddr_requests;
    start_read(addr, len, fixed_burst ? 0 : 1, 8'hb7);
    drain_read(len, 8'hb7, first, fixed_burst, bad);
    check(ddr_requests == saved_ddr && !gbus_ddr_arvalid, "local aperture leaked to DDR");
  endtask

  task automatic ddr_read(input logic [31:0] addr, input logic [1:0] lock_bits);
    integer before_beats;
    @(negedge gbus_host_clk);
    gbus_axi_araddr = addr; gbus_axi_arid = 8'he3; gbus_axi_arlen = 3;
    gbus_axi_arsize = 4; gbus_axi_arburst = 0; gbus_axi_arlock = lock_bits;
    gbus_axi_arcache = 4'ha; gbus_axi_arprot = 3'h5; gbus_axi_arqos = 4'hc;
    gbus_axi_arvalid = 1; gbus_ddr_arready = 0;
    repeat (3) begin
      #1;
      check(gbus_ddr_arvalid && !gbus_axi_arready && !gbus_local_arvalid, "DDR route under AR stall");
      check(gbus_ddr_arid == 14'he3 && gbus_ddr_araddr == {2'b0, addr} &&
            gbus_ddr_arlen == 8'd3 && gbus_ddr_arsize == 4 && gbus_ddr_arburst == 0 &&
            gbus_ddr_arlock == lock_bits[0] && gbus_ddr_arcache == 4'ha &&
            gbus_ddr_arprot == 5 && gbus_ddr_arqos == 4'hc && gbus_ddr_arregion == 0,
            "DDR AR metadata");
      @(negedge gbus_host_clk);
    end
    gbus_ddr_arready = 1;
    @(negedge gbus_host_clk);
    gbus_axi_arvalid = 0; gbus_ddr_arready = 0;
    before_beats = axi_beats;
    // Change the live AR address while busy: response route must stay DDR.
    gbus_axi_araddr = 32'h10000000;
    for (integer n = 0; n < 4; n++) begin
      gbus_ddr_rvalid = 1; gbus_ddr_rid = 14'he3;
      gbus_ddr_rdata = payload(100+n); gbus_ddr_rresp = 2'b01;
      gbus_ddr_rlast = (n == 3);
      repeat (3) begin
        #1;
        check(gbus_axi_rvalid && gbus_axi_rid == 8'he3 && gbus_axi_rdata == payload(100+n) &&
              gbus_axi_rresp == 1 && gbus_axi_rlast == (n == 3) && !gbus_ddr_rready,
              "DDR response/stability/metadata");
        @(negedge gbus_host_clk);
      end
      gbus_axi_rready = 1;
      #1; check(gbus_ddr_rready && !gbus_local_rready, "DDR ready return path");
      @(negedge gbus_host_clk); gbus_axi_rready = 0;
    end
    gbus_ddr_rvalid = 0;
    check(axi_beats - before_beats == 4, "DDR response count");
    gbus_axi_arsize = 5;
  endtask

  reg [31:0] v;
  reg [255:0] beat_value;
  initial begin
    for (integer n = 0; n < 13; n++) bar[n] = 0;
    repeat (4) @(negedge gbus_host_clk);
    rstn_sw4 = 1; difftest_c2h_rstn = 1;
    repeat (4) @(negedge gbus_host_clk);
    expect_reg(16'h2200, 32'h80000000); expect_reg(16'h2204, 0);
    expect_reg(16'h2208, 32'h47424431); expect_reg(16'h220c, 0);
    expect_reg(16'h2210, 32'h10000000); expect_reg(16'h2214, 1024);
    for (integer n = 0; n < 13; n++) begin
      write_raw(16'h1000+16'(n*4), 32'hca000000+32'(n));
      expect_reg(16'h1000+16'(n*4), 32'hca000000+32'(n));
    end
    send_frames(); fill(256);
    // Keep these first debug checks early so mutation failures are explicit.
    read_raw(16'h3000, 1, v); beat_value = payload(0);
    check(v == beat_value[31:0], "first frozen debug word");
    expect_reg(16'h220c, 1);
    if (errors) $fatal(1, "DMA decode failed: %0d assertions", errors);
    $display("PASS live raw 2200..2214 decode, BAR bridge, first 1024-byte publication");

    local_read(32'h10000000, 15, 0, 0, 0);
    local_read(32'h10000200, 15, 16, 0, 0);
    local_read(32'h100003e0, 15, 31, 1, 0);
    for (integer n = 0; n < 256; n++) begin
      beat_value = payload(n/8);
      expect_reg(16'h3000+16'(n*4), beat_value[(n%8)*32 +: 32]);
    end
    write_raw(16'h2204, 1); // cannot replace frozen bank
    read_raw(16'h2200, 1, v); check(v[29] && v[5], "frozen FILL rejection");
    write_raw(16'h2204, 4);
    // AR and ACK accepted by their input interfaces on the same edge.
    @(negedge gbus_host_clk);
    gbus_axi_araddr = 32'h10000000; gbus_axi_arlen = 15;
    gbus_axi_arburst = 1; gbus_axi_arid = 8'h59; gbus_axi_arvalid = 1;
    gbus_cfg_wr_en = 1; gbus_cfg_wr_addr = 16'h2204; gbus_cfg_wdata = 2;
    @(negedge gbus_host_clk); gbus_axi_arvalid = 0; gbus_cfg_wr_en = 0;
    read_raw(16'h2200, 1, v); check(v[29] && v[5] && v[4], "ACK/AR race");
    drain_read(15, 8'h59, 0, 0, 0);
    write_raw(16'h2204, 4); write_raw(16'h2204, 2);
    expect_reg(16'h2204, 0); fill(128); expect_reg(16'h220c, 2);
    local_read(32'h10000000, 15, 32, 0, 0);
    for (integer n = 0; n < 128; n++) begin
      beat_value = payload(32+n/8);
      expect_reg(16'h3000+16'(n*4), beat_value[(n%8)*32 +: 32]);
    end
    expect_reg(16'h3200, 0); // outside published length
    local_read(32'h100001e0, 1, 0, 0, 1);
    local_read(32'h10000400, 15, 0, 0, 1);
    local_read(32'h10000fe0, 0, 0, 0, 1);
    write_raw(16'h2204, 4); write_raw(16'h2204, 2);
    fill(0); expect_reg(16'h220c, 2); expect_reg(16'h2200, 32'h80000000);
    $display("PASS 1536 distinct bytes from two 768-byte frames: 1024+512 banks, AXI/debug, ACK and bounds");

    // The AR diagnostics are decoded in the DMA branch.  They must report the
    // transaction the endpoint actually accepted, because the host cannot
    // otherwise tell an engine that ignored the requested offset from a
    // framing bug -- every window reuses the same absolute aperture.
    read_raw(16'h2218, 1, v); check(v == 32'h10000fe0, "last AR address not recorded");
    read_raw(16'h221c, 1, v);
    check(v[31:24] == 8'hb7, "last AR id not recorded");
    check(v[14:0] == 15'b0, "AR attribute padding not zero");
    read_raw(16'h2220, 1, v); check(v != 0, "AR count not recorded");
    // Reserved/raw aliases are not decoded by the DMA branch.
    read_raw(16'h1200, 0, v);
    read_raw(16'h2ffc, 0, v); read_raw(16'h3400, 0, v); read_raw(16'h0000, 0, v);
    ddr_read(32'h0fffffe0, 2'b10);
    ddr_read(32'h10001000, 2'b01);
    ddr_read(32'hf1234000, 2'b11);
    check(ddr_requests == 3, "only non-aperture reads reached DDR");
    if (errors) $fatal(1, "DMA top integration: %0d assertions", errors);
    $display("PASS actual router/adapter DDR boundaries, widened AR metadata, stalled R return path");
    $display("ALL PASS DMA top integration: %0d AXI response beats, %0d DDR requests", axi_beats, ddr_requests);
    $finish;
  end
  initial begin
    #2000000;
    $fatal(1, "DMA top integration watchdog");
  end
endmodule
