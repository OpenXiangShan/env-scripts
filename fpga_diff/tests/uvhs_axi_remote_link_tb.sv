`timescale 1ns/1ps

module uvhs_axi_remote_link_tb;
  localparam int DW = 256;
  localparam int AW = 34;
  localparam int IW = 14;
  localparam int FW = 80;
  localparam int PW = 320;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  integer cycle = 0;
  integer errors = 0;
  always #5 clk = ~clk;
  always @(posedge clk) if (rst_n) cycle <= cycle + 1;

  reg [IW-1:0] s_awid; reg [AW-1:0] s_awaddr; reg [7:0] s_awlen;
  reg [2:0] s_awsize; reg [1:0] s_awburst; reg s_awlock;
  reg [3:0] s_awcache; reg [2:0] s_awprot; reg [3:0] s_awqos;
  reg [3:0] s_awregion; reg s_awvalid; wire s_awready;
  reg [DW-1:0] s_wdata; reg [DW/8-1:0] s_wstrb; reg s_wlast;
  reg s_wvalid; wire s_wready;
  wire [IW-1:0] s_bid; wire [1:0] s_bresp; wire s_bvalid;
  reg s_bready;
  reg [IW-1:0] s_arid; reg [AW-1:0] s_araddr; reg [7:0] s_arlen;
  reg [2:0] s_arsize; reg [1:0] s_arburst; reg s_arlock;
  reg [3:0] s_arcache; reg [2:0] s_arprot; reg [3:0] s_arqos;
  reg [3:0] s_arregion; reg s_arvalid; wire s_arready;
  wire [IW-1:0] s_rid; wire [DW-1:0] s_rdata; wire [1:0] s_rresp;
  wire s_rlast; wire s_rvalid; reg s_rready;

  wire [FW-1:0] req_src_data, rsp_sink_data;
  wire req_src_valid, req_src_ready, rsp_sink_valid, rsp_sink_ready;
  wire req_sink_valid, req_sink_ready, rsp_src_valid, rsp_src_ready;
  wire req_gate = (cycle % 7 != 2) && (cycle % 7 != 3);
  wire rsp_gate = (cycle % 9 != 4) && (cycle % 9 != 5);
  assign req_src_ready = req_sink_ready && req_gate;
  assign req_sink_valid = req_src_valid && req_gate;
  assign rsp_sink_ready = rsp_src_ready && rsp_gate;
  assign rsp_src_valid = rsp_sink_valid && rsp_gate;

  wire [IW-1:0] m_awid; wire [AW-1:0] m_awaddr; wire [7:0] m_awlen;
  wire [2:0] m_awsize; wire [1:0] m_awburst; wire m_awlock;
  wire [3:0] m_awcache; wire [2:0] m_awprot; wire [3:0] m_awqos;
  wire [3:0] m_awregion; wire m_awvalid; wire m_awready;
  wire [DW-1:0] m_wdata; wire [DW/8-1:0] m_wstrb; wire m_wlast;
  wire m_wvalid; wire m_wready;
  reg [IW-1:0] m_bid; reg [1:0] m_bresp; reg m_bvalid; wire m_bready;
  wire [IW-1:0] m_arid; wire [AW-1:0] m_araddr; wire [7:0] m_arlen;
  wire [2:0] m_arsize; wire [1:0] m_arburst; wire m_arlock;
  wire [3:0] m_arcache; wire [2:0] m_arprot; wire [3:0] m_arqos;
  wire [3:0] m_arregion; wire m_arvalid; wire m_arready;
  reg [IW-1:0] m_rid; reg [DW-1:0] m_rdata; reg [1:0] m_rresp;
  reg m_rlast; reg m_rvalid; wire m_rready;

  // Exercise independent backpressure at the DDR and CPU interfaces too.
  assign m_awready = (cycle % 5 != 1);
  // Model a legal but strict DDR slave which will not accept write data until
  // its address has arrived.  This catches W-before-AW transport deadlocks.
  assign m_wready  = (w_seen < aw_seen * 2) && (cycle % 6 != 2);
  assign m_arready = (cycle % 4 != 1);
  always @(*) begin
    s_bready = (cycle % 5 != 3);
    s_rready = (cycle % 6 != 4);
  end

  uvhs_axi_remote_source #(
    .DATA_WIDTH(DW), .ADDR_WIDTH(AW), .ID_WIDTH(IW),
    .FLIT_WIDTH(FW), .PACKET_WIDTH(PW)
  ) src (
    .clk(clk), .rst_n(rst_n),
    .s_axi_awid(s_awid), .s_axi_awaddr(s_awaddr), .s_axi_awlen(s_awlen),
    .s_axi_awsize(s_awsize), .s_axi_awburst(s_awburst), .s_axi_awlock(s_awlock),
    .s_axi_awcache(s_awcache), .s_axi_awprot(s_awprot), .s_axi_awqos(s_awqos),
    .s_axi_awregion(s_awregion), .s_axi_awvalid(s_awvalid), .s_axi_awready(s_awready),
    .s_axi_wdata(s_wdata), .s_axi_wstrb(s_wstrb), .s_axi_wlast(s_wlast),
    .s_axi_wvalid(s_wvalid), .s_axi_wready(s_wready),
    .s_axi_bid(s_bid), .s_axi_bresp(s_bresp), .s_axi_bvalid(s_bvalid), .s_axi_bready(s_bready),
    .s_axi_arid(s_arid), .s_axi_araddr(s_araddr), .s_axi_arlen(s_arlen),
    .s_axi_arsize(s_arsize), .s_axi_arburst(s_arburst), .s_axi_arlock(s_arlock),
    .s_axi_arcache(s_arcache), .s_axi_arprot(s_arprot), .s_axi_arqos(s_arqos),
    .s_axi_arregion(s_arregion), .s_axi_arvalid(s_arvalid), .s_axi_arready(s_arready),
    .s_axi_rid(s_rid), .s_axi_rdata(s_rdata), .s_axi_rresp(s_rresp),
    .s_axi_rlast(s_rlast), .s_axi_rvalid(s_rvalid), .s_axi_rready(s_rready),
    .req_tx_data(req_src_data), .req_tx_valid(req_src_valid), .req_tx_ready(req_src_ready),
    .rsp_rx_data(rsp_sink_data), .rsp_rx_valid(rsp_src_valid), .rsp_rx_ready(rsp_src_ready)
  );

  uvhs_axi_remote_sink #(
    .DATA_WIDTH(DW), .ADDR_WIDTH(AW), .ID_WIDTH(IW),
    .FLIT_WIDTH(FW), .PACKET_WIDTH(PW)
  ) sink (
    .clk(clk), .rst_n(rst_n),
    .req_rx_data(req_src_data), .req_rx_valid(req_sink_valid), .req_rx_ready(req_sink_ready),
    .rsp_tx_data(rsp_sink_data), .rsp_tx_valid(rsp_sink_valid), .rsp_tx_ready(rsp_sink_ready),
    .m_axi_awid(m_awid), .m_axi_awaddr(m_awaddr), .m_axi_awlen(m_awlen),
    .m_axi_awsize(m_awsize), .m_axi_awburst(m_awburst), .m_axi_awlock(m_awlock),
    .m_axi_awcache(m_awcache), .m_axi_awprot(m_awprot), .m_axi_awqos(m_awqos),
    .m_axi_awregion(m_awregion), .m_axi_awvalid(m_awvalid), .m_axi_awready(m_awready),
    .m_axi_wdata(m_wdata), .m_axi_wstrb(m_wstrb), .m_axi_wlast(m_wlast),
    .m_axi_wvalid(m_wvalid), .m_axi_wready(m_wready),
    .m_axi_bid(m_bid), .m_axi_bresp(m_bresp), .m_axi_bvalid(m_bvalid), .m_axi_bready(m_bready),
    .m_axi_arid(m_arid), .m_axi_araddr(m_araddr), .m_axi_arlen(m_arlen),
    .m_axi_arsize(m_arsize), .m_axi_arburst(m_arburst), .m_axi_arlock(m_arlock),
    .m_axi_arcache(m_arcache), .m_axi_arprot(m_arprot), .m_axi_arqos(m_arqos),
    .m_axi_arregion(m_arregion), .m_axi_arvalid(m_arvalid), .m_axi_arready(m_arready),
    .m_axi_rid(m_rid), .m_axi_rdata(m_rdata), .m_axi_rresp(m_rresp),
    .m_axi_rlast(m_rlast), .m_axi_rvalid(m_rvalid), .m_axi_rready(m_rready)
  );

  integer aw_seen = 0, w_seen = 0, ar_seen = 0, b_seen = 0, r_seen = 0;
  reg [IW-1:0] exp_awid [0:1]; reg [AW-1:0] exp_awaddr [0:1];
  reg [7:0] exp_awlen [0:1];
  reg [DW-1:0] exp_wdata [0:3]; reg [DW/8-1:0] exp_wstrb [0:3];
  reg exp_wlast [0:3];
  reg [IW-1:0] exp_arid [0:1]; reg [AW-1:0] exp_araddr [0:1];
  reg [7:0] exp_arlen [0:1];
  reg [IW-1:0] exp_bid [0:1]; reg [1:0] exp_bresp [0:1];
  reg [IW-1:0] exp_rid [0:2]; reg [DW-1:0] exp_rdata [0:2];
  reg [1:0] exp_rresp [0:2]; reg exp_rlast [0:2];

  task automatic fail(input [1023:0] what);
    begin errors = errors + 1; $display("ERROR cycle=%0d %0s", cycle, what); end
  endtask

  always @(posedge clk) if (rst_n) begin
    if (m_awvalid && m_awready) begin
      if (aw_seen > 1) fail("unexpected AW");
      else begin
        if (m_awid !== exp_awid[aw_seen] || m_awaddr !== exp_awaddr[aw_seen] ||
            m_awlen !== exp_awlen[aw_seen] || m_awsize !== 3'd5 ||
            m_awburst !== 2'd1 || m_awlock !== 1'b0 || m_awcache !== 4'ha ||
            m_awprot !== 3'd3 || m_awqos !== 4'h6 || m_awregion !== 4'h9)
          fail("AW payload mismatch");
        aw_seen <= aw_seen + 1;
      end
    end
    if (m_wvalid && m_wready) begin
      if (w_seen > 3) fail("unexpected W");
      else begin
        if (m_wdata !== exp_wdata[w_seen] || m_wstrb !== exp_wstrb[w_seen] ||
            m_wlast !== exp_wlast[w_seen]) fail("W payload mismatch");
        w_seen <= w_seen + 1;
      end
    end
    if (m_arvalid && m_arready) begin
      if (ar_seen > 1) fail("unexpected AR");
      else begin
        if (m_arid !== exp_arid[ar_seen] || m_araddr !== exp_araddr[ar_seen] ||
            m_arlen !== exp_arlen[ar_seen] || m_arsize !== 3'd5 ||
            m_arburst !== 2'd1 || m_arlock !== 1'b0 || m_arcache !== 4'h5 ||
            m_arprot !== 3'd2 || m_arqos !== 4'h7 || m_arregion !== 4'hc)
          fail("AR payload mismatch");
        ar_seen <= ar_seen + 1;
      end
    end
    if (s_bvalid && s_bready) begin
      if (b_seen > 1) fail("unexpected B");
      else begin
        if (s_bid !== exp_bid[b_seen] || s_bresp !== exp_bresp[b_seen])
          fail("B payload mismatch");
        b_seen <= b_seen + 1;
      end
    end
    if (s_rvalid && s_rready) begin
      if (r_seen > 2) fail("unexpected R");
      else begin
        if (s_rid !== exp_rid[r_seen] || s_rdata !== exp_rdata[r_seen] ||
            s_rresp !== exp_rresp[r_seen] || s_rlast !== exp_rlast[r_seen])
          fail("R payload mismatch");
        r_seen <= r_seen + 1;
      end
    end
  end

  task automatic send_aw(input [IW-1:0] id, input [AW-1:0] addr, input [7:0] len);
    begin
      @(negedge clk); s_awid=id; s_awaddr=addr; s_awlen=len; s_awsize=3'd5;
      s_awburst=2'd1; s_awlock=0; s_awcache=4'ha; s_awprot=3'd3;
      s_awqos=4'h6; s_awregion=4'h9; s_awvalid=1;
      do @(posedge clk); while (!s_awready);
      @(negedge clk); s_awvalid=0;
    end
  endtask
  task automatic send_w(input [DW-1:0] data, input [DW/8-1:0] strb, input last);
    begin
      @(negedge clk); s_wdata=data; s_wstrb=strb; s_wlast=last; s_wvalid=1;
      do @(posedge clk); while (!s_wready);
      @(negedge clk); s_wvalid=0;
    end
  endtask
  task automatic send_ar(input [IW-1:0] id, input [AW-1:0] addr, input [7:0] len);
    begin
      @(negedge clk); s_arid=id; s_araddr=addr; s_arlen=len; s_arsize=3'd5;
      s_arburst=2'd1; s_arlock=0; s_arcache=4'h5; s_arprot=3'd2;
      s_arqos=4'h7; s_arregion=4'hc; s_arvalid=1;
      do @(posedge clk); while (!s_arready);
      @(negedge clk); s_arvalid=0;
    end
  endtask
  task automatic drive_b(input [IW-1:0] id, input [1:0] resp);
    begin
      @(negedge clk); m_bid=id; m_bresp=resp; m_bvalid=1;
      do @(posedge clk); while (!m_bready);
      @(negedge clk); m_bvalid=0;
    end
  endtask
  task automatic drive_r(input [IW-1:0] id, input [DW-1:0] data,
                         input [1:0] resp, input last);
    begin
      @(negedge clk); m_rid=id; m_rdata=data; m_rresp=resp; m_rlast=last; m_rvalid=1;
      do @(posedge clk); while (!m_rready);
      @(negedge clk); m_rvalid=0;
    end
  endtask

  initial begin
    s_awvalid=0; s_wvalid=0; s_arvalid=0; m_bvalid=0; m_rvalid=0;
    s_awid=0; s_awaddr=0; s_awlen=0; s_awsize=0; s_awburst=0; s_awlock=0;
    s_awcache=0; s_awprot=0; s_awqos=0; s_awregion=0;
    s_wdata=0; s_wstrb=0; s_wlast=0;
    s_arid=0; s_araddr=0; s_arlen=0; s_arsize=0; s_arburst=0; s_arlock=0;
    s_arcache=0; s_arprot=0; s_arqos=0; s_arregion=0;
    m_bid=0; m_bresp=0; m_rid=0; m_rdata=0; m_rresp=0; m_rlast=0;

    exp_awid[0]=14'h123; exp_awaddr[0]=34'h012345670; exp_awlen[0]=8'd1;
    exp_awid[1]=14'h2ab; exp_awaddr[1]=34'h023456780; exp_awlen[1]=8'd1;
    exp_wdata[0]={4{64'h0123456789abcdef}}; exp_wstrb[0]=32'hffff00ff; exp_wlast[0]=0;
    exp_wdata[1]={4{64'h1111222233334444}}; exp_wstrb[1]=32'hffffffff; exp_wlast[1]=1;
    exp_wdata[2]={4{64'hdeadbeefcafef00d}}; exp_wstrb[2]=32'h0fffffff; exp_wlast[2]=0;
    exp_wdata[3]={4{64'h55aa55aa66996699}}; exp_wstrb[3]=32'hf0f0f0f0; exp_wlast[3]=1;
    exp_arid[0]=14'h345; exp_araddr[0]=34'h034567890; exp_arlen[0]=8'd1;
    exp_arid[1]=14'h3c1; exp_araddr[1]=34'h001234560; exp_arlen[1]=8'd0;
    exp_bid[0]=14'h123; exp_bresp[0]=2'd0; exp_bid[1]=14'h2ab; exp_bresp[1]=2'd2;
    exp_rid[0]=14'h345; exp_rdata[0]={4{64'h1020304050607080}}; exp_rresp[0]=0; exp_rlast[0]=0;
    exp_rid[1]=14'h345; exp_rdata[1]={4{64'h8877665544332211}}; exp_rresp[1]=1; exp_rlast[1]=1;
    exp_rid[2]=14'h3c1; exp_rdata[2]={4{64'habcdef0123456789}}; exp_rresp[2]=0; exp_rlast[2]=1;

    repeat (5) @(posedge clk); rst_n=1;
    // W is intentionally launched ahead of AW. AR traffic is concurrent.
    fork
      begin
        send_w(exp_wdata[0],exp_wstrb[0],exp_wlast[0]);
        send_w(exp_wdata[1],exp_wstrb[1],exp_wlast[1]);
        send_w(exp_wdata[2],exp_wstrb[2],exp_wlast[2]);
        send_w(exp_wdata[3],exp_wstrb[3],exp_wlast[3]);
      end
      begin
        repeat (3) @(posedge clk);
        send_aw(exp_awid[0],exp_awaddr[0],exp_awlen[0]);
        send_aw(exp_awid[1],exp_awaddr[1],exp_awlen[1]);
      end
      begin
        send_ar(exp_arid[0],exp_araddr[0],exp_arlen[0]);
        send_ar(exp_arid[1],exp_araddr[1],exp_arlen[1]);
      end
      begin
        wait (aw_seen >= 1 && ar_seen >= 1 && w_seen >= 2);
        // B and R become valid in the same cycle and must both survive.
        fork
          drive_b(exp_bid[0],exp_bresp[0]);
          begin
            drive_r(exp_rid[0],exp_rdata[0],exp_rresp[0],exp_rlast[0]);
            drive_r(exp_rid[1],exp_rdata[1],exp_rresp[1],exp_rlast[1]);
          end
        join
        wait (aw_seen >= 2 && ar_seen >= 2 && w_seen >= 4);
        fork
          drive_b(exp_bid[1],exp_bresp[1]);
          drive_r(exp_rid[2],exp_rdata[2],exp_rresp[2],exp_rlast[2]);
        join
      end
    join
    wait (b_seen == 2 && r_seen == 3);
    repeat (10) @(posedge clk);
    if (aw_seen != 2 || w_seen != 4 || ar_seen != 2 || b_seen != 2 || r_seen != 3)
      fail("transaction count mismatch");
    if (errors == 0) $display("PASS uvhs_axi_remote_link cycles=%0d AW=%0d W=%0d AR=%0d B=%0d R=%0d",
                              cycle,aw_seen,w_seen,ar_seen,b_seen,r_seen);
    else $fatal(1,"FAIL uvhs_axi_remote_link errors=%0d",errors);
    $finish;
  end

  initial begin
    #200000; $fatal(1,"TIMEOUT uvhs_axi_remote_link");
  end
endmodule
