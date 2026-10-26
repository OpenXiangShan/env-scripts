wire uvhs_ddr_transport_clk = gbus_host_clk;
wire uvhs_ddr_user_clk, uvhs_ddr_user_rst;
wire [79:0] uvhs_func_ddr_req_data, uvhs_func_ddr_rsp_data;
wire uvhs_func_ddr_req_valid, uvhs_func_ddr_req_ready, uvhs_func_ddr_rsp_valid, uvhs_func_ddr_rsp_ready;
wire uvhs_ddr_user_rst_synced;
uvhs_async_status_sync #(.INIT(1'b1)) u_uvhs_ddr_user_rst_sync (
  .clk(sys_clk_i), .rstn(rstn_sw4), .async_in(uvhs_ddr_user_rst), .sync_out(uvhs_ddr_user_rst_synced)
);
assign init_calib_complete = rstn_sw4 & ~uvhs_ddr_user_rst_synced;

`ifdef CPU_NUTSHELL
uvhs_axi64_to_axi256 u_uvhs_axi64_to_axi256 (
    .clk                   (inter_soc_clk),
    .rstn                  (rstn_sw4),
    .session_resetn        (uvhs_memory_session_resetn),
    .s_axi_awid            (cpu2ddr_m2s_awid_mix[13:0]),
    .s_axi_awaddr          ({7'b0, cpu2ddr_m2s_awaddr_mix}),
    .s_axi_awlen           (cpu2ddr_m2s_awlen),
    .s_axi_awsize          (cpu2ddr_m2s_awsize),
    .s_axi_awburst         (cpu2ddr_m2s_awburst),
    .s_axi_awlock          (cpu2ddr_m2s_awlock),
    .s_axi_awcache         (cpu2ddr_m2s_awcache),
    .s_axi_awprot          (cpu2ddr_m2s_awprot),
    .s_axi_awqos           (cpu2ddr_m2s_awqos),
    .s_axi_awvalid         (cpu2ddr_m2s_awvalid),
    .s_axi_awready         (cpu2ddr_s2m_awready),
    .s_axi_wdata           (cpu2ddr_m2s_wdata[63:0]),
    .s_axi_wstrb           (cpu2ddr_m2s_wstrb[7:0]),
    .s_axi_wlast           (cpu2ddr_m2s_wlast),
    .s_axi_wvalid          (cpu2ddr_m2s_wvalid),
    .s_axi_wready          (cpu2ddr_s2m_wready),
    .s_axi_bid             (cpu2ddr_s2m_bid[13:0]),
    .s_axi_bresp           (cpu2ddr_s2m_bresp),
    .s_axi_bvalid          (cpu2ddr_s2m_bvalid),
    .s_axi_bready          (cpu2ddr_m2s_bready),
    .s_axi_arid            (cpu2ddr_m2s_arid_mix[13:0]),
    .s_axi_araddr          ({7'b0, cpu2ddr_m2s_araddr_mix}),
    .s_axi_arlen           (cpu2ddr_m2s_arlen),
    .s_axi_arsize          (cpu2ddr_m2s_arsize),
    .s_axi_arburst         (cpu2ddr_m2s_arburst),
    .s_axi_arlock          (cpu2ddr_m2s_arlock),
    .s_axi_arcache         (cpu2ddr_m2s_arcache),
    .s_axi_arprot          (cpu2ddr_m2s_arprot),
    .s_axi_arqos           (cpu2ddr_m2s_arqos),
    .s_axi_arvalid         (cpu2ddr_m2s_arvalid),
    .s_axi_arready         (cpu2ddr_s2m_arready),
    .s_axi_rid             (cpu2ddr_s2m_rid[13:0]),
    .s_axi_rdata           (cpu2ddr_s2m_rdata[63:0]),
    .s_axi_rresp           (cpu2ddr_s2m_rresp),
    .s_axi_rlast           (cpu2ddr_s2m_rlast),
    .s_axi_rvalid          (cpu2ddr_s2m_rvalid),
    .s_axi_rready          (cpu2ddr_m2s_rready),
    .m_axi_awid            (cpu_ddr_soc_awid),
    .m_axi_awaddr          (cpu_ddr_soc_awaddr),
    .m_axi_awlen           (cpu_ddr_soc_awlen),
    .m_axi_awsize          (cpu_ddr_soc_awsize),
    .m_axi_awburst         (cpu_ddr_soc_awburst),
    .m_axi_awlock          (cpu_ddr_soc_awlock),
    .m_axi_awcache         (cpu_ddr_soc_awcache),
    .m_axi_awprot          (cpu_ddr_soc_awprot),
    .m_axi_awqos           (cpu_ddr_soc_awqos),
    .m_axi_awregion        (cpu_ddr_soc_awregion),
    .m_axi_awvalid         (cpu_ddr_soc_awvalid),
    .m_axi_awready         (cpu_ddr_soc_awready),
    .m_axi_wdata           (cpu_ddr_soc_wdata),
    .m_axi_wstrb           (cpu_ddr_soc_wstrb),
    .m_axi_wlast           (cpu_ddr_soc_wlast),
    .m_axi_wvalid          (cpu_ddr_soc_wvalid),
    .m_axi_wready          (cpu_ddr_soc_wready),
    .m_axi_bid             (cpu_ddr_soc_bid),
    .m_axi_bresp           (cpu_ddr_soc_bresp),
    .m_axi_bvalid          (cpu_ddr_soc_bvalid),
    .m_axi_bready          (cpu_ddr_soc_bready),
    .m_axi_arid            (cpu_ddr_soc_arid),
    .m_axi_araddr          (cpu_ddr_soc_araddr),
    .m_axi_arlen           (cpu_ddr_soc_arlen),
    .m_axi_arsize          (cpu_ddr_soc_arsize),
    .m_axi_arburst         (cpu_ddr_soc_arburst),
    .m_axi_arlock          (cpu_ddr_soc_arlock),
    .m_axi_arcache         (cpu_ddr_soc_arcache),
    .m_axi_arprot          (cpu_ddr_soc_arprot),
    .m_axi_arqos           (cpu_ddr_soc_arqos),
    .m_axi_arregion        (cpu_ddr_soc_arregion),
    .m_axi_arvalid         (cpu_ddr_soc_arvalid),
    .m_axi_arready         (cpu_ddr_soc_arready),
    .m_axi_rid             (cpu_ddr_soc_rid),
    .m_axi_rdata           (cpu_ddr_soc_rdata),
    .m_axi_rresp           (cpu_ddr_soc_rresp),
    .m_axi_rlast           (cpu_ddr_soc_rlast),
    .m_axi_rvalid          (cpu_ddr_soc_rvalid),
    .m_axi_rready          (cpu_ddr_soc_rready)
);
assign cpu2ddr_s2m_bid[17:14] = 4'b0;
assign cpu2ddr_s2m_rid[17:14] = 4'b0;
`else
assign cpu_ddr_soc_awid = cpu2ddr_m2s_awid_mix[13:0];
assign cpu_ddr_soc_awaddr = cpu2ddr_m2s_awaddr_mix[33:0];
assign cpu_ddr_soc_awlen = cpu2ddr_m2s_awlen; assign cpu_ddr_soc_awsize = cpu2ddr_m2s_awsize;
assign cpu_ddr_soc_awburst = cpu2ddr_m2s_awburst; assign cpu_ddr_soc_awlock = cpu2ddr_m2s_awlock;
assign cpu_ddr_soc_awcache = cpu2ddr_m2s_awcache; assign cpu_ddr_soc_awprot = cpu2ddr_m2s_awprot;
assign cpu_ddr_soc_awqos = cpu2ddr_m2s_awqos; assign cpu_ddr_soc_awregion = cpu2ddr_m2s_awregion;
assign cpu_ddr_soc_awvalid = cpu2ddr_m2s_awvalid; assign cpu2ddr_s2m_awready = cpu_ddr_soc_awready;
assign cpu_ddr_soc_wdata = cpu2ddr_m2s_wdata; assign cpu_ddr_soc_wstrb = cpu2ddr_m2s_wstrb;
assign cpu_ddr_soc_wlast = cpu2ddr_m2s_wlast; assign cpu_ddr_soc_wvalid = cpu2ddr_m2s_wvalid;
assign cpu2ddr_s2m_wready = cpu_ddr_soc_wready; assign cpu2ddr_s2m_bid = {4'b0, cpu_ddr_soc_bid};
assign cpu2ddr_s2m_bresp = cpu_ddr_soc_bresp; assign cpu2ddr_s2m_bvalid = cpu_ddr_soc_bvalid;
assign cpu_ddr_soc_bready = cpu2ddr_m2s_bready;
assign cpu_ddr_soc_arid = cpu2ddr_m2s_arid_mix[13:0]; assign cpu_ddr_soc_araddr = cpu2ddr_m2s_araddr_mix[33:0];
assign cpu_ddr_soc_arlen = cpu2ddr_m2s_arlen; assign cpu_ddr_soc_arsize = cpu2ddr_m2s_arsize;
assign cpu_ddr_soc_arburst = cpu2ddr_m2s_arburst; assign cpu_ddr_soc_arlock = cpu2ddr_m2s_arlock;
assign cpu_ddr_soc_arcache = cpu2ddr_m2s_arcache; assign cpu_ddr_soc_arprot = cpu2ddr_m2s_arprot;
assign cpu_ddr_soc_arqos = cpu2ddr_m2s_arqos; assign cpu_ddr_soc_arregion = cpu2ddr_m2s_arregion;
assign cpu_ddr_soc_arvalid = cpu2ddr_m2s_arvalid; assign cpu2ddr_s2m_arready = cpu_ddr_soc_arready;
assign cpu2ddr_s2m_rid = {4'b0, cpu_ddr_soc_rid}; assign cpu2ddr_s2m_rdata = cpu_ddr_soc_rdata;
assign cpu2ddr_s2m_rresp = cpu_ddr_soc_rresp; assign cpu2ddr_s2m_rlast = cpu_ddr_soc_rlast;
assign cpu2ddr_s2m_rvalid = cpu_ddr_soc_rvalid; assign cpu_ddr_soc_rready = cpu2ddr_m2s_rready;
`endif

uvhs_axi_async_bridge #(.ADDR_WIDTH(34), .ID_WIDTH(14), .DATA_WIDTH(256)) U_GBUS_CPU_DDR_CDC (
  .s_clk(inter_soc_clk), .s_rstn(rstn_sw4),
  .s_awid(cpu_ddr_soc_awid), .s_awaddr(cpu_ddr_soc_awaddr), .s_awlen(cpu_ddr_soc_awlen), .s_awsize(cpu_ddr_soc_awsize), .s_awburst(cpu_ddr_soc_awburst), .s_awlock(cpu_ddr_soc_awlock), .s_awcache(cpu_ddr_soc_awcache), .s_awprot(cpu_ddr_soc_awprot), .s_awqos(cpu_ddr_soc_awqos), .s_awregion(cpu_ddr_soc_awregion), .s_awvalid(cpu_ddr_soc_awvalid), .s_awready(cpu_ddr_soc_awready),
  .s_wdata(cpu_ddr_soc_wdata), .s_wstrb(cpu_ddr_soc_wstrb), .s_wlast(cpu_ddr_soc_wlast), .s_wvalid(cpu_ddr_soc_wvalid), .s_wready(cpu_ddr_soc_wready), .s_bid(cpu_ddr_soc_bid), .s_bresp(cpu_ddr_soc_bresp), .s_bvalid(cpu_ddr_soc_bvalid), .s_bready(cpu_ddr_soc_bready),
  .s_arid(cpu_ddr_soc_arid), .s_araddr(cpu_ddr_soc_araddr), .s_arlen(cpu_ddr_soc_arlen), .s_arsize(cpu_ddr_soc_arsize), .s_arburst(cpu_ddr_soc_arburst), .s_arlock(cpu_ddr_soc_arlock), .s_arcache(cpu_ddr_soc_arcache), .s_arprot(cpu_ddr_soc_arprot), .s_arqos(cpu_ddr_soc_arqos), .s_arregion(cpu_ddr_soc_arregion), .s_arvalid(cpu_ddr_soc_arvalid), .s_arready(cpu_ddr_soc_arready), .s_rid(cpu_ddr_soc_rid), .s_rdata(cpu_ddr_soc_rdata), .s_rresp(cpu_ddr_soc_rresp), .s_rlast(cpu_ddr_soc_rlast), .s_rvalid(cpu_ddr_soc_rvalid), .s_rready(cpu_ddr_soc_rready),
  .m_clk(uvhs_ddr_transport_clk), .m_rstn(rstn_sw4),
  .m_awid(cpu_ddr_awid), .m_awaddr(cpu_ddr_awaddr), .m_awlen(cpu_ddr_awlen), .m_awsize(cpu_ddr_awsize), .m_awburst(cpu_ddr_awburst), .m_awlock(cpu_ddr_awlock), .m_awcache(cpu_ddr_awcache), .m_awprot(cpu_ddr_awprot), .m_awqos(cpu_ddr_awqos), .m_awregion(cpu_ddr_awregion), .m_awvalid(cpu_ddr_awvalid), .m_awready(cpu_ddr_awready),
  .m_wdata(cpu_ddr_wdata), .m_wstrb(cpu_ddr_wstrb), .m_wlast(cpu_ddr_wlast), .m_wvalid(cpu_ddr_wvalid), .m_wready(cpu_ddr_wready), .m_bid(cpu_ddr_bid), .m_bresp(cpu_ddr_bresp), .m_bvalid(cpu_ddr_bvalid), .m_bready(cpu_ddr_bready),
  .m_arid(cpu_ddr_arid), .m_araddr(cpu_ddr_araddr), .m_arlen(cpu_ddr_arlen), .m_arsize(cpu_ddr_arsize), .m_arburst(cpu_ddr_arburst), .m_arlock(cpu_ddr_arlock), .m_arcache(cpu_ddr_arcache), .m_arprot(cpu_ddr_arprot), .m_arqos(cpu_ddr_arqos), .m_arregion(cpu_ddr_arregion), .m_arvalid(cpu_ddr_arvalid), .m_arready(cpu_ddr_arready), .m_rid(cpu_ddr_rid), .m_rdata(cpu_ddr_rdata), .m_rresp(cpu_ddr_rresp), .m_rlast(cpu_ddr_rlast), .m_rvalid(cpu_ddr_rvalid), .m_rready(cpu_ddr_rready)
);

uvhs_axi_3master_arbiter #(.ADDR_WIDTH(34), .ID_WIDTH(14), .DATA_WIDTH(256)) U_GBUS_DDR_ARBITER (
  .clk(uvhs_ddr_transport_clk), .rstn(rstn_sw4),
  .s0_awid(cpu_ddr_awid), .s0_awaddr(cpu_ddr_awaddr), .s0_awlen(cpu_ddr_awlen), .s0_awsize(cpu_ddr_awsize), .s0_awburst(cpu_ddr_awburst), .s0_awlock(cpu_ddr_awlock), .s0_awcache(cpu_ddr_awcache), .s0_awprot(cpu_ddr_awprot), .s0_awqos(cpu_ddr_awqos), .s0_awregion(cpu_ddr_awregion), .s0_awvalid(cpu_ddr_awvalid), .s0_awready(cpu_ddr_awready), .s0_wdata(cpu_ddr_wdata), .s0_wstrb(cpu_ddr_wstrb), .s0_wlast(cpu_ddr_wlast), .s0_wvalid(cpu_ddr_wvalid), .s0_wready(cpu_ddr_wready), .s0_bid(cpu_ddr_bid), .s0_bresp(cpu_ddr_bresp), .s0_bvalid(cpu_ddr_bvalid), .s0_bready(cpu_ddr_bready), .s0_arid(cpu_ddr_arid), .s0_araddr(cpu_ddr_araddr), .s0_arlen(cpu_ddr_arlen), .s0_arsize(cpu_ddr_arsize), .s0_arburst(cpu_ddr_arburst), .s0_arlock(cpu_ddr_arlock), .s0_arcache(cpu_ddr_arcache), .s0_arprot(cpu_ddr_arprot), .s0_arqos(cpu_ddr_arqos), .s0_arregion(cpu_ddr_arregion), .s0_arvalid(cpu_ddr_arvalid), .s0_arready(cpu_ddr_arready), .s0_rid(cpu_ddr_rid), .s0_rdata(cpu_ddr_rdata), .s0_rresp(cpu_ddr_rresp), .s0_rlast(cpu_ddr_rlast), .s0_rvalid(cpu_ddr_rvalid), .s0_rready(cpu_ddr_rready),
  .s1_awid(gbus_ddr_awid), .s1_awaddr(gbus_ddr_awaddr), .s1_awlen(gbus_ddr_awlen), .s1_awsize(gbus_ddr_awsize), .s1_awburst(gbus_ddr_awburst), .s1_awlock(gbus_ddr_awlock), .s1_awcache(gbus_ddr_awcache), .s1_awprot(gbus_ddr_awprot), .s1_awqos(gbus_ddr_awqos), .s1_awregion(gbus_ddr_awregion), .s1_awvalid(gbus_ddr_awvalid), .s1_awready(gbus_ddr_awready), .s1_wdata(gbus_ddr_wdata), .s1_wstrb(gbus_ddr_wstrb), .s1_wlast(gbus_ddr_wlast), .s1_wvalid(gbus_ddr_wvalid), .s1_wready(gbus_ddr_wready), .s1_bid(gbus_ddr_bid), .s1_bresp(gbus_ddr_bresp), .s1_bvalid(gbus_ddr_bvalid), .s1_bready(gbus_ddr_bready), .s1_arid(gbus_ddr_arid), .s1_araddr(gbus_ddr_araddr), .s1_arlen(gbus_ddr_arlen), .s1_arsize(gbus_ddr_arsize), .s1_arburst(gbus_ddr_arburst), .s1_arlock(gbus_ddr_arlock), .s1_arcache(gbus_ddr_arcache), .s1_arprot(gbus_ddr_arprot), .s1_arqos(gbus_ddr_arqos), .s1_arregion(gbus_ddr_arregion), .s1_arvalid(gbus_ddr_arvalid), .s1_arready(gbus_ddr_arready), .s1_rid(gbus_ddr_rid), .s1_rdata(gbus_ddr_rdata), .s1_rresp(gbus_ddr_rresp), .s1_rlast(gbus_ddr_rlast), .s1_rvalid(gbus_ddr_rvalid), .s1_rready(gbus_ddr_rready),
  .s2_awid(14'b0), .s2_awaddr(34'b0), .s2_awlen(8'b0), .s2_awsize(3'b0), .s2_awburst(2'b0), .s2_awlock(1'b0), .s2_awcache(4'b0), .s2_awprot(3'b0), .s2_awqos(4'b0), .s2_awregion(4'b0), .s2_awvalid(1'b0), .s2_awready(), .s2_wdata(256'b0), .s2_wstrb(32'b0), .s2_wlast(1'b0), .s2_wvalid(1'b0), .s2_wready(), .s2_bid(), .s2_bresp(), .s2_bvalid(), .s2_bready(1'b0), .s2_arid(14'b0), .s2_araddr(34'b0), .s2_arlen(8'b0), .s2_arsize(3'b0), .s2_arburst(2'b0), .s2_arlock(1'b0), .s2_arcache(4'b0), .s2_arprot(3'b0), .s2_arqos(4'b0), .s2_arregion(4'b0), .s2_arvalid(1'b0), .s2_arready(), .s2_rid(), .s2_rdata(), .s2_rresp(), .s2_rlast(), .s2_rvalid(), .s2_rready(1'b0),
  .m_awid(gbus_merged_awid), .m_awaddr(gbus_merged_awaddr), .m_awlen(gbus_merged_awlen), .m_awsize(gbus_merged_awsize), .m_awburst(gbus_merged_awburst), .m_awlock(gbus_merged_awlock), .m_awcache(gbus_merged_awcache), .m_awprot(gbus_merged_awprot), .m_awqos(gbus_merged_awqos), .m_awregion(gbus_merged_awregion), .m_awvalid(gbus_merged_awvalid), .m_awready(gbus_merged_awready), .m_wdata(gbus_merged_wdata), .m_wstrb(gbus_merged_wstrb), .m_wlast(gbus_merged_wlast), .m_wvalid(gbus_merged_wvalid), .m_wready(gbus_merged_wready), .m_bid(gbus_merged_bid), .m_bresp(gbus_merged_bresp), .m_bvalid(gbus_merged_bvalid), .m_bready(gbus_merged_bready), .m_arid(gbus_merged_arid), .m_araddr(gbus_merged_araddr), .m_arlen(gbus_merged_arlen), .m_arsize(gbus_merged_arsize), .m_arburst(gbus_merged_arburst), .m_arlock(gbus_merged_arlock), .m_arcache(gbus_merged_arcache), .m_arprot(gbus_merged_arprot), .m_arqos(gbus_merged_arqos), .m_arregion(gbus_merged_arregion), .m_arvalid(gbus_merged_arvalid), .m_arready(gbus_merged_arready), .m_rid(gbus_merged_rid), .m_rdata(gbus_merged_rdata), .m_rresp(gbus_merged_rresp), .m_rlast(gbus_merged_rlast), .m_rvalid(gbus_merged_rvalid), .m_rready(gbus_merged_rready)
);
`ifdef UVHS_FUNCTIONAL_DDR_REMOTE_LINK
uvhs_axi_remote_source #(
    .DATA_WIDTH(256), .ADDR_WIDTH(34), .ID_WIDTH(14),
    .FLIT_WIDTH(80), .PACKET_WIDTH(320)
) u_uvhs_gbus_func_ddr_remote_source (
    .clk(uvhs_ddr_transport_clk), .rst_n(rstn_sw4),
    .s_axi_awid(gbus_merged_awid), .s_axi_awaddr(gbus_merged_awaddr),
    .s_axi_awlen(gbus_merged_awlen), .s_axi_awsize(gbus_merged_awsize),
    .s_axi_awburst(gbus_merged_awburst), .s_axi_awlock(gbus_merged_awlock),
    .s_axi_awcache(gbus_merged_awcache), .s_axi_awprot(gbus_merged_awprot),
    .s_axi_awqos(gbus_merged_awqos), .s_axi_awregion(gbus_merged_awregion),
    .s_axi_awvalid(gbus_merged_awvalid), .s_axi_awready(gbus_merged_awready),
    .s_axi_wdata(gbus_merged_wdata), .s_axi_wstrb(gbus_merged_wstrb),
    .s_axi_wlast(gbus_merged_wlast), .s_axi_wvalid(gbus_merged_wvalid),
    .s_axi_wready(gbus_merged_wready), .s_axi_bid(gbus_merged_bid),
    .s_axi_bresp(gbus_merged_bresp), .s_axi_bvalid(gbus_merged_bvalid),
    .s_axi_bready(gbus_merged_bready), .s_axi_arid(gbus_merged_arid),
    .s_axi_araddr(gbus_merged_araddr), .s_axi_arlen(gbus_merged_arlen),
    .s_axi_arsize(gbus_merged_arsize), .s_axi_arburst(gbus_merged_arburst),
    .s_axi_arlock(gbus_merged_arlock), .s_axi_arcache(gbus_merged_arcache),
    .s_axi_arprot(gbus_merged_arprot), .s_axi_arqos(gbus_merged_arqos),
    .s_axi_arregion(gbus_merged_arregion), .s_axi_arvalid(gbus_merged_arvalid),
    .s_axi_arready(gbus_merged_arready), .s_axi_rid(gbus_merged_rid),
    .s_axi_rdata(gbus_merged_rdata), .s_axi_rresp(gbus_merged_rresp),
    .s_axi_rlast(gbus_merged_rlast), .s_axi_rvalid(gbus_merged_rvalid),
    .s_axi_rready(gbus_merged_rready),
    .req_tx_data(uvhs_func_ddr_req_data), .req_tx_valid(uvhs_func_ddr_req_valid),
    .req_tx_ready(uvhs_func_ddr_req_ready), .rsp_rx_data(uvhs_func_ddr_rsp_data),
    .rsp_rx_valid(uvhs_func_ddr_rsp_valid), .rsp_rx_ready(uvhs_func_ddr_rsp_ready)
);

uvhs_axi_remote_sink #(
    .DATA_WIDTH(256), .ADDR_WIDTH(34), .ID_WIDTH(14),
    .FLIT_WIDTH(80), .PACKET_WIDTH(320)
) u_uvhs_gbus_func_ddr_remote_sink (
    .clk(uvhs_ddr_transport_clk), .rst_n(rstn_sw4),
    .req_rx_data(uvhs_func_ddr_req_data), .req_rx_valid(uvhs_func_ddr_req_valid),
    .req_rx_ready(uvhs_func_ddr_req_ready), .rsp_tx_data(uvhs_func_ddr_rsp_data),
    .rsp_tx_valid(uvhs_func_ddr_rsp_valid), .rsp_tx_ready(uvhs_func_ddr_rsp_ready),
    .m_axi_awid(uvhs_ddr_awid), .m_axi_awaddr(uvhs_ddr_awaddr),
    .m_axi_awlen(uvhs_ddr_awlen), .m_axi_awsize(uvhs_ddr_awsize),
    .m_axi_awburst(uvhs_ddr_awburst), .m_axi_awlock(uvhs_ddr_awlock),
    .m_axi_awcache(uvhs_ddr_awcache), .m_axi_awprot(uvhs_ddr_awprot),
    .m_axi_awqos(uvhs_ddr_awqos), .m_axi_awregion(uvhs_ddr_awregion),
    .m_axi_awvalid(uvhs_ddr_awvalid), .m_axi_awready(uvhs_ddr_awready),
    .m_axi_wdata(uvhs_ddr_wdata), .m_axi_wstrb(uvhs_ddr_wstrb),
    .m_axi_wlast(uvhs_ddr_wlast), .m_axi_wvalid(uvhs_ddr_wvalid),
    .m_axi_wready(uvhs_ddr_wready), .m_axi_bid(uvhs_ddr_bid),
    .m_axi_bresp(uvhs_ddr_bresp), .m_axi_bvalid(uvhs_ddr_bvalid),
    .m_axi_bready(uvhs_ddr_bready), .m_axi_arid(uvhs_ddr_arid),
    .m_axi_araddr(uvhs_ddr_araddr), .m_axi_arlen(uvhs_ddr_arlen),
    .m_axi_arsize(uvhs_ddr_arsize), .m_axi_arburst(uvhs_ddr_arburst),
    .m_axi_arlock(uvhs_ddr_arlock), .m_axi_arcache(uvhs_ddr_arcache),
    .m_axi_arprot(uvhs_ddr_arprot), .m_axi_arqos(uvhs_ddr_arqos),
    .m_axi_arregion(uvhs_ddr_arregion), .m_axi_arvalid(uvhs_ddr_arvalid),
    .m_axi_arready(uvhs_ddr_arready), .m_axi_rid(uvhs_ddr_rid),
    .m_axi_rdata(uvhs_ddr_rdata), .m_axi_rresp(uvhs_ddr_rresp),
    .m_axi_rlast(uvhs_ddr_rlast), .m_axi_rvalid(uvhs_ddr_rvalid),
    .m_axi_rready(uvhs_ddr_rready)
);
`else
assign uvhs_ddr_awid = gbus_merged_awid;
assign uvhs_ddr_awaddr = gbus_merged_awaddr;
assign uvhs_ddr_awlen = gbus_merged_awlen;
assign uvhs_ddr_awsize = gbus_merged_awsize;
assign uvhs_ddr_awburst = gbus_merged_awburst;
assign uvhs_ddr_awlock = gbus_merged_awlock;
assign uvhs_ddr_awcache = gbus_merged_awcache;
assign uvhs_ddr_awprot = gbus_merged_awprot;
assign uvhs_ddr_awqos = gbus_merged_awqos;
assign uvhs_ddr_awregion = gbus_merged_awregion;
assign uvhs_ddr_awvalid = gbus_merged_awvalid;
assign gbus_merged_awready = uvhs_ddr_awready;
assign uvhs_ddr_wdata = gbus_merged_wdata;
assign uvhs_ddr_wstrb = gbus_merged_wstrb;
assign uvhs_ddr_wlast = gbus_merged_wlast;
assign uvhs_ddr_wvalid = gbus_merged_wvalid;
assign gbus_merged_wready = uvhs_ddr_wready;
assign gbus_merged_bid = uvhs_ddr_bid;
assign gbus_merged_bresp = uvhs_ddr_bresp;
assign gbus_merged_bvalid = uvhs_ddr_bvalid;
assign uvhs_ddr_bready = gbus_merged_bready;
assign uvhs_ddr_arid = gbus_merged_arid;
assign uvhs_ddr_araddr = gbus_merged_araddr;
assign uvhs_ddr_arlen = gbus_merged_arlen;
assign uvhs_ddr_arsize = gbus_merged_arsize;
assign uvhs_ddr_arburst = gbus_merged_arburst;
assign uvhs_ddr_arlock = gbus_merged_arlock;
assign uvhs_ddr_arcache = gbus_merged_arcache;
assign uvhs_ddr_arprot = gbus_merged_arprot;
assign uvhs_ddr_arqos = gbus_merged_arqos;
assign uvhs_ddr_arregion = gbus_merged_arregion;
assign uvhs_ddr_arvalid = gbus_merged_arvalid;
assign gbus_merged_arready = uvhs_ddr_arready;
assign gbus_merged_rid = uvhs_ddr_rid;
assign gbus_merged_rdata = uvhs_ddr_rdata;
assign gbus_merged_rresp = uvhs_ddr_rresp;
assign gbus_merged_rlast = uvhs_ddr_rlast;
assign gbus_merged_rvalid = uvhs_ddr_rvalid;
assign uvhs_ddr_rready = gbus_merged_rready;
`endif
uvw_axi4_to_ddr4 U_UVHS_UVW_AXI4_TO_DDR4 (
    .ddr4ip_dut_axi_aclk     (uvhs_ddr_transport_clk),
    .ddr4ip_dut_axi_aresetn  (rstn_sw4),
    .ddr4ip_dut_axi_awaddr   (uvhs_ddr_awaddr),
    .ddr4ip_dut_axi_awburst  (uvhs_ddr_awburst),
    .ddr4ip_dut_axi_awcache  (uvhs_ddr_awcache),
    .ddr4ip_dut_axi_awid     (uvhs_ddr_awid),
    .ddr4ip_dut_axi_awlen    (uvhs_ddr_awlen),
    .ddr4ip_dut_axi_awlock   (uvhs_ddr_awlock),
    .ddr4ip_dut_axi_awprot   (uvhs_ddr_awprot),
    .ddr4ip_dut_axi_awqos    (uvhs_ddr_awqos),
    .ddr4ip_dut_axi_awready  (uvhs_ddr_awready),
    .ddr4ip_dut_axi_awregion (uvhs_ddr_awregion),
    .ddr4ip_dut_axi_awsize   (uvhs_ddr_awsize),
    .ddr4ip_dut_axi_awvalid  (uvhs_ddr_awvalid),
    .ddr4ip_dut_axi_wdata    (uvhs_ddr_wdata),
    .ddr4ip_dut_axi_wlast    (uvhs_ddr_wlast),
    .ddr4ip_dut_axi_wready   (uvhs_ddr_wready),
    .ddr4ip_dut_axi_wstrb    (uvhs_ddr_wstrb),
    .ddr4ip_dut_axi_wvalid   (uvhs_ddr_wvalid),
    .ddr4ip_dut_axi_bid      (uvhs_ddr_bid),
    .ddr4ip_dut_axi_bready   (uvhs_ddr_bready),
    .ddr4ip_dut_axi_bresp    (uvhs_ddr_bresp),
    .ddr4ip_dut_axi_bvalid   (uvhs_ddr_bvalid),
    .ddr4ip_dut_axi_araddr   (uvhs_ddr_araddr),
    .ddr4ip_dut_axi_arburst  (uvhs_ddr_arburst),
    .ddr4ip_dut_axi_arcache  (uvhs_ddr_arcache),
    .ddr4ip_dut_axi_arid     (uvhs_ddr_arid),
    .ddr4ip_dut_axi_arlen    (uvhs_ddr_arlen),
    .ddr4ip_dut_axi_arlock   (uvhs_ddr_arlock),
    .ddr4ip_dut_axi_arprot   (uvhs_ddr_arprot),
    .ddr4ip_dut_axi_arqos    (uvhs_ddr_arqos),
    .ddr4ip_dut_axi_arready  (uvhs_ddr_arready),
    .ddr4ip_dut_axi_arregion (uvhs_ddr_arregion),
    .ddr4ip_dut_axi_arsize   (uvhs_ddr_arsize),
    .ddr4ip_dut_axi_arvalid  (uvhs_ddr_arvalid),
    .ddr4ip_dut_axi_rdata    (uvhs_ddr_rdata),
    .ddr4ip_dut_axi_rid      (uvhs_ddr_rid),
    .ddr4ip_dut_axi_rlast    (uvhs_ddr_rlast),
    .ddr4ip_dut_axi_rready   (uvhs_ddr_rready),
    .ddr4ip_dut_axi_rresp    (uvhs_ddr_rresp),
    .ddr4ip_dut_axi_rvalid   (uvhs_ddr_rvalid),
    .ddr4ip_dut_axi_aclk_en  (1'b1),
    .ddr4ip_ddr4_user_clk    (uvhs_ddr_user_clk),
    .ddr4ip_ddr4_user_rst    (uvhs_ddr_user_rst),
    // UVHS binds DCMEM/GENERALBUS/GENERALBD system buses through IP metadata.
    .sysbus_ghbd_i           (),
    .sysbus_ghbd_o           (),
    .FP_CLK_200M_P           (),
    .FP_CLK_200M_N           (),
    .DDR4_DIMM_ACT_N         (),
    .DDR4_DIMM_A             (),
    .DDR4_DIMM_BA            (),
    .DDR4_DIMM_BG            (),
    .DDR4_DIMM_CK_N          (),
    .DDR4_DIMM_CK_P          (),
    .DDR4_DIMM_CKE           (),
    .DDR4_DIMM_CS_N          (),
    .DDR4_DIMM_ODT           (),
    .DDR4_DIMM_RST_B         (),
    .DDR4_DIMM_DM            (),
    .DDR4_DIMM_DQ            (),
    .DDR4_DIMM_DQS_N         (),
    .DDR4_DIMM_DQS_P         ()
);
