module AXI4UART(
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
  output        io_extra_out_valid,
  output [7:0]  io_extra_out_ch,
  output        io_extra_in_valid,
  input  [7:0]  io_extra_in_ch
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
`endif // RANDOMIZE_REG_INIT
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
  reg [31:0] txfifo; // @[AXI4UART.scala 28:21]
  reg [31:0] stat; // @[AXI4UART.scala 29:23]
  reg [31:0] ctrl; // @[AXI4UART.scala 30:23]
  wire  _T_76 = _GEN_13[3:0] == 4'h4; // @[AXI4UART.scala 32:43]
  wire [63:0] in_w_bits_data = auto_in_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  wire [7:0] _T_88 = in_w_bits_strb >> _GEN_13[2:0]; // @[AXI4UART.scala 44:74]
  wire [7:0] lo_lo_lo_1 = _T_88[0] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_lo_hi_1 = _T_88[1] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_lo_1 = _T_88[2] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] lo_hi_hi_1 = _T_88[3] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_lo_1 = _T_88[4] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_lo_hi_1 = _T_88[5] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_lo_1 = _T_88[6] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [7:0] hi_hi_hi_1 = _T_88[7] ? 8'hff : 8'h0; // @[Bitwise.scala 72:12]
  wire [63:0] _T_105 = {hi_hi_hi_1,hi_hi_lo_1,hi_lo_hi_1,hi_lo_lo_1,lo_hi_hi_1,lo_hi_lo_1,lo_lo_hi_1,lo_lo_lo_1}; // @[Cat.scala 30:58]
  wire  _T_106 = 4'h0 == _GEN_10[3:0]; // @[LookupTree.scala 8:34]
  wire  _T_107 = 4'h4 == _GEN_10[3:0]; // @[LookupTree.scala 8:34]
  wire  _T_108 = 4'h8 == _GEN_10[3:0]; // @[LookupTree.scala 8:34]
  wire  _T_109 = 4'hc == _GEN_10[3:0]; // @[LookupTree.scala 8:34]
  wire [7:0] _T_110 = _T_106 ? io_extra_in_ch : 8'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_111 = _T_107 ? txfifo : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_112 = _T_108 ? stat : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _T_113 = _T_109 ? ctrl : 32'h0; // @[Mux.scala 27:72]
  wire [31:0] _GEN_21 = {{24'd0}, _T_110}; // @[Mux.scala 27:72]
  wire [31:0] _T_114 = _GEN_21 | _T_111; // @[Mux.scala 27:72]
  wire [31:0] _T_115 = _T_114 | _T_112; // @[Mux.scala 27:72]
  wire [31:0] _T_116 = _T_115 | _T_113; // @[Mux.scala 27:72]
  wire [63:0] _T_119 = in_w_bits_data & _T_105; // @[BitUtils.scala 17:13]
  wire [63:0] _T_120 = ~_T_105; // @[BitUtils.scala 17:38]
  wire [63:0] _GEN_22 = {{32'd0}, txfifo}; // @[BitUtils.scala 17:36]
  wire [63:0] _T_121 = _GEN_22 & _T_120; // @[BitUtils.scala 17:36]
  wire [63:0] _T_122 = _T_119 | _T_121; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_18 = _T_2 & _T_76 ? _T_122 : {{32'd0}, txfifo}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4UART.scala 28:21]
  wire [63:0] _GEN_23 = {{32'd0}, stat}; // @[BitUtils.scala 17:36]
  wire [63:0] _T_127 = _GEN_23 & _T_120; // @[BitUtils.scala 17:36]
  wire [63:0] _T_128 = _T_119 | _T_127; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_19 = _T_2 & _GEN_13[3:0] == 4'h8 ? _T_128 : {{32'd0}, stat}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4UART.scala 29:23]
  wire [63:0] _GEN_24 = {{32'd0}, ctrl}; // @[BitUtils.scala 17:36]
  wire [63:0] _T_133 = _GEN_24 & _T_120; // @[BitUtils.scala 17:36]
  wire [63:0] _T_134 = _T_119 | _T_133; // @[BitUtils.scala 17:25]
  wire [63:0] _GEN_20 = _T_2 & _GEN_13[3:0] == 4'hc ? _T_134 : {{32'd0}, ctrl}; // @[RegMap.scala 14:48 RegMap.scala 14:52 AXI4UART.scala 30:23]
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
  wire [63:0] in_r_bits_data = {{32'd0}, _T_116}; // @[Nodes.scala 1210:84 RegMap.scala 12:11]
  wire [1:0] in_r_bits_resp = 2'h0; // @[Nodes.scala 1210:84 AXI4SlaveModule.scala 138:18]
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
  assign io_extra_out_valid = _GEN_13[3:0] == 4'h4 & _T_2; // @[AXI4UART.scala 32:51]
  assign io_extra_out_ch = in_w_bits_data[7:0]; // @[AXI4UART.scala 33:42]
  assign io_extra_in_valid = _GEN_10[3:0] == 4'h0 & _T_4; // @[AXI4UART.scala 34:50]
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
    txfifo <= _GEN_18[31:0];
    if (reset) begin // @[AXI4UART.scala 29:23]
      stat <= 32'h1; // @[AXI4UART.scala 29:23]
    end else begin
      stat <= _GEN_19[31:0];
    end
    if (reset) begin // @[AXI4UART.scala 30:23]
      ctrl <= 32'h0; // @[AXI4UART.scala 30:23]
    end else begin
      ctrl <= _GEN_20[31:0];
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
  txfifo = _RAND_7[31:0];
  _RAND_8 = {1{`RANDOM}};
  stat = _RAND_8[31:0];
  _RAND_9 = {1{`RANDOM}};
  ctrl = _RAND_9[31:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule

