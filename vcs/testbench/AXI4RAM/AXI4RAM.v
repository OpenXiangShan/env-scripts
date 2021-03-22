module AXI4RAM(
  input          clock,
  input          reset,
  output         auto_in_aw_ready,
  input          auto_in_aw_valid,
  input  [7:0]   auto_in_aw_bits_id,
  input  [39:0]  auto_in_aw_bits_addr,
  input  [7:0]   auto_in_aw_bits_len,
  input  [2:0]   auto_in_aw_bits_size,
  input  [1:0]   auto_in_aw_bits_burst,
  input          auto_in_aw_bits_lock,
  input  [3:0]   auto_in_aw_bits_cache,
  input  [2:0]   auto_in_aw_bits_prot,
  input  [3:0]   auto_in_aw_bits_qos,
  output         auto_in_w_ready,
  input          auto_in_w_valid,
  input  [255:0] auto_in_w_bits_data,
  input  [31:0]  auto_in_w_bits_strb,
  input          auto_in_w_bits_last,
  input          auto_in_b_ready,
  output         auto_in_b_valid,
  output [7:0]   auto_in_b_bits_id,
  output [1:0]   auto_in_b_bits_resp,
  output         auto_in_ar_ready,
  input          auto_in_ar_valid,
  input  [7:0]   auto_in_ar_bits_id,
  input  [39:0]  auto_in_ar_bits_addr,
  input  [7:0]   auto_in_ar_bits_len,
  input  [2:0]   auto_in_ar_bits_size,
  input  [1:0]   auto_in_ar_bits_burst,
  input          auto_in_ar_bits_lock,
  input  [3:0]   auto_in_ar_bits_cache,
  input  [2:0]   auto_in_ar_bits_prot,
  input  [3:0]   auto_in_ar_bits_qos,
  input          auto_in_r_ready,
  output         auto_in_r_valid,
  output [7:0]   auto_in_r_bits_id,
  output [255:0] auto_in_r_bits_data,
  output [1:0]   auto_in_r_bits_resp,
  output         auto_in_r_bits_last
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [63:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [63:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
`endif // RANDOMIZE_REG_INIT
  wire  RAMHelper_clk; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_en; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_rIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_rdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_wIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_wdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_wmask; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_wen; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_1_clk; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_1_en; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_1_rIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_1_rdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_1_wIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_1_wdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_1_wmask; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_1_wen; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_2_clk; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_2_en; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_2_rIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_2_rdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_2_wIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_2_wdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_2_wmask; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_2_wen; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_3_clk; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_3_en; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_3_rIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_3_rdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_3_wIdx; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_3_wdata; // @[AXI4RAM.scala 54:50]
  wire [63:0] RAMHelper_3_wmask; // @[AXI4RAM.scala 54:50]
  wire  RAMHelper_3_wen; // @[AXI4RAM.scala 54:50]
  reg [1:0] state; // @[AXI4SlaveModule.scala 80:22]
  wire  _T_109 = state == 2'h0; // @[AXI4SlaveModule.scala 138:24]
  wire  in_ar_ready = state == 2'h0; // @[AXI4SlaveModule.scala 138:24]
  wire  in_ar_valid = auto_in_ar_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T = in_ar_ready & in_ar_valid; // @[Decoupled.scala 40:37]
  wire  in_aw_ready = _T_109 & ~in_ar_valid; // @[AXI4SlaveModule.scala 156:35]
  wire  in_aw_valid = auto_in_aw_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_1 = in_aw_ready & in_aw_valid; // @[Decoupled.scala 40:37]
  wire  _T_117 = state == 2'h2; // @[AXI4SlaveModule.scala 157:23]
  wire  in_w_ready = state == 2'h2; // @[AXI4SlaveModule.scala 157:23]
  wire  in_w_valid = auto_in_w_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_2 = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  wire  in_b_ready = auto_in_b_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_b_valid = state == 2'h3; // @[AXI4SlaveModule.scala 160:22]
  wire  _T_3 = in_b_ready & in_b_valid; // @[Decoupled.scala 40:37]
  wire  in_r_ready = auto_in_r_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_110 = state == 2'h1; // @[AXI4SlaveModule.scala 140:23]
  wire  in_r_valid = state == 2'h1; // @[AXI4SlaveModule.scala 140:23]
  wire  _T_4 = in_r_ready & in_r_valid; // @[Decoupled.scala 40:37]
  wire [1:0] in_aw_bits_burst = auto_in_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] in_ar_bits_burst = auto_in_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  _T_15 = 2'h0 == state; // @[Conditional.scala 37:30]
  wire  _T_18 = 2'h1 == state; // @[Conditional.scala 37:30]
  reg [7:0] value; // @[Counter.scala 60:40]
  wire [7:0] in_ar_bits_len = auto_in_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [7:0] r; // @[Reg.scala 27:20]
  wire [7:0] _T_91 = _T ? in_ar_bits_len : r; // @[Hold.scala 7:48]
  wire  in_r_bits_last = value == _T_91; // @[AXI4SlaveModule.scala 118:32]
  wire  _T_21 = 2'h2 == state; // @[Conditional.scala 37:30]
  wire  in_w_bits_last = auto_in_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [1:0] _GEN_3 = _T_2 & in_w_bits_last ? 2'h3 : state; // @[AXI4SlaveModule.scala 97:42 AXI4SlaveModule.scala 98:15 AXI4SlaveModule.scala 80:22]
  wire  _T_24 = 2'h3 == state; // @[Conditional.scala 37:30]
  wire [1:0] _GEN_4 = _T_3 ? 2'h0 : state; // @[AXI4SlaveModule.scala 102:24 AXI4SlaveModule.scala 103:15 AXI4SlaveModule.scala 80:22]
  wire [1:0] _GEN_5 = _T_24 ? _GEN_4 : state; // @[Conditional.scala 39:67 AXI4SlaveModule.scala 80:22]
  wire [31:0] in_w_bits_strb = auto_in_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [39:0] r_1; // @[Reg.scala 27:20]
  wire [39:0] in_ar_bits_addr = auto_in_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [39:0] _GEN_10 = _T ? in_ar_bits_addr : r_1; // @[Reg.scala 28:19 Reg.scala 28:23 Reg.scala 27:20]
  wire [7:0] _value_T_1 = value + 8'h1; // @[Counter.scala 76:24]
  wire  _T_98 = in_ar_bits_len == 8'h1; // @[AXI4SlaveModule.scala 129:26]
  wire  _T_99 = in_ar_bits_len == 8'h0 | _T_98; // @[AXI4SlaveModule.scala 128:32]
  wire  _T_100 = in_ar_bits_len == 8'h3; // @[AXI4SlaveModule.scala 130:26]
  wire  _T_101 = _T_99 | _T_100; // @[AXI4SlaveModule.scala 129:34]
  wire  _T_102 = in_ar_bits_len == 8'h7; // @[AXI4SlaveModule.scala 131:26]
  wire  _T_103 = _T_101 | _T_102; // @[AXI4SlaveModule.scala 130:34]
  wire  _T_104 = in_ar_bits_len == 8'hf; // @[AXI4SlaveModule.scala 132:26]
  wire  _T_105 = _T_103 | _T_104; // @[AXI4SlaveModule.scala 131:34]
  reg [7:0] value_1; // @[Counter.scala 60:40]
  reg [39:0] r_2; // @[Reg.scala 27:20]
  wire [39:0] in_aw_bits_addr = auto_in_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [39:0] _GEN_13 = _T_1 ? in_aw_bits_addr : r_2; // @[Reg.scala 28:19 Reg.scala 28:23 Reg.scala 27:20]
  wire [7:0] _value_T_3 = value_1 + 8'h1; // @[Counter.scala 76:24]
  reg [7:0] r_3; // @[Reg.scala 15:16]
  wire [7:0] in_aw_bits_id = auto_in_aw_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  reg [7:0] r_5; // @[Reg.scala 15:16]
  wire [7:0] in_ar_bits_id = auto_in_ar_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [39:0] _T_124 = _GEN_13 - 40'h80000000; // @[AXI4RAM.scala 44:36]
  wire [30:0] _GEN_18 = {{23'd0}, value_1}; // @[AXI4RAM.scala 48:29]
  wire [30:0] wIdx = _T_124[35:5] + _GEN_18; // @[AXI4RAM.scala 48:29]
  wire [39:0] _T_129 = _GEN_10 - 40'h80000000; // @[AXI4RAM.scala 44:36]
  wire [30:0] _GEN_19 = {{23'd0}, value}; // @[AXI4RAM.scala 49:29]
  wire [30:0] rIdx = _T_129[35:5] + _GEN_19; // @[AXI4RAM.scala 49:29]
  wire [32:0] _T_141 = {rIdx, 2'h0}; // @[AXI4RAM.scala 58:31]
  wire [33:0] _T_142 = {{1'd0}, _T_141}; // @[AXI4RAM.scala 58:49]
  wire [32:0] _T_144 = {wIdx, 2'h0}; // @[AXI4RAM.scala 59:31]
  wire [33:0] _T_145 = {{1'd0}, _T_144}; // @[AXI4RAM.scala 59:49]
  wire [255:0] in_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [7:0] lo_lo_lo_1 = in_w_bits_strb[0] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_lo_hi_1 = in_w_bits_strb[1] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_lo_1 = in_w_bits_strb[2] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_hi_1 = in_w_bits_strb[3] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_lo_1 = in_w_bits_strb[4] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_hi_1 = in_w_bits_strb[5] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_lo_1 = in_w_bits_strb[6] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_hi_1 = in_w_bits_strb[7] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [31:0] lo_1 = {lo_hi_hi_1,lo_hi_lo_1,lo_lo_hi_1,lo_lo_lo_1}; // @[Cat.scala 30:58]
  wire [31:0] hi_1 = {hi_hi_hi_1,hi_hi_lo_1,hi_lo_hi_1,hi_lo_lo_1}; // @[Cat.scala 30:58]
  wire [32:0] _T_174 = _T_141 + 33'h1; // @[AXI4RAM.scala 58:49]
  wire [32:0] _T_177 = _T_144 + 33'h1; // @[AXI4RAM.scala 59:49]
  wire [7:0] lo_lo_lo_2 = in_w_bits_strb[8] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_lo_hi_2 = in_w_bits_strb[9] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_lo_2 = in_w_bits_strb[10] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_hi_2 = in_w_bits_strb[11] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_lo_2 = in_w_bits_strb[12] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_hi_2 = in_w_bits_strb[13] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_lo_2 = in_w_bits_strb[14] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_hi_2 = in_w_bits_strb[15] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [31:0] lo_2 = {lo_hi_hi_2,lo_hi_lo_2,lo_lo_hi_2,lo_lo_lo_2}; // @[Cat.scala 30:58]
  wire [31:0] hi_2 = {hi_hi_hi_2,hi_hi_lo_2,hi_lo_hi_2,hi_lo_lo_2}; // @[Cat.scala 30:58]
  wire [32:0] _T_205 = _T_141 + 33'h2; // @[AXI4RAM.scala 58:49]
  wire [32:0] _T_208 = _T_144 + 33'h2; // @[AXI4RAM.scala 59:49]
  wire [7:0] lo_lo_lo_3 = in_w_bits_strb[16] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_lo_hi_3 = in_w_bits_strb[17] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_lo_3 = in_w_bits_strb[18] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_hi_3 = in_w_bits_strb[19] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_lo_3 = in_w_bits_strb[20] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_hi_3 = in_w_bits_strb[21] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_lo_3 = in_w_bits_strb[22] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_hi_3 = in_w_bits_strb[23] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [31:0] lo_3 = {lo_hi_hi_3,lo_hi_lo_3,lo_lo_hi_3,lo_lo_lo_3}; // @[Cat.scala 30:58]
  wire [31:0] hi_3 = {hi_hi_hi_3,hi_hi_lo_3,hi_lo_hi_3,hi_lo_lo_3}; // @[Cat.scala 30:58]
  wire [32:0] _T_236 = _T_141 + 33'h3; // @[AXI4RAM.scala 58:49]
  wire [32:0] _T_239 = _T_144 + 33'h3; // @[AXI4RAM.scala 59:49]
  wire [7:0] lo_lo_lo_4 = in_w_bits_strb[24] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_lo_hi_4 = in_w_bits_strb[25] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_lo_4 = in_w_bits_strb[26] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_hi_4 = in_w_bits_strb[27] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_lo_4 = in_w_bits_strb[28] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_hi_4 = in_w_bits_strb[29] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_lo_4 = in_w_bits_strb[30] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_hi_4 = in_w_bits_strb[31] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [31:0] lo_4 = {lo_hi_hi_4,lo_hi_lo_4,lo_lo_hi_4,lo_lo_lo_4}; // @[Cat.scala 30:58]
  wire [31:0] hi_4 = {hi_hi_hi_4,hi_hi_lo_4,hi_lo_hi_4,hi_lo_lo_4}; // @[Cat.scala 30:58]
  wire [255:0] rdata = {RAMHelper_3_rdata,RAMHelper_2_rdata,RAMHelper_1_rdata,RAMHelper_rdata}; // @[Cat.scala 30:58]
  wire [7:0] in_aw_bits_len = auto_in_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_aw_bits_size = auto_in_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_aw_bits_lock = auto_in_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_aw_bits_cache = auto_in_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_aw_bits_prot = auto_in_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_aw_bits_qos = auto_in_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [7:0] in_b_bits_id = r_3; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 162:16]
  wire [1:0] in_b_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 159:18]
  wire [2:0] in_ar_bits_size = auto_in_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire  in_ar_bits_lock = auto_in_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_ar_bits_cache = auto_in_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [2:0] in_ar_bits_prot = auto_in_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [3:0] in_ar_bits_qos = auto_in_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [7:0] in_r_bits_id = r_5; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 164:16]
  wire [255:0] in_r_bits_data = rdata; // @[Cat.scala 30:58]
  wire [1:0] in_r_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 139:18]
  RAMHelper RAMHelper ( // @[AXI4RAM.scala 54:50]
    .clk(RAMHelper_clk),
    .en(RAMHelper_en),
    .rIdx(RAMHelper_rIdx),
    .rdata(RAMHelper_rdata),
    .wIdx(RAMHelper_wIdx),
    .wdata(RAMHelper_wdata),
    .wmask(RAMHelper_wmask),
    .wen(RAMHelper_wen)
  );
  RAMHelper RAMHelper_1 ( // @[AXI4RAM.scala 54:50]
    .clk(RAMHelper_1_clk),
    .en(RAMHelper_1_en),
    .rIdx(RAMHelper_1_rIdx),
    .rdata(RAMHelper_1_rdata),
    .wIdx(RAMHelper_1_wIdx),
    .wdata(RAMHelper_1_wdata),
    .wmask(RAMHelper_1_wmask),
    .wen(RAMHelper_1_wen)
  );
  RAMHelper RAMHelper_2 ( // @[AXI4RAM.scala 54:50]
    .clk(RAMHelper_2_clk),
    .en(RAMHelper_2_en),
    .rIdx(RAMHelper_2_rIdx),
    .rdata(RAMHelper_2_rdata),
    .wIdx(RAMHelper_2_wIdx),
    .wdata(RAMHelper_2_wdata),
    .wmask(RAMHelper_2_wmask),
    .wen(RAMHelper_2_wen)
  );
  RAMHelper RAMHelper_3 ( // @[AXI4RAM.scala 54:50]
    .clk(RAMHelper_3_clk),
    .en(RAMHelper_3_en),
    .rIdx(RAMHelper_3_rIdx),
    .rdata(RAMHelper_3_rdata),
    .wIdx(RAMHelper_3_wIdx),
    .wdata(RAMHelper_3_wdata),
    .wmask(RAMHelper_3_wmask),
    .wen(RAMHelper_3_wen)
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
  assign RAMHelper_clk = clock; // @[AXI4RAM.scala 56:22]
  assign RAMHelper_en = ~reset & (_T_110 | _T_117); // @[AXI4RAM.scala 57:41]
  assign RAMHelper_rIdx = {{31'd0}, _T_142[32:0]}; // @[AXI4RAM.scala 58:49]
  assign RAMHelper_wIdx = {{31'd0}, _T_145[32:0]}; // @[AXI4RAM.scala 59:49]
  assign RAMHelper_wdata = in_w_bits_data[63:0]; // @[AXI4RAM.scala 60:39]
  assign RAMHelper_wmask = {hi_1,lo_1}; // @[Cat.scala 30:58]
  assign RAMHelper_wen = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  assign RAMHelper_1_clk = clock; // @[AXI4RAM.scala 56:22]
  assign RAMHelper_1_en = ~reset & (_T_110 | _T_117); // @[AXI4RAM.scala 57:41]
  assign RAMHelper_1_rIdx = {{31'd0}, _T_174}; // @[AXI4RAM.scala 58:49]
  assign RAMHelper_1_wIdx = {{31'd0}, _T_177}; // @[AXI4RAM.scala 59:49]
  assign RAMHelper_1_wdata = in_w_bits_data[127:64]; // @[AXI4RAM.scala 60:39]
  assign RAMHelper_1_wmask = {hi_2,lo_2}; // @[Cat.scala 30:58]
  assign RAMHelper_1_wen = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  assign RAMHelper_2_clk = clock; // @[AXI4RAM.scala 56:22]
  assign RAMHelper_2_en = ~reset & (_T_110 | _T_117); // @[AXI4RAM.scala 57:41]
  assign RAMHelper_2_rIdx = {{31'd0}, _T_205}; // @[AXI4RAM.scala 58:49]
  assign RAMHelper_2_wIdx = {{31'd0}, _T_208}; // @[AXI4RAM.scala 59:49]
  assign RAMHelper_2_wdata = in_w_bits_data[191:128]; // @[AXI4RAM.scala 60:39]
  assign RAMHelper_2_wmask = {hi_3,lo_3}; // @[Cat.scala 30:58]
  assign RAMHelper_2_wen = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  assign RAMHelper_3_clk = clock; // @[AXI4RAM.scala 56:22]
  assign RAMHelper_3_en = ~reset & (_T_110 | _T_117); // @[AXI4RAM.scala 57:41]
  assign RAMHelper_3_rIdx = {{31'd0}, _T_236}; // @[AXI4RAM.scala 58:49]
  assign RAMHelper_3_wIdx = {{31'd0}, _T_239}; // @[AXI4RAM.scala 59:49]
  assign RAMHelper_3_wdata = in_w_bits_data[255:192]; // @[AXI4RAM.scala 60:39]
  assign RAMHelper_3_wmask = {hi_4,lo_4}; // @[Cat.scala 30:58]
  assign RAMHelper_3_wen = in_w_ready & in_w_valid; // @[Decoupled.scala 40:37]
  always @(posedge clock) begin
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
      r_1 <= 40'h0; // @[Reg.scala 27:20]
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
      r_2 <= 40'h0; // @[Reg.scala 27:20]
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
        if (_T & ~(_T_105 | reset)) begin
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
        if (_T & ~(_T_105 | reset)) begin
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
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  state = _RAND_0[1:0];
  _RAND_1 = {1{`RANDOM}};
  value = _RAND_1[7:0];
  _RAND_2 = {1{`RANDOM}};
  r = _RAND_2[7:0];
  _RAND_3 = {2{`RANDOM}};
  r_1 = _RAND_3[39:0];
  _RAND_4 = {1{`RANDOM}};
  value_1 = _RAND_4[7:0];
  _RAND_5 = {2{`RANDOM}};
  r_2 = _RAND_5[39:0];
  _RAND_6 = {1{`RANDOM}};
  r_3 = _RAND_6[7:0];
  _RAND_7 = {1{`RANDOM}};
  r_5 = _RAND_7[7:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
