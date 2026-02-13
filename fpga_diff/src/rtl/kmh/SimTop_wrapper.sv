`include "DifftestMacros.svh"
`include "sys_define.vh"

`ifdef CONFIG_USE_XSCORE_CHI
`include "kconfig.svh"
`include "chi_icn_defines.svh"
`endif

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
 
`ifdef CONFIG_USE_XSCORE_AXI
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

`elsif CONFIG_USE_XSCORE_CHI
  input                                 noc_clk,
  input                                 noc_rstn, 
  input                                 clint_int_0[`CONFIG_XSCORE_NR-1:0],
  input                                 clint_int_1[`CONFIG_XSCORE_NR-1:0],
  input  [1:0]                          plic_int[`CONFIG_XSCORE_NR-1:0],
  input                                 io_debug_module_hart[`CONFIG_XSCORE_NR-1:0],
  output                                io_hartIsInReset[`CONFIG_XSCORE_NR-1:0],
  input                                 io_clintTime_valid,
  input  [63:0]                         io_clintTime_bits,
  output                                io_riscv_halt[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_syscoreq[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_syscoack[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_txsactive[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rxsactive[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_linkactivereq[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_tx_linkactiveack[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_req_flitpend[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_req_flitv[`CONFIG_XSCORE_NR-1:0],
  output [`CHI_REQFLIT_WIDTH-1:0]       io_chi_tx_req_flit[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_tx_req_lcrdv[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_rsp_flitpend[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_rsp_flitv[`CONFIG_XSCORE_NR-1:0],
  output [`CHI_RSPFLIT_WIDTH-1:0]       io_chi_tx_rsp_flit[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_tx_rsp_lcrdv[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_dat_flitpend[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_tx_dat_flitv[`CONFIG_XSCORE_NR-1:0],
  output [`CHI_DATFLIT_WIDTH-1:0]       io_chi_tx_dat_flit[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_tx_dat_lcrdv[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_linkactivereq[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_rx_linkactiveack[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_rsp_flitpend[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_rsp_flitv[`CONFIG_XSCORE_NR-1:0],
  input  [`CHI_RSPFLIT_WIDTH-1:0]       io_chi_rx_rsp_flit[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_rx_rsp_lcrdv[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_dat_flitpend[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_dat_flitv[`CONFIG_XSCORE_NR-1:0],
  input  [`CHI_DATFLIT_WIDTH-1:0]       io_chi_rx_dat_flit[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_rx_dat_lcrdv[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_snp_flitpend[`CONFIG_XSCORE_NR-1:0],
  input                                 io_chi_rx_snp_flitv[`CONFIG_XSCORE_NR-1:0],
  input  [`CHI_SNPFLIT_WIDTH-1:0]       io_chi_rx_snp_flit[`CONFIG_XSCORE_NR-1:0],
  output                                io_chi_rx_snp_lcrdv[`CONFIG_XSCORE_NR-1:0],
`endif
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
  output          io_riscv_halt_1,
  input           difftest_ref_clock,
                  difftest_pcie_clock,
                  difftest_to_host_axis_ready,
  output          difftest_to_host_axis_valid,
  output [511:0]  difftest_to_host_axis_bits_data,
  output          difftest_to_host_axis_bits_last,
                  difftest_clock_enable
);

`ifdef CONFIG_USE_XSCORE_AXI
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

