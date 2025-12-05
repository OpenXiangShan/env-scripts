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
input [1:0] memory_0_rresp,
input memory_0_rlast,
input io_clock,
input io_reset,
input io_pll0_lock,
output [31:0] io_pll0_ctrl_0,
output [31:0] io_pll0_ctrl_1,
output [31:0] io_pll0_ctrl_2,
output [31:0] io_pll0_ctrl_3,
output [31:0] io_pll0_ctrl_4,
output [31:0] io_pll0_ctrl_5,
input [10:0] io_systemjtag_mfr_id,
input [15:0] io_systemjtag_part_number,
input [3:0] io_systemjtag_version,
output io_debug_reset,
input io_cacheable_check_req_0_valid,
input [35:0] io_cacheable_check_req_0_bits_addr,
input [1:0] io_cacheable_check_req_0_bits_size,
input [2:0] io_cacheable_check_req_0_bits_cmd,
input io_cacheable_check_req_1_bits_valid,
input [35:0] io_cacheable_check_req_1_bits_addr,
input [1:0] io_cacheable_check_req_1_bits_size,
input [2:0] io_cacheable_check_req_1_bits_cmd,
output io_cacheable_check_resp_0_1d,
output io_cacheable_check_resp_0_st,
output io_cacheable_check_resp_0_instr,
output io_cacheable_check_resp_0_mmio,
output io_cacheable_check_resp_1_1d,
output io_cacheable_check_resp_1_st,
output io_cacheable_check_resp_1_instr,
output io_cacheable_check_resp_1_mmio,
output io_riscv_halt_0,
output io_riscv_halt_1,

input          difftest_ref_clock,
               difftest_to_host_axis_ready,
