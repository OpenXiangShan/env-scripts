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
  (*mark_debug="true"*) input           dma_core_awid,
  (*mark_debug="true"*) input  [31:0]   dma_core_awaddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_awlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_awsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_awburst,
  (*mark_debug="true"*) input           dma_core_awlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_awcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_awprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_awqos,
  (*mark_debug="true"*) output          dma_core_wready,
  (*mark_debug="true"*) input           dma_core_wvalid,
  (*mark_debug="true"*) input  [63:0]   dma_core_wdata,
  (*mark_debug="true"*) input  [31:0]   dma_core_wstrb,
  (*mark_debug="true"*) input           dma_core_wlast,
  (*mark_debug="true"*) input           dma_core_bready,
  (*mark_debug="true"*) output          dma_core_bvalid,
  (*mark_debug="true"*) output          dma_core_bid,
  (*mark_debug="true"*) output [1:0]    dma_core_bresp,
  (*mark_debug="true"*) output          dma_core_arready,
  (*mark_debug="true"*) input           dma_core_arvalid,
  (*mark_debug="true"*) input           dma_core_arid,
  (*mark_debug="true"*) input  [31:0]   dma_core_araddr,
  (*mark_debug="true"*) input  [7:0]    dma_core_arlen,
  (*mark_debug="true"*) input  [2:0]    dma_core_arsize,
  (*mark_debug="true"*) input  [1:0]    dma_core_arburst,
  (*mark_debug="true"*) input           dma_core_arlock,
  (*mark_debug="true"*) input  [3:0]    dma_core_arcache,
  (*mark_debug="true"*) input  [2:0]    dma_core_arprot,
  (*mark_debug="true"*) input  [3:0]    dma_core_arqos,
  (*mark_debug="true"*) input           dma_core_rready,
  (*mark_debug="true"*) output          dma_core_rvalid,
  (*mark_debug="true"*) output          dma_core_rid,
  (*mark_debug="true"*) output [63:0]   dma_core_rdata,
  (*mark_debug="true"*) output [1:0]    dma_core_rresp,
  (*mark_debug="true"*) output          dma_core_rlast,
  
  (*mark_debug="true"*) input           peri_awready,
  (*mark_debug="true"*) output          peri_awvalid,
  (*mark_debug="true"*) output          peri_awid,
  (*mark_debug="true"*) output [31:0]   peri_awaddr,
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
  (*mark_debug="true"*) output          peri_arid,
  (*mark_debug="true"*) output [31:0]   peri_araddr,
  (*mark_debug="true"*) output [7:0]    peri_arlen,
  (*mark_debug="true"*) output [2:0]    peri_arsize,
  (*mark_debug="true"*) output [1:0]    peri_arburst,
  (*mark_debug="true"*) output          peri_arlock,
  (*mark_debug="true"*) output [3:0]    peri_arcache,
  (*mark_debug="true"*) output [2:0]    peri_arprot,
  (*mark_debug="true"*) output [3:0]    peri_arqos,
  (*mark_debug="true"*) output          peri_rready,
  (*mark_debug="true"*) input           peri_rvalid,
  (*mark_debug="true"*) input           peri_rid,
  (*mark_debug="true"*) input  [63:0]   peri_rdata,
  (*mark_debug="true"*) input  [1:0]    peri_rresp,
  (*mark_debug="true"*) input           peri_rlast,
  
  (*mark_debug="true"*) input           mem_core_awready,
  (*mark_debug="true"*) output          mem_core_awvalid,
  (*mark_debug="true"*) output [7:0]    mem_core_awid,
  (*mark_debug="true"*) output [31:0]   mem_core_awaddr,
  (*mark_debug="true"*) output [7:0]    mem_core_awlen,
  (*mark_debug="true"*) output [2:0]    mem_core_awsize,
  (*mark_debug="true"*) output [1:0]    mem_core_awburst,
  (*mark_debug="true"*) output          mem_core_awlock,
  (*mark_debug="true"*) output [3:0]    mem_core_awcache,
  (*mark_debug="true"*) output [2:0]    mem_core_awprot,
  (*mark_debug="true"*) output [3:0]    mem_core_awqos,
  (*mark_debug="true"*) input           mem_core_wready,
  (*mark_debug="true"*) output          mem_core_wvalid,
  (*mark_debug="true"*) output [63:0]   mem_core_wdata,
  (*mark_debug="true"*) output [7:0]    mem_core_wstrb,
  (*mark_debug="true"*) output          mem_core_wlast,
  (*mark_debug="true"*) output          mem_core_bready,
  (*mark_debug="true"*) input           mem_core_bvalid,
  (*mark_debug="true"*) input           mem_core_bid,
  (*mark_debug="true"*) input  [1:0]    mem_core_bresp,
  (*mark_debug="true"*) input           mem_core_arready,
  (*mark_debug="true"*) output          mem_core_arvalid,
  (*mark_debug="true"*) output          mem_core_arid,
  (*mark_debug="true"*) output [31:0]   mem_core_araddr,
  (*mark_debug="true"*) output [7:0]    mem_core_arlen,
  (*mark_debug="true"*) output [2:0]    mem_core_arsize,
  (*mark_debug="true"*) output [1:0]    mem_core_arburst,
  (*mark_debug="true"*) output          mem_core_arlock,
  (*mark_debug="true"*) output [3:0]    mem_core_arcache,
  (*mark_debug="true"*) output [2:0]    mem_core_arprot,
  (*mark_debug="true"*) output [3:0]    mem_core_arqos,
  (*mark_debug="true"*) output          mem_core_rready,
  (*mark_debug="true"*) input           mem_core_rvalid,
  (*mark_debug="true"*) input           mem_core_rid,
  (*mark_debug="true"*) input  [63:0]   mem_core_rdata,
  (*mark_debug="true"*) input  [1:0]    mem_core_rresp,
  (*mark_debug="true"*) input           mem_core_rlast,