SimTop  u_XSTop(
  .clock                         (inter_soc_clk),
  .reset                         (~sys_rstn_i),

  .nmi_0_0                       (nmi_0_0),
  .nmi_0_1                       (nmi_0_1),
  .memory_awready                (mem_core_awready )                        ,
  .memory_awvalid                (mem_core_awvalid )                        ,
  .memory_awid                   (mem_core_awid    )                        ,
  .memory_awaddr                 ({12'd0, mem_core_awaddr})                  ,
  .memory_awlen                  (mem_core_awlen   )                           ,
  .memory_awsize                 (mem_core_awsize  )                            ,
  .memory_awburst                (mem_core_awburst )                             ,
  .memory_awlock                 (mem_core_awlock  )                            ,
  .memory_awcache                (mem_core_awcache )                             ,
  .memory_awprot                 (mem_core_awprot  )                            ,
  .memory_awqos                  (mem_core_awqos   )                           ,
  .memory_wready                 (mem_core_wready  )                       ,
  .memory_wvalid                 (mem_core_wvalid  )                       ,
  .memory_wdata                  (mem_core_wdata   )                           ,
  .memory_wstrb                  (mem_core_wstrb   )                           ,
  .memory_wlast                  (mem_core_wlast   )                           ,
  .memory_bready                 (mem_core_bready  )                       ,
  .memory_bvalid                 (mem_core_bvalid  )                       ,
  .memory_bid                    (mem_core_bid     )                         ,
  .memory_bresp                  (mem_core_bresp   )                           ,
  .memory_arready                (mem_core_arready )                        ,
  .memory_arvalid                (mem_core_arvalid )                        ,
  .memory_arid                   (mem_core_arid    )                          ,
  .memory_araddr                 ({12'd0, mem_core_araddr})                  ,
  .memory_arlen                  (mem_core_arlen   )                           ,
  .memory_arsize                 (mem_core_arsize  )                            ,
  .memory_arburst                (mem_core_arburst )                             ,
  .memory_arlock                 (mem_core_arlock  )                            ,
  .memory_arcache                (mem_core_arcache )                             ,
  .memory_arprot                 (mem_core_arprot  )                            ,
  .memory_arqos                  (mem_core_arqos   )                           ,
  .memory_rready                 (mem_core_rready  )                       ,
  .memory_rvalid                 (mem_core_rvalid  )                       ,
  .memory_rid                    (mem_core_rid     )                         ,
  .memory_rdata                  (mem_core_rdata   )                           ,
  .memory_rresp                  (mem_core_rresp   )                           ,
  .memory_rlast                  (mem_core_rlast   )                           ,
  .peripheral_awready            (peri_awready  )                            ,
  .peripheral_awvalid            (peri_awvalid  )                            ,
  .peripheral_awid               (peri_awid     )                              ,
  .peripheral_awaddr             ({16'd0, peri_awaddr})                        ,
  .peripheral_awlen              (peri_awlen    )                               ,
  .peripheral_awsize             (peri_awsize   )                                ,
  .peripheral_awburst            (peri_awburst  )                                 ,
  .peripheral_awlock             (peri_awlock   )                                ,
  .peripheral_awcache            (peri_awcache  )                                 ,
  .peripheral_awprot             (peri_awprot   )                                ,
  .peripheral_awqos              (peri_awqos    )                               ,
  .peripheral_wready             (peri_wready   )                           ,
  .peripheral_wvalid             (peri_wvalid   )                           ,
  .peripheral_wdata              (peri_wdata    )                               ,
  .peripheral_wstrb              (peri_wstrb    )                               ,
  .peripheral_wlast              (peri_wlast    )                               ,
  .peripheral_bready             (peri_bready   )                           ,
  .peripheral_bvalid             (peri_bvalid   )                           ,
  .peripheral_bid                (peri_bid      )                             ,
  .peripheral_bresp              (peri_bresp    )                               ,
  .peripheral_arready            (peri_arready  )                            ,
  .peripheral_arvalid            (peri_arvalid  )                            ,
  .peripheral_arid               (peri_arid     )                              ,
  .peripheral_araddr             ({16'd0, peri_araddr})                        ,
  .peripheral_arlen              (peri_arlen    )                               ,
  .peripheral_arsize             (peri_arsize   )                                ,
  .peripheral_arburst            (peri_arburst  )                                 ,
  .peripheral_arlock             (peri_arlock   )                                ,
  .peripheral_arcache            (peri_arcache  )                                 ,
  .peripheral_arprot             (peri_arprot   )                                ,
  .peripheral_arqos              (peri_arqos    )                               ,
  .peripheral_rready             (peri_rready   )                           ,
  .peripheral_rvalid             (peri_rvalid   )                           ,
  .peripheral_rid                (peri_rid      )                             ,
  .peripheral_rdata              (peri_rdata    )                               ,
  .peripheral_rresp              (peri_rresp    )                               ,
  .peripheral_rlast              (peri_rlast    )                               ,
  .dma_awready                   (dma_core_awready )                     ,
  .dma_awvalid                   (dma_core_awvalid )                     ,
  .dma_awid                      (dma_core_awid    )                       ,
  .dma_awaddr                    (dma_core_awaddr[35:0]  )                         ,
  .dma_awlen                     (dma_core_awlen   )                        ,
  .dma_awsize                    (dma_core_awsize  )                         ,
  .dma_awburst                   (dma_core_awburst )                          ,
  .dma_awlock                    (dma_core_awlock  )                         ,
  .dma_awcache                   (dma_core_awcache )                          ,
  .dma_awprot                    (dma_core_awprot  )                         ,
  .dma_awqos                     (dma_core_awqos   )                        ,
  .dma_wready                    (dma_core_wready  )                    ,
  .dma_wvalid                    (dma_core_wvalid  )                    ,
  .dma_wdata                     (dma_core_wdata   )                        ,
  .dma_wstrb                     (dma_core_wstrb   )                        ,
  .dma_wlast                     (dma_core_wlast   )                        ,
  .dma_bready                    (dma_core_bready  )                    ,
  .dma_bvalid                    (dma_core_bvalid  )                    ,
  .dma_bid                       (dma_core_bid     )                      ,
  .dma_bresp                     (dma_core_bresp   )                        ,
  .dma_arready                   (dma_core_arready )                     ,
  .dma_arvalid                   (dma_core_arvalid )                     ,
  .dma_arid                      (dma_core_arid    )                       ,
  .dma_araddr                    (dma_core_araddr[35:0]  )                         ,
  .dma_arlen                     (dma_core_arlen   )                        ,
  .dma_arsize                    (dma_core_arsize  )                         ,
  .dma_arburst                   (dma_core_arburst )                          ,
  .dma_arlock                    (dma_core_arlock  )                         ,
  .dma_arcache                   (dma_core_arcache )                          ,
  .dma_arprot                    (dma_core_arprot  )                         ,
  .dma_arqos                     (dma_core_arqos   )                        ,
  .dma_rready                    (dma_core_rready  )                    ,
  .dma_rvalid                    (dma_core_rvalid  )                    ,
  .dma_rid                       (dma_core_rid     )                      ,
  .dma_rdata                     (dma_core_rdata   )                        ,
  .dma_rresp                     (dma_core_rresp   )                        ,
  .dma_rlast                     (dma_core_rlast   )                        ,

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


  //difftest
  .difftest_ref_clock              (difftest_ref_clock),
  .difftest_pcie_clock             (difftest_pcie_clock),
  .difftest_to_host_axis_ready     (difftest_to_host_axis_ready),
  .difftest_to_host_axis_valid     (difftest_to_host_axis_valid),
  .difftest_to_host_axis_bits_data (difftest_to_host_axis_bits_data),
  .difftest_to_host_axis_bits_last (difftest_to_host_axis_bits_last),
  .difftest_clock_enable           (difftest_clock_enable),

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
`elsif CONFIG_USE_XSCORE_CHI

  wire xstile_cpu_reset;
  XSTileResetGen reset_sync_resetSync_cpu (
      .clock   (inter_soc_clk),
      .reset   (~sys_rstn_i),
      .o_reset (xstile_cpu_reset)
  );
  wire xstile_soc_reset;
  XSTileResetGen reset_sync_resetSync_sys (
      .clock   (inter_soc_clk),
      .reset   (~sys_rstn_i),
      .o_reset (xstile_soc_reset)
  );

  generate
    genvar i;

    for (i = 0; i < `CONFIG_XSCORE_NR; i = i+1)
    begin: u_CPU_TOP

      wire [`CHI_DATFLIT_WIDTH-1:0] _io_chi_tx_dat_flit;
      wire [6:0] nodeID;
      case (i)
`ifdef CONFIG_USE_XSCORE_CHI_ISSUE_B
        0: assign nodeID = 7'd12;
        1: assign nodeID = 7'd44;
`elsif CONFIG_USE_XSCORE_CHI_ISSUE_E
        0: assign nodeID = 7'd10;
        1: assign nodeID = 7'd42;
`endif
      endcase

     SimTop u_XSTop (
         .clint_0_0               (clint_int_0[i]),
         .clint_0_1               (clint_int_1[i]),
         .debug_0_0               (io_debug_module_hart[i]),
         .io_hartIsInReset        (io_hartIsInReset[i]),
         .plic_1_0                (plic_int[i][1:1]),
         .plic_0_0                (plic_int[i][0:0]),
         .beu_0_0                 (),
         .nmi_0_0                 (1'b0),
         .nmi_0_1                 (1'b0),
         .clock                   (inter_soc_clk),
         .reset                   (xstile_cpu_reset),
         .noc_clock               (noc_clk),
         .noc_reset               (xstile_soc_reset),
         .soc_clock               (inter_soc_clk),
         .soc_reset               (xstile_soc_reset),
         .io_hartId               (64'h0 + i),
         .io_clintTime_valid      (io_clintTime_valid),
         .io_clintTime_bits       (io_clintTime_bits),
         .io_riscv_halt           (io_riscv_halt[i]),
         .io_riscv_rst_vec        (38'h10000000),
         .io_chi_syscoreq         (io_chi_syscoreq[i]),
         .io_chi_syscoack         (io_chi_syscoack[i]),
         .io_chi_txsactive        (io_chi_txsactive[i]),
         .io_chi_rxsactive        (io_chi_rxsactive[i]),
         .io_chi_tx_linkactivereq (io_chi_tx_linkactivereq[i]),
         .io_chi_tx_linkactiveack (io_chi_tx_linkactiveack[i]),
         .io_chi_tx_req_flitpend  (io_chi_tx_req_flitpend[i]),
         .io_chi_tx_req_flitv     (io_chi_tx_req_flitv[i]),
         .io_chi_tx_req_flit      (io_chi_tx_req_flit[i]),
         .io_chi_tx_req_lcrdv     (io_chi_tx_req_lcrdv[i]),
         .io_chi_tx_rsp_flitpend  (io_chi_tx_rsp_flitpend[i]),
         .io_chi_tx_rsp_flitv     (io_chi_tx_rsp_flitv[i]),
         .io_chi_tx_rsp_flit      (io_chi_tx_rsp_flit[i]),
         .io_chi_tx_rsp_lcrdv     (io_chi_tx_rsp_lcrdv[i]),
         .io_chi_tx_dat_flitpend  (io_chi_tx_dat_flitpend[i]),
         .io_chi_tx_dat_flitv     (io_chi_tx_dat_flitv[i]),
         .io_chi_tx_dat_flit      (_io_chi_tx_dat_flit),
         .io_chi_tx_dat_lcrdv     (io_chi_tx_dat_lcrdv[i]),
         .io_chi_rx_linkactivereq (io_chi_rx_linkactivereq[i]),
         .io_chi_rx_linkactiveack (io_chi_rx_linkactiveack[i]),
         .io_chi_rx_rsp_flitpend  (io_chi_rx_rsp_flitpend[i]),
         .io_chi_rx_rsp_flitv     (io_chi_rx_rsp_flitv[i]),
         .io_chi_rx_rsp_flit      (io_chi_rx_rsp_flit[i]),
         .io_chi_rx_rsp_lcrdv     (io_chi_rx_rsp_lcrdv[i]),
         .io_chi_rx_dat_flitpend  (io_chi_rx_dat_flitpend[i]),
         .io_chi_rx_dat_flitv     (io_chi_rx_dat_flitv[i]),
         .io_chi_rx_dat_flit      (io_chi_rx_dat_flit[i]),
         .io_chi_rx_dat_lcrdv     (io_chi_rx_dat_lcrdv[i]),
         .io_chi_rx_snp_flitpend  (io_chi_rx_snp_flitpend[i]),
         .io_chi_rx_snp_flitv     (io_chi_rx_snp_flitv[i]),
         .io_chi_rx_snp_flit      (io_chi_rx_snp_flit[i]),
         .io_chi_rx_snp_lcrdv     (io_chi_rx_snp_lcrdv[i]),
         .io_nodeID               (nodeID),

         .difftest_ref_clock              (difftest_ref_clock),
         .difftest_pcie_clock             (difftest_pcie_clock),
         .difftest_to_host_axis_ready     (difftest_to_host_axis_ready),
         .difftest_to_host_axis_valid     (difftest_to_host_axis_valid),
         .difftest_to_host_axis_bits_data (difftest_to_host_axis_bits_data),
         .difftest_to_host_axis_bits_last (difftest_to_host_axis_bits_last),
         .difftest_clock_enable           (difftest_clock_enable),

         /* trace */
`ifdef CONFIG_HAVE_XSCORE_TRACE
         .io_traceCoreInterface_fromEncoder_enable (1'b0),
         .io_traceCoreInterface_fromEncoder_stall  (1'b0),
         .io_traceCoreInterface_toEncoder_cause    (),
         .io_traceCoreInterface_toEncoder_tval     (),
         .io_traceCoreInterface_toEncoder_priv     (),
         .io_traceCoreInterface_toEncoder_iaddr    (),
         .io_traceCoreInterface_toEncoder_itype    (),
         .io_traceCoreInterface_toEncoder_iretire  (),
         .io_traceCoreInterface_toEncoder_ilastsize(),
`endif /* CONFIG_HAVE_XSCORE_TRACE */

`ifdef CONFIG_USE_IMSIC
         .imsic_axi4_awready  (io_imsic_awready[i]),
         .imsic_axi4_awvalid  (io_imsic_awvalid[i]),
         .imsic_axi4_awid     (io_imsic_awid[i]),
         .imsic_axi4_awaddr   (io_imsic_awaddr[i]),
         .imsic_axi4_wready   (io_imsic_wready[i]),
         .imsic_axi4_wvalid   (io_imsic_wvalid[i]),
         .imsic_axi4_wdata    (io_imsic_wdata[i]),
         .imsic_axi4_bready   (io_imsic_bready[i]),
         .imsic_axi4_bvalid   (io_imsic_bvalid[i]),
         .imsic_axi4_bid      (io_imsic_bid[i]),
         .imsic_axi4_bresp    (io_imsic_bresp[i]),
         .imsic_axi4_arready  (io_imsic_arready[i]),
         .imsic_axi4_arvalid  (io_imsic_arvalid[i]),
         .imsic_axi4_arid     (io_imsic_arid[i]),
         .imsic_axi4_araddr   (io_imsic_araddr[i]),
         .imsic_axi4_rready   (io_imsic_rready[i]),
         .imsic_axi4_rvalid   (io_imsic_rvalid[i]),
         .imsic_axi4_rid      (io_imsic_rid[i]),
         .imsic_axi4_rdata    (io_imsic_rdata[i]),
         .imsic_axi4_rresp    (io_imsic_rresp[i])
`else
         .imsic_axi4_awready  (),
         .imsic_axi4_awvalid  (1'b0),
         .imsic_axi4_awid     (5'b0),
         .imsic_axi4_awaddr   (32'b0),
         .imsic_axi4_wready   (),
         .imsic_axi4_wvalid   (1'b0),
         .imsic_axi4_wdata    (32'b0),
         .imsic_axi4_bready   (1'b0),
         .imsic_axi4_bvalid   (),
         .imsic_axi4_bid      (),
         .imsic_axi4_bresp    (),
         .imsic_axi4_arready  (),
         .imsic_axi4_arvalid  (1'b0),
         .imsic_axi4_arid     (5'b0),
         .imsic_axi4_araddr   (32'b0),
         .imsic_axi4_rready   (1'b0),
         .imsic_axi4_rvalid   (),
         .imsic_axi4_rid      (),
         .imsic_axi4_rdata    (),
         .imsic_axi4_rresp    ()
`endif /* CONFIG_USE_IMSIC */
     );

/* HACK: io_chi_tx_dat_flit.{DataCheck,Poison} */
`ifndef CONFIG_HAVE_XSCORE_DATACHK
      `define TXDAT_FLIT_DATA		(`CHI_DATFLIT_NOCHKWIDTH - 256)
      wire [31:0] tx_dat_flit_datachk;
      genvar idx;
      for (idx = 0; idx < 32; idx = idx + 1) begin: u_tx_dat_chk
          assign tx_dat_flit_datachk[idx] =
              ~^(_io_chi_tx_dat_flit[`TXDAT_FLIT_DATA + 8*idx +: 8]);
      end: u_tx_dat_chk
      assign io_chi_tx_dat_flit[i] = {
          4'b0 /* Poison */, tx_dat_flit_datachk[31:0],
          _io_chi_tx_dat_flit[`CHI_DATFLIT_NOCHKWIDTH-1:0]
      };
`else
      assign io_chi_tx_dat_flit[i] = _io_chi_tx_dat_flit;
`endif /* !CONFIG_HAVE_XSCORE_DATACHK */
    end
  endgenerate

`endif

endmodule
