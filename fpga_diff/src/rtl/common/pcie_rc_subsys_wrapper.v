`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/05/2022 07:47:03 AM
// Design Name: 
// Module Name: pcie_rc_subsys_wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pcie_rc_subsys_wrapper # ( 
  parameter          PCIE_EXT_CLK                 = "FALSE",
  parameter          C_DATA_WIDTH                 = 128,            // RX/TX interface data width
  parameter          EXT_PIPE_SIM                 = "FALSE",                                // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
  parameter          PL_LINK_CAP_MAX_LINK_SPEED   = 2,  // 1- GEN1, 2 - GEN2, 4 - GEN3, 8 - GEN4
  parameter [4:0]    PL_LINK_CAP_MAX_LINK_WIDTH   = 4,  // 1- X1, 2 - X2, 4 - X4, 8 - X8, 16 - X16
  parameter          PL_DISABLE_EI_INFER_IN_L0    = "TRUE",
  parameter          ROM_FILE                     = "cgator_cfg_rom.data",
  parameter          ROM_SIZE                     = 40,
  parameter [15:0]   REQUESTER_ID                 = 16'h0011,
  //  USER_CLK[1/2]_FREQ  : 0 = Disable user clock
  //                      : 1 =  31.25 MHz
  //                      : 2 =  62.50 MHz (default)
  //                      : 3 = 125.00 MHz
  //                      : 4 = 250.00 MHz
  //                      : 5 = 500.00 MHz
  parameter PL_DISABLE_UPCONFIG_CAPABLE           = "FALSE",
  parameter  integer USER_CLK2_FREQ               = 3,
//  parameter USER_CLK2_DIV2                      = "FALSE",         // "FALSE" => user_clk2 = user_clk
  parameter        REF_CLK_FREQ                   = 0,  // 0 - 100 MHz, 1 - 125 MHz,  2 - 250 MHz
  parameter        AXISTEN_IF_RQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_CQ_ALIGNMENT_MODE   = "FALSE",
  parameter        AXISTEN_IF_RC_ALIGNMENT_MODE   = "FALSE",
  parameter        AXI4_CQ_TUSER_WIDTH            = 88,
  parameter        AXI4_CC_TUSER_WIDTH            = 33,
  parameter        AXI4_RQ_TUSER_WIDTH            = 62,
  parameter        AXI4_RC_TUSER_WIDTH            = 75,
  parameter        AXISTEN_IF_ENABLE_CLIENT_TAG   = "TRUE",
  parameter        AXISTEN_IF_RQ_PARITY_CHECK     = "FALSE",
  parameter        AXISTEN_IF_CC_PARITY_CHECK     = "FALSE",
  parameter        AXISTEN_IF_MC_RX_STRADDLE      = "FALSE",
  parameter        AXISTEN_IF_ENABLE_RX_MSG_INTFC = "FALSE",
  parameter [17:0] AXISTEN_IF_ENABLE_MSG_ROUTE    = 18'h2FFFF,
  parameter        KEEP_WIDTH                     = C_DATA_WIDTH / 32,
  parameter        CCIX_ENABLE                    = "FALSE",
  parameter        AXIS_CCIX_RX_TDATA_WIDTH       = 256,
  parameter        AXIS_CCIX_TX_TDATA_WIDTH       = 256,
  parameter        AXIS_CCIX_RX_TUSER_WIDTH       = 47,
  parameter        AXIS_CCIX_TX_TUSER_WIDTH       = 47
  ) (

//   system interface only for PCIe
     input                                           sys_clk,
     input                                           sys_clk_gt,
     input                                           sys_rst_n,
     output  reg                                     pcie_interrupt,
//   system interface with main clk : 50MHz
     input                                           main_clk,
     input                                           main_rst_n,
//   PCI Express (pci_exp) Interface   
     output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txp,
     output  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_txn,
     input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
     input   [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,
//   AXI Master Interface
     output       [14:0]                             pcie_bridge_m_awid            , 
     output       [39:0]                             pcie_bridge_m_awaddr          , 
     output       [7:0]                              pcie_bridge_m_awlen           , 
     output       [2:0]                              pcie_bridge_m_awsize          , 
     output       [1:0]                              pcie_bridge_m_awburst         , 
     output                                          pcie_bridge_m_awlock          , 
     output       [3:0]                              pcie_bridge_m_awcache         , 
     output       [2:0]                              pcie_bridge_m_awprot          , 
     output                                          pcie_bridge_m_awvalid         , 
     input                                           pcie_bridge_m_awready         , 
     output       [3:0]                              pcie_bridge_m_awqos           , 
     output       [255:0]                            pcie_bridge_m_wdata           , 
     output       [31:0]                             pcie_bridge_m_wstrb           , 
     output                                          pcie_bridge_m_wlast           , 
     output                                          pcie_bridge_m_wvalid          , 
     input                                           pcie_bridge_m_wready          , 
     output                                          pcie_bridge_m_bready          , 
     input        [14:0]                             pcie_bridge_m_bid             , 
     input        [1:0]                              pcie_bridge_m_bresp           , 
     input                                           pcie_bridge_m_bvalid          , 
     output       [14:0]                             pcie_bridge_m_arid            , 
     output       [39:0]                             pcie_bridge_m_araddr          , 
     output       [7:0]                              pcie_bridge_m_arlen           , 
     output       [2:0]                              pcie_bridge_m_arsize          , 
     output       [1:0]                              pcie_bridge_m_arburst         , 
     output                                          pcie_bridge_m_arlock          , 
     output       [3:0]                              pcie_bridge_m_arcache         , 
     output       [2:0]                              pcie_bridge_m_arprot          , 
     output                                          pcie_bridge_m_arvalid         , 
     output       [3:0]                              pcie_bridge_m_arqos           ,     
     input                                           pcie_bridge_m_arready         , 
     output                                          pcie_bridge_m_rready          , 
     input        [6:0]                              pcie_bridge_m_rid             , 
     input        [255:0]                            pcie_bridge_m_rdata           , 
     input        [1:0]                              pcie_bridge_m_rresp           , 
     input                                           pcie_bridge_m_rlast           , 
     input                                           pcie_bridge_m_rvalid          , 
//   AXI Slave Interface
     input          [14:0]                         cfg_pcie_s_arid        , 
     input          [14:0]                         cfg_pcie_s_awid        , 
     input          [39:0]                         cfg_pcie_s_araddr          , 
     input          [1:0]                          cfg_pcie_s_arburst         , 
     input          [3:0]                          cfg_pcie_s_arcache         , 
     input          [7:0]                          cfg_pcie_s_arlen           , 
     input          [0:0]                          cfg_pcie_s_arlock          , 
     input          [2:0]                          cfg_pcie_s_arprot          , 
     input          [3:0]                          cfg_pcie_s_arqos           , 
     input          [2:0]                          cfg_pcie_s_arsize          , 
     input                                         cfg_pcie_s_arvalid         , 
     input          [39:0]                         cfg_pcie_s_awaddr          , 
     input          [1:0]                          cfg_pcie_s_awburst         , 
     input          [3:0]                          cfg_pcie_s_awcache         , 
     input          [7:0]                          cfg_pcie_s_awlen           , 
     input          [0:0]                          cfg_pcie_s_awlock          , 
     input          [2:0]                          cfg_pcie_s_awprot          , 
     input          [3:0]                          cfg_pcie_s_awqos           , 
     input          [2:0]                          cfg_pcie_s_awsize          , 
     input                                         cfg_pcie_s_awvalid         , 
     input                                         cfg_pcie_s_bready          , 
     input                                         cfg_pcie_s_rready          , 
     input          [255:0]                        cfg_pcie_s_wdata           , 
     input                                         cfg_pcie_s_wlast           , 
     input          [31:0]                         cfg_pcie_s_wstrb           , 
     input                                         cfg_pcie_s_wvalid          , 
     output         [14:0]                         cfg_pcie_s_rid             , 
     output         [14:0]                         cfg_pcie_s_bid             , 
     output                                        cfg_pcie_s_arready         , 
     output                                        cfg_pcie_s_awready         , 
     output         [1:0]                          cfg_pcie_s_bresp           , 
     output                                        cfg_pcie_s_bvalid          , 
     output         [255:0]                        cfg_pcie_s_rdata           , 
     output                                        cfg_pcie_s_rlast           , 
     output         [1:0]                          cfg_pcie_s_rresp           , 
     output                                        cfg_pcie_s_rvalid          , 
     output                                        cfg_pcie_s_wready          , 
     
//   Debug signals list
    output                                           cfg_phy_link_down,
    output                            [1:0]          cfg_phy_link_status,
    output                            [2:0]          cfg_negotiated_width,
    output                            [1:0]          cfg_current_speed,
    output                            [1:0]          cfg_max_payload,
    output                            [2:0]          cfg_max_read_req,
    output                           [15:0]          cfg_function_status,     
    output                            [4:0]          cfg_local_error_out,
    output                                           cfg_pl_status_change,
    output                                           user_lnk_up,        
    output                                           phy_rdy_out        

     );
     
  localparam        TCQ = 1;
  localparam integer USER_CLK_FREQ         = ((PL_LINK_CAP_MAX_LINK_SPEED == 'h4) ? 5 : 4);     
  //----------------------------------------------------------------------------------------------------------------//
  //    System(SYS) Interface                                                                                       //
  //----------------------------------------------------------------------------------------------------------------//

//  wire    sys_clk;            // 100MHz
//  wire    sys_clk_gt;         // 100MHz
//  wire    sys_rst_n_c;

  wire    user_clk_out;       // 125MHz
  wire    user_reset_out;  

//  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));

//  IBUFDS_GTE4 refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));



  wire [15:0]  cfg_vend_id        = 16'h10EE;   
  wire [15:0]  cfg_dev_id         = 16'h9124;   
  wire [15:0]  cfg_subsys_id      = 16'h0007;                                
  wire [7:0]   cfg_rev_id         = 8'h00; 
  wire [15:0]  cfg_subsys_vend_id = 16'h10EE;
  
  localparam X8_GEN3 = ((PL_LINK_CAP_MAX_LINK_WIDTH == 8) && (PL_LINK_CAP_MAX_LINK_SPEED == 4)) ? 1'b1 : 1'b0;

  //--------------------------------------------------------------------------------------------------------------------//
  // Connections between Root Port and Configurator
  //--------------------------------------------------------------------------------------------------------------------//

  wire                                [3:0]     axis_rq_tready;
  wire                   [C_DATA_WIDTH-1:0]     axis_rq_tdata;
  wire                     [KEEP_WIDTH-1:0]     axis_rq_tkeep;
  wire            [AXI4_RQ_TUSER_WIDTH-1:0]     axis_rq_tuser;
  wire                                          axis_rq_tlast;
  wire                                          axis_rq_tvalid;

  wire                   [C_DATA_WIDTH-1:0]     rport_m_axis_rc_tdata;
  wire                     [KEEP_WIDTH-1:0]     rport_m_axis_rc_tkeep;
  wire                                          rport_m_axis_rc_tlast;
  wire                                          rport_m_axis_rc_tvalid;
  reg                                           rport_m_axis_rc_tready = 1'b1;
  wire            [AXI4_RC_TUSER_WIDTH-1:0]     rport_m_axis_rc_tuser;
  
  wire                   [C_DATA_WIDTH-1:0]     axis_cq_tdata;
  wire            [AXI4_CQ_TUSER_WIDTH-1:0]     axis_cq_tuser;
  wire                                          axis_cq_tlast;
  wire                     [KEEP_WIDTH-1:0]     axis_cq_tkeep;
  wire                                          axis_cq_tvalid;
  wire                                          axis_cq_tready;

  reg                    [C_DATA_WIDTH-1:0]     s_axis_cc_tdata = 0;
  reg             [AXI4_CC_TUSER_WIDTH-1:0]     s_axis_cc_tuser = 0;
  reg                                           s_axis_cc_tlast = 0;
  reg                      [KEEP_WIDTH-1:0]     s_axis_cc_tkeep = 0;
  reg                                           s_axis_cc_tvalid = 0;
  wire                                [3:0]     s_axis_cc_tready;

   
// Interrupt related 
(*mark_debug = "true"*)   wire        [4:0]     cfg_msg_received_type;
(*mark_debug = "true"*)   wire                  cfg_msg_received; 

// Core Top Level Wrapper
 pcie4c_uscale_plus_0  pcie4c_uscale_plus_0_i (
    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//
    //---------------------------------------------------------------------------------------//
    //  PCI Express (pci_exp) Interface                                                      //
    //---------------------------------------------------------------------------------------//

    // Tx
    .pci_exp_txn                                    ( pci_exp_txn ),
    .pci_exp_txp                                    ( pci_exp_txp ),

    // Rx
    .pci_exp_rxn                                    ( pci_exp_rxn ),
    .pci_exp_rxp                                    ( pci_exp_rxp ),



   //---------------------------------------------------------------------------------------//
    //  AXI Interface                                                                        //
    //---------------------------------------------------------------------------------------//

    .user_clk                                       ( user_clk_out ),
    .user_reset                                     ( user_reset_out ),
    .user_lnk_up                                    ( user_lnk_up ),
    .phy_rdy_out                                    ( phy_rdy_out ),

    .s_axis_rq_tlast                                ( axis_rq_tlast ),
    .s_axis_rq_tdata                                ( axis_rq_tdata ),
    .s_axis_rq_tuser                                ( 62'h0 /*axis_rq_tuser*/ ),
    .s_axis_rq_tkeep                                ( axis_rq_tkeep ),
    .s_axis_rq_tready                               ( axis_rq_tready ),
    .s_axis_rq_tvalid                               ( axis_rq_tvalid ),

    .m_axis_rc_tdata                                ( rport_m_axis_rc_tdata ),
    .m_axis_rc_tuser                                ( rport_m_axis_rc_tuser ),
    .m_axis_rc_tlast                                ( rport_m_axis_rc_tlast ),
    .m_axis_rc_tkeep                                ( rport_m_axis_rc_tkeep ),
    .m_axis_rc_tvalid                               ( rport_m_axis_rc_tvalid ),
    .m_axis_rc_tready                               ( rport_m_axis_rc_tready ),


    .m_axis_cq_tdata                                ( axis_cq_tdata ),
    .m_axis_cq_tuser                                ( axis_cq_tuser ),
    .m_axis_cq_tlast                                ( axis_cq_tlast ),
    .m_axis_cq_tkeep                                ( axis_cq_tkeep ),
    .m_axis_cq_tvalid                               ( axis_cq_tvalid ),
    .m_axis_cq_tready                               ( axis_cq_tready ),

    .s_axis_cc_tdata                                ( s_axis_cc_tdata ),
    .s_axis_cc_tuser                                ( s_axis_cc_tuser ),
    .s_axis_cc_tlast                                ( s_axis_cc_tlast ),
    .s_axis_cc_tkeep                                ( s_axis_cc_tkeep ),
    .s_axis_cc_tvalid                               ( s_axis_cc_tvalid ),
    .s_axis_cc_tready                               ( s_axis_cc_tready ),


    //---------------------------------------------------------------------------------------//
    //  Configuration (CFG) Interface                                                        //
    //---------------------------------------------------------------------------------------//
    .pcie_tfc_nph_av                                ( /*pcie_tfc_nph_av */),
    .pcie_tfc_npd_av                                ( /*pcie_tfc_npd_av */),

    .pcie_rq_seq_num0                               ( /*pcie_rq_seq_num0    */  ) ,
    .pcie_rq_seq_num_vld0                           ( /*pcie_rq_seq_num_vld0*/  ) ,
    .pcie_rq_seq_num1                               ( /*pcie_rq_seq_num1    */  ) ,
    .pcie_rq_seq_num_vld1                           ( /*pcie_rq_seq_num_vld1*/  ) ,
    .pcie_rq_tag0                                   ( /*pcie_rq_tag0        */  ) ,
    .pcie_rq_tag1                                   ( /*pcie_rq_tag1        */  ) ,
    .pcie_rq_tag_av                                 ( /*pcie_rq_tag_av      */  ) ,
    .pcie_rq_tag_vld0                               ( /*pcie_rq_tag_vld0    */  ) ,
    .pcie_rq_tag_vld1                               ( /*pcie_rq_tag_vld1    */  ) ,
    .pcie_cq_np_req                                 ( 1'b1 /*pcie_cq_np_req*/ ),
    .pcie_cq_np_req_count                           ( /*pcie_cq_np_req_count*/ ),
    .cfg_phy_link_down                              ( cfg_phy_link_down ),
    .cfg_phy_link_status                            ( cfg_phy_link_status),
    .cfg_negotiated_width                           ( cfg_negotiated_width ),
    .cfg_current_speed                              ( cfg_current_speed ),
    .cfg_max_payload                                ( cfg_max_payload ),
    .cfg_max_read_req                               ( cfg_max_read_req ),
    .cfg_function_status                            ( cfg_function_status ),
    .cfg_function_power_state                       ( /*cfg_function_power_state*/ ),
    .cfg_vf_status                                  ( /*cfg_vf_status*/ ),
    .cfg_vf_power_state                             ( /*cfg_vf_power_state */),
    .cfg_link_power_state                           ( /*cfg_link_power_state*/ ),
    // Error Reporting Interface
    .cfg_err_cor_out                                ( /*cfg_err_cor_out*/ ),
    .cfg_err_nonfatal_out                           ( /*cfg_err_nonfatal_out*/ ),
    .cfg_err_fatal_out                              ( /*cfg_err_fatal_out*/ ),
    .cfg_local_error_out                            ( /*cfg_local_error_out */),
    .cfg_local_error_valid                          ( /*cfg_local_error_valid*/ ),
    .cfg_ltssm_state                                ( /*cfg_ltssm_state            */ ),
    .cfg_rx_pm_state                                ( /*cfg_rx_pm_state            */ ),
    .cfg_tx_pm_state                                ( /*cfg_tx_pm_state            */ ),
    .cfg_rcb_status                                 ( /*cfg_rcb_status             */ ),
    .cfg_obff_enable                                ( /*cfg_obff_enable            */ ),
    .cfg_pl_status_change                           ( /*cfg_pl_status_change       */ ),
    .cfg_tph_requester_enable                       ( /*cfg_tph_requester_enable   */ ),
    .cfg_tph_st_mode                                ( /*cfg_tph_st_mode            */ ),
    .cfg_vf_tph_requester_enable                    ( /*cfg_vf_tph_requester_enable*/ ),
    .cfg_vf_tph_st_mode                             ( /*cfg_vf_tph_st_mode         */ ),

    // Management Interface
    .cfg_mgmt_addr                                  ( 0 /* cfg_mgmt_addr */),
    .cfg_mgmt_write                                 ( 0 /* cfg_mgmt_write */),
    .cfg_mgmt_write_data                            ( 0 /* cfg_mgmt_write_data */),
    .cfg_mgmt_byte_enable                           ( 0 /* cfg_mgmt_byte_enable */),
    .cfg_mgmt_read                                  ( 0 /* cfg_mgmt_read */),
    .cfg_mgmt_read_data                             ( /*cfg_mgmt_read_data*/ ),
    .cfg_mgmt_read_write_done                       ( /*cfg_mgmt_read_write_done*/ ),
    .cfg_mgmt_debug_access                          ( 1'b0 /*cfg_mgmt_debug_access */),
    .cfg_mgmt_function_number                       ( 8'b0 /*cfg_mgmt_function_number */),

    .cfg_pm_aspm_l1_entry_reject                    ( 1'b0 /*cfg_pm_aspm_l1_entry_reject*/),
    .cfg_pm_aspm_tx_l0s_entry_disable               ( 1'b1 /*cfg_pm_aspm_tx_l0s_entry_disable*/),

    .cfg_msg_received                               ( cfg_msg_received      ),
    .cfg_msg_received_data                          ( /*cfg_msg_received_data */),
    .cfg_msg_received_type                          ( cfg_msg_received_type ),

    .cfg_msg_transmit                               ( 0 /*cfg_msg_transmit*/ ),
    .cfg_msg_transmit_type                          ( 0 /*cfg_msg_transmit_type*/ ),
    .cfg_msg_transmit_data                          ( 0 /*cfg_msg_transmit_data*/ ),
    .cfg_msg_transmit_done                          ( /*cfg_msg_transmit_done*/ ),

    .cfg_fc_ph                                      ( /*cfg_fc_ph  */ ),
    .cfg_fc_pd                                      ( /*cfg_fc_pd  */ ),
    .cfg_fc_nph                                     ( /*cfg_fc_nph */ ),
    .cfg_fc_npd                                     ( /*cfg_fc_npd */ ),
    .cfg_fc_cplh                                    ( /*cfg_fc_cplh*/ ),
    .cfg_fc_cpld                                    ( /*cfg_fc_cpld*/ ),
    .cfg_fc_sel                                     ( 0 /*cfg_fc_sel*/ ),
    //-------------------------------------------------------------------------------//
    // EP and RP                                                                     //
    //-------------------------------------------------------------------------------//
    .cfg_bus_number                                 ( /*cfg_bus_number*/ ), 
    .cfg_dsn                                        ( 64'h78EE32BAD28F906B /*cfg_dsn */),
    .cfg_power_state_change_ack                     ( 0 /*cfg_power_state_change_ack */),
    .cfg_power_state_change_interrupt               ( /*cfg_power_state_change_interrupt*/ ),
    .cfg_err_cor_in                                 ( 0 /*cfg_err_cor_in*/ ),
    .cfg_err_uncor_in                               ( 0 /*cfg_err_uncor_in*/ ),

    .cfg_flr_in_process                             ( /*cfg_flr_in_process */),
    .cfg_flr_done                                   ( 0 /* cfg_flr_done */),
    .cfg_vf_flr_in_process                          ( /*cfg_vf_flr_in_process */),
    .cfg_vf_flr_done                                ( 0 /* cfg_vf_flr_done */ ),
    .cfg_link_training_enable                       ( 1'b1 /* cfg_link_training_enable */ ),
  // EP only
    .cfg_hot_reset_out                              ( /*cfg_hot_reset_out*/ ),
    .cfg_config_space_enable                        ( 1'b1 /*cfg_config_space_enable*/ ),
    .cfg_req_pm_transition_l23_ready                ( 0 /*cfg_req_pm_transition_l23_ready*/ ),

  // RP only
    .cfg_hot_reset_in                               ( 0 /*cfg_hot_reset_in*/ ),

    .cfg_ds_bus_number                              ( 8'h45 /*cfg_ds_bus_number*/ ),
    .cfg_ds_device_number                           ( 4'b0001 /*cfg_ds_device_number*/ ),
    .cfg_ds_port_number                             ( 8'h9F /*cfg_ds_port_number*/ ),
    .cfg_vf_flr_func_num                            ( 0 /*cfg_vf_flr_func_num*/),

    //-------------------------------------------------------------------------------//
    // EP Only                                                                       //
    //-------------------------------------------------------------------------------//

    // Interrupt Interface Signals
    .cfg_interrupt_int                              ( 0 /*cfg_interrupt_int */),
    .cfg_interrupt_pending                          ( 0 /*{2'b0,cfg_interrupt_pending} */),
    .cfg_interrupt_sent                             ( /*cfg_interrupt_sent */),
    .cfg_interrupt_msi_enable                       ( /*cfg_interrupt_msi_enable*/ ),
    .cfg_interrupt_msi_mmenable                     ( /*cfg_interrupt_msi_mmenable*/ ),
    .cfg_interrupt_msi_mask_update                  ( /*cfg_interrupt_msi_mask_update*/ ),
    .cfg_interrupt_msi_data                         ( /*cfg_interrupt_msi_data */),
    .cfg_interrupt_msi_select                       ( 0 /*cfg_interrupt_msi_select */),
    .cfg_interrupt_msi_int                          ( 0 /*cfg_interrupt_msi_int */),
    .cfg_interrupt_msi_pending_status               ( 0 /*cfg_interrupt_msi_pending_status [31:0]*/),
    .cfg_interrupt_msi_sent                         ( /*cfg_interrupt_msi_sent  */),
    .cfg_interrupt_msi_fail                         ( /*cfg_interrupt_msi_fail  */),
    .cfg_interrupt_msi_attr                         ( 0 /*cfg_interrupt_msi_attr        */),
    .cfg_interrupt_msi_tph_present                  ( 0 /*cfg_interrupt_msi_tph_present */),
    .cfg_interrupt_msi_tph_type                     ( 0 /*cfg_interrupt_msi_tph_type    */),
    .cfg_interrupt_msi_tph_st_tag                   ( 0 /*cfg_interrupt_msi_tph_st_tag  */),
    .cfg_interrupt_msi_function_number              (8'b0 ),
    .cfg_interrupt_msi_pending_status_function_num  (2'b0),
    .cfg_interrupt_msi_pending_status_data_enable   (1'b0),

    //--------------------------------------------------------------------------------------//
    //  System(SYS) Interface                                                               //
    //--------------------------------------------------------------------------------------//

    .sys_clk                                        ( sys_clk ),
    .sys_clk_gt                                     ( sys_clk_gt ),
    .sys_reset                                      ( sys_rst_n  )


  );


  always@(posedge user_clk_out) begin
     if (user_reset_out)
	pcie_interrupt <= 1'b0;
     else if ((cfg_msg_received_type == 5'b00011) && cfg_msg_received)
	pcie_interrupt <= 1'b1;
     else if ((cfg_msg_received_type == 5'b00100) && cfg_msg_received)
	pcie_interrupt <= 1'b0;
     else
	pcie_interrupt <= pcie_interrupt;
  end 


  pcie_axi_axis_bridge pcie_axi_axis_bridge_i
       (.cfg_pcie_s_araddr(cfg_pcie_s_araddr),
        .cfg_pcie_s_arburst(cfg_pcie_s_arburst),
        .cfg_pcie_s_arcache(cfg_pcie_s_arcache),
        .cfg_pcie_s_arid(cfg_pcie_s_arid),
        .cfg_pcie_s_arlen(cfg_pcie_s_arlen),
        .cfg_pcie_s_arlock(cfg_pcie_s_arlock),
        .cfg_pcie_s_arprot(cfg_pcie_s_arprot),
        .cfg_pcie_s_arqos(cfg_pcie_s_arqos),
        .cfg_pcie_s_arready(cfg_pcie_s_arready),
        .cfg_pcie_s_arsize(cfg_pcie_s_arsize),
        .cfg_pcie_s_arvalid(cfg_pcie_s_arvalid),
        .cfg_pcie_s_awaddr(cfg_pcie_s_awaddr),
        .cfg_pcie_s_awburst(cfg_pcie_s_awburst),
        .cfg_pcie_s_awcache(cfg_pcie_s_awcache),
        .cfg_pcie_s_awid(cfg_pcie_s_awid),
        .cfg_pcie_s_awlen(cfg_pcie_s_awlen),
        .cfg_pcie_s_awlock(cfg_pcie_s_awlock),
        .cfg_pcie_s_awprot(cfg_pcie_s_awprot),
        .cfg_pcie_s_awqos(cfg_pcie_s_awqos),
        .cfg_pcie_s_awready(cfg_pcie_s_awready),
        .cfg_pcie_s_awsize(cfg_pcie_s_awsize),
        .cfg_pcie_s_awvalid(cfg_pcie_s_awvalid),
        .cfg_pcie_s_bid(cfg_pcie_s_bid),
        .cfg_pcie_s_bready(cfg_pcie_s_bready),
        .cfg_pcie_s_bresp(cfg_pcie_s_bresp),
        .cfg_pcie_s_bvalid(cfg_pcie_s_bvalid),
        .cfg_pcie_s_rdata(cfg_pcie_s_rdata),
        .cfg_pcie_s_rid(cfg_pcie_s_rid),
        .cfg_pcie_s_rlast(cfg_pcie_s_rlast),
        .cfg_pcie_s_rready(cfg_pcie_s_rready),
        .cfg_pcie_s_rresp(cfg_pcie_s_rresp),
        .cfg_pcie_s_rvalid(cfg_pcie_s_rvalid),
        .cfg_pcie_s_wdata(cfg_pcie_s_wdata),
        .cfg_pcie_s_wlast(cfg_pcie_s_wlast),
        .cfg_pcie_s_wready(cfg_pcie_s_wready),
        .cfg_pcie_s_wstrb(cfg_pcie_s_wstrb),
        .cfg_pcie_s_wvalid(cfg_pcie_s_wvalid),
        .m_axis_rq_tdata  (axis_rq_tdata),
        .m_axis_rq_tid    (axis_rq_tid),
        .m_axis_rq_tkeep  (axis_rq_tkeep),
        .m_axis_rq_tlast  (axis_rq_tlast),
        .m_axis_rq_tready (axis_rq_tready[0]),
        .m_axis_rq_tvalid (axis_rq_tvalid),
        .main_clk(main_clk),
        .main_rst_n(main_rst_n),
        .pcie_bridge_m_araddr(pcie_bridge_m_araddr),
        .pcie_bridge_m_arburst(pcie_bridge_m_arburst),
        .pcie_bridge_m_arcache(pcie_bridge_m_arcache),
        .pcie_bridge_m_arid(pcie_bridge_m_arid),
        .pcie_bridge_m_arlen(pcie_bridge_m_arlen),
        .pcie_bridge_m_arlock(pcie_bridge_m_arlock),
        .pcie_bridge_m_arprot(pcie_bridge_m_arprot),
        .pcie_bridge_m_arqos(pcie_bridge_m_arqos),
        .pcie_bridge_m_arready(pcie_bridge_m_arready),
        .pcie_bridge_m_arsize(pcie_bridge_m_arsize),
        .pcie_bridge_m_arvalid(pcie_bridge_m_arvalid),
        .pcie_bridge_m_awaddr(pcie_bridge_m_awaddr),
        .pcie_bridge_m_awburst(pcie_bridge_m_awburst),
        .pcie_bridge_m_awcache(pcie_bridge_m_awcache),
        .pcie_bridge_m_awid(pcie_bridge_m_awid),
        .pcie_bridge_m_awlen(pcie_bridge_m_awlen),
        .pcie_bridge_m_awlock(pcie_bridge_m_awlock),
        .pcie_bridge_m_awprot(pcie_bridge_m_awprot),
        .pcie_bridge_m_awqos(pcie_bridge_m_awqos),
        .pcie_bridge_m_awready(pcie_bridge_m_awready),
        .pcie_bridge_m_awsize(pcie_bridge_m_awsize),
        .pcie_bridge_m_awvalid(pcie_bridge_m_awvalid),
        .pcie_bridge_m_bid(pcie_bridge_m_bid),
        .pcie_bridge_m_bready(pcie_bridge_m_bready),
        .pcie_bridge_m_bresp(pcie_bridge_m_bresp),
        .pcie_bridge_m_bvalid(pcie_bridge_m_bvalid),
        .pcie_bridge_m_rdata(pcie_bridge_m_rdata),
        .pcie_bridge_m_rid(pcie_bridge_m_rid),
        .pcie_bridge_m_rlast(pcie_bridge_m_rlast),
        .pcie_bridge_m_rready(pcie_bridge_m_rready),
        .pcie_bridge_m_rresp(pcie_bridge_m_rresp),
        .pcie_bridge_m_rvalid(pcie_bridge_m_rvalid),
        .pcie_bridge_m_wdata(pcie_bridge_m_wdata),
        .pcie_bridge_m_wlast(pcie_bridge_m_wlast),
        .pcie_bridge_m_wready(pcie_bridge_m_wready),
        .pcie_bridge_m_wstrb(pcie_bridge_m_wstrb),
        .pcie_bridge_m_wvalid(pcie_bridge_m_wvalid),
        .s_axis_cq_tdata (axis_cq_tdata),
        .s_axis_cq_tkeep (axis_cq_tkeep),
        .s_axis_cq_tlast (axis_cq_tlast),
        .s_axis_cq_tready(axis_cq_tready),
        .s_axis_cq_tvalid(axis_cq_tvalid),
        .user_clk(user_clk_out),
        .user_reset(user_reset_out)
);



    
    
endmodule
