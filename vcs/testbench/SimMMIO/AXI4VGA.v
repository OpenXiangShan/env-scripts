module AXI4VGA(
  input         clock,
  input         reset,
  output        auto_in_1_aw_ready,
  input         auto_in_1_aw_valid,
  input         auto_in_1_aw_bits_id,
  input  [30:0] auto_in_1_aw_bits_addr,
  input  [7:0]  auto_in_1_aw_bits_len,
  input  [2:0]  auto_in_1_aw_bits_size,
  input  [1:0]  auto_in_1_aw_bits_burst,
  input         auto_in_1_aw_bits_lock,
  input  [3:0]  auto_in_1_aw_bits_cache,
  input  [2:0]  auto_in_1_aw_bits_prot,
  input  [3:0]  auto_in_1_aw_bits_qos,
  output        auto_in_1_w_ready,
  input         auto_in_1_w_valid,
  input  [63:0] auto_in_1_w_bits_data,
  input  [7:0]  auto_in_1_w_bits_strb,
  input         auto_in_1_w_bits_last,
  input         auto_in_1_b_ready,
  output        auto_in_1_b_valid,
  output        auto_in_1_b_bits_id,
  output [1:0]  auto_in_1_b_bits_resp,
  output        auto_in_1_ar_ready,
  input         auto_in_1_ar_valid,
  input         auto_in_1_ar_bits_id,
  input  [30:0] auto_in_1_ar_bits_addr,
  input  [7:0]  auto_in_1_ar_bits_len,
  input  [2:0]  auto_in_1_ar_bits_size,
  input  [1:0]  auto_in_1_ar_bits_burst,
  input         auto_in_1_ar_bits_lock,
  input  [3:0]  auto_in_1_ar_bits_cache,
  input  [2:0]  auto_in_1_ar_bits_prot,
  input  [3:0]  auto_in_1_ar_bits_qos,
  input         auto_in_1_r_ready,
  output        auto_in_1_r_valid,
  output        auto_in_1_r_bits_id,
  output [63:0] auto_in_1_r_bits_data,
  output [1:0]  auto_in_1_r_bits_resp,
  output        auto_in_1_r_bits_last,
  output        auto_in_0_aw_ready,
  input         auto_in_0_aw_valid,
  input         auto_in_0_aw_bits_id,
  input  [30:0] auto_in_0_aw_bits_addr,
  input  [7:0]  auto_in_0_aw_bits_len,
  input  [2:0]  auto_in_0_aw_bits_size,
  input  [1:0]  auto_in_0_aw_bits_burst,
  input         auto_in_0_aw_bits_lock,
  input  [3:0]  auto_in_0_aw_bits_cache,
  input  [2:0]  auto_in_0_aw_bits_prot,
  input  [3:0]  auto_in_0_aw_bits_qos,
  output        auto_in_0_w_ready,
  input         auto_in_0_w_valid,
  input  [63:0] auto_in_0_w_bits_data,
  input  [7:0]  auto_in_0_w_bits_strb,
  input         auto_in_0_w_bits_last,
  input         auto_in_0_b_ready,
  output        auto_in_0_b_valid,
  output        auto_in_0_b_bits_id,
  output [1:0]  auto_in_0_b_bits_resp,
  input         auto_in_0_ar_valid,
  input         auto_in_0_ar_bits_id,
  input  [7:0]  auto_in_0_ar_bits_len,
  input  [2:0]  auto_in_0_ar_bits_size,
  input  [1:0]  auto_in_0_ar_bits_burst,
  input         auto_in_0_ar_bits_lock,
  input  [3:0]  auto_in_0_ar_bits_cache,
  input  [3:0]  auto_in_0_ar_bits_qos,
  input         auto_in_0_r_ready,
  output        auto_in_0_r_valid,
  output        auto_in_0_r_bits_id,
  output        auto_in_0_r_bits_last
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
`endif // RANDOMIZE_REG_INIT
  wire  fb_clock; // @[AXI4VGA.scala 115:30]
  wire  fb_reset; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_aw_ready; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_aw_valid; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_aw_bits_id; // @[AXI4VGA.scala 115:30]
  wire [30:0] fb_auto_in_aw_bits_addr; // @[AXI4VGA.scala 115:30]
  wire [7:0] fb_auto_in_aw_bits_len; // @[AXI4VGA.scala 115:30]
  wire [2:0] fb_auto_in_aw_bits_size; // @[AXI4VGA.scala 115:30]
  wire [1:0] fb_auto_in_aw_bits_burst; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_aw_bits_lock; // @[AXI4VGA.scala 115:30]
  wire [3:0] fb_auto_in_aw_bits_cache; // @[AXI4VGA.scala 115:30]
  wire [2:0] fb_auto_in_aw_bits_prot; // @[AXI4VGA.scala 115:30]
  wire [3:0] fb_auto_in_aw_bits_qos; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_w_ready; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_w_valid; // @[AXI4VGA.scala 115:30]
  wire [63:0] fb_auto_in_w_bits_data; // @[AXI4VGA.scala 115:30]
  wire [7:0] fb_auto_in_w_bits_strb; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_w_bits_last; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_b_ready; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_b_valid; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_b_bits_id; // @[AXI4VGA.scala 115:30]
  wire [1:0] fb_auto_in_b_bits_resp; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_ar_valid; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_ar_bits_id; // @[AXI4VGA.scala 115:30]
  wire [30:0] fb_auto_in_ar_bits_addr; // @[AXI4VGA.scala 115:30]
  wire [7:0] fb_auto_in_ar_bits_len; // @[AXI4VGA.scala 115:30]
  wire [2:0] fb_auto_in_ar_bits_size; // @[AXI4VGA.scala 115:30]
  wire [1:0] fb_auto_in_ar_bits_burst; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_ar_bits_lock; // @[AXI4VGA.scala 115:30]
  wire [3:0] fb_auto_in_ar_bits_cache; // @[AXI4VGA.scala 115:30]
  wire [3:0] fb_auto_in_ar_bits_qos; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_r_bits_id; // @[AXI4VGA.scala 115:30]
  wire  fb_auto_in_r_bits_last; // @[AXI4VGA.scala 115:30]
  wire  ctrl_clock; // @[AXI4VGA.scala 121:32]
  wire  ctrl_reset; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_aw_ready; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_aw_valid; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_aw_bits_id; // @[AXI4VGA.scala 121:32]
  wire [30:0] ctrl_auto_in_aw_bits_addr; // @[AXI4VGA.scala 121:32]
  wire [7:0] ctrl_auto_in_aw_bits_len; // @[AXI4VGA.scala 121:32]
  wire [2:0] ctrl_auto_in_aw_bits_size; // @[AXI4VGA.scala 121:32]
  wire [1:0] ctrl_auto_in_aw_bits_burst; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_aw_bits_lock; // @[AXI4VGA.scala 121:32]
  wire [3:0] ctrl_auto_in_aw_bits_cache; // @[AXI4VGA.scala 121:32]
  wire [2:0] ctrl_auto_in_aw_bits_prot; // @[AXI4VGA.scala 121:32]
  wire [3:0] ctrl_auto_in_aw_bits_qos; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_w_ready; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_w_valid; // @[AXI4VGA.scala 121:32]
  wire [63:0] ctrl_auto_in_w_bits_data; // @[AXI4VGA.scala 121:32]
  wire [7:0] ctrl_auto_in_w_bits_strb; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_w_bits_last; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_b_ready; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_b_valid; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_b_bits_id; // @[AXI4VGA.scala 121:32]
  wire [1:0] ctrl_auto_in_b_bits_resp; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_ar_ready; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_ar_valid; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_ar_bits_id; // @[AXI4VGA.scala 121:32]
  wire [30:0] ctrl_auto_in_ar_bits_addr; // @[AXI4VGA.scala 121:32]
  wire [7:0] ctrl_auto_in_ar_bits_len; // @[AXI4VGA.scala 121:32]
  wire [2:0] ctrl_auto_in_ar_bits_size; // @[AXI4VGA.scala 121:32]
  wire [1:0] ctrl_auto_in_ar_bits_burst; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_ar_bits_lock; // @[AXI4VGA.scala 121:32]
  wire [3:0] ctrl_auto_in_ar_bits_cache; // @[AXI4VGA.scala 121:32]
  wire [2:0] ctrl_auto_in_ar_bits_prot; // @[AXI4VGA.scala 121:32]
  wire [3:0] ctrl_auto_in_ar_bits_qos; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_r_ready; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_r_valid; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_r_bits_id; // @[AXI4VGA.scala 121:32]
  wire [63:0] ctrl_auto_in_r_bits_data; // @[AXI4VGA.scala 121:32]
  wire [1:0] ctrl_auto_in_r_bits_resp; // @[AXI4VGA.scala 121:32]
  wire  ctrl_auto_in_r_bits_last; // @[AXI4VGA.scala 121:32]
  reg  REG; // @[StopWatch.scala 7:20]
  wire  _T_1 = auto_in_0_r_ready & REG; // @[Decoupled.scala 40:37]
  wire  _GEN_0 = _T_1 ? 1'h0 : REG; // @[StopWatch.scala 9:19 StopWatch.scala 9:23 StopWatch.scala 7:20]
  wire  _GEN_1 = auto_in_0_ar_valid | _GEN_0; // @[StopWatch.scala 10:20 StopWatch.scala 10:24]
  reg [10:0] hCounter; // @[Counter.scala 60:40]
  wire  wrap_wrap = hCounter == 11'h41f; // @[Counter.scala 72:24]
  wire [10:0] _wrap_value_T_1 = hCounter + 11'h1; // @[Counter.scala 76:24]
  reg [9:0] vCounter; // @[Counter.scala 60:40]
  wire  wrap_wrap_1 = vCounter == 10'h273; // @[Counter.scala 72:24]
  wire [9:0] _wrap_value_T_3 = vCounter + 10'h1; // @[Counter.scala 76:24]
  wire  vInRange = vCounter >= 10'h5 & vCounter < 10'h25d; // @[AXI4VGA.scala 144:65]
  wire  hCounterIsOdd = hCounter[0]; // @[AXI4VGA.scala 155:33]
  wire  hCounterIs2 = hCounter[1:0] == 2'h2; // @[AXI4VGA.scala 156:38]
  wire  vCounterIsOdd = vCounter[0]; // @[AXI4VGA.scala 157:33]
  wire  _T_12 = hCounter >= 11'ha7 & hCounter < 11'h3c7; // @[AXI4VGA.scala 144:65]
  wire  nextPixel = _T_12 & vInRange & hCounterIsOdd; // @[AXI4VGA.scala 160:80]
  wire  _T_15 = nextPixel & ~vCounterIsOdd; // @[AXI4VGA.scala 161:43]
  reg [16:0] fbPixelAddrV0; // @[Counter.scala 60:40]
  wire  wrap_wrap_2 = fbPixelAddrV0 == 17'h1d4bf; // @[Counter.scala 72:24]
  wire [16:0] _wrap_value_T_5 = fbPixelAddrV0 + 17'h1; // @[Counter.scala 76:24]
  wire  _T_16 = nextPixel & vCounterIsOdd; // @[AXI4VGA.scala 162:43]
  reg [16:0] fbPixelAddrV1; // @[Counter.scala 60:40]
  wire  wrap_wrap_3 = fbPixelAddrV1 == 17'h1d4bf; // @[Counter.scala 72:24]
  wire [16:0] _wrap_value_T_7 = fbPixelAddrV1 + 17'h1; // @[Counter.scala 76:24]
  wire [16:0] hi = vCounterIsOdd ? fbPixelAddrV1 : fbPixelAddrV0; // @[AXI4VGA.scala 166:35]
  wire [18:0] _T_17 = {hi,2'h0}; // @[Cat.scala 30:58]
  reg  REG_1; // @[AXI4VGA.scala 167:31]
  AXI4RAM_1 fb ( // @[AXI4VGA.scala 115:30]
    .clock(fb_clock),
    .reset(fb_reset),
    .auto_in_aw_ready(fb_auto_in_aw_ready),
    .auto_in_aw_valid(fb_auto_in_aw_valid),
    .auto_in_aw_bits_id(fb_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(fb_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(fb_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(fb_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(fb_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(fb_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(fb_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(fb_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(fb_auto_in_aw_bits_qos),
    .auto_in_w_ready(fb_auto_in_w_ready),
    .auto_in_w_valid(fb_auto_in_w_valid),
    .auto_in_w_bits_data(fb_auto_in_w_bits_data),
    .auto_in_w_bits_strb(fb_auto_in_w_bits_strb),
    .auto_in_w_bits_last(fb_auto_in_w_bits_last),
    .auto_in_b_ready(fb_auto_in_b_ready),
    .auto_in_b_valid(fb_auto_in_b_valid),
    .auto_in_b_bits_id(fb_auto_in_b_bits_id),
    .auto_in_b_bits_resp(fb_auto_in_b_bits_resp),
    .auto_in_ar_valid(fb_auto_in_ar_valid),
    .auto_in_ar_bits_id(fb_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(fb_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(fb_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(fb_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(fb_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(fb_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(fb_auto_in_ar_bits_cache),
    .auto_in_ar_bits_qos(fb_auto_in_ar_bits_qos),
    .auto_in_r_bits_id(fb_auto_in_r_bits_id),
    .auto_in_r_bits_last(fb_auto_in_r_bits_last)
  );
  VGACtrl ctrl ( // @[AXI4VGA.scala 121:32]
    .clock(ctrl_clock),
    .reset(ctrl_reset),
    .auto_in_aw_ready(ctrl_auto_in_aw_ready),
    .auto_in_aw_valid(ctrl_auto_in_aw_valid),
    .auto_in_aw_bits_id(ctrl_auto_in_aw_bits_id),
    .auto_in_aw_bits_addr(ctrl_auto_in_aw_bits_addr),
    .auto_in_aw_bits_len(ctrl_auto_in_aw_bits_len),
    .auto_in_aw_bits_size(ctrl_auto_in_aw_bits_size),
    .auto_in_aw_bits_burst(ctrl_auto_in_aw_bits_burst),
    .auto_in_aw_bits_lock(ctrl_auto_in_aw_bits_lock),
    .auto_in_aw_bits_cache(ctrl_auto_in_aw_bits_cache),
    .auto_in_aw_bits_prot(ctrl_auto_in_aw_bits_prot),
    .auto_in_aw_bits_qos(ctrl_auto_in_aw_bits_qos),
    .auto_in_w_ready(ctrl_auto_in_w_ready),
    .auto_in_w_valid(ctrl_auto_in_w_valid),
    .auto_in_w_bits_data(ctrl_auto_in_w_bits_data),
    .auto_in_w_bits_strb(ctrl_auto_in_w_bits_strb),
    .auto_in_w_bits_last(ctrl_auto_in_w_bits_last),
    .auto_in_b_ready(ctrl_auto_in_b_ready),
    .auto_in_b_valid(ctrl_auto_in_b_valid),
    .auto_in_b_bits_id(ctrl_auto_in_b_bits_id),
    .auto_in_b_bits_resp(ctrl_auto_in_b_bits_resp),
    .auto_in_ar_ready(ctrl_auto_in_ar_ready),
    .auto_in_ar_valid(ctrl_auto_in_ar_valid),
    .auto_in_ar_bits_id(ctrl_auto_in_ar_bits_id),
    .auto_in_ar_bits_addr(ctrl_auto_in_ar_bits_addr),
    .auto_in_ar_bits_len(ctrl_auto_in_ar_bits_len),
    .auto_in_ar_bits_size(ctrl_auto_in_ar_bits_size),
    .auto_in_ar_bits_burst(ctrl_auto_in_ar_bits_burst),
    .auto_in_ar_bits_lock(ctrl_auto_in_ar_bits_lock),
    .auto_in_ar_bits_cache(ctrl_auto_in_ar_bits_cache),
    .auto_in_ar_bits_prot(ctrl_auto_in_ar_bits_prot),
    .auto_in_ar_bits_qos(ctrl_auto_in_ar_bits_qos),
    .auto_in_r_ready(ctrl_auto_in_r_ready),
    .auto_in_r_valid(ctrl_auto_in_r_valid),
    .auto_in_r_bits_id(ctrl_auto_in_r_bits_id),
    .auto_in_r_bits_data(ctrl_auto_in_r_bits_data),
    .auto_in_r_bits_resp(ctrl_auto_in_r_bits_resp),
    .auto_in_r_bits_last(ctrl_auto_in_r_bits_last)
  );
  assign auto_in_1_aw_ready = ctrl_auto_in_aw_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_w_ready = ctrl_auto_in_w_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_b_valid = ctrl_auto_in_b_valid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_b_bits_id = ctrl_auto_in_b_bits_id; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_b_bits_resp = ctrl_auto_in_b_bits_resp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_ar_ready = ctrl_auto_in_ar_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_r_valid = ctrl_auto_in_r_valid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_r_bits_id = ctrl_auto_in_r_bits_id; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_r_bits_data = ctrl_auto_in_r_bits_data; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_r_bits_resp = ctrl_auto_in_r_bits_resp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_1_r_bits_last = ctrl_auto_in_r_bits_last; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_aw_ready = fb_auto_in_aw_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_w_ready = fb_auto_in_w_ready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_b_valid = fb_auto_in_b_valid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_b_bits_id = fb_auto_in_b_bits_id; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_b_bits_resp = fb_auto_in_b_bits_resp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_r_valid = REG; // @[Nodes.scala 1210:84 AXI4VGA.scala 142:19]
  assign auto_in_0_r_bits_id = fb_auto_in_r_bits_id; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign auto_in_0_r_bits_last = fb_auto_in_r_bits_last; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign fb_clock = clock;
  assign fb_reset = reset;
  assign fb_auto_in_aw_valid = auto_in_0_aw_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_id = auto_in_0_aw_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_addr = auto_in_0_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_len = auto_in_0_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_size = auto_in_0_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_burst = auto_in_0_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_lock = auto_in_0_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_cache = auto_in_0_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_prot = auto_in_0_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_aw_bits_qos = auto_in_0_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_w_valid = auto_in_0_w_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_w_bits_data = auto_in_0_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_w_bits_strb = auto_in_0_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_w_bits_last = auto_in_0_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_b_ready = auto_in_0_b_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_valid = REG_1 & hCounterIs2; // @[AXI4VGA.scala 167:43]
  assign fb_auto_in_ar_bits_id = auto_in_0_ar_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_bits_addr = {{12'd0}, _T_17}; // @[Nodes.scala 1207:84 AXI4VGA.scala 166:25]
  assign fb_auto_in_ar_bits_len = auto_in_0_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_bits_size = auto_in_0_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_bits_burst = auto_in_0_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_bits_lock = auto_in_0_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_bits_cache = auto_in_0_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign fb_auto_in_ar_bits_qos = auto_in_0_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_clock = clock;
  assign ctrl_reset = reset;
  assign ctrl_auto_in_aw_valid = auto_in_1_aw_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_id = auto_in_1_aw_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_addr = auto_in_1_aw_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_len = auto_in_1_aw_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_size = auto_in_1_aw_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_burst = auto_in_1_aw_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_lock = auto_in_1_aw_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_cache = auto_in_1_aw_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_prot = auto_in_1_aw_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_aw_bits_qos = auto_in_1_aw_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_w_valid = auto_in_1_w_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_w_bits_data = auto_in_1_w_bits_data; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_w_bits_strb = auto_in_1_w_bits_strb; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_w_bits_last = auto_in_1_w_bits_last; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_b_ready = auto_in_1_b_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_valid = auto_in_1_ar_valid; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_id = auto_in_1_ar_bits_id; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_addr = auto_in_1_ar_bits_addr; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_len = auto_in_1_ar_bits_len; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_size = auto_in_1_ar_bits_size; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_burst = auto_in_1_ar_bits_burst; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_lock = auto_in_1_ar_bits_lock; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_cache = auto_in_1_ar_bits_cache; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_prot = auto_in_1_ar_bits_prot; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_ar_bits_qos = auto_in_1_ar_bits_qos; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  assign ctrl_auto_in_r_ready = auto_in_1_r_ready; // @[Nodes.scala 1210:84 LazyModule.scala 309:16]
  always @(posedge clock) begin
    if (reset) begin // @[StopWatch.scala 7:20]
      REG <= 1'h0; // @[StopWatch.scala 7:20]
    end else begin
      REG <= _GEN_1;
    end
    if (reset) begin // @[Counter.scala 60:40]
      hCounter <= 11'h0; // @[Counter.scala 60:40]
    end else if (wrap_wrap) begin // @[Counter.scala 86:20]
      hCounter <= 11'h0; // @[Counter.scala 86:28]
    end else begin
      hCounter <= _wrap_value_T_1; // @[Counter.scala 76:15]
    end
    if (reset) begin // @[Counter.scala 60:40]
      vCounter <= 10'h0; // @[Counter.scala 60:40]
    end else if (wrap_wrap) begin // @[Counter.scala 118:17]
      if (wrap_wrap_1) begin // @[Counter.scala 86:20]
        vCounter <= 10'h0; // @[Counter.scala 86:28]
      end else begin
        vCounter <= _wrap_value_T_3; // @[Counter.scala 76:15]
      end
    end
    if (reset) begin // @[Counter.scala 60:40]
      fbPixelAddrV0 <= 17'h0; // @[Counter.scala 60:40]
    end else if (_T_15) begin // @[Counter.scala 118:17]
      if (wrap_wrap_2) begin // @[Counter.scala 86:20]
        fbPixelAddrV0 <= 17'h0; // @[Counter.scala 86:28]
      end else begin
        fbPixelAddrV0 <= _wrap_value_T_5; // @[Counter.scala 76:15]
      end
    end
    if (reset) begin // @[Counter.scala 60:40]
      fbPixelAddrV1 <= 17'h0; // @[Counter.scala 60:40]
    end else if (_T_16) begin // @[Counter.scala 118:17]
      if (wrap_wrap_3) begin // @[Counter.scala 86:20]
        fbPixelAddrV1 <= 17'h0; // @[Counter.scala 86:28]
      end else begin
        fbPixelAddrV1 <= _wrap_value_T_7; // @[Counter.scala 76:15]
      end
    end
    REG_1 <= _T_12 & vInRange & hCounterIsOdd; // @[AXI4VGA.scala 160:80]
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
  REG = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  hCounter = _RAND_1[10:0];
  _RAND_2 = {1{`RANDOM}};
  vCounter = _RAND_2[9:0];
  _RAND_3 = {1{`RANDOM}};
  fbPixelAddrV0 = _RAND_3[16:0];
  _RAND_4 = {1{`RANDOM}};
  fbPixelAddrV1 = _RAND_4[16:0];
  _RAND_5 = {1{`RANDOM}};
  REG_1 = _RAND_5[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