input          difftest_ref_clock,
               difftest_pcie_clock,

// C2H (DUT -> Host)
input          difftest_to_host_axis_ready,
output         difftest_to_host_axis_valid,
output [511:0] difftest_to_host_axis_bits_data,
output         difftest_to_host_axis_bits_last,

// H2C (Host -> DUT)
input          difftest_h2c_axis_valid,
output         difftest_h2c_axis_ready,
input  [63:0]  difftest_h2c_axis_bits_data,
input          difftest_h2c_axis_bits_last,

// Config AXI4-Lite
input          difftest_cfg_aw_valid,
output         difftest_cfg_aw_ready,
input  [31:0]  difftest_cfg_aw_bits_addr,
input  [2:0]   difftest_cfg_aw_bits_prot,
input          difftest_cfg_w_valid,
output         difftest_cfg_w_ready,
input  [31:0]  difftest_cfg_w_bits_data,
input  [3:0]   difftest_cfg_w_bits_strb,
output         difftest_cfg_b_valid,
input          difftest_cfg_b_ready,
output [1:0]   difftest_cfg_b_bits_resp,
input          difftest_cfg_ar_valid,
output         difftest_cfg_ar_ready,
input  [31:0]  difftest_cfg_ar_bits_addr,
input  [2:0]   difftest_cfg_ar_bits_prot,
output         difftest_cfg_r_valid,
input          difftest_cfg_r_ready,
output [31:0]  difftest_cfg_r_bits_data,
output [1:0]   difftest_cfg_r_bits_resp,

output         difftest_clock_enable,

// Control outputs from config registers
output         difftest_HOST_IO_RESET,
output         difftest_HOST_IO_DIFFTEST_ENABLE
);

// // Route CPU memory traffic through difftest_cpu_mem <-> difftest_ddr_mem path.
// wire         cpu_mem_awready;
// wire         cpu_mem_awvalid;
// wire [31:0]  cpu_mem_awaddr;
// wire [2:0]   cpu_mem_awprot;
// wire         cpu_mem_awid;
// wire         cpu_mem_awuser;
// wire [7:0]   cpu_mem_awlen;
// wire [2:0]   cpu_mem_awsize;
// wire [1:0]   cpu_mem_awburst;
// wire         cpu_mem_awlock;
// wire [3:0]   cpu_mem_awcache;
// wire [3:0]   cpu_mem_awqos;
// wire         cpu_mem_wready;
// wire         cpu_mem_wvalid;
// wire [63:0]  cpu_mem_wdata;
// wire [7:0]   cpu_mem_wstrb;
// wire         cpu_mem_wlast;
// wire         cpu_mem_bready;
// wire         cpu_mem_bvalid;
// wire [1:0]   cpu_mem_bresp;
// wire         cpu_mem_bid;
// wire         cpu_mem_buser;
// wire         cpu_mem_arready;
// wire         cpu_mem_arvalid;
// wire [31:0]  cpu_mem_araddr;
// wire [2:0]   cpu_mem_arprot;
// wire         cpu_mem_arid;
// wire         cpu_mem_aruser;
// wire [7:0]   cpu_mem_arlen;
// wire [2:0]   cpu_mem_arsize;
// wire [1:0]   cpu_mem_arburst;
// wire         cpu_mem_arlock;
// wire [3:0]   cpu_mem_arcache;
// wire [3:0]   cpu_mem_arqos;
// wire         cpu_mem_rready;
// wire         cpu_mem_rvalid;
// wire [1:0]   cpu_mem_rresp;
// wire [63:0]  cpu_mem_rdata;
// wire         cpu_mem_rlast;
// wire         cpu_mem_rid;
// wire         cpu_mem_ruser;

