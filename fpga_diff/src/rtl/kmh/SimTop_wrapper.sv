`ifndef NO_DIFF
`include "DifftestMacros.svh"
`endif
`include "sys_define.vh"

`ifdef NO_DIFF
`define TOP_NAME XSTop
`define MEM_PREFIX memory
`else
`define TOP_NAME SimTop
`define MEM_PREFIX difftest_mem
`endif
`define MEM_PORT_(prefix, name) .prefix``_``name
`define MEM_PORT(prefix, name) `MEM_PORT_(prefix, name)

module SimTop_wrapper(
  input           inter_soc_clk,
  input           sys_rstn_i,
  input           tmclk,

  input           global_reset,     //24MHz

  input  [3:0]    pll_bypass_sel,   //apb clk : 100MHz
  output          pll0_lock,
  output          pll0_clk_div_1024,
  output [11:0]   pll0_test_calout,

  input  [15:0]   soc_to_cpu,   // none
  output [15:0]   cpu_to_soc,   //none

  input  [63:0]   io_extIntrs,   // come from IPs, Max : 600MHz

  input  [15:0]   io_sram_config,  //apb clk : 100MHz

  input           io_systemjtag_jtag_TCK,         // come from gpio
  input           io_systemjtag_jtag_TMS,         // come from gpio
  input           io_systemjtag_jtag_TDI,         // come from gpio
  output          io_systemjtag_jtag_TDO_data,    // come from gpio
  output          io_systemjtag_jtag_TDO_driven,  // come from gpio
  input           io_systemjtag_reset,            // come from gpio

// peri bus   //400MHz
// dma bus    //800MHz
// mem bus    //800MHz

  (*mark_debug="true"*) output          dma_core_awready,
  (*mark_debug="true"*) input           dma_core_awvalid,
  (*mark_debug="true"*) input  [13:0]   dma_core_awid,
  (*mark_debug="true"*) input  [35:0]   dma_core_awaddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_awlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_awsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_awburst,
  (*mark_debug="true"*) input           dma_core_awlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_awcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_awprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_awqos,
  (*mark_debug="true"*) output          dma_core_wready,
  (*mark_debug="true"*) input           dma_core_wvalid,
  (*mark_debug="true"*) input  [255:0]  dma_core_wdata,
  (*mark_debug="true"*) input  [31:0]   dma_core_wstrb,
  (*mark_debug="true"*) input           dma_core_wlast,
  (*mark_debug="true"*) input           dma_core_bready,
  (*mark_debug="true"*) output          dma_core_bvalid,
  (*mark_debug="true"*) output [13:0]   dma_core_bid,
  (*mark_debug="true"*) output [1:0]    dma_core_bresp,
  (*mark_debug="true"*) output          dma_core_arready,
  (*mark_debug="true"*) input           dma_core_arvalid,
  (*mark_debug="true"*) input  [13:0]   dma_core_arid,
  (*mark_debug="true"*) input  [35:0]   dma_core_araddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_arlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_arsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_arburst,
  (*mark_debug="true"*) input           dma_core_arlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_arcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_arprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_arqos,
  (*mark_debug="true"*) input           dma_core_rready,
  (*mark_debug="true"*) output          dma_core_rvalid,
  (*mark_debug="true"*) output [13:0]   dma_core_rid,
  (*mark_debug="true"*) output [255:0]  dma_core_rdata,
  (*mark_debug="true"*) output [1:0]    dma_core_rresp,
  (*mark_debug="true"*) output          dma_core_rlast,

  (*mark_debug="true"*) input           peri_awready,
  (*mark_debug="true"*) output          peri_awvalid,
  (*mark_debug="true"*) output [1:0]    peri_awid,
  (*mark_debug="true"*) output [30:0]   peri_awaddr,
  (*mark_debug="true"*) output [7:0]    peri_awlen,
  (*mark_debug="true"*) output [2:0]    peri_awsize,
  (*mark_debug="true"*) output [1:0]    peri_awburst,
  (*mark_debug="true"*) output          peri_awlock,
  (*mark_debug="true"*) output [3:0]    peri_awcache,
  (*mark_debug="true"*) output [2:0]    peri_awprot,
  (*mark_debug="true"*) output [3:0]    peri_awqos,
  (*mark_debug="true"*) input           peri_wready,
  (*mark_debug="true"*) output          peri_wvalid,
  (*mark_debug="true"*) output [63:0]   peri_wdata,
  (*mark_debug="true"*) output [7:0]    peri_wstrb,
  (*mark_debug="true"*) output          peri_wlast,
  (*mark_debug="true"*) output          peri_bready,
  (*mark_debug="true"*) input           peri_bvalid,
  (*mark_debug="true"*) input  [1:0]    peri_bid,
  (*mark_debug="true"*) input  [1:0]    peri_bresp,
  (*mark_debug="true"*) input           peri_arready,
  (*mark_debug="true"*) output          peri_arvalid,
  (*mark_debug="true"*) output [1:0]    peri_arid,
  (*mark_debug="true"*) output [30:0]   peri_araddr,
  (*mark_debug="true"*) output [7:0]    peri_arlen,
  (*mark_debug="true"*) output [2:0]    peri_arsize,
  (*mark_debug="true"*) output [1:0]    peri_arburst,
  (*mark_debug="true"*) output          peri_arlock,
  (*mark_debug="true"*) output [3:0]    peri_arcache,
  (*mark_debug="true"*) output [2:0]    peri_arprot,
  (*mark_debug="true"*) output [3:0]    peri_arqos,
  (*mark_debug="true"*) output          peri_rready,
  (*mark_debug="true"*) input           peri_rvalid,
  (*mark_debug="true"*) input  [1:0]    peri_rid,
  (*mark_debug="true"*) input  [63:0]   peri_rdata,
  (*mark_debug="true"*) input  [1:0]    peri_rresp,
  (*mark_debug="true"*) input           peri_rlast,

  (*mark_debug="true"*) input           mem_core_awready,
  (*mark_debug="true"*) output          mem_core_awvalid,
  (*mark_debug="true"*) output [13:0]   mem_core_awid,
  (*mark_debug="true"*) output [35:0]   mem_core_awaddr,
  (*mark_debug="true"*) output [7:0]    mem_core_awlen,
  (*mark_debug="true"*) output [2:0]    mem_core_awsize,
  (*mark_debug="true"*) output [1:0]    mem_core_awburst,
  (*mark_debug="true"*) output          mem_core_awlock,
  (*mark_debug="true"*) output [3:0]    mem_core_awcache,
  (*mark_debug="true"*) output [2:0]    mem_core_awprot,
  (*mark_debug="true"*) output [3:0]    mem_core_awqos,
  (*mark_debug="true"*) input           mem_core_wready,
  (*mark_debug="true"*) output          mem_core_wvalid,
  (*mark_debug="true"*) output [255:0]  mem_core_wdata,
  (*mark_debug="true"*) output [31:0]   mem_core_wstrb,
  (*mark_debug="true"*) output          mem_core_wlast,
  (*mark_debug="true"*) output          mem_core_bready,
  (*mark_debug="true"*) input           mem_core_bvalid,
  (*mark_debug="true"*) input  [13:0]   mem_core_bid,
  (*mark_debug="true"*) input  [1:0]    mem_core_bresp,
  (*mark_debug="true"*) input           mem_core_arready,
  (*mark_debug="true"*) output          mem_core_arvalid,
  (*mark_debug="true"*) output [13:0]   mem_core_arid,
  (*mark_debug="true"*) output [35:0]   mem_core_araddr,
  (*mark_debug="true"*) output [7:0]    mem_core_arlen,
  (*mark_debug="true"*) output [2:0]    mem_core_arsize,
  (*mark_debug="true"*) output [1:0]    mem_core_arburst,
  (*mark_debug="true"*) output          mem_core_arlock,
  (*mark_debug="true"*) output [3:0]    mem_core_arcache,
  (*mark_debug="true"*) output [2:0]    mem_core_arprot,
  (*mark_debug="true"*) output [3:0]    mem_core_arqos,
  (*mark_debug="true"*) output          mem_core_rready,
  (*mark_debug="true"*) input           mem_core_rvalid,
  (*mark_debug="true"*) input  [13:0]   mem_core_rid,
  (*mark_debug="true"*) input  [255:0]  mem_core_rdata,
  (*mark_debug="true"*) input  [1:0]    mem_core_rresp,
  (*mark_debug="true"*) input           mem_core_rlast,

`ifdef CONFIG_USE_IMSIC
  output                                io_imsic_awready[`CONFIG_XSCORE_NR-1:0],
  input                                 io_imsic_awvalid[`CONFIG_XSCORE_NR-1:0],
  input  [4:0]                          io_imsic_awid[`CONFIG_XSCORE_NR-1:0],
  input  [31:0]                         io_imsic_awaddr[`CONFIG_XSCORE_NR-1:0],
  output                                io_imsic_wready[`CONFIG_XSCORE_NR-1:0],
  input                                 io_imsic_wvalid[`CONFIG_XSCORE_NR-1:0],
  input  [31:0]                         io_imsic_wdata[`CONFIG_XSCORE_NR-1:0],
  input                                 io_imsic_bready[`CONFIG_XSCORE_NR-1:0],
  output                                io_imsic_bvalid[`CONFIG_XSCORE_NR-1:0],
  output [4:0]                          io_imsic_bid[`CONFIG_XSCORE_NR-1:0],
  output [1:0]                          io_imsic_bresp[`CONFIG_XSCORE_NR-1:0],
  output                                io_imsic_arready[`CONFIG_XSCORE_NR-1:0],
  input                                 io_imsic_arvalid[`CONFIG_XSCORE_NR-1:0],
  input  [4:0]                          io_imsic_arid[`CONFIG_XSCORE_NR-1:0],
  input  [31:0]                         io_imsic_araddr[`CONFIG_XSCORE_NR-1:0],
  input                                 io_imsic_rready[`CONFIG_XSCORE_NR-1:0],
  output                                io_imsic_rvalid[`CONFIG_XSCORE_NR-1:0],
  output [4:0]                          io_imsic_rid[`CONFIG_XSCORE_NR-1:0],
  output [31:0]                         io_imsic_rdata[`CONFIG_XSCORE_NR-1:0],
  output [1:0]                          io_imsic_rresp[`CONFIG_XSCORE_NR-1:0],
`endif /* CONFIG_USE_IMSIC */
  input [1:0]     memory_0_rresp,
  input           memory_0_rlast,
  input           io_clock,
  input           io_reset,
  input           io_pll0_lock,
  output [31:0]   io_pll0_ctrl_0,
  output [31:0]   io_pll0_ctrl_1,
  output [31:0]   io_pll0_ctrl_2,
  output [31:0]   io_pll0_ctrl_3,
  output [31:0]   io_pll0_ctrl_4,
  output [31:0]   io_pll0_ctrl_5,
  input [10:0]    io_systemjtag_mfr_id,
  input [15:0]    io_systemjtag_part_number,
  input [3:0]     io_systemjtag_version,
  output          io_debug_reset,
  output          io_riscv_halt_0,
  output          io_riscv_halt_1
`ifndef NO_DIFF
  ,
  input           difftest_ref_clock,
  input           difftest_ref_reset,
  input           difftest_pcie_clock,
  input           difftest_to_host_axis_tready,
  output          difftest_to_host_axis_tvalid,
  output [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_to_host_axis_tdata,
  output [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_to_host_axis_tkeep,
  output          difftest_to_host_axis_tlast,
  output          difftest_from_host_axis_tready,
  input           difftest_from_host_axis_tvalid,
  input  [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_from_host_axis_tdata,
  input  [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_from_host_axis_tkeep,
  input           difftest_from_host_axis_tlast,
  output          difftest_clock_enable,
  output          difftest_hostCtrl_reset,
  output          difftest_hostCtrl_diffEnable,
  output          difftest_hostCtrl_ilaTrigger,
  input  [31:0]   difftest_cfg_axilite_awaddr,
  input           difftest_cfg_axilite_awvalid,
  output          difftest_cfg_axilite_awready,
  input  [31:0]   difftest_cfg_axilite_wdata,
  input  [3:0]    difftest_cfg_axilite_wstrb,
  input           difftest_cfg_axilite_wvalid,
  output          difftest_cfg_axilite_wready,
  output [1:0]    difftest_cfg_axilite_bresp,
  output          difftest_cfg_axilite_bvalid,
  input           difftest_cfg_axilite_bready,
  input  [31:0]   difftest_cfg_axilite_araddr,
  input           difftest_cfg_axilite_arvalid,
  output          difftest_cfg_axilite_arready,
  output [31:0]   difftest_cfg_axilite_rdata,
  output [1:0]    difftest_cfg_axilite_rresp,
  output          difftest_cfg_axilite_rvalid,
  input           difftest_cfg_axilite_rready
`endif
);

  wire          cpu_clock       ;
  wire          cpu_global_reset;
  wire          global_reset_sync;

  wire [31:0]   pll0_config_0;
  wire [31:0]   pll0_config_1;
  wire [31:0]   pll0_config_2;
  wire [31:0]   pll0_config_3;
  wire [31:0]   pll0_config_4;
  wire [31:0]   pll0_config_5;