output         difftest_to_host_axis_valid,
output [511:0] difftest_to_host_axis_bits_data,
output         difftest_to_host_axis_bits_last,
               difftest_clock_enable
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
//  wire [31:0]   pll0_config_5 = 32'h3;
  wire [5:0]  xlnfpga_mem_awid, xlnfpga_mem_arid;
  wire [11:0] xlnfpga_dma_awid, xlnfpga_dma_arid, xlnfpga_dma_bid, xlnfpga_dma_rid;

  assign mem_core_awid = {8'b0, xlnfpga_mem_awid};  // 6bit -> 14bit
  assign mem_core_arid = {8'b0, xlnfpga_mem_arid};  // 6bit -> 14bit

  assign dma_core_bid = {2'b0, xlnfpga_dma_bid};  // 12bit -> 14bit
  assign dma_core_rid = {2'b0, xlnfpga_dma_rid};  // 12bit -> 14bit

assign cpu_to_soc = 32'h0;

XlnFpgaTop  XlnFpgaTop_inst(
  // Basic clocks and resets
  .io_aresetn                      (sys_rstn_i),
  .io_aclk                         (inter_soc_clk),
  .io_core_clk_0                   (inter_soc_clk),
  .io_rtc_clk                      (tmclk),
  .io_reset_vector                 (48'h10000000),
  .io_ddr_offset                   (48'h80000000),
  .io_ext_intr                     ({192'b0, io_extIntrs}),  // 64bit -> 256bit
  
  // JTAG
  .io_systemjtag_jtag_TCK          (io_systemjtag_jtag_TCK),
  .io_systemjtag_jtag_TMS          (io_systemjtag_jtag_TMS),
  .io_systemjtag_jtag_TDI          (io_systemjtag_jtag_TDI),
  .io_systemjtag_jtag_TDO_data     (io_systemjtag_jtag_TDO_data),
  .io_systemjtag_jtag_TDO_driven   (io_systemjtag_jtag_TDO_driven),
  .io_systemjtag_reset             (io_systemjtag_reset),

  // Memory AXI (m_axi_mem_0)
  .m_axi_mem_0_awvalid             (mem_core_awvalid),
  .m_axi_mem_0_awready             (mem_core_awready),
  .m_axi_mem_0_awid                (xlnfpga_mem_awid),  // 6bit -> 14bit
  .m_axi_mem_0_awaddr              ({12'b0, mem_core_awaddr}),  // 48bit -> 36bit
  .m_axi_mem_0_awlen               (mem_core_awlen),
  .m_axi_mem_0_awsize              (mem_core_awsize),
  .m_axi_mem_0_awburst             (mem_core_awburst),
  .m_axi_mem_0_awlock              (mem_core_awlock),
  .m_axi_mem_0_awcache             (mem_core_awcache),
  .m_axi_mem_0_awprot              (mem_core_awprot),
  .m_axi_mem_0_awqos               (mem_core_awqos),
  .m_axi_mem_0_awregion            (/* unused */),
  .m_axi_mem_0_wvalid              (mem_core_wvalid),
  .m_axi_mem_0_wready              (mem_core_wready),
  .m_axi_mem_0_wdata               (mem_core_wdata),
  .m_axi_mem_0_wstrb               (mem_core_wstrb),
  .m_axi_mem_0_wlast               (mem_core_wlast),
  .m_axi_mem_0_bvalid              (mem_core_bvalid),
  .m_axi_mem_0_bready              (mem_core_bready),
  .m_axi_mem_0_bid                 (mem_core_bid[5:0]),  // 14bit -> 6bit
  .m_axi_mem_0_bresp               (mem_core_bresp),
  .m_axi_mem_0_arvalid             (mem_core_arvalid),
  .m_axi_mem_0_arready             (mem_core_arready),
  .m_axi_mem_0_arid                (xlnfpga_mem_arid),  // 6bit -> 14bit
  .m_axi_mem_0_araddr              ({12'b0, mem_core_araddr}),  // 48bit -> 36bit
  .m_axi_mem_0_arlen               (mem_core_arlen),
  .m_axi_mem_0_arsize              (mem_core_arsize),
  .m_axi_mem_0_arburst             (mem_core_arburst),
  .m_axi_mem_0_arlock              (mem_core_arlock),
  .m_axi_mem_0_arcache             (mem_core_arcache),
  .m_axi_mem_0_arprot              (mem_core_arprot),
  .m_axi_mem_0_arqos               (mem_core_arqos),
  .m_axi_mem_0_arregion            (/* unused */),
  .m_axi_mem_0_rvalid              (mem_core_rvalid),
  .m_axi_mem_0_rready              (mem_core_rready),
  .m_axi_mem_0_rid                 (mem_core_rid[5:0]),  // 14bit -> 6bit
  .m_axi_mem_0_rdata               (mem_core_rdata),
  .m_axi_mem_0_rresp               (mem_core_rresp),
  .m_axi_mem_0_rlast               (mem_core_rlast),

  // High-speed AXI Master (m_axi_hs)
  .m_axi_hs_awvalid                (/* unused */),
  .m_axi_hs_awready                (1'b0),
  .m_axi_hs_awid                   (/* unused */),
  .m_axi_hs_awaddr                 (/* unused */),
  .m_axi_hs_awlen                  (/* unused */),
  .m_axi_hs_awsize                 (/* unused */),
  .m_axi_hs_awburst                (/* unused */),
  .m_axi_hs_awlock                 (/* unused */),
  .m_axi_hs_awcache                (/* unused */),
  .m_axi_hs_awprot                 (/* unused */),
  .m_axi_hs_awqos                  (/* unused */),
  .m_axi_hs_awregion               (/* unused */),
  .m_axi_hs_arvalid                (/* unused */),
  .m_axi_hs_arready                (1'b0),
  .m_axi_hs_arid                   (/* unused */),
  .m_axi_hs_araddr                 (/* unused */),
  .m_axi_hs_arlen                  (/* unused */),
  .m_axi_hs_arsize                 (/* unused */),
  .m_axi_hs_arburst                (/* unused */),
  .m_axi_hs_arlock                 (/* unused */),
  .m_axi_hs_arcache                (/* unused */),
  .m_axi_hs_arprot                 (/* unused */),
  .m_axi_hs_arqos                  (/* unused */),
  .m_axi_hs_arregion               (/* unused */),
  .m_axi_hs_wvalid                 (/* unused */),
  .m_axi_hs_wready                 (1'b0),
  .m_axi_hs_wdata                  (/* unused */),
  .m_axi_hs_wstrb                  (/* unused */),
  .m_axi_hs_wlast                  (/* unused */),
  .m_axi_hs_bvalid                 (1'b0),
  .m_axi_hs_bready                 (/* unused */),
  .m_axi_hs_bid                    (6'b0),
  .m_axi_hs_bresp                  (2'b0),
  .m_axi_hs_rvalid                 (1'b0),
  .m_axi_hs_rready                 (/* unused */),
  .m_axi_hs_rid                    (6'b0),
  .m_axi_hs_rdata                  (256'b0),
  .m_axi_hs_rresp                  (2'b0),
  .m_axi_hs_rlast                  (1'b0),


  // Config/Peripheral AXI (m_axi_cfg)
  .m_axi_cfg_awvalid               (peri_awvalid),
  .m_axi_cfg_awready               (peri_awready),
  .m_axi_cfg_awid                  (peri_awid),
  .m_axi_cfg_awaddr                ({17'b0, peri_awaddr}),  // 31bit -> 48bit
  .m_axi_cfg_awlen                 (peri_awlen),
  .m_axi_cfg_awsize                (peri_awsize),
  .m_axi_cfg_awburst               (peri_awburst),
  .m_axi_cfg_awlock                (peri_awlock),
  .m_axi_cfg_awcache               (peri_awcache),
  .m_axi_cfg_awprot                (peri_awprot),
  .m_axi_cfg_awqos                 (peri_awqos),
  .m_axi_cfg_awregion              (/* unused */),
  .m_axi_cfg_wvalid                (peri_wvalid),
  .m_axi_cfg_wready                (peri_wready),
  .m_axi_cfg_wdata                 (peri_wdata),
  .m_axi_cfg_wstrb                 (peri_wstrb),
  .m_axi_cfg_wlast                 (peri_wlast),
  .m_axi_cfg_bvalid                (peri_bvalid),
  .m_axi_cfg_bready                (peri_bready),
  .m_axi_cfg_bid                   (peri_bid),
  .m_axi_cfg_bresp                 (peri_bresp),
  .m_axi_cfg_arvalid               (peri_arvalid),
  .m_axi_cfg_arready               (peri_arready),
  .m_axi_cfg_arid                  (peri_arid),
  .m_axi_cfg_araddr                ({17'b0, peri_araddr}),  // 48bit -> 31bit
  .m_axi_cfg_arlen                 (peri_arlen),
  .m_axi_cfg_arsize                (peri_arsize),
  .m_axi_cfg_arburst               (peri_arburst),
  .m_axi_cfg_arlock                (peri_arlock),
  .m_axi_cfg_arcache               (peri_arcache),
  .m_axi_cfg_arprot                (peri_arprot),
  .m_axi_cfg_arqos                 (peri_arqos),
  .m_axi_cfg_arregion              (/* unused */),
  .m_axi_cfg_rvalid                (peri_rvalid),
  .m_axi_cfg_rready                (peri_rready),
  .m_axi_cfg_rid                   (peri_rid),
  .m_axi_cfg_rdata                 (peri_rdata),
  .m_axi_cfg_rresp                 (peri_rresp),
  .m_axi_cfg_rlast                 (peri_rlast),

  // DMA AXI Slave (s_axi_hs) - connected to dma_core ports
  .s_axi_hs_awvalid                (dma_core_awvalid),
  .s_axi_hs_awready                (dma_core_awready),
  .s_axi_hs_awid                   (dma_core_awid[11:0]),  // 14bit -> 12bit
  .s_axi_hs_awaddr                 ({12'b0, dma_core_awaddr}),  // 36bit -> 48bit
  .s_axi_hs_awlen                  (dma_core_awlen),
  .s_axi_hs_awsize                 (dma_core_awsize),
  .s_axi_hs_awburst                (dma_core_awburst),
  .s_axi_hs_awlock                 (dma_core_awlock),
  .s_axi_hs_awcache                (dma_core_awcache),
  .s_axi_hs_awprot                 (dma_core_awprot),
  .s_axi_hs_awqos                  (dma_core_awqos),
  .s_axi_hs_awregion               (4'b0),
  .s_axi_hs_wvalid                 (dma_core_wvalid),
  .s_axi_hs_wready                 (dma_core_wready),
  .s_axi_hs_wdata                  (dma_core_wdata),
  .s_axi_hs_wstrb                  (dma_core_wstrb),
  .s_axi_hs_wlast                  (dma_core_wlast),
  .s_axi_hs_bvalid                 (dma_core_bvalid),
  .s_axi_hs_bready                 (dma_core_bready),
  .s_axi_hs_bid                    (xlnfpga_dma_bid),  // 14bit -> 12bit
  .s_axi_hs_bresp                  (dma_core_bresp),
  .s_axi_hs_arvalid                (dma_core_arvalid),
  .s_axi_hs_arready                (dma_core_arready),
  .s_axi_hs_arid                   (dma_core_arid[11:0]),  // 14bit -> 12bit
  .s_axi_hs_araddr                 ({12'b0, dma_core_araddr}),  // 36bit -> 48bit
  .s_axi_hs_arlen                  (dma_core_arlen),
  .s_axi_hs_arsize                 (dma_core_arsize),
  .s_axi_hs_arburst                (dma_core_arburst),
  .s_axi_hs_arlock                 (dma_core_arlock),
  .s_axi_hs_arcache                (dma_core_arcache),
  .s_axi_hs_arprot                 (dma_core_arprot),
  .s_axi_hs_arqos                  (dma_core_arqos),
  .s_axi_hs_arregion               (4'b0),
  .s_axi_hs_rvalid                 (dma_core_rvalid),
  .s_axi_hs_rready                 (dma_core_rready),
  .s_axi_hs_rid                    (xlnfpga_dma_rid),  // 14bit -> 12bit
  .s_axi_hs_rdata                  (dma_core_rdata),
  .s_axi_hs_rresp                  (dma_core_rresp),
  .s_axi_hs_rlast                  (dma_core_rlast),

  //difftest
  .difftest_ref_clock              (difftest_ref_clock),
  .difftest_to_host_axis_ready     (difftest_to_host_axis_ready),
  .difftest_to_host_axis_valid     (difftest_to_host_axis_valid),
  .difftest_to_host_axis_bits_data (difftest_to_host_axis_bits_data),
  .difftest_to_host_axis_bits_last (difftest_to_host_axis_bits_last),
  .difftest_clock_enable           (difftest_clock_enable)
);


endmodule
