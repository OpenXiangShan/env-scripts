module AXI4RAM_1(
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
  input         auto_in_ar_valid,
  input         auto_in_ar_bits_id,
  input  [30:0] auto_in_ar_bits_addr,
  input  [7:0]  auto_in_ar_bits_len,
  input  [2:0]  auto_in_ar_bits_size,
  input  [1:0]  auto_in_ar_bits_burst,
  input         auto_in_ar_bits_lock,
  input  [3:0]  auto_in_ar_bits_cache,
  input  [3:0]  auto_in_ar_bits_qos,
  output        auto_in_r_bits_id,
  output        auto_in_r_bits_last
);
`ifdef RANDOMIZE_GARBAGE_ASSIGN
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_13;
  reg [31:0] _RAND_15;
`endif // RANDOMIZE_GARBAGE_ASSIGN
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_12;
  reg [31:0] _RAND_14;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_16;
  reg [31:0] _RAND_17;
  reg [31:0] _RAND_18;
  reg [31:0] _RAND_19;
  reg [31:0] _RAND_20;
  reg [31:0] _RAND_21;
  reg [31:0] _RAND_22;
  reg [31:0] _RAND_23;
`endif // RANDOMIZE_REG_INIT
  reg [7:0] MEM_0 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_0_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_0_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_0_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_0_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_0_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_0_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_1 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_1_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_1_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_1_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_1_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_1_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_1_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_2 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_2_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_2_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_2_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_2_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_2_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_2_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_3 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_3_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_3_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_3_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_3_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_3_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_3_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_4 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_4_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_4_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_4_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_4_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_4_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_4_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_5 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_5_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_5_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_5_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_5_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_5_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_5_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_6 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_6_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_6_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_6_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_6_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_6_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_6_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [7:0] MEM_7 [0:59999]; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_7_MPORT_1_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_7_MPORT_1_addr; // @[AXI4RAM.scala 67:20]
  wire [7:0] MEM_7_MPORT_data; // @[AXI4RAM.scala 67:20]
  wire [15:0] MEM_7_MPORT_addr; // @[AXI4RAM.scala 67:20]
  wire  MEM_7_MPORT_mask; // @[AXI4RAM.scala 67:20]
  wire  MEM_7_MPORT_en; // @[AXI4RAM.scala 67:20]
  reg [1:0] state; // @[AXI4SlaveModule.scala 80:22]
  wire  _T_61 = state == 2'h0; // @[AXI4SlaveModule.scala 138:24]
  wire  in_ar_ready = state == 2'h0; // @[AXI4SlaveModule.scala 138:24]
  wire  in_ar_valid = auto_in_ar_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T = in_ar_ready & in_ar_valid; // @[Decoupled.scala 40:37]
  wire  in_aw_ready = _T_61 & ~in_ar_valid; // @[AXI4SlaveModule.scala 156:35]
  wire  in_aw_valid = auto_in_aw_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_1 = in_aw_ready & in_aw_valid; // @[Decoupled.scala 40:37]
  wire  in_w_ready = state == 2'h2; // @[AXI4SlaveModule.scala 157:23]
  wire  in_w_valid = auto_in_w_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_2 = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  wire  in_b_ready = auto_in_b_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_b_valid = state == 2'h3; // @[AXI4SlaveModule.scala 160:22]
  wire  _T_3 = in_b_ready & in_b_valid; // @[Decoupled.scala 40:37]
  wire  in_r_ready = 1'h1; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_r_valid = state == 2'h1; // @[AXI4SlaveModule.scala 140:23]
  wire  _T_4 = in_r_ready & in_r_valid; // @[Decoupled.scala 40:37]
  wire [1:0] in_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] in_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_15 = 2'h0 == state; // @[Conditional.scala 37:30]
  wire  _T_18 = 2'h1 == state; // @[Conditional.scala 37:30]
  reg [7:0] value; // @[Counter.scala 60:40]
  wire [7:0] in_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [7:0] r; // @[Reg.scala 27:20]
  wire [7:0] _T_43 = _T ? in_ar_bits_len : r; // @[Hold.scala 7:48]
  wire  in_r_bits_last = value == _T_43; // @[AXI4SlaveModule.scala 118:32]
  wire  _T_21 = 2'h2 == state; // @[Conditional.scala 37:30]
  wire  in_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] _GEN_3 = _T_2 & in_w_bits_last ? 2'h3 : state; // @[AXI4SlaveModule.scala 97:42 AXI4SlaveModule.scala 98:15 AXI4SlaveModule.scala 80:22]
  wire  _T_24 = 2'h3 == state; // @[Conditional.scala 37:30]
  wire [1:0] _GEN_4 = _T_3 ? 2'h0 : state; // @[AXI4SlaveModule.scala 102:24 AXI4SlaveModule.scala 103:15 AXI4SlaveModule.scala 80:22]
  wire [1:0] _GEN_5 = _T_24 ? _GEN_4 : state; // @[Conditional.scala 39:67 AXI4SlaveModule.scala 80:22]
  wire [7:0] in_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [30:0] r_1; // @[Reg.scala 27:20]
  wire [30:0] in_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [30:0] _GEN_10 = _T ? in_ar_bits_addr : r_1; // @[Reg.scala 28:19 Reg.scala 28:23 Reg.scala 27:20]
  wire [7:0] _value_T_1 = value + 8'h1; // @[Counter.scala 76:24]
  wire  _T_50 = in_ar_bits_len == 8'h1; // @[AXI4SlaveModule.scala 129:26]
  wire  _T_51 = in_ar_bits_len == 8'h0 | _T_50; // @[AXI4SlaveModule.scala 128:32]
  wire  _T_52 = in_ar_bits_len == 8'h3; // @[AXI4SlaveModule.scala 130:26]
  wire  _T_53 = _T_51 | _T_52; // @[AXI4SlaveModule.scala 129:34]
  wire  _T_54 = in_ar_bits_len == 8'h7; // @[AXI4SlaveModule.scala 131:26]
  wire  _T_55 = _T_53 | _T_54; // @[AXI4SlaveModule.scala 130:34]
  wire  _T_56 = in_ar_bits_len == 8'hf; // @[AXI4SlaveModule.scala 132:26]
  wire  _T_57 = _T_55 | _T_56; // @[AXI4SlaveModule.scala 131:34]
  reg [7:0] value_1; // @[Counter.scala 60:40]
  reg [30:0] r_2; // @[Reg.scala 27:20]
  wire [30:0] in_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [30:0] _GEN_13 = _T_1 ? in_aw_bits_addr : r_2; // @[Reg.scala 28:19 Reg.scala 28:23 Reg.scala 27:20]
  wire [7:0] _value_T_3 = value_1 + 8'h1; // @[Counter.scala 76:24]
  reg  r_3; // @[Reg.scala 15:16]
  wire  in_aw_bits_id = auto_in_aw_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg  r_5; // @[Reg.scala 15:16]
  wire  in_ar_bits_id = auto_in_ar_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [30:0] _T_76 = _GEN_13 - 31'h50000000; // @[AXI4RAM.scala 44:36]
  wire [15:0] _GEN_53 = {{8'd0}, value_1}; // @[AXI4RAM.scala 48:29]
  wire [15:0] wIdx = _T_76[18:3] + _GEN_53; // @[AXI4RAM.scala 48:29]
  wire [30:0] _T_81 = _GEN_10 - 31'h50000000; // @[AXI4RAM.scala 44:36]
  wire [15:0] _GEN_54 = {{8'd0}, value}; // @[AXI4RAM.scala 49:29]
  wire  _T_86 = wIdx < 16'hea60; // @[AXI4RAM.scala 46:34]
  wire [63:0] in_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [63:0] rdata = {MEM_7_MPORT_1_data,MEM_6_MPORT_1_data,MEM_5_MPORT_1_data,MEM_4_MPORT_1_data,MEM_3_MPORT_1_data,
    MEM_2_MPORT_1_data,MEM_1_MPORT_1_data,MEM_0_MPORT_1_data}; // @[Cat.scala 30:58]
  wire [7:0] in_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_b_bits_id = r_3; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 162:16]
  wire [1:0] in_b_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 159:18]
  wire [2:0] in_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_ar_bits_prot = 3'h0; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_r_bits_id = r_5; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 164:16]
  wire [63:0] in_r_bits_data = rdata; // @[Cat.scala 30:58]
  wire [1:0] in_r_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 139:18]
  assign MEM_0_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_0_MPORT_1_data = MEM_0[MEM_0_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_0_MPORT_1_data = MEM_0_MPORT_1_addr >= 16'hea60 ? _RAND_1[7:0] : MEM_0[MEM_0_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_0_MPORT_data = in_w_bits_data[7:0];
  assign MEM_0_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_0_MPORT_mask = in_w_bits_strb[0];
  assign MEM_0_MPORT_en = _T_2 & _T_86;
  assign MEM_1_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_1_MPORT_1_data = MEM_1[MEM_1_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_1_MPORT_1_data = MEM_1_MPORT_1_addr >= 16'hea60 ? _RAND_3[7:0] : MEM_1[MEM_1_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_1_MPORT_data = in_w_bits_data[15:8];
  assign MEM_1_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_1_MPORT_mask = in_w_bits_strb[1];
  assign MEM_1_MPORT_en = _T_2 & _T_86;
  assign MEM_2_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_2_MPORT_1_data = MEM_2[MEM_2_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_2_MPORT_1_data = MEM_2_MPORT_1_addr >= 16'hea60 ? _RAND_5[7:0] : MEM_2[MEM_2_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_2_MPORT_data = in_w_bits_data[23:16];
  assign MEM_2_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_2_MPORT_mask = in_w_bits_strb[2];
  assign MEM_2_MPORT_en = _T_2 & _T_86;
  assign MEM_3_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_3_MPORT_1_data = MEM_3[MEM_3_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_3_MPORT_1_data = MEM_3_MPORT_1_addr >= 16'hea60 ? _RAND_7[7:0] : MEM_3[MEM_3_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_3_MPORT_data = in_w_bits_data[31:24];
  assign MEM_3_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_3_MPORT_mask = in_w_bits_strb[3];
  assign MEM_3_MPORT_en = _T_2 & _T_86;
  assign MEM_4_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_4_MPORT_1_data = MEM_4[MEM_4_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_4_MPORT_1_data = MEM_4_MPORT_1_addr >= 16'hea60 ? _RAND_9[7:0] : MEM_4[MEM_4_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_4_MPORT_data = in_w_bits_data[39:32];
  assign MEM_4_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_4_MPORT_mask = in_w_bits_strb[4];
  assign MEM_4_MPORT_en = _T_2 & _T_86;
  assign MEM_5_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_5_MPORT_1_data = MEM_5[MEM_5_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_5_MPORT_1_data = MEM_5_MPORT_1_addr >= 16'hea60 ? _RAND_11[7:0] : MEM_5[MEM_5_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_5_MPORT_data = in_w_bits_data[47:40];
  assign MEM_5_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_5_MPORT_mask = in_w_bits_strb[5];
  assign MEM_5_MPORT_en = _T_2 & _T_86;
  assign MEM_6_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_6_MPORT_1_data = MEM_6[MEM_6_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_6_MPORT_1_data = MEM_6_MPORT_1_addr >= 16'hea60 ? _RAND_13[7:0] : MEM_6[MEM_6_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_6_MPORT_data = in_w_bits_data[55:48];
  assign MEM_6_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_6_MPORT_mask = in_w_bits_strb[6];
  assign MEM_6_MPORT_en = _T_2 & _T_86;
  assign MEM_7_MPORT_1_addr = _T_81[18:3] + _GEN_54;
  `ifndef RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_7_MPORT_1_data = MEM_7[MEM_7_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `else
  assign MEM_7_MPORT_1_data = MEM_7_MPORT_1_addr >= 16'hea60 ? _RAND_15[7:0] : MEM_7[MEM_7_MPORT_1_addr]; // @[AXI4RAM.scala 67:20]
  `endif // RANDOMIZE_GARBAGE_ASSIGN
  assign MEM_7_MPORT_data = in_w_bits_data[63:56];
  assign MEM_7_MPORT_addr = _T_76[18:3] + _GEN_53;
  assign MEM_7_MPORT_mask = in_w_bits_strb[7];
  assign MEM_7_MPORT_en = _T_2 & _T_86;
  assign auto_in_aw_ready = in_aw_ready; // @[LazyModule.scala 309:16]
  assign auto_in_w_ready = in_w_ready; // @[LazyModule.scala 309:16]
  assign auto_in_b_valid = in_b_valid; // @[LazyModule.scala 309:16]
  assign auto_in_b_bits_id = in_b_bits_id; // @[LazyModule.scala 309:16]
  assign auto_in_b_bits_resp = in_b_bits_resp; // @[LazyModule.scala 309:16]
  assign auto_in_r_bits_id = in_r_bits_id; // @[LazyModule.scala 309:16]
  assign auto_in_r_bits_last = in_r_bits_last; // @[LazyModule.scala 309:16]
  always @(posedge clock) begin
    if(MEM_0_MPORT_en & MEM_0_MPORT_mask) begin
      MEM_0[MEM_0_MPORT_addr] <= MEM_0_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_1_MPORT_en & MEM_1_MPORT_mask) begin
      MEM_1[MEM_1_MPORT_addr] <= MEM_1_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_2_MPORT_en & MEM_2_MPORT_mask) begin
      MEM_2[MEM_2_MPORT_addr] <= MEM_2_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_3_MPORT_en & MEM_3_MPORT_mask) begin
      MEM_3[MEM_3_MPORT_addr] <= MEM_3_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_4_MPORT_en & MEM_4_MPORT_mask) begin
      MEM_4[MEM_4_MPORT_addr] <= MEM_4_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_5_MPORT_en & MEM_5_MPORT_mask) begin
      MEM_5[MEM_5_MPORT_addr] <= MEM_5_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_6_MPORT_en & MEM_6_MPORT_mask) begin
      MEM_6[MEM_6_MPORT_addr] <= MEM_6_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if(MEM_7_MPORT_en & MEM_7_MPORT_mask) begin
      MEM_7[MEM_7_MPORT_addr] <= MEM_7_MPORT_data; // @[AXI4RAM.scala 67:20]
    end
    if (reset) begin // @[AXI4SlaveModule.scala 80:22]
      state <= 2'h0; // @[AXI4SlaveModule.scala 80:22]
    end else if (_T_15) begin // @[Conditional.scala 40:58]
      if (_T_1) begin // @[AXI4SlaveModule.scala 87:25]
        state <= 2'h2; // @[AXI4SlaveModule.scala 88:15]
      end else if (_T) begin // @[AXI4SlaveModule.scala 84:25]
        state <= 2'h1; // @[AXI4SlaveModule.scala 85:15]
      end
    end else if (_T_18) begin // @[Conditional.scala 39:67]
      if (_T_4 & in_r_bits_last) begin // @[AXI4SlaveModule.scala 92:42]
        state <= 2'h0; // @[AXI4SlaveModule.scala 93:15]
      end
    end else if (_T_21) begin // @[Conditional.scala 39:67]
      state <= _GEN_3;
    end else begin
      state <= _GEN_5;
    end
    if (reset) begin // @[Counter.scala 60:40]
      value <= 8'h0; // @[Counter.scala 60:40]
    end else if (_T_4) begin // @[AXI4SlaveModule.scala 120:23]
      if (in_r_bits_last) begin // @[AXI4SlaveModule.scala 122:28]
        value <= 8'h0; // @[AXI4SlaveModule.scala 123:17]
      end else begin
        value <= _value_T_1; // @[Counter.scala 76:15]
      end
    end
    if (reset) begin // @[Reg.scala 27:20]
      r <= 8'h0; // @[Reg.scala 27:20]
    end else if (_T) begin // @[Hold.scala 7:48]
      r <= in_ar_bits_len;
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_1 <= 31'h0; // @[Reg.scala 27:20]
    end else if (_T) begin // @[Reg.scala 28:19]
      r_1 <= in_ar_bits_addr; // @[Reg.scala 28:23]
    end
    if (reset) begin // @[Counter.scala 60:40]
      value_1 <= 8'h0; // @[Counter.scala 60:40]
    end else if (_T_2) begin // @[AXI4SlaveModule.scala 147:23]
      if (in_w_bits_last) begin // @[AXI4SlaveModule.scala 149:28]
        value_1 <= 8'h0; // @[AXI4SlaveModule.scala 150:17]
      end else begin
        value_1 <= _value_T_3; // @[Counter.scala 76:15]
      end
    end
    if (reset) begin // @[Reg.scala 27:20]
      r_2 <= 31'h0; // @[Reg.scala 27:20]
    end else if (_T_1) begin // @[Reg.scala 28:19]
      r_2 <= in_aw_bits_addr; // @[Reg.scala 28:23]
    end
    if (_T_1) begin // @[Reg.scala 16:19]
      r_3 <= in_aw_bits_id; // @[Reg.scala 16:23]
    end
    if (_T) begin // @[Reg.scala 16:19]
      r_5 <= in_ar_bits_id; // @[Reg.scala 16:23]
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_1 & ~(in_aw_bits_burst == 2'h1 | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed: only support busrt ince!\n    at AXI4SlaveModule.scala:72 assert(in.aw.bits.burst === AXI4Parameters.BURST_INCR, \"only support busrt ince!\")\n"
            ); // @[AXI4SlaveModule.scala 72:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T_1 & ~(in_aw_bits_burst == 2'h1 | reset)) begin
          $fatal; // @[AXI4SlaveModule.scala 72:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T & ~(in_ar_bits_burst == 2'h1 | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed: only support busrt ince!\n    at AXI4SlaveModule.scala:75 assert(in.ar.bits.burst === AXI4Parameters.BURST_INCR, \"only support busrt ince!\")\n"
            ); // @[AXI4SlaveModule.scala 75:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T & ~(in_ar_bits_burst == 2'h1 | reset)) begin
          $fatal; // @[AXI4SlaveModule.scala 75:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T & ~(_T_57 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at AXI4SlaveModule.scala:127 assert(\n"); // @[AXI4SlaveModule.scala 127:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_T & ~(_T_57 | reset)) begin
          $fatal; // @[AXI4SlaveModule.scala 127:13]
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
`ifdef RANDOMIZE_GARBAGE_ASSIGN
  _RAND_1 = {1{`RANDOM}};
  _RAND_3 = {1{`RANDOM}};
  _RAND_5 = {1{`RANDOM}};
  _RAND_7 = {1{`RANDOM}};
  _RAND_9 = {1{`RANDOM}};
  _RAND_11 = {1{`RANDOM}};
  _RAND_13 = {1{`RANDOM}};
  _RAND_15 = {1{`RANDOM}};
`endif // RANDOMIZE_GARBAGE_ASSIGN
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_0[initvar] = _RAND_0[7:0];
  _RAND_2 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_1[initvar] = _RAND_2[7:0];
  _RAND_4 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_2[initvar] = _RAND_4[7:0];
  _RAND_6 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_3[initvar] = _RAND_6[7:0];
  _RAND_8 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_4[initvar] = _RAND_8[7:0];
  _RAND_10 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_5[initvar] = _RAND_10[7:0];
  _RAND_12 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_6[initvar] = _RAND_12[7:0];
  _RAND_14 = {1{`RANDOM}};
  for (initvar = 0; initvar < 60000; initvar = initvar+1)
    MEM_7[initvar] = _RAND_14[7:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_16 = {1{`RANDOM}};
  state = _RAND_16[1:0];
  _RAND_17 = {1{`RANDOM}};
  value = _RAND_17[7:0];
  _RAND_18 = {1{`RANDOM}};
  r = _RAND_18[7:0];
  _RAND_19 = {1{`RANDOM}};
  r_1 = _RAND_19[30:0];
  _RAND_20 = {1{`RANDOM}};
  value_1 = _RAND_20[7:0];
  _RAND_21 = {1{`RANDOM}};
  r_2 = _RAND_21[30:0];
  _RAND_22 = {1{`RANDOM}};
  r_3 = _RAND_22[0:0];
  _RAND_23 = {1{`RANDOM}};
  r_5 = _RAND_23[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