assign cpu_to_soc = 32'h0;

// Internal tie-offs / local wires for XSTop new ports (keep wrapper external interface stable)
wire nmi_0_0 = 1'b0;
wire nmi_0_1 = 1'b0;
// PLL: use existing wrapper outputs to reflect inner registers directly
// XSTop provides ctrl outputs; connect them directly (no intermediate *_int wires needed)
wire io_debug_reset_int;
wire io_riscv_critical_error_0_int;
// Trace interface (ignored internally)
wire trace_en   = 1'b0;
wire trace_stall= 1'b0;
wire [63:0]  trace_cause;
wire [49:0]  trace_tval;
wire [2:0]   trace_priv;
wire [149:0] trace_iaddr;
wire [11:0]  trace_itype;
wire [20:0]  trace_iretire;
wire [2:0]   trace_ilastsize;

`ifndef CONFIG_SIMTOP_HAS_DMA
assign dma_core_awready = 1'b0;
assign dma_core_wready  = 1'b0;
assign dma_core_bvalid  = 1'b0;
assign dma_core_bid     = '0;
assign dma_core_bresp   = '0;
assign dma_core_arready = 1'b0;
assign dma_core_rvalid  = 1'b0;
assign dma_core_rid     = '0;
assign dma_core_rdata   = '0;
assign dma_core_rresp   = '0;
assign dma_core_rlast   = 1'b0;
`endif

`TOP_NAME u_XSTop(
`ifdef NO_DIFF
  .io_clock                      (inter_soc_clk),
  .io_reset                      (~sys_rstn_i),
`else
  .clock                         (inter_soc_clk),
  .reset                         (~sys_rstn_i),
`endif

  .nmi_0_0                       (nmi_0_0),
  .nmi_0_1                       (nmi_0_1),

  .peripheral_awready            (peri_awready  ),
  .peripheral_awvalid            (peri_awvalid  ),
  .peripheral_awid               (peri_awid     ),
  .peripheral_awaddr             ({16'd0, peri_awaddr}),
  .peripheral_awlen              (peri_awlen    ),
  .peripheral_awsize             (peri_awsize   ),
  .peripheral_awburst            (peri_awburst  ),
  .peripheral_awlock             (peri_awlock   ),
  .peripheral_awcache            (peri_awcache  ),
  .peripheral_awprot             (peri_awprot   ),
  .peripheral_awqos              (peri_awqos    ),
  .peripheral_wready             (peri_wready   ),
  .peripheral_wvalid             (peri_wvalid   ),
  .peripheral_wdata              (peri_wdata    ),
  .peripheral_wstrb              (peri_wstrb    ),
  .peripheral_wlast              (peri_wlast    ),
  .peripheral_bready             (peri_bready   ),
  .peripheral_bvalid             (peri_bvalid   ),
  .peripheral_bid                (peri_bid      ),
  .peripheral_bresp              (peri_bresp    ),
  .peripheral_arready            (peri_arready  ),
  .peripheral_arvalid            (peri_arvalid  ),
  .peripheral_arid               (peri_arid     ),
  .peripheral_araddr             ({16'd0, peri_araddr}),
  .peripheral_arlen              (peri_arlen    ),
  .peripheral_arsize             (peri_arsize   ),
  .peripheral_arburst            (peri_arburst  ),
  .peripheral_arlock             (peri_arlock   ),
  .peripheral_arcache            (peri_arcache  ),
  .peripheral_arprot             (peri_arprot   ),
  .peripheral_arqos              (peri_arqos    ),
  .peripheral_rready             (peri_rready   ),
  .peripheral_rvalid             (peri_rvalid   ),
  .peripheral_rid                (peri_rid      ),
  .peripheral_rdata              (peri_rdata    ),
  .peripheral_rresp              (peri_rresp    ),
  .peripheral_rlast              (peri_rlast    ),
`ifdef CONFIG_SIMTOP_HAS_DMA
  .dma_awready                   (dma_core_awready ),
  .dma_awvalid                   (dma_core_awvalid ),
  .dma_awid                      (dma_core_awid    ),
  .dma_awaddr                    (dma_core_awaddr[35:0]  ),
  .dma_awlen                     (dma_core_awlen   ),
  .dma_awsize                    (dma_core_awsize  ),
  .dma_awburst                   (dma_core_awburst ),
  .dma_awlock                    (dma_core_awlock  ),
  .dma_awcache                   (dma_core_awcache ),
  .dma_awprot                    (dma_core_awprot  ),
  .dma_awqos                     (dma_core_awqos   ),
  .dma_wready                    (dma_core_wready  ),
  .dma_wvalid                    (dma_core_wvalid  ),
  .dma_wdata                     (dma_core_wdata   ),
  .dma_wstrb                     (dma_core_wstrb   ),
  .dma_wlast                     (dma_core_wlast   ),
  .dma_bready                    (dma_core_bready  ),
  .dma_bvalid                    (dma_core_bvalid  ),
  .dma_bid                       (dma_core_bid     ),
  .dma_bresp                     (dma_core_bresp   ),
  .dma_arready                   (dma_core_arready ),
  .dma_arvalid                   (dma_core_arvalid ),
  .dma_arid                      (dma_core_arid    ),
  .dma_araddr                    (dma_core_araddr[35:0]  ),
  .dma_arlen                     (dma_core_arlen   ),
  .dma_arsize                    (dma_core_arsize  ),
  .dma_arburst                   (dma_core_arburst ),
  .dma_arlock                    (dma_core_arlock  ),
  .dma_arcache                   (dma_core_arcache ),
  .dma_arprot                    (dma_core_arprot  ),
  .dma_arqos                     (dma_core_arqos   ),
  .dma_rready                    (dma_core_rready  ),
  .dma_rvalid                    (dma_core_rvalid  ),
  .dma_rid                       (dma_core_rid     ),
  .dma_rdata                     (dma_core_rdata   ),
  .dma_rresp                     (dma_core_rresp   ),
  .dma_rlast                     (dma_core_rlast   ),
`endif
  .io_systemjtag_jtag_TCK          (io_systemjtag_jtag_TCK),
  .io_systemjtag_jtag_TMS          (io_systemjtag_jtag_TMS),
  .io_systemjtag_jtag_TDI          (io_systemjtag_jtag_TDI),
  .io_systemjtag_jtag_TDO_data     (io_systemjtag_jtag_TDO_data),
  .io_systemjtag_jtag_TDO_driven   (io_systemjtag_jtag_TDO_driven),
  .io_systemjtag_reset             (io_systemjtag_reset),
  .io_systemjtag_mfr_id            (11'h11),
  .io_systemjtag_part_number       (16'h16),
  .io_systemjtag_version           (4'h4),
  .io_debug_reset                  (io_debug_reset_int),


  .io_sram_config                  (io_sram_config),
  .io_pll0_lock                    (pll0_lock),
  .io_pll0_ctrl_0                  (io_pll0_ctrl_0),
  .io_pll0_ctrl_1                  (io_pll0_ctrl_1),
  .io_pll0_ctrl_2                  (io_pll0_ctrl_2),
  .io_pll0_ctrl_3                  (io_pll0_ctrl_3),
  .io_pll0_ctrl_4                  (io_pll0_ctrl_4),
  .io_pll0_ctrl_5                  (io_pll0_ctrl_5),
  .io_extIntrs                     (io_extIntrs  ),
  .io_rtc_clock                    (tmclk),
  .io_riscv_rst_vec_0              (38'h10000000),


`ifndef NO_DIFF
  //difftest
  .difftest_ref_clock              (difftest_ref_clock),
  .difftest_ref_reset              (difftest_ref_reset),
  .difftest_pcie_clock             (difftest_pcie_clock),
  .difftest_to_host_axis_tready    (difftest_to_host_axis_tready),
  .difftest_to_host_axis_tvalid    (difftest_to_host_axis_tvalid),
  .difftest_to_host_axis_tdata     (difftest_to_host_axis_tdata),
  .difftest_to_host_axis_tkeep     (difftest_to_host_axis_tkeep),
  .difftest_to_host_axis_tlast     (difftest_to_host_axis_tlast),
  .difftest_from_host_axis_tready  (difftest_from_host_axis_tready),
  .difftest_from_host_axis_tvalid  (difftest_from_host_axis_tvalid),
  .difftest_from_host_axis_tdata   (difftest_from_host_axis_tdata),
  .difftest_from_host_axis_tkeep   (difftest_from_host_axis_tkeep),
  .difftest_from_host_axis_tlast   (difftest_from_host_axis_tlast),
  .difftest_clock_enable           (difftest_clock_enable),
  .difftest_hostCtrl_reset         (difftest_hostCtrl_reset),
  .difftest_hostCtrl_diffEnable    (difftest_hostCtrl_diffEnable),
  .difftest_hostCtrl_ilaTrigger    (difftest_hostCtrl_ilaTrigger),
  .difftest_cfg_axilite_awready    (difftest_cfg_axilite_awready),
  .difftest_cfg_axilite_awvalid    (difftest_cfg_axilite_awvalid),
  .difftest_cfg_axilite_awaddr     (difftest_cfg_axilite_awaddr),
  .difftest_cfg_axilite_wready     (difftest_cfg_axilite_wready),
  .difftest_cfg_axilite_wvalid     (difftest_cfg_axilite_wvalid),
  .difftest_cfg_axilite_wdata      (difftest_cfg_axilite_wdata),
  .difftest_cfg_axilite_wstrb      (difftest_cfg_axilite_wstrb),
  .difftest_cfg_axilite_bready     (difftest_cfg_axilite_bready),
  .difftest_cfg_axilite_bvalid     (difftest_cfg_axilite_bvalid),
  .difftest_cfg_axilite_bresp      (difftest_cfg_axilite_bresp),
  .difftest_cfg_axilite_arready    (difftest_cfg_axilite_arready),
  .difftest_cfg_axilite_arvalid    (difftest_cfg_axilite_arvalid),
  .difftest_cfg_axilite_araddr     (difftest_cfg_axilite_araddr),
  .difftest_cfg_axilite_rready     (difftest_cfg_axilite_rready),
  .difftest_cfg_axilite_rvalid     (difftest_cfg_axilite_rvalid),
  .difftest_cfg_axilite_rdata      (difftest_cfg_axilite_rdata),
  .difftest_cfg_axilite_rresp      (difftest_cfg_axilite_rresp),

`endif
  `MEM_PORT(`MEM_PREFIX, awready) (mem_core_awready ),
  `MEM_PORT(`MEM_PREFIX, awvalid) (mem_core_awvalid ),
  `MEM_PORT(`MEM_PREFIX, awid)    (mem_core_awid    ),
`ifndef NO_DIFF
  `MEM_PORT(`MEM_PREFIX, awuser)  (),
`endif
  `MEM_PORT(`MEM_PREFIX, awaddr)  ({12'd0, mem_core_awaddr}),
  `MEM_PORT(`MEM_PREFIX, awlen)   (mem_core_awlen   ),
  `MEM_PORT(`MEM_PREFIX, awsize)  (mem_core_awsize  ),
  `MEM_PORT(`MEM_PREFIX, awburst) (mem_core_awburst ),
  `MEM_PORT(`MEM_PREFIX, awlock)  (mem_core_awlock  ),
  `MEM_PORT(`MEM_PREFIX, awcache) (mem_core_awcache ),
  `MEM_PORT(`MEM_PREFIX, awprot)  (mem_core_awprot  ),
  `MEM_PORT(`MEM_PREFIX, awqos)   (mem_core_awqos   ),
  `MEM_PORT(`MEM_PREFIX, wready)  (mem_core_wready  ),
  `MEM_PORT(`MEM_PREFIX, wvalid)  (mem_core_wvalid  ),
  `MEM_PORT(`MEM_PREFIX, wdata)   (mem_core_wdata   ),
  `MEM_PORT(`MEM_PREFIX, wstrb)   (mem_core_wstrb   ),
  `MEM_PORT(`MEM_PREFIX, wlast)   (mem_core_wlast   ),
  `MEM_PORT(`MEM_PREFIX, bready)  (mem_core_bready  ),
  `MEM_PORT(`MEM_PREFIX, bvalid)  (mem_core_bvalid  ),
  `MEM_PORT(`MEM_PREFIX, bid)     (mem_core_bid     ),
