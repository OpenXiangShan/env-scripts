module AXI4Xbar(
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
  input         auto_out_5_aw_ready,
  output        auto_out_5_aw_valid,
  output [1:0]  auto_out_5_aw_bits_id,
  output [30:0] auto_out_5_aw_bits_addr,
  output [7:0]  auto_out_5_aw_bits_len,
  output [2:0]  auto_out_5_aw_bits_size,
  output [1:0]  auto_out_5_aw_bits_burst,
  output        auto_out_5_aw_bits_lock,
  output [3:0]  auto_out_5_aw_bits_cache,
  output [2:0]  auto_out_5_aw_bits_prot,
  output [3:0]  auto_out_5_aw_bits_qos,
  input         auto_out_5_w_ready,
  output        auto_out_5_w_valid,
  output [63:0] auto_out_5_w_bits_data,
  output [7:0]  auto_out_5_w_bits_strb,
  output        auto_out_5_w_bits_last,
  output        auto_out_5_b_ready,
  input         auto_out_5_b_valid,
  input  [1:0]  auto_out_5_b_bits_id,
  input  [1:0]  auto_out_5_b_bits_resp,
  input         auto_out_5_ar_ready,
  output        auto_out_5_ar_valid,
  output [1:0]  auto_out_5_ar_bits_id,
  output [30:0] auto_out_5_ar_bits_addr,
  output [7:0]  auto_out_5_ar_bits_len,
  output [2:0]  auto_out_5_ar_bits_size,
  output [1:0]  auto_out_5_ar_bits_burst,
  output        auto_out_5_ar_bits_lock,
  output [3:0]  auto_out_5_ar_bits_cache,
  output [2:0]  auto_out_5_ar_bits_prot,
  output [3:0]  auto_out_5_ar_bits_qos,
  output        auto_out_5_r_ready,
  input         auto_out_5_r_valid,
  input  [1:0]  auto_out_5_r_bits_id,
  input  [63:0] auto_out_5_r_bits_data,
  input  [1:0]  auto_out_5_r_bits_resp,
  input         auto_out_5_r_bits_last,
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
  reg [31:0] _RAND_23;
  reg [31:0] _RAND_24;
`endif // RANDOMIZE_REG_INIT
  wire  awIn_0_clock; // @[Xbar.scala 62:47]
  wire  awIn_0_reset; // @[Xbar.scala 62:47]
  wire  awIn_0_io_enq_ready; // @[Xbar.scala 62:47]
  wire  awIn_0_io_enq_valid; // @[Xbar.scala 62:47]
  wire [5:0] awIn_0_io_enq_bits; // @[Xbar.scala 62:47]
  wire  awIn_0_io_deq_ready; // @[Xbar.scala 62:47]
  wire  awIn_0_io_deq_valid; // @[Xbar.scala 62:47]
  wire [5:0] awIn_0_io_deq_bits; // @[Xbar.scala 62:47]
  wire [30:0] _T = auto_in_ar_bits_addr ^ 31'h40200000; // @[Parameters.scala 137:31]
  wire [31:0] _T_1 = {1'b0,$signed(_T)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_3 = $signed(_T_1) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_0 = $signed(_T_3) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_5 = auto_in_ar_bits_addr ^ 31'h50000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_6 = {1'b0,$signed(_T_5)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_8 = $signed(_T_6) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_1 = $signed(_T_8) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_10 = auto_in_ar_bits_addr ^ 31'h40000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_11 = {1'b0,$signed(_T_10)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_13 = $signed(_T_11) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_2 = $signed(_T_13) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_15 = auto_in_ar_bits_addr ^ 31'h10000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_16 = {1'b0,$signed(_T_15)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_18 = $signed(_T_16) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_3 = $signed(_T_18) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_20 = auto_in_ar_bits_addr ^ 31'h40002000; // @[Parameters.scala 137:31]
  wire [31:0] _T_21 = {1'b0,$signed(_T_20)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_23 = $signed(_T_21) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_4 = $signed(_T_23) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_25 = auto_in_ar_bits_addr ^ 31'h40040000; // @[Parameters.scala 137:31]
  wire [31:0] _T_26 = {1'b0,$signed(_T_25)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_28 = $signed(_T_26) & 32'sh50240000; // @[Parameters.scala 137:52]
  wire  requestARIO_0_5 = $signed(_T_28) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_30 = auto_in_aw_bits_addr ^ 31'h40200000; // @[Parameters.scala 137:31]
  wire [31:0] _T_31 = {1'b0,$signed(_T_30)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_33 = $signed(_T_31) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_0 = $signed(_T_33) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_35 = auto_in_aw_bits_addr ^ 31'h50000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_36 = {1'b0,$signed(_T_35)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_38 = $signed(_T_36) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_1 = $signed(_T_38) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_40 = auto_in_aw_bits_addr ^ 31'h40000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_41 = {1'b0,$signed(_T_40)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_43 = $signed(_T_41) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_2 = $signed(_T_43) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_45 = auto_in_aw_bits_addr ^ 31'h10000000; // @[Parameters.scala 137:31]
  wire [31:0] _T_46 = {1'b0,$signed(_T_45)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_48 = $signed(_T_46) & 32'sh50000000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_3 = $signed(_T_48) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_50 = auto_in_aw_bits_addr ^ 31'h40002000; // @[Parameters.scala 137:31]
  wire [31:0] _T_51 = {1'b0,$signed(_T_50)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_53 = $signed(_T_51) & 32'sh50242000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_4 = $signed(_T_53) == 32'sh0; // @[Parameters.scala 137:67]
  wire [30:0] _T_55 = auto_in_aw_bits_addr ^ 31'h40040000; // @[Parameters.scala 137:31]
  wire [31:0] _T_56 = {1'b0,$signed(_T_55)}; // @[Parameters.scala 137:49]
  wire [31:0] _T_58 = $signed(_T_56) & 32'sh50240000; // @[Parameters.scala 137:52]
  wire  requestAWIO_0_5 = $signed(_T_58) == 32'sh0; // @[Parameters.scala 137:67]
  wire [2:0] lo = {requestAWIO_0_2,requestAWIO_0_1,requestAWIO_0_0}; // @[Xbar.scala 71:75]
  wire [2:0] hi = {requestAWIO_0_5,requestAWIO_0_4,requestAWIO_0_3}; // @[Xbar.scala 71:75]
  wire  requestWIO_0_0 = awIn_0_io_deq_bits[0]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_1 = awIn_0_io_deq_bits[1]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_2 = awIn_0_io_deq_bits[2]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_3 = awIn_0_io_deq_bits[3]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_4 = awIn_0_io_deq_bits[4]; // @[Xbar.scala 72:73]
  wire  requestWIO_0_5 = awIn_0_io_deq_bits[5]; // @[Xbar.scala 72:73]
  reg  REG_41; // @[Xbar.scala 249:23]
  wire [5:0] lo_12 = {auto_out_5_r_valid,auto_out_4_r_valid,auto_out_3_r_valid,auto_out_2_r_valid,auto_out_1_r_valid,
    auto_out_0_r_valid}; // @[Cat.scala 30:58]
  reg [5:0] REG_42; // @[Arbiter.scala 23:23]
  wire [5:0] _T_678 = ~REG_42; // @[Arbiter.scala 24:30]
  wire [5:0] hi_12 = lo_12 & _T_678; // @[Arbiter.scala 24:28]
  wire [11:0] _T_679 = {hi_12,auto_out_5_r_valid,auto_out_4_r_valid,auto_out_3_r_valid,auto_out_2_r_valid,
    auto_out_1_r_valid,auto_out_0_r_valid}; // @[Cat.scala 30:58]
  wire [11:0] _GEN_48 = {{1'd0}, _T_679[11:1]}; // @[package.scala 253:43]
  wire [11:0] _T_681 = _T_679 | _GEN_48; // @[package.scala 253:43]
  wire [11:0] _GEN_49 = {{2'd0}, _T_681[11:2]}; // @[package.scala 253:43]
  wire [11:0] _T_683 = _T_681 | _GEN_49; // @[package.scala 253:43]
  wire [11:0] _GEN_50 = {{4'd0}, _T_683[11:4]}; // @[package.scala 253:43]
  wire [11:0] _T_685 = _T_683 | _GEN_50; // @[package.scala 253:43]
  wire [11:0] _T_688 = {REG_42, 6'h0}; // @[Arbiter.scala 25:66]
  wire [11:0] _GEN_51 = {{1'd0}, _T_685[11:1]}; // @[Arbiter.scala 25:58]
  wire [11:0] _T_689 = _GEN_51 | _T_688; // @[Arbiter.scala 25:58]
  wire [5:0] _T_692 = _T_689[11:6] & _T_689[5:0]; // @[Arbiter.scala 26:39]
  wire [5:0] _T_693 = ~_T_692; // @[Arbiter.scala 26:18]
  wire  _T_714 = _T_693[0] & auto_out_0_r_valid; // @[Xbar.scala 257:63]
  reg  REG_43_0; // @[Xbar.scala 268:24]
  wire  _T_762_0 = REG_41 ? _T_714 : REG_43_0; // @[Xbar.scala 269:23]
  wire [1:0] _T_816 = _T_762_0 ? auto_out_0_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire  _T_715 = _T_693[1] & auto_out_1_r_valid; // @[Xbar.scala 257:63]
  reg  REG_43_1; // @[Xbar.scala 268:24]
  wire  _T_762_1 = REG_41 ? _T_715 : REG_43_1; // @[Xbar.scala 269:23]
  wire [1:0] _T_817 = _T_762_1 ? auto_out_1_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_822 = _T_816 | _T_817; // @[Mux.scala 27:72]
  wire  _T_716 = _T_693[2] & auto_out_2_r_valid; // @[Xbar.scala 257:63]
  reg  REG_43_2; // @[Xbar.scala 268:24]
  wire  _T_762_2 = REG_41 ? _T_716 : REG_43_2; // @[Xbar.scala 269:23]
  wire [1:0] _T_818 = _T_762_2 ? auto_out_2_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_823 = _T_822 | _T_818; // @[Mux.scala 27:72]
  wire  _T_717 = _T_693[3] & auto_out_3_r_valid; // @[Xbar.scala 257:63]
  reg  REG_43_3; // @[Xbar.scala 268:24]
  wire  _T_762_3 = REG_41 ? _T_717 : REG_43_3; // @[Xbar.scala 269:23]
  wire [1:0] _T_819 = _T_762_3 ? auto_out_3_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_824 = _T_823 | _T_819; // @[Mux.scala 27:72]
  wire  _T_718 = _T_693[4] & auto_out_4_r_valid; // @[Xbar.scala 257:63]
  reg  REG_43_4; // @[Xbar.scala 268:24]
  wire  _T_762_4 = REG_41 ? _T_718 : REG_43_4; // @[Xbar.scala 269:23]
  wire [1:0] _T_820 = _T_762_4 ? auto_out_4_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_825 = _T_824 | _T_820; // @[Mux.scala 27:72]
  wire  _T_719 = _T_693[5] & auto_out_5_r_valid; // @[Xbar.scala 257:63]
  reg  REG_43_5; // @[Xbar.scala 268:24]
  wire  _T_762_5 = REG_41 ? _T_719 : REG_43_5; // @[Xbar.scala 269:23]
  wire [1:0] _T_821 = _T_762_5 ? auto_out_5_r_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] in_0_r_bits_id = _T_825 | _T_821; // @[Mux.scala 27:72]
  reg  REG_44; // @[Xbar.scala 249:23]
  wire [5:0] lo_14 = {auto_out_5_b_valid,auto_out_4_b_valid,auto_out_3_b_valid,auto_out_2_b_valid,auto_out_1_b_valid,
    auto_out_0_b_valid}; // @[Cat.scala 30:58]
  reg [5:0] REG_45; // @[Arbiter.scala 23:23]
  wire [5:0] _T_837 = ~REG_45; // @[Arbiter.scala 24:30]
  wire [5:0] hi_14 = lo_14 & _T_837; // @[Arbiter.scala 24:28]
  wire [11:0] _T_838 = {hi_14,auto_out_5_b_valid,auto_out_4_b_valid,auto_out_3_b_valid,auto_out_2_b_valid,
    auto_out_1_b_valid,auto_out_0_b_valid}; // @[Cat.scala 30:58]
  wire [11:0] _GEN_52 = {{1'd0}, _T_838[11:1]}; // @[package.scala 253:43]
  wire [11:0] _T_840 = _T_838 | _GEN_52; // @[package.scala 253:43]
  wire [11:0] _GEN_53 = {{2'd0}, _T_840[11:2]}; // @[package.scala 253:43]
  wire [11:0] _T_842 = _T_840 | _GEN_53; // @[package.scala 253:43]
  wire [11:0] _GEN_54 = {{4'd0}, _T_842[11:4]}; // @[package.scala 253:43]
  wire [11:0] _T_844 = _T_842 | _GEN_54; // @[package.scala 253:43]
  wire [11:0] _T_847 = {REG_45, 6'h0}; // @[Arbiter.scala 25:66]
  wire [11:0] _GEN_55 = {{1'd0}, _T_844[11:1]}; // @[Arbiter.scala 25:58]
  wire [11:0] _T_848 = _GEN_55 | _T_847; // @[Arbiter.scala 25:58]
  wire [5:0] _T_851 = _T_848[11:6] & _T_848[5:0]; // @[Arbiter.scala 26:39]
  wire [5:0] _T_852 = ~_T_851; // @[Arbiter.scala 26:18]
  wire  _T_873 = _T_852[0] & auto_out_0_b_valid; // @[Xbar.scala 257:63]
  reg  REG_46_0; // @[Xbar.scala 268:24]
  wire  _T_921_0 = REG_44 ? _T_873 : REG_46_0; // @[Xbar.scala 269:23]
  wire [1:0] _T_953 = _T_921_0 ? auto_out_0_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire  _T_874 = _T_852[1] & auto_out_1_b_valid; // @[Xbar.scala 257:63]
  reg  REG_46_1; // @[Xbar.scala 268:24]
  wire  _T_921_1 = REG_44 ? _T_874 : REG_46_1; // @[Xbar.scala 269:23]
  wire [1:0] _T_954 = _T_921_1 ? auto_out_1_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_959 = _T_953 | _T_954; // @[Mux.scala 27:72]
  wire  _T_875 = _T_852[2] & auto_out_2_b_valid; // @[Xbar.scala 257:63]
  reg  REG_46_2; // @[Xbar.scala 268:24]
  wire  _T_921_2 = REG_44 ? _T_875 : REG_46_2; // @[Xbar.scala 269:23]
  wire [1:0] _T_955 = _T_921_2 ? auto_out_2_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_960 = _T_959 | _T_955; // @[Mux.scala 27:72]
  wire  _T_876 = _T_852[3] & auto_out_3_b_valid; // @[Xbar.scala 257:63]
  reg  REG_46_3; // @[Xbar.scala 268:24]
  wire  _T_921_3 = REG_44 ? _T_876 : REG_46_3; // @[Xbar.scala 269:23]
  wire [1:0] _T_956 = _T_921_3 ? auto_out_3_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_961 = _T_960 | _T_956; // @[Mux.scala 27:72]
  wire  _T_877 = _T_852[4] & auto_out_4_b_valid; // @[Xbar.scala 257:63]
  reg  REG_46_4; // @[Xbar.scala 268:24]
  wire  _T_921_4 = REG_44 ? _T_877 : REG_46_4; // @[Xbar.scala 269:23]
  wire [1:0] _T_957 = _T_921_4 ? auto_out_4_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_962 = _T_961 | _T_957; // @[Mux.scala 27:72]
  wire  _T_878 = _T_852[5] & auto_out_5_b_valid; // @[Xbar.scala 257:63]
  reg  REG_46_5; // @[Xbar.scala 268:24]
  wire  _T_921_5 = REG_44 ? _T_878 : REG_46_5; // @[Xbar.scala 269:23]
  wire [1:0] _T_958 = _T_921_5 ? auto_out_5_b_bits_id : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] in_0_b_bits_id = _T_962 | _T_958; // @[Mux.scala 27:72]
  wire [3:0] _T_149 = 4'h1 << auto_in_ar_bits_id; // @[OneHot.scala 65:12]
  wire [3:0] _T_151 = 4'h1 << auto_in_aw_bits_id; // @[OneHot.scala 65:12]
  wire [3:0] _T_153 = 4'h1 << in_0_r_bits_id; // @[OneHot.scala 65:12]
  wire [3:0] _T_155 = 4'h1 << in_0_b_bits_id; // @[OneHot.scala 65:12]
  wire  in_0_ar_ready = requestARIO_0_0 & auto_out_0_ar_ready | requestARIO_0_1 | requestARIO_0_2 & auto_out_2_ar_ready
     | requestARIO_0_3 & auto_out_3_ar_ready | requestARIO_0_4 & auto_out_4_ar_ready | requestARIO_0_5 &
    auto_out_5_ar_ready; // @[Mux.scala 27:72]
  reg  REG_12; // @[Xbar.scala 111:34]
  wire  _T_353 = ~REG_12; // @[Xbar.scala 119:22]
  reg  REG_8; // @[Xbar.scala 111:34]
  wire  _T_298 = ~REG_8; // @[Xbar.scala 119:22]
  reg  REG_4; // @[Xbar.scala 111:34]
  wire  _T_243 = ~REG_4; // @[Xbar.scala 119:22]
  reg  REG; // @[Xbar.scala 111:34]
  wire  _T_188 = ~REG; // @[Xbar.scala 119:22]
  wire  _T_166 = in_0_ar_ready & auto_in_ar_valid; // @[Decoupled.scala 40:37]
  wire  _T_167 = _T_149[0] & _T_166; // @[Xbar.scala 126:25]
  wire  _T_672 = auto_out_0_r_valid | auto_out_1_r_valid | auto_out_2_r_valid | auto_out_3_r_valid | auto_out_4_r_valid
     | auto_out_5_r_valid; // @[Xbar.scala 253:36]
  wire  _T_781 = REG_43_0 & auto_out_0_r_valid | REG_43_1 & auto_out_1_r_valid | REG_43_2 & auto_out_2_r_valid |
    REG_43_3 & auto_out_3_r_valid | REG_43_4 & auto_out_4_r_valid | REG_43_5 & auto_out_5_r_valid; // @[Mux.scala 27:72]
  wire  in_0_r_valid = REG_41 ? _T_672 : _T_781; // @[Xbar.scala 285:22]
  wire  _T_169 = auto_in_r_ready & in_0_r_valid; // @[Decoupled.scala 40:37]
  wire  in_0_r_bits_last = _T_762_0 & auto_out_0_r_bits_last | _T_762_1 & auto_out_1_r_bits_last | _T_762_2 &
    auto_out_2_r_bits_last | _T_762_3 & auto_out_3_r_bits_last | _T_762_4 & auto_out_4_r_bits_last | _T_762_5 &
    auto_out_5_r_bits_last; // @[Mux.scala 27:72]
  wire  _T_171 = _T_153[0] & _T_169 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_173 = REG + _T_167; // @[Xbar.scala 113:30]
  wire  in_0_aw_ready = requestAWIO_0_0 & auto_out_0_aw_ready | requestAWIO_0_1 & auto_out_1_aw_ready | requestAWIO_0_2
     & auto_out_2_aw_ready | requestAWIO_0_3 & auto_out_3_aw_ready | requestAWIO_0_4 & auto_out_4_aw_ready |
    requestAWIO_0_5 & auto_out_5_aw_ready; // @[Mux.scala 27:72]
  reg  REG_16; // @[Xbar.scala 144:30]
  wire  _T_390 = REG_16 | awIn_0_io_enq_ready; // @[Xbar.scala 146:57]
  wire  io_in_0_aw_ready = in_0_aw_ready & (REG_16 | awIn_0_io_enq_ready); // @[Xbar.scala 146:45]
  reg  REG_14; // @[Xbar.scala 111:34]
  wire  _T_380 = ~REG_14; // @[Xbar.scala 119:22]
  reg  REG_10; // @[Xbar.scala 111:34]
  wire  _T_325 = ~REG_10; // @[Xbar.scala 119:22]
  reg  REG_6; // @[Xbar.scala 111:34]
  wire  _T_270 = ~REG_6; // @[Xbar.scala 119:22]
  reg  REG_2; // @[Xbar.scala 111:34]
  wire  _T_215 = ~REG_2; // @[Xbar.scala 119:22]
  wire  _T_194 = io_in_0_aw_ready & auto_in_aw_valid; // @[Decoupled.scala 40:37]
  wire  _T_195 = _T_151[0] & _T_194; // @[Xbar.scala 130:25]
  wire  _T_831 = auto_out_0_b_valid | auto_out_1_b_valid | auto_out_2_b_valid | auto_out_3_b_valid | auto_out_4_b_valid
     | auto_out_5_b_valid; // @[Xbar.scala 253:36]
  wire  _T_940 = REG_46_0 & auto_out_0_b_valid | REG_46_1 & auto_out_1_b_valid | REG_46_2 & auto_out_2_b_valid |
    REG_46_3 & auto_out_3_b_valid | REG_46_4 & auto_out_4_b_valid | REG_46_5 & auto_out_5_b_valid; // @[Mux.scala 27:72]
  wire  in_0_b_valid = REG_44 ? _T_831 : _T_940; // @[Xbar.scala 285:22]
  wire  _T_197 = auto_in_b_ready & in_0_b_valid; // @[Decoupled.scala 40:37]
  wire  _T_198 = _T_155[0] & _T_197; // @[Xbar.scala 131:24]
  wire  _T_200 = REG_2 + _T_195; // @[Xbar.scala 113:30]
  wire  _T_222 = _T_149[1] & _T_166; // @[Xbar.scala 126:25]
  wire  _T_226 = _T_153[1] & _T_169 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_228 = REG_4 + _T_222; // @[Xbar.scala 113:30]
  wire  _T_250 = _T_151[1] & _T_194; // @[Xbar.scala 130:25]
  wire  _T_253 = _T_155[1] & _T_197; // @[Xbar.scala 131:24]
  wire  _T_255 = REG_6 + _T_250; // @[Xbar.scala 113:30]
  wire  _T_277 = _T_149[2] & _T_166; // @[Xbar.scala 126:25]
  wire  _T_281 = _T_153[2] & _T_169 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_283 = REG_8 + _T_277; // @[Xbar.scala 113:30]
  wire  _T_305 = _T_151[2] & _T_194; // @[Xbar.scala 130:25]
  wire  _T_308 = _T_155[2] & _T_197; // @[Xbar.scala 131:24]
  wire  _T_310 = REG_10 + _T_305; // @[Xbar.scala 113:30]
  wire  _T_332 = _T_149[3] & _T_166; // @[Xbar.scala 126:25]
  wire  _T_336 = _T_153[3] & _T_169 & in_0_r_bits_last; // @[Xbar.scala 127:45]
  wire  _T_338 = REG_12 + _T_332; // @[Xbar.scala 113:30]
  wire  _T_360 = _T_151[3] & _T_194; // @[Xbar.scala 130:25]
  wire  _T_363 = _T_155[3] & _T_197; // @[Xbar.scala 131:24]
  wire  _T_365 = REG_14 + _T_360; // @[Xbar.scala 113:30]
  wire  in_0_aw_valid = auto_in_aw_valid & _T_390; // @[Xbar.scala 145:45]
  wire  _T_395 = awIn_0_io_enq_ready & awIn_0_io_enq_valid; // @[Decoupled.scala 40:37]
  wire  _GEN_16 = _T_395 | REG_16; // @[Xbar.scala 148:38 Xbar.scala 148:48 Xbar.scala 144:30]
  wire  _T_396 = in_0_aw_ready & in_0_aw_valid; // @[Decoupled.scala 40:37]
  wire  in_0_w_valid = auto_in_w_valid & awIn_0_io_deq_valid; // @[Xbar.scala 152:43]
  wire  in_0_w_ready = requestWIO_0_0 & auto_out_0_w_ready | requestWIO_0_1 & auto_out_1_w_ready | requestWIO_0_2 &
    auto_out_2_w_ready | requestWIO_0_3 & auto_out_3_w_ready | requestWIO_0_4 & auto_out_4_w_ready | requestWIO_0_5 &
    auto_out_5_w_ready; // @[Mux.scala 27:72]
  wire  out_0_ar_valid = auto_in_ar_valid & requestARIO_0_0; // @[Xbar.scala 229:40]
  wire  out_1_ar_valid = auto_in_ar_valid & requestARIO_0_1; // @[Xbar.scala 229:40]
  wire  out_2_ar_valid = auto_in_ar_valid & requestARIO_0_2; // @[Xbar.scala 229:40]
  wire  out_3_ar_valid = auto_in_ar_valid & requestARIO_0_3; // @[Xbar.scala 229:40]
  wire  out_4_ar_valid = auto_in_ar_valid & requestARIO_0_4; // @[Xbar.scala 229:40]
  wire  out_5_ar_valid = auto_in_ar_valid & requestARIO_0_5; // @[Xbar.scala 229:40]
  wire  out_0_aw_valid = in_0_aw_valid & requestAWIO_0_0; // @[Xbar.scala 229:40]
  wire  out_1_aw_valid = in_0_aw_valid & requestAWIO_0_1; // @[Xbar.scala 229:40]
  wire  out_2_aw_valid = in_0_aw_valid & requestAWIO_0_2; // @[Xbar.scala 229:40]
  wire  out_3_aw_valid = in_0_aw_valid & requestAWIO_0_3; // @[Xbar.scala 229:40]
  wire  out_4_aw_valid = in_0_aw_valid & requestAWIO_0_4; // @[Xbar.scala 229:40]
  wire  out_5_aw_valid = in_0_aw_valid & requestAWIO_0_5; // @[Xbar.scala 229:40]
  wire  _T_467 = ~out_0_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_483 = ~out_0_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_501 = ~out_1_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_517 = ~out_1_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_535 = ~out_2_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_551 = ~out_2_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_569 = ~out_3_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_585 = ~out_3_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_603 = ~out_4_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_619 = ~out_4_ar_valid; // @[Xbar.scala 263:60]
  wire  _T_637 = ~out_5_aw_valid; // @[Xbar.scala 263:60]
  wire  _T_653 = ~out_5_ar_valid; // @[Xbar.scala 263:60]
  wire [5:0] _T_696 = _T_693 & lo_12; // @[Arbiter.scala 28:29]
  wire [6:0] _T_697 = {_T_696, 1'h0}; // @[package.scala 244:48]
  wire [5:0] _T_699 = _T_696 | _T_697[5:0]; // @[package.scala 244:43]
  wire [7:0] _T_700 = {_T_699, 2'h0}; // @[package.scala 244:48]
  wire [5:0] _T_702 = _T_699 | _T_700[5:0]; // @[package.scala 244:43]
  wire [9:0] _T_703 = {_T_702, 4'h0}; // @[package.scala 244:48]
  wire [5:0] _T_705 = _T_702 | _T_703[5:0]; // @[package.scala 244:43]
  wire  _T_721 = _T_714 | _T_715; // @[Xbar.scala 262:50]
  wire  _T_722 = _T_714 | _T_715 | _T_716; // @[Xbar.scala 262:50]
  wire  _T_723 = _T_714 | _T_715 | _T_716 | _T_717; // @[Xbar.scala 262:50]
  wire  _T_724 = _T_714 | _T_715 | _T_716 | _T_717 | _T_718; // @[Xbar.scala 262:50]
  wire  _T_725 = _T_714 | _T_715 | _T_716 | _T_717 | _T_718 | _T_719; // @[Xbar.scala 262:50]
  wire  _GEN_43 = _T_672 ? 1'h0 : REG_41; // @[Xbar.scala 273:21 Xbar.scala 273:28 Xbar.scala 249:23]
  wire  _GEN_44 = _T_169 | _GEN_43; // @[Xbar.scala 274:24 Xbar.scala 274:31]
  wire  _T_764_0 = REG_41 ? _T_693[0] : REG_43_0; // @[Xbar.scala 277:24]
  wire  _T_764_1 = REG_41 ? _T_693[1] : REG_43_1; // @[Xbar.scala 277:24]
  wire  _T_764_2 = REG_41 ? _T_693[2] : REG_43_2; // @[Xbar.scala 277:24]
  wire  _T_764_3 = REG_41 ? _T_693[3] : REG_43_3; // @[Xbar.scala 277:24]
  wire  _T_764_4 = REG_41 ? _T_693[4] : REG_43_4; // @[Xbar.scala 277:24]
  wire  _T_764_5 = REG_41 ? _T_693[5] : REG_43_5; // @[Xbar.scala 277:24]
  wire [1:0] _T_794 = _T_762_0 ? auto_out_0_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_796 = _T_762_2 ? auto_out_2_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_797 = _T_762_3 ? auto_out_3_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_798 = _T_762_4 ? auto_out_4_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_799 = _T_762_5 ? auto_out_5_r_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_801 = _T_794 | _T_796; // @[Mux.scala 27:72]
  wire [1:0] _T_802 = _T_801 | _T_797; // @[Mux.scala 27:72]
  wire [1:0] _T_803 = _T_802 | _T_798; // @[Mux.scala 27:72]
  wire [63:0] _T_805 = _T_762_0 ? auto_out_0_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_807 = _T_762_2 ? auto_out_2_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_808 = _T_762_3 ? auto_out_3_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_809 = _T_762_4 ? auto_out_4_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_810 = _T_762_5 ? auto_out_5_r_bits_data : 64'h0; // @[Mux.scala 27:72]
  wire [63:0] _T_812 = _T_805 | _T_807; // @[Mux.scala 27:72]
  wire [63:0] _T_813 = _T_812 | _T_808; // @[Mux.scala 27:72]
  wire [63:0] _T_814 = _T_813 | _T_809; // @[Mux.scala 27:72]
  wire [5:0] _T_855 = _T_852 & lo_14; // @[Arbiter.scala 28:29]
  wire [6:0] _T_856 = {_T_855, 1'h0}; // @[package.scala 244:48]
  wire [5:0] _T_858 = _T_855 | _T_856[5:0]; // @[package.scala 244:43]
  wire [7:0] _T_859 = {_T_858, 2'h0}; // @[package.scala 244:48]
  wire [5:0] _T_861 = _T_858 | _T_859[5:0]; // @[package.scala 244:43]
  wire [9:0] _T_862 = {_T_861, 4'h0}; // @[package.scala 244:48]
  wire [5:0] _T_864 = _T_861 | _T_862[5:0]; // @[package.scala 244:43]
  wire  _T_880 = _T_873 | _T_874; // @[Xbar.scala 262:50]
  wire  _T_881 = _T_873 | _T_874 | _T_875; // @[Xbar.scala 262:50]
  wire  _T_882 = _T_873 | _T_874 | _T_875 | _T_876; // @[Xbar.scala 262:50]
  wire  _T_883 = _T_873 | _T_874 | _T_875 | _T_876 | _T_877; // @[Xbar.scala 262:50]
  wire  _T_884 = _T_873 | _T_874 | _T_875 | _T_876 | _T_877 | _T_878; // @[Xbar.scala 262:50]
  wire  _GEN_46 = _T_831 ? 1'h0 : REG_44; // @[Xbar.scala 273:21 Xbar.scala 273:28 Xbar.scala 249:23]
  wire  _GEN_47 = _T_197 | _GEN_46; // @[Xbar.scala 274:24 Xbar.scala 274:31]
  wire  _T_923_0 = REG_44 ? _T_852[0] : REG_46_0; // @[Xbar.scala 277:24]
  wire  _T_923_1 = REG_44 ? _T_852[1] : REG_46_1; // @[Xbar.scala 277:24]
  wire  _T_923_2 = REG_44 ? _T_852[2] : REG_46_2; // @[Xbar.scala 277:24]
  wire  _T_923_3 = REG_44 ? _T_852[3] : REG_46_3; // @[Xbar.scala 277:24]
  wire  _T_923_4 = REG_44 ? _T_852[4] : REG_46_4; // @[Xbar.scala 277:24]
  wire  _T_923_5 = REG_44 ? _T_852[5] : REG_46_5; // @[Xbar.scala 277:24]
  wire [1:0] _T_942 = _T_921_0 ? auto_out_0_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_943 = _T_921_1 ? auto_out_1_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_944 = _T_921_2 ? auto_out_2_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_945 = _T_921_3 ? auto_out_3_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_946 = _T_921_4 ? auto_out_4_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_947 = _T_921_5 ? auto_out_5_b_bits_resp : 2'h0; // @[Mux.scala 27:72]
  wire [1:0] _T_948 = _T_942 | _T_943; // @[Mux.scala 27:72]
  wire [1:0] _T_949 = _T_948 | _T_944; // @[Mux.scala 27:72]
  wire [1:0] _T_950 = _T_949 | _T_945; // @[Mux.scala 27:72]
  wire [1:0] _T_951 = _T_950 | _T_946; // @[Mux.scala 27:72]
  QueueCompatibility_228 awIn_0 ( // @[Xbar.scala 62:47]
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
  assign auto_in_b_valid = REG_44 ? _T_831 : _T_940; // @[Xbar.scala 285:22]
  assign auto_in_b_bits_id = _T_962 | _T_958; // @[Mux.scala 27:72]
  assign auto_in_b_bits_resp = _T_951 | _T_947; // @[Mux.scala 27:72]
  assign auto_in_ar_ready = requestARIO_0_0 & auto_out_0_ar_ready | requestARIO_0_1 | requestARIO_0_2 &
    auto_out_2_ar_ready | requestARIO_0_3 & auto_out_3_ar_ready | requestARIO_0_4 & auto_out_4_ar_ready |
    requestARIO_0_5 & auto_out_5_ar_ready; // @[Mux.scala 27:72]
  assign auto_in_r_valid = REG_41 ? _T_672 : _T_781; // @[Xbar.scala 285:22]
  assign auto_in_r_bits_id = _T_825 | _T_821; // @[Mux.scala 27:72]
  assign auto_in_r_bits_data = _T_814 | _T_810; // @[Mux.scala 27:72]
  assign auto_in_r_bits_resp = _T_803 | _T_799; // @[Mux.scala 27:72]
  assign auto_in_r_bits_last = _T_762_0 & auto_out_0_r_bits_last | _T_762_1 & auto_out_1_r_bits_last | _T_762_2 &
    auto_out_2_r_bits_last | _T_762_3 & auto_out_3_r_bits_last | _T_762_4 & auto_out_4_r_bits_last | _T_762_5 &
    auto_out_5_r_bits_last; // @[Mux.scala 27:72]
  assign auto_out_5_aw_valid = in_0_aw_valid & requestAWIO_0_5; // @[Xbar.scala 229:40]
  assign auto_out_5_aw_bits_id = auto_in_aw_bits_id; // @[Xbar.scala 86:47]
  assign auto_out_5_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_w_valid = in_0_w_valid & requestWIO_0_5; // @[Xbar.scala 229:40]
  assign auto_out_5_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_b_ready = auto_in_b_ready & _T_923_5; // @[Xbar.scala 279:31]
  assign auto_out_5_ar_valid = auto_in_ar_valid & requestARIO_0_5; // @[Xbar.scala 229:40]
  assign auto_out_5_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_5_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_5_r_ready = auto_in_r_ready & _T_764_5; // @[Xbar.scala 279:31]
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
  assign auto_out_4_b_ready = auto_in_b_ready & _T_923_4; // @[Xbar.scala 279:31]
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
  assign auto_out_4_r_ready = auto_in_r_ready & _T_764_4; // @[Xbar.scala 279:31]
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
  assign auto_out_3_b_ready = auto_in_b_ready & _T_923_3; // @[Xbar.scala 279:31]
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
  assign auto_out_3_r_ready = auto_in_r_ready & _T_764_3; // @[Xbar.scala 279:31]
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
  assign auto_out_2_b_ready = auto_in_b_ready & _T_923_2; // @[Xbar.scala 279:31]
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
  assign auto_out_2_r_ready = auto_in_r_ready & _T_764_2; // @[Xbar.scala 279:31]
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
  assign auto_out_1_b_ready = auto_in_b_ready & _T_923_1; // @[Xbar.scala 279:31]
  assign auto_out_1_ar_valid = auto_in_ar_valid & requestARIO_0_1; // @[Xbar.scala 229:40]
  assign auto_out_1_ar_bits_id = auto_in_ar_bits_id; // @[Xbar.scala 87:47]
  assign auto_out_1_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign auto_out_1_r_ready = auto_in_r_ready & _T_764_1; // @[Xbar.scala 279:31]
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
  assign auto_out_0_b_ready = auto_in_b_ready & _T_923_0; // @[Xbar.scala 279:31]
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
  assign auto_out_0_r_ready = auto_in_r_ready & _T_764_0; // @[Xbar.scala 279:31]
  assign awIn_0_clock = clock;
  assign awIn_0_reset = reset;
  assign awIn_0_io_enq_valid = auto_in_aw_valid & ~REG_16; // @[Xbar.scala 147:51]
  assign awIn_0_io_enq_bits = {hi,lo}; // @[Xbar.scala 71:75]
  assign awIn_0_io_deq_ready = auto_in_w_valid & auto_in_w_bits_last & in_0_w_ready; // @[Xbar.scala 154:74]
  always @(posedge clock) begin
    REG_41 <= reset | _GEN_44; // @[Xbar.scala 249:23 Xbar.scala 249:23]
    if (reset) begin // @[Arbiter.scala 23:23]
      REG_42 <= 6'h3f; // @[Arbiter.scala 23:23]
    end else if (REG_41 & |lo_12) begin // @[Arbiter.scala 27:32]
      REG_42 <= _T_705; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_43_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_41) begin // @[Xbar.scala 269:23]
      REG_43_0 <= _T_714;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_43_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_41) begin // @[Xbar.scala 269:23]
      REG_43_1 <= _T_715;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_43_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_41) begin // @[Xbar.scala 269:23]
      REG_43_2 <= _T_716;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_43_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_41) begin // @[Xbar.scala 269:23]
      REG_43_3 <= _T_717;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_43_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_41) begin // @[Xbar.scala 269:23]
      REG_43_4 <= _T_718;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_43_5 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_41) begin // @[Xbar.scala 269:23]
      REG_43_5 <= _T_719;
    end
    REG_44 <= reset | _GEN_47; // @[Xbar.scala 249:23 Xbar.scala 249:23]
    if (reset) begin // @[Arbiter.scala 23:23]
      REG_45 <= 6'h3f; // @[Arbiter.scala 23:23]
    end else if (REG_44 & |lo_14) begin // @[Arbiter.scala 27:32]
      REG_45 <= _T_864; // @[Arbiter.scala 28:12]
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_46_0 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_44) begin // @[Xbar.scala 269:23]
      REG_46_0 <= _T_873;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_46_1 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_44) begin // @[Xbar.scala 269:23]
      REG_46_1 <= _T_874;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_46_2 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_44) begin // @[Xbar.scala 269:23]
      REG_46_2 <= _T_875;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_46_3 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_44) begin // @[Xbar.scala 269:23]
      REG_46_3 <= _T_876;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_46_4 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_44) begin // @[Xbar.scala 269:23]
      REG_46_4 <= _T_877;
    end
    if (reset) begin // @[Xbar.scala 268:24]
      REG_46_5 <= 1'h0; // @[Xbar.scala 268:24]
    end else if (REG_44) begin // @[Xbar.scala 269:23]
      REG_46_5 <= _T_878;
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_12 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_12 <= _T_338 - _T_336; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_8 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_8 <= _T_283 - _T_281; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_4 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_4 <= _T_228 - _T_226; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG <= _T_173 - _T_171; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 144:30]
      REG_16 <= 1'h0; // @[Xbar.scala 144:30]
    end else if (_T_396) begin // @[Xbar.scala 149:32]
      REG_16 <= 1'h0; // @[Xbar.scala 149:42]
    end else begin
      REG_16 <= _GEN_16;
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_14 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_14 <= _T_365 - _T_363; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_10 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_10 <= _T_310 - _T_308; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_6 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_6 <= _T_255 - _T_253; // @[Xbar.scala 113:21]
    end
    if (reset) begin // @[Xbar.scala 111:34]
      REG_2 <= 1'h0; // @[Xbar.scala 111:34]
    end else begin
      REG_2 <= _T_200 - _T_198; // @[Xbar.scala 113:21]
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_171 | REG | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_167 | _T_188 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_198 | REG_2 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_195 | _T_215 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_226 | REG_4 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_222 | _T_243 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_253 | REG_6 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_250 | _T_270 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_281 | REG_8 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_277 | _T_298 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_308 | REG_10 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_305 | _T_325 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_336 | REG_12 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_332 | _T_353 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_363 | REG_14 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:114 assert (!resp_fire || count =/= UInt(0))\n"); // @[Xbar.scala 114:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_360 | _T_380 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:115 assert (!req_fire  || count =/= UInt(flight))\n"
            ); // @[Xbar.scala 115:22]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_467 | out_0_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_483 | out_0_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_501 | out_1_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_517 | out_1_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_535 | out_2_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_551 | out_2_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_569 | out_3_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_585 | out_3_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_603 | out_4_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_619 | out_4_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_637 | out_5_aw_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(_T_653 | out_5_ar_valid | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~((~_T_714 | ~_T_715) & (~_T_721 | ~_T_716) & (~_T_722 | ~_T_717) & (~_T_723 | ~_T_718) & (~_T_724 | ~_T_719
          ) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Xbar.scala:263 assert((prefixOR zip winner) map { case (p,w) => !p || !w } reduce {_ && _})\n"
            ); // @[Xbar.scala 263:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_672 | _T_725 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~((~_T_873 | ~_T_874) & (~_T_880 | ~_T_875) & (~_T_881 | ~_T_876) & (~_T_882 | ~_T_877) & (~_T_883 | ~_T_878
          ) | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed\n    at Xbar.scala:263 assert((prefixOR zip winner) map { case (p,w) => !p || !w } reduce {_ && _})\n"
            ); // @[Xbar.scala 263:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_831 | _T_884 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at Xbar.scala:265 assert (!anyValid || winner.reduce(_||_))\n"); // @[Xbar.scala 265:12]
        end
    `ifdef PRINTF_COND
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
  REG_41 = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  REG_42 = _RAND_1[5:0];
  _RAND_2 = {1{`RANDOM}};
  REG_43_0 = _RAND_2[0:0];
  _RAND_3 = {1{`RANDOM}};
  REG_43_1 = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  REG_43_2 = _RAND_4[0:0];
  _RAND_5 = {1{`RANDOM}};
  REG_43_3 = _RAND_5[0:0];
  _RAND_6 = {1{`RANDOM}};
  REG_43_4 = _RAND_6[0:0];
  _RAND_7 = {1{`RANDOM}};
  REG_43_5 = _RAND_7[0:0];
  _RAND_8 = {1{`RANDOM}};
  REG_44 = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  REG_45 = _RAND_9[5:0];
  _RAND_10 = {1{`RANDOM}};
  REG_46_0 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  REG_46_1 = _RAND_11[0:0];
  _RAND_12 = {1{`RANDOM}};
  REG_46_2 = _RAND_12[0:0];
  _RAND_13 = {1{`RANDOM}};
  REG_46_3 = _RAND_13[0:0];
  _RAND_14 = {1{`RANDOM}};
  REG_46_4 = _RAND_14[0:0];
  _RAND_15 = {1{`RANDOM}};
  REG_46_5 = _RAND_15[0:0];
  _RAND_16 = {1{`RANDOM}};
  REG_12 = _RAND_16[0:0];
  _RAND_17 = {1{`RANDOM}};
  REG_8 = _RAND_17[0:0];
  _RAND_18 = {1{`RANDOM}};
  REG_4 = _RAND_18[0:0];
  _RAND_19 = {1{`RANDOM}};
  REG = _RAND_19[0:0];
  _RAND_20 = {1{`RANDOM}};
  REG_16 = _RAND_20[0:0];
  _RAND_21 = {1{`RANDOM}};
  REG_14 = _RAND_21[0:0];
  _RAND_22 = {1{`RANDOM}};
  REG_10 = _RAND_22[0:0];
  _RAND_23 = {1{`RANDOM}};
  REG_6 = _RAND_23[0:0];
  _RAND_24 = {1{`RANDOM}};
  REG_2 = _RAND_24[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule

