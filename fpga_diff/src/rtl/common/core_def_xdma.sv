`include "sys_define.vh"
`ifndef NO_DIFF
`include "DifftestMacros.svh"
`endif

`ifndef XDMA_PCIE_LANES
`define XDMA_PCIE_LANES 4
`endif

`ifndef CONFIG_RANK_WIDTH
`define CONFIG_RANK_WIDTH 1
`endif

module core_def (
      input                                      ddr_clk_p,
      input                                      ddr_clk_n,
      input                                      tmclk,
      input                                      cqetmclk,
      output                                     init_calib_complete,
      output                                     cpu_rd_qspi_valid,
      output                                     cpu_wr_ddr_valid,
      input                                      sys_clk_i,
      input                                      dev_clk_i,
      input                                      sys_rstn,
      input                                      cpu_rstn,
      input                                      rstn_sw4,
`ifdef  XS_XDMA_EP
      input       [`XDMA_PCIE_LANES-1:0]         pci_ep_rxn,
      input       [`XDMA_PCIE_LANES-1:0]         pci_ep_rxp,
      output      [`XDMA_PCIE_LANES-1:0]         pci_ep_txn,
      output      [`XDMA_PCIE_LANES-1:0]         pci_ep_txp,
      input                                      pcie_ep_gt_ref_clk_n,
      input                                      pcie_ep_gt_ref_clk_p,
      output                                     pcie_ep_lnk_up,
      input                                      pcie_ep_perstn,
`endif
`ifdef  XS_UART
      input                                      uart0_sin,
      input                                      uart1_sin,
      input                                      uart2_sin,
      output                                     uart0_sout,
      output                                     uart1_sout,
      output                                     uart2_sout,
`endif
      output                                     sd_card_clk_out,
      output                                     sd_cmd_out     ,
      output                                     sd_cmd_out_oe  ,
      output          [3:0]                      sd_dat_out     ,
      output          [3:0]                      sd_dat_out_oe  ,
      input                                      sd_cmd_in      ,
      input           [3:0]                      sd_dat_in      ,
      input                                      sd_card_det_in ,
      input                                      sd_card_wp_in  ,
      output      [2:0]                          sd_vdd1_sel                    ,
      output                                     sd_vdd1_on                     ,
      output      [1:0]                          uhs1_drv_sth                   ,
      output                                     uhs1_swvolt_en                 ,
      output                                     sd_led_control                 ,
`ifndef UVHS
      output      [`CONFIG_RANK_WIDTH-1:0]       DDR_CK_T                       ,
      output      [`CONFIG_RANK_WIDTH-1:0]       DDR_CK_C                       ,
      output      [`CONFIG_RANK_WIDTH-1:0]       DDR_CKE                        ,
      output      [`CONFIG_RANK_WIDTH-1:0]       DDR_CS_N                       ,
      output      [`CONFIG_RANK_WIDTH-1:0]       DDR_ODT                        ,
      output                                     DDR_ACT_N                      ,
      output      [1:0]                          DDR_BG                         ,
      output      [1:0]                          DDR_BA                         ,
      output      [16:0]                         DDR_A                          ,
      output                                     DDR_RESET_N                    ,
      inout           [7:0]                      DDR_DM_N                       ,
      inout           [63:0]                     DDR_DQ                         ,
      inout           [7:0]                      DDR_DQS_T                      ,
      inout           [7:0]                      DDR_DQS_C                      ,
`endif

      //==JTAG

      input           io_systemjtag_jtag_TCK,         // come from gpio
      input           io_systemjtag_jtag_TMS,         // come from gpio
      input           io_systemjtag_jtag_TDI,         // come from gpio
      output          io_systemjtag_jtag_TDO_data,    // come from gpio
      output          io_systemjtag_jtag_TDO_driven,  // come from gpio
      input           io_systemjtag_reset,            // come from gpio

      //==gmac
`ifdef  XS_GMAC
      output                                     io_gmac_mdo_oe                 ,
      output                                     io_gmac_mdo                    ,
      output                                     io_gmac_mck_out                ,
      input                                      io_gmac_mdi                    ,
      output                                     io_gmac_tx_clk                 ,
      output                                     io_gmac_txd_en                 ,
      input                                      io_gmac_rx_clk                 ,
      input                                      io_gmac_rxd_vld                ,
      input             [3:0]                    io_gmac_rxd                    ,
      output            [3:0]                    io_gmac_txd                    ,
`endif

      //==input
      input                                      dft_lgc_rst_n                  ,
      input                                      dft_se                         ,
      //input                                      xtal_clk_24m                 ,
      input           [1:0]                      chip_mode_i                    ,
      //input           [53-1:0]                   pad_c                        ,
      input                                      dft_crg_rst_n
);

// Unbind useless output port {{{
assign cpu_rd_qspi_valid = 0;
assign cpu_wr_ddr_valid = 0;
assign uart1_sout = 0;
assign uart2_sout = 0;
assign sd_card_clk_out = 0;
assign sd_cmd_out = 0;
assign sd_cmd_out_oe = 0;
assign sd_dat_out = 0;
assign sd_dat_out_oe = 0;
assign sd_vdd1_sel = 0;
assign sd_vdd1_on = 0;
assign uhs1_drv_sth = 0;
assign uhs1_swvolt_en = 0;
assign sd_led_control = 0;
// }}} Unbind useless output port

wire                       axi_bclk_sync_rstn        ;
wire                       ddr_bus_clk               ;
wire                       ddr_bclk_sync_rstn        ;
`ifdef  XS_UART
wire                       uart_pclk                 ;
wire                       uart_pclk_sync_rstn       ;
wire                       uart_sclk                 ;
wire                       uart_sclk_sync_rstn       ;
`endif
wire                       qspi_sclk                 ;
wire                       qspi_pclk                 ;
wire                       qspi_pclk_sync_rstn       ;
wire                       qspi_hclk                 ;
wire                       qspi_hclk_sync_rstn       ;
wire                       qspi_ref_clk              ;
wire                       qspi_rclk_sync_rstn       ;
wire                       sd_axi_clk                ;
wire                       sd_aclk_sync_rstn         ;
wire                       sd_ahb_clk                ;
wire                       sd_hclk_sync_rstn         ;
wire                       sd_bclk                   ;
wire                       sd_bclk_sync_rstn         ;
wire                       sd_tmclk                  ;
wire                       sd_tclk_sync_rstn         ;
wire                       sd_cqetmclk               ;
wire                       sd_cqetclk_sync_rstn      ;
wire                                           apb_bus_clk_100m               ;
wire                                           apb_bus_rst_n                  ;
wire            [31:0]                         hpm_dig_result                 ;
wire            [15:0]                         syscfg_paddr_mix               ;
wire                                           syscfg_psel                    ;
wire                                           syscfg_penable                 ;
wire                                           syscfg_pwrite                  ;
wire            [31:0]                         syscfg_pwdata                  ;
wire                                           syscfg_pready                  ;
wire            [31:0]                         syscfg_prdata                  ;
wire                                           syscfg_pslverr                 ;
wire                                           sd_qos_sel_cfg                 ;
wire                                           dp_qos_sel_cfg                 ;
wire                                           gpu_qos_sel_cfg                ;
wire                                           gmac_qos_sel_cfg               ;
wire                                           dma_qos_sel_cfg                ;
wire                                           usb_qos_sel_cfg                ;
wire            [11:0]                         hpm_data_svt                   ;
wire            [11:0]                         hpm_data_lvt                   ;
wire            [11:0]                         hpm_data_ulvt                  ;
wire            [3:0]                          cfg_gpu_m_awqos                ;
wire            [3:0]                          cfg_gpu_m_arqos                ;
wire            [3:0]                          cfg_dp_m_awqos                 ;
wire            [3:0]                          cfg_dp_m_arqos                 ;
wire            [3:0]                          cfg_gmac_m_awqos               ;
wire            [3:0]                          cfg_gmac_m_arqos               ;
wire            [3:0]                          cfg_sd_m_awqos                 ;
wire            [3:0]                          cfg_sd_m_arqos                 ;
wire            [3:0]                          cfg_dma_m_awqos                ;
wire            [3:0]                          cfg_dma_m_arqos                ;
wire                                           cfg_gpu_addr_offset_en         ;
wire                                           cfg_gmac_addr_offset_en        ;
wire                                           sdio_voltage_sw_cfg            ;
wire            [3:0]                          gpio_test_mux_cfg              ;
wire                                           ddr_rrb_sram_rme_cfg           ;
wire            [3:0]                          ddr_rrb_sram_rm_cfg            ;
wire                                           ddr_data_sram_rme_cfg          ;
wire            [3:0]                          ddr_data_sram_rm_cfg           ;
wire            [15:0]                         cpu_sram_cfg                   ;
wire            [1:0]                          usb3_timing_opt_cfg            ;
wire                                           dp_frame_start                 ;
wire                                           ahb_bus_clk_200m               ;
wire                                           axi_bus_clk_400m               ;
wire                                           ahb_bus_rst_n                  ;
wire                                           axi_bus_rst_n                  ;
wire                                           gpio0_fun_sel                  ;
wire                                           gpio1_fun_sel                  ;
wire                                           gpio2_fun_sel                  ;
wire                                           gpio3_fun_sel                  ;
wire                                           gpio4_fun_sel                  ;
wire                                           gpio5_fun_sel                  ;
wire                                           gpio6_fun_sel                  ;
wire                                           gpio7_fun_sel                  ;
wire                                           gpio8_fun_sel                  ;
wire                                           gpio9_fun_sel                  ;
wire                                           gpio10_fun_sel                 ;
wire                                           gpio11_fun_sel                 ;
wire                                           gpio12_fun_sel                 ;
wire                                           gpio13_fun_sel                 ;
wire                                           gpio14_fun_sel                 ;
wire                                           gpio15_fun_sel                 ;
wire                                           gpio16_fun_sel                 ;
wire                                           gpio17_fun_sel                 ;
wire                                           gpio18_fun_sel                 ;
wire                                           gpio19_fun_sel                 ;
wire                                           gpio20_fun_sel                 ;
wire                                           gpio21_fun_sel                 ;
wire                                           gpio22_fun_sel                 ;
wire                                           gpio23_fun_sel                 ;
wire                                           gpio24_fun_sel                 ;
wire                                           gpio25_fun_sel                 ;
wire                                           gpio26_fun_sel                 ;
wire                                           gpio27_fun_sel                 ;
wire                                           gpio28_fun_sel                 ;
wire                                           gpio29_fun_sel                 ;
wire                                           gpio30_fun_sel                 ;
wire                                           gpio31_fun_sel                 ;
wire                                           gpio32_fun_sel                 ;
wire                                           gpio33_fun_sel                 ;
wire                                           gpio34_fun_sel                 ;
wire                                           gpio35_fun_sel                 ;
wire                                           gpio36_fun_sel                 ;
wire                                           gpio37_fun_sel                 ;
wire                                           gpio38_fun_sel                 ;
wire                                           gpio39_fun_sel                 ;
wire                                           gpio40_fun_sel                 ;
wire                                           gpio41_fun_sel                 ;
wire                                           gpio42_fun_sel                 ;
wire                                           gpio43_fun_sel                 ;
wire                                           gpio44_fun_sel                 ;
wire                                           gpio45_fun_sel                 ;
wire                                           gpio46_fun_sel                 ;
wire                                           gpio47_fun_sel                 ;
wire                                           gpio48_fun_sel                 ;
wire                                           gpio49_fun_sel                 ;
wire                                           gpio50_fun_sel                 ;
wire                                           gpio51_fun_sel                 ;
wire                                           gpio52_fun_sel                 ;
`ifdef  XS_GMAC
wire            [31:0]                         gmac_m_awaddr                  ;
wire            [31:0]                         gmac_m_araddr                  ;
`endif
wire            [31:0]                         gpu_m_araddr                   ;
wire            [31:0]                         gpu_m_awaddr                   ;
wire            [31:0]                         qspi_haddr                     ;
wire            [31:0]                         gpu_haddr                      ;
wire            [31:0]                         dma_haddr                      ;
wire            [31:0]                         sd_haddr                       ;
wire            [31:0]                         usb_haddr                      ;
wire            [31:0]                         qos_haddr                      ;
wire            [52:0]                         io_function_select             ;
`ifdef  XS_GMAC
wire            [39:0]                         gmac_m_awaddr_mix              ;
wire            [39:0]                         gmac_m_araddr_mix              ;
`endif
wire            [39:0]                         gpu_m_araddr_mix               ;
wire            [39:0]                         gpu_m_awaddr_mix               ;
`ifdef  XS_QSPI2ROM
wire            [31:0]                         qspi_haddr_mix_pre                 ;
(*mark_debug = "true"*) wire            [31:0]                         qspi_haddr_mix                 ;
`endif
wire            [31:0]                         gpu_haddr_mix                  ;
wire            [31:0]                         dma_haddr_mix                  ;
wire            [31:0]                         sd_haddr_mix                   ;
wire            [63:0]                         usb_haddr_mix                  ;
wire            [31:0]                         qos_haddr_mix                  ;
wire                                           sd_wakeup_int                  ;
wire                                           sd_int                         ;
wire                                           dp_de_int                      ;
wire                                           dp_se_int                      ;
wire                                           hdmiphy_int                    ;
wire                                           hdmitx_wakeup                  ;
wire                                           hdmitx_int                     ;
wire                                           wdt_int                        ;
wire                                           gpu_int                        ;
//`ifdef  XS_GMAC
wire                                           gmac_lpi_int                   ;
wire                                           gmac_sbd_int                   ;
wire                                           gmac_pmt_int                   ;
//`endif
(*mark_debug = "true"*) wire                                           qspi_int                       ;
wire                                           i2s_int                        ;
//`ifdef  XS_UART
wire                                           uart2_int                      ;
wire                                           uart1_int                      ;
(*mark_debug = "true"*) wire                                           uart0_int                      ;
//`endif
wire                                           i2c2_int                       ;
wire                                           i2c1_int                       ;
wire                                           i2c0_int                       ;
wire            [31:0]                         gpio_int                       ;
wire                                           dma_int                        ;
wire            [63:0]                         cpu_int_mix                        ;
wire            [3:0]                          sd_m_awqos                     ;
wire            [3:0]                          sd_m_arqos                     ;
wire            [3:0]                          dp_m_awqos                     ;
wire            [3:0]                          dp_m_arqos                     ;
wire            [3:0]                          dma_m_awqos                    ;
wire            [3:0]                          dma_m_arqos                    ;
wire            [3:0]                          gmac_m_awqos_mix               ;
wire            [3:0]                          gmac_m_arqos_mix               ;
wire            [3:0]                          sd_m_awqos_mix                 ;
wire            [3:0]                          sd_m_arqos_mix                 ;
wire            [3:0]                          dp_m_awqos_mix                 ;
wire            [3:0]                          dp_m_arqos_mix                 ;
wire            [3:0]                          dma_m_awqos_mix                ;
wire            [3:0]                          dma_m_arqos_mix                ;
wire            [3:0]                          gpu_m_awqos_mix                ;
wire            [3:0]                          gpu_m_arqos_mix                ;
wire                                           cpu_pll_clk_test               ;
wire                                           cpu_pll_lock_test              ;
wire            [1:0]                          soc_pll_clk_test               ;
wire            [4:0]                          soc_pll_lock_test              ;
wire                                           ddr_pll_lock_test              ;
wire                                           dft_mode                       ;
wire                                           scan_mode                      ;
wire                                           sys_peri_rst_n                 ;
wire            [13:0]                         data_cpu_bridge_m2s_awid       ;
wire            [35:0]                         data_cpu_bridge_m2s_awaddr     ;
wire            [7:0]                          data_cpu_bridge_m2s_awlen      ;
wire            [2:0]                          data_cpu_bridge_m2s_awsize     ;
wire            [1:0]                          data_cpu_bridge_m2s_awburst    ;
wire                                           data_cpu_bridge_m2s_awlock     ;
wire            [3:0]                          data_cpu_bridge_m2s_awcache    ;
wire            [2:0]                          data_cpu_bridge_m2s_awprot     ;
wire                                           data_cpu_bridge_m2s_awvalid    ;
wire            [255:0]                        data_cpu_bridge_m2s_wdata      ;
wire            [31:0]                         data_cpu_bridge_m2s_wstrb      ;
wire                                           data_cpu_bridge_m2s_wlast      ;
wire                                           data_cpu_bridge_m2s_wvalid     ;
wire                                           data_cpu_bridge_m2s_bready     ;
wire            [13:0]                         data_cpu_bridge_m2s_arid       ;
wire            [35:0]                         data_cpu_bridge_m2s_araddr     ;
wire            [7:0]                          data_cpu_bridge_m2s_arlen      ;
wire            [2:0]                          data_cpu_bridge_m2s_arsize     ;
wire            [1:0]                          data_cpu_bridge_m2s_arburst    ;
wire                                           data_cpu_bridge_m2s_arlock     ;
wire            [3:0]                          data_cpu_bridge_m2s_arcache    ;
wire            [2:0]                          data_cpu_bridge_m2s_arprot     ;
wire                                           data_cpu_bridge_m2s_arvalid    ;
wire                                           data_cpu_bridge_m2s_rready     ;
wire                                           data_cpu_bridge_s2m_awready    ;
wire                                           data_cpu_bridge_s2m_wready     ;
wire            [13:0]                         data_cpu_bridge_s2m_bid        ;
wire            [1:0]                          data_cpu_bridge_s2m_bresp      ;
wire                                           data_cpu_bridge_s2m_bvalid     ;
wire                                           data_cpu_bridge_s2m_arready    ;
wire            [13:0]                         data_cpu_bridge_s2m_rid        ;
wire            [255:0]                        data_cpu_bridge_s2m_rdata      ;
wire            [1:0]                          data_cpu_bridge_s2m_rresp      ;
wire                                           data_cpu_bridge_s2m_rlast      ;
wire                                           data_cpu_bridge_s2m_rvalid     ;
wire            [3:0]                          data_cpu_bridge_m2s_awqos      ;
wire            [3:0]                          data_cpu_bridge_m2s_arqos      ;
wire                                           dft_glb_gt_se                  ;
wire                                           dft_dp_rst_disable             ;
wire                                           dft_dp_ram_hold                ;
wire                                           dft_dp_cg_en                   ;
wire                                           dft_dp_pclk_disable            ;
wire                                           dft_dp_aclk_disable            ;
wire                                           dft_dp_mclk_disable            ;
wire                                           dft_dp_pixlclk_disable         ;
wire                                           sys_bus_rst_n                  ;
wire                                           cpu_bak_clk                    ;
wire                                           sys_cpu_rst                    ;
wire            [3:0]                          cpu_pll0_bypass_cfg            ;
wire                                           cpu_jtag_tck                   ;
wire                                           cpu_jtag_tms                   ;
wire                                           cpu_jtag_tdi                   ;
wire                                           cpu_jtag_trst                  ;
wire                                           cpu_jtag_tdo                   ;
wire                                           cpu_jtag_tdo_oen               ;
wire            [11:0]                         cpu_pll_test_info              ;

(*mark_debug = "true"*) wire                                       cpu2ddr_s2m_awready            ;
(*mark_debug = "true"*) wire                                       cpu2ddr_s2m_wready             ;
wire            [13:0]                          cpu2ddr_s2m_bid_mix            ;
(*mark_debug = "true"*) wire                                       cpu2ddr_s2m_bvalid             ;
(*mark_debug = "true"*) wire                                       cpu2ddr_s2m_arready            ;
wire            [13:0]                          cpu2ddr_s2m_rid_mix            ;
(*mark_debug = "true"*) wire                                       cpu2ddr_s2m_rlast              ;
(*mark_debug = "true"*) wire                                       cpu2ddr_s2m_rvalid             ;
wire            [13:0]                          cpu2ddr_m2s_awid               ;
(*mark_debug = "true"*) wire            [35:0]                     cpu2ddr_m2s_awaddr             ;
wire                                            cpu2ddr_m2s_awlock             ;
(*mark_debug = "true"*) wire                                       cpu2ddr_m2s_awvalid            ;
(*mark_debug = "true"*) wire                                       cpu2ddr_m2s_wlast              ;
(*mark_debug = "true"*) wire                                       cpu2ddr_m2s_wvalid             ;
(*mark_debug = "true"*) wire                                       cpu2ddr_m2s_bready             ;
wire            [13:0]                          cpu2ddr_m2s_arid               ;
(*mark_debug = "true"*) wire            [35:0]                     cpu2ddr_m2s_araddr             ;
wire                                            cpu2ddr_m2s_arlock             ;
(*mark_debug = "true"*) wire                                       cpu2ddr_m2s_arvalid            ;
(*mark_debug = "true"*) wire                                       cpu2ddr_m2s_rready             ;