`ifndef NO_DIFF
  `MEM_PORT(`MEM_PREFIX, buser)   ('b0),
`endif
  `MEM_PORT(`MEM_PREFIX, bresp)   (mem_core_bresp   ),
  `MEM_PORT(`MEM_PREFIX, arready) (mem_core_arready ),
  `MEM_PORT(`MEM_PREFIX, arvalid) (mem_core_arvalid ),
  `MEM_PORT(`MEM_PREFIX, arid)    (mem_core_arid    ),
`ifndef NO_DIFF
  `MEM_PORT(`MEM_PREFIX, aruser)  (),
`endif
  `MEM_PORT(`MEM_PREFIX, araddr)  ({12'd0, mem_core_araddr}),
  `MEM_PORT(`MEM_PREFIX, arlen)   (mem_core_arlen   ),
  `MEM_PORT(`MEM_PREFIX, arsize)  (mem_core_arsize  ),
  `MEM_PORT(`MEM_PREFIX, arburst) (mem_core_arburst ),
  `MEM_PORT(`MEM_PREFIX, arlock)  (mem_core_arlock  ),
  `MEM_PORT(`MEM_PREFIX, arcache) (mem_core_arcache ),
  `MEM_PORT(`MEM_PREFIX, arprot)  (mem_core_arprot  ),
  `MEM_PORT(`MEM_PREFIX, arqos)   (mem_core_arqos   ),
  `MEM_PORT(`MEM_PREFIX, rready)  (mem_core_rready  ),
  `MEM_PORT(`MEM_PREFIX, rvalid)  (mem_core_rvalid  ),
  `MEM_PORT(`MEM_PREFIX, rid)     (mem_core_rid     ),