// assign mem_core_awvalid = cpu_mem_awvalid;
// assign mem_core_awid    = {7'b0, cpu_mem_awid};
// assign mem_core_awaddr  = cpu_mem_awaddr;
// assign mem_core_awlen   = cpu_mem_awlen;
// assign mem_core_awsize  = cpu_mem_awsize;
// assign mem_core_awburst = cpu_mem_awburst;
// assign mem_core_awlock  = cpu_mem_awlock;
// assign mem_core_awcache = cpu_mem_awcache;
// assign mem_core_awprot  = cpu_mem_awprot;
// assign mem_core_awqos   = cpu_mem_awqos;
// assign mem_core_wvalid  = cpu_mem_wvalid;
// assign mem_core_wdata   = cpu_mem_wdata;
// assign mem_core_wstrb   = cpu_mem_wstrb;
// assign mem_core_wlast   = cpu_mem_wlast;
// assign mem_core_bready  = cpu_mem_bready;
// assign mem_core_arvalid = cpu_mem_arvalid;
// assign mem_core_arid    = cpu_mem_arid;
// assign mem_core_araddr  = cpu_mem_araddr;
// assign mem_core_arlen   = cpu_mem_arlen;
// assign mem_core_arsize  = cpu_mem_arsize;
// assign mem_core_arburst = cpu_mem_arburst;
// assign mem_core_arlock  = cpu_mem_arlock;
// assign mem_core_arcache = cpu_mem_arcache;
// assign mem_core_arprot  = cpu_mem_arprot;
// assign mem_core_arqos   = cpu_mem_arqos;
// assign mem_core_rready  = cpu_mem_rready;

// assign cpu_mem_awready = mem_core_awready;
// assign cpu_mem_wready  = mem_core_wready;
// assign cpu_mem_bvalid  = mem_core_bvalid;
// assign cpu_mem_bresp   = mem_core_bresp;
// assign cpu_mem_bid     = mem_core_bid;
// assign cpu_mem_buser   = 1'b0;
// assign cpu_mem_arready = mem_core_arready;
// assign cpu_mem_rvalid  = mem_core_rvalid;
// assign cpu_mem_rresp   = mem_core_rresp;
// assign cpu_mem_rdata   = mem_core_rdata;
// assign cpu_mem_rlast   = mem_core_rlast;
// assign cpu_mem_rid     = mem_core_rid;
// assign cpu_mem_ruser   = 1'b0;

