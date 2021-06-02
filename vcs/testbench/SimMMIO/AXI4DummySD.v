module AXI4DummySD(
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
  output        auto_in_r_bits_last
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
`endif // RANDOMIZE_REG_INIT
  wire  sdHelper_clk; // @[AXI4DummySD.scala 108:26]
  wire  sdHelper_ren; // @[AXI4DummySD.scala 108:26]
  wire [31:0] sdHelper_data; // @[AXI4DummySD.scala 108:26]
  wire  sdHelper_setAddr; // @[AXI4DummySD.scala 108:26]
  wire [31:0] sdHelper_addr; // @[AXI4DummySD.scala 108:26]
  reg [1:0] state; // @[AXI4SlaveModule.scala 79:22]
  wire  _T_61 = state == 2'h0; // @[AXI4SlaveModule.scala 137:24]
  wire  in_ar_ready = state == 2'h0; // @[AXI4SlaveModule.scala 137:24]
  wire  in_ar_valid = auto_in_ar_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T = in_ar_ready & in_ar_valid; // @[Decoupled.scala 40:37]
  wire  in_aw_ready = _T_61 & ~in_ar_valid; // @[AXI4SlaveModule.scala 155:35]
  wire  in_aw_valid = auto_in_aw_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_1 = in_aw_ready & in_aw_valid; // @[Decoupled.scala 40:37]
  wire  in_w_ready = state == 2'h2; // @[AXI4SlaveModule.scala 156:23]
  wire  in_w_valid = auto_in_w_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_2 = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  wire  in_b_ready = auto_in_b_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_b_valid = state == 2'h3; // @[AXI4SlaveModule.scala 159:22]
  wire  _T_3 = in_b_ready & in_b_valid; // @[Decoupled.scala 40:37]
  wire  in_r_ready = auto_in_r_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_r_valid = state == 2'h1; // @[AXI4SlaveModule.scala 139:23]
  wire  _T_4 = in_r_ready & in_r_valid; // @[Decoupled.scala 40:37]
  wire [1:0] in_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] in_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_15 = 2'h0 == state; // @[Conditional.scala 37:30]
  wire  _T_18 = 2'h1 == state; // @[Conditional.scala 37:30]
  reg [7:0] value; // @[Counter.scala 60:40]
  wire [7:0] in_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [7:0] r; // @[Reg.scala 27:20]
  wire [7:0] _T_43 = _T ? in_ar_bits_len : r; // @[Hold.scala 7:48]
  wire  in_r_bits_last = value == _T_43; // @[AXI4SlaveModule.scala 117:32]
  wire  _T_21 = 2'h2 == state; // @[Conditional.scala 37:30]
  wire  in_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] _GEN_3 = _T_2 & in_w_bits_last ? 2'h3 : state; // @[AXI4SlaveModule.scala 96:42 AXI4SlaveModule.scala 97:15 AXI4SlaveModule.scala 79:22]
  wire  _T_24 = 2'h3 == state; // @[Conditional.scala 37:30]
  wire [1:0] _GEN_4 = _T_3 ? 2'h0 : state; // @[AXI4SlaveModule.scala 101:24 AXI4SlaveModule.scala 102:15 AXI4SlaveModule.scala 79:22]
  wire [1:0] _GEN_5 = _T_24 ? _GEN_4 : state; // @[Conditional.scala 39:67 AXI4SlaveModule.scala 79:22]
  wire [7:0] in_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [30:0] r_1; // @[Reg.scala 27:20]
  wire [30:0] in_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [30:0] _GEN_10 = _T ? in_ar_bits_addr : r_1; // @[Reg.scala 28:19 Reg.scala 28:23 Reg.scala 27:20]
  wire [7:0] _value_T_1 = value + 8'h1; // @[Counter.scala 76:24]
  wire  _T_50 = in_ar_bits_len == 8'h1; // @[AXI4SlaveModule.scala 128:26]
  wire  _T_51 = in_ar_bits_len == 8'h0 | _T_50; // @[AXI4SlaveModule.scala 127:32]
  wire  _T_52 = in_ar_bits_len == 8'h3; // @[AXI4SlaveModule.scala 129:26]
  wire  _T_53 = _T_51 | _T_52; // @[AXI4SlaveModule.scala 128:34]
  wire  _T_54 = in_ar_bits_len == 8'h7; // @[AXI4SlaveModule.scala 130:26]
  wire  _T_55 = _T_53 | _T_54; // @[AXI4SlaveModule.scala 129:34]
  wire  _T_56 = in_ar_bits_len == 8'hf; // @[AXI4SlaveModule.scala 131:26]
  wire  _T_57 = _T_55 | _T_56; // @[AXI4SlaveModule.scala 130:34]
  reg [30:0] r_2; // @[Reg.scala 27:20]
  wire [30:0] in_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [30:0] _GEN_13 = _T_1 ? in_aw_bits_addr : r_2; // @[Reg.scala 28:19 Reg.scala 28:23 Reg.scala 27:20]
  reg [1:0] r_3; // @[Reg.scala 15:16]
  wire [1:0] in_aw_bits_id = auto_in_aw_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [1:0] r_5; // @[Reg.scala 15:16]
  wire [1:0] in_ar_bits_id = auto_in_ar_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [31:0] regs_0; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_1; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_4; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_5; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_6; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_7; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_8; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_15; // @[AXI4DummySD.scala 66:45]
  reg [31:0] regs_20; // @[AXI4DummySD.scala 66:45]
  wire [3:0] strb = _GEN_13[2] ? in_w_bits_strb[7:4] : in_w_bits_strb[3:0]; // @[AXI4DummySD.scala 133:19]
  wire [7:0] lo_lo_1 = strb[0] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_1 = strb[1] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_1 = strb[2] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_1 = strb[3] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [31:0] _T_93 = {hi_hi_1,hi_lo_1,lo_hi_1,lo_lo_1}; // @[Cat.scala 30:58]
  wire  _T_94 = 13'h0 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_95 = 13'h38 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_96 = 13'h18 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_97 = 13'h34 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_98 = 13'h14 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_99 = 13'h1c == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_100 = 13'h20 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_101 = 13'h40 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_102 = 13'h50 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_103 = 13'h10 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire  _T_104 = 13'h4 == _GEN_10[12:0]; // @[LookupTree.scala 8:34]
  wire [31:0] _T_105 = _T_94 ? regs_0 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_106 = _T_95 ? regs_15 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_107 = _T_96 ? regs_6 : 32'h0; // @[Mux.scala 27:72]
  wire [7:0] _T_108 = _T_97 ? 8'h80 : 8'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_109 = _T_98 ? regs_5 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_110 = _T_99 ? regs_7 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_111 = _T_100 ? regs_8 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_112 = _T_101 ? sdHelper_data : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_113 = _T_102 ? regs_20 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_114 = _T_103 ? regs_4 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_115 = _T_104 ? regs_1 : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_116 = _T_105 | _T_106; // @[Mux.scala 27:72]
  wire [31:0] _T_117 = _T_116 | _T_107; // @[Mux.scala 27:72]
  wire [31:0] _GEN_49 = {{24'd0}, _T_108}; // @[Mux.scala 27:72]
  wire [31:0] _T_118 = _T_117 | _GEN_49; // @[Mux.scala 27:72]
  wire [31:0] _T_119 = _T_118 | _T_109; // @[Mux.scala 27:72]
  wire [31:0] _T_120 = _T_119 | _T_110; // @[Mux.scala 27:72]
  wire [31:0] _T_121 = _T_120 | _T_111; // @[Mux.scala 27:72]
  wire [31:0] _T_122 = _T_121 | _T_112; // @[Mux.scala 27:72]
  wire [31:0] _T_123 = _T_122 | _T_113; // @[Mux.scala 27:72]
  wire [31:0] _T_124 = _T_123 | _T_114; // @[Mux.scala 27:72]
  wire [31:0] _T_125 = _T_124 | _T_115; // @[Mux.scala 27:72]
  wire [63:0] in_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [63:0] _GEN_50 = {{32'd0}, _T_93}; // @[BitUtils.scala 17:13]
  wire [63:0] _T_128 = in_w_bits_data & _GEN_50; // @[BitUtils.scala 17:13]
  wire [31:0] _T_129 = ~_T_93; // @[BitUtils.scala 17:38]
  wire [31:0] _T_130 = regs_0 & _T_129; // @[BitUtils.scala 17:36]
  wire [63:0] _GEN_51 = {{32'd0}, _T_130}; // @[BitUtils.scala 17:25]
  wire [63:0] _T_131 = _T_128 | _GEN_51; // @[BitUtils.scala 17:25]
  wire  _T_133 = 6'h1 == _T_131[5:0]; // @[Conditional.scala 37:30]
  wire  _T_134 = 6'h2 == _T_131[5:0]; // @[Conditional.scala 37:30]
  wire  _T_135 = 6'h9 == _T_131[5:0]; // @[Conditional.scala 37:30]
  wire  _T_141 = 6'hd == _T_131[5:0]; // @[Conditional.scala 37:30]
  wire  _T_142 = 6'h12 == _T_131[5:0]; // @[Conditional.scala 37:30]
  wire [31:0] _GEN_19 = _T_141 ? 32'h0 : regs_4; // @[Conditional.scala 39:67 AXI4DummySD.scala 96:24 AXI4DummySD.scala 66:45]
  wire [31:0] _GEN_20 = _T_141 ? 32'h0 : regs_5; // @[Conditional.scala 39:67 AXI4DummySD.scala 97:24 AXI4DummySD.scala 66:45]
  wire [31:0] _GEN_21 = _T_141 ? 32'h0 : regs_6; // @[Conditional.scala 39:67 AXI4DummySD.scala 98:24 AXI4DummySD.scala 66:45]
  wire [31:0] _GEN_22 = _T_141 ? 32'h0 : regs_7; // @[Conditional.scala 39:67 AXI4DummySD.scala 99:24 AXI4DummySD.scala 66:45]
  wire  _GEN_23 = _T_141 ? 1'h0 : _T_142; // @[Conditional.scala 39:67]
  wire [31:0] _GEN_24 = _T_135 ? 32'h92404001 : _GEN_19; // @[Conditional.scala 39:67 AXI4DummySD.scala 90:24]
  wire [31:0] _GEN_25 = _T_135 ? 32'hd24b97e3 : _GEN_20; // @[Conditional.scala 39:67 AXI4DummySD.scala 91:24]
  wire [31:0] _GEN_26 = _T_135 ? 32'hf5f803f : _GEN_21; // @[Conditional.scala 39:67 AXI4DummySD.scala 92:24]
  wire [31:0] _GEN_27 = _T_135 ? 32'h8c26012a : _GEN_22; // @[Conditional.scala 39:67 AXI4DummySD.scala 93:24]
  wire  _GEN_28 = _T_135 ? 1'h0 : _GEN_23; // @[Conditional.scala 39:67]
  wire  _GEN_33 = _T_134 ? 1'h0 : _GEN_28; // @[Conditional.scala 39:67]
  wire  _GEN_38 = _T_133 ? 1'h0 : _GEN_33; // @[Conditional.scala 40:58]
  wire [63:0] _GEN_44 = _T_2 & _GEN_13[12:0] == 13'h0 ? _T_131 : {{32'd0}, regs_0}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4DummySD.scala 66:45]
  wire [31:0] _T_147 = regs_15 & _T_129; // @[BitUtils.scala 17:36]
  wire [63:0] _GEN_53 = {{32'd0}, _T_147}; // @[BitUtils.scala 17:25]
  wire [63:0] _T_148 = _T_128 | _GEN_53; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_45 = _T_2 & _GEN_13[12:0] == 13'h38 ? _T_148 : {{32'd0}, regs_15}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4DummySD.scala 66:45]
  wire [31:0] _T_153 = regs_8 & _T_129; // @[BitUtils.scala 17:36]
  wire [63:0] _GEN_55 = {{32'd0}, _T_153}; // @[BitUtils.scala 17:25]
  wire [63:0] _T_154 = _T_128 | _GEN_55; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_46 = _T_2 & _GEN_13[12:0] == 13'h20 ? _T_154 : {{32'd0}, regs_8}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4DummySD.scala 66:45]
  wire [31:0] _T_159 = regs_20 & _T_129; // @[BitUtils.scala 17:36]
  wire [63:0] _GEN_57 = {{32'd0}, _T_159}; // @[BitUtils.scala 17:25]
  wire [63:0] _T_160 = _T_128 | _GEN_57; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_47 = _T_2 & _GEN_13[12:0] == 13'h50 ? _T_160 : {{32'd0}, regs_20}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4DummySD.scala 66:45]
  wire [31:0] _T_165 = regs_1 & _T_129; // @[BitUtils.scala 17:36]
  wire [63:0] _GEN_59 = {{32'd0}, _T_165}; // @[BitUtils.scala 17:25]
  wire [63:0] _T_166 = _T_128 | _GEN_59; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_48 = _T_2 & _GEN_13[12:0] == 13'h4 ? _T_166 : {{32'd0}, regs_1}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4DummySD.scala 66:45]
  wire [63:0] rdata = {{32'd0}, _T_125}; // @[AXI4DummySD.scala 134:21 RegMap.scala 12:11]
  wire [31:0] hi_2 = rdata[31:0]; // @[AXI4DummySD.scala 138:36]
  wire [7:0] in_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] in_b_bits_id = r_3; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 161:16]
  wire [1:0] in_b_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 158:18]
  wire [2:0] in_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] in_r_bits_id = r_5; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 163:16]
  wire [63:0] in_r_bits_data = {hi_2,hi_2}; // @[Cat.scala 30:58]
  wire [1:0] in_r_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 138:18]
  SDHelper sdHelper ( // @[AXI4DummySD.scala 108:26]
    .clk(sdHelper_clk),
    .ren(sdHelper_ren),
    .data(sdHelper_data),
    .setAddr(sdHelper_setAddr),
    .addr(sdHelper_addr)
  );
  assign auto_in_aw_ready = in_aw_ready; // @[LazyModule.scala 309:16]
  assign auto_in_w_ready = in_w_ready; // @[LazyModule.scala 309:16]
  assign auto_in_b_valid = in_b_valid; // @[LazyModule.scala 309:16]
  assign auto_in_b_bits_id = in_b_bits_id; // @[LazyModule.scala 309:16]
  assign auto_in_b_bits_resp = in_b_bits_resp; // @[LazyModule.scala 309:16]
  assign auto_in_ar_ready = in_ar_ready; // @[LazyModule.scala 309:16]
  assign auto_in_r_valid = in_r_valid; // @[LazyModule.scala 309:16]
  assign auto_in_r_bits_id = in_r_bits_id; // @[LazyModule.scala 309:16]
  assign auto_in_r_bits_data = in_r_bits_data; // @[LazyModule.scala 309:16]
  assign auto_in_r_bits_resp = in_b_bits_resp; // @[LazyModule.scala 309:16]
  assign auto_in_r_bits_last = in_r_bits_last; // @[LazyModule.scala 309:16]
  assign sdHelper_clk = clock; // @[AXI4DummySD.scala 109:21]
  assign sdHelper_ren = _GEN_10[12:0] == 13'h40 & _T; // @[AXI4DummySD.scala 110:53]
  assign sdHelper_setAddr = _T_2 & _GEN_13[12:0] == 13'h0 & _GEN_38; // @[RegMap.scala 14:48]
  assign sdHelper_addr = regs_1; // @[AXI4DummySD.scala 112:22]
  always @(posedge clock) begin
    if (reset) begin // @[AXI4SlaveModule.scala 79:22]
      state <= 2'h0; // @[AXI4SlaveModule.scala 79:22]
    end else if (_T_15) begin // @[Conditional.scala 40:58]
      if (_T_1) begin // @[AXI4SlaveModule.scala 86:25]
        state <= 2'h2; // @[AXI4SlaveModule.scala 87:15]
      end else if (_T) begin // @[AXI4SlaveModule.scala 83:25]
        state <= 2'h1; // @[AXI4SlaveModule.scala 84:15]
      end
    end else if (_T_18) begin // @[Conditional.scala 39:67]
      if (_T_4 & in_r_bits_last) begin // @[AXI4SlaveModule.scala 91:42]
        state <= 2'h0; // @[AXI4SlaveModule.scala 92:15]
      end
    end else if (_T_21) begin // @[Conditional.scala 39:67]
      state <= _GEN_3;
    end else begin
      state <= _GEN_5;
    end
    if (reset) begin // @[Counter.scala 60:40]
      value <= 8'h0; // @[Counter.scala 60:40]
    end else if (_T_4) begin // @[AXI4SlaveModule.scala 119:23]
      if (in_r_bits_last) begin // @[AXI4SlaveModule.scala 121:28]
        value <= 8'h0; // @[AXI4SlaveModule.scala 122:17]
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
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_0 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else begin
      regs_0 <= _GEN_44[31:0];
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_1 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else begin
      regs_1 <= _GEN_48[31:0];
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_4 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else if (_T_2 & _GEN_13[12:0] == 13'h0) begin // @[RegMap.scala 14:48]
      if (_T_133) begin // @[Conditional.scala 40:58]
        regs_4 <= 32'h80ff8000; // @[AXI4DummySD.scala 81:24]
      end else if (_T_134) begin // @[Conditional.scala 39:67]
        regs_4 <= 32'h1; // @[AXI4DummySD.scala 84:24]
      end else begin
        regs_4 <= _GEN_24;
      end
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_5 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else if (_T_2 & _GEN_13[12:0] == 13'h0) begin // @[RegMap.scala 14:48]
      if (!(_T_133)) begin // @[Conditional.scala 40:58]
        if (_T_134) begin // @[Conditional.scala 39:67]
          regs_5 <= 32'h0; // @[AXI4DummySD.scala 85:24]
        end else begin
          regs_5 <= _GEN_25;
        end
      end
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_6 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else if (_T_2 & _GEN_13[12:0] == 13'h0) begin // @[RegMap.scala 14:48]
      if (!(_T_133)) begin // @[Conditional.scala 40:58]
        if (_T_134) begin // @[Conditional.scala 39:67]
          regs_6 <= 32'h0; // @[AXI4DummySD.scala 86:24]
        end else begin
          regs_6 <= _GEN_26;
        end
      end
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_7 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else if (_T_2 & _GEN_13[12:0] == 13'h0) begin // @[RegMap.scala 14:48]
      if (!(_T_133)) begin // @[Conditional.scala 40:58]
        if (_T_134) begin // @[Conditional.scala 39:67]
          regs_7 <= 32'h15000000; // @[AXI4DummySD.scala 87:24]
        end else begin
          regs_7 <= _GEN_27;
        end
      end
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_8 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else begin
      regs_8 <= _GEN_46[31:0];
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_15 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else begin
      regs_15 <= _GEN_45[31:0];
    end
    if (reset) begin // @[AXI4DummySD.scala 66:45]
      regs_20 <= 32'h0; // @[AXI4DummySD.scala 66:45]
    end else begin
      regs_20 <= _GEN_47[31:0];
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_1 & ~(in_aw_bits_burst == 2'h1 | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed: only support busrt ince!\n    at AXI4SlaveModule.scala:71 assert(in.aw.bits.burst === AXI4Parameters.BURST_INCR, \"only support busrt ince!\")\n"
            ); // @[AXI4SlaveModule.scala 71:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T & ~(in_ar_bits_burst == 2'h1 | reset)) begin
          $fwrite(32'h80000002,
            "Assertion failed: only support busrt ince!\n    at AXI4SlaveModule.scala:74 assert(in.ar.bits.burst === AXI4Parameters.BURST_INCR, \"only support busrt ince!\")\n"
            ); // @[AXI4SlaveModule.scala 74:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T & ~(_T_57 | reset)) begin
          $fwrite(32'h80000002,"Assertion failed\n    at AXI4SlaveModule.scala:126 assert(\n"); // @[AXI4SlaveModule.scala 126:13]
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
  state = _RAND_0[1:0];
  _RAND_1 = {1{`RANDOM}};
  value = _RAND_1[7:0];
  _RAND_2 = {1{`RANDOM}};
  r = _RAND_2[7:0];
  _RAND_3 = {1{`RANDOM}};
  r_1 = _RAND_3[30:0];
  _RAND_4 = {1{`RANDOM}};
  r_2 = _RAND_4[30:0];
  _RAND_5 = {1{`RANDOM}};
  r_3 = _RAND_5[1:0];
  _RAND_6 = {1{`RANDOM}};
  r_5 = _RAND_6[1:0];
  _RAND_7 = {1{`RANDOM}};
  regs_0 = _RAND_7[31:0];
  _RAND_8 = {1{`RANDOM}};
  regs_1 = _RAND_8[31:0];
  _RAND_9 = {1{`RANDOM}};
  regs_4 = _RAND_9[31:0];
  _RAND_10 = {1{`RANDOM}};
  regs_5 = _RAND_10[31:0];
  _RAND_11 = {1{`RANDOM}};
  regs_6 = _RAND_11[31:0];
  _RAND_12 = {1{`RANDOM}};
  regs_7 = _RAND_12[31:0];
  _RAND_13 = {1{`RANDOM}};
  regs_8 = _RAND_13[31:0];
  _RAND_14 = {1{`RANDOM}};
  regs_15 = _RAND_14[31:0];
  _RAND_15 = {1{`RANDOM}};
  regs_20 = _RAND_15[31:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule

