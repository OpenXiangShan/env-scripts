module AXI4Xbar_1(
  input         clock,
  input         reset,
  output        auto_in_aw_ready,
  input         auto_in_aw_valid,
  input         auto_in_aw_bits_id,
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
  output        auto_in_b_bits_id,
  output [1:0]  auto_in_b_bits_resp,
  output        auto_in_ar_ready,
  input         auto_in_ar_valid,
  input         auto_in_ar_bits_id,
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
  output        auto_in_r_bits_id,
  output [63:0] auto_in_r_bits_data,
  output [1:0]  auto_in_r_bits_resp,
  output        auto_in_r_bits_last,
  input         auto_out_4_aw_ready,
  output        auto_out_4_aw_valid,
  output        auto_out_4_aw_bits_id,
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
  input         auto_out_4_b_bits_id,
  input  [1:0]  auto_out_4_b_bits_resp,
  input         auto_out_4_ar_ready,
  output        auto_out_4_ar_valid,
  output        auto_out_4_ar_bits_id,
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
  input         auto_out_4_r_bits_id,
  input  [63:0] auto_out_4_r_bits_data,
  input  [1:0]  auto_out_4_r_bits_resp,
  input         auto_out_4_r_bits_last,
  input         auto_out_3_aw_ready,
  output        auto_out_3_aw_valid,
  output        auto_out_3_aw_bits_id,
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
  input         auto_out_3_b_bits_id,
  input  [1:0]  auto_out_3_b_bits_resp,
  input         auto_out_3_ar_ready,
  output        auto_out_3_ar_valid,
  output        auto_out_3_ar_bits_id,
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
  input         auto_out_3_r_bits_id,
  input  [63:0] auto_out_3_r_bits_data,
  input  [1:0]  auto_out_3_r_bits_resp,
  input         auto_out_3_r_bits_last,
  input         auto_out_2_aw_ready,
  output        auto_out_2_aw_valid,
  output        auto_out_2_aw_bits_id,
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
  input         auto_out_2_b_bits_id,
  input  [1:0]  auto_out_2_b_bits_resp,
  input         auto_out_2_ar_ready,
  output        auto_out_2_ar_valid,
  output        auto_out_2_ar_bits_id,
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
  input         auto_out_2_r_bits_id,
  input  [63:0] auto_out_2_r_bits_data,
  input  [1:0]  auto_out_2_r_bits_resp,
  input         auto_out_2_r_bits_last,
  input         auto_out_1_aw_ready,
  output        auto_out_1_aw_valid,
  output        auto_out_1_aw_bits_id,
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
  input         auto_out_1_b_bits_id,
  input  [1:0]  auto_out_1_b_bits_resp,
  output        auto_out_1_ar_valid,
  output        auto_out_1_ar_bits_id,
  output [7:0]  auto_out_1_ar_bits_len,
  output [2:0]  auto_out_1_ar_bits_size,
  output [1:0]  auto_out_1_ar_bits_burst,
  output        auto_out_1_ar_bits_lock,
  output [3:0]  auto_out_1_ar_bits_cache,
  output [3:0]  auto_out_1_ar_bits_qos,
  output        auto_out_1_r_ready,
  input         auto_out_1_r_valid,
  input         auto_out_1_r_bits_id,
  input         auto_out_1_r_bits_last,
  input         auto_out_0_aw_ready,
  output        auto_out_0_aw_valid,
  output        auto_out_0_aw_bits_id,
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
  input         auto_out_0_b_bits_id,
  input  [1:0]  auto_out_0_b_bits_resp,
  input         auto_out_0_ar_ready,
  output        auto_out_0_ar_valid,
  output        auto_out_0_ar_bits_id,
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
  input         auto_out_0_r_bits_id,
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
  reg  REG_29; // @[Xbar.scala 249:23]
  wire [4:0] lo_12 = {auto_out_4_r_valid,auto_out_3_r_valid,auto_out_2_r_valid,auto_out_1_r_valid,auto_out_0_r_valid}; // @[Cat.scala 30:58]
  reg [4:0] REG_30; // @[Arbiter.scala 23:23]
  wire [4:0] _T_498 = ~REG_30; // @[Arbiter.scala 24:30]
  wire [4:0] hi_12 = lo_12 & _T_498; // @[Arbiter.scala 24:28]
  wire [9:0] _T_499 = {hi_12,auto_out_4_r_valid,auto_out_3_r_valid,auto_out_2_r_valid,auto_out_1_r_valid,
    auto_out_0_r_valid}; // @[Cat.scala 30:58]
  wire [9:0] _GEN_36 = {{1'd0}, _T_499[9:1]}; // @[package.scala 253:43]
  wire [9:0] _T_501 = _T_499 | _GEN_36; // @[package.scala 253:43]
  wire [9:0] _GEN_37 = {{2'd0}, _T_501[9:2]}; // @[package.scala 253:43]
  wire [9:0] _T_503 = _T_501 | _GEN_37; // @[package.scala 253:43]
  wire [9:0] _GEN_38 = {{4'd0}, _T_503[9:4]}; // @[package.scala 253:43]
  wire [9:0] _T_505 = _T_503 | _GEN_38; // @[package.scala 253:43]
  wire [9:0] _T_508 = {REG_30, 5'h0}; // @[Arbiter.scala 25:66]
  wire [9:0] _GEN_39 = {{1'd0}, _T_505[9:1]}; // @[Arbiter.scala 25:58]
  wire [9:0] _T_509 = _GEN_39 | _T_508; // @[Arbiter.scala 25:58]
  wire [4:0] _T_512 = _T_509[9:5] & _T_509[4:0]; // @[Arbiter.scala 26:39]
  wire [4:0] _T_513 = ~_T_512; // @[Arbiter.scala 26:18]
  wire  _T_533 = _T_513[0] & auto_out_0_r_valid; // @[Xbar.scala 257:63]
  reg  REG_31_0; // @[Xbar.scala 268:24]
  wire  _T_574_0 = REG_29 ? _T_533 : REG_31_0; // @[Xbar.scala 269:23]
  wire  _T_534 = _T_513[1] & auto_out_1_r_valid; // @[Xbar.scala 257:63]
  reg  REG_31_1; // @[Xbar.scala 268:24]
  wire  _T_574_1 = REG_29 ? _T_534 : REG_31_1; // @[Xbar.scala 269:23]
  wire  _T_535 = _T_513[2] & auto_out_2_r_valid; // @[Xbar.scala 257:63]
  reg  REG_31_2; // @[Xbar.scala 268:24]
  wire  _T_574_2 = REG_29 ? _T_535 : REG_31_2; // @[Xbar.scala 269:23]
  wire  _T_536 = _T_513[3] & auto_out_3_r_valid; // @[Xbar.scala 257:63]
  reg  REG_31_3; // @[Xbar.scala 268:24]
  wire  _T_574_3 = REG_29 ? _T_536 : REG_31_3; // @[Xbar.scala 269:23]
  wire  _T_537 = _T_513[4] & auto_out_4_r_valid; // @[Xbar.scala 257:63]
  reg  REG_31_4; // @[Xbar.scala 268:24]
  wire  _T_574_4 = REG_29 ? _T_537 : REG_31_4; // @[Xbar.scala 269:23]
  wire  in_0_r_bits_id = _T_574_0 & auto_out_0_r_bits_id | _T_574_1 & auto_out_1_r_bits_id | _T_574_2 &
    auto_out_2_r_bits_id | _T_574_3 & auto_out_3_r_bits_id | _T_574_4 & auto_out_4_r_bits_id; // @[Mux.scala 27:72]
  reg  REG_32; // @[Xbar.scala 249:23]
  wire [4:0] lo_14 = {auto_out_4_b_valid,auto_out_3_b_valid,auto_out_2_b_valid,auto_out_1_b_valid,auto_out_0_b_valid}; // @[Cat.scala 30:58]
  reg [4:0] REG_33; // @[Arbiter.scala 23:23]
  wire [4:0] _T_637 = ~REG_33; // @[Arbiter.scala 24:30]
  wire [4:0] hi_14 = lo_14 & _T_637; // @[Arbiter.scala 24:28]
  wire [9:0] _T_638 = {hi_14,auto_out_4_b_valid,auto_out_3_b_valid,auto_out_2_b_valid,auto_out_1_b_valid,
    auto_out_0_b_valid}; // @[Cat.scala 30:58]
  wire [9:0] _GEN_40 = {{1'd0}, _T_638[9:1]}; // @[package.scala 253:43]
  wire [9:0] _T_640 = _T_638 | _GEN_40; // @[package.scala 253:43]
  wire [9:0] _GEN_41 = {{2'd0}, _T_640[9:2]}; // @[package.scala 253:43]
  wire [9:0] _T_642 = _T_640 | _GEN_41; // @[package.scala 253:43]
  wire [9:0] _GEN_42 = {{4'd0}, _T_642[9:4]}; // @[package.scala 253:43]
  wire [9:0] _T_644 = _T_642 | _GEN_42; // @[package.scala 253:43]
  wire [9:0] _T_647 = {REG_33, 5'h0}; // @[Arbiter.scala 25:66]
  wire [9:0] _GEN_43 = {{1'd0}, _T_644[9:1]}; // @[Arbiter.scala 25:58]
  wire [9:0] _T_648 = _GEN_43 | _T_647; // @[Arbiter.scala 25:58]
  wire [4:0] _T_651 = _T_648[9:5] & _T_648[4:0]; // @[Arbiter.scala 26:39]
  wire [4:0] _T_652 = ~_T_651; // @[Arbiter.scala 26:18]
  wire  _T_672 = _T_652[0] & auto_out_0_b_valid; // @[Xbar.scala 257:63]
  reg  REG_34_0; // @[Xbar.scala 268:24]
  wire  _T_713_0 = REG_32 ? _T_672 : REG_34_0; // @[Xbar.scala 269:23]
  wire  _T_673 = _T_652[1] & auto_out_1_b_valid; // @[Xbar.scala 257:63]
  reg  REG_34_1; // @[Xbar.scala 268:24]
  wire  _T_713_1 = REG_32 ? _T_673 : REG_34_1; // @[Xbar.scala 269:23]
  wire  _T_674 = _T_652[2] & auto_out_2_b_valid; // @[Xbar.scala 257:63]
  reg  REG_34_2; // @[Xbar.scala 268:24]
  wire  _T_713_2 = REG_32 ? _T_674 : REG_34_2; // @[Xbar.scala 269:23]
  wire  _T_675 = _T_652[3] & auto_out_3_b_valid; // @[Xbar.scala 257:63]
  reg  REG_34_3; // @[Xbar.scala 268:24]
  wire  _T_713_3 = REG_32 ? _T_675 : REG_34_3; // @[Xbar.scala 269:23]
  wire  _T_676 = _T_652[4] & auto_out_4_b_valid; // @[Xbar.scala 257:63]
  reg  REG_34_4; // @[Xbar.scala 268:24]
  wire  _T_713_4 = REG_32 ? _T_676 : REG_34_4; // @[Xbar.scala 269:23]
  wire  in_0_b_bits_id = _T_713_0 & auto_out_0_b_bits_id | _T_713_1 & auto_out_1_b_bits_id | _T_713_2 &
    auto_out_2_b_bits_id | _T_713_3 & auto_out_3_b_bits_id | _T_713_4 & auto_out_4_b_bits_id; // @[Mux.scala 27:72]
  wire [1:0] _T_125 = 2'h1 << auto_in_ar_bits_id; // @[OneHot.scala 65:12]
  wire [1:0] _T_127 = 2'h1 << auto_in_aw_bits_id; // @[OneHot.scala 65:12]
  wire [1:0] _T_129 = 2'h1 << in_0_r_bits_id; // @[OneHot.scala 65:12]
  wire [1:0] _T_131 = 2'h1 << in_0_b_bits_id; // @[OneHot.scala 65:12]
  wire  in_0_ar_ready = requestARIO_0_0 & auto_out_0_ar_ready | requestARIO_0_1 | requestARIO_0_2 & auto_out_2_ar_ready
     | requestARIO_0_3 & auto_out_3_ar_ready | requestARIO_0_4 & auto_out_4_ar_ready; // @[Mux.scala 27:72]
  reg  REG_4; // @[Xbar.scala 111:34]
  wire  _T_219 = ~REG_4; // @[Xbar.scala 119:22]
  reg  REG; // @[Xbar.scala 111:34]
  wire  _T_164 = ~REG; // @[Xbar.scala 119:22]
  wire  _T_142 = in_0_ar_ready & auto_in_ar_valid; // @[Decoupled.scala 40:37]
  wire  _T_143 = _T_125[0] & _T_142; // @[Xbar.scala 126:25]
  wire  _T_492 = auto_out_0_r_valid | auto_out_1_r_valid | auto_out_2_r_valid | auto_out_3_r_valid | auto_out_4_r_valid; // @[Xbar.scala 253:36]
  wire  _T_590 = REG_31_0 & auto_out_0_r_valid | REG_31_1 & auto_out_1_r_valid | REG_31_2 & auto_out_2_r_valid |
    REG_31_3 & auto_out_3_r_valid | REG_31_4 & auto_out_4_r_valid; // @[Mux.scala 27:72]
  wire  in_0_r_valid = REG_29 ? _T_492 : _T_590; // @[Xbar.scala 285:22]
  wire  _T_145 = auto_in_r_ready & in_0_r_valid; // @[Decoupled.scala 40:37]
  wire  in_0_r_bits_last = _T_574_0 & auto_out_0_r_bits_last | _T_574_1 & auto_out_1_r_bits_last | _T_574_2 &
    auto_out_2_r_bits_last | _T_574_3 & auto_out_3_r_bits_last | _T_574_4 & auto_out_4_r_bits_last; // @[Mux.scala 27:72]
  wire  _T_147 = _T_129[0] & _T_145 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_149 = REG + _T_143; // @[Xbar.scala 113:30]
  wire  in_0_aw_ready = requestAWIO_0_0 & auto_out_0_aw_ready | requestAWIO_0_1 & auto_out_1_aw_ready | requestAWIO_0_2
     & auto_out_2_aw_ready | requestAWIO_0_3 & auto_out_3_aw_ready | requestAWIO_0_4 & auto_out_4_aw_ready; // @[Mux.scala 27:72]
  reg  REG_8; // @[Xbar.scala 144:30]
  wire  _T_256 = REG_8 | awIn_0_io_enq_ready; // @[Xbar.scala 146:57]
  wire  io_in_0_aw_ready = in_0_aw_ready & (REG_8 | awIn_0_io_enq_ready); // @[Xbar.scala 146:45]
  reg  REG_6; // @[Xbar.scala 111:34]
  wire  _T_246 = ~REG_6; // @[Xbar.scala 119:22]
  reg  REG_2; // @[Xbar.scala 111:34]
  wire  _T_191 = ~REG_2; // @[Xbar.scala 119:22]
  wire  _T_170 = io_in_0_aw_ready & auto_in_aw_valid; // @[Decoupled.scala 40:37]
  wire  _T_171 = _T_127[0] & _T_170; // @[Xbar.scala 130:25]
  wire  _T_631 = auto_out_0_b_valid | auto_out_1_b_valid | auto_out_2_b_valid | auto_out_3_b_valid | auto_out_4_b_valid; // @[Xbar.scala 253:36]
  wire  _T_729 = REG_34_0 & auto_out_0_b_valid | REG_34_1 & auto_out_1_b_valid | REG_34_2 & auto_out_2_b_valid |
    REG_34_3 & auto_out_3_b_valid | REG_34_4 & auto_out_4_b_valid; // @[Mux.scala 27:72]
  wire  in_0_b_valid = REG_32 ? _T_631 : _T_729; // @[Xbar.scala 285:22]
  wire  _T_173 = auto_in_b_ready & in_0_b_valid; // @[Decoupled.scala 40:37]
  wire  _T_174 = _T_131[0] & _T_173; // @[Xbar.scala 131:24]
  wire  _T_176 = REG_2 + _T_171; // @[Xbar.scala 113:30]
  wire  _T_198 = _T_125[1] & _T_142; // @[Xbar.scala 126:25]
  wire  _T_202 = _T_129[1] & _T_145 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_204 = REG_4 + _T_198; // @[Xbar.scala 113:30]
  wire  _T_226 = _T_127[1] & _T_170; // @[Xbar.scala 130:25]
  wire  _T_229 = _T_131[1] & _T_173; // @[Xbar.scala 131:24]
  wire  _T_231 = REG_6 + _T_226; // @[Xbar.scala 113:30]
  wire  in_0_aw_valid = auto_in_aw_valid & _T_256; // @[Xbar.scala 145:45]
  wire  _T_261 = awIn_0_io_enq_ready & awIn_0_io_enq_valid; // @[Decoupled.scala 40:37]
  wire  _GEN_8 = _T_261 | REG_8; // @[Xbar.scala 148:38 Xbar.scala 148:48 Xbar.scala 144:30]
  wire  _T_262 = in_0_aw_ready & in_0_aw_valid; // @[Decoupled.scala 40:37]
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
  wire  _T_322 = ~out_0_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_338 = ~out_0_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_356 = ~out_1_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_372 = ~out_1_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_390 = ~out_2_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_406 = ~out_2_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_424 = ~out_3_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_440 = ~out_3_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_458 = ~out_4_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_474 = ~out_4_ar_valid; // @[Xbar.scala 263:60]
  wire [4:0] _T_516 = _T_513 & lo_12; // @[Arbiter.scala 28:29]
  wire [5:0] _T_517 = {_T_516, 1'h0}; // @[package.scala 244:48]
  wire [4:0] _T_519 = _T_516 | _T_517[4:0]; // @[package.scala 244:43]
  wire [6:0] _T_520 = {_T_519, 2'h0}; // @[package.scala 244:48]
  wire [4:0] _T_522 = _T_519 | _T_520[4:0]; // @[package.scala 244:43]
  wire [8:0] _T_523 = {_T_522, 4'h0}; // @[package.scala 244:48]
  wire [4:0] _T_525 = _T_522 | _T_523[4:0]; // @[package.scala 244:43]
  wire  _T_539 = _T_533 | _T_534; // @[Xbar.scala 262:50]
  wire  _T_540 = _T_533 | _T_534 | _T_535; // @[Xbar.scala 262:50]
  wire  _T_541 = _T_533 | _T_534 | _T_535 | _T_536; // @[Xbar.scala 262:50]
  wire  _T_542 = _T_533 | _T_534 | _T_535 | _T_536 | _T_537; // @[Xbar.scala 262:50]
  wire  _GEN_31 = _T_492 ? 1'h0 : REG_29; // @[Xbar.scala 273:21 Xbar.scala 273:28 Xbar.scala 249:23]
  wire  _GEN_32 = _T_145 | _GEN_31; // @[Xbar.scala 274:24 Xbar.scala 274:31]
  wire  _T_576_0 = REG_29 ? _T_513[0] : REG_31_0; // @[Xbar.scala 277:24]
  wire  _T_576_1 = REG_29 ? _T_513[1] : REG_31_1; // @[Xbar.scala 277:24]
  wire  _T_576_2 = REG_29 ? _T_513[2] : REG_31_2; // @[Xbar.scala 277:24]
  wire  _T_576_3 = REG_29 ? _T_513[3] : REG_31_3; // @[Xbar.scala 277:24]
  wire  _T_576_4 = REG_29 ? _T_513[4] : REG_31_4; // @[Xbar.scala 277:24]
  wire [1:0] _T_601 = _T_574_0 ? auto_out_0_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_603 = _T_574_2 ? auto_out_2_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_604 = _T_574_3 ? auto_out_3_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_605 = _T_574_4 ? auto_out_4_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_607 = _T_601 | _T_603; // @[Mux.scala 27:72]
  wire [1:0] _T_608 = _T_607 | _T_604; // @[Mux.scala 27:72]
  wire [63:0] _T_610 = _T_574_0 ? auto_out_0_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_612 = _T_574_2 ? auto_out_2_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_613 = _T_574_3 ? auto_out_3_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_614 = _T_574_4 ? auto_out_4_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_616 = _T_610 | _T_612; // @[Mux.scala 27:72]
  wire [63:0] _T_617 = _T_616 | _T_613; // @[Mux.scala 27:72]
  wire [4:0] _T_655 = _T_652 & lo_14; // @[Arbiter.scala 28:29]
  wire [5:0] _T_656 = {_T_655, 1'h0}; // @[package.scala 244:48]
  wire [4:0] _T_658 = _T_655 | _T_656[4:0]; // @[package.scala 244:43]
  wire [6:0] _T_659 = {_T_658, 2'h0}; // @[package.scala 244:48]
  wire [4:0] _T_661 = _T_658 | _T_659[4:0]; // @[package.scala 244:43]
  wire [8:0] _T_662 = {_T_661, 4'h0}; // @[package.scala 244:48]
  wire [4:0] _T_664 = _T_661 | _T_662[4:0]; // @[package.scala 244:43]
  wire  _T_678 = _T_672 | _T_673; // @[Xbar.scala 262:50]
  wire  _T_679 = _T_672 | _T_673 | _T_674; // @[Xbar.scala 262:50]
  wire  _T_680 = _T_672 | _T_673 | _T_674 | _T_675; // @[Xbar.scala 262:50]
  wire  _T_681 = _T_672 | _T_673 | _T_674 | _T_675 | _T_676; // @[Xbar.scala 262:50]
  wire  _GEN_34 = _T_631 ? 1'h0 : REG_32; // @[Xbar.scala 273:21 Xbar.scala 273:28 Xbar.scala 249:23]
  wire  _GEN_35 = _T_173 | _GEN_34; // @[Xbar.scala 274:24 Xbar.scala 274:31]
  wire  _T_715_0 = REG_32 ? _T_652[0] : REG_34_0; // @[Xbar.scala 277:24]
  wire  _T_715_1 = REG_32 ? _T_652[1] : REG_34_1; // @[Xbar.scala 277:24]
  wire  _T_715_2 = REG_32 ? _T_652[2] : REG_34_2; // @[Xbar.scala 277:24]
  wire  _T_715_3 = REG_32 ? _T_652[3] : REG_34_3; // @[Xbar.scala 277:24]
  wire  _T_715_4 = REG_32 ? _T_652[4] : REG_34_4; // @[Xbar.scala 277:24]
  wire [1:0] _T_731 = _T_713_0 ? auto_out_0_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_732 = _T_713_1 ? auto_out_1_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_733 = _T_713_2 ? auto_out_2_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_734 = _T_713_3 ? auto_out_3_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_735 = _T_713_4 ? auto_out_4_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_736 = _T_731 | _T_732; // @[Mux.scala 27:72]
  wire [1:0] _T_737 = _T_736 | _T_733; // @[Mux.scala 27:72]
  wire [1:0] _T_738 = _T_737 | _T_734; // @[Mux.scala 27:72]
  QueueCompatibility_347 awIn_0 ( // @[Xbar.scala 62:47]
    .clock(awIn_0_clock),
    .reset(awIn_0_reset),
    .io_enq_ready(awIn_0_io_enq_ready),
    .io_enq_valid(awIn_0_io_enq_valid),
    .io_enq_bits(awIn_0_io_enq_bits),
    .io_deq_ready(awIn_0_io_deq_ready),
    .io_deq_valid(awIn_0_io_deq_valid),
    .io_deq_bits(awIn_0_io_deq_bits)
  );
  assign auto_in_aw_ready = in_0_aw_ready & (REG_8 | awIn_0_io_enq_ready); // @[Xbar.scala 146:45]
  assign auto_in_w_ready = in_0_w_ready & awIn_0_io_deq_valid; // @[Xbar.scala 153:43]
  assign auto_in_b_valid = REG_32 ? _T_631 : _T_729; // @[Xbar.scala 285:22]
  assign auto_in_b_bits_id = _T_713_0 & auto_out_0_b_bits_id | _T_713_1 & auto_out_1_b_bits_id | _T_713_2 &
    auto_out_2_b_bits_id | _T_713_3 & auto_out_3_b_bits_id | _T_713_4 & auto_out_4_b_bits_id; // @[Mux.scala 27:72]
  assign auto_in_b_bits_resp = _T_738 | _T_735; // @[Mux.scala 27:72]
  assign auto_in_ar_ready = requestARIO_0_0 & auto_out_0_ar_ready | requestARIO_0_1 | requestARIO_0_2 &
    auto_out_2_ar_ready | requestARIO_0_3 & auto_out_3_ar_ready | requestARIO_0_4 & auto_out_4_ar_ready; // @[Mux.scala 27:72]
  assign auto_in_r_valid = REG_29 ? _T_492 : _T_590; // @[Xbar.scala 285:22]
  assign auto_in_r_bits_id = _T_574_0 & auto_out_0_r_bits_id | _T_574_1 & auto_out_1_r_bits_id | _T_574_2 &
    auto_out_2_r_bits_id | _T_574_3 & auto_out_3_r_bits_id | _T_574_4 & auto_out_4_r_bits_id; // @[Mux.scala 27:72]
  assign auto_in_r_bits_data = _T_617 | _T_614; // @[Mux.scala 27:72]
  assign auto_in_r_bits_resp = _T_608 | _T_605; // @[Mux.scala 27:72]
  assign auto_in_r_bits_last = _T_574_0 & auto_out_0_r_bits_last | _T_574_1 & auto_out_1_r_bits_last | _T_574_2 &
    auto_out_2_r_bits_last | _T_574_3 & auto_out_3_r_bits_last | _T_574_4 & auto_out_4_r_bits_last; // @[Mux.scala 27:72]
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
  assign auto_out_4_b_ready = auto_in_b_ready & _T_715_4; // @[Xbar.scala 279:31]
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
  assign auto_out_4_r_ready = auto_in_r_ready & _T_576_4; // @[Xbar.scala 279:31]
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
  assign auto_out_3_b_ready = auto_in_b_ready & _T_715_3; // @[Xbar.scala 279:31]
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
  assign auto_out_3_r_ready = auto_in_r_ready & _T_576_3; // @[Xbar.scala 279:31]
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
  assign auto_out_2_b_ready = auto_in_b_ready & _T_715_2; // @[Xbar.scala 279:31]
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
  assign auto_out_2_r_ready = auto_in_r_ready & _T_576_2; // @[Xbar.scala 279:31]
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
  assign auto_out_1_b_ready = auto_in_b_ready & _T_715_1; // @[Xbar.scala 279:31]
  assign auto_out_1_ar_valid = auto_in_ar_valid & requestARIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_1_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_r_ready = auto_in_r_ready & _T_576_1; // @[Xbar.scala 279:31]
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
  assign auto_out_0_b_ready = auto_in_b_ready & _T_715_0; // @[Xbar.scala 279:31]
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
  assign auto_out_0_r_ready = auto_in_r_ready & _T_576_0; // @[Xbar.scala 279:31]
  assign awIn_0_clock = clock;
  assign awIn_0_reset = reset;
  assign awIn_0_io_enq_valid = auto_in_aw_valid & ~REG_8; // @[Xbar.scala 147:51]
  assign awIn_0_io_enq_bits = {hi,lo}; // @[Xbar.scala 71:75]
  assign awIn_0_io_deq_ready = auto_in_w_valid & auto_in_w_bits_last & in_0_w_ready; // @[Xbar.scala 154:74]
  always @(posedge clock) begin
    REG_29 <= reset | _GEN_32; // @[Xbar.scala 249:23 Xbar.scala 249:23]
    if (reset) begin // @[Arbiter.scala 23:23]
      REG_30 <= 5'h1f; // @[Arbiter.scala 23:23]
    end else if (REG_29 & |lo_12) begin // @[Arbiter.scala 27:32]
      REG_30 <= _T_525; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_31_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_29) begin // @[Xbar.scala 269:23]
      REG_31_0 <= _T_533;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_31_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_29) begin // @[Xbar.scala 269:23]
      REG_31_1 <= _T_534;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_31_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_29) begin // @[Xbar.scala 269:23]
      REG_31_2 <= _T_535;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_31_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_29) begin // @[Xbar.scala 269:23]
      REG_31_3 <= _T_536;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_31_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_29) begin // @[Xbar.scala 269:23]
      REG_31_4 <= _T_537;
    end
    REG_32 <= reset | _GEN_35; // @[Xbar.scala 249:23 Xbar.scala 249:23]
    if (reset) begin // @[Arbiter.scala 23:23]
      REG_33 <= 5'h1f; // @[Arbiter.scala 23:23]
    end else if (REG_32 & |lo_14) begin // @[Arbiter.scala 27:32]
      REG_33 <= _T_664; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_34_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_32) begin // @[Xbar.scala 269:23]
      REG_34_0 <= _T_672;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_34_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_32) begin // @[Xbar.scala 269:23]
      REG_34_1 <= _T_673;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_34_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_32) begin // @[Xbar.scala 269:23]
      REG_34_2 <= _T_674;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_34_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_32) begin // @[Xbar.scala 269:23]
      REG_34_3 <= _T_675;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_34_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_32) begin // @[Xbar.scala 269:23]
      REG_34_4 <= _T_676;
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
      REG_8 <= 1'h0; // @[Xbar.scala 144:30]
    end else if (_T_262) begin // @[Xbar.scala 149:32]
      REG_8 <= 1'h0; // @[Xbar.scala 149:42]
    end else begin
      REG_8 <= _GEN_8;
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
        if (~(_T_322 | out_0_aw_valid | reset)) begin
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
        if (~(_T_322 | out_0_aw_valid | reset)) begin
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
        if (~(_T_338 | out_0_ar_valid | reset)) begin
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
        if (~(_T_338 | out_0_ar_valid | reset)) begin
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
        if (~(_T_356 | out_1_aw_valid | reset)) begin
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
        if (~(_T_356 | out_1_aw_valid | reset)) begin
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
        if (~(_T_372 | out_1_ar_valid | reset)) begin
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
        if (~(_T_372 | out_1_ar_valid | reset)) begin
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
        if (~(_T_390 | out_2_aw_valid | reset)) begin
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
        if (~(_T_390 | out_2_aw_valid | reset)) begin
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
        if (~(_T_406 | out_2_ar_valid | reset)) begin
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
        if (~(_T_406 | out_2_ar_valid | reset)) begin
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
        if (~(_T_424 | out_3_aw_valid | reset)) begin
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
        if (~(_T_424 | out_3_aw_valid | reset)) begin
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
        if (~(_T_440 | out_3_ar_valid | reset)) begin
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
        if (~(_T_440 | out_3_ar_valid | reset)) begin
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
        if (~(_T_458 | out_4_aw_valid | reset)) begin
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
        if (~(_T_458 | out_4_aw_valid | reset)) begin
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
        if (~(_T_474 | out_4_ar_valid | reset)) begin
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
        if (~(_T_474 | out_4_ar_valid | reset)) begin
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
        if (~((~_T_533 | ~_T_534) & (~_T_539 | ~_T_535) & (~_T_540 | ~_T_536) & (~_T_541 | ~_T_537) | reset)) begin
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
        if (~((~_T_533 | ~_T_534) & (~_T_539 | ~_T_535) & (~_T_540 | ~_T_536) & (~_T_541 | ~_T_537) | reset)) begin
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
        if (~(~_T_492 | _T_542 | reset)) begin
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
        if (~(~_T_492 | _T_542 | reset)) begin
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
        if (~((~_T_672 | ~_T_673) & (~_T_678 | ~_T_674) & (~_T_679 | ~_T_675) & (~_T_680 | ~_T_676) | reset)) begin
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
        if (~((~_T_672 | ~_T_673) & (~_T_678 | ~_T_674) & (~_T_679 | ~_T_675) & (~_T_680 | ~_T_676) | reset)) begin
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
        if (~(~_T_631 | _T_681 | reset)) begin
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
        if (~(~_T_631 | _T_681 | reset)) begin
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
  REG_29 = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  REG_30 = _RAND_1[4:0];
  _RAND_2 = {1{`RANDOM}};
  REG_31_0 = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  REG_31_1 = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  REG_31_2 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  REG_31_3 = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  REG_31_4 = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  REG_32 = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  REG_33 = _RAND_8[4:0];
  _RAND_9 = {1{`RANDOM}};
  REG_34_0 = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  REG_34_1 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  REG_34_2 = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  REG_34_3 = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  REG_34_4 = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  REG_4 = _RAND_14[0:0];
  _RAND_15 = {1{`RANDOM}};
  REG = _RAND_15[0:0];
  _RAND_16 = {1{`RANDOM}};
  REG_8 = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  REG_6 = _RAND_17[0:0];
  _RAND_18 = {1{`RANDOM}};
  REG_2 = _RAND_18[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