SimTop u_SimTop (
    .clock                      (inter_soc_clk),
    .reset                      (~sys_rstn_i),

    // AXI4 MEMORY (flattened port names)
    .io_mem_awready             (mem_core_awready),
    .io_mem_awvalid             (mem_core_awvalid),
    .io_mem_awaddr              (mem_core_awaddr[31:0]),
    .io_mem_awprot              (mem_core_awprot),
    .io_mem_awid                (mem_core_awid),
    .io_mem_awuser              (/* TODO */),
    .io_mem_awlen               (mem_core_awlen),
    .io_mem_awsize              (mem_core_awsize),
    .io_mem_awburst             (mem_core_awburst),
    .io_mem_awlock              (mem_core_awlock),
    .io_mem_awcache             (mem_core_awcache),
    .io_mem_awqos               (mem_core_awqos),

    .io_mem_wready              (mem_core_wready),
    .io_mem_wvalid              (mem_core_wvalid),
    .io_mem_wdata               (mem_core_wdata[63:0]),
    .io_mem_wstrb               (mem_core_wstrb[7:0]),
    .io_mem_wlast               (mem_core_wlast),

    .io_mem_bready              (mem_core_bready),
    .io_mem_bvalid              (mem_core_bvalid),
    .io_mem_bresp               (mem_core_bresp),
    .io_mem_bid                 (mem_core_bid),
    .io_mem_buser               (/* TODO */),

    .io_mem_arready             (mem_core_arready),
    .io_mem_arvalid             (mem_core_arvalid),
    .io_mem_araddr              (mem_core_araddr[31:0]),
    .io_mem_arprot              (mem_core_arprot),
    .io_mem_arid                (mem_core_arid),
    .io_mem_aruser              (/* TODO */),
    .io_mem_arlen               (mem_core_arlen),
    .io_mem_arsize              (mem_core_arsize),
    .io_mem_arburst             (mem_core_arburst),
    .io_mem_arlock              (mem_core_arlock),
    .io_mem_arcache             (mem_core_arcache),
    .io_mem_arqos               (mem_core_arqos),

    .io_mem_rready              (mem_core_rready),
    .io_mem_rvalid              (mem_core_rvalid),
    .io_mem_rresp               (mem_core_rresp),
    .io_mem_rdata               (mem_core_rdata[63:0]),
    .io_mem_rlast               (mem_core_rlast),
    .io_mem_rid                 (mem_core_rid),
    .io_mem_ruser               (/* TODO */),

    // AXI4 MMIO
    .io_mmio_awready            (peri_awready),
    .io_mmio_awvalid            (peri_awvalid),
    .io_mmio_awaddr             (peri_awaddr[31:0]),
    .io_mmio_awprot             (peri_awprot),
    .io_mmio_awid               (peri_awid),
    .io_mmio_awuser             (/* TODO */),
    .io_mmio_awlen              (peri_awlen),
    .io_mmio_awsize             (peri_awsize),
    .io_mmio_awburst            (peri_awburst),
    .io_mmio_awlock             (peri_awlock),
    .io_mmio_awcache            (peri_awcache),
    .io_mmio_awqos              (peri_awqos),

    .io_mmio_wready             (peri_wready),
    .io_mmio_wvalid             (peri_wvalid),
    .io_mmio_wdata              (peri_wdata),
    .io_mmio_wstrb              (peri_wstrb),
    .io_mmio_wlast              (peri_wlast),

    .io_mmio_bready             (peri_bready),
    .io_mmio_bvalid             (peri_bvalid),
    .io_mmio_bresp              (peri_bresp),
    .io_mmio_bid                (peri_bid),
    .io_mmio_buser              (/* TODO */),

    .io_mmio_arready            (peri_arready),
    .io_mmio_arvalid            (peri_arvalid),
    .io_mmio_araddr             (peri_araddr[31:0]),
    .io_mmio_arprot             (peri_arprot),
    .io_mmio_arid               (peri_arid),
    .io_mmio_aruser             (/* TODO */),
    .io_mmio_arlen              (peri_arlen),
    .io_mmio_arsize             (peri_arsize),
    .io_mmio_arburst            (peri_arburst),
    .io_mmio_arlock             (peri_arlock),
    .io_mmio_arcache            (peri_arcache),
    .io_mmio_arqos              (peri_arqos),

    .io_mmio_rready             (peri_rready),
    .io_mmio_rvalid             (peri_rvalid),
    .io_mmio_rresp              (peri_rresp),
    .io_mmio_rdata              (peri_rdata),
    .io_mmio_rlast              (peri_rlast),
    .io_mmio_rid                (peri_rid),
    .io_mmio_ruser              (/* TODO */),

    // AXI4 DMA / FRONTEND
    .io_frontend_awready        (dma_core_awready),
    .io_frontend_awvalid        (dma_core_awvalid),
    .io_frontend_awaddr         (dma_core_awaddr[31:0]),
    .io_frontend_awprot         (dma_core_awprot),
    .io_frontend_awid           (dma_core_awid),
    .io_frontend_awuser         (/* TODO */),
    .io_frontend_awlen          (dma_core_awlen),
    .io_frontend_awsize         (dma_core_awsize),
    .io_frontend_awburst        (dma_core_awburst),
    .io_frontend_awlock         (dma_core_awlock),
    .io_frontend_awcache        (dma_core_awcache),
    .io_frontend_awqos          (dma_core_awqos),

    .io_frontend_wready         (dma_core_wready),
    .io_frontend_wvalid         (dma_core_wvalid),
    .io_frontend_wdata          (dma_core_wdata[63:0]),
    .io_frontend_wstrb          (dma_core_wstrb[7:0]),
    .io_frontend_wlast          (dma_core_wlast),

    .io_frontend_bready         (dma_core_bready),
    .io_frontend_bvalid         (dma_core_bvalid),
    .io_frontend_bresp          (dma_core_bresp),
    .io_frontend_bid            (dma_core_bid),
    .io_frontend_buser          (/* TODO */),

    .io_frontend_arready        (dma_core_arready),
    .io_frontend_arvalid        (dma_core_arvalid),
    .io_frontend_araddr         (dma_core_araddr[31:0]),
    .io_frontend_arprot         (dma_core_arprot),
    .io_frontend_arid           (dma_core_arid),
    .io_frontend_aruser         (/* TODO */),
    .io_frontend_arlen          (dma_core_arlen),
    .io_frontend_arsize         (dma_core_arsize),
    .io_frontend_arburst        (dma_core_arburst),
    .io_frontend_arlock         (dma_core_arlock),
    .io_frontend_arcache        (dma_core_arcache),
    .io_frontend_arqos          (dma_core_arqos),

    .io_frontend_rready         (dma_core_rready),
    .io_frontend_rvalid         (dma_core_rvalid),
    .io_frontend_rresp          (dma_core_rresp),
    .io_frontend_rdata          (dma_core_rdata[63:0]),
    .io_frontend_rlast          (dma_core_rlast),
    .io_frontend_rid            (dma_core_rid),
    .io_frontend_ruser          (/* TODO */),

    // MIP
    .io_meip                    (io_extIntrs[1:0]),

    // difftest
    .difftest_ref_clock              (difftest_ref_clock),
    .difftest_pcie_clock             (difftest_pcie_clock),

    // C2H (DUT -> Host)
    .difftest_to_host_axis_ready     (difftest_to_host_axis_ready),
    .difftest_to_host_axis_valid     (difftest_to_host_axis_valid),
    .difftest_to_host_axis_bits_data (difftest_to_host_axis_bits_data),
    .difftest_to_host_axis_bits_last (difftest_to_host_axis_bits_last),

    // Config AXI4-Lite (note: SimTop uses flat naming without _bits)
    .difftest_cfg_awvalid            (difftest_cfg_aw_valid),
    .difftest_cfg_awready            (difftest_cfg_aw_ready),
    .difftest_cfg_awaddr             (difftest_cfg_aw_bits_addr),
    .difftest_cfg_awprot             (difftest_cfg_aw_bits_prot),
    .difftest_cfg_wvalid             (difftest_cfg_w_valid),
    .difftest_cfg_wready             (difftest_cfg_w_ready),
    .difftest_cfg_wdata              (difftest_cfg_w_bits_data),
    .difftest_cfg_wstrb              (difftest_cfg_w_bits_strb),
    .difftest_cfg_bvalid             (difftest_cfg_b_valid),
    .difftest_cfg_bready             (difftest_cfg_b_ready),
    .difftest_cfg_bresp              (difftest_cfg_b_bits_resp),
    .difftest_cfg_arvalid            (difftest_cfg_ar_valid),
    .difftest_cfg_arready            (difftest_cfg_ar_ready),
    .difftest_cfg_araddr             (difftest_cfg_ar_bits_addr),
    .difftest_cfg_arprot             (difftest_cfg_ar_bits_prot),
    .difftest_cfg_rvalid             (difftest_cfg_r_valid),
    .difftest_cfg_rready             (difftest_cfg_r_ready),
    .difftest_cfg_rdata              (difftest_cfg_r_bits_data),
    .difftest_cfg_rresp              (difftest_cfg_r_bits_resp),

    .difftest_clock_enable           (difftest_clock_enable),

    // Control outputs
    .difftest_HOST_IO_RESET          (difftest_HOST_IO_RESET),
    .difftest_HOST_IO_DIFFTEST_ENABLE(difftest_HOST_IO_DIFFTEST_ENABLE),

    .difftest_exit              (/* TODO */),
    .difftest_step              (/* TODO */),
    .difftest_perfCtrl_clean    (/* TODO */),
    .difftest_perfCtrl_dump     (/* TODO */),
    .difftest_logCtrl_begin     (/* TODO */),
    .difftest_logCtrl_end       (/* TODO */),
    .difftest_logCtrl_level     (/* TODO */),
    .difftest_uart_out_valid    (/* TODO */),
    .difftest_uart_out_ch       (/* TODO */),
    .difftest_uart_in_valid     (/* TODO */),
    .difftest_uart_in_ch        (/* TODO */)
);
endmodule