`ifndef NO_DIFF
  `MEM_PORT(`MEM_PREFIX, ruser)   ('b0),
`endif
  `MEM_PORT(`MEM_PREFIX, rdata)   (mem_core_rdata   ),
  `MEM_PORT(`MEM_PREFIX, rresp)   (mem_core_rresp   ),
  `MEM_PORT(`MEM_PREFIX, rlast)   (mem_core_rlast   ),

  .io_cacheable_check_req_0_valid    ('b0),
  .io_cacheable_check_req_0_bits_addr('b0),
  .io_cacheable_check_req_0_bits_size('b0),
  .io_cacheable_check_req_0_bits_cmd ('b0),
  .io_cacheable_check_req_1_valid    ('b0),
  .io_cacheable_check_req_1_bits_addr('b0),
  .io_cacheable_check_req_1_bits_size('b0),
  .io_cacheable_check_req_1_bits_cmd ('b0),
  .io_cacheable_check_resp_0_ld      (),
  .io_cacheable_check_resp_0_st      (),
  .io_cacheable_check_resp_0_instr   (),
  .io_cacheable_check_resp_0_mmio    (),
  .io_cacheable_check_resp_0_atomic    (),
  .io_cacheable_check_resp_1_ld      (),
  .io_cacheable_check_resp_1_st      (),
  .io_cacheable_check_resp_1_instr   (),
  .io_cacheable_check_resp_1_mmio    (),
  .io_cacheable_check_resp_1_atomic    (),
  .io_riscv_halt_0                     (),
  .io_riscv_critical_error_0           (io_riscv_critical_error_0_int),
  .io_traceCoreInterface_0_fromEncoder_enable (trace_en),
  .io_traceCoreInterface_0_fromEncoder_stall  (trace_stall),
  .io_traceCoreInterface_0_toEncoder_cause    (trace_cause),
  .io_traceCoreInterface_0_toEncoder_tval     (trace_tval),
  .io_traceCoreInterface_0_toEncoder_priv     (trace_priv),
  .io_traceCoreInterface_0_toEncoder_iaddr    (trace_iaddr),
  .io_traceCoreInterface_0_toEncoder_itype    (trace_itype),
  .io_traceCoreInterface_0_toEncoder_iretire  (trace_iretire),
  .io_traceCoreInterface_0_toEncoder_ilastsize(trace_ilastsize)
);
endmodule

`undef MEM_PORT
`undef MEM_PORT_
`undef MEM_PREFIX
`undef TOP_NAME