(*mark_debug = "true"*) wire                                           cpu2cfg_s2m_awready            ;
(*mark_debug = "true"*) wire                                           cpu2cfg_s2m_wready             ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_s2m_bid                ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_s2m_bresp              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_s2m_bvalid             ;
(*mark_debug = "true"*) wire                                           cpu2cfg_s2m_arready            ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_s2m_rid                ;
(*mark_debug = "true"*) wire            [63:0]                         cpu2cfg_s2m_rdata              ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_s2m_rresp              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_s2m_rlast              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_s2m_rvalid             ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_m2s_awid               ;
(*mark_debug = "true"*) wire            [30:0]                         cpu2cfg_m2s_awaddr             ;
(*mark_debug = "true"*) wire            [3:0]                          cpu2cfg_m2s_awregion           ;
(*mark_debug = "true"*) wire            [7:0]                          cpu2cfg_m2s_awlen              ;
(*mark_debug = "true"*) wire            [2:0]                          cpu2cfg_m2s_awsize             ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_m2s_awburst            ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_awlock             ;
(*mark_debug = "true"*) wire            [3:0]                          cpu2cfg_m2s_awcache            ;
(*mark_debug = "true"*) wire            [2:0]                          cpu2cfg_m2s_awprot             ;
(*mark_debug = "true"*) wire            [3:0]                          cpu2cfg_m2s_awqos              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_awvalid            ;
(*mark_debug = "true"*) wire            [63:0]                         cpu2cfg_m2s_wdata              ;
(*mark_debug = "true"*) wire            [7:0]                          cpu2cfg_m2s_wstrb              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_wlast              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_wvalid             ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_bready             ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_m2s_arid               ;
(*mark_debug = "true"*) wire            [30:0]                         cpu2cfg_m2s_araddr             ;
(*mark_debug = "true"*) wire            [3:0]                          cpu2cfg_m2s_arregion           ;
(*mark_debug = "true"*) wire            [7:0]                          cpu2cfg_m2s_arlen              ;
(*mark_debug = "true"*) wire            [2:0]                          cpu2cfg_m2s_arsize             ;
(*mark_debug = "true"*) wire            [1:0]                          cpu2cfg_m2s_arburst            ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_arlock             ;
(*mark_debug = "true"*) wire            [3:0]                          cpu2cfg_m2s_arcache            ;
(*mark_debug = "true"*) wire            [2:0]                          cpu2cfg_m2s_arprot             ;
(*mark_debug = "true"*) wire            [3:0]                          cpu2cfg_m2s_arqos              ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_arvalid            ;
(*mark_debug = "true"*) wire                                           cpu2cfg_m2s_rready             ;

wire                                           axi_bus_clk_800m               ;
wire                                           adb_bus_rst_n                  ;
wire            [13:0]                         data_x2x_bridge_m2s_awid       ;
wire            [35:0]                         data_x2x_bridge_m2s_awaddr_mix ;
wire            [7:0]                          data_x2x_bridge_m2s_awlen      ;
wire            [2:0]                          data_x2x_bridge_m2s_awsize     ;
wire            [1:0]                          data_x2x_bridge_m2s_awburst    ;
wire                                           data_x2x_bridge_m2s_awlock     ;
wire            [3:0]                          data_x2x_bridge_m2s_awcache    ;
wire            [2:0]                          data_x2x_bridge_m2s_awprot     ;
wire            [3:0]                          data_x2x_bridge_m2s_awqos      ;
wire                                           data_x2x_bridge_m2s_awvalid    ;
wire            [127:0]                        data_x2x_bridge_m2s_wdata      ;
wire            [15:0]                         data_x2x_bridge_m2s_wstrb      ;
wire                                           data_x2x_bridge_m2s_wlast      ;
wire                                           data_x2x_bridge_m2s_wvalid     ;
wire                                           data_x2x_bridge_m2s_bready     ;
wire            [13:0]                         data_x2x_bridge_m2s_arid       ;
wire            [35:0]                         data_x2x_bridge_m2s_araddr_mix ;
wire            [7:0]                          data_x2x_bridge_m2s_arlen      ;
wire            [2:0]                          data_x2x_bridge_m2s_arsize     ;
wire            [1:0]                          data_x2x_bridge_m2s_arburst    ;
wire                                           data_x2x_bridge_m2s_arlock     ;
wire            [3:0]                          data_x2x_bridge_m2s_arcache    ;
wire            [2:0]                          data_x2x_bridge_m2s_arprot     ;
wire            [3:0]                          data_x2x_bridge_m2s_arqos      ;
wire                                           data_x2x_bridge_m2s_arvalid    ;
wire                                           data_x2x_bridge_m2s_rready     ;
wire                                           data_x2x_bridge_s2m_awready    ;
wire                                           data_x2x_bridge_s2m_wready     ;
wire            [13:0]                         data_x2x_bridge_s2m_bid        ;
wire            [1:0]                          data_x2x_bridge_s2m_bresp      ;
wire                                           data_x2x_bridge_s2m_bvalid     ;
wire                                           data_x2x_bridge_s2m_arready    ;
wire            [13:0]                         data_x2x_bridge_s2m_rid        ;
wire            [127:0]                        data_x2x_bridge_s2m_rdata      ;
wire            [1:0]                          data_x2x_bridge_s2m_rresp      ;
wire                                           data_x2x_bridge_s2m_rlast      ;
wire                                           data_x2x_bridge_s2m_rvalid     ;
wire            [39:0]                         data_x2x_bridge_m2s_awaddr     ;
wire            [39:0]                         data_x2x_bridge_m2s_araddr     ;
(*mark_debug = "true"*) wire           [17:0]                       cpu2ddr_m2s_awid_mix           ;
`ifdef CPU_NUTSHELL
(*mark_debug = "true"*) wire           [32:0]                      cpu2ddr_m2s_awaddr_mix         ;
`else
(*mark_debug = "true"*) wire           [39:0]                      cpu2ddr_m2s_awaddr_mix         ;
`endif
(*mark_debug = "true"*) wire           [7:0]                       cpu2ddr_m2s_awlen              ;
(*mark_debug = "true"*) wire           [2:0]                       cpu2ddr_m2s_awsize             ;
(*mark_debug = "true"*) wire           [1:0]                       cpu2ddr_m2s_awburst            ;
wire           [3:0]                       cpu2ddr_m2s_awcache            ;
wire           [2:0]                       cpu2ddr_m2s_awprot             ;
wire           [3:0]                       cpu2ddr_m2s_awqos              ;
wire           [3:0]                       cpu2ddr_m2s_awregion           ;
`ifdef CPU_NUTSHELL
(*mark_debug = "true"*) wire           [63:0]                      cpu2ddr_m2s_wdata              ;
(*mark_debug = "true"*) wire           [7:0]                       cpu2ddr_m2s_wstrb              ;
`else
(*mark_debug = "true"*) wire           [255:0]                     cpu2ddr_m2s_wdata              ;
(*mark_debug = "true"*) wire           [31:0]                      cpu2ddr_m2s_wstrb              ;
`endif
(*mark_debug = "true"*) wire           [17:0]                       cpu2ddr_m2s_arid_mix           ;
`ifdef CPU_NUTSHELL
(*mark_debug = "true"*) wire           [32:0]                      cpu2ddr_m2s_araddr_mix         ;
`else
(*mark_debug = "true"*) wire           [39:0]                      cpu2ddr_m2s_araddr_mix         ;
`endif
(*mark_debug = "true"*) wire           [7:0]                       cpu2ddr_m2s_arlen              ;
(*mark_debug = "true"*) wire           [2:0]                       cpu2ddr_m2s_arsize             ;
(*mark_debug = "true"*) wire           [1:0]                       cpu2ddr_m2s_arburst            ;
wire           [3:0]                       cpu2ddr_m2s_arcache            ;
wire           [2:0]                       cpu2ddr_m2s_arprot             ;
wire           [3:0]                       cpu2ddr_m2s_arqos              ;
wire           [3:0]                       cpu2ddr_m2s_arregion           ;
(*mark_debug = "true"*) wire           [17:0]                      cpu2ddr_s2m_bid                ;
(*mark_debug = "true"*) wire           [1:0]                       cpu2ddr_s2m_bresp              ;
(*mark_debug = "true"*) wire           [17:0]                      cpu2ddr_s2m_rid                ;
`ifdef CPU_NUTSHELL
(*mark_debug = "true"*) wire           [63:0]                      cpu2ddr_s2m_rdata              ;
`else
(*mark_debug = "true"*) wire           [255:0]                     cpu2ddr_s2m_rdata              ;
`endif
(*mark_debug = "true"*) wire           [1:0]                       cpu2ddr_s2m_rresp              ;
wire                                           ddr_core_clk                   ;
wire                                           sys_ddr_rst_n                  ;
wire                                           normal_mode                    ;
wire                                           phy_bist_mode                  ;
wire                                           mbist_mode                     ;
wire            [1:0]                          dft_qspi_clk_sel               ;
wire                                           dft_dp_clk_sel                 ;
wire            [1:0]                          dft_test_clk_sel               ;
wire                                           dft_crg_pre_gt_se              ;
wire                                           dft_rstn_sel                   ;
wire            [4:0]                          dft_pll_clksel                 ;
wire            [1:0]                          dft_gmac_clk_sel               ;
wire            [1:0]                          dft_uart0_clk_sel              ;
wire            [1:0]                          dft_uart1_clk_sel              ;
wire            [1:0]                          dft_uart2_clk_sel              ;
wire                                           dft_bclk_sel                   ;
wire            [2:0]                          io_phy_test_sel                ;
wire                                           io_phy_ate_rst_n               ;
wire                                           io_phy_ate_paddr               ;
wire                                           io_phy_ate_pclk                ;
wire                                           io_phy_ate_prst_n              ;
wire                                           io_phy_ate_psel                ;
wire                                           io_phy_ate_pwdata              ;
wire                                           io_phy_ate_pwrite              ;
wire                                           io_phy_ate_prdata              ;
wire                                           io_phy_ate_pready              ;
wire            [31:0]                         io_gpio_out_oe                 ;
wire            [31:0]                         io_gpio_out                    ;
wire            [31:0]                         io_gpio_in                     ;
wire                                           io_i2c0_clk_oe                 ;
wire                                           io_i2c0_data_oe                ;
wire                                           io_i2c1_clk_oe                 ;
wire                                           io_i2c1_data_oe                ;
wire                                           io_i2c2_clk_oe                 ;
wire                                           io_i2c2_data_oe                ;
wire                                           io_i2c0_clk_in                 ;
wire                                           io_i2c0_data_in                ;
wire                                           io_i2c1_clk_in                 ;
wire                                           io_i2c1_data_in                ;
wire                                           io_i2c2_clk_in                 ;
wire                                           io_i2c2_data_in                ;
wire                                           io_uart0_txd                   ;
wire                                           io_uart0_rxd                   ;
wire                                           io_uart1_txd                   ;
wire                                           io_uart1_rxd                   ;
wire                                           io_uart2_txd                   ;
wire                                           io_uart2_rxd                   ;
wire                                           io_qspi_sclk_out               ;
wire                                           io_qspi_cs_out_n_mix           ;
wire                                           io_qspi_mo0                    ;
wire                                           io_qspi_mo1                    ;
wire                                           io_qspi_mo2                    ;
wire                                           io_qspi_mo3                    ;
wire            [3:0]                          io_qspi_mo_oe_n                ;
wire                                           io_qspi_mi0                    ;
wire                                           io_qspi_mi1                    ;
wire                                           io_qspi_mi2                    ;
wire                                           io_qspi_mi3                    ;
`ifdef  XS_GMAC
wire                                           io_gmac_mdo_oe                 ;
wire                                           io_gmac_mdo                    ;
wire                                           io_gmac_mck_out                ;
wire                                           io_gmac_mdi                    ;
wire                                           io_gmac_tx_clk                 ;
wire                                           io_gmac_txd_en                 ;
wire            [3:0]                          io_gmac_txd_mix                ;
wire                                           io_gmac_rx_clk                 ;
wire                                           io_gmac_rxd_vld                ;
wire            [3:0]                          io_gmac_rxd                    ;
`endif
wire                                           cpu_jtag_trst_n                ;
wire            [31:0]                         crg_dbug_out                   ;
wire            [15:0]                         crg_paddr_mix                  ;
wire                                           crg_psel                       ;
wire                                           crg_penable                    ;
wire                                           crg_pwrite                     ;
wire            [31:0]                         crg_pwdata                     ;
wire                                           crg_pready                     ;
wire            [31:0]                         crg_prdata                     ;
wire                                           crg_pslverr                    ;
wire                                           sys_glb_rst_n                  ;
wire                                           sys_crg_rst_n                  ;
wire                                           sys_cpu_rst_n                  ;
wire                                           wdt_sys_rst_req_inv            ;
wire            [1:0]                          gmac_speed_mode                ;
wire                                           gpio53_fun_sel                 ;
wire                                           i2c0_clk_src                   ;
wire                                           i2c1_clk_src                   ;
wire                                           i2c2_clk_src                   ;
wire                                           i2c2_cken                      ;
wire                                           i2c1_cken                      ;
wire                                           i2c0_cken                      ;
wire                                           i2c2_apb_cken                  ;
wire                                           i2c1_apb_cken                  ;
wire                                           i2c0_apb_cken                  ;
wire                                           i2c2_srst_req                  ;
wire                                           i2c1_srst_req                  ;
wire                                           i2c0_srst_req                  ;
wire                                           uart2_sys_clk_src              ;
wire                                           uart1_sys_clk_src              ;
wire                                           uart0_sys_clk_src              ;
wire                                           uart2_apb_cken                 ;
wire                                           uart1_apb_cken                 ;
wire                                           uart0_apb_cken                 ;
wire                                           uart2_sys_cken                 ;
wire                                           uart1_sys_cken                 ;
wire                                           uart0_sys_cken                 ;
wire                                           uart2_srst_req                 ;
wire                                           uart1_srst_req                 ;
wire                                           uart0_srst_req                 ;
wire                                           qspi_ref_clk_src               ;
wire                                           qspi_ref_cken                  ;
wire                                           qspi_ahb_cken                  ;
wire                                           qspi_apb_cken                  ;
wire                                           qspi_srst_req                  ;
wire                                           dma_ahb_cken                   ;
wire                                           dma_axi_cken                   ;
wire                                           dma_srst_req                   ;
wire                                           gmac_tx_clk                    ;
wire                                           gmac_tx_cken                   ;
wire                                           gmac_rx_cken                   ;
wire                                           gmac_apb_cken                  ;
wire                                           gmac_axi_cken                  ;
wire                                           gpio_db_clk_src                ;
wire                                           gpio_apb_cken                  ;
wire                                           gpio_db_cken                   ;
wire                                           gpio_srst_req                  ;
wire                                           i2s_core_clk_src               ;
wire                                           i2s_core_cken                  ;
wire                                           i2s_apb_cken                   ;
wire                                           i2s_srst_req                   ;
wire                                           dft_clk_60m                    ;
wire                                           dft_clk_125m                   ;
wire                                           ddr_cken                       ;
wire                                           ddr_pcken                      ;
wire                                           ddr_acken                      ;
wire            [1:0]                          dma_breq_mix                   ;
wire            [1:0]                          dma_blast_mix                  ;
wire            [1:0]                          dma_ack                        ;
wire                                           gpio_penable                   ;
wire                                           gpio_pwrite                    ;
wire            [31:0]                         gpio_pwdata                    ;
wire            [6:0]                          gpio_paddr_mix                 ;
wire                                           gpio_psel                      ;
wire            [31:0]                         gpio_prdata                    ;
wire                                           dma_ack_rx                     ;
wire                                           dma_ack_tx                     ;
wire                                           dma_breq_rx                    ;
wire                                           dma_blast_rx                   ;
wire                                           dma_breq_tx                    ;
wire                                           dma_blast_tx                   ;
wire            [3:0]                          io_qspi_cs_out_n               ;
`ifdef  XS_QSPI2ROM
(*mark_debug = "true"*) wire                                           qspi_hsel                      ;
(*mark_debug = "true"*) wire                                           qspi_hready_from_bus           ;
(*mark_debug = "true"*) wire            [1:0]                          qspi_htrans                    ;
(*mark_debug = "true"*) wire                                           qspi_hwrite                    ;
(*mark_debug = "true"*) wire            [2:0]                          qspi_hsize                     ;
(*mark_debug = "true"*) wire            [2:0]                          qspi_hburst                    ;
(*mark_debug = "true"*) wire            [31:0]                         qspi_hwdata                    ;
(*mark_debug = "true"*) wire            [31:0]                         qspi_hrdata                    ;
(*mark_debug = "true"*) wire                                           qspi_hresp                     ;
(*mark_debug = "true"*) wire                                           qspi_hready                    ;
`endif
wire                                           qspi_psel                      ;
wire                                           qspi_penable                   ;
wire                                           qspi_pwrite                    ;
wire            [7:0]                          qspi_paddr_mix                 ;
wire            [31:0]                         qspi_pwdata                    ;
wire            [31:0]                         qspi_prdata                    ;
wire                                           qspi_pready                    ;
wire                                           qspi_pslverr                   ;
`ifdef  XS_GMAC
wire            [7:0]                          io_gmac_rxd_mix                ;
wire            [7:0]                          io_gmac_txd                    ;
wire                                           gmac_psel                      ;
wire            [13:0]                         gmac_paddr_mix                 ;
wire                                           gmac_pwrite                    ;
wire            [31:0]                         gmac_pwdata                    ;
wire                                           gmac_penable                   ;
wire            [31:0]                         gmac_prdata                    ;
wire                                           gmac_m_awready                 ;
wire                                           gmac_m_wready                  ;
wire            [3:0]                          gmac_m_bid                     ;
wire            [1:0]                          gmac_m_bresp                   ;
wire                                           gmac_m_bvalid                  ;
wire                                           gmac_m_arready                 ;
wire            [3:0]                          gmac_m_rid                     ;
wire            [1:0]                          gmac_m_rresp                   ;
wire            [63:0]                         gmac_m_rdata                   ;
wire                                           gmac_m_rvalid                  ;
wire                                           gmac_m_rlast                   ;
wire            [3:0]                          gmac_m_awlen                   ;
wire            [3:0]                          gmac_m_awid                    ;
wire            [1:0]                          gmac_m_awburst                 ;
wire                                           gmac_m_awvalid                 ;
wire            [2:0]                          gmac_m_awsize                  ;
wire            [1:0]                          gmac_m_awlock                  ;
wire            [3:0]                          gmac_m_awcache                 ;
wire            [2:0]                          gmac_m_awprot                  ;
wire            [3:0]                          gmac_m_wid                     ;
wire            [63:0]                         gmac_m_wdata                   ;
wire            [7:0]                          gmac_m_wstrb                   ;
wire                                           gmac_m_wlast                   ;
wire                                           gmac_m_wvalid                  ;
wire                                           gmac_m_bready                  ;
wire            [3:0]                          gmac_m_arlen                   ;
wire            [3:0]                          gmac_m_arid                    ;
wire            [1:0]                          gmac_m_arburst                 ;
wire                                           gmac_m_arvalid                 ;
wire            [2:0]                          gmac_m_arsize                  ;
wire            [1:0]                          gmac_m_arlock                  ;
wire            [3:0]                          gmac_m_arcache                 ;
wire            [2:0]                          gmac_m_arprot                  ;
wire                                           gmac_m_rready                  ;
`endif
`ifdef  XS_UART
wire                                           uart2_penable                  ;
wire                                           uart2_pwrite                   ;
wire            [31:0]                         uart2_pwdata                   ;
wire            [7:0]                          uart2_paddr_mix                ;
wire                                           uart2_psel                     ;
wire            [31:0]                         uart2_prdata                   ;
wire                                           uart1_penable                  ;
wire                                           uart1_pwrite                   ;
wire            [31:0]                         uart1_pwdata                   ;
wire            [7:0]                          uart1_paddr_mix                ;
wire                                           uart1_psel                     ;
wire            [31:0]                         uart1_prdata                   ;
(*mark_debug = "true"*) wire                                           uart0_penable                  ;
(*mark_debug = "true"*) wire                                           uart0_pwrite                   ;
(*mark_debug = "true"*) wire            [31:0]                         uart0_pwdata                   ;
(*mark_debug = "true"*) wire            [7:0]                          uart0_paddr_mix                ;
(*mark_debug = "true"*) wire                                           uart0_psel                     ;
(*mark_debug = "true"*) wire            [31:0]                         uart0_prdata                   ;
`endif
wire                                           i2c2_psel                      ;
wire                                           i2c2_penable                   ;
wire                                           i2c2_pwrite                    ;
wire            [7:0]                          i2c2_paddr_mix                 ;
wire            [31:0]                         i2c2_pwdata                    ;
wire            [31:0]                         i2c2_prdata                    ;
wire                                           i2c1_psel                      ;
wire                                           i2c1_penable                   ;
wire                                           i2c1_pwrite                    ;
wire            [7:0]                          i2c1_paddr_mix                 ;
wire            [31:0]                         i2c1_pwdata                    ;
wire            [31:0]                         i2c1_prdata                    ;
wire                                           i2c0_psel                      ;
wire                                           i2c0_penable                   ;
wire                                           i2c0_pwrite                    ;
wire            [7:0]                          i2c0_paddr_mix                 ;
wire            [31:0]                         i2c0_pwdata                    ;
wire            [31:0]                         i2c0_prdata                    ;


wire                                           dma_bridge_data_m_awready      ;
wire                                           dma_bridge_data_m_wready       ;
wire            [3:0]                          dma_bridge_data_m_bid          ;
wire            [1:0]                          dma_bridge_data_m_bresp        ;
wire                                           dma_bridge_data_m_bvalid       ;
wire                                           dma_bridge_data_m_arready      ;
wire            [3:0]                          dma_bridge_data_m_rid          ;
wire            [255:0]                        dma_bridge_data_m_rdata        ;
wire            [1:0]                          dma_bridge_data_m_rresp        ;
wire                                           dma_bridge_data_m_rlast        ;
wire                                           dma_bridge_data_m_rvalid       ;
wire            [3:0]                          dma_bridge_data_m_awid         ;
wire            [39:0]                         dma_bridge_data_m_awaddr       ;
wire            [7:0]                          dma_bridge_data_m_awlen        ;
wire            [2:0]                          dma_bridge_data_m_awsize       ;
wire            [1:0]                          dma_bridge_data_m_awburst      ;
wire                                           dma_bridge_data_m_awlock       ;
wire            [3:0]                          dma_bridge_data_m_awcache      ;
wire            [2:0]                          dma_bridge_data_m_awprot       ;
wire                                           dma_bridge_data_m_awvalid      ;
wire            [255:0]                        dma_bridge_data_m_wdata        ;
wire            [31:0]                         dma_bridge_data_m_wstrb        ;
wire                                           dma_bridge_data_m_wlast        ;
wire                                           dma_bridge_data_m_wvalid       ;
wire                                           dma_bridge_data_m_bready       ;
wire            [3:0]                          dma_bridge_data_m_arid         ;
wire            [39:0]                         dma_bridge_data_m_araddr       ;
wire            [7:0]                          dma_bridge_data_m_arlen        ;
wire            [2:0]                          dma_bridge_data_m_arsize       ;
wire            [1:0]                          dma_bridge_data_m_arburst      ;
wire                                           dma_bridge_data_m_arlock       ;
wire            [3:0]                          dma_bridge_data_m_arcache      ;
wire            [2:0]                          dma_bridge_data_m_arprot       ;
wire                                           dma_bridge_data_m_arvalid      ;
wire                                           dma_bridge_data_m_rready       ;
wire            [3:0]                          dma_bridge_data_m_awqos        ;
wire            [3:0]                          dma_bridge_data_m_arqos        ;
wire            [2:0]                          qos_hburst                     ;
wire            [3:0]                          qos_hprot                      ;
wire            [2:0]                          qos_hsize                      ;
wire            [1:0]                          qos_htrans                     ;
wire            [31:0]                         qos_hwdata                     ;
wire                                           qos_hwrite                     ;
wire            [31:0]                         qos_hrdata                     ;
wire                                           qos_hready                     ;
wire                                           qos_hresp                      ;
wire                                           qos_hsel                       ;
wire                                           qos_hready_from_bus            ;
wire            [7:0]                          peri_bridge_m_awid             ;
wire            [39:0]                         peri_bridge_m_awaddr           ;
wire            [3:0]                          peri_bridge_m_awlen            ;
wire            [2:0]                          peri_bridge_m_awsize           ;
wire            [1:0]                          peri_bridge_m_awburst          ;
wire            [1:0]                          peri_bridge_m_awlock           ;
wire            [3:0]                          peri_bridge_m_awcache          ;
wire            [2:0]                          peri_bridge_m_awprot           ;
wire                                           peri_bridge_m_awvalid          ;
wire            [7:0]                          peri_bridge_m_wid              ;
wire            [63:0]                         peri_bridge_m_wdata            ;
wire            [7:0]                          peri_bridge_m_wstrb            ;
wire                                           peri_bridge_m_wlast            ;
wire                                           peri_bridge_m_wvalid           ;
wire                                           peri_bridge_m_bready           ;
wire            [7:0]                          peri_bridge_m_arid             ;
wire            [39:0]                         peri_bridge_m_araddr           ;
wire            [3:0]                          peri_bridge_m_arlen            ;
wire            [2:0]                          peri_bridge_m_arsize           ;
wire            [1:0]                          peri_bridge_m_arburst          ;
wire            [1:0]                          peri_bridge_m_arlock           ;
wire            [3:0]                          peri_bridge_m_arcache          ;
wire            [2:0]                          peri_bridge_m_arprot           ;
wire                                           peri_bridge_m_arvalid          ;
wire                                           peri_bridge_m_rready           ;
wire            [3:0]                          peri_bridge_m_awqos            ;
wire            [3:0]                          peri_bridge_m_arqos            ;
wire                                           peri_bridge_m_awready          ;
wire                                           peri_bridge_m_wready           ;
wire            [7:0]                          peri_bridge_m_bid              ;
wire            [1:0]                          peri_bridge_m_bresp            ;
wire                                           peri_bridge_m_bvalid           ;
wire                                           peri_bridge_m_arready          ;
wire            [7:0]                          peri_bridge_m_rid              ;
wire            [63:0]                         peri_bridge_m_rdata            ;
wire            [1:0]                          peri_bridge_m_rresp            ;
wire                                           peri_bridge_m_rlast            ;
wire                                           peri_bridge_m_rvalid           ;
`ifdef  XS_GMAC
wire            [31:0]                         gmac_paddr                     ;
`endif
wire            [31:0]                         gpio_paddr                     ;
wire            [31:0]                         i2c2_paddr                     ;
wire            [31:0]                         i2c1_paddr                     ;
wire            [31:0]                         i2c0_paddr                     ;
`ifdef  XS_UART
wire            [31:0]                         uart2_paddr                    ;
wire            [31:0]                         uart1_paddr                    ;
wire            [31:0]                         uart0_paddr                    ;
`endif
wire            [31:0]                         qspi_paddr                     ;
wire            [31:0]                         syscfg_paddr                   ;
wire                                           gpu_hresp_mix                  ;
wire                                           dma_hresp_mix                  ;
wire            [2:0]                          dma_hburst                     ;
wire            [3:0]                          dma_hprot                      ;
`ifdef  XS_QSPI2ROM
wire            [3:0]                          qspi_hprot                     ;
`endif
wire                                           sd_hresp_mix                   ;
wire            [2:0]                          sd_hburst                      ;
wire            [3:0]                          sd_hprot                       ;

assign dma_ack_rx = dma_ack[1] ;
assign dma_ack_tx = dma_ack[0] ;
assign dma_breq_mix  = {dma_breq_rx ,dma_breq_tx } ;
assign dma_blast_mix = {dma_blast_rx,dma_blast_tx} ;

wire [58:0] cpu_int ;  // 11-26 add sd 2 int
wire [104:0] cpu_pll_config ;

