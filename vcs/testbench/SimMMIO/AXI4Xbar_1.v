module AXI4Xbar_1(
  input         clock,
  input         reset,
  output        auto_in_aw_ready,
  input         auto_in_aw_valid,
  input  [1:0]  auto_in_aw_bits_id,
  input  [30:0] auto_in_aw_bits_addr,
  input  [7:0]  auto_in_aw_bits_len,
  input  [2:0]  auto_in_aw_bits_size,
  input  [1:0]  auto_in_aw_bits_burst,
  input         auto_in_aw_bits_lock,
  input  [3:0]  auto_in_aw_bits_cache,
  input  [2:0]  auto_in_aw_bits_prot,
  input  [3:0]  auto_in_aw_bits_qos,
  output        auto_in_w_ready,
  input         auto_in_w_valid,
  input  [63:0] auto_in_w_bits_data,
  input  [7:0]  auto_in_w_bits_strb,
  input         auto_in_w_bits_last,
  input         auto_in_b_ready,
  output        auto_in_b_valid,
  output [1:0]  auto_in_b_bits_id,
  output [1:0]  auto_in_b_bits_resp,
  output        auto_in_ar_ready,
  input         auto_in_ar_valid,
  input  [1:0]  auto_in_ar_bits_id,
  input  [30:0] auto_in_ar_bits_addr,
  input  [7:0]  auto_in_ar_bits_len,
  input  [2:0]  auto_in_ar_bits_size,
  input  [1:0]  auto_in_ar_bits_burst,
  input         auto_in_ar_bits_lock,
  input  [3:0]  auto_in_ar_bits_cache,
  input  [2:0]  auto_in_ar_bits_prot,
  input  [3:0]  auto_in_ar_bits_qos,
  input         auto_in_r_ready,
  output        auto_in_r_valid,
  output [1:0]  auto_in_r_bits_id,
  output [63:0] auto_in_r_bits_data,
  output [1:0]  auto_in_r_bits_resp,
  output        auto_in_r_bits_last,
  input         auto_out_4_aw_ready,
  output        auto_out_4_aw_valid,
  output [1:0]  auto_out_4_aw_bits_id,
  output [30:0] auto_out_4_aw_bits_addr,
  output [7:0]  auto_out_4_aw_bits_len,
  output [2:0]  auto_out_4_aw_bits_size,
  output [1:0]  auto_out_4_aw_bits_burst,
  output        auto_out_4_aw_bits_lock,
  output [3:0]  auto_out_4_aw_bits_cache,
  output [2:0]  auto_out_4_aw_bits_prot,
  output [3:0]  auto_out_4_aw_bits_qos,
  input         auto_out_4_w_ready,
  output        auto_out_4_w_valid,
  output [63:0] auto_out_4_w_bits_data,
  output [7:0]  auto_out_4_w_bits_strb,
  output        auto_out_4_w_bits_last,
  output        auto_out_4_b_ready,
  input         auto_out_4_b_valid,
  input  [1:0]  auto_out_4_b_bits_id,
  input  [1:0]  auto_out_4_b_bits_resp,
  input         auto_out_4_ar_ready,
  output        auto_out_4_ar_valid,
  output [1:0]  auto_out_4_ar_bits_id,
  output [30:0] auto_out_4_ar_bits_addr,
  output [7:0]  auto_out_4_ar_bits_len,
  output [2:0]  auto_out_4_ar_bits_size,
  output [1:0]  auto_out_4_ar_bits_burst,
  output        auto_out_4_ar_bits_lock,
  output [3:0]  auto_out_4_ar_bits_cache,
  output [2:0]  auto_out_4_ar_bits_prot,
  output [3:0]  auto_out_4_ar_bits_qos,
  output        auto_out_4_r_ready,
  input         auto_out_4_r_valid,
  input  [1:0]  auto_out_4_r_bits_id,
  input  [63:0] auto_out_4_r_bits_data,
  input  [1:0]  auto_out_4_r_bits_resp,
  input         auto_out_4_r_bits_last,
  input         auto_out_3_aw_ready,
  output        auto_out_3_aw_valid,
  output [1:0]  auto_out_3_aw_bits_id,
  output [28:0] auto_out_3_aw_bits_addr,
  output [7:0]  auto_out_3_aw_bits_len,
  output [2:0]  auto_out_3_aw_bits_size,
  output [1:0]  auto_out_3_aw_bits_burst,
  output        auto_out_3_aw_bits_lock,
  output [3:0]  auto_out_3_aw_bits_cache,
  output [2:0]  auto_out_3_aw_bits_prot,
  output [3:0]  auto_out_3_aw_bits_qos,
  input         auto_out_3_w_ready,
  output        auto_out_3_w_valid,
  output [63:0] auto_out_3_w_bits_data,
  output [7:0]  auto_out_3_w_bits_strb,
  output        auto_out_3_w_bits_last,
  output        auto_out_3_b_ready,
  input         auto_out_3_b_valid,
  input  [1:0]  auto_out_3_b_bits_id,
  input  [1:0]  auto_out_3_b_bits_resp,
  input         auto_out_3_ar_ready,
  output        auto_out_3_ar_valid,
  output [1:0]  auto_out_3_ar_bits_id,
  output [28:0] auto_out_3_ar_bits_addr,
  output [7:0]  auto_out_3_ar_bits_len,
  output [2:0]  auto_out_3_ar_bits_size,
  output [1:0]  auto_out_3_ar_bits_burst,
  output        auto_out_3_ar_bits_lock,
  output [3:0]  auto_out_3_ar_bits_cache,
  output [2:0]  auto_out_3_ar_bits_prot,
  output [3:0]  auto_out_3_ar_bits_qos,
  output        auto_out_3_r_ready,
  input         auto_out_3_r_valid,
  input  [1:0]  auto_out_3_r_bits_id,
  input  [63:0] auto_out_3_r_bits_data,
  input  [1:0]  auto_out_3_r_bits_resp,
  input         auto_out_3_r_bits_last,
  input         auto_out_2_aw_ready,
  output        auto_out_2_aw_valid,
  output [1:0]  auto_out_2_aw_bits_id,
  output [30:0] auto_out_2_aw_bits_addr,
  output [7:0]  auto_out_2_aw_bits_len,
  output [2:0]  auto_out_2_aw_bits_size,
  output [1:0]  auto_out_2_aw_bits_burst,
  output        auto_out_2_aw_bits_lock,
  output [3:0]  auto_out_2_aw_bits_cache,
  output [2:0]  auto_out_2_aw_bits_prot,
  output [3:0]  auto_out_2_aw_bits_qos,
  input         auto_out_2_w_ready,
  output        auto_out_2_w_valid,
  output [63:0] auto_out_2_w_bits_data,
  output [7:0]  auto_out_2_w_bits_strb,
  output        auto_out_2_w_bits_last,
  output        auto_out_2_b_ready,
  input         auto_out_2_b_valid,
  input  [1:0]  auto_out_2_b_bits_id,
  input  [1:0]  auto_out_2_b_bits_resp,
  input         auto_out_2_ar_ready,
  output        auto_out_2_ar_valid,
  output [1:0]  auto_out_2_ar_bits_id,
  output [30:0] auto_out_2_ar_bits_addr,
  output [7:0]  auto_out_2_ar_bits_len,
  output [2:0]  auto_out_2_ar_bits_size,
  output [1:0]  auto_out_2_ar_bits_burst,
  output        auto_out_2_ar_bits_lock,
  output [3:0]  auto_out_2_ar_bits_cache,
  output [2:0]  auto_out_2_ar_bits_prot,
  output [3:0]  auto_out_2_ar_bits_qos,
  output        auto_out_2_r_ready,
  input         auto_out_2_r_valid,
  input  [1:0]  auto_out_2_r_bits_id,
  input  [63:0] auto_out_2_r_bits_data,
  input  [1:0]  auto_out_2_r_bits_resp,
  input         auto_out_2_r_bits_last,
  input         auto_out_1_aw_ready,
  output        auto_out_1_aw_valid,
  output [1:0]  auto_out_1_aw_bits_id,
  output [30:0] auto_out_1_aw_bits_addr,
  output [7:0]  auto_out_1_aw_bits_len,
  output [2:0]  auto_out_1_aw_bits_size,
  output [1:0]  auto_out_1_aw_bits_burst,
  output        auto_out_1_aw_bits_lock,
  output [3:0]  auto_out_1_aw_bits_cache,
  output [2:0]  auto_out_1_aw_bits_prot,
  output [3:0]  auto_out_1_aw_bits_qos,
  input         auto_out_1_w_ready,
  output        auto_out_1_w_valid,
  output [63:0] auto_out_1_w_bits_data,
  output [7:0]  auto_out_1_w_bits_strb,
  output        auto_out_1_w_bits_last,
  output        auto_out_1_b_ready,
  input         auto_out_1_b_valid,
  input  [1:0]  auto_out_1_b_bits_id,
  input  [1:0]  auto_out_1_b_bits_resp,
  output        auto_out_1_ar_valid,
  output [1:0]  auto_out_1_ar_bits_id,
  output [7:0]  auto_out_1_ar_bits_len,
  output [2:0]  auto_out_1_ar_bits_size,
  output [1:0]  auto_out_1_ar_bits_burst,
  output        auto_out_1_ar_bits_lock,
  output [3:0]  auto_out_1_ar_bits_cache,
  output [3:0]  auto_out_1_ar_bits_qos,
  output        auto_out_1_r_ready,
  input         auto_out_1_r_valid,
  input  [1:0]  auto_out_1_r_bits_id,
  input         auto_out_1_r_bits_last,
  input         auto_out_0_aw_ready,
  output        auto_out_0_aw_valid,
  output [1:0]  auto_out_0_aw_bits_id,
  output [30:0] auto_out_0_aw_bits_addr,
  output [7:0]  auto_out_0_aw_bits_len,
  output [2:0]  auto_out_0_aw_bits_size,
  output [1:0]  auto_out_0_aw_bits_burst,
  output        auto_out_0_aw_bits_lock,
  output [3:0]  auto_out_0_aw_bits_cache,
  output [2:0]  auto_out_0_aw_bits_prot,
  output [3:0]  auto_out_0_aw_bits_qos,
  input         auto_out_0_w_ready,
  output        auto_out_0_w_valid,
  output [63:0] auto_out_0_w_bits_data,
  output [7:0]  auto_out_0_w_bits_strb,
  output        auto_out_0_w_bits_last,
  output        auto_out_0_b_ready,
  input         auto_out_0_b_valid,
  input  [1:0]  auto_out_0_b_bits_id,
  input  [1:0]  auto_out_0_b_bits_resp,
  input         auto_out_0_ar_ready,
  output        auto_out_0_ar_valid,
  output [1:0]  auto_out_0_ar_bits_id,
  output [30:0] auto_out_0_ar_bits_addr,
  output [7:0]  auto_out_0_ar_bits_len,
  output [2:0]  auto_out_0_ar_bits_size,
  output [1:0]  auto_out_0_ar_bits_burst,
  output        auto_out_0_ar_bits_lock,
  output [3:0]  auto_out_0_ar_bits_cache,
  output [2:0]  auto_out_0_ar_bits_prot,
  output [3:0]  auto_out_0_ar_bits_qos,
  output        auto_out_0_r_ready,
  input         auto_out_0_r_valid,
  input  [1:0]  auto_out_0_r_bits_id,
  input  [63:0] auto_out_0_r_bits_data,
  input  [1:0]  auto_out_0_r_bits_resp,
  input         auto_out_0_r_bits_last
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
  reg [31:0] _RAND_17;
  reg [31:0] _RAND_18;
  reg [31:0] _RAND_19;
  reg [31:0] _RAND_20;
  reg [31:0] _RAND_21;
  reg [31:0] _RAND_22;
`endif // RANDOMIZE_REG_INIT
  wire  awIn_0_clock; // @[Xbar.scala 62:47]
  wire  awIn_0_reset; // @[Xbar.scala 62:47]
  wire  awIn_0_io_enq_ready; // @[Xbar.scala 62:47]
  wire  awIn_0_io_enq_valid; // @[Xbar.scala 62:47]
  wire [4:0] awIn_0_io_enq_bits; // @[Xbar.scala 62:47]
  wire  awIn_0_io_deq_ready; // @[Xbar.scala 62:47]
  wire  awIn_0_io_deq_valid; // @[Xbar.scala 62:47]
  wire [4:0] awIn_0_io_deq_bits; // @[Xbar.scala 62:47]
  wire [30:0] _T = auto_in_ar_bits_addr ^ 31'h40200000; // @[Parameters.scala 137:31]
  wire [31:0] _T_1 = {1'b0,$signed(_T)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_3 = $signed(_T_1) & 32'sh50202000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_0 = $signed(_T_3) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_5 = auto_in_ar_bits_addr ^ 31'h50000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_6 = {1'b0,$signed(_T_5)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_8 = $signed(_T_6) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_1 = $signed(_T_8) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_10 = auto_in_ar_bits_addr ^ 31'h40000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_11 = {1'b0,$signed(_T_10)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_13 = $signed(_T_11) & 32'sh50202000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_2 = $signed(_T_13) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_15 = auto_in_ar_bits_addr ^ 31'h10000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_16 = {1'b0,$signed(_T_15)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_18 = $signed(_T_16) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_3 = $signed(_T_18) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_20 = auto_in_ar_bits_addr ^ 31'h40002000; // @[Parameters.scala 137:31]
  wire [31:0] _T_21 = {1'b0,$signed(_T_20)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_23 = $signed(_T_21) & 32'sh50202000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_4 = $signed(_T_23) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_25 = auto_in_aw_bits_addr ^ 31'h40200000; // @[Parameters.scala 137:31]
  wire [31:0] _T_26 = {1'b0,$signed(_T_25)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_28 = $signed(_T_26) & 32'sh50202000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_0 = $signed(_T_28) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_30 = auto_in_aw_bits_addr ^ 31'h50000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_31 = {1'b0,$signed(_T_30)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_33 = $signed(_T_31) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_1 = $signed(_T_33) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_35 = auto_in_aw_bits_addr ^ 31'h40000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_36 = {1'b0,$signed(_T_35)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_38 = $signed(_T_36) & 32'sh50202000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_2 = $signed(_T_38) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_40 = auto_in_aw_bits_addr ^ 31'h10000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_41 = {1'b0,$signed(_T_40)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_43 = $signed(_T_41) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_3 = $signed(_T_43) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_45 = auto_in_aw_bits_addr ^ 31'h40002000; // @[Parameters.scala 137:31]
  wire [31:0] _T_46 = {1'b0,$signed(_T_45)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_48 = $signed(_T_46) & 32'sh50202000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_4 = $signed(_T_48) == 32'sh0; // @[Parameters.scala 137:67]
  wire [1:0] lo = {requestAWIO_0_1,requestAWIO_0_0}; // @[Xbar.scala 71:75]
  wire [2:0] hi = {requestAWIO_0_4,requestAWIO_0_3,requestAWIO_0_2}; // @[Xbar.scala 71:75]
  wire  requestWIO_0_0 = awIn_0_io_deq_bits[0]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_1 = awIn_0_io_deq_bits[1]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_2 = awIn_0_io_deq_bits[2]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_3 = awIn_0_io_deq_bits[3]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_4 = awIn_0_io_deq_bits[4]; // @[Xbar.scala 72:73]
  reg  REG_37; // @[Xbar.scala 249:23]
  wire [4:0] lo_12 = {auto_out_4_r_valid,auto_out_3_r_valid,auto_out_2_r_valid,auto_out_1_r_valid,auto_out_0_r_valid}; // @[Cat.scala 30:58]
  reg [4:0] REG_38; // @[Arbiter.scala 23:23]
  wire [4:0] _T_608 = ~REG_38; // @[Arbiter.scala 24:30]
  wire [4:0] hi_12 = lo_12 & _T_608; // @[Arbiter.scala 24:28]
  wire [9:0] _T_609 = {hi_12,auto_out_4_r_valid,auto_out_3_r_valid,auto_out_2_r_valid,auto_out_1_r_valid,
    auto_out_0_r_valid}; // @[Cat.scala 30:58]
  wire [9:0] _GEN_44 = {{1'd0}, _T_609[9:1]}; // @[package.scala 253:43]
  wire [9:0] _T_611 = _T_609 | _GEN_44; // @[package.scala 253:43]
  wire [9:0] _GEN_45 = {{2'd0}, _T_611[9:2]}; // @[package.scala 253:43]
  wire [9:0] _T_613 = _T_611 | _GEN_45; // @[package.scala 253:43]
  wire [9:0] _GEN_46 = {{4'd0}, _T_613[9:4]}; // @[package.scala 253:43]
  wire [9:0] _T_615 = _T_613 | _GEN_46; // @[package.scala 253:43]
  wire [9:0] _T_618 = {REG_38, 5'h0}; // @[Arbiter.scala 25:66]
  wire [9:0] _GEN_47 = {{1'd0}, _T_615[9:1]}; // @[Arbiter.scala 25:58]
  wire [9:0] _T_619 = _GEN_47 | _T_618; // @[Arbiter.scala 25:58]
  wire [4:0] _T_622 = _T_619[9:5] & _T_619[4:0]; // @[Arbiter.scala 26:39]
  wire [4:0] _T_623 = ~_T_622; // @[Arbiter.scala 26:18]
  wire  _T_643 = _T_623[0] & auto_out_0_r_valid; // @[Xbar.scala 257:63]
  reg  REG_39_0; // @[Xbar.scala 268:24]
  wire  _T_684_0 = REG_37 ? _T_643 : REG_39_0; // @[Xbar.scala 269:23]
  wire [1:0] _T_729 = _T_684_0 ? auto_out_0_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire  _T_644 = _T_623[1] & auto_out_1_r_valid; // @[Xbar.scala 257:63]
  reg  REG_39_1; // @[Xbar.scala 268:24]
  wire  _T_684_1 = REG_37 ? _T_644 : REG_39_1; // @[Xbar.scala 269:23]
  wire [1:0] _T_730 = _T_684_1 ? auto_out_1_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_734 = _T_729 | _T_730; // @[Mux.scala 27:72]
  wire  _T_645 = _T_623[2] & auto_out_2_r_valid; // @[Xbar.scala 257:63]
  reg  REG_39_2; // @[Xbar.scala 268:24]
  wire  _T_684_2 = REG_37 ? _T_645 : REG_39_2; // @[Xbar.scala 269:23]
  wire [1:0] _T_731 = _T_684_2 ? auto_out_2_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_735 = _T_734 | _T_731; // @[Mux.scala 27:72]
  wire  _T_646 = _T_623[3] & auto_out_3_r_valid; // @[Xbar.scala 257:63]
  reg  REG_39_3; // @[Xbar.scala 268:24]
  wire  _T_684_3 = REG_37 ? _T_646 : REG_39_3; // @[Xbar.scala 269:23]
  wire [1:0] _T_732 = _T_684_3 ? auto_out_3_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_736 = _T_735 | _T_732; // @[Mux.scala 27:72]
  wire  _T_647 = _T_623[4] & auto_out_4_r_valid; // @[Xbar.scala 257:63]
  reg  REG_39_4; // @[Xbar.scala 268:24]
  wire  _T_684_4 = REG_37 ? _T_647 : REG_39_4; // @[Xbar.scala 269:23]
  wire [1:0] _T_733 = _T_684_4 ? auto_out_4_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] in_0_r_bits_id = _T_736 | _T_733; // @[Mux.scala 27:72]
  reg  REG_40; // @[Xbar.scala 249:23]
  wire [4:0] lo_14 = {auto_out_4_b_valid,auto_out_3_b_valid,auto_out_2_b_valid,auto_out_1_b_valid,auto_out_0_b_valid}; // @[Cat.scala 30:58]
  reg [4:0] REG_41; // @[Arbiter.scala 23:23]
  wire [4:0] _T_747 = ~REG_41; // @[Arbiter.scala 24:30]
  wire [4:0] hi_14 = lo_14 & _T_747; // @[Arbiter.scala 24:28]
  wire [9:0] _T_748 = {hi_14,auto_out_4_b_valid,auto_out_3_b_valid,auto_out_2_b_valid,auto_out_1_b_valid,
    auto_out_0_b_valid}; // @[Cat.scala 30:58]
  wire [9:0] _GEN_48 = {{1'd0}, _T_748[9:1]}; // @[package.scala 253:43]
  wire [9:0] _T_750 = _T_748 | _GEN_48; // @[package.scala 253:43]
  wire [9:0] _GEN_49 = {{2'd0}, _T_750[9:2]}; // @[package.scala 253:43]
  wire [9:0] _T_752 = _T_750 | _GEN_49; // @[package.scala 253:43]
  wire [9:0] _GEN_50 = {{4'd0}, _T_752[9:4]}; // @[package.scala 253:43]
  wire [9:0] _T_754 = _T_752 | _GEN_50; // @[package.scala 253:43]
  wire [9:0] _T_757 = {REG_41, 5'h0}; // @[Arbiter.scala 25:66]
  wire [9:0] _GEN_51 = {{1'd0}, _T_754[9:1]}; // @[Arbiter.scala 25:58]
  wire [9:0] _T_758 = _GEN_51 | _T_757; // @[Arbiter.scala 25:58]
  wire [4:0] _T_761 = _T_758[9:5] & _T_758[4:0]; // @[Arbiter.scala 26:39]
  wire [4:0] _T_762 = ~_T_761; // @[Arbiter.scala 26:18]
  wire  _T_782 = _T_762[0] & auto_out_0_b_valid; // @[Xbar.scala 257:63]
  reg  REG_42_0; // @[Xbar.scala 268:24]
  wire  _T_823_0 = REG_40 ? _T_782 : REG_42_0; // @[Xbar.scala 269:23]
  wire [1:0] _T_850 = _T_823_0 ? auto_out_0_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire  _T_783 = _T_762[1] & auto_out_1_b_valid; // @[Xbar.scala 257:63]
  reg  REG_42_1; // @[Xbar.scala 268:24]
  wire  _T_823_1 = REG_40 ? _T_783 : REG_42_1; // @[Xbar.scala 269:23]
  wire [1:0] _T_851 = _T_823_1 ? auto_out_1_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_855 = _T_850 | _T_851; // @[Mux.scala 27:72]
  wire  _T_784 = _T_762[2] & auto_out_2_b_valid; // @[Xbar.scala 257:63]
  reg  REG_42_2; // @[Xbar.scala 268:24]
  wire  _T_823_2 = REG_40 ? _T_784 : REG_42_2; // @[Xbar.scala 269:23]
  wire [1:0] _T_852 = _T_823_2 ? auto_out_2_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_856 = _T_855 | _T_852; // @[Mux.scala 27:72]
  wire  _T_785 = _T_762[3] & auto_out_3_b_valid; // @[Xbar.scala 257:63]
  reg  REG_42_3; // @[Xbar.scala 268:24]
  wire  _T_823_3 = REG_40 ? _T_785 : REG_42_3; // @[Xbar.scala 269:23]
  wire [1:0] _T_853 = _T_823_3 ? auto_out_3_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_857 = _T_856 | _T_853; // @[Mux.scala 27:72]
  wire  _T_786 = _T_762[4] & auto_out_4_b_valid; // @[Xbar.scala 257:63]
  reg  REG_42_4; // @[Xbar.scala 268:24]
  wire  _T_823_4 = REG_40 ? _T_786 : REG_42_4; // @[Xbar.scala 269:23]
  wire [1:0] _T_854 = _T_823_4 ? auto_out_4_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] in_0_b_bits_id = _T_857 | _T_854; // @[Mux.scala 27:72]
  wire [3:0] _T_125 = 4'h1 << auto_in_ar_bits_id; // @[OneHot.scala 65:12]
  wire [3:0] _T_127 = 4'h1 << auto_in_aw_bits_id; // @[OneHot.scala 65:12]
  wire [3:0] _T_129 = 4'h1 << in_0_r_bits_id; // @[OneHot.scala 65:12]
  wire [3:0] _T_131 = 4'h1 << in_0_b_bits_id; // @[OneHot.scala 65:12]
  wire  in_0_ar_ready = requestARIO_0_0 & auto_out_0_ar_ready | requestARIO_0_1 | requestARIO_0_2 & auto_out_2_ar_ready
     | requestARIO_0_3 & auto_out_3_ar_ready | requestARIO_0_4 & auto_out_4_ar_ready; // @[Mux.scala 27:72]
  reg  REG_12; // @[Xbar.scala 111:34]
  wire  _T_329 = ~REG_12; // @[Xbar.scala 119:22]
  reg  REG_8; // @[Xbar.scala 111:34]
  wire  _T_274 = ~REG_8; // @[Xbar.scala 119:22]
  reg  REG_4; // @[Xbar.scala 111:34]
  wire  _T_219 = ~REG_4; // @[Xbar.scala 119:22]
  reg  REG; // @[Xbar.scala 111:34]
  wire  _T_164 = ~REG; // @[Xbar.scala 119:22]
  wire  _T_142 = in_0_ar_ready & auto_in_ar_valid; // @[Decoupled.scala 40:37]
  wire  _T_143 = _T_125[0] & _T_142; // @[Xbar.scala 126:25]
  wire  _T_602 = auto_out_0_r_valid | auto_out_1_r_valid | auto_out_2_r_valid | auto_out_3_r_valid | auto_out_4_r_valid; // @[Xbar.scala 253:36]
  wire  _T_700 = REG_39_0 & auto_out_0_r_valid | REG_39_1 & auto_out_1_r_valid | REG_39_2 & auto_out_2_r_valid |
    REG_39_3 & auto_out_3_r_valid | REG_39_4 & auto_out_4_r_valid; // @[Mux.scala 27:72]
  wire  in_0_r_valid = REG_37 ? _T_602 : _T_700; // @[Xbar.scala 285:22]
  wire  _T_145 = auto_in_r_ready & in_0_r_valid; // @[Decoupled.scala 40:37]
  wire  in_0_r_bits_last = _T_684_0 & auto_out_0_r_bits_last | _T_684_1 & auto_out_1_r_bits_last | _T_684_2 &
    auto_out_2_r_bits_last | _T_684_3 & auto_out_3_r_bits_last | _T_684_4 & auto_out_4_r_bits_last; // @[Mux.scala 27:72]
  wire  _T_147 = _T_129[0] & _T_145 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_149 = REG + _T_143; // @[Xbar.scala 113:30]
  wire  in_0_aw_ready = requestAWIO_0_0 & auto_out_0_aw_ready | requestAWIO_0_1 & auto_out_1_aw_ready | requestAWIO_0_2
     & auto_out_2_aw_ready | requestAWIO_0_3 & auto_out_3_aw_ready | requestAWIO_0_4 & auto_out_4_aw_ready; // @[Mux.scala 27:72]
  reg  REG_16; // @[Xbar.scala 144:30]
  wire  _T_366 = REG_16 | awIn_0_io_enq_ready; // @[Xbar.scala 146:57]
  wire  io_in_0_aw_ready = in_0_aw_ready & (REG_16 | awIn_0_io_enq_ready); // @[Xbar.scala 146:45]
  reg  REG_14; // @[Xbar.scala 111:34]
  wire  _T_356 = ~REG_14; // @[Xbar.scala 119:22]
  reg  REG_10; // @[Xbar.scala 111:34]
  wire  _T_301 = ~REG_10; // @[Xbar.scala 119:22]
  reg  REG_6; // @[Xbar.scala 111:34]
  wire  _T_246 = ~REG_6; // @[Xbar.scala 119:22]
  reg  REG_2; // @[Xbar.scala 111:34]
  wire  _T_191 = ~REG_2; // @[Xbar.scala 119:22]
  wire  _T_170 = io_in_0_aw_ready & auto_in_aw_valid; // @[Decoupled.scala 40:37]
  wire  _T_171 = _T_127[0] & _T_170; // @[Xbar.scala 130:25]
  wire  _T_741 = auto_out_0_b_valid | auto_out_1_b_valid | auto_out_2_b_valid | auto_out_3_b_valid | auto_out_4_b_valid; // @[Xbar.scala 253:36]
  wire  _T_839 = REG_42_0 & auto_out_0_b_valid | REG_42_1 & auto_out_1_b_valid | REG_42_2 & auto_out_2_b_valid |
    REG_42_3 & auto_out_3_b_valid | REG_42_4 & auto_out_4_b_valid; // @[Mux.scala 27:72]
  wire  in_0_b_valid = REG_40 ? _T_741 : _T_839; // @[Xbar.scala 285:22]
  wire  _T_173 = auto_in_b_ready & in_0_b_valid; // @[Decoupled.scala 40:37]
  wire  _T_174 = _T_131[0] & _T_173; // @[Xbar.scala 131:24]
  wire  _T_176 = REG_2 + _T_171; // @[Xbar.scala 113:30]
  wire  _T_198 = _T_125[1] & _T_142; // @[Xbar.scala 126:25]
  wire  _T_202 = _T_129[1] & _T_145 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_204 = REG_4 + _T_198; // @[Xbar.scala 113:30]
  wire  _T_226 = _T_127[1] & _T_170; // @[Xbar.scala 130:25]
  wire  _T_229 = _T_131[1] & _T_173; // @[Xbar.scala 131:24]
  wire  _T_231 = REG_6 + _T_226; // @[Xbar.scala 113:30]
  wire  _T_253 = _T_125[2] & _T_142; // @[Xbar.scala 126:25]
  wire  _T_257 = _T_129[2] & _T_145 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_259 = REG_8 + _T_253; // @[Xbar.scala 113:30]
  wire  _T_281 = _T_127[2] & _T_170; // @[Xbar.scala 130:25]
  wire  _T_284 = _T_131[2] & _T_173; // @[Xbar.scala 131:24]
  wire  _T_286 = REG_10 + _T_281; // @[Xbar.scala 113:30]
  wire  _T_308 = _T_125[3] & _T_142; // @[Xbar.scala 126:25]
  wire  _T_312 = _T_129[3] & _T_145 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_314 = REG_12 + _T_308; // @[Xbar.scala 113:30]
  wire  _T_336 = _T_127[3] & _T_170; // @[Xbar.scala 130:25]
  wire  _T_339 = _T_131[3] & _T_173; // @[Xbar.scala 131:24]
  wire  _T_341 = REG_14 + _T_336; // @[Xbar.scala 113:30]
  wire  in_0_aw_valid = auto_in_aw_valid & _T_366; // @[Xbar.scala 145:45]
  wire  _T_371 = awIn_0_io_enq_ready & awIn_0_io_enq_valid; // @[Decoupled.scala 40:37]
  wire  _GEN_16 = _T_371 | REG_16; // @[Xbar.scala 148:38 Xbar.scala 148:48 Xbar.scala 144:30]
  wire  _T_372 = in_0_aw_ready & in_0_aw_valid; // @[Decoupled.scala 40:37]
  wire  in_0_w_valid = auto_in_w_valid & awIn_0_io_deq_valid; // @[Xbar.scala 152:43]
  wire  in_0_w_ready = requestWIO_0_0 & auto_out_0_w_ready | requestWIO_0_1 & auto_out_1_w_ready | requestWIO_0_2 &
    auto_out_2_w_ready | requestWIO_0_3 & auto_out_3_w_ready | requestWIO_0_4 & auto_out_4_w_ready; // @[Mux.scala 27:72]
  wire  out_0_ar_valid = auto_in_ar_valid & requestARIO_0_0; // @[Xbar.scala 229:40]
  wire  out_1_ar_valid = auto_in_ar_valid & requestARIO_0_1; // @[Xbar.scala 229:40]
  wire  out_2_ar_valid = auto_in_ar_valid & requestARIO_0_2; // @[Xbar.scala 229:40]
  wire  out_3_ar_valid = auto_in_ar_valid & requestARIO_0_3; // @[Xbar.scala 229:40]
  wire  out_4_ar_valid = auto_in_ar_valid & requestARIO_0_4; // @[Xbar.scala 229:40]
  wire  out_0_aw_valid = in_0_aw_valid & requestAWIO_0_0; // @[Xbar.scala 229:40]
  wire  out_1_aw_valid = in_0_aw_valid & requestAWIO_0_1; // @[Xbar.scala 229:40]
  wire  out_2_aw_valid = in_0_aw_valid & requestAWIO_0_2; // @[Xbar.scala 229:40]
  wire  out_3_aw_valid = in_0_aw_valid & requestAWIO_0_3; // @[Xbar.scala 229:40]
  wire  out_4_aw_valid = in_0_aw_valid & requestAWIO_0_4; // @[Xbar.scala 229:40]
  wire  _T_432 = ~out_0_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_448 = ~out_0_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_466 = ~out_1_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_482 = ~out_1_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_500 = ~out_2_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_516 = ~out_2_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_534 = ~out_3_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_550 = ~out_3_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_568 = ~out_4_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_584 = ~out_4_ar_valid; // @[Xbar.scala 263:60]
  wire [4:0] _T_626 = _T_623 & lo_12; // @[Arbiter.scala 28:29]
  wire [5:0] _T_627 = {_T_626, 1'h0}; // @[package.scala 244:48]
  wire [4:0] _T_629 = _T_626 | _T_627[4:0]; // @[package.scala 244:43]
  wire [6:0] _T_630 = {_T_629, 2'h0}; // @[package.scala 244:48]
  wire [4:0] _T_632 = _T_629 | _T_630[4:0]; // @[package.scala 244:43]
  wire [8:0] _T_633 = {_T_632, 4'h0}; // @[package.scala 244:48]
  wire [4:0] _T_635 = _T_632 | _T_633[4:0]; // @[package.scala 244:43]
  wire  _T_649 = _T_643 | _T_644; // @[Xbar.scala 262:50]
  wire  _T_650 = _T_643 | _T_644 | _T_645; // @[Xbar.scala 262:50]
  wire  _T_651 = _T_643 | _T_644 | _T_645 | _T_646; // @[Xbar.scala 262:50]
  wire  _T_652 = _T_643 | _T_644 | _T_645 | _T_646 | _T_647; // @[Xbar.scala 262:50]
  wire  _GEN_39 = _T_602 ? 1'h0 : REG_37; // @[Xbar.scala 273:21 Xbar.scala 273:28 Xbar.scala 249:23]
  wire  _GEN_40 = _T_145 | _GEN_39; // @[Xbar.scala 274:24 Xbar.scala 274:31]
  wire  _T_686_0 = REG_37 ? _T_623[0] : REG_39_0; // @[Xbar.scala 277:24]
  wire  _T_686_1 = REG_37 ? _T_623[1] : REG_39_1; // @[Xbar.scala 277:24]
  wire  _T_686_2 = REG_37 ? _T_623[2] : REG_39_2; // @[Xbar.scala 277:24]
  wire  _T_686_3 = REG_37 ? _T_623[3] : REG_39_3; // @[Xbar.scala 277:24]
  wire  _T_686_4 = REG_37 ? _T_623[4] : REG_39_4; // @[Xbar.scala 277:24]
  wire [1:0] _T_711 = _T_684_0 ? auto_out_0_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_713 = _T_684_2 ? auto_out_2_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_714 = _T_684_3 ? auto_out_3_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_715 = _T_684_4 ? auto_out_4_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_717 = _T_711 | _T_713; // @[Mux.scala 27:72]
  wire [1:0] _T_718 = _T_717 | _T_714; // @[Mux.scala 27:72]
  wire [63:0] _T_720 = _T_684_0 ? auto_out_0_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_722 = _T_684_2 ? auto_out_2_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_723 = _T_684_3 ? auto_out_3_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_724 = _T_684_4 ? auto_out_4_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_726 = _T_720 | _T_722; // @[Mux.scala 27:72]
  wire [63:0] _T_727 = _T_726 | _T_723; // @[Mux.scala 27:72]
  wire [4:0] _T_765 = _T_762 & lo_14; // @[Arbiter.scala 28:29]
  wire [5:0] _T_766 = {_T_765, 1'h0}; // @[package.scala 244:48]
  wire [4:0] _T_768 = _T_765 | _T_766[4:0]; // @[package.scala 244:43]
  wire [6:0] _T_769 = {_T_768, 2'h0}; // @[package.scala 244:48]
  wire [4:0] _T_771 = _T_768 | _T_769[4:0]; // @[package.scala 244:43]
  wire [8:0] _T_772 = {_T_771, 4'h0}; // @[package.scala 244:48]
  wire [4:0] _T_774 = _T_771 | _T_772[4:0]; // @[package.scala 244:43]
  wire  _T_788 = _T_782 | _T_783; // @[Xbar.scala 262:50]
  wire  _T_789 = _T_782 | _T_783 | _T_784; // @[Xbar.scala 262:50]
  wire  _T_790 = _T_782 | _T_783 | _T_784 | _T_785; // @[Xbar.scala 262:50]
  wire  _T_791 = _T_782 | _T_783 | _T_784 | _T_785 | _T_786; // @[Xbar.scala 262:50]
  wire  _GEN_42 = _T_741 ? 1'h0 : REG_40; // @[Xbar.scala 273:21 Xbar.scala 273:28 Xbar.scala 249:23]
  wire  _GEN_43 = _T_173 | _GEN_42; // @[Xbar.scala 274:24 Xbar.scala 274:31]
  wire  _T_825_0 = REG_40 ? _T_762[0] : REG_42_0; // @[Xbar.scala 277:24]
  wire  _T_825_1 = REG_40 ? _T_762[1] : REG_42_1; // @[Xbar.scala 277:24]
  wire  _T_825_2 = REG_40 ? _T_762[2] : REG_42_2; // @[Xbar.scala 277:24]
  wire  _T_825_3 = REG_40 ? _T_762[3] : REG_42_3; // @[Xbar.scala 277:24]
  wire  _T_825_4 = REG_40 ? _T_762[4] : REG_42_4; // @[Xbar.scala 277:24]
  wire [1:0] _T_841 = _T_823_0 ? auto_out_0_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_842 = _T_823_1 ? auto_out_1_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_843 = _T_823_2 ? auto_out_2_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_844 = _T_823_3 ? auto_out_3_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_845 = _T_823_4 ? auto_out_4_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_846 = _T_841 | _T_842; // @[Mux.scala 27:72]
  wire [1:0] _T_847 = _T_846 | _T_843; // @[Mux.scala 27:72]
  wire [1:0] _T_848 = _T_847 | _T_844; // @[Mux.scala 27:72]
  QueueCompatibility_357 awIn_0 ( // @[Xbar.scala 62:47]
    .clock(awIn_0_clock),
    .reset(awIn_0_reset),
    .io_enq_ready(awIn_0_io_enq_ready),
    .io_enq_valid(awIn_0_io_enq_valid),
    .io_enq_bits(awIn_0_io_enq_bits),
    .io_deq_ready(awIn_0_io_deq_ready),
    .io_deq_valid(awIn_0_io_deq_valid),
    .io_deq_bits(awIn_0_io_deq_bits)
  );
  assign auto_in_aw_ready = in_0_aw_ready & (REG_16 | awIn_0_io_enq_ready); // @[Xbar.scala 146:45]
  assign auto_in_w_ready = in_0_w_ready & awIn_0_io_deq_valid; // @[Xbar.scala 153:43]
  assign auto_in_b_valid = REG_40 ? _T_741 : _T_839; // @[Xbar.scala 285:22]
  assign auto_in_b_bits_id = _T_857 | _T_854; // @[Mux.scala 27:72]
  assign auto_in_b_bits_resp = _T_848 | _T_845; // @[Mux.scala 27:72]
  assign auto_in_ar_ready = requestARIO_0_0 & auto_out_0_ar_ready | requestARIO_0_1 | requestARIO_0_2 &
    auto_out_2_ar_ready | requestARIO_0_3 & auto_out_3_ar_ready | requestARIO_0_4 & auto_out_4_ar_ready; // @[Mux.scala 27:72]
  assign auto_in_r_valid = REG_37 ? _T_602 : _T_700; // @[Xbar.scala 285:22]
  assign auto_in_r_bits_id = _T_736 | _T_733; // @[Mux.scala 27:72]
  assign auto_in_r_bits_data = _T_727 | _T_724; // @[Mux.scala 27:72]
  assign auto_in_r_bits_resp = _T_718 | _T_715; // @[Mux.scala 27:72]
  assign auto_in_r_bits_last = _T_684_0 & auto_out_0_r_bits_last | _T_684_1 & auto_out_1_r_bits_last | _T_684_2 &
    auto_out_2_r_bits_last | _T_684_3 & auto_out_3_r_bits_last | _T_684_4 & auto_out_4_r_bits_last; // @[Mux.scala 27:72]
  assign auto_out_4_aw_valid = in_0_aw_valid & requestAWIO_0_4; // @[Xbar.scala 229:40]
  assign auto_out_4_aw_bits_id = auto_in_aw_bits_id; // @[Xbar.scala 86:47]
  assign auto_out_4_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_w_valid = in_0_w_valid & requestWIO_0_4; // @[Xbar.scala 229:40]
  assign auto_out_4_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_b_ready = auto_in_b_ready & _T_825_4; // @[Xbar.scala 279:31]
  assign auto_out_4_ar_valid = auto_in_ar_valid & requestARIO_0_4; // @[Xbar.scala 229:40]
  assign auto_out_4_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_4_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_4_r_ready = auto_in_r_ready & _T_686_4; // @[Xbar.scala 279:31]
  assign auto_out_3_aw_valid = in_0_aw_valid & requestAWIO_0_3; // @[Xbar.scala 229:40]
  assign auto_out_3_aw_bits_id = auto_in_aw_bits_id; // @[Xbar.scala 86:47]
  assign auto_out_3_aw_bits_addr = auto_in_aw_bits_addr[28:0]; // @[Nodes.scala 1207:84 BundleMap.scala 247:19]
  assign auto_out_3_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_w_valid = in_0_w_valid & requestWIO_0_3; // @[Xbar.scala 229:40]
  assign auto_out_3_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_b_ready = auto_in_b_ready & _T_825_3; // @[Xbar.scala 279:31]
  assign auto_out_3_ar_valid = auto_in_ar_valid & requestARIO_0_3; // @[Xbar.scala 229:40]
  assign auto_out_3_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_3_ar_bits_addr = auto_in_ar_bits_addr[28:0]; // @[Nodes.scala 1207:84 BundleMap.scala 247:19]
  assign auto_out_3_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_3_r_ready = auto_in_r_ready & _T_686_3; // @[Xbar.scala 279:31]
  assign auto_out_2_aw_valid = in_0_aw_valid & requestAWIO_0_2; // @[Xbar.scala 229:40]
  assign auto_out_2_aw_bits_id = auto_in_aw_bits_id; // @[Xbar.scala 86:47]
  assign auto_out_2_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_w_valid = in_0_w_valid & requestWIO_0_2; // @[Xbar.scala 229:40]
  assign auto_out_2_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_b_ready = auto_in_b_ready & _T_825_2; // @[Xbar.scala 279:31]
  assign auto_out_2_ar_valid = auto_in_ar_valid & requestARIO_0_2; // @[Xbar.scala 229:40]
  assign auto_out_2_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_2_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_2_r_ready = auto_in_r_ready & _T_686_2; // @[Xbar.scala 279:31]
  assign auto_out_1_aw_valid = in_0_aw_valid & requestAWIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_aw_bits_id = auto_in_aw_bits_id; // @[Xbar.scala 86:47]
  assign auto_out_1_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_w_valid = in_0_w_valid & requestWIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_b_ready = auto_in_b_ready & _T_825_1; // @[Xbar.scala 279:31]
  assign auto_out_1_ar_valid = auto_in_ar_valid & requestARIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_1_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_r_ready = auto_in_r_ready & _T_686_1; // @[Xbar.scala 279:31]
  assign auto_out_0_aw_valid = in_0_aw_valid & requestAWIO_0_0; // @[Xbar.scala 229:40]
  assign auto_out_0_aw_bits_id = auto_in_aw_bits_id; // @[Xbar.scala 86:47]
  assign auto_out_0_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_w_valid = in_0_w_valid & requestWIO_0_0; // @[Xbar.scala 229:40]
  assign auto_out_0_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_b_ready = auto_in_b_ready & _T_825_0; // @[Xbar.scala 279:31]
  assign auto_out_0_ar_valid = auto_in_ar_valid & requestARIO_0_0; // @[Xbar.scala 229:40]
  assign auto_out_0_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_0_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_0_r_ready = auto_in_r_ready & _T_686_0; // @[Xbar.scala 279:31]
  assign awIn_0_clock = clock;
  assign awIn_0_reset = reset;
  assign awIn_0_io_enq_valid = auto_in_aw_valid & ~REG_16; // @[Xbar.scala 147:51]
  assign awIn_0_io_enq_bits = {hi,lo}; // @[Xbar.scala 71:75]
  assign awIn_0_io_deq_ready = auto_in_w_valid & auto_in_w_bits_last & in_0_w_ready; // @[Xbar.scala 154:74]
  always @(posedge clock) begin
    REG_37 <= reset | _GEN_40; // @[Xbar.scala 249:23 Xbar.scala 249:23]
    if (reset) begin // @[Arbiter.scala 23:23]
      REG_38 <= 5'h1f; // @[Arbiter.scala 23:23]
    end else if (REG_37 & |lo_12) begin // @[Arbiter.scala 27:32]
      REG_38 <= _T_635; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_39_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_37) begin // @[Xbar.scala 269:23]
      REG_39_0 <= _T_643;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_39_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_37) begin // @[Xbar.scala 269:23]
      REG_39_1 <= _T_644;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_39_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_37) begin // @[Xbar.scala 269:23]
      REG_39_2 <= _T_645;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_39_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_37) begin // @[Xbar.scala 269:23]
      REG_39_3 <= _T_646;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_39_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_37) begin // @[Xbar.scala 269:23]
      REG_39_4 <= _T_647;
    end
    REG_40 <= reset | _GEN_43; // @[Xbar.scala 249:23 Xbar.scala 249:23]
    if (reset) begin // @[Arbiter.scala 23:23]
      REG_41 <= 5'h1f; // @[Arbiter.scala 23:23]
    end else if (REG_40 & |lo_14) begin // @[Arbiter.scala 27:32]
      REG_41 <= _T_774; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_42_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_40) begin // @[Xbar.scala 269:23]
      REG_42_0 <= _T_782;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_42_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_40) begin // @[Xbar.scala 269:23]
      REG_42_1 <= _T_783;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_42_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_40) begin // @[Xbar.scala 269:23]
      REG_42_2 <= _T_784;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_42_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_40) begin // @[Xbar.scala 269:23]
      REG_42_3 <= _T_785;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_42_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_40) begin // @[Xbar.scala 269:23]
      REG_42_4 <= _T_786;
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_12 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_12 <= _T_314 - _T_312; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_8 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_8 <= _T_259 - _T_257; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_4 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_4 <= _T_204 - _T_202; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG <= _T_149 - _T_147; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 144:30]
      REG_16 <= 1'h0; // @[Xbar.scala 144:30]
    end else if (_T_372) begin // @[Xbar.scala 149:32]
      REG_16 <= 1'h0; // @[Xbar.scala 149:42]
    end else begin
      REG_16 <= _GEN_16;
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_14 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_14 <= _T_341 - _T_339; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_10 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_10 <= _T_286 - _T_284; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_6 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_6 <= _T_231 - _T_229; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_2 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_2 <= _T_176 - _T_174; // @[Xbar.scala 113:21]
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_147 | REG | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_147 | REG | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_143 | _T_164 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_143 | _T_164 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_174 | REG_2 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_174 | REG_2 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_171 | _T_191 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_171 | _T_191 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_202 | REG_4 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_202 | REG_4 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_198 | _T_219 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_198 | _T_219 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_229 | REG_6 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_229 | REG_6 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_226 | _T_246 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_226 | _T_246 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_257 | REG_8 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_257 | REG_8 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_253 | _T_274 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_253 | _T_274 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_284 | REG_10 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_284 | REG_10 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_281 | _T_301 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_281 | _T_301 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_312 | REG_12 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_312 | REG_12 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_308 | _T_329 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_308 | _T_329 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_339 | REG_14 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_339 | REG_14 | reset)) begin
          $fatal; // @[Xbar.scala 114:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_336 | _T_356 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_336 | _T_356 | reset)) begin
          $fatal; // @[Xbar.scala 115:22]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_432 | out_0_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_432 | out_0_aw_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_448 | out_0_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_448 | out_0_ar_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_466 | out_1_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_466 | out_1_aw_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_482 | out_1_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_482 | out_1_ar_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_500 | out_2_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_500 | out_2_aw_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_516 | out_2_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_516 | out_2_ar_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_534 | out_3_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_534 | out_3_aw_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_550 | out_3_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_550 | out_3_ar_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_568 | out_4_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_568 | out_4_aw_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_584 | out_4_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(_T_584 | out_4_ar_valid | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~((~_T_643 | ~_T_644) & (~_T_649 | ~_T_645) & (~_T_650 | ~_T_646) & (~_T_651 | ~_T_647) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Xbar.scala:263 assert((prefixOR zip winner) map { case (p,w) => !p || !w } reduce {_ && _})\n"
            ); // @[Xbar.scala 263:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~((~_T_643 | ~_T_644) & (~_T_649 | ~_T_645) & (~_T_650 | ~_T_646) & (~_T_651 | ~_T_647) | reset)) begin
          $fatal; // @[Xbar.scala 263:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_602 | _T_652 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_602 | _T_652 | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~((~_T_782 | ~_T_783) & (~_T_788 | ~_T_784) & (~_T_789 | ~_T_785) & (~_T_790 | ~_T_786) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Xbar.scala:263 assert((prefixOR zip winner) map { case (p,w) => !p || !w } reduce {_ && _})\n"
            ); // @[Xbar.scala 263:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~((~_T_782 | ~_T_783) & (~_T_788 | ~_T_784) & (~_T_789 | ~_T_785) & (~_T_790 | ~_T_786) | reset)) begin
          $fatal; // @[Xbar.scala 263:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_741 | _T_791 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_741 | _T_791 | reset)) begin
          $fatal; // @[Xbar.scala 265:12]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
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
  REG_37 = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  REG_38 = _RAND_1[4:0];
  _RAND_2 = {1{`RANDOM}};
  REG_39_0 = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  REG_39_1 = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  REG_39_2 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  REG_39_3 = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  REG_39_4 = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  REG_40 = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  REG_41 = _RAND_8[4:0];
  _RAND_9 = {1{`RANDOM}};
  REG_42_0 = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  REG_42_1 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  REG_42_2 = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  REG_42_3 = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  REG_42_4 = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  REG_12 = _RAND_14[0:0];
  _RAND_15 = {1{`RANDOM}};
  REG_8 = _RAND_15[0:0];
  _RAND_16 = {1{`RANDOM}};
  REG_4 = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  REG = _RAND_17[0:0];
  _RAND_18 = {1{`RANDOM}};
  REG_16 = _RAND_18[0:0];
  _RAND_19 = {1{`RANDOM}};
  REG_14 = _RAND_19[0:0];
  _RAND_20 = {1{`RANDOM}};
  REG_10 = _RAND_20[0:0];
  _RAND_21 = {1{`RANDOM}};
  REG_6 = _RAND_21[0:0];
  _RAND_22 = {1{`RANDOM}};
  REG_2 = _RAND_22[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
