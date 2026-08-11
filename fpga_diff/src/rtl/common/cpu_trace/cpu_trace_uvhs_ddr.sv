`timescale 1ns/1ps

// UVHS implementation wrapper for the two passive trace DDR channels.
module cpu_trace_uvhs_ddr (
    input  wire         cpu_clk,
    input  wire         cpu_ctrl_clk,
    input  wire         trace_clk,
    input  wire         resetn,
    input  wire [691:0] trace_data,
    input  wire         trace_valid,
    output wire         trace_ready
);
    wire [13:0] ch0_awid, ch1_awid;
    wire [33:0] ch0_awaddr, ch1_awaddr;
    wire [7:0] ch0_awlen, ch1_awlen;
    wire [2:0] ch0_awsize, ch1_awsize;
    wire [1:0] ch0_awburst, ch1_awburst;
    wire ch0_awlock, ch1_awlock;
    wire [3:0] ch0_awcache, ch1_awcache;
    wire [2:0] ch0_awprot, ch1_awprot;
    wire [3:0] ch0_awqos, ch1_awqos;
    wire ch0_awvalid, ch1_awvalid;
    wire ch0_awready, ch1_awready;
    wire [255:0] ch0_wdata, ch1_wdata;
    wire [31:0] ch0_wstrb, ch1_wstrb;
    wire ch0_wlast, ch1_wlast;
    wire ch0_wvalid, ch1_wvalid;
    wire ch0_wready, ch1_wready;
    wire [13:0] ch0_bid, ch1_bid;
    wire [1:0] ch0_bresp, ch1_bresp;
    wire ch0_bvalid, ch1_bvalid;
    wire ch0_bready, ch1_bready;
    wire ch0_user_clk, ch1_user_clk;
    wire ch0_user_rst, ch1_user_rst;
    wire [255:0] ch0_sysbus_o, ch1_sysbus_o;

    cpu_trace_axi_ddr_core0 #(
        .ADDR_WIDTH     (34),
        .ID_WIDTH       (14),
        // CH0 data grows upward from 0; metadata grows independently from
        // 8 GiB, allowing at least 134,217,728 snapshots before overlap.
        .META_BASE_ADDR (34'h2_0000_0000)
    ) u_trace_core0 (
        .cpu_clk(cpu_clk), .cpu_ctrl_clk(cpu_ctrl_clk),
        .trace_clk(trace_clk), .resetn(resetn),
        .trace_data(trace_data), .trace_valid(trace_valid),
        .trace_ready(trace_ready),
        .m0_axi_awid(ch0_awid), .m0_axi_awaddr(ch0_awaddr),
        .m0_axi_awlen(ch0_awlen), .m0_axi_awsize(ch0_awsize),
        .m0_axi_awburst(ch0_awburst), .m0_axi_awlock(ch0_awlock),
        .m0_axi_awcache(ch0_awcache), .m0_axi_awprot(ch0_awprot),
        .m0_axi_awqos(ch0_awqos), .m0_axi_awvalid(ch0_awvalid),
        .m0_axi_awready(ch0_awready), .m0_axi_wdata(ch0_wdata),
        .m0_axi_wstrb(ch0_wstrb), .m0_axi_wlast(ch0_wlast),
        .m0_axi_wvalid(ch0_wvalid), .m0_axi_wready(ch0_wready),
        .m0_axi_bid(ch0_bid), .m0_axi_bresp(ch0_bresp),
        .m0_axi_bvalid(ch0_bvalid), .m0_axi_bready(ch0_bready),
        .m1_axi_awid(ch1_awid), .m1_axi_awaddr(ch1_awaddr),
        .m1_axi_awlen(ch1_awlen), .m1_axi_awsize(ch1_awsize),
        .m1_axi_awburst(ch1_awburst), .m1_axi_awlock(ch1_awlock),
        .m1_axi_awcache(ch1_awcache), .m1_axi_awprot(ch1_awprot),
        .m1_axi_awqos(ch1_awqos), .m1_axi_awvalid(ch1_awvalid),
        .m1_axi_awready(ch1_awready), .m1_axi_wdata(ch1_wdata),
        .m1_axi_wstrb(ch1_wstrb), .m1_axi_wlast(ch1_wlast),
        .m1_axi_wvalid(ch1_wvalid), .m1_axi_wready(ch1_wready),
        .m1_axi_bid(ch1_bid), .m1_axi_bresp(ch1_bresp),
        .m1_axi_bvalid(ch1_bvalid), .m1_axi_bready(ch1_bready)
    );

`define UVHS_TRACE_DDR_INSTANCE(INST, PFX, USER_CLK, USER_RST, SYSBUS_O) \
    uvw_axi4_to_ddr4 INST ( \
      .ddr4ip_dut_axi_aclk(trace_clk), .ddr4ip_dut_axi_aresetn(resetn), \
      .ddr4ip_dut_axi_awaddr(PFX``_awaddr), \
      .ddr4ip_dut_axi_awburst(PFX``_awburst), \
      .ddr4ip_dut_axi_awcache(PFX``_awcache), \
      .ddr4ip_dut_axi_awid(PFX``_awid), .ddr4ip_dut_axi_awlen(PFX``_awlen), \
      .ddr4ip_dut_axi_awlock(PFX``_awlock), \
      .ddr4ip_dut_axi_awprot(PFX``_awprot), .ddr4ip_dut_axi_awqos(PFX``_awqos), \
      .ddr4ip_dut_axi_awready(PFX``_awready), .ddr4ip_dut_axi_awregion(4'b0), \
      .ddr4ip_dut_axi_awsize(PFX``_awsize), .ddr4ip_dut_axi_awvalid(PFX``_awvalid), \
      .ddr4ip_dut_axi_wdata(PFX``_wdata), .ddr4ip_dut_axi_wlast(PFX``_wlast), \
      .ddr4ip_dut_axi_wready(PFX``_wready), .ddr4ip_dut_axi_wstrb(PFX``_wstrb), \
      .ddr4ip_dut_axi_wvalid(PFX``_wvalid), .ddr4ip_dut_axi_bid(PFX``_bid), \
      .ddr4ip_dut_axi_bready(PFX``_bready), .ddr4ip_dut_axi_bresp(PFX``_bresp), \
      .ddr4ip_dut_axi_bvalid(PFX``_bvalid), .ddr4ip_dut_axi_araddr(34'b0), \
      .ddr4ip_dut_axi_arburst(2'b01), .ddr4ip_dut_axi_arcache(4'b0011), \
      .ddr4ip_dut_axi_arid(14'b0), .ddr4ip_dut_axi_arlen(8'b0), \
      .ddr4ip_dut_axi_arlock(1'b0), .ddr4ip_dut_axi_arprot(3'b0), \
      .ddr4ip_dut_axi_arqos(4'b0), .ddr4ip_dut_axi_arready(), \
      .ddr4ip_dut_axi_arregion(4'b0), .ddr4ip_dut_axi_arsize(3'd5), \
      .ddr4ip_dut_axi_arvalid(1'b0), .ddr4ip_dut_axi_rdata(), \
      .ddr4ip_dut_axi_rid(), .ddr4ip_dut_axi_rlast(), .ddr4ip_dut_axi_rready(1'b1), \
      .ddr4ip_dut_axi_rresp(), .ddr4ip_dut_axi_rvalid(), \
      .ddr4ip_dut_axi_aclk_en(1'b1), .ddr4ip_ddr4_user_clk(USER_CLK), \
      .ddr4ip_ddr4_user_rst(USER_RST), .sysbus_ghbd_i(256'b0), \
      .sysbus_ghbd_o(SYSBUS_O), .FP_CLK_200M_P(), .FP_CLK_200M_N(), \
      .DDR4_DIMM_ACT_N(), .DDR4_DIMM_A(), .DDR4_DIMM_BA(), .DDR4_DIMM_BG(), \
      .DDR4_DIMM_CK_N(), .DDR4_DIMM_CK_P(), .DDR4_DIMM_CKE(), \
      .DDR4_DIMM_CS_N(), .DDR4_DIMM_ODT(), .DDR4_DIMM_RST_B(), \
      .DDR4_DIMM_DM(), .DDR4_DIMM_DQ(), .DDR4_DIMM_DQS_N(), .DDR4_DIMM_DQS_P() \
    );

    `UVHS_TRACE_DDR_INSTANCE(U_CPU_TRACE_CH0_DDR, ch0, ch0_user_clk,
                             ch0_user_rst, ch0_sysbus_o)
    `UVHS_TRACE_DDR_INSTANCE(U_CPU_TRACE_CH1_DDR, ch1, ch1_user_clk,
                             ch1_user_rst, ch1_sysbus_o)
`undef UVHS_TRACE_DDR_INSTANCE

    wire _unused_ddr_status = &{1'b0, ch0_user_clk, ch0_user_rst,
                                 ch1_user_clk, ch1_user_rst,
                                 ch0_sysbus_o, ch1_sysbus_o};
endmodule