assign cpu_int = {
      0   ,
      0   ,
      0   ,
	  sd_wakeup_int   ,
	  sd_int          ,
      pcie1_int       ,
//`ifdef  XS_XDMA
      0   ,
      0   ,
      0  ,
//`endif
      dp_de_int       ,
      dp_se_int       ,
      hdmiphy_int     ,
      hdmitx_int      ,
      wdt_int         ,
      gpu_int         ,
      qspi_int        ,
      i2s_int         ,
//`ifdef  XS_UART
      uart2_int       ,
      uart1_int       ,
      uart0_int       ,
//`endif
      i2c2_int        ,
      i2c1_int        ,
      i2c0_int        ,
      gpio_int[31:0]  ,
      dma_int         ,
//`ifdef  XS_GMAC
      gmac_lpi_int    ,
      gmac_sbd_int    ,
      gmac_pmt_int
//`endif

};
assign cpu_int_mix = {5'b0, cpu_int}; //1-14:not match to 100NL SoC
assign i2c2_paddr_mix  = i2c2_paddr[7:0] ;
assign i2c1_paddr_mix  = i2c1_paddr[7:0] ;
assign i2c0_paddr_mix  = i2c0_paddr[7:0] ;
assign gpio_paddr_mix  = gpio_paddr[6:0] ;
`ifdef  XS_GMAC
assign gmac_paddr_mix = gmac_paddr[13:0];
`endif
assign syscfg_paddr_mix = syscfg_paddr[15:0] ;
`ifdef  XS_QSPI2ROM
assign qspi_haddr_mix_pre = qspi_haddr - 32'h1000_0000 ;
assign qspi_haddr_mix = (qspi_haddr_mix_pre == 0) ? 32'h00000088 : qspi_haddr_mix_pre;
`endif
`ifdef  XS_GMAC
assign gmac_m_awaddr_mix = cfg_gmac_addr_offset_en ? {{8'h0,gmac_m_awaddr[31:0]}+32'h8000_0000} : {8'h0,gmac_m_awaddr[31:0]};
assign gmac_m_araddr_mix = cfg_gmac_addr_offset_en ? {{8'h0,gmac_m_araddr[31:0]}+32'h8000_0000} : {8'h0,gmac_m_araddr[31:0]};
`endif
assign cpu2ddr_m2s_awaddr_mix = cpu2ddr_m2s_awaddr - 36'h8000_0000;
assign cpu2ddr_m2s_araddr_mix = cpu2ddr_m2s_araddr - 36'h8000_0000;
assign cpu2ddr_m2s_awid_mix = cpu2ddr_m2s_awid[13:0] ;
assign cpu2ddr_m2s_arid_mix = cpu2ddr_m2s_arid[13:0] ;
assign cpu2ddr_s2m_bid_mix  = cpu2ddr_s2m_bid[13:0];
assign cpu2ddr_s2m_rid_mix  = cpu2ddr_s2m_rid[13:0];
assign io_qspi_cs_out_n_mix = io_qspi_cs_out_n[0];
`ifdef  XS_GMAC
assign io_gmac_txd_mix = io_gmac_txd[3:0];
assign io_gmac_rxd_mix = {4'b0,io_gmac_rxd[3:0]};
`endif
assign sys_cpu_rst   = ~sys_cpu_rst_n ;
assign cpu_jtag_trst = ~cpu_jtag_trst_n ;
assign soc_pll_lock_test = crg_dbug_out[4:0] ;

`ifdef  XS_QSPI2ROM
wire [7 : 0]                rom_axi_awlen    ;
wire [2 : 0]                rom_axi_awsize   ;
wire [1 : 0]                rom_axi_awburst  ;
wire [3 : 0]                rom_axi_awcache  ;
(*mark_debug = "true"*) wire [31 : 0]               rom_axi_awaddr   ;
wire [2 : 0]                rom_axi_awprot   ;
(*mark_debug = "true"*) wire                        rom_axi_awvalid  ;
(*mark_debug = "true"*) wire                        rom_axi_awready  ;
wire                        rom_axi_awlock   ;
(*mark_debug = "true"*) wire [31 : 0]               rom_axi_wdata    ;
wire [3 : 0]                rom_axi_wstrb    ;
(*mark_debug = "true"*) wire                        rom_axi_wlast    ;
(*mark_debug = "true"*) wire                        rom_axi_wvalid   ;
(*mark_debug = "true"*) wire                        rom_axi_wready   ;
(*mark_debug = "true"*) wire [1 : 0]                rom_axi_bresp    ;
(*mark_debug = "true"*) wire                        rom_axi_bvalid   ;
(*mark_debug = "true"*) wire                        rom_axi_bready   ;
wire [7 : 0]                rom_axi_arlen    ;
wire [2 : 0]                rom_axi_arsize   ;
wire [1 : 0]                rom_axi_arburst  ;
wire [2 : 0]                rom_axi_arprot   ;
wire [3 : 0]                rom_axi_arcache  ;
(*mark_debug = "true"*) wire                        rom_axi_arvalid  ;
(*mark_debug = "true"*) wire [31 : 0]               rom_axi_araddr   ;
wire                        rom_axi_arlock   ;
(*mark_debug = "true"*) wire                        rom_axi_arready  ;
(*mark_debug = "true"*) wire [31 : 0]               rom_axi_rdata    ;
wire [1 : 0]                rom_axi_rresp    ;
(*mark_debug = "true"*) wire                        rom_axi_rvalid   ;
(*mark_debug = "true"*) wire                        rom_axi_rlast    ;
(*mark_debug = "true"*) wire                        rom_axi_rready   ;
`ifndef CONFIG_DIFFTEST_HOSTIF_GBUS
`ifdef UVHS
wire [7:0]  uvhs_flash_axi_awid;
wire [31:0] uvhs_flash_axi_awaddr;
wire [3:0]  uvhs_flash_axi_awlen;
wire [2:0]  uvhs_flash_axi_awsize;
wire [1:0]  uvhs_flash_axi_awburst;
wire [1:0]  uvhs_flash_axi_awlock;
wire [3:0]  uvhs_flash_axi_awcache;
wire [2:0]  uvhs_flash_axi_awprot;
wire [3:0]  uvhs_flash_axi_awqos;
wire        uvhs_flash_axi_awvalid;
wire        uvhs_flash_axi_awready;
wire [7:0]  uvhs_flash_axi_wid;
wire [63:0] uvhs_flash_axi_wdata;
wire [7:0]  uvhs_flash_axi_wstrb;
wire        uvhs_flash_axi_wlast;
wire        uvhs_flash_axi_wvalid;
wire        uvhs_flash_axi_wready;
wire [7:0]  uvhs_flash_axi_bid;
wire [1:0]  uvhs_flash_axi_bresp;
wire        uvhs_flash_axi_bvalid;
wire        uvhs_flash_axi_bready;
wire [7:0]  uvhs_flash_axi_arid;
wire [31:0] uvhs_flash_axi_araddr;
wire [3:0]  uvhs_flash_axi_arlen;
wire [2:0]  uvhs_flash_axi_arsize;
wire [1:0]  uvhs_flash_axi_arburst;
wire [1:0]  uvhs_flash_axi_arlock;
wire [3:0]  uvhs_flash_axi_arcache;
wire [2:0]  uvhs_flash_axi_arprot;
wire [3:0]  uvhs_flash_axi_arqos;
wire        uvhs_flash_axi_arvalid;
wire        uvhs_flash_axi_arready;
wire [7:0]  uvhs_flash_axi_rid;
wire [63:0] uvhs_flash_axi_rdata;
wire [1:0]  uvhs_flash_axi_rresp;
wire        uvhs_flash_axi_rlast;
wire        uvhs_flash_axi_rvalid;
wire        uvhs_flash_axi_rready;

uvw_general_bus U_UVHS_FLASH_GBUS (
    .dut_axi_aclk      (sys_clk_i),
    .dut_axi_aclk_en   (1'b1),
    .dut_axi_aresetn   (axi_bclk_sync_rstn),
    .dut_axi_awid      (uvhs_flash_axi_awid),
    .dut_axi_awaddr    (uvhs_flash_axi_awaddr),
    .dut_axi_awlen     (uvhs_flash_axi_awlen),
    .dut_axi_awsize    (uvhs_flash_axi_awsize),
    .dut_axi_awburst   (uvhs_flash_axi_awburst),
    .dut_axi_awlock    (uvhs_flash_axi_awlock),
    .dut_axi_awcache   (uvhs_flash_axi_awcache),
    .dut_axi_awprot    (uvhs_flash_axi_awprot),
    .dut_axi_awqos     (uvhs_flash_axi_awqos),
    .dut_axi_awvalid   (uvhs_flash_axi_awvalid),
    .dut_axi_awready   (uvhs_flash_axi_awready),
    .dut_axi_wid       (uvhs_flash_axi_wid),
    .dut_axi_wdata     (uvhs_flash_axi_wdata),
    .dut_axi_wstrb     (uvhs_flash_axi_wstrb),
    .dut_axi_wlast     (uvhs_flash_axi_wlast),
    .dut_axi_wvalid    (uvhs_flash_axi_wvalid),
    .dut_axi_wready    (uvhs_flash_axi_wready),
    .dut_axi_bid       (uvhs_flash_axi_bid),
    .dut_axi_bresp     (uvhs_flash_axi_bresp),
    .dut_axi_bvalid    (uvhs_flash_axi_bvalid),
    .dut_axi_bready    (uvhs_flash_axi_bready),
    .dut_axi_arid      (uvhs_flash_axi_arid),
    .dut_axi_araddr    (uvhs_flash_axi_araddr),
    .dut_axi_arlen     (uvhs_flash_axi_arlen),
    .dut_axi_arsize    (uvhs_flash_axi_arsize),
    .dut_axi_arburst   (uvhs_flash_axi_arburst),
    .dut_axi_arlock    (uvhs_flash_axi_arlock),
    .dut_axi_arcache   (uvhs_flash_axi_arcache),
    .dut_axi_arprot    (uvhs_flash_axi_arprot),
    .dut_axi_arqos     (uvhs_flash_axi_arqos),
    .dut_axi_arvalid   (uvhs_flash_axi_arvalid),
    .dut_axi_arready   (uvhs_flash_axi_arready),
    .dut_axi_rid       (uvhs_flash_axi_rid),
    .dut_axi_rdata     (uvhs_flash_axi_rdata),
    .dut_axi_rresp     (uvhs_flash_axi_rresp),
    .dut_axi_rlast     (uvhs_flash_axi_rlast),
    .dut_axi_rvalid    (uvhs_flash_axi_rvalid),
    .dut_axi_rready    (uvhs_flash_axi_rready),
    .sysbus_ghbd_o     (),
    .sysbus_ghbd_i     ()
);
`endif
`endif
`endif

`ifdef  XS_QSPI2ROM
blk_mem_gen_0 u_rom (
  .rsta_busy      (rsta_busy          ),
  .rstb_busy      (rstb_busy          ),
  .s_aclk         (sys_clk_i          ),
  .s_aresetn      (axi_bclk_sync_rstn ),
  .s_axi_awaddr   (rom_axi_awaddr     ),
  .s_axi_awlen    (rom_axi_awlen      ),
  .s_axi_awvalid  (rom_axi_awvalid    ),
  .s_axi_awready  (rom_axi_awready    ),
  .s_axi_wdata    (rom_axi_wdata      ),
  .s_axi_wstrb    (rom_axi_wstrb      ),
  .s_axi_wlast    (rom_axi_wlast      ),
  .s_axi_wvalid   (rom_axi_wvalid     ),
  .s_axi_wready   (rom_axi_wready     ),
  .s_axi_bresp    (rom_axi_bresp      ),
  .s_axi_bvalid   (rom_axi_bvalid     ),
  .s_axi_bready   (rom_axi_bready     ),
  .s_axi_araddr   (rom_axi_araddr     ),
  .s_axi_arlen    (rom_axi_arlen      ),
  .s_axi_arvalid  (rom_axi_arvalid    ),
  .s_axi_arready  (rom_axi_arready    ),
  .s_axi_rdata    (rom_axi_rdata      ),
  .s_axi_rresp    (rom_axi_rresp      ),
  .s_axi_rlast    (rom_axi_rlast      ),
  .s_axi_rvalid   (rom_axi_rvalid     ),
  .s_axi_rready   (rom_axi_rready     )
);

`endif

`ifndef  XS_XDMA
assign cfg_pcie0_s2m_arready = 1;
assign cfg_pcie0_s2m_awready = 1;
assign cfg_pcie0_s2m_wready = 1;
assign cfg_pcie0_s2m_bvalid = 1;
assign cfg_pcie0_s2m_bresp = 0;
assign cfg_pcie0_s2m_rdata = 0;
assign cfg_pcie0_s2m_rvalid = 1;

assign cfg_pcie1_s2m_arready = 1;
assign cfg_pcie1_s2m_awready = 1;
assign cfg_pcie1_s2m_wready = 1;
assign cfg_pcie1_s2m_bvalid = 1;
assign cfg_pcie1_s2m_bresp = 0;
assign cfg_pcie1_s2m_rdata = 0;
assign cfg_pcie1_s2m_rvalid = 1;
`endif

`ifdef CONFIG_USE_IMSIC
    wire                          xstile_imsic_awready        [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_awvalid        [`CONFIG_XSCORE_NR-1:0];
    wire [4:0]                    xstile_imsic_awid           [`CONFIG_XSCORE_NR-1:0];
    wire [31:0]                   xstile_imsic_awaddr         [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_wready         [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_wvalid         [`CONFIG_XSCORE_NR-1:0];
    wire [31:0]                   xstile_imsic_wdata          [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_bready         [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_bvalid         [`CONFIG_XSCORE_NR-1:0];
    wire [4:0]                    xstile_imsic_bid            [`CONFIG_XSCORE_NR-1:0];
    wire [1:0]                    xstile_imsic_bresp          [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_arready        [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_arvalid        [`CONFIG_XSCORE_NR-1:0];
    wire [4:0]                    xstile_imsic_arid           [`CONFIG_XSCORE_NR-1:0];
    wire [31:0]                   xstile_imsic_araddr         [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_rready         [`CONFIG_XSCORE_NR-1:0];
    wire                          xstile_imsic_rvalid         [`CONFIG_XSCORE_NR-1:0];
    wire [4:0]                    xstile_imsic_rid            [`CONFIG_XSCORE_NR-1:0];
    wire [31:0]                   xstile_imsic_rdata          [`CONFIG_XSCORE_NR-1:0];
    wire [1:0]                    xstile_imsic_rresp          [`CONFIG_XSCORE_NR-1:0];
`endif /* CONFIG_USE_IMSIC */
assign pcie1_int = 0;
assign gpu_m_arvalid = 0;
assign gpu_m_awvalid = 0;
assign gpu_m_wvalid = 0;
assign gpu_hready = 1;
assign gpu_hrdata = 0;
assign gpu_int = 0;
assign i2c0_int = 0;
assign i2c0_prdata = 0;
assign i2c1_int = 0;
assign i2c1_prdata = 0;
assign i2c2_int = 0;
assign i2c2_prdata = 0;

wire [30:0]   br2cfg_araddr;
wire [1:0]    br2cfg_arburst;
wire [3:0]    br2cfg_arcache;
wire [1:0]    br2cfg_arid;
wire [7:0]    br2cfg_arlen;
wire [0:0]    br2cfg_arlock;
wire [2:0]    br2cfg_arprot;
wire [3:0]    br2cfg_arqos;
wire [0:0]    br2cfg_arready;
wire [2:0]    br2cfg_arsize;
wire [0:0]    br2cfg_arvalid;
wire [30:0]   br2cfg_awaddr;
wire [1:0]    br2cfg_awburst;
wire [3:0]    br2cfg_awcache;
wire [1:0]    br2cfg_awid;
wire [7:0]    br2cfg_awlen;
wire [0:0]    br2cfg_awlock;
wire [2:0]    br2cfg_awprot;
wire [3:0]    br2cfg_awqos;
wire [0:0]    br2cfg_awready;
wire [2:0]    br2cfg_awsize;
wire [0:0]    br2cfg_awvalid;
wire [1:0]    br2cfg_bid;
wire [0:0]    br2cfg_bready;
wire [1:0]    br2cfg_bresp;
wire [0:0]    br2cfg_bvalid;
wire [64:0]   br2cfg_rdata;
wire [1:0]    br2cfg_rid;
wire [0:0]    br2cfg_rlast;
wire [0:0]    br2cfg_rready;
wire [1:0]    br2cfg_rresp;
wire [0:0]    br2cfg_rvalid;
wire [64:0]   br2cfg_wdata;
wire [0:0]    br2cfg_wlast;
wire [0:0]    br2cfg_wready;
wire [7:0]    br2cfg_wstrb;
wire [0:0]    br2cfg_wvalid;

`ifndef NO_DIFF
  wire [31:0] XDMA_AXI_LITE_awaddr;
  wire [2:0]  XDMA_AXI_LITE_awprot;
  wire        XDMA_AXI_LITE_awvalid;
  wire        XDMA_AXI_LITE_awready;
  wire [31:0] XDMA_AXI_LITE_wdata;
  wire [3:0]  XDMA_AXI_LITE_wstrb;
  wire        XDMA_AXI_LITE_wvalid;
  wire        XDMA_AXI_LITE_wready;
  wire [1:0]  XDMA_AXI_LITE_bresp;
  wire        XDMA_AXI_LITE_bvalid;
  wire        XDMA_AXI_LITE_bready;
  wire [31:0] XDMA_AXI_LITE_araddr;
  wire [2:0]  XDMA_AXI_LITE_arprot;
  wire        XDMA_AXI_LITE_arvalid;
  wire        XDMA_AXI_LITE_arready;
  wire [31:0] XDMA_AXI_LITE_rdata;
  wire [1:0]  XDMA_AXI_LITE_rresp;
  wire        XDMA_AXI_LITE_rvalid;
  wire        XDMA_AXI_LITE_rready;

  wire [31:0] difftest_cfg_axilite_awaddr;
  wire        difftest_cfg_axilite_awvalid;
  wire        difftest_cfg_axilite_awready;
  wire [31:0] difftest_cfg_axilite_wdata;
  wire [3:0]  difftest_cfg_axilite_wstrb;
  wire        difftest_cfg_axilite_wvalid;
  wire        difftest_cfg_axilite_wready;
  wire [1:0]  difftest_cfg_axilite_bresp;
  wire        difftest_cfg_axilite_bvalid;
  wire        difftest_cfg_axilite_bready;
  wire [31:0] difftest_cfg_axilite_araddr;
  wire        difftest_cfg_axilite_arvalid;
  wire        difftest_cfg_axilite_arready;
  wire [31:0] difftest_cfg_axilite_rdata;
  wire [1:0]  difftest_cfg_axilite_rresp;
  wire        difftest_cfg_axilite_rvalid;
  wire        difftest_cfg_axilite_rready;

  wire        difftest_to_host_axis_tready_io;
  wire        difftest_to_host_axis_tvalid_io;
  wire        difftest_to_host_axis_tready;
  wire        difftest_to_host_axis_tvalid;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_to_host_axis_tdata;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_to_host_axis_tkeep;
  wire        difftest_to_host_axis_tlast;
  wire        difftest_from_host_axis_tready;
  wire        difftest_from_host_axis_tvalid;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] difftest_from_host_axis_tdata;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] difftest_from_host_axis_tkeep;
  wire        difftest_from_host_axis_tlast;
  wire        difftest_clock_enable;
  wire        inter_soc_clk;
  wire        inter_soc_sync_rstn;
  wire        inter_rtc_clk;

  wire io_host_reset;
  wire io_host_diff_enable;
  (*mark_debug = "true"*) wire io_host_ila_trigger;
  wire clock_enable;
  wire sys_rstn_io;
  wire cpu_rstn_io;
  wire difftest_startup_ready_pcie;
  wire difftest_startup_done_pcie;
  wire cpu_rstn_pcie;
  reg  cpu_rstn_pcie_src;
  wire io_host_diff_enable_pcie;
  wire xdma_link_up_pcie;
  reg [19:0] difftest_startup_wait_pcie;
  reg difftest_stream_enable_pcie;
  wire difftest_c2h_rstn;
  wire difftest_clock_gate_enable = difftest_clock_enable;
  wire difftest_pcie_clock;
`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  // GBus has no XDMA user-clock output.  The DiffTest host-side protocol and
  // the UVHS GeneralBD/GENERALBUS endpoints are synchronous to the always-on
  // GBus host/user interface clock: use the real always-running UVHS host
  // clock (dev_clk_i/clk6_p), not the gated CPU clock or infer_clock output.
  wire gbus_host_clk = dev_clk_i;
  assign difftest_pcie_clock = gbus_host_clk;
`endif
  wire pcie_ep_lnk_up_raw;
  (* ASYNC_REG = "TRUE" *) reg [1:0] pcie_lnk_sync;
  assign sys_rstn_io = sys_rstn & ~io_host_reset;
  assign cpu_rstn_io = cpu_rstn & ~io_host_reset;
  assign difftest_c2h_rstn = cpu_rstn_pcie & difftest_stream_enable_pcie;
`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  // GBus has no PCIe training state.  Expose a logical ready indication to
  // the shared control/CDC gates; XDMA retains the physical link status.
  assign pcie_ep_lnk_up = 1'b1;
`else
  assign pcie_ep_lnk_up = pcie_lnk_sync[1];
`endif

  always @(posedge sys_clk_i) begin
      if (!sys_rstn) cpu_rstn_pcie_src <= 1'b0;
      else           cpu_rstn_pcie_src <= cpu_rstn_io;
  end

  always @(posedge sys_clk_i) begin
      if (!sys_rstn) pcie_lnk_sync <= 2'b00;
      else           pcie_lnk_sync <= {pcie_lnk_sync[0], pcie_ep_lnk_up_raw};
  end
`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  wire xdma_link_up = 1'b1;
`else
  wire xdma_link_up = pcie_lnk_sync[1];
`endif

  RST_SYNC #(
      .SYNC_STAGES(3),
      .PIPELINE_STAGES(1),
      .INIT(1'b0)
  ) difftest_cpu_rstn_pcie_sync (
      .clk      (difftest_pcie_clock),
      .async_in (cpu_rstn_pcie_src),
      .sync_out (cpu_rstn_pcie)
  );

  RST_SYNC #(
      .SYNC_STAGES(3),
      .PIPELINE_STAGES(1),
      .INIT(1'b0)
  ) difftest_host_enable_pcie_sync (
      .clk      (difftest_pcie_clock),
      .async_in (io_host_diff_enable),
      .sync_out (io_host_diff_enable_pcie)
  );

`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  assign difftest_startup_ready_pcie = cpu_rstn_pcie & io_host_diff_enable_pcie;
`else
  RST_SYNC #(
      .SYNC_STAGES(3),
      .PIPELINE_STAGES(1),
      .INIT(1'b0)
  ) difftest_link_up_pcie_sync (
      .clk      (difftest_pcie_clock),
      .async_in (xdma_link_up),
      .sync_out (xdma_link_up_pcie)
  );

  assign difftest_startup_ready_pcie = cpu_rstn_pcie & io_host_diff_enable_pcie & xdma_link_up_pcie;
`endif
  assign difftest_startup_done_pcie = &difftest_startup_wait_pcie;

  always @(posedge difftest_pcie_clock) begin
      if (!difftest_startup_ready_pcie) begin
          difftest_startup_wait_pcie <= 20'b0;
          difftest_stream_enable_pcie <= 1'b0;
      end else begin
          difftest_stream_enable_pcie <= difftest_startup_done_pcie;
          if (!difftest_startup_done_pcie)
              difftest_startup_wait_pcie <= difftest_startup_wait_pcie + 20'b1;
      end
  end

  assign difftest_to_host_axis_tready = difftest_to_host_axis_tready_io & difftest_stream_enable_pcie;
  assign difftest_to_host_axis_tvalid_io = difftest_to_host_axis_tvalid & difftest_stream_enable_pcie;

`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  // The GBus shell has no PCIe clock/link reset domain.  Its compatibility
  // clock is the always-running host clock, so the AXI-Lite bridge must be
  // released from the normal fabric reset rather than a nonexistent PCIe
  // training indication.  Do not use sys_rstn_io here: that signal is
  // intentionally masked by io_host_reset, and fpga-host asserts
  // HOST_IO_CFG_RESET before issuing the remaining configuration writes.
  // Using the masked signal would therefore hold this bridge in reset for the
  // entire host initialization sequence, making successful GBus API calls
  // disappear before they reach the DiffTest config block.
  wire difftest_axil_cdc_s_resetn = sys_rstn;
  wire difftest_axil_cdc_m_resetn = sys_rstn;
`else
  wire difftest_axil_cdc_s_resetn = xdma_link_up_pcie;
  wire difftest_axil_cdc_m_resetn = sys_rstn & xdma_link_up;
`endif

  uvhs_axilite_cdc_bridge #(
      .ADDR_WIDTH (32),
      .DATA_WIDTH (32)
  ) difftest_cfg_axilite_cdc (
      .s_clk      (difftest_pcie_clock),
      .s_resetn   (difftest_axil_cdc_s_resetn),
      .s_awaddr   (XDMA_AXI_LITE_awaddr),
      .s_awprot   (XDMA_AXI_LITE_awprot),
      .s_awvalid  (XDMA_AXI_LITE_awvalid),
      .s_awready  (XDMA_AXI_LITE_awready),
      .s_wdata    (XDMA_AXI_LITE_wdata),
      .s_wstrb    (XDMA_AXI_LITE_wstrb),
      .s_wvalid   (XDMA_AXI_LITE_wvalid),
      .s_wready   (XDMA_AXI_LITE_wready),
      .s_bresp    (XDMA_AXI_LITE_bresp),
      .s_bvalid   (XDMA_AXI_LITE_bvalid),
      .s_bready   (XDMA_AXI_LITE_bready),
      .s_araddr   (XDMA_AXI_LITE_araddr),
      .s_arprot   (XDMA_AXI_LITE_arprot),
      .s_arvalid  (XDMA_AXI_LITE_arvalid),
      .s_arready  (XDMA_AXI_LITE_arready),
      .s_rdata    (XDMA_AXI_LITE_rdata),
      .s_rresp    (XDMA_AXI_LITE_rresp),
      .s_rvalid   (XDMA_AXI_LITE_rvalid),
      .s_rready   (XDMA_AXI_LITE_rready),

      .m_clk      (sys_clk_i),
      .m_resetn   (difftest_axil_cdc_m_resetn),
      .m_awaddr   (difftest_cfg_axilite_awaddr),
      .m_awprot   (),
      .m_awvalid  (difftest_cfg_axilite_awvalid),
      .m_awready  (difftest_cfg_axilite_awready),
      .m_wdata    (difftest_cfg_axilite_wdata),
      .m_wstrb    (difftest_cfg_axilite_wstrb),
      .m_wvalid   (difftest_cfg_axilite_wvalid),
      .m_wready   (difftest_cfg_axilite_wready),
      .m_bresp    (difftest_cfg_axilite_bresp),
      .m_bvalid   (difftest_cfg_axilite_bvalid),
      .m_bready   (difftest_cfg_axilite_bready),
      .m_araddr   (difftest_cfg_axilite_araddr),
      .m_arprot   (),
      .m_arvalid  (difftest_cfg_axilite_arvalid),
      .m_arready  (difftest_cfg_axilite_arready),
      .m_rdata    (difftest_cfg_axilite_rdata),
      .m_rresp    (difftest_cfg_axilite_rresp),
      .m_rvalid   (difftest_cfg_axilite_rvalid),
      .m_rready   (difftest_cfg_axilite_rready)
  );

  wire [`CONFIG_DIFFTEST_HOST_AXIS_WIDTH-1:0] xdma_s00_axis_tdata;
  wire [`CONFIG_DIFFTEST_HOST_AXIS_BYTES-1:0] xdma_s00_axis_tkeep;
  wire xdma_s00_axis_tlast;
  wire xdma_s00_axis_tvalid;
  wire xdma_m00_axis_tready;
  wire xdma_cpu_clk;
  wire xdma_cpu_rstn;

  assign xdma_s00_axis_tdata = difftest_to_host_axis_tdata;
  assign xdma_s00_axis_tkeep = difftest_to_host_axis_tkeep;
  assign xdma_s00_axis_tlast = difftest_to_host_axis_tlast;
  assign xdma_s00_axis_tvalid = difftest_to_host_axis_tvalid_io;
  assign xdma_m00_axis_tready = difftest_from_host_axis_tready;
  // Keep the XDMA user side in the clock domain exported by the XDMA DCP and
  // do not let SoC reset
  // hold the endpoint user logic while the host probes BARs.
`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  // Keep the compatibility shell's CPU-side input on the 25-MHz SoC clock.
  // Its legacy user-clock output is explicitly driven from host_clk below,
  // so there is no clock loop and no reason to run the CPU-side shim at the
  // 50-MHz GBus host rate.
  assign xdma_cpu_clk = sys_clk_i;
`else
  assign xdma_cpu_clk = difftest_pcie_clock;
`endif
  assign xdma_cpu_rstn = 1'b1;

`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  wire gbus_cfg_wr_en;
  wire [15:0] gbus_cfg_wr_addr;
  wire [31:0] gbus_cfg_wdata;
  wire gbus_cfg_rd_en;
  wire [15:0] gbus_cfg_rd_addr;
  wire [31:0] gbus_cfg_rdata;
  wire gbus_cfg_rdata_vld;
  wire [15:0] gbus_cfg_local_wr_addr;
  wire [15:0] gbus_cfg_local_rd_addr;
  wire [31:0] gbus_c2h_cfg_rdata;
  wire gbus_c2h_cfg_rdata_vld;
  wire [31:0] gbus_axil_cfg_rdata;
  wire gbus_axil_cfg_rdata_vld;
  wire [7:0] gbus_axi_awid;
  wire [31:0] gbus_axi_awaddr;
  wire [3:0] gbus_axi_awlen;
  wire [2:0] gbus_axi_awsize;
  wire [1:0] gbus_axi_awburst, gbus_axi_awlock;
  wire [3:0] gbus_axi_awcache, gbus_axi_awqos;
  wire [2:0] gbus_axi_awprot;
  wire gbus_axi_awvalid, gbus_axi_awready;
  wire [7:0] gbus_axi_wid;
  wire [255:0] gbus_axi_wdata;
  wire [31:0] gbus_axi_wstrb;
  wire gbus_axi_wlast, gbus_axi_wvalid, gbus_axi_wready;
  wire [7:0] gbus_axi_bid;
  wire [1:0] gbus_axi_bresp;
  wire gbus_axi_bvalid, gbus_axi_bready;
  wire [7:0] gbus_axi_arid;
  wire [31:0] gbus_axi_araddr;
  wire [3:0] gbus_axi_arlen;
  wire [2:0] gbus_axi_arsize;
  wire [1:0] gbus_axi_arburst, gbus_axi_arlock;
  wire [3:0] gbus_axi_arcache, gbus_axi_arqos;
  wire [2:0] gbus_axi_arprot;
  wire gbus_axi_arvalid, gbus_axi_arready;
  wire [7:0] gbus_axi_rid;
  wire [255:0] gbus_axi_rdata;
  wire [1:0] gbus_axi_rresp;
  wire gbus_axi_rlast, gbus_axi_rvalid, gbus_axi_rready;

  wire [13:0] gbus_h2c_awid, gbus_h2c_arid;
  wire [35:0] gbus_h2c_awaddr, gbus_h2c_araddr;
  wire [7:0] gbus_h2c_awlen, gbus_h2c_arlen;
  wire [2:0] gbus_h2c_awsize, gbus_h2c_arsize;
  wire [1:0] gbus_h2c_awburst, gbus_h2c_arburst;
  wire gbus_h2c_awlock, gbus_h2c_arlock;
  wire [3:0] gbus_h2c_awcache, gbus_h2c_arcache, gbus_h2c_awqos, gbus_h2c_arqos;
  wire [3:0] gbus_h2c_awregion, gbus_h2c_arregion;
  wire [2:0] gbus_h2c_awprot, gbus_h2c_arprot;
  wire gbus_h2c_awvalid, gbus_h2c_awready, gbus_h2c_wlast, gbus_h2c_wvalid, gbus_h2c_wready;
  wire [255:0] gbus_h2c_wdata, gbus_h2c_rdata;
  wire [31:0] gbus_h2c_wstrb;
  wire [13:0] gbus_h2c_bid, gbus_h2c_rid;
  wire [1:0] gbus_h2c_bresp, gbus_h2c_rresp;
  wire gbus_h2c_bvalid, gbus_h2c_bready, gbus_h2c_arvalid, gbus_h2c_arready;
  wire gbus_h2c_rlast, gbus_h2c_rvalid, gbus_h2c_rready;

  wire [13:0] gbus_dma_awid, gbus_dma_arid;
  wire [35:0] gbus_dma_awaddr, gbus_dma_araddr;
  wire [7:0] gbus_dma_awlen, gbus_dma_arlen;
  wire [2:0] gbus_dma_awsize, gbus_dma_arsize;
  wire [1:0] gbus_dma_awburst, gbus_dma_arburst;
  wire gbus_dma_awlock, gbus_dma_arlock;
  wire [3:0] gbus_dma_awcache, gbus_dma_arcache;
  wire [3:0] gbus_dma_awqos, gbus_dma_arqos;
  wire [3:0] gbus_dma_awregion, gbus_dma_arregion;
  wire [2:0] gbus_dma_awprot, gbus_dma_arprot;
  wire gbus_dma_awvalid, gbus_dma_awready;
  wire [255:0] gbus_dma_wdata, gbus_dma_rdata;
  wire [31:0] gbus_dma_wstrb;
  wire gbus_dma_wlast, gbus_dma_wvalid, gbus_dma_wready;
  wire [13:0] gbus_dma_bid, gbus_dma_rid;
  wire [1:0] gbus_dma_bresp, gbus_dma_rresp;
  wire gbus_dma_bvalid, gbus_dma_bready;
  wire gbus_dma_arvalid, gbus_dma_arready;
  wire gbus_dma_rlast, gbus_dma_rvalid, gbus_dma_rready;
  wire gbus_shell_sready;
  wire gbus_c2h_sready;
  // The GENERALBD and GENERALBUS protected IPs share a 256-bit system-bus
  // link.  UVHS metadata identifies the endpoint type, but the tool does not
  // infer this connection when the ports are left open; an open port is
  // explicitly tied to GND during elaboration.  Keep the link explicit so
  // host commands and responses reach the GENERALBD endpoint.
  wire [255:0] gbus_sysbus_to_generalbus;
  wire [255:0] gbus_sysbus_to_generalbd;
  // The endpoint shell remains only a clock/readiness shim in GBus mode.
  // Actual GBus AXI and system-bus traffic is provided by the UVHS protected
  // IPs below and is not presented as a PCIe endpoint.
  uvhs_gbus_host_adapter xdma_ep_i(
`else
  xdma_ep xdma_ep_i(
`endif
    .cpu_clk              (xdma_cpu_clk),
`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
    .host_clk             (gbus_host_clk),
`endif
    .cpu_rstn             (xdma_cpu_rstn),
    .S00_AXIS_0_tdata     (xdma_s00_axis_tdata),
    .S00_AXIS_0_tkeep     (xdma_s00_axis_tkeep),
    .S00_AXIS_0_tlast     (xdma_s00_axis_tlast),
`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
    .S00_AXIS_0_tready    (gbus_shell_sready),
`else
    .S00_AXIS_0_tready    (difftest_to_host_axis_tready_io),
`endif
    .S00_AXIS_0_tvalid    (xdma_s00_axis_tvalid),
    .M00_AXIS_0_tdata     (difftest_from_host_axis_tdata),
    .M00_AXIS_0_tkeep     (difftest_from_host_axis_tkeep),
    .M00_AXIS_0_tlast     (difftest_from_host_axis_tlast),
    .M00_AXIS_0_tready    (xdma_m00_axis_tready),
    .M00_AXIS_0_tvalid    (difftest_from_host_axis_tvalid),

`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
    // The compatibility shell is not the GBus register master.  Leave its
    // quiescent AXI-Lite pins disconnected; GENERALBD drives the real config
    // path below.
    .XDMA_AXI_LITE_awaddr (), .XDMA_AXI_LITE_awprot (), .XDMA_AXI_LITE_awvalid(),
    .XDMA_AXI_LITE_awready(1'b0), .XDMA_AXI_LITE_wdata(), .XDMA_AXI_LITE_wstrb(),
    .XDMA_AXI_LITE_wvalid (), .XDMA_AXI_LITE_wready(1'b0),
    .XDMA_AXI_LITE_bresp  (2'b0), .XDMA_AXI_LITE_bvalid(1'b0), .XDMA_AXI_LITE_bready(),
    .XDMA_AXI_LITE_araddr (), .XDMA_AXI_LITE_arprot(), .XDMA_AXI_LITE_arvalid(),
    .XDMA_AXI_LITE_arready(1'b0), .XDMA_AXI_LITE_rdata(32'b0),
    .XDMA_AXI_LITE_rresp  (2'b0), .XDMA_AXI_LITE_rvalid(1'b0), .XDMA_AXI_LITE_rready(),
`else
    .XDMA_AXI_LITE_awaddr (XDMA_AXI_LITE_awaddr),
    .XDMA_AXI_LITE_awprot (XDMA_AXI_LITE_awprot),
    .XDMA_AXI_LITE_awvalid(XDMA_AXI_LITE_awvalid),
    .XDMA_AXI_LITE_awready(XDMA_AXI_LITE_awready),
    .XDMA_AXI_LITE_wdata  (XDMA_AXI_LITE_wdata),
    .XDMA_AXI_LITE_wstrb  (XDMA_AXI_LITE_wstrb),
    .XDMA_AXI_LITE_wvalid (XDMA_AXI_LITE_wvalid),
    .XDMA_AXI_LITE_wready (XDMA_AXI_LITE_wready),
    .XDMA_AXI_LITE_bresp  (XDMA_AXI_LITE_bresp),
    .XDMA_AXI_LITE_bvalid (XDMA_AXI_LITE_bvalid),
    .XDMA_AXI_LITE_bready (XDMA_AXI_LITE_bready),
    .XDMA_AXI_LITE_araddr (XDMA_AXI_LITE_araddr),
    .XDMA_AXI_LITE_arprot (XDMA_AXI_LITE_arprot),
    .XDMA_AXI_LITE_arvalid(XDMA_AXI_LITE_arvalid),
    .XDMA_AXI_LITE_arready(XDMA_AXI_LITE_arready),
    .XDMA_AXI_LITE_rdata  (XDMA_AXI_LITE_rdata),
    .XDMA_AXI_LITE_rresp  (XDMA_AXI_LITE_rresp),
    .XDMA_AXI_LITE_rvalid (XDMA_AXI_LITE_rvalid),
    .XDMA_AXI_LITE_rready (XDMA_AXI_LITE_rready),
`endif

`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
    // The GBus branch binds difftest_pcie_clock directly to the explicit
    // gbus_host_clk above.  Do not expose a pseudo XDMA clock output to UVHS
    // clock inference; the compatibility shell has no physical user clock.
    .TO_DIFFTEST_PCIE_CLK (),
`else
    .TO_DIFFTEST_PCIE_CLK (difftest_pcie_clock),
`endif
    .pci_exp_rxn(pci_ep_rxn),
    .pci_exp_rxp(pci_ep_rxp),
    .pci_exp_txn(pci_ep_txn),
    .pci_exp_txp(pci_ep_txp),
    .pcie_ep_gt_ref_clk_n(pcie_ep_gt_ref_clk_n),
    .pcie_ep_gt_ref_clk_p(pcie_ep_gt_ref_clk_p),
    .pcie_ep_lnk_up(pcie_ep_lnk_up_raw),
    .pcie_ep_perstn(pcie_ep_perstn)
  );

`ifdef CONFIG_DIFFTEST_HOSTIF_GBUS
  // The shared DiffTest sender (`Difftest2AXIs` inside the generated SimTop --
  // the very module the XDMA build streams straight into the XDMA IP) is the
  // C2H producer in both hostif modes.  Only the interface layer below it
  // differs.  The XDMA build has no DDR staging and neither does this one: the
  // same 256-bit stream is buffered in on-chip SRAM and exposed as a GBus
  // register window. The C2H path therefore does not enter the CPU memory
  // hierarchy or the physical DDR interface.
  assign difftest_to_host_axis_tready_io = gbus_c2h_sready;
  assign gbus_shell_sready = 1'b0;

  // libuvgbus addresses everything through a 0x1000 config window, so every
  // enable below is decoded on the *windowed* address while the downstream
  // blocks take the zero-based register offset.  Do not mix the two: decoding
  // an enable against the local offset compiles, elaborates, and then silently
  // dead-ends the whole block.  That is exactly how the C2H control write was
  // lost -- upstream a raw 0x2204 was compared against the local range
  // 0x1200..0x1204, so the fill never started and staged_words stayed 0
  // forever, while a status read only appeared to work because raw 0x2200
  // happened to hit a window branch and subtract back to the status offset.
  //
  // The two forms are equivalent for raw >= 0x1000 and both cannot alias for
  // raw < 0x1000 (the subtraction wraps to >= 0xf000, outside every range), so
  // decoding on the local address is safe as well as clearer.  Declare these
  // before the instances below; UVHS elaboration rejects forward references.
  assign gbus_cfg_local_wr_addr = gbus_cfg_wr_addr - 16'h1000;
  assign gbus_cfg_local_rd_addr = gbus_cfg_rd_addr - 16'h1000;

  wire gbus_c2h_cfg_wr_en =
      gbus_cfg_wr_en && (gbus_cfg_local_wr_addr >= 16'h1200) && (gbus_cfg_local_wr_addr <= 16'h1208);
  wire gbus_c2h_cfg_rd_en =
      gbus_cfg_rd_en &&
      (((gbus_cfg_local_rd_addr >= 16'h1200) && (gbus_cfg_local_rd_addr <= 16'h1208)) ||
       ((gbus_cfg_local_rd_addr >= 16'h2000) && (gbus_cfg_local_rd_addr <= 16'h2ffc)));
  wire gbus_axil_cfg_wr_en = gbus_cfg_wr_en && (gbus_cfg_local_wr_addr <= 16'h0030);
  wire gbus_axil_cfg_rd_en = gbus_cfg_rd_en && (gbus_cfg_local_rd_addr <= 16'h0030);

  // The sender is the same Difftest2AXIs instance the XDMA build feeds to PCIe;
  // only this interface layer differs, so nothing is staged in DDR.
  uvhs_gbus_c2h_fifo #(
      .AXIS_DATA_WIDTH(`CONFIG_DIFFTEST_HOST_AXIS_WIDTH)
  ) U_GBUS_C2H_FIFO (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .stream_rstn(difftest_c2h_rstn),
    .s_tdata(difftest_to_host_axis_tdata), .s_tkeep(difftest_to_host_axis_tkeep),
    .s_tlast(difftest_to_host_axis_tlast), .s_tvalid(difftest_to_host_axis_tvalid_io),
    .s_tready(gbus_c2h_sready),
    .cfg_wr_en(gbus_c2h_cfg_wr_en), .cfg_wr_addr(gbus_cfg_local_wr_addr),
    .cfg_wdata(gbus_cfg_wdata), .cfg_rd_en(gbus_c2h_cfg_rd_en),
    .cfg_rd_addr(gbus_cfg_local_rd_addr), .cfg_rdata(gbus_c2h_cfg_rdata),
    .cfg_rdata_vld(gbus_c2h_cfg_rdata_vld)
  );

  uvhs_generalbd_axilite_bridge U_GBUS_CONFIG_BRIDGE (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .gbd_wr_en(gbus_axil_cfg_wr_en), .gbd_wr_addr(gbus_cfg_local_wr_addr),
    .gbd_wdata(gbus_cfg_wdata), .gbd_rd_en(gbus_axil_cfg_rd_en),
    .gbd_rd_addr(gbus_cfg_local_rd_addr), .gbd_rdata(gbus_axil_cfg_rdata),
    .gbd_rdata_vld(gbus_axil_cfg_rdata_vld),
    .axil_awaddr(XDMA_AXI_LITE_awaddr), .axil_awvalid(XDMA_AXI_LITE_awvalid),
    .axil_awready(XDMA_AXI_LITE_awready), .axil_wdata(XDMA_AXI_LITE_wdata),
    .axil_wstrb(XDMA_AXI_LITE_wstrb), .axil_wvalid(XDMA_AXI_LITE_wvalid),
    .axil_wready(XDMA_AXI_LITE_wready), .axil_bresp(XDMA_AXI_LITE_bresp),
    .axil_bvalid(XDMA_AXI_LITE_bvalid), .axil_bready(XDMA_AXI_LITE_bready),
    .axil_araddr(XDMA_AXI_LITE_araddr), .axil_arvalid(XDMA_AXI_LITE_arvalid),
    .axil_arready(XDMA_AXI_LITE_arready), .axil_rdata(XDMA_AXI_LITE_rdata),
    .axil_rresp(XDMA_AXI_LITE_rresp), .axil_rvalid(XDMA_AXI_LITE_rvalid),
    .axil_rready(XDMA_AXI_LITE_rready), .h2c_active()
  );
  assign XDMA_AXI_LITE_awprot = 3'b0;
  assign XDMA_AXI_LITE_arprot = 3'b0;
  assign gbus_cfg_rdata = gbus_axil_cfg_rdata_vld ? gbus_axil_cfg_rdata : gbus_c2h_cfg_rdata;
  assign gbus_cfg_rdata_vld = gbus_axil_cfg_rdata_vld | gbus_c2h_cfg_rdata_vld;

  generalBD U_GBUS_GENERALBD (
    .i_clk        (gbus_host_clk),
    .i_rstn       (rstn_sw4),
    .i_clk_en     (1'b1),
    .o_wr_en      (gbus_cfg_wr_en),
    .o_wr_addr    (gbus_cfg_wr_addr),
    .o_wdata      (gbus_cfg_wdata),
    .o_rd_en      (gbus_cfg_rd_en),
    .o_rd_addr    (gbus_cfg_rd_addr),
    .i_rdata      (gbus_cfg_rdata),
    .i_rdata_vld  (gbus_cfg_rdata_vld),
    .gbd_sysbus_i (gbus_sysbus_to_generalbd),
    .gbd_sysbus_o (gbus_sysbus_to_generalbus)
  );

  uvw_general_bus U_GBUS_GENERAL_BUS (
    .dut_axi_aclk    (gbus_host_clk),
    .dut_axi_aclk_en (1'b1),
    .dut_axi_aresetn (rstn_sw4),
    .dut_axi_awid    (gbus_axi_awid), .dut_axi_awaddr(gbus_axi_awaddr), .dut_axi_awlen(gbus_axi_awlen),
    .dut_axi_awsize  (gbus_axi_awsize), .dut_axi_awburst(gbus_axi_awburst), .dut_axi_awlock(gbus_axi_awlock),
    .dut_axi_awcache(gbus_axi_awcache), .dut_axi_awprot(gbus_axi_awprot), .dut_axi_awqos(gbus_axi_awqos),
    .dut_axi_awvalid(gbus_axi_awvalid), .dut_axi_awready(gbus_axi_awready), .dut_axi_wid(gbus_axi_wid),
    .dut_axi_wdata(gbus_axi_wdata), .dut_axi_wstrb(gbus_axi_wstrb), .dut_axi_wlast(gbus_axi_wlast),
    .dut_axi_wvalid(gbus_axi_wvalid), .dut_axi_wready(gbus_axi_wready), .dut_axi_bid(gbus_axi_bid),
    .dut_axi_bresp(gbus_axi_bresp), .dut_axi_bvalid(gbus_axi_bvalid), .dut_axi_bready(gbus_axi_bready),
    .dut_axi_arid(gbus_axi_arid), .dut_axi_araddr(gbus_axi_araddr), .dut_axi_arlen(gbus_axi_arlen),
    .dut_axi_arsize(gbus_axi_arsize), .dut_axi_arburst(gbus_axi_arburst), .dut_axi_arlock(gbus_axi_arlock),
    .dut_axi_arcache(gbus_axi_arcache), .dut_axi_arprot(gbus_axi_arprot), .dut_axi_arqos(gbus_axi_arqos),
    .dut_axi_arvalid(gbus_axi_arvalid), .dut_axi_arready(gbus_axi_arready), .dut_axi_rid(gbus_axi_rid),
    .dut_axi_rdata(gbus_axi_rdata), .dut_axi_rresp(gbus_axi_rresp), .dut_axi_rlast(gbus_axi_rlast),
    .dut_axi_rvalid(gbus_axi_rvalid), .dut_axi_rready(gbus_axi_rready),
    .sysbus_ghbd_o (gbus_sysbus_to_generalbd),
    .sysbus_ghbd_i (gbus_sysbus_to_generalbus)
  );

  uvhs_axi3_to_axi4_adapter #(
      .ADDR_WIDTH(36), .ID_WIDTH(14), .AXI3_ID_WIDTH(8), .DATA_WIDTH(256)
  ) U_GBUS_AXI_ADAPTER (
    .clk(gbus_host_clk), .rstn(rstn_sw4),
    .s_awid(gbus_axi_awid), .s_awaddr({4'b0, gbus_axi_awaddr}),
    .s_awlen(gbus_axi_awlen), .s_awsize(gbus_axi_awsize),
    .s_awburst(gbus_axi_awburst), .s_awlock(gbus_axi_awlock),
    .s_awcache(gbus_axi_awcache), .s_awprot(gbus_axi_awprot),
    .s_awqos(gbus_axi_awqos), .s_awvalid(gbus_axi_awvalid),
    .s_awready(gbus_axi_awready), .s_wid(gbus_axi_wid),
    .s_wdata(gbus_axi_wdata), .s_wstrb(gbus_axi_wstrb),
    .s_wlast(gbus_axi_wlast), .s_wvalid(gbus_axi_wvalid),
    .s_wready(gbus_axi_wready), .s_bid(gbus_axi_bid),
    .s_bresp(gbus_axi_bresp), .s_bvalid(gbus_axi_bvalid),
    .s_bready(gbus_axi_bready), .s_arid(gbus_axi_arid),
    .s_araddr({4'b0, gbus_axi_araddr}), .s_arlen(gbus_axi_arlen),
    .s_arsize(gbus_axi_arsize), .s_arburst(gbus_axi_arburst),
    .s_arlock(gbus_axi_arlock), .s_arcache(gbus_axi_arcache),
    .s_arprot(gbus_axi_arprot), .s_arqos(gbus_axi_arqos),
    .s_arvalid(gbus_axi_arvalid), .s_arready(gbus_axi_arready),
    .s_rid(gbus_axi_rid), .s_rdata(gbus_axi_rdata),
    .s_rresp(gbus_axi_rresp), .s_rlast(gbus_axi_rlast),
    .s_rvalid(gbus_axi_rvalid), .s_rready(gbus_axi_rready),
    .m_awid(gbus_h2c_awid), .m_awaddr(gbus_h2c_awaddr),
    .m_awlen(gbus_h2c_awlen), .m_awsize(gbus_h2c_awsize),
    .m_awburst(gbus_h2c_awburst), .m_awlock(gbus_h2c_awlock),
    .m_awcache(gbus_h2c_awcache), .m_awprot(gbus_h2c_awprot),
    .m_awqos(gbus_h2c_awqos), .m_awregion(gbus_h2c_awregion),
    .m_awvalid(gbus_h2c_awvalid), .m_awready(gbus_h2c_awready),
    .m_wdata(gbus_h2c_wdata), .m_wstrb(gbus_h2c_wstrb),
    .m_wlast(gbus_h2c_wlast), .m_wvalid(gbus_h2c_wvalid),
    .m_wready(gbus_h2c_wready), .m_bid(gbus_h2c_bid),
    .m_bresp(gbus_h2c_bresp), .m_bvalid(gbus_h2c_bvalid),
    .m_bready(gbus_h2c_bready), .m_arid(gbus_h2c_arid),
    .m_araddr(gbus_h2c_araddr), .m_arlen(gbus_h2c_arlen),
    .m_arsize(gbus_h2c_arsize), .m_arburst(gbus_h2c_arburst),
    .m_arlock(gbus_h2c_arlock), .m_arcache(gbus_h2c_arcache),
    .m_arprot(gbus_h2c_arprot), .m_arqos(gbus_h2c_arqos),
    .m_arregion(gbus_h2c_arregion), .m_arvalid(gbus_h2c_arvalid),
    .m_arready(gbus_h2c_arready), .m_rid(gbus_h2c_rid),
    .m_rdata(gbus_h2c_rdata), .m_rresp(gbus_h2c_rresp),
    .m_rlast(gbus_h2c_rlast), .m_rvalid(gbus_h2c_rvalid),
    .m_rready(gbus_h2c_rready)
  );

  uvhs_axi_async_bridge #(
      .ADDR_WIDTH(36), .ID_WIDTH(14), .DATA_WIDTH(256)
  ) U_GBUS_H2C_CDC (
    .s_clk(gbus_host_clk), .s_rstn(rstn_sw4),
    .s_awid(gbus_h2c_awid), .s_awaddr(gbus_h2c_awaddr),
    .s_awlen(gbus_h2c_awlen), .s_awsize(gbus_h2c_awsize),
    .s_awburst(gbus_h2c_awburst), .s_awlock(gbus_h2c_awlock),
    .s_awcache(gbus_h2c_awcache), .s_awprot(gbus_h2c_awprot),
    .s_awqos(gbus_h2c_awqos), .s_awregion(gbus_h2c_awregion),
    .s_awvalid(gbus_h2c_awvalid), .s_awready(gbus_h2c_awready),
    .s_wdata(gbus_h2c_wdata), .s_wstrb(gbus_h2c_wstrb),
    .s_wlast(gbus_h2c_wlast), .s_wvalid(gbus_h2c_wvalid),
    .s_wready(gbus_h2c_wready), .s_bid(gbus_h2c_bid),
    .s_bresp(gbus_h2c_bresp), .s_bvalid(gbus_h2c_bvalid),
    .s_bready(gbus_h2c_bready), .s_arid(gbus_h2c_arid),
    .s_araddr(gbus_h2c_araddr), .s_arlen(gbus_h2c_arlen),
    .s_arsize(gbus_h2c_arsize), .s_arburst(gbus_h2c_arburst),
    .s_arlock(gbus_h2c_arlock), .s_arcache(gbus_h2c_arcache),
    .s_arprot(gbus_h2c_arprot), .s_arqos(gbus_h2c_arqos),
    .s_arregion(gbus_h2c_arregion), .s_arvalid(gbus_h2c_arvalid),
    .s_arready(gbus_h2c_arready), .s_rid(gbus_h2c_rid),
    .s_rdata(gbus_h2c_rdata), .s_rresp(gbus_h2c_rresp),
    .s_rlast(gbus_h2c_rlast), .s_rvalid(gbus_h2c_rvalid),
    .s_rready(gbus_h2c_rready),
    .m_clk(inter_soc_clk), .m_rstn(inter_soc_sync_rstn),
    .m_awid(gbus_dma_awid), .m_awaddr(gbus_dma_awaddr),
    .m_awlen(gbus_dma_awlen), .m_awsize(gbus_dma_awsize),
    .m_awburst(gbus_dma_awburst), .m_awlock(gbus_dma_awlock),
    .m_awcache(gbus_dma_awcache), .m_awprot(gbus_dma_awprot),
    .m_awqos(gbus_dma_awqos), .m_awregion(gbus_dma_awregion),
    .m_awvalid(gbus_dma_awvalid), .m_awready(gbus_dma_awready),
    .m_wdata(gbus_dma_wdata), .m_wstrb(gbus_dma_wstrb),
    .m_wlast(gbus_dma_wlast), .m_wvalid(gbus_dma_wvalid),
    .m_wready(gbus_dma_wready), .m_bid(gbus_dma_bid),
    .m_bresp(gbus_dma_bresp), .m_bvalid(gbus_dma_bvalid),
    .m_bready(gbus_dma_bready), .m_arid(gbus_dma_arid),
    .m_araddr(gbus_dma_araddr), .m_arlen(gbus_dma_arlen),
    .m_arsize(gbus_dma_arsize), .m_arburst(gbus_dma_arburst),
    .m_arlock(gbus_dma_arlock), .m_arcache(gbus_dma_arcache),
    .m_arprot(gbus_dma_arprot), .m_arqos(gbus_dma_arqos),
    .m_arregion(gbus_dma_arregion), .m_arvalid(gbus_dma_arvalid),
    .m_arready(gbus_dma_arready), .m_rid(gbus_dma_rid),
    .m_rdata(gbus_dma_rdata), .m_rresp(gbus_dma_rresp),
    .m_rlast(gbus_dma_rlast), .m_rvalid(gbus_dma_rvalid),
    .m_rready(gbus_dma_rready)
  );

`ifdef CPU_NUTSHELL
  // NutShell's inbound frontend is 64 bits wide even though the common wrapper
  // exposes the 256-bit dma_core_* contract. Use the vendor AXI converter so
  // wide and narrow GeneralBus bursts retain their AXI lane and response rules.
  uvhs_gbus_axi_dwidth U_GBUS_H2C_DWIDTH (
    .s_axi_aclk(inter_soc_clk), .s_axi_aresetn(inter_soc_sync_rstn),
    .s_axi_awid(gbus_dma_awid), .s_axi_awaddr(gbus_dma_awaddr),
    .s_axi_awlen(gbus_dma_awlen), .s_axi_awsize(gbus_dma_awsize),
    .s_axi_awburst(gbus_dma_awburst), .s_axi_awlock(gbus_dma_awlock),
    .s_axi_awcache(gbus_dma_awcache), .s_axi_awprot(gbus_dma_awprot),
    .s_axi_awregion(gbus_dma_awregion), .s_axi_awqos(gbus_dma_awqos),
    .s_axi_awvalid(gbus_dma_awvalid), .s_axi_awready(gbus_dma_awready),
    .s_axi_wdata(gbus_dma_wdata), .s_axi_wstrb(gbus_dma_wstrb),
    .s_axi_wlast(gbus_dma_wlast), .s_axi_wvalid(gbus_dma_wvalid),
    .s_axi_wready(gbus_dma_wready), .s_axi_bid(gbus_dma_bid),
    .s_axi_bresp(gbus_dma_bresp), .s_axi_bvalid(gbus_dma_bvalid),
    .s_axi_bready(gbus_dma_bready), .s_axi_arid(gbus_dma_arid),
    .s_axi_araddr(gbus_dma_araddr), .s_axi_arlen(gbus_dma_arlen),
    .s_axi_arsize(gbus_dma_arsize), .s_axi_arburst(gbus_dma_arburst),
    .s_axi_arlock(gbus_dma_arlock), .s_axi_arcache(gbus_dma_arcache),
    .s_axi_arprot(gbus_dma_arprot), .s_axi_arregion(gbus_dma_arregion),
    .s_axi_arqos(gbus_dma_arqos), .s_axi_arvalid(gbus_dma_arvalid),
    .s_axi_arready(gbus_dma_arready), .s_axi_rid(gbus_dma_rid),
    .s_axi_rdata(gbus_dma_rdata), .s_axi_rresp(gbus_dma_rresp),
    .s_axi_rlast(gbus_dma_rlast), .s_axi_rvalid(gbus_dma_rvalid),
    .s_axi_rready(gbus_dma_rready),
    .m_axi_awaddr(data_cpu_bridge_m2s_awaddr),
    .m_axi_awlen(data_cpu_bridge_m2s_awlen),
    .m_axi_awsize(data_cpu_bridge_m2s_awsize),
    .m_axi_awburst(data_cpu_bridge_m2s_awburst),
    .m_axi_awlock(data_cpu_bridge_m2s_awlock),
    .m_axi_awcache(data_cpu_bridge_m2s_awcache),
    .m_axi_awprot(data_cpu_bridge_m2s_awprot), .m_axi_awregion(),
    .m_axi_awqos(data_cpu_bridge_m2s_awqos),
    .m_axi_awvalid(data_cpu_bridge_m2s_awvalid),
    .m_axi_awready(data_cpu_bridge_s2m_awready),
    .m_axi_wdata(data_cpu_bridge_m2s_wdata[63:0]),
    .m_axi_wstrb(data_cpu_bridge_m2s_wstrb[7:0]),
    .m_axi_wlast(data_cpu_bridge_m2s_wlast),
    .m_axi_wvalid(data_cpu_bridge_m2s_wvalid),
    .m_axi_wready(data_cpu_bridge_s2m_wready),
    .m_axi_bresp(data_cpu_bridge_s2m_bresp),
    .m_axi_bvalid(data_cpu_bridge_s2m_bvalid),
    .m_axi_bready(data_cpu_bridge_m2s_bready),
    .m_axi_araddr(data_cpu_bridge_m2s_araddr),
    .m_axi_arlen(data_cpu_bridge_m2s_arlen),
    .m_axi_arsize(data_cpu_bridge_m2s_arsize),
    .m_axi_arburst(data_cpu_bridge_m2s_arburst),
    .m_axi_arlock(data_cpu_bridge_m2s_arlock),
    .m_axi_arcache(data_cpu_bridge_m2s_arcache),
    .m_axi_arprot(data_cpu_bridge_m2s_arprot), .m_axi_arregion(),
    .m_axi_arqos(data_cpu_bridge_m2s_arqos),
    .m_axi_arvalid(data_cpu_bridge_m2s_arvalid),
    .m_axi_arready(data_cpu_bridge_s2m_arready),
    .m_axi_rdata(data_cpu_bridge_s2m_rdata[63:0]),
    .m_axi_rresp(data_cpu_bridge_s2m_rresp),
    .m_axi_rlast(data_cpu_bridge_s2m_rlast),
    .m_axi_rvalid(data_cpu_bridge_s2m_rvalid),
    .m_axi_rready(data_cpu_bridge_m2s_rready)
  );
  assign data_cpu_bridge_m2s_awid = 14'b0;
  assign data_cpu_bridge_m2s_arid = 14'b0;
  assign data_cpu_bridge_m2s_wdata[255:64] = 192'b0;
  assign data_cpu_bridge_m2s_wstrb[31:8] = 24'b0;
`else
  assign data_cpu_bridge_m2s_awid = gbus_dma_awid;
  assign data_cpu_bridge_m2s_awaddr = gbus_dma_awaddr;
  assign data_cpu_bridge_m2s_awlen = gbus_dma_awlen;
  assign data_cpu_bridge_m2s_awsize = gbus_dma_awsize;
  assign data_cpu_bridge_m2s_awburst = gbus_dma_awburst;
  assign data_cpu_bridge_m2s_awlock = gbus_dma_awlock;
  assign data_cpu_bridge_m2s_awcache = gbus_dma_awcache;
  assign data_cpu_bridge_m2s_awprot = gbus_dma_awprot;
  assign data_cpu_bridge_m2s_awqos = gbus_dma_awqos;
  assign data_cpu_bridge_m2s_awvalid = gbus_dma_awvalid;
  assign gbus_dma_awready = data_cpu_bridge_s2m_awready;
  assign data_cpu_bridge_m2s_wdata = gbus_dma_wdata;
  assign data_cpu_bridge_m2s_wstrb = gbus_dma_wstrb;
  assign data_cpu_bridge_m2s_wlast = gbus_dma_wlast;
  assign data_cpu_bridge_m2s_wvalid = gbus_dma_wvalid;
  assign gbus_dma_wready = data_cpu_bridge_s2m_wready;
  assign gbus_dma_bid = data_cpu_bridge_s2m_bid;
  assign gbus_dma_bresp = data_cpu_bridge_s2m_bresp;
  assign gbus_dma_bvalid = data_cpu_bridge_s2m_bvalid;
  assign data_cpu_bridge_m2s_bready = gbus_dma_bready;
  assign data_cpu_bridge_m2s_arid = gbus_dma_arid;
  assign data_cpu_bridge_m2s_araddr = gbus_dma_araddr;
  assign data_cpu_bridge_m2s_arlen = gbus_dma_arlen;
  assign data_cpu_bridge_m2s_arsize = gbus_dma_arsize;
  assign data_cpu_bridge_m2s_arburst = gbus_dma_arburst;
  assign data_cpu_bridge_m2s_arlock = gbus_dma_arlock;
  assign data_cpu_bridge_m2s_arcache = gbus_dma_arcache;
  assign data_cpu_bridge_m2s_arprot = gbus_dma_arprot;
  assign data_cpu_bridge_m2s_arqos = gbus_dma_arqos;
  assign data_cpu_bridge_m2s_arvalid = gbus_dma_arvalid;
  assign gbus_dma_arready = data_cpu_bridge_s2m_arready;
  assign gbus_dma_rid = data_cpu_bridge_s2m_rid;
  assign gbus_dma_rdata = data_cpu_bridge_s2m_rdata;
  assign gbus_dma_rresp = data_cpu_bridge_s2m_rresp;
  assign gbus_dma_rlast = data_cpu_bridge_s2m_rlast;
  assign gbus_dma_rvalid = data_cpu_bridge_s2m_rvalid;
  assign data_cpu_bridge_m2s_rready = gbus_dma_rready;
`endif

`endif

  // CPU progress is controlled exclusively by the DiffTest ready/clock-enable
  // handshake.  GBus FIFO activity must not be OR'ed into this signal:
  // doing so lets the CPU retire while the formatter snapshot is waiting for
  // transport backpressure, which mixes the architectural register snapshot
  // with a later commit group.  This is the same verified gating contract used
  // by the XDMA path.  The GBus drain path must therefore be provisioned with
  // enough buffering (or moved to an independent always-running clock) rather
  // than weakening CPU backpressure.
  wire soc_clock_run_enable =
      (difftest_clock_gate_enable & xdma_link_up) ||
      ~io_host_diff_enable || ~sys_rstn_io || ~cpu_rstn_io;

  DifftestClockGate SOC_CLK_CTRL(
      .CK  (sys_clk_i),
      .E   (soc_clock_run_enable),
      .Q   (inter_soc_clk)
  );

  wire difftest_clock_gate_enable_tmclk;
  wire xdma_link_up_tmclk;
  wire io_host_reset_tmclk;
  wire io_host_diff_enable_tmclk;
  wire sys_rstn_tmclk;
  wire cpu_rstn_tmclk;

  RST_SYNC #(.INIT(1'b0)) rtc_clock_gate_enable_sync (
      .clk      (tmclk),
      .async_in (difftest_clock_gate_enable),
      .sync_out (difftest_clock_gate_enable_tmclk)
  );

  RST_SYNC #(.INIT(1'b0)) rtc_xdma_link_up_sync (
      .clk      (tmclk),
      .async_in (xdma_link_up),
      .sync_out (xdma_link_up_tmclk)
  );

  RST_SYNC #(.INIT(1'b1)) rtc_host_reset_sync (
      .clk      (tmclk),
      .async_in (io_host_reset),
      .sync_out (io_host_reset_tmclk)
  );

  RST_SYNC #(.INIT(1'b0)) rtc_host_diff_enable_sync (
      .clk      (tmclk),
      .async_in (io_host_diff_enable),
      .sync_out (io_host_diff_enable_tmclk)
  );

  RST_SYNC #(.INIT(1'b0)) rtc_sys_rstn_sync (
      .clk      (tmclk),
      .async_in (sys_rstn),
      .sync_out (sys_rstn_tmclk)
  );

  RST_SYNC #(.INIT(1'b0)) rtc_cpu_rstn_sync (
      .clk      (tmclk),
      .async_in (cpu_rstn),
      .sync_out (cpu_rstn_tmclk)
  );

  wire sys_rstn_io_tmclk = sys_rstn_tmclk & ~io_host_reset_tmclk;
  wire cpu_rstn_io_tmclk = cpu_rstn_tmclk & ~io_host_reset_tmclk;

  DifftestClockGate RTC_CLK_CTRL(
      .CK  (tmclk),
      .E   ((difftest_clock_gate_enable_tmclk & xdma_link_up_tmclk)
            || ~io_host_diff_enable_tmclk || ~sys_rstn_io_tmclk || ~cpu_rstn_io_tmclk),
      .Q   (inter_rtc_clk)
  );

  RST_SYNC #(
      .SYNC_STAGES(3),
      .PIPELINE_STAGES(1),
      .INIT(1'b0)
  ) inter_soc_rstn_sync (
      .clk      (inter_soc_clk),
      .async_in (axi_bclk_sync_rstn),
      .sync_out (inter_soc_sync_rstn)
  );
`else
  wire inter_soc_clk;
  wire inter_rtc_clk;
  wire inter_soc_sync_rstn;
  wire sys_rstn_io;
  wire cpu_rstn_io;

  assign inter_soc_clk = sys_clk_i;
  assign inter_rtc_clk = tmclk;
  assign inter_soc_sync_rstn = axi_bclk_sync_rstn;
  assign sys_rstn_io = sys_rstn;
  assign cpu_rstn_io = cpu_rstn;
`endif

xilnx_crg xilnx_crg(
   .sys_clk                         (sys_clk_i                     ),
   .dev_clk                         (dev_clk_i                     ),
   .tmclk                           (tmclk                         ),
   .cqetmclk                        (cqetmclk                      ),
   .sys_rstn                        (sys_rstn_io                   ),
   .axi_bus_clk                     (axi_bus_clk                   ),
   .axi_bclk_sync_rstn              (axi_bclk_sync_rstn            ),
   .ddr_bus_clk                     (ddr_bus_clk                   ),
   .ddr_bclk_sync_rstn              (ddr_bclk_sync_rstn            ),
 `ifdef  XS_UART
   .uart_pclk                       (uart_pclk                     ),
   .uart_pclk_sync_rstn             (uart_pclk_sync_rstn           ),
   .uart_sclk                       (uart_sclk                     ),
   .uart_sclk_sync_rstn             (uart_sclk_sync_rstn           ),
 `endif
   .qspi_sclk                       (qspi_sclk                     ),
   .qspi_pclk                       (qspi_pclk                     ),
   .qspi_pclk_sync_rstn             (qspi_pclk_sync_rstn           ),
   .qspi_hclk                       (qspi_hclk                     ),
   .qspi_hclk_sync_rstn             (qspi_hclk_sync_rstn           ),
   .qspi_ref_clk                    (qspi_ref_clk                  ),
   .qspi_rclk_sync_rstn             (qspi_rclk_sync_rstn           ),
   .sd_axi_clk                      (sd_axi_clk                    ),
   .sd_aclk_sync_rstn               (sd_aclk_sync_rstn             ),
   .sd_ahb_clk                      (sd_ahb_clk                    ),
   .sd_hclk_sync_rstn               (sd_hclk_sync_rstn             ),
   .sd_bclk                         (sd_bclk                       ),
   .sd_bclk_sync_rstn               (sd_bclk_sync_rstn             ),
   .sd_tmclk                        (sd_tmclk                      ),
   .sd_tclk_sync_rstn               (sd_tclk_sync_rstn             ),
   .sd_cqetmclk                     (sd_cqetmclk                   ),
   .sd_cqetclk_sync_rstn            (sd_cqetclk_sync_rstn          )
);

assign dma_m_arvalid = 0;
assign dma_m_awvalid = 0;
assign dma_m_wvalid = 0;
assign dma_hready = 1;
assign dma_hrdata = 0;
assign dma_int = 0;
mode_ctrl U_MODE_CTRL(
    .chip_mode_i                    (chip_mode_i                   ),
    .normal_mode                    (normal_mode                   ),
    .phy_bist_mode                  (phy_bist_mode                 ),
    .mbist_mode                     (mbist_mode                    ),
    .scan_mode                      (                              )
);

`ifdef UVHS
// The vendor DDR IP uses 34-bit addresses and 14-bit IDs. Keep those narrow
// adaptations local while preserving the common fpga_diff AXI interface.
wire [33:0] uvhs_ddr_awaddr;
wire [33:0] uvhs_ddr_araddr;
wire [13:0] uvhs_ddr_bid;
wire [13:0] uvhs_ddr_rid;
wire        uvhs_ddr_user_rst;

`ifdef CPU_NUTSHELL
assign uvhs_ddr_awaddr = {1'b0, cpu2ddr_m2s_awaddr_mix};
assign uvhs_ddr_araddr = {1'b0, cpu2ddr_m2s_araddr_mix};
`else
assign uvhs_ddr_awaddr = cpu2ddr_m2s_awaddr_mix[33:0];
assign uvhs_ddr_araddr = cpu2ddr_m2s_araddr_mix[33:0];
`endif
assign cpu2ddr_s2m_bid = {4'b0, uvhs_ddr_bid};
assign cpu2ddr_s2m_rid = {4'b0, uvhs_ddr_rid};
assign init_calib_complete = rstn_sw4 & ~uvhs_ddr_user_rst;

uvw_axi4_to_ddr4 U_UVHS_UVW_AXI4_TO_DDR4 (
    .ddr4ip_dut_axi_aclk       (sys_clk_i),
    .ddr4ip_dut_axi_aresetn    (rstn_sw4),
    .ddr4ip_dut_axi_awaddr     (uvhs_ddr_awaddr),
    .ddr4ip_dut_axi_awburst    (cpu2ddr_m2s_awburst),
    .ddr4ip_dut_axi_awcache    (cpu2ddr_m2s_awcache),
    .ddr4ip_dut_axi_awid       (cpu2ddr_m2s_awid_mix[13:0]),
    .ddr4ip_dut_axi_awlen      (cpu2ddr_m2s_awlen),
    .ddr4ip_dut_axi_awlock     (cpu2ddr_m2s_awlock),
    .ddr4ip_dut_axi_awprot     (cpu2ddr_m2s_awprot),
    .ddr4ip_dut_axi_awqos      (cpu2ddr_m2s_awqos),
    .ddr4ip_dut_axi_awready    (cpu2ddr_s2m_awready),
    .ddr4ip_dut_axi_awregion   (cpu2ddr_m2s_awregion),
    .ddr4ip_dut_axi_awsize     (cpu2ddr_m2s_awsize),
    .ddr4ip_dut_axi_awvalid    (cpu2ddr_m2s_awvalid),
    .ddr4ip_dut_axi_wdata      (cpu2ddr_m2s_wdata),
    .ddr4ip_dut_axi_wlast      (cpu2ddr_m2s_wlast),
    .ddr4ip_dut_axi_wready     (cpu2ddr_s2m_wready),
    .ddr4ip_dut_axi_wstrb      (cpu2ddr_m2s_wstrb),
    .ddr4ip_dut_axi_wvalid     (cpu2ddr_m2s_wvalid),
    .ddr4ip_dut_axi_bid        (uvhs_ddr_bid),
    .ddr4ip_dut_axi_bready     (cpu2ddr_m2s_bready),
    .ddr4ip_dut_axi_bresp      (cpu2ddr_s2m_bresp),
    .ddr4ip_dut_axi_bvalid     (cpu2ddr_s2m_bvalid),
    .ddr4ip_dut_axi_araddr     (uvhs_ddr_araddr),
    .ddr4ip_dut_axi_arburst    (cpu2ddr_m2s_arburst),
    .ddr4ip_dut_axi_arcache    (cpu2ddr_m2s_arcache),
    .ddr4ip_dut_axi_arid       (cpu2ddr_m2s_arid_mix[13:0]),
    .ddr4ip_dut_axi_arlen      (cpu2ddr_m2s_arlen),
    .ddr4ip_dut_axi_arlock     (cpu2ddr_m2s_arlock),
    .ddr4ip_dut_axi_arprot     (cpu2ddr_m2s_arprot),
    .ddr4ip_dut_axi_arqos      (cpu2ddr_m2s_arqos),
    .ddr4ip_dut_axi_arready    (cpu2ddr_s2m_arready),
    .ddr4ip_dut_axi_arregion   (cpu2ddr_m2s_arregion),
    .ddr4ip_dut_axi_arsize     (cpu2ddr_m2s_arsize),
    .ddr4ip_dut_axi_arvalid    (cpu2ddr_m2s_arvalid),
    .ddr4ip_dut_axi_rdata      (cpu2ddr_s2m_rdata),
    .ddr4ip_dut_axi_rid        (uvhs_ddr_rid),
    .ddr4ip_dut_axi_rlast      (cpu2ddr_s2m_rlast),
    .ddr4ip_dut_axi_rready     (cpu2ddr_m2s_rready),
    .ddr4ip_dut_axi_rresp      (cpu2ddr_s2m_rresp),
    .ddr4ip_dut_axi_rvalid     (cpu2ddr_s2m_rvalid),
    .ddr4ip_dut_axi_aclk_en    (difftest_clock_gate_enable),
    .ddr4ip_ddr4_user_clk      (),
    .ddr4ip_ddr4_user_rst      (uvhs_ddr_user_rst),
    .sysbus_ghbd_i             (256'b0),
    .sysbus_ghbd_o             (),
    .FP_CLK_200M_P             (),
    .FP_CLK_200M_N             (),
    .DDR4_DIMM_ACT_N           (),
    .DDR4_DIMM_A               (),
    .DDR4_DIMM_BA              (),
    .DDR4_DIMM_BG              (),
    .DDR4_DIMM_CK_N            (),
    .DDR4_DIMM_CK_P            (),
    .DDR4_DIMM_CKE             (),
    .DDR4_DIMM_CS_N            (),
    .DDR4_DIMM_ODT             (),
    .DDR4_DIMM_RST_B           (),
    .DDR4_DIMM_DM              (),
    .DDR4_DIMM_DQ              (),
    .DDR4_DIMM_DQS_N           (),
    .DDR4_DIMM_DQS_P           ()
);
`else
jtag_ddr_subsys_wrapper U_JTAG_DDR_SUBSYS(
    .DDR4_act_n             (DDR_ACT_N),
    .DDR4_adr               (DDR_A),
    .DDR4_ba                (DDR_BA),
    .DDR4_bg                (DDR_BG),
    .DDR4_ck_c              (DDR_CK_C),
    .DDR4_ck_t              (DDR_CK_T),
    .DDR4_cke               (DDR_CKE),
    .DDR4_cs_n              (DDR_CS_N),
    .DDR4_dm_n              (DDR_DM_N),
    .DDR4_dq                (DDR_DQ),
    .DDR4_dqs_c             (DDR_DQS_C),
    .DDR4_dqs_t             (DDR_DQS_T),
    .DDR4_odt               (DDR_ODT),
    .DDR4_reset_n           (DDR_RESET_N),
    .OSC_SYS_CLK_clk_n      (ddr_clk_n),
    .OSC_SYS_CLK_clk_p      (ddr_clk_p),
    // AXI INTERFACE CLK
    .SOC_CLK                (inter_soc_clk),

    .SOC_M_AXI_awid         (cpu2ddr_m2s_awid_mix          ),
    .SOC_M_AXI_awaddr       (cpu2ddr_m2s_awaddr_mix        ),
    .SOC_M_AXI_awlen        (cpu2ddr_m2s_awlen             ),
    .SOC_M_AXI_awsize       (cpu2ddr_m2s_awsize            ),
    .SOC_M_AXI_awburst      (cpu2ddr_m2s_awburst           ),
    .SOC_M_AXI_awlock       (cpu2ddr_m2s_awlock            ),
    .SOC_M_AXI_awcache      (cpu2ddr_m2s_awcache           ),
    .SOC_M_AXI_awprot       (cpu2ddr_m2s_awprot            ),
    .SOC_M_AXI_awqos        (cpu2ddr_m2s_awqos             ),
    .SOC_M_AXI_awvalid      (cpu2ddr_m2s_awvalid           ),
    .SOC_M_AXI_awready      (cpu2ddr_s2m_awready           ),
    .SOC_M_AXI_wdata        (cpu2ddr_m2s_wdata             ),
    .SOC_M_AXI_wstrb        (cpu2ddr_m2s_wstrb             ),
    .SOC_M_AXI_wlast        (cpu2ddr_m2s_wlast             ),
    .SOC_M_AXI_wvalid       (cpu2ddr_m2s_wvalid            ),
    .SOC_M_AXI_wready       (cpu2ddr_s2m_wready            ),
    .SOC_M_AXI_bid          (cpu2ddr_s2m_bid               ),
    .SOC_M_AXI_bresp        (cpu2ddr_s2m_bresp             ),
    .SOC_M_AXI_bvalid       (cpu2ddr_s2m_bvalid            ),
    .SOC_M_AXI_bready       (cpu2ddr_m2s_bready            ),
    .SOC_M_AXI_arid         (cpu2ddr_m2s_arid_mix          ),
    .SOC_M_AXI_araddr       (cpu2ddr_m2s_araddr_mix        ),
    .SOC_M_AXI_arlen        (cpu2ddr_m2s_arlen             ),
    .SOC_M_AXI_arsize       (cpu2ddr_m2s_arsize            ),
    .SOC_M_AXI_arburst      (cpu2ddr_m2s_arburst           ),
    .SOC_M_AXI_arlock       (cpu2ddr_m2s_arlock            ),
    .SOC_M_AXI_arcache      (cpu2ddr_m2s_arcache           ),
    .SOC_M_AXI_arprot       (cpu2ddr_m2s_arprot            ),
    .SOC_M_AXI_arqos        (cpu2ddr_m2s_arqos             ),
    .SOC_M_AXI_arvalid      (cpu2ddr_m2s_arvalid           ),
    .SOC_M_AXI_arready      (cpu2ddr_s2m_arready           ),
    .SOC_M_AXI_rid          (cpu2ddr_s2m_rid               ),
    .SOC_M_AXI_rdata        (cpu2ddr_s2m_rdata             ),
    .SOC_M_AXI_rresp        (cpu2ddr_s2m_rresp             ),
    .SOC_M_AXI_rlast        (cpu2ddr_s2m_rlast             ),
    .SOC_M_AXI_rvalid       (cpu2ddr_s2m_rvalid            ),
    .SOC_M_AXI_rready       (cpu2ddr_m2s_rready            ),
`ifdef CONFIG_HAVE_DDRC_MCU_PERI_AXI
    /* ext peri AXI */
    .M_AXI_DP_araddr        (mcu_axi_dp_araddr  ),
    .M_AXI_DP_arburst       (mcu_axi_dp_arburst ),
    .M_AXI_DP_arcache       (mcu_axi_dp_arcache ),
    .M_AXI_DP_arlen         (mcu_axi_dp_arlen   ),
    .M_AXI_DP_arlock        (mcu_axi_dp_arlock  ),
    .M_AXI_DP_arprot        (mcu_axi_dp_arprot  ),
    .M_AXI_DP_arqos         (mcu_axi_dp_arqos   ),
    .M_AXI_DP_arready       (mcu_axi_dp_arready ),
    .M_AXI_DP_arregion      (mcu_axi_dp_arregion),
    .M_AXI_DP_arsize        (mcu_axi_dp_arsize  ),
    .M_AXI_DP_arvalid       (mcu_axi_dp_arvalid ),
    .M_AXI_DP_awaddr        (mcu_axi_dp_awaddr  ),
    .M_AXI_DP_awburst       (mcu_axi_dp_awburst ),
    .M_AXI_DP_awcache       (mcu_axi_dp_awcache ),
    .M_AXI_DP_awlen         (mcu_axi_dp_awlen   ),
    .M_AXI_DP_awlock        (mcu_axi_dp_awlock  ),
    .M_AXI_DP_awprot        (mcu_axi_dp_awprot  ),
    .M_AXI_DP_awqos         (mcu_axi_dp_awqos   ),
    .M_AXI_DP_awready       (mcu_axi_dp_awready ),
    .M_AXI_DP_awregion      (mcu_axi_dp_awregion),
    .M_AXI_DP_awsize        (mcu_axi_dp_awsize  ),
    .M_AXI_DP_awvalid       (mcu_axi_dp_awvalid ),
    .M_AXI_DP_bready        (mcu_axi_dp_bready  ),
    .M_AXI_DP_bresp         (mcu_axi_dp_bresp   ),
    .M_AXI_DP_bvalid        (mcu_axi_dp_bvalid  ),
    .M_AXI_DP_rdata         (mcu_axi_dp_rdata   ),
    .M_AXI_DP_rlast         (mcu_axi_dp_rlast   ),
    .M_AXI_DP_rready        (mcu_axi_dp_rready  ),
    .M_AXI_DP_rresp         (mcu_axi_dp_rresp   ),
    .M_AXI_DP_rvalid        (mcu_axi_dp_rvalid  ),
    .M_AXI_DP_wdata         (mcu_axi_dp_wdata   ),
    .M_AXI_DP_wlast         (mcu_axi_dp_wlast   ),
    .M_AXI_DP_wready        (mcu_axi_dp_wready  ),
    .M_AXI_DP_wstrb         (mcu_axi_dp_wstrb   ),
    .M_AXI_DP_wvalid        (mcu_axi_dp_wvalid  ),
`endif /* CONFIG_HAVE_DDRC_MCU_PERI_AXI */
    .ddr_rstn               (rstn_sw4),
    .soc_rstn               (rstn_sw4),
    .calib_complete         (init_calib_complete)
);
`endif

SimTop_wrapper U_CPU_TOP(
`ifndef NO_DIFF
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
    .difftest_ref_clock              (sys_clk_i),
    .difftest_ref_reset              (~sys_rstn),
    .difftest_hostCtrl_reset         (io_host_reset),
    .difftest_hostCtrl_diffEnable    (io_host_diff_enable),
    .difftest_hostCtrl_ilaTrigger    (io_host_ila_trigger),
    .difftest_cfg_axilite_awaddr     (difftest_cfg_axilite_awaddr),
    .difftest_cfg_axilite_awvalid    (difftest_cfg_axilite_awvalid),
    .difftest_cfg_axilite_awready    (difftest_cfg_axilite_awready),
    .difftest_cfg_axilite_wdata      (difftest_cfg_axilite_wdata),
    .difftest_cfg_axilite_wstrb      (difftest_cfg_axilite_wstrb),
    .difftest_cfg_axilite_wvalid     (difftest_cfg_axilite_wvalid),
    .difftest_cfg_axilite_wready     (difftest_cfg_axilite_wready),
    .difftest_cfg_axilite_bresp      (difftest_cfg_axilite_bresp),
    .difftest_cfg_axilite_bvalid     (difftest_cfg_axilite_bvalid),
    .difftest_cfg_axilite_bready     (difftest_cfg_axilite_bready),
    .difftest_cfg_axilite_araddr     (difftest_cfg_axilite_araddr),
    .difftest_cfg_axilite_arvalid    (difftest_cfg_axilite_arvalid),
    .difftest_cfg_axilite_arready    (difftest_cfg_axilite_arready),
    .difftest_cfg_axilite_rdata      (difftest_cfg_axilite_rdata),
    .difftest_cfg_axilite_rresp      (difftest_cfg_axilite_rresp),
    .difftest_cfg_axilite_rvalid     (difftest_cfg_axilite_rvalid),
    .difftest_cfg_axilite_rready     (difftest_cfg_axilite_rready),
`endif
    .inter_soc_clk                  (inter_soc_clk),
    .sys_rstn_i                     (cpu_rstn_io  ),
    .tmclk                          (inter_rtc_clk),

    .global_reset                   (cpu_rstn                  ),
    .pll_bypass_sel                 (4'b0 ),
    .pll0_lock                      (),
    .pll0_clk_div_1024              (),
    .pll0_test_calout               (),
    .soc_to_cpu                     (16'b0                         ),
    .cpu_to_soc                     (                              ),
`ifdef CONFIG_USE_IMSIC
    .io_imsic_awready               (xstile_imsic_awready),
    .io_imsic_awvalid               (xstile_imsic_awvalid),
    .io_imsic_awid                  (xstile_imsic_awid),
    .io_imsic_awaddr                (xstile_imsic_awaddr),
    .io_imsic_wready                (xstile_imsic_wready),
    .io_imsic_wvalid                (xstile_imsic_wvalid),
    .io_imsic_wdata                 (xstile_imsic_wdata),
    .io_imsic_bready                (xstile_imsic_bready),
    .io_imsic_bvalid                (xstile_imsic_bvalid),
    .io_imsic_bid                   (xstile_imsic_bid),
    .io_imsic_bresp                 (xstile_imsic_bresp),
    .io_imsic_arready               (xstile_imsic_arready),
    .io_imsic_arvalid               (xstile_imsic_arvalid),
    .io_imsic_arid                  (xstile_imsic_arid),
    .io_imsic_araddr                (xstile_imsic_araddr),
    .io_imsic_rready                (xstile_imsic_rready),
    .io_imsic_rvalid                (xstile_imsic_rvalid),
    .io_imsic_rid                   (xstile_imsic_rid),
    .io_imsic_rdata                 (xstile_imsic_rdata),
    .io_imsic_rresp                 (xstile_imsic_rresp),
`endif /* CONFIG_USE_IMSIC */
    .io_systemjtag_jtag_TCK         (io_systemjtag_jtag_TCK),
    .io_systemjtag_jtag_TMS         (io_systemjtag_jtag_TMS),
    .io_systemjtag_jtag_TDI         (io_systemjtag_jtag_TDI),
    .io_systemjtag_jtag_TDO_data    (io_systemjtag_jtag_TDO_data),
    .io_systemjtag_jtag_TDO_driven  (io_systemjtag_jtag_TDO_driven),
//    .io_systemjtag_reset            (io_systemjtag_reset),
    .io_systemjtag_reset            (~sys_rstn_io),
    .io_sram_config                 (16'b0),

    .dma_core_awready               (data_cpu_bridge_s2m_awready),
    .dma_core_awvalid               (data_cpu_bridge_m2s_awvalid),
    .dma_core_awid                  (data_cpu_bridge_m2s_awid),
    .dma_core_awaddr                (data_cpu_bridge_m2s_awaddr),
    .dma_core_awlen                 (data_cpu_bridge_m2s_awlen),
    .dma_core_awsize                (data_cpu_bridge_m2s_awsize),
    .dma_core_awburst               (data_cpu_bridge_m2s_awburst),
    .dma_core_awlock                (data_cpu_bridge_m2s_awlock),
    .dma_core_awcache               (data_cpu_bridge_m2s_awcache),
    .dma_core_awprot                (data_cpu_bridge_m2s_awprot),
    .dma_core_awqos                 (data_cpu_bridge_m2s_awqos),
    .dma_core_wready                (data_cpu_bridge_s2m_wready),
    .dma_core_wvalid                (data_cpu_bridge_m2s_wvalid),
    .dma_core_wdata                 (data_cpu_bridge_m2s_wdata),
    .dma_core_wstrb                 (data_cpu_bridge_m2s_wstrb),
    .dma_core_wlast                 (data_cpu_bridge_m2s_wlast),
    .dma_core_bready                (data_cpu_bridge_m2s_bready),
    .dma_core_bvalid                (data_cpu_bridge_s2m_bvalid),
    .dma_core_bid                   (data_cpu_bridge_s2m_bid),
    .dma_core_bresp                 (data_cpu_bridge_s2m_bresp),
    .dma_core_arready               (data_cpu_bridge_s2m_arready),
    .dma_core_arvalid               (data_cpu_bridge_m2s_arvalid),
    .dma_core_arid                  (data_cpu_bridge_m2s_arid),
    .dma_core_araddr                (data_cpu_bridge_m2s_araddr),
    .dma_core_arlen                 (data_cpu_bridge_m2s_arlen),
    .dma_core_arsize                (data_cpu_bridge_m2s_arsize),
    .dma_core_arburst               (data_cpu_bridge_m2s_arburst),
    .dma_core_arlock                (data_cpu_bridge_m2s_arlock),
    .dma_core_arcache               (data_cpu_bridge_m2s_arcache),
    .dma_core_arprot                (data_cpu_bridge_m2s_arprot),
    .dma_core_arqos                 (data_cpu_bridge_m2s_arqos),
    .dma_core_rready                (data_cpu_bridge_m2s_rready),
    .dma_core_rvalid                (data_cpu_bridge_s2m_rvalid),
    .dma_core_rid                   (data_cpu_bridge_s2m_rid),
    .dma_core_rdata                 (data_cpu_bridge_s2m_rdata),
    .dma_core_rresp                 (data_cpu_bridge_s2m_rresp),
    .dma_core_rlast                 (data_cpu_bridge_s2m_rlast),

    .peri_awready                   (cpu2cfg_s2m_awready),
    .peri_awvalid                   (cpu2cfg_m2s_awvalid),
    .peri_awid                      (cpu2cfg_m2s_awid),
    .peri_awaddr                    (cpu2cfg_m2s_awaddr),
    .peri_awlen                     (cpu2cfg_m2s_awlen),
    .peri_awsize                    (cpu2cfg_m2s_awsize),
    .peri_awburst                   (cpu2cfg_m2s_awburst),
    .peri_awlock                    (cpu2cfg_m2s_awlock),
    .peri_awcache                   (cpu2cfg_m2s_awcache),
    .peri_awprot                    (cpu2cfg_m2s_awprot),
    .peri_awqos                     (cpu2cfg_m2s_awqos),
    .peri_wready                    (cpu2cfg_s2m_wready),
    .peri_wvalid                    (cpu2cfg_m2s_wvalid),
    .peri_wdata                     (cpu2cfg_m2s_wdata),
    .peri_wstrb                     (cpu2cfg_m2s_wstrb),
    .peri_wlast                     (cpu2cfg_m2s_wlast),
    .peri_bready                    (cpu2cfg_m2s_bready),
    .peri_bvalid                    (cpu2cfg_s2m_bvalid),
    .peri_bid                       (cpu2cfg_s2m_bid),
    .peri_bresp                     (cpu2cfg_s2m_bresp),
    .peri_arready                   (cpu2cfg_s2m_arready),
    .peri_arvalid                   (cpu2cfg_m2s_arvalid),
    .peri_arid                      (cpu2cfg_m2s_arid),
    .peri_araddr                    (cpu2cfg_m2s_araddr),
    .peri_arlen                     (cpu2cfg_m2s_arlen),
    .peri_arsize                    (cpu2cfg_m2s_arsize),
    .peri_arburst                   (cpu2cfg_m2s_arburst),
    .peri_arlock                    (cpu2cfg_m2s_arlock),
    .peri_arcache                   (cpu2cfg_m2s_arcache),
    .peri_arprot                    (cpu2cfg_m2s_arprot),
    .peri_arqos                     (cpu2cfg_m2s_arqos),
    .peri_rready                    (cpu2cfg_m2s_rready),
    .peri_rvalid                    (cpu2cfg_s2m_rvalid),
    .peri_rid                       (cpu2cfg_s2m_rid),
    .peri_rdata                     (cpu2cfg_s2m_rdata),
    .peri_rresp                     (cpu2cfg_s2m_rresp),
    .peri_rlast                     (cpu2cfg_s2m_rlast),

    .mem_core_awready               (cpu2ddr_s2m_awready),
    .mem_core_awvalid               (cpu2ddr_m2s_awvalid),
    .mem_core_awid                  (cpu2ddr_m2s_awid),
    .mem_core_awaddr                (cpu2ddr_m2s_awaddr),
    .mem_core_awlen                 (cpu2ddr_m2s_awlen),
    .mem_core_awsize                (cpu2ddr_m2s_awsize),
    .mem_core_awburst               (cpu2ddr_m2s_awburst),
    .mem_core_awlock                (cpu2ddr_m2s_awlock),
    .mem_core_awcache               (cpu2ddr_m2s_awcache),
    .mem_core_awprot                (cpu2ddr_m2s_awprot),
    .mem_core_awqos                 (cpu2ddr_m2s_awqos),
    .mem_core_wready                (cpu2ddr_s2m_wready),
    .mem_core_wvalid                (cpu2ddr_m2s_wvalid),
    .mem_core_wdata                 (cpu2ddr_m2s_wdata),
    .mem_core_wstrb                 (cpu2ddr_m2s_wstrb),
    .mem_core_wlast                 (cpu2ddr_m2s_wlast),
    .mem_core_bready                (cpu2ddr_m2s_bready),
    .mem_core_bvalid                (cpu2ddr_s2m_bvalid),
    .mem_core_bid                   (cpu2ddr_s2m_bid[13:0]),
    .mem_core_bresp                 (cpu2ddr_s2m_bresp),
    .mem_core_arready               (cpu2ddr_s2m_arready),
    .mem_core_arvalid               (cpu2ddr_m2s_arvalid),
    .mem_core_arid                  (cpu2ddr_m2s_arid),
    .mem_core_araddr                (cpu2ddr_m2s_araddr),
    .mem_core_arlen                 (cpu2ddr_m2s_arlen),
    .mem_core_arsize                (cpu2ddr_m2s_arsize),
    .mem_core_arburst               (cpu2ddr_m2s_arburst),
    .mem_core_arlock                (cpu2ddr_m2s_arlock),
    .mem_core_arcache               (cpu2ddr_m2s_arcache),
    .mem_core_arprot                (cpu2ddr_m2s_arprot),
    .mem_core_arqos                 (cpu2ddr_m2s_arqos),
    .mem_core_rready                (cpu2ddr_m2s_rready),
    .mem_core_rvalid                (cpu2ddr_s2m_rvalid),
    .mem_core_rid                   (cpu2ddr_s2m_rid[13:0]),
    .mem_core_rdata                 (cpu2ddr_s2m_rdata),
    .mem_core_rresp                 (cpu2ddr_s2m_rresp),
    .mem_core_rlast                 (cpu2ddr_s2m_rlast),

    .io_extIntrs                    (cpu_int_mix)
);

assign hpm_data_ulvt = 0;
assign hpm_data_lvt = 0;
assign hpm_data_svt = 0;
syscfg U_SYS_CFG(
    .clk                            (axi_bus_clk            ),
    .rst_n                          (axi_bclk_sync_rstn            ),
    .apb_addr                       (syscfg_paddr_mix              ),
    .apb_selx                       (syscfg_psel                   ),
    .apb_enable                     (syscfg_penable                ),
    .apb_write                      (syscfg_pwrite                 ),
    .apb_wdata                      (syscfg_pwdata                 ),
    .syscfg_version                 (32'h20230609                  ),
    .apb_ready                      (syscfg_pready                 ),
    .apb_rdata                      (syscfg_prdata                 ),
    .apb_slverr                     (syscfg_pslverr                )
);
assign hpm_dig_result = 0;

AXI_bridge CFG_AXI_bridge_i
       (.SYS_INTER_CLK          (inter_soc_clk),
`ifdef UVHS
        .UART_ACLK              (uart_sclk),
        .UART_ARESETN           (uart_sclk_sync_rstn),
`endif
        .SYS_INTER_ARESETN      (inter_soc_sync_rstn),
        .ACLK                   (sys_clk_i),
        .ARESETN                (axi_bclk_sync_rstn),

        .S00_AXI_araddr         (cpu2cfg_m2s_araddr),
        .S00_AXI_arburst        (cpu2cfg_m2s_arburst),
        .S00_AXI_arcache        (cpu2cfg_m2s_arcache),
        .S00_AXI_arid           (cpu2cfg_m2s_arid),
        .S00_AXI_arlen          (cpu2cfg_m2s_arlen),
        .S00_AXI_arlock         (cpu2cfg_m2s_arlock),
        .S00_AXI_arprot         (cpu2cfg_m2s_arprot),
        .S00_AXI_arqos          (cpu2cfg_m2s_arqos),
        .S00_AXI_arready        (cpu2cfg_s2m_arready),
        .S00_AXI_arsize         (cpu2cfg_m2s_arsize),
        .S00_AXI_arvalid        (cpu2cfg_m2s_arvalid),
        .S00_AXI_awaddr         (cpu2cfg_m2s_awaddr),
        .S00_AXI_awburst        (cpu2cfg_m2s_awburst),
        .S00_AXI_awcache        (cpu2cfg_m2s_awcache),
        .S00_AXI_awid           (cpu2cfg_m2s_awid),
        .S00_AXI_awlen          (cpu2cfg_m2s_awlen),
        .S00_AXI_awlock         (cpu2cfg_m2s_awlock),
        .S00_AXI_awprot         (cpu2cfg_m2s_awprot),
        .S00_AXI_awqos          (cpu2cfg_m2s_awqos),
        .S00_AXI_awready        (cpu2cfg_s2m_awready),
        .S00_AXI_awsize         (cpu2cfg_m2s_awsize),
        .S00_AXI_awvalid        (cpu2cfg_m2s_awvalid),
        .S00_AXI_bid            (cpu2cfg_s2m_bid),
        .S00_AXI_bready         (cpu2cfg_m2s_bready),
        .S00_AXI_bresp          (cpu2cfg_s2m_bresp),
        .S00_AXI_bvalid         (cpu2cfg_s2m_bvalid),
        .S00_AXI_rdata          (cpu2cfg_s2m_rdata),
        .S00_AXI_rid            (cpu2cfg_s2m_rid),
        .S00_AXI_rlast          (cpu2cfg_s2m_rlast),
        .S00_AXI_rready         (cpu2cfg_m2s_rready),
        .S00_AXI_rresp          (cpu2cfg_s2m_rresp),
        .S00_AXI_rvalid         (cpu2cfg_s2m_rvalid),
        .S00_AXI_wdata          (cpu2cfg_m2s_wdata),
        .S00_AXI_wlast          (cpu2cfg_m2s_wlast),
        .S00_AXI_wready         (cpu2cfg_s2m_wready),
        .S00_AXI_wstrb          (cpu2cfg_m2s_wstrb),
        .S00_AXI_wvalid         (cpu2cfg_m2s_wvalid),

        .SYS_CFG_APB_paddr      (syscfg_paddr_mix),
        .SYS_CFG_APB_penable    (syscfg_penable),
        .SYS_CFG_APB_prdata     (syscfg_prdata),
        .SYS_CFG_APB_pready     (syscfg_pready),
        .SYS_CFG_APB_psel       (syscfg_psel),
        .SYS_CFG_APB_pslverr    (syscfg_pslverr),
        .SYS_CFG_APB_pwdata     (syscfg_pwdata),
        .SYS_CFG_APB_pwrite     (syscfg_pwrite),
        .rom_axi_araddr         (rom_axi_araddr),
        .rom_axi_arburst        (),
        .rom_axi_arcache        (),
        .rom_axi_arlen          (rom_axi_arlen),
        .rom_axi_arlock         (),
        .rom_axi_arprot         (),
        .rom_axi_arqos          (),
        .rom_axi_arready        (rom_axi_arready),
        .rom_axi_arregion       (),
        .rom_axi_arsize         (),
        .rom_axi_arvalid        (rom_axi_arvalid),
        .rom_axi_awaddr         (rom_axi_awaddr),
        .rom_axi_awburst        (),
        .rom_axi_awcache        (),
        .rom_axi_awlen          (rom_axi_awlen),
        .rom_axi_awlock         (),
        .rom_axi_awprot         (),
        .rom_axi_awqos          (),
        .rom_axi_awready        (rom_axi_awready),
        .rom_axi_awregion       (),
        .rom_axi_awsize         (),
        .rom_axi_awvalid        (rom_axi_awvalid),
        .rom_axi_bready         (rom_axi_bready),
        .rom_axi_bresp          (rom_axi_bresp),
        .rom_axi_bvalid         (rom_axi_bvalid),
        .rom_axi_rdata          (rom_axi_rdata),
        .rom_axi_rlast          (rom_axi_rlast),
        .rom_axi_rready         (rom_axi_rready),
        .rom_axi_rresp          (rom_axi_rresp),
        .rom_axi_rvalid         (rom_axi_rvalid),
        .rom_axi_wdata          (rom_axi_wdata),
        .rom_axi_wlast          (rom_axi_wlast),
        .rom_axi_wready         (rom_axi_wready),
        .rom_axi_wstrb          (rom_axi_wstrb),
        .rom_axi_wvalid         (rom_axi_wvalid)
        );

`ifndef NO_DIFF
`ifndef CONFIG_DIFFTEST_HOSTIF_GBUS
  data_bridge data_bridge_i
       (.ACLK                   (axi_bus_clk),
        .ARESETN                (axi_bclk_sync_rstn),
        .M00_AXI_araddr         (data_cpu_bridge_m2s_araddr),
        .M00_AXI_arburst        (data_cpu_bridge_m2s_arburst),
        .M00_AXI_arcache        (data_cpu_bridge_m2s_arcache),
        .M00_AXI_arid           (data_cpu_bridge_m2s_arid),
        .M00_AXI_arlen          (data_cpu_bridge_m2s_arlen),
        .M00_AXI_arlock         (data_cpu_bridge_m2s_arlock),
        .M00_AXI_arprot         (data_cpu_bridge_m2s_arprot),
        .M00_AXI_arqos          (data_cpu_bridge_m2s_arqos),
        .M00_AXI_arready        (data_cpu_bridge_s2m_arready),
        .M00_AXI_arregion       (),
        .M00_AXI_arsize         (data_cpu_bridge_m2s_arsize),
        .M00_AXI_arvalid        (data_cpu_bridge_m2s_arvalid),
        .M00_AXI_awaddr         (data_cpu_bridge_m2s_awaddr),
        .M00_AXI_awburst        (data_cpu_bridge_m2s_awburst),
        .M00_AXI_awcache        (data_cpu_bridge_m2s_awcache),
        .M00_AXI_awid           (data_cpu_bridge_m2s_awid),
        .M00_AXI_awlen          (data_cpu_bridge_m2s_awlen),
        .M00_AXI_awlock         (data_cpu_bridge_m2s_awlock),
        .M00_AXI_awprot         (data_cpu_bridge_m2s_awprot),
        .M00_AXI_awqos          (data_cpu_bridge_m2s_awqos),
        .M00_AXI_awready        (data_cpu_bridge_s2m_awready),
        .M00_AXI_awregion       (),
        .M00_AXI_awsize         (data_cpu_bridge_m2s_awsize),
        .M00_AXI_awvalid        (data_cpu_bridge_m2s_awvalid),
        .M00_AXI_bid            (data_cpu_bridge_s2m_bid),
        .M00_AXI_bready         (data_cpu_bridge_m2s_bready),
        .M00_AXI_bresp          (data_cpu_bridge_s2m_bresp),
        .M00_AXI_bvalid         (data_cpu_bridge_s2m_bvalid),
        .M00_AXI_rdata          (data_cpu_bridge_s2m_rdata),
        .M00_AXI_rid            (data_cpu_bridge_s2m_rid),
        .M00_AXI_rlast          (data_cpu_bridge_s2m_rlast),
        .M00_AXI_rready         (data_cpu_bridge_m2s_rready),
        .M00_AXI_rresp          (data_cpu_bridge_s2m_rresp),
        .M00_AXI_rvalid         (data_cpu_bridge_s2m_rvalid),
        .M00_AXI_wdata          (data_cpu_bridge_m2s_wdata),
        .M00_AXI_wlast          (data_cpu_bridge_m2s_wlast),
        .M00_AXI_wready         (data_cpu_bridge_s2m_wready),
        .M00_AXI_wstrb          (data_cpu_bridge_m2s_wstrb),
        .M00_AXI_wvalid         (data_cpu_bridge_m2s_wvalid),

      //   .S00_AXI_araddr         (pcie_bridge_m_araddr),
      //   .S00_AXI_arburst        (pcie_bridge_m_arburst),
      //   .S00_AXI_arcache        (pcie_bridge_m_arcache),
      //   .S00_AXI_arid           (pcie_bridge_m_arid),
      //   .S00_AXI_arlen          (pcie_bridge_m_arlen),
      //   .S00_AXI_arlock         (pcie_bridge_m_arlock),
      //   .S00_AXI_arprot         (pcie_bridge_m_arprot),
      //   .S00_AXI_arqos          (pcie_bridge_m_arqos),
      //   .S00_AXI_arready        (pcie_bridge_m_arready),
      //   .S00_AXI_arregion       (pcie_bridge_m_arregion),
      //   .S00_AXI_arsize         (pcie_bridge_m_arsize),
      //   .S00_AXI_arvalid        (pcie_bridge_m_arvalid),
      //   .S00_AXI_awaddr         (pcie_bridge_m_awaddr),
      //   .S00_AXI_awburst        (pcie_bridge_m_awburst),
      //   .S00_AXI_awcache        (pcie_bridge_m_awcache),
      //   .S00_AXI_awid           (pcie_bridge_m_awid),
      //   .S00_AXI_awlen          (pcie_bridge_m_awlen),
      //   .S00_AXI_awlock         (pcie_bridge_m_awlock),
      //   .S00_AXI_awprot         (pcie_bridge_m_awprot),
      //   .S00_AXI_awqos          (pcie_bridge_m_awqos),
      //   .S00_AXI_awready        (pcie_bridge_m_awready),
      //   .S00_AXI_awregion       (pcie_bridge_m_awregion),
      //   .S00_AXI_awsize         (pcie_bridge_m_awsize),
      //   .S00_AXI_awvalid        (pcie_bridge_m_awvalid),
      //   .S00_AXI_bid            (pcie_bridge_m_bid_mix),
      //   .S00_AXI_bready         (pcie_bridge_m_bready),
      //   .S00_AXI_bresp          (pcie_bridge_m_bresp),
      //   .S00_AXI_bvalid         (pcie_bridge_m_bvalid),
      //   .S00_AXI_rdata          (pcie_bridge_m_rdata),
      //   .S00_AXI_rid            (pcie_bridge_m_rid_mix),
      //   .S00_AXI_rlast          (pcie_bridge_m_rlast),
      //   .S00_AXI_rready         (pcie_bridge_m_rready),
      //   .S00_AXI_rresp          (pcie_bridge_m_rresp),
      //   .S00_AXI_rvalid         (pcie_bridge_m_rvalid),
      //   .S00_AXI_wdata          (pcie_bridge_m_wdata),
      //   .S00_AXI_wlast          (pcie_bridge_m_wlast),
      //   .S00_AXI_wready         (pcie_bridge_m_wready),
      //   .S00_AXI_wstrb          (pcie_bridge_m_wstrb),
      //   .S00_AXI_wvalid         (pcie_bridge_m_wvalid),

        .S01_AXI_araddr         (gmac_m_araddr),
        .S01_AXI_arburst        (gmac_m_arburst),
        .S01_AXI_arcache        (gmac_m_arcache),
        .S01_AXI_arid           (gmac_m_arid),
        .S01_AXI_arlen          (gmac_m_arlen),
        .S01_AXI_arlock         (gmac_m_arlock),
        .S01_AXI_arprot         (gmac_m_arprot),
        .S01_AXI_arqos          (),
        .S01_AXI_arready        (gmac_m_arready),
        .S01_AXI_arregion       (),
        .S01_AXI_arsize         (gmac_m_arsize),
        .S01_AXI_arvalid        (gmac_m_arvalid),
        .S01_AXI_awaddr         (gmac_m_awaddr),
        .S01_AXI_awburst        (gmac_m_awburst),
        .S01_AXI_awcache        (gmac_m_awcache),
        .S01_AXI_awid           (gmac_m_awid),
        .S01_AXI_awlen          (gmac_m_awlen),
        .S01_AXI_awlock         (gmac_m_awlock),
        .S01_AXI_awprot         (gmac_m_awprot),
        .S01_AXI_awqos          (),
        .S01_AXI_awready        (gmac_m_awready),
        .S01_AXI_awregion       (),
        .S01_AXI_awsize         (gmac_m_awsize),
        .S01_AXI_awvalid        (gmac_m_awvalid),
        .S01_AXI_bid            (gmac_m_bid),
        .S01_AXI_bready         (gmac_m_bready),
        .S01_AXI_bresp          (gmac_m_bresp),
        .S01_AXI_bvalid         (gmac_m_bvalid),
        .S01_AXI_rdata          (gmac_m_rdata),
        .S01_AXI_rid            (gmac_m_rid),
        .S01_AXI_rlast          (gmac_m_rlast),
        .S01_AXI_rready         (gmac_m_rready),
        .S01_AXI_rresp          (gmac_m_rresp),
        .S01_AXI_rvalid         (gmac_m_rvalid),
        .S01_AXI_wdata          (gmac_m_wdata),
        .S01_AXI_wlast          (gmac_m_wlast),
        .S01_AXI_wready         (gmac_m_wready),
        .S01_AXI_wstrb          (gmac_m_wstrb),
        .S01_AXI_wvalid         (gmac_m_wvalid));
`endif
`endif


endmodule
