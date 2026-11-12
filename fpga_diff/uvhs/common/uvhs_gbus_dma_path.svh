  wire [7:0] gbus_local_arid, gbus_local_rid;
  wire [31:0] gbus_local_araddr;
  wire [3:0] gbus_local_arlen;
  wire [2:0] gbus_local_arsize;
  wire [1:0] gbus_local_arburst, gbus_local_rresp;
  wire gbus_local_arvalid, gbus_local_arready, gbus_local_rlast, gbus_local_rvalid, gbus_local_rready;
  wire [255:0] gbus_local_rdata;
  wire [7:0] gbus_routed_arid, gbus_routed_rid;
  wire [31:0] gbus_routed_araddr;
  wire [3:0] gbus_routed_arlen, gbus_routed_arcache, gbus_routed_arqos;
  wire [2:0] gbus_routed_arsize, gbus_routed_arprot;
  wire [1:0] gbus_routed_arburst, gbus_routed_arlock, gbus_routed_rresp;
  wire gbus_routed_arvalid, gbus_routed_arready, gbus_routed_rlast, gbus_routed_rvalid, gbus_routed_rready;
  wire [255:0] gbus_routed_rdata;
  wire [7:0] gbus_guard_awid, gbus_guard_wid, gbus_guard_bid;
  wire [31:0] gbus_guard_awaddr, gbus_guard_wstrb;
  wire [3:0] gbus_guard_awlen, gbus_guard_awcache, gbus_guard_awqos;
  wire [2:0] gbus_guard_awsize, gbus_guard_awprot;
  wire [1:0] gbus_guard_awburst, gbus_guard_awlock, gbus_guard_bresp;
  wire gbus_guard_awvalid, gbus_guard_awready, gbus_guard_wlast, gbus_guard_wvalid, gbus_guard_wready;
  wire gbus_guard_bvalid, gbus_guard_bready;
  wire [255:0] gbus_guard_wdata;

  uvhs_gbus_axi_read_router U_GBUS_C2H_READ_ROUTER (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .s_arid(gbus_axi_arid), .s_araddr(gbus_axi_araddr), .s_arlen(gbus_axi_arlen),
    .s_arsize(gbus_axi_arsize), .s_arburst(gbus_axi_arburst), .s_arlock(gbus_axi_arlock),
    .s_arcache(gbus_axi_arcache), .s_arprot(gbus_axi_arprot), .s_arqos(gbus_axi_arqos),
    .s_arvalid(gbus_axi_arvalid), .s_arready(gbus_axi_arready),
    .s_rid(gbus_axi_rid), .s_rdata(gbus_axi_rdata), .s_rresp(gbus_axi_rresp),
    .s_rlast(gbus_axi_rlast), .s_rvalid(gbus_axi_rvalid), .s_rready(gbus_axi_rready),
    .c_arid(gbus_local_arid), .c_araddr(gbus_local_araddr), .c_arlen(gbus_local_arlen),
    .c_arsize(gbus_local_arsize), .c_arburst(gbus_local_arburst),
    .c_arvalid(gbus_local_arvalid), .c_arready(gbus_local_arready),
    .c_rid(gbus_local_rid), .c_rdata(gbus_local_rdata), .c_rresp(gbus_local_rresp),
    .c_rlast(gbus_local_rlast), .c_rvalid(gbus_local_rvalid), .c_rready(gbus_local_rready),
    .d_arid(gbus_routed_arid), .d_araddr(gbus_routed_araddr), .d_arlen(gbus_routed_arlen),
    .d_arsize(gbus_routed_arsize), .d_arburst(gbus_routed_arburst), .d_arlock(gbus_routed_arlock),
    .d_arcache(gbus_routed_arcache), .d_arprot(gbus_routed_arprot), .d_arqos(gbus_routed_arqos),
    .d_arvalid(gbus_routed_arvalid), .d_arready(gbus_routed_arready),
    .d_rid(gbus_routed_rid), .d_rdata(gbus_routed_rdata), .d_rresp(gbus_routed_rresp),
    .d_rlast(gbus_routed_rlast), .d_rvalid(gbus_routed_rvalid), .d_rready(gbus_routed_rready)
  );

  uvhs_gbus_c2h_dma #(.AXIS_DATA_WIDTH(`CONFIG_DIFFTEST_HOST_AXIS_WIDTH)) U_GBUS_C2H_DMA (
    .clk(gbus_host_clk), .rstn(rstn_sw4), .stream_rstn(difftest_c2h_rstn),
    .s_tdata(difftest_to_host_axis_tdata), .s_tkeep(difftest_to_host_axis_tkeep),
    .s_tlast(difftest_to_host_axis_tlast), .s_tvalid(difftest_to_host_axis_tvalid_io), .s_tready(gbus_c2h_sready),
    .cfg_wr_en(gbus_c2h_cfg_wr_en), .cfg_wr_addr(gbus_cfg_local_wr_addr), .cfg_wdata(gbus_cfg_wdata),
    .cfg_rd_en(gbus_c2h_cfg_rd_en), .cfg_rd_addr(gbus_cfg_local_rd_addr),
    .cfg_rdata(gbus_c2h_cfg_rdata), .cfg_rdata_vld(gbus_c2h_cfg_rdata_vld),
    .s_arid(gbus_local_arid), .s_araddr(gbus_local_araddr), .s_arlen(gbus_local_arlen),
    .s_arsize(gbus_local_arsize), .s_arburst(gbus_local_arburst),
    .s_arvalid(gbus_local_arvalid), .s_arready(gbus_local_arready),
    .s_rid(gbus_local_rid), .s_rdata(gbus_local_rdata), .s_rresp(gbus_local_rresp),
    .s_rlast(gbus_local_rlast), .s_rvalid(gbus_local_rvalid), .s_rready(gbus_local_rready)
  );

  uvhs_gbus_axi_write_guard U_GBUS_WRITE_GUARD (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .s_awid(gbus_axi_awid), .s_awaddr(gbus_axi_awaddr), .s_awlen(gbus_axi_awlen),
    .s_awsize(gbus_axi_awsize), .s_awburst(gbus_axi_awburst), .s_awlock(gbus_axi_awlock),
    .s_awcache(gbus_axi_awcache), .s_awprot(gbus_axi_awprot), .s_awqos(gbus_axi_awqos),
    .s_awvalid(gbus_axi_awvalid), .s_awready(gbus_axi_awready),
    .s_wid(gbus_axi_wid), .s_wdata(gbus_axi_wdata), .s_wstrb(gbus_axi_wstrb),
    .s_wlast(gbus_axi_wlast), .s_wvalid(gbus_axi_wvalid), .s_wready(gbus_axi_wready),
    .s_bid(gbus_axi_bid), .s_bresp(gbus_axi_bresp), .s_bvalid(gbus_axi_bvalid), .s_bready(gbus_axi_bready),
    .d_awid(gbus_guard_awid), .d_awaddr(gbus_guard_awaddr), .d_awlen(gbus_guard_awlen),
    .d_awsize(gbus_guard_awsize), .d_awburst(gbus_guard_awburst), .d_awlock(gbus_guard_awlock),
    .d_awcache(gbus_guard_awcache), .d_awprot(gbus_guard_awprot), .d_awqos(gbus_guard_awqos),
    .d_awvalid(gbus_guard_awvalid), .d_awready(gbus_guard_awready),
    .d_wid(gbus_guard_wid), .d_wdata(gbus_guard_wdata), .d_wstrb(gbus_guard_wstrb),
    .d_wlast(gbus_guard_wlast), .d_wvalid(gbus_guard_wvalid), .d_wready(gbus_guard_wready),
    .d_bid(gbus_guard_bid), .d_bresp(gbus_guard_bresp), .d_bvalid(gbus_guard_bvalid), .d_bready(gbus_guard_bready)
  );

  uvhs_axi3_to_axi4_adapter #(.ADDR_WIDTH(34), .ID_WIDTH(14), .DATA_WIDTH(256)) U_GBUS_AXI_ADAPTER (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .s_awid(gbus_guard_awid), .s_awaddr({2'b0, gbus_guard_awaddr}), .s_awlen(gbus_guard_awlen),
    .s_awsize(gbus_guard_awsize), .s_awburst(gbus_guard_awburst), .s_awlock(gbus_guard_awlock),
    .s_awcache(gbus_guard_awcache), .s_awprot(gbus_guard_awprot), .s_awqos(gbus_guard_awqos),
    .s_awvalid(gbus_guard_awvalid), .s_awready(gbus_guard_awready),
    .s_wid(gbus_guard_wid), .s_wdata(gbus_guard_wdata), .s_wstrb(gbus_guard_wstrb),
    .s_wlast(gbus_guard_wlast), .s_wvalid(gbus_guard_wvalid), .s_wready(gbus_guard_wready),
    .s_bid(gbus_guard_bid), .s_bresp(gbus_guard_bresp), .s_bvalid(gbus_guard_bvalid), .s_bready(gbus_guard_bready),
    .s_arid(gbus_routed_arid), .s_araddr({2'b0, gbus_routed_araddr}), .s_arlen(gbus_routed_arlen),
    .s_arsize(gbus_routed_arsize), .s_arburst(gbus_routed_arburst), .s_arlock(gbus_routed_arlock),
    .s_arcache(gbus_routed_arcache), .s_arprot(gbus_routed_arprot), .s_arqos(gbus_routed_arqos),
    .s_arvalid(gbus_routed_arvalid), .s_arready(gbus_routed_arready),
    .s_rid(gbus_routed_rid), .s_rdata(gbus_routed_rdata), .s_rresp(gbus_routed_rresp),
    .s_rlast(gbus_routed_rlast), .s_rvalid(gbus_routed_rvalid), .s_rready(gbus_routed_rready),
    .m_awid(ddr_awid), .m_awaddr(ddr_awaddr), .m_awlen(ddr_awlen), .m_awsize(ddr_awsize),
    .m_awburst(ddr_awburst), .m_awlock(ddr_awlock), .m_awcache(ddr_awcache), .m_awprot(ddr_awprot),
    .m_awqos(ddr_awqos), .m_awregion(ddr_awregion), .m_awvalid(ddr_awvalid), .m_awready(ddr_awready),
    .m_wdata(ddr_wdata), .m_wstrb(ddr_wstrb), .m_wlast(ddr_wlast), .m_wvalid(ddr_wvalid), .m_wready(ddr_wready),
    .m_bid(ddr_bid), .m_bresp(ddr_bresp), .m_bvalid(ddr_bvalid), .m_bready(ddr_bready),
    .m_arid(ddr_arid), .m_araddr(ddr_araddr), .m_arlen(ddr_arlen), .m_arsize(ddr_arsize),
    .m_arburst(ddr_arburst), .m_arlock(ddr_arlock), .m_arcache(ddr_arcache), .m_arprot(ddr_arprot),
    .m_arqos(ddr_arqos), .m_arregion(ddr_arregion), .m_arvalid(ddr_arvalid), .m_arready(ddr_arready),
    .m_rid(ddr_rid), .m_rdata(ddr_rdata), .m_rresp(ddr_rresp), .m_rlast(ddr_rlast), .m_rvalid(ddr_rvalid), .m_rready(ddr_rready)
  );
