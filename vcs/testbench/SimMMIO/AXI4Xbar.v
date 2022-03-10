module AXI4Xbar(
  input         clock,
  input         reset,
  output        auto_in_awready,
  input         auto_in_awvalid,
  input  [1:0]  auto_in_awid,
  input  [30:0] auto_in_awaddr,
  input  [7:0]  auto_in_awlen,
  input  [2:0]  auto_in_awsize,
  input  [1:0]  auto_in_awburst,
  input         auto_in_awlock,
  input  [3:0]  auto_in_awcache,
  input  [2:0]  auto_in_awprot,
  input  [3:0]  auto_in_awqos,
  output        auto_in_wready,
  input         auto_in_wvalid,
  input  [63:0] auto_in_wdata,
  input  [7:0]  auto_in_wstrb,
  input         auto_in_wlast,
  input         auto_in_bready,
  output        auto_in_bvalid,
  output [1:0]  auto_in_bid,
  output [1:0]  auto_in_bresp,
  output        auto_in_arready,
  input         auto_in_arvalid,
  input  [1:0]  auto_in_arid,
  input  [30:0] auto_in_araddr,
  input  [7:0]  auto_in_arlen,
  input  [2:0]  auto_in_arsize,
  input  [1:0]  auto_in_arburst,
  input         auto_in_arlock,
  input  [3:0]  auto_in_arcache,
  input  [2:0]  auto_in_arprot,
  input  [3:0]  auto_in_arqos,
  input         auto_in_rready,
  output        auto_in_rvalid,
  output [1:0]  auto_in_rid,
  output [63:0] auto_in_rdata,
  output [1:0]  auto_in_rresp,
  output        auto_in_rlast,
  input         auto_out_5_awready,
  output        auto_out_5_awvalid,
  output [1:0]  auto_out_5_awid,
  output [30:0] auto_out_5_awaddr,
  output [7:0]  auto_out_5_awlen,
  output [2:0]  auto_out_5_awsize,
  output [1:0]  auto_out_5_awburst,
  output        auto_out_5_awlock,
  output [3:0]  auto_out_5_awcache,
  output [2:0]  auto_out_5_awprot,
  output [3:0]  auto_out_5_awqos,
  input         auto_out_5_wready,
  output        auto_out_5_wvalid,
  output [63:0] auto_out_5_wdata,
  output [7:0]  auto_out_5_wstrb,
  output        auto_out_5_wlast,
  output        auto_out_5_bready,
  input         auto_out_5_bvalid,
  input  [1:0]  auto_out_5_bid,
  input  [1:0]  auto_out_5_bresp,
  input         auto_out_5_arready,
  output        auto_out_5_arvalid,
  output [1:0]  auto_out_5_arid,
  output [30:0] auto_out_5_araddr,
  output [7:0]  auto_out_5_arlen,
  output [2:0]  auto_out_5_arsize,
  output [1:0]  auto_out_5_arburst,
  output        auto_out_5_arlock,
  output [3:0]  auto_out_5_arcache,
  output [2:0]  auto_out_5_arprot,
  output [3:0]  auto_out_5_arqos,
  output        auto_out_5_rready,
  input         auto_out_5_rvalid,
  input  [1:0]  auto_out_5_rid,
  input  [63:0] auto_out_5_rdata,
  input  [1:0]  auto_out_5_rresp,
  input         auto_out_5_rlast,
  input         auto_out_4_awready,
  output        auto_out_4_awvalid,
  output [1:0]  auto_out_4_awid,
  output [30:0] auto_out_4_awaddr,
  output [7:0]  auto_out_4_awlen,
  output [2:0]  auto_out_4_awsize,
  output [1:0]  auto_out_4_awburst,
  output        auto_out_4_awlock,
  output [3:0]  auto_out_4_awcache,
  output [2:0]  auto_out_4_awprot,
  output [3:0]  auto_out_4_awqos,
  input         auto_out_4_wready,
  output        auto_out_4_wvalid,
  output [63:0] auto_out_4_wdata,
  output [7:0]  auto_out_4_wstrb,
  output        auto_out_4_wlast,
  output        auto_out_4_bready,
  input         auto_out_4_bvalid,
  input  [1:0]  auto_out_4_bid,
  input  [1:0]  auto_out_4_bresp,
  input         auto_out_4_arready,
  output        auto_out_4_arvalid,
  output [1:0]  auto_out_4_arid,
  output [30:0] auto_out_4_araddr,
  output [7:0]  auto_out_4_arlen,
  output [2:0]  auto_out_4_arsize,
  output [1:0]  auto_out_4_arburst,
  output        auto_out_4_arlock,
  output [3:0]  auto_out_4_arcache,
  output [2:0]  auto_out_4_arprot,
  output [3:0]  auto_out_4_arqos,
  output        auto_out_4_rready,
  input         auto_out_4_rvalid,
  input  [1:0]  auto_out_4_rid,
  input  [63:0] auto_out_4_rdata,
  input  [1:0]  auto_out_4_rresp,
  input         auto_out_4_rlast,
  input         auto_out_3_awready,
  output        auto_out_3_awvalid,
  output [1:0]  auto_out_3_awid,
  output [28:0] auto_out_3_awaddr,
  output [7:0]  auto_out_3_awlen,
  output [2:0]  auto_out_3_awsize,
  output [1:0]  auto_out_3_awburst,
  output        auto_out_3_awlock,
  output [3:0]  auto_out_3_awcache,
  output [2:0]  auto_out_3_awprot,
  output [3:0]  auto_out_3_awqos,
  input         auto_out_3_wready,
  output        auto_out_3_wvalid,
  output [63:0] auto_out_3_wdata,
  output [7:0]  auto_out_3_wstrb,
  output        auto_out_3_wlast,
  output        auto_out_3_bready,
  input         auto_out_3_bvalid,
  input  [1:0]  auto_out_3_bid,
  input  [1:0]  auto_out_3_bresp,
  input         auto_out_3_arready,
  output        auto_out_3_arvalid,
  output [1:0]  auto_out_3_arid,
  output [28:0] auto_out_3_araddr,
  output [7:0]  auto_out_3_arlen,
  output [2:0]  auto_out_3_arsize,
  output [1:0]  auto_out_3_arburst,
  output        auto_out_3_arlock,
  output [3:0]  auto_out_3_arcache,
  output [2:0]  auto_out_3_arprot,
  output [3:0]  auto_out_3_arqos,
  output        auto_out_3_rready,
  input         auto_out_3_rvalid,
  input  [1:0]  auto_out_3_rid,
  input  [63:0] auto_out_3_rdata,
  input  [1:0]  auto_out_3_rresp,
  input         auto_out_3_rlast,
  input         auto_out_2_awready,
  output        auto_out_2_awvalid,
  output [1:0]  auto_out_2_awid,
  output [30:0] auto_out_2_awaddr,
  output [7:0]  auto_out_2_awlen,
  output [2:0]  auto_out_2_awsize,
  output [1:0]  auto_out_2_awburst,
  output        auto_out_2_awlock,
  output [3:0]  auto_out_2_awcache,
  output [2:0]  auto_out_2_awprot,
  output [3:0]  auto_out_2_awqos,
  input         auto_out_2_wready,
  output        auto_out_2_wvalid,
  output [63:0] auto_out_2_wdata,
  output [7:0]  auto_out_2_wstrb,
  output        auto_out_2_wlast,
  output        auto_out_2_bready,
  input         auto_out_2_bvalid,
  input  [1:0]  auto_out_2_bid,
  input  [1:0]  auto_out_2_bresp,
  input         auto_out_2_arready,
  output        auto_out_2_arvalid,
  output [1:0]  auto_out_2_arid,
  output [30:0] auto_out_2_araddr,
  output [7:0]  auto_out_2_arlen,
  output [2:0]  auto_out_2_arsize,
  output [1:0]  auto_out_2_arburst,
  output        auto_out_2_arlock,
  output [3:0]  auto_out_2_arcache,
  output [2:0]  auto_out_2_arprot,
  output [3:0]  auto_out_2_arqos,
  output        auto_out_2_rready,
  input         auto_out_2_rvalid,
  input  [1:0]  auto_out_2_rid,
  input  [63:0] auto_out_2_rdata,
  input  [1:0]  auto_out_2_rresp,
  input         auto_out_2_rlast,
  input         auto_out_1_awready,
  output        auto_out_1_awvalid,
  output [1:0]  auto_out_1_awid,
  output [30:0] auto_out_1_awaddr,
  output [7:0]  auto_out_1_awlen,
  output [2:0]  auto_out_1_awsize,
  output [1:0]  auto_out_1_awburst,
  output        auto_out_1_awlock,
  output [3:0]  auto_out_1_awcache,
  output [2:0]  auto_out_1_awprot,
  output [3:0]  auto_out_1_awqos,
  input         auto_out_1_wready,
  output        auto_out_1_wvalid,
  output [63:0] auto_out_1_wdata,
  output [7:0]  auto_out_1_wstrb,
  output        auto_out_1_wlast,
  output        auto_out_1_bready,
  input         auto_out_1_bvalid,
  input  [1:0]  auto_out_1_bid,
  input  [1:0]  auto_out_1_bresp,
  output        auto_out_1_arvalid,
  output [1:0]  auto_out_1_arid,
  output [7:0]  auto_out_1_arlen,
  output [2:0]  auto_out_1_arsize,
  output [1:0]  auto_out_1_arburst,
  output        auto_out_1_arlock,
  output [3:0]  auto_out_1_arcache,
  output [3:0]  auto_out_1_arqos,
  output        auto_out_1_rready,
  input         auto_out_1_rvalid,
  input  [1:0]  auto_out_1_rid,
  input         auto_out_1_rlast,
  input         auto_out_0_awready,
  output        auto_out_0_awvalid,
  output [1:0]  auto_out_0_awid,
  output [30:0] auto_out_0_awaddr,
  output [7:0]  auto_out_0_awlen,
  output [2:0]  auto_out_0_awsize,
  output [1:0]  auto_out_0_awburst,
  output        auto_out_0_awlock,
  output [3:0]  auto_out_0_awcache,
  output [2:0]  auto_out_0_awprot,
  output [3:0]  auto_out_0_awqos,
  input         auto_out_0_wready,
  output        auto_out_0_wvalid,
  output [63:0] auto_out_0_wdata,
  output [7:0]  auto_out_0_wstrb,
  output        auto_out_0_wlast,
  output        auto_out_0_bready,
  input         auto_out_0_bvalid,
  input  [1:0]  auto_out_0_bid,
  input  [1:0]  auto_out_0_bresp,
  input         auto_out_0_arready,
  output        auto_out_0_arvalid,
  output [1:0]  auto_out_0_arid,
  output [30:0] auto_out_0_araddr,
  output [7:0]  auto_out_0_arlen,
  output [2:0]  auto_out_0_arsize,
  output [1:0]  auto_out_0_arburst,
  output        auto_out_0_arlock,
  output [3:0]  auto_out_0_arcache,
  output [2:0]  auto_out_0_arprot,
  output [3:0]  auto_out_0_arqos,
  output        auto_out_0_rready,
  input         auto_out_0_rvalid,
  input  [1:0]  auto_out_0_rid,
  input  [63:0] auto_out_0_rdata,
  input  [1:0]  auto_out_0_rresp,
  input         auto_out_0_rlast
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_14;
  reg [31:0] _RAND_15;
  reg [31:0] _RAND_16;
`endif // RANDOMIZE_REG_INIT
  wire  awIn_0_clock; // @[Xbar.scala 62:47]
  wire  awIn_0_reset; // @[Xbar.scala 62:47]
  wire  awIn_0_io_enq_ready; // @[Xbar.scala 62:47]
  wire  awIn_0_io_enq_valid; // @[Xbar.scala 62:47]
  wire [5:0] awIn_0_io_enq_bits; // @[Xbar.scala 62:47]
  wire  awIn_0_io_deq_ready; // @[Xbar.scala 62:47]
  wire  awIn_0_io_deq_valid; // @[Xbar.scala 62:47]
  wire [5:0] awIn_0_io_deq_bits; // @[Xbar.scala 62:47]
  wire [30:0] _requestARIO_T = auto_in_araddr ^ 31'h40200000; // @[Parameters.scala 137:31]
  wire [31:0] _requestARIO_T_1 = {1'b0,$signed(_requestARIO_T)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestARIO_T_3 = $signed(_requestARIO_T_1) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_0 = $signed(_requestARIO_T_3) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestARIO_T_5 = auto_in_araddr ^ 31'h50000000; // @[Parameters.scala 137:31]
  wire [31:0] _requestARIO_T_6 = {1'b0,$signed(_requestARIO_T_5)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestARIO_T_8 = $signed(_requestARIO_T_6) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_1 = $signed(_requestARIO_T_8) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestARIO_T_10 = auto_in_araddr ^ 31'h40000000; // @[Parameters.scala 137:31]
  wire [31:0] _requestARIO_T_11 = {1'b0,$signed(_requestARIO_T_10)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestARIO_T_13 = $signed(_requestARIO_T_11) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_2 = $signed(_requestARIO_T_13) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestARIO_T_15 = auto_in_araddr ^ 31'h10000000; // @[Parameters.scala 137:31]
  wire [31:0] _requestARIO_T_16 = {1'b0,$signed(_requestARIO_T_15)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestARIO_T_18 = $signed(_requestARIO_T_16) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_3 = $signed(_requestARIO_T_18) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestARIO_T_20 = auto_in_araddr ^ 31'h40002000; // @[Parameters.scala 137:31]
  wire [31:0] _requestARIO_T_21 = {1'b0,$signed(_requestARIO_T_20)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestARIO_T_23 = $signed(_requestARIO_T_21) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_4 = $signed(_requestARIO_T_23) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestARIO_T_25 = auto_in_araddr ^ 31'h40040000; // @[Parameters.scala 137:31]
  wire [31:0] _requestARIO_T_26 = {1'b0,$signed(_requestARIO_T_25)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestARIO_T_28 = $signed(_requestARIO_T_26) & 32'sh50240000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_5 = $signed(_requestARIO_T_28) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestAWIO_T = auto_in_awaddr ^ 31'h40200000; // @[Parameters.scala 137:31]
  wire [31:0] _requestAWIO_T_1 = {1'b0,$signed(_requestAWIO_T)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestAWIO_T_3 = $signed(_requestAWIO_T_1) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_0 = $signed(_requestAWIO_T_3) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestAWIO_T_5 = auto_in_awaddr ^ 31'h50000000; // @[Parameters.scala 137:31]
  wire [31:0] _requestAWIO_T_6 = {1'b0,$signed(_requestAWIO_T_5)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestAWIO_T_8 = $signed(_requestAWIO_T_6) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_1 = $signed(_requestAWIO_T_8) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestAWIO_T_10 = auto_in_awaddr ^ 31'h40000000; // @[Parameters.scala 137:31]
  wire [31:0] _requestAWIO_T_11 = {1'b0,$signed(_requestAWIO_T_10)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestAWIO_T_13 = $signed(_requestAWIO_T_11) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_2 = $signed(_requestAWIO_T_13) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestAWIO_T_15 = auto_in_awaddr ^ 31'h10000000; // @[Parameters.scala 137:31]
  wire [31:0] _requestAWIO_T_16 = {1'b0,$signed(_requestAWIO_T_15)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestAWIO_T_18 = $signed(_requestAWIO_T_16) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_3 = $signed(_requestAWIO_T_18) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestAWIO_T_20 = auto_in_awaddr ^ 31'h40002000; // @[Parameters.scala 137:31]
  wire [31:0] _requestAWIO_T_21 = {1'b0,$signed(_requestAWIO_T_20)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestAWIO_T_23 = $signed(_requestAWIO_T_21) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_4 = $signed(_requestAWIO_T_23) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _requestAWIO_T_25 = auto_in_awaddr ^ 31'h40040000; // @[Parameters.scala 137:31]
  wire [31:0] _requestAWIO_T_26 = {1'b0,$signed(_requestAWIO_T_25)}; // @[Parameters.scala 137:49]
  wire [31:0] _requestAWIO_T_28 = $signed(_requestAWIO_T_26) & 32'sh50240000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_5 = $signed(_requestAWIO_T_28) == 32'sh0; // @[Parameters.scala 137:67]
  wire [2:0] awIn_0_io_enq_bits_lo = {requestAWIO_0_2,requestAWIO_0_1,requestAWIO_0_0}; // @[Xbar.scala 71:75]
  wire [2:0] awIn_0_io_enq_bits_hi = {requestAWIO_0_5,requestAWIO_0_4,requestAWIO_0_3}; // @[Xbar.scala 71:75]
  wire  requestWIO_0_0 = awIn_0_io_deq_bits[0]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_1 = awIn_0_io_deq_bits[1]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_2 = awIn_0_io_deq_bits[2]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_3 = awIn_0_io_deq_bits[3]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_4 = awIn_0_io_deq_bits[4]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_5 = awIn_0_io_deq_bits[5]; // @[Xbar.scala 72:73]
  reg  idle_6; // @[Xbar.scala 249:23]
  wire [5:0] readys_valid = {auto_out_5_rvalid,auto_out_4_rvalid,auto_out_3_rvalid,auto_out_2_rvalid,
    auto_out_1_rvalid,auto_out_0_rvalid}; // @[Cat.scala 30:58]
  reg [5:0] readys_mask; // @[Arbiter.scala 23:23]
  wire [5:0] _readys_filter_T = ~readys_mask; // @[Arbiter.scala 24:30]
  wire [5:0] _readys_filter_T_1 = readys_valid & _readys_filter_T; // @[Arbiter.scala 24:28]
  wire [11:0] readys_filter = {_readys_filter_T_1,auto_out_5_rvalid,auto_out_4_rvalid,auto_out_3_rvalid,
    auto_out_2_rvalid,auto_out_1_rvalid,auto_out_0_rvalid}; // @[Cat.scala 30:58]
  wire [11:0] _GEN_48 = {{1'd0}, readys_filter[11:1]}; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_1 = readys_filter | _GEN_48; // @[package.scala 253:43]
  wire [11:0] _GEN_49 = {{2'd0}, _readys_unready_T_1[11:2]}; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_3 = _readys_unready_T_1 | _GEN_49; // @[package.scala 253:43]
  wire [11:0] _GEN_50 = {{4'd0}, _readys_unready_T_3[11:4]}; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_5 = _readys_unready_T_3 | _GEN_50; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_8 = {readys_mask, 6'h0}; // @[Arbiter.scala 25:66]
  wire [11:0] _GEN_51 = {{1'd0}, _readys_unready_T_5[11:1]}; // @[Arbiter.scala 25:58]
  wire [11:0] readys_unready = _GEN_51 | _readys_unready_T_8; // @[Arbiter.scala 25:58]
  wire [5:0] _readys_readys_T_2 = readys_unready[11:6] & readys_unready[5:0]; // @[Arbiter.scala 26:39]
  wire [5:0] readys_readys = ~_readys_readys_T_2; // @[Arbiter.scala 26:18]
  wire  readys_6_0 = readys_readys[0]; // @[Xbar.scala 255:69]
  wire  winner_6_0 = readys_6_0 & auto_out_0_rvalid; // @[Xbar.scala 257:63]
  reg  state_6_0; // @[Xbar.scala 268:24]
  wire  muxState_6_0 = idle_6 ? winner_6_0 : state_6_0; // @[Xbar.scala 269:23]
  wire [1:0] _T_150 = muxState_6_0 ? auto_out_0_rid : 2'h0; // @[Mux.scala 27:72]
  wire  readys_6_1 = readys_readys[1]; // @[Xbar.scala 255:69]
  wire  winner_6_1 = readys_6_1 & auto_out_1_rvalid; // @[Xbar.scala 257:63]
  reg  state_6_1; // @[Xbar.scala 268:24]
  wire  muxState_6_1 = idle_6 ? winner_6_1 : state_6_1; // @[Xbar.scala 269:23]
  wire [1:0] _T_151 = muxState_6_1 ? auto_out_1_rid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_156 = _T_150 | _T_151; // @[Mux.scala 27:72]
  wire  readys_6_2 = readys_readys[2]; // @[Xbar.scala 255:69]
  wire  winner_6_2 = readys_6_2 & auto_out_2_rvalid; // @[Xbar.scala 257:63]
  reg  state_6_2; // @[Xbar.scala 268:24]
  wire  muxState_6_2 = idle_6 ? winner_6_2 : state_6_2; // @[Xbar.scala 269:23]
  wire [1:0] _T_152 = muxState_6_2 ? auto_out_2_rid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_157 = _T_156 | _T_152; // @[Mux.scala 27:72]
  wire  readys_6_3 = readys_readys[3]; // @[Xbar.scala 255:69]
  wire  winner_6_3 = readys_6_3 & auto_out_3_rvalid; // @[Xbar.scala 257:63]
  reg  state_6_3; // @[Xbar.scala 268:24]
  wire  muxState_6_3 = idle_6 ? winner_6_3 : state_6_3; // @[Xbar.scala 269:23]
  wire [1:0] _T_153 = muxState_6_3 ? auto_out_3_rid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_158 = _T_157 | _T_153; // @[Mux.scala 27:72]
  wire  readys_6_4 = readys_readys[4]; // @[Xbar.scala 255:69]
  wire  winner_6_4 = readys_6_4 & auto_out_4_rvalid; // @[Xbar.scala 257:63]
  reg  state_6_4; // @[Xbar.scala 268:24]
  wire  muxState_6_4 = idle_6 ? winner_6_4 : state_6_4; // @[Xbar.scala 269:23]
  wire [1:0] _T_154 = muxState_6_4 ? auto_out_4_rid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_159 = _T_158 | _T_154; // @[Mux.scala 27:72]
  wire  readys_6_5 = readys_readys[5]; // @[Xbar.scala 255:69]
  wire  winner_6_5 = readys_6_5 & auto_out_5_rvalid; // @[Xbar.scala 257:63]
  reg  state_6_5; // @[Xbar.scala 268:24]
  wire  muxState_6_5 = idle_6 ? winner_6_5 : state_6_5; // @[Xbar.scala 269:23]
  wire [1:0] _T_155 = muxState_6_5 ? auto_out_5_rid : 2'h0; // @[Mux.scala 27:72]
  reg  idle_7; // @[Xbar.scala 249:23]
  wire [5:0] readys_valid_1 = {auto_out_5_bvalid,auto_out_4_bvalid,auto_out_3_bvalid,auto_out_2_bvalid,
    auto_out_1_bvalid,auto_out_0_bvalid}; // @[Cat.scala 30:58]
  reg [5:0] readys_mask_1; // @[Arbiter.scala 23:23]
  wire [5:0] _readys_filter_T_2 = ~readys_mask_1; // @[Arbiter.scala 24:30]
  wire [5:0] _readys_filter_T_3 = readys_valid_1 & _readys_filter_T_2; // @[Arbiter.scala 24:28]
  wire [11:0] readys_filter_1 = {_readys_filter_T_3,auto_out_5_bvalid,auto_out_4_bvalid,auto_out_3_bvalid,
    auto_out_2_bvalid,auto_out_1_bvalid,auto_out_0_bvalid}; // @[Cat.scala 30:58]
  wire [11:0] _GEN_52 = {{1'd0}, readys_filter_1[11:1]}; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_10 = readys_filter_1 | _GEN_52; // @[package.scala 253:43]
  wire [11:0] _GEN_53 = {{2'd0}, _readys_unready_T_10[11:2]}; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_12 = _readys_unready_T_10 | _GEN_53; // @[package.scala 253:43]
  wire [11:0] _GEN_54 = {{4'd0}, _readys_unready_T_12[11:4]}; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_14 = _readys_unready_T_12 | _GEN_54; // @[package.scala 253:43]
  wire [11:0] _readys_unready_T_17 = {readys_mask_1, 6'h0}; // @[Arbiter.scala 25:66]
  wire [11:0] _GEN_55 = {{1'd0}, _readys_unready_T_14[11:1]}; // @[Arbiter.scala 25:58]
  wire [11:0] readys_unready_1 = _GEN_55 | _readys_unready_T_17; // @[Arbiter.scala 25:58]
  wire [5:0] _readys_readys_T_5 = readys_unready_1[11:6] & readys_unready_1[5:0]; // @[Arbiter.scala 26:39]
  wire [5:0] readys_readys_1 = ~_readys_readys_T_5; // @[Arbiter.scala 26:18]
  wire  readys_7_0 = readys_readys_1[0]; // @[Xbar.scala 255:69]
  wire  winner_7_0 = readys_7_0 & auto_out_0_bvalid; // @[Xbar.scala 257:63]
  reg  state_7_0; // @[Xbar.scala 268:24]
  wire  muxState_7_0 = idle_7 ? winner_7_0 : state_7_0; // @[Xbar.scala 269:23]
  wire [1:0] _T_209 = muxState_7_0 ? auto_out_0_bid : 2'h0; // @[Mux.scala 27:72]
  wire  readys_7_1 = readys_readys_1[1]; // @[Xbar.scala 255:69]
  wire  winner_7_1 = readys_7_1 & auto_out_1_bvalid; // @[Xbar.scala 257:63]
  reg  state_7_1; // @[Xbar.scala 268:24]
  wire  muxState_7_1 = idle_7 ? winner_7_1 : state_7_1; // @[Xbar.scala 269:23]
  wire [1:0] _T_210 = muxState_7_1 ? auto_out_1_bid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_215 = _T_209 | _T_210; // @[Mux.scala 27:72]
  wire  readys_7_2 = readys_readys_1[2]; // @[Xbar.scala 255:69]
  wire  winner_7_2 = readys_7_2 & auto_out_2_bvalid; // @[Xbar.scala 257:63]
  reg  state_7_2; // @[Xbar.scala 268:24]
  wire  muxState_7_2 = idle_7 ? winner_7_2 : state_7_2; // @[Xbar.scala 269:23]
  wire [1:0] _T_211 = muxState_7_2 ? auto_out_2_bid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_216 = _T_215 | _T_211; // @[Mux.scala 27:72]
  wire  readys_7_3 = readys_readys_1[3]; // @[Xbar.scala 255:69]
  wire  winner_7_3 = readys_7_3 & auto_out_3_bvalid; // @[Xbar.scala 257:63]
  reg  state_7_3; // @[Xbar.scala 268:24]
  wire  muxState_7_3 = idle_7 ? winner_7_3 : state_7_3; // @[Xbar.scala 269:23]
  wire [1:0] _T_212 = muxState_7_3 ? auto_out_3_bid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_217 = _T_216 | _T_212; // @[Mux.scala 27:72]
  wire  readys_7_4 = readys_readys_1[4]; // @[Xbar.scala 255:69]
  wire  winner_7_4 = readys_7_4 & auto_out_4_bvalid; // @[Xbar.scala 257:63]
  reg  state_7_4; // @[Xbar.scala 268:24]
  wire  muxState_7_4 = idle_7 ? winner_7_4 : state_7_4; // @[Xbar.scala 269:23]
  wire [1:0] _T_213 = muxState_7_4 ? auto_out_4_bid : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_218 = _T_217 | _T_213; // @[Mux.scala 27:72]
  wire  readys_7_5 = readys_readys_1[5]; // @[Xbar.scala 255:69]
  wire  winner_7_5 = readys_7_5 & auto_out_5_bvalid; // @[Xbar.scala 257:63]
  reg  state_7_5; // @[Xbar.scala 268:24]
  wire  muxState_7_5 = idle_7 ? winner_7_5 : state_7_5; // @[Xbar.scala 269:23]
  wire [1:0] _T_214 = muxState_7_5 ? auto_out_5_bid : 2'h0; // @[Mux.scala 27:72]
  wire  anyValid = auto_out_0_rvalid | auto_out_1_rvalid | auto_out_2_rvalid | auto_out_3_rvalid |
    auto_out_4_rvalid | auto_out_5_rvalid; // @[Xbar.scala 253:36]
  wire  _in_0_rvalid_T_10 = state_6_0 & auto_out_0_rvalid | state_6_1 & auto_out_1_rvalid | state_6_2 &
    auto_out_2_rvalid | state_6_3 & auto_out_3_rvalid | state_6_4 & auto_out_4_rvalid | state_6_5 &
    auto_out_5_rvalid; // @[Mux.scala 27:72]
  wire  in_0_rvalid = idle_6 ? anyValid : _in_0_rvalid_T_10; // @[Xbar.scala 285:22]
  wire  _arFIFOMap_0_T_4 = auto_in_rready & in_0_rvalid; // @[Decoupled.scala 40:37]
  wire  in_0_awready = requestAWIO_0_0 & auto_out_0_awready | requestAWIO_0_1 & auto_out_1_awready | requestAWIO_0_2
     & auto_out_2_awready | requestAWIO_0_3 & auto_out_3_awready | requestAWIO_0_4 & auto_out_4_awready |
    requestAWIO_0_5 & auto_out_5_awready; // @[Mux.scala 27:72]
  reg  latched; // @[Xbar.scala 144:30]
  wire  _bundleIn_0_awready_T = latched | awIn_0_io_enq_ready; // @[Xbar.scala 146:57]
  wire  anyValid_1 = auto_out_0_bvalid | auto_out_1_bvalid | auto_out_2_bvalid | auto_out_3_bvalid |
    auto_out_4_bvalid | auto_out_5_bvalid; // @[Xbar.scala 253:36]
  wire  _in_0_bvalid_T_10 = state_7_0 & auto_out_0_bvalid | state_7_1 & auto_out_1_bvalid | state_7_2 &
    auto_out_2_bvalid | state_7_3 & auto_out_3_bvalid | state_7_4 & auto_out_4_bvalid | state_7_5 &
    auto_out_5_bvalid; // @[Mux.scala 27:72]
  wire  in_0_bvalid = idle_7 ? anyValid_1 : _in_0_bvalid_T_10; // @[Xbar.scala 285:22]
  wire  _awFIFOMap_0_T_4 = auto_in_bready & in_0_bvalid; // @[Decoupled.scala 40:37]
  wire  in_0_awvalid = auto_in_awvalid & _bundleIn_0_awready_T; // @[Xbar.scala 145:45]
  wire  _T = awIn_0_io_enq_ready & awIn_0_io_enq_valid; // @[Decoupled.scala 40:37]
  wire  _GEN_16 = _T | latched; // @[Xbar.scala 144:30 148:{38,48}]
  wire  _T_1 = in_0_awready & in_0_awvalid; // @[Decoupled.scala 40:37]
  wire  in_0_wvalid = auto_in_wvalid & awIn_0_io_deq_valid; // @[Xbar.scala 152:43]
  wire  in_0_wready = requestWIO_0_0 & auto_out_0_wready | requestWIO_0_1 & auto_out_1_wready | requestWIO_0_2 &
    auto_out_2_wready | requestWIO_0_3 & auto_out_3_wready | requestWIO_0_4 & auto_out_4_wready | requestWIO_0_5 &
    auto_out_5_wready; // @[Mux.scala 27:72]
  wire [5:0] _readys_mask_T = readys_readys & readys_valid; // @[Arbiter.scala 28:29]
  wire [6:0] _readys_mask_T_1 = {_readys_mask_T, 1'h0}; // @[package.scala 244:48]
  wire [5:0] _readys_mask_T_3 = _readys_mask_T | _readys_mask_T_1[5:0]; // @[package.scala 244:43]
  wire [7:0] _readys_mask_T_4 = {_readys_mask_T_3, 2'h0}; // @[package.scala 244:48]
  wire [5:0] _readys_mask_T_6 = _readys_mask_T_3 | _readys_mask_T_4[5:0]; // @[package.scala 244:43]
  wire [9:0] _readys_mask_T_7 = {_readys_mask_T_6, 4'h0}; // @[package.scala 244:48]
  wire [5:0] _readys_mask_T_9 = _readys_mask_T_6 | _readys_mask_T_7[5:0]; // @[package.scala 244:43]
  wire  _GEN_43 = anyValid ? 1'h0 : idle_6; // @[Xbar.scala 273:21 249:23 273:28]
  wire  _GEN_44 = _arFIFOMap_0_T_4 | _GEN_43; // @[Xbar.scala 274:{24,31}]
  wire  allowed__0 = idle_6 ? readys_6_0 : state_6_0; // @[Xbar.scala 277:24]
  wire  allowed__1 = idle_6 ? readys_6_1 : state_6_1; // @[Xbar.scala 277:24]
  wire  allowed__2 = idle_6 ? readys_6_2 : state_6_2; // @[Xbar.scala 277:24]
  wire  allowed__3 = idle_6 ? readys_6_3 : state_6_3; // @[Xbar.scala 277:24]
  wire  allowed__4 = idle_6 ? readys_6_4 : state_6_4; // @[Xbar.scala 277:24]
  wire  allowed__5 = idle_6 ? readys_6_5 : state_6_5; // @[Xbar.scala 277:24]
  wire [1:0] _T_128 = muxState_6_0 ? auto_out_0_rresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_130 = muxState_6_2 ? auto_out_2_rresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_131 = muxState_6_3 ? auto_out_3_rresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_132 = muxState_6_4 ? auto_out_4_rresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_133 = muxState_6_5 ? auto_out_5_rresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_135 = _T_128 | _T_130; // @[Mux.scala 27:72]
  wire [1:0] _T_136 = _T_135 | _T_131; // @[Mux.scala 27:72]
  wire [1:0] _T_137 = _T_136 | _T_132; // @[Mux.scala 27:72]
  wire [63:0] _T_139 = muxState_6_0 ? auto_out_0_rdata : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_141 = muxState_6_2 ? auto_out_2_rdata : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_142 = muxState_6_3 ? auto_out_3_rdata : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_143 = muxState_6_4 ? auto_out_4_rdata : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_144 = muxState_6_5 ? auto_out_5_rdata : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_146 = _T_139 | _T_141; // @[Mux.scala 27:72]
  wire [63:0] _T_147 = _T_146 | _T_142; // @[Mux.scala 27:72]
  wire [63:0] _T_148 = _T_147 | _T_143; // @[Mux.scala 27:72]
  wire [5:0] _readys_mask_T_11 = readys_readys_1 & readys_valid_1; // @[Arbiter.scala 28:29]
  wire [6:0] _readys_mask_T_12 = {_readys_mask_T_11, 1'h0}; // @[package.scala 244:48]
  wire [5:0] _readys_mask_T_14 = _readys_mask_T_11 | _readys_mask_T_12[5:0]; // @[package.scala 244:43]
  wire [7:0] _readys_mask_T_15 = {_readys_mask_T_14, 2'h0}; // @[package.scala 244:48]
  wire [5:0] _readys_mask_T_17 = _readys_mask_T_14 | _readys_mask_T_15[5:0]; // @[package.scala 244:43]
  wire [9:0] _readys_mask_T_18 = {_readys_mask_T_17, 4'h0}; // @[package.scala 244:48]
  wire [5:0] _readys_mask_T_20 = _readys_mask_T_17 | _readys_mask_T_18[5:0]; // @[package.scala 244:43]
  wire  _GEN_46 = anyValid_1 ? 1'h0 : idle_7; // @[Xbar.scala 273:21 249:23 273:28]
  wire  _GEN_47 = _awFIFOMap_0_T_4 | _GEN_46; // @[Xbar.scala 274:{24,31}]
  wire  allowed_1_0 = idle_7 ? readys_7_0 : state_7_0; // @[Xbar.scala 277:24]
  wire  allowed_1_1 = idle_7 ? readys_7_1 : state_7_1; // @[Xbar.scala 277:24]
  wire  allowed_1_2 = idle_7 ? readys_7_2 : state_7_2; // @[Xbar.scala 277:24]
  wire  allowed_1_3 = idle_7 ? readys_7_3 : state_7_3; // @[Xbar.scala 277:24]
  wire  allowed_1_4 = idle_7 ? readys_7_4 : state_7_4; // @[Xbar.scala 277:24]
  wire  allowed_1_5 = idle_7 ? readys_7_5 : state_7_5; // @[Xbar.scala 277:24]
  wire [1:0] _T_198 = muxState_7_0 ? auto_out_0_bresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_199 = muxState_7_1 ? auto_out_1_bresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_200 = muxState_7_2 ? auto_out_2_bresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_201 = muxState_7_3 ? auto_out_3_bresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_202 = muxState_7_4 ? auto_out_4_bresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_203 = muxState_7_5 ? auto_out_5_bresp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_204 = _T_198 | _T_199; // @[Mux.scala 27:72]
  wire [1:0] _T_205 = _T_204 | _T_200; // @[Mux.scala 27:72]
  wire [1:0] _T_206 = _T_205 | _T_201; // @[Mux.scala 27:72]
  wire [1:0] _T_207 = _T_206 | _T_202; // @[Mux.scala 27:72]
  QueueCompatibility_140 awIn_0 ( // @[Xbar.scala 62:47]
    .clock(awIn_0_clock),
    .reset(awIn_0_reset),
    .io_enq_ready(awIn_0_io_enq_ready),
    .io_enq_valid(awIn_0_io_enq_valid),
    .io_enq_bits(awIn_0_io_enq_bits),
    .io_deq_ready(awIn_0_io_deq_ready),
    .io_deq_valid(awIn_0_io_deq_valid),
    .io_deq_bits(awIn_0_io_deq_bits)
  );
  assign auto_in_awready = in_0_awready & (latched | awIn_0_io_enq_ready); // @[Xbar.scala 146:45]
  assign auto_in_wready = in_0_wready & awIn_0_io_deq_valid; // @[Xbar.scala 153:43]
  assign auto_in_bvalid = idle_7 ? anyValid_1 : _in_0_bvalid_T_10; // @[Xbar.scala 285:22]
  assign auto_in_bid = _T_218 | _T_214; // @[Mux.scala 27:72]
  assign auto_in_bresp = _T_207 | _T_203; // @[Mux.scala 27:72]
  assign auto_in_arready = requestARIO_0_0 & auto_out_0_arready | requestARIO_0_1 | requestARIO_0_2 &
    auto_out_2_arready | requestARIO_0_3 & auto_out_3_arready | requestARIO_0_4 & auto_out_4_arready |
    requestARIO_0_5 & auto_out_5_arready; // @[Mux.scala 27:72]
  assign auto_in_rvalid = idle_6 ? anyValid : _in_0_rvalid_T_10; // @[Xbar.scala 285:22]
  assign auto_in_rid = _T_159 | _T_155; // @[Mux.scala 27:72]
  assign auto_in_rdata = _T_148 | _T_144; // @[Mux.scala 27:72]
  assign auto_in_rresp = _T_137 | _T_133; // @[Mux.scala 27:72]
  assign auto_in_rlast = muxState_6_0 & auto_out_0_rlast | muxState_6_1 & auto_out_1_rlast |
    muxState_6_2 & auto_out_2_rlast | muxState_6_3 & auto_out_3_rlast | muxState_6_4 &
    auto_out_4_rlast | muxState_6_5 & auto_out_5_rlast; // @[Mux.scala 27:72]
  assign auto_out_5_awvalid = in_0_awvalid & requestAWIO_0_5; // @[Xbar.scala 229:40]
  assign auto_out_5_awid = auto_in_awid; // @[Xbar.scala 86:47]
  assign auto_out_5_awaddr = auto_in_awaddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awlen = auto_in_awlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awsize = auto_in_awsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awburst = auto_in_awburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awlock = auto_in_awlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awcache = auto_in_awcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awprot = auto_in_awprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_awqos = auto_in_awqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_wvalid = in_0_wvalid & requestWIO_0_5; // @[Xbar.scala 229:40]
  assign auto_out_5_wdata = auto_in_wdata; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_wstrb = auto_in_wstrb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_wlast = auto_in_wlast; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_bready = auto_in_bready & allowed_1_5; // @[Xbar.scala 279:31]
  assign auto_out_5_arvalid = auto_in_arvalid & requestARIO_0_5; // @[Xbar.scala 229:40]
  assign auto_out_5_arid = auto_in_arid; // @[Xbar.scala 87:47]
  assign auto_out_5_araddr = auto_in_araddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arlen = auto_in_arlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arsize = auto_in_arsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arburst = auto_in_arburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arlock = auto_in_arlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arcache = auto_in_arcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arprot = auto_in_arprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_arqos = auto_in_arqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_rready = auto_in_rready & allowed__5; // @[Xbar.scala 279:31]
  assign auto_out_4_awvalid = in_0_awvalid & requestAWIO_0_4; // @[Xbar.scala 229:40]
  assign auto_out_4_awid = auto_in_awid; // @[Xbar.scala 86:47]
  assign auto_out_4_awaddr = auto_in_awaddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awlen = auto_in_awlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awsize = auto_in_awsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awburst = auto_in_awburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awlock = auto_in_awlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awcache = auto_in_awcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awprot = auto_in_awprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_awqos = auto_in_awqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_wvalid = in_0_wvalid & requestWIO_0_4; // @[Xbar.scala 229:40]
  assign auto_out_4_wdata = auto_in_wdata; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_wstrb = auto_in_wstrb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_wlast = auto_in_wlast; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_bready = auto_in_bready & allowed_1_4; // @[Xbar.scala 279:31]
  assign auto_out_4_arvalid = auto_in_arvalid & requestARIO_0_4; // @[Xbar.scala 229:40]
  assign auto_out_4_arid = auto_in_arid; // @[Xbar.scala 87:47]
  assign auto_out_4_araddr = auto_in_araddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arlen = auto_in_arlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arsize = auto_in_arsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arburst = auto_in_arburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arlock = auto_in_arlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arcache = auto_in_arcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arprot = auto_in_arprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_arqos = auto_in_arqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_rready = auto_in_rready & allowed__4; // @[Xbar.scala 279:31]
  assign auto_out_3_awvalid = in_0_awvalid & requestAWIO_0_3; // @[Xbar.scala 229:40]
  assign auto_out_3_awid = auto_in_awid; // @[Xbar.scala 86:47]
  assign auto_out_3_awaddr = auto_in_awaddr[28:0]; // @[Nodes.scala 1207:84 BundleMap.scala 247:19]
  assign auto_out_3_awlen = auto_in_awlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_awsize = auto_in_awsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_awburst = auto_in_awburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_awlock = auto_in_awlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_awcache = auto_in_awcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_awprot = auto_in_awprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_awqos = auto_in_awqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_wvalid = in_0_wvalid & requestWIO_0_3; // @[Xbar.scala 229:40]
  assign auto_out_3_wdata = auto_in_wdata; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_wstrb = auto_in_wstrb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_wlast = auto_in_wlast; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_bready = auto_in_bready & allowed_1_3; // @[Xbar.scala 279:31]
  assign auto_out_3_arvalid = auto_in_arvalid & requestARIO_0_3; // @[Xbar.scala 229:40]
  assign auto_out_3_arid = auto_in_arid; // @[Xbar.scala 87:47]
  assign auto_out_3_araddr = auto_in_araddr[28:0]; // @[Nodes.scala 1207:84 BundleMap.scala 247:19]
  assign auto_out_3_arlen = auto_in_arlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_arsize = auto_in_arsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_arburst = auto_in_arburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_arlock = auto_in_arlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_arcache = auto_in_arcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_arprot = auto_in_arprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_arqos = auto_in_arqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_rready = auto_in_rready & allowed__3; // @[Xbar.scala 279:31]
  assign auto_out_2_awvalid = in_0_awvalid & requestAWIO_0_2; // @[Xbar.scala 229:40]
  assign auto_out_2_awid = auto_in_awid; // @[Xbar.scala 86:47]
  assign auto_out_2_awaddr = auto_in_awaddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awlen = auto_in_awlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awsize = auto_in_awsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awburst = auto_in_awburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awlock = auto_in_awlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awcache = auto_in_awcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awprot = auto_in_awprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_awqos = auto_in_awqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_wvalid = in_0_wvalid & requestWIO_0_2; // @[Xbar.scala 229:40]
  assign auto_out_2_wdata = auto_in_wdata; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_wstrb = auto_in_wstrb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_wlast = auto_in_wlast; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_bready = auto_in_bready & allowed_1_2; // @[Xbar.scala 279:31]
  assign auto_out_2_arvalid = auto_in_arvalid & requestARIO_0_2; // @[Xbar.scala 229:40]
  assign auto_out_2_arid = auto_in_arid; // @[Xbar.scala 87:47]
  assign auto_out_2_araddr = auto_in_araddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arlen = auto_in_arlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arsize = auto_in_arsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arburst = auto_in_arburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arlock = auto_in_arlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arcache = auto_in_arcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arprot = auto_in_arprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_arqos = auto_in_arqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_rready = auto_in_rready & allowed__2; // @[Xbar.scala 279:31]
  assign auto_out_1_awvalid = in_0_awvalid & requestAWIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_awid = auto_in_awid; // @[Xbar.scala 86:47]
  assign auto_out_1_awaddr = auto_in_awaddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awlen = auto_in_awlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awsize = auto_in_awsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awburst = auto_in_awburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awlock = auto_in_awlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awcache = auto_in_awcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awprot = auto_in_awprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_awqos = auto_in_awqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_wvalid = in_0_wvalid & requestWIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_wdata = auto_in_wdata; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_wstrb = auto_in_wstrb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_wlast = auto_in_wlast; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_bready = auto_in_bready & allowed_1_1; // @[Xbar.scala 279:31]
  assign auto_out_1_arvalid = auto_in_arvalid & requestARIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_arid = auto_in_arid; // @[Xbar.scala 87:47]
  assign auto_out_1_arlen = auto_in_arlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_arsize = auto_in_arsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_arburst = auto_in_arburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_arlock = auto_in_arlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_arcache = auto_in_arcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_arqos = auto_in_arqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_rready = auto_in_rready & allowed__1; // @[Xbar.scala 279:31]
  assign auto_out_0_awvalid = in_0_awvalid & requestAWIO_0_0; // @[Xbar.scala 229:40]
  assign auto_out_0_awid = auto_in_awid; // @[Xbar.scala 86:47]
  assign auto_out_0_awaddr = auto_in_awaddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awlen = auto_in_awlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awsize = auto_in_awsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awburst = auto_in_awburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awlock = auto_in_awlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awcache = auto_in_awcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awprot = auto_in_awprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_awqos = auto_in_awqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_wvalid = in_0_wvalid & requestWIO_0_0; // @[Xbar.scala 229:40]
  assign auto_out_0_wdata = auto_in_wdata; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_wstrb = auto_in_wstrb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_wlast = auto_in_wlast; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_bready = auto_in_bready & allowed_1_0; // @[Xbar.scala 279:31]
  assign auto_out_0_arvalid = auto_in_arvalid & requestARIO_0_0; // @[Xbar.scala 229:40]
  assign auto_out_0_arid = auto_in_arid; // @[Xbar.scala 87:47]
  assign auto_out_0_araddr = auto_in_araddr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arlen = auto_in_arlen; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arsize = auto_in_arsize; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arburst = auto_in_arburst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arlock = auto_in_arlock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arcache = auto_in_arcache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arprot = auto_in_arprot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_arqos = auto_in_arqos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_rready = auto_in_rready & allowed__0; // @[Xbar.scala 279:31]
  assign awIn_0_clock = clock;
  assign awIn_0_reset = reset;
  assign awIn_0_io_enq_valid = auto_in_awvalid & ~latched; // @[Xbar.scala 147:51]
  assign awIn_0_io_enq_bits = {awIn_0_io_enq_bits_hi,awIn_0_io_enq_bits_lo}; // @[Xbar.scala 71:75]
  assign awIn_0_io_deq_ready = auto_in_wvalid & auto_in_wlast & in_0_wready; // @[Xbar.scala 154:74]
  always @(posedge clock) begin
    idle_6 <= reset | _GEN_44; // @[Xbar.scala 249:{23,23}]
    if (reset) begin // @[Arbiter.scala 23:23]
      readys_mask <= 6'h3f; // @[Arbiter.scala 23:23]
    end else if (idle_6 & |readys_valid) begin // @[Arbiter.scala 27:32]
      readys_mask <= _readys_mask_T_9; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_6_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_6) begin // @[Xbar.scala 269:23]
      state_6_0 <= winner_6_0;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_6_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_6) begin // @[Xbar.scala 269:23]
      state_6_1 <= winner_6_1;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_6_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_6) begin // @[Xbar.scala 269:23]
      state_6_2 <= winner_6_2;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_6_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_6) begin // @[Xbar.scala 269:23]
      state_6_3 <= winner_6_3;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_6_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_6) begin // @[Xbar.scala 269:23]
      state_6_4 <= winner_6_4;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_6_5 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_6) begin // @[Xbar.scala 269:23]
      state_6_5 <= winner_6_5;
    end
    idle_7 <= reset | _GEN_47; // @[Xbar.scala 249:{23,23}]
    if (reset) begin // @[Arbiter.scala 23:23]
      readys_mask_1 <= 6'h3f; // @[Arbiter.scala 23:23]
    end else if (idle_7 & |readys_valid_1) begin // @[Arbiter.scala 27:32]
      readys_mask_1 <= _readys_mask_T_20; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_7_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_7) begin // @[Xbar.scala 269:23]
      state_7_0 <= winner_7_0;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_7_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_7) begin // @[Xbar.scala 269:23]
      state_7_1 <= winner_7_1;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_7_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_7) begin // @[Xbar.scala 269:23]
      state_7_2 <= winner_7_2;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_7_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_7) begin // @[Xbar.scala 269:23]
      state_7_3 <= winner_7_3;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_7_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_7) begin // @[Xbar.scala 269:23]
      state_7_4 <= winner_7_4;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      state_7_5 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (idle_7) begin // @[Xbar.scala 269:23]
      state_7_5 <= winner_7_5;
    end
    if (reset) begin // @[Xbar.scala 144:30]
      latched <= 1'h0; // @[Xbar.scala 144:30]
    end else if (_T_1) begin // @[Xbar.scala 149:32]
      latched <= 1'h0; // @[Xbar.scala 149:42]
    end else begin
      latched <= _GEN_16;
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  idle_6 = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  readys_mask = _RAND_1[5:0];
  _RAND_2 = {1{`RANDOM}};
  state_6_0 = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  state_6_1 = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  state_6_2 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  state_6_3 = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  state_6_4 = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  state_6_5 = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  idle_7 = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  readys_mask_1 = _RAND_9[5:0];
  _RAND_10 = {1{`RANDOM}};
  state_7_0 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  state_7_1 = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  state_7_2 = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  state_7_3 = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  state_7_4 = _RAND_14[0:0];
  _RAND_15 = {1{`RANDOM}};
  state_7_5 = _RAND_15[0:0];
  _RAND_16 = {1{`RANDOM}};
  latched = _RAND_16[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule

