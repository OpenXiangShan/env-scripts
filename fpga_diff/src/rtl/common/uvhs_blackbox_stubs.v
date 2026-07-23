`ifndef UVHS_BLACKBOX_STUBS_V
`define UVHS_BLACKBOX_STUBS_V

module IBUF(output O, input I);
  assign O = I;
endmodule

module OBUF(output O, input I);
  assign O = I;
endmodule

module BUFG(output O, input I);
  assign O = I;
endmodule

module IBUFGDS(output O, input I, input IB);
  assign O = I;
endmodule

module IBUFDS_GTE4(output O, output ODIV2, input I, input IB, input CEB);
  assign O = I;
  assign ODIV2 = I;
endmodule

module DifftestClockGate (
  input  CK,
  input  E,
  output Q
);
`ifdef SYNTHESIS
  BUFGCE u_bufgce (
    .I(CK),
    .CE(E),
    .O(Q)
  );
`else
  reg en;
  always @(*) begin
    if (!CK) en = E;
  end
  assign Q = CK & en;
`endif
endmodule

(* black_box, syn_black_box *)
module vio_0 (
  clk, probe_out0, probe_out1, probe_out2
);
input clk;
output probe_out0, probe_out1, probe_out2;
endmodule

(* black_box, syn_black_box *)
module blk_mem_gen_0 (
  rsta_busy, rstb_busy, s_aclk, s_aresetn, s_axi_araddr, s_axi_arlen,
  s_axi_arready, s_axi_arvalid, s_axi_awaddr, s_axi_awlen, s_axi_awready,
  s_axi_awvalid, s_axi_bready, s_axi_bresp, s_axi_bvalid, s_axi_rdata,
  s_axi_rlast, s_axi_rready, s_axi_rresp, s_axi_rvalid, s_axi_wdata,
  s_axi_wlast, s_axi_wready, s_axi_wstrb, s_axi_wvalid
);
output rsta_busy, rstb_busy;
input s_aclk, s_aresetn;
input [31:0] s_axi_araddr, s_axi_awaddr, s_axi_wdata;
input [7:0] s_axi_arlen, s_axi_awlen;
input [3:0] s_axi_wstrb;
input s_axi_arvalid, s_axi_awvalid, s_axi_bready, s_axi_rready;
input s_axi_wlast, s_axi_wvalid;
output s_axi_arready, s_axi_awready, s_axi_wready;
output [1:0] s_axi_bresp, s_axi_rresp;
output [31:0] s_axi_rdata;
output s_axi_bvalid, s_axi_rlast, s_axi_rvalid;
endmodule

(* black_box, syn_black_box *)
module xdma_ep (
  M00_AXIS_0_tdata, M00_AXIS_0_tkeep, M00_AXIS_0_tlast, M00_AXIS_0_tready,
  M00_AXIS_0_tvalid, S00_AXIS_0_tdata, S00_AXIS_0_tkeep, S00_AXIS_0_tlast,
  S00_AXIS_0_tready, S00_AXIS_0_tvalid, TO_DIFFTEST_PCIE_CLK,
  XDMA_AXI_LITE_araddr, XDMA_AXI_LITE_arprot, XDMA_AXI_LITE_arready,
  XDMA_AXI_LITE_arvalid, XDMA_AXI_LITE_awaddr, XDMA_AXI_LITE_awprot,
  XDMA_AXI_LITE_awready, XDMA_AXI_LITE_awvalid, XDMA_AXI_LITE_bready,
  XDMA_AXI_LITE_bresp, XDMA_AXI_LITE_bvalid, XDMA_AXI_LITE_rdata,
  XDMA_AXI_LITE_rready, XDMA_AXI_LITE_rresp, XDMA_AXI_LITE_rvalid,
  XDMA_AXI_LITE_wdata, XDMA_AXI_LITE_wready, XDMA_AXI_LITE_wstrb,
  XDMA_AXI_LITE_wvalid, cpu_clk, cpu_rstn, pci_exp_rxn, pci_exp_rxp,
  pci_exp_txn, pci_exp_txp, pcie_ep_gt_ref_clk_n, pcie_ep_gt_ref_clk_p,
  pcie_ep_lnk_up, pcie_ep_perstn
);
output [255:0] M00_AXIS_0_tdata;
output [31:0] M00_AXIS_0_tkeep;
output M00_AXIS_0_tlast;
input M00_AXIS_0_tready;
output M00_AXIS_0_tvalid;
input [255:0] S00_AXIS_0_tdata;
input [31:0] S00_AXIS_0_tkeep;
input S00_AXIS_0_tlast, S00_AXIS_0_tvalid;
output S00_AXIS_0_tready, TO_DIFFTEST_PCIE_CLK;
output [31:0] XDMA_AXI_LITE_araddr, XDMA_AXI_LITE_awaddr, XDMA_AXI_LITE_wdata;
output [2:0] XDMA_AXI_LITE_arprot, XDMA_AXI_LITE_awprot;
input XDMA_AXI_LITE_arready, XDMA_AXI_LITE_awready;
output XDMA_AXI_LITE_arvalid, XDMA_AXI_LITE_awvalid, XDMA_AXI_LITE_bready;
input [1:0] XDMA_AXI_LITE_bresp, XDMA_AXI_LITE_rresp;
input XDMA_AXI_LITE_bvalid;
input [31:0] XDMA_AXI_LITE_rdata;
output XDMA_AXI_LITE_rready;
input XDMA_AXI_LITE_rvalid;
input XDMA_AXI_LITE_wready;
output [3:0] XDMA_AXI_LITE_wstrb;
output XDMA_AXI_LITE_wvalid;
input cpu_clk, cpu_rstn;
input [3:0] pci_exp_rxn, pci_exp_rxp;
output [3:0] pci_exp_txn, pci_exp_txp;
input pcie_ep_gt_ref_clk_n, pcie_ep_gt_ref_clk_p, pcie_ep_perstn;
output pcie_ep_lnk_up;
endmodule

module xdma_ep_util_ds_buf_0_0 (
  IBUF_DS_P, IBUF_DS_N, IBUF_OUT, IBUF_DS_ODIV2
);
input [0:0] IBUF_DS_P, IBUF_DS_N;
output [0:0] IBUF_OUT, IBUF_DS_ODIV2;

wire ibuf_out;
wire ibuf_div2;

IBUFDS_GTE4 u_ibufds_gte4 (
  .I(IBUF_DS_P[0]),
  .IB(IBUF_DS_N[0]),
  .CEB(1'b0),
  .O(ibuf_out),
  .ODIV2(ibuf_div2)
);

assign IBUF_OUT[0] = ibuf_out;
assign IBUF_DS_ODIV2[0] = ibuf_div2;
endmodule

(* black_box, syn_black_box *)
module AXI_bridge (
  ACLK, ARESETN, S00_AXI_araddr, S00_AXI_arburst, S00_AXI_arcache,
  S00_AXI_arid, S00_AXI_arlen, S00_AXI_arlock, S00_AXI_arprot,
  S00_AXI_arqos, S00_AXI_arready, S00_AXI_arregion, S00_AXI_arsize, S00_AXI_arvalid,
  S00_AXI_awaddr, S00_AXI_awburst, S00_AXI_awcache, S00_AXI_awid,
  S00_AXI_awlen, S00_AXI_awlock, S00_AXI_awprot, S00_AXI_awqos,
  S00_AXI_awready, S00_AXI_awregion, S00_AXI_awsize, S00_AXI_awvalid, S00_AXI_bid,
  S00_AXI_bready, S00_AXI_bresp, S00_AXI_bvalid, S00_AXI_rdata,
  S00_AXI_rid, S00_AXI_rlast, S00_AXI_rready, S00_AXI_rresp,
  S00_AXI_rvalid, S00_AXI_wdata, S00_AXI_wlast, S00_AXI_wready,
  S00_AXI_wstrb, S00_AXI_wvalid, SYS_CFG_APB_paddr, SYS_CFG_APB_penable,
  SYS_CFG_APB_prdata, SYS_CFG_APB_pready, SYS_CFG_APB_psel,
  SYS_CFG_APB_pslverr, SYS_CFG_APB_pwdata, SYS_CFG_APB_pwrite,
  DMAC_CFG_AHB_hrdata, DMAC_CFG_AHB_hready, DMAC_CFG_AHB_hresp,
  IOMMU_CFG_APB_prdata, IOMMU_CFG_APB_pready, IOMMU_CFG_APB_pslverr,
  SYS_INTER_CLK, SYS_INTER_ARESETN, UART_0_rxd, UART_0_txd,
  UARTLITE_AXI_arready, UARTLITE_AXI_awready, UARTLITE_AXI_bid,
  UARTLITE_AXI_bresp, UARTLITE_AXI_bvalid, UARTLITE_AXI_rdata,
  UARTLITE_AXI_rid, UARTLITE_AXI_rlast, UARTLITE_AXI_rresp,
  UARTLITE_AXI_rvalid, UARTLITE_AXI_wready,
  pcie_cfg_arready, pcie_cfg_awready, pcie_cfg_bresp, pcie_cfg_bvalid,
  pcie_cfg_rdata, pcie_cfg_rlast, pcie_cfg_rresp, pcie_cfg_rvalid,
  pcie_cfg_wready,
  rom_axi_araddr, rom_axi_arburst, rom_axi_arcache, rom_axi_arlen,
  rom_axi_arlock, rom_axi_arprot, rom_axi_arqos, rom_axi_arready,
  rom_axi_arregion, rom_axi_arsize, rom_axi_arvalid, rom_axi_awaddr,
  rom_axi_awburst, rom_axi_awcache, rom_axi_awlen, rom_axi_awlock,
  rom_axi_awprot, rom_axi_awqos, rom_axi_awready, rom_axi_awregion,
  rom_axi_awsize, rom_axi_awvalid, rom_axi_bready, rom_axi_bresp,
  rom_axi_bvalid, rom_axi_rdata, rom_axi_rlast, rom_axi_rready,
  rom_axi_rresp, rom_axi_rvalid, rom_axi_wdata, rom_axi_wlast,
  rom_axi_wready, rom_axi_wstrb, rom_axi_wvalid, uart0_intc
);
input ACLK, ARESETN, SYS_INTER_CLK, SYS_INTER_ARESETN;
input [30:0] S00_AXI_araddr, S00_AXI_awaddr;
input [1:0] S00_AXI_arburst, S00_AXI_awburst, S00_AXI_arid, S00_AXI_awid;
input [3:0] S00_AXI_arcache, S00_AXI_arqos, S00_AXI_awcache, S00_AXI_awqos;
input [3:0] S00_AXI_arregion, S00_AXI_awregion;
input [7:0] S00_AXI_arlen, S00_AXI_awlen, S00_AXI_wstrb;
input S00_AXI_arlock, S00_AXI_awlock;
input [2:0] S00_AXI_arprot, S00_AXI_arsize, S00_AXI_awprot, S00_AXI_awsize;
input S00_AXI_arvalid, S00_AXI_awvalid, S00_AXI_bready;
input S00_AXI_rready, S00_AXI_wlast, S00_AXI_wvalid;
input [63:0] S00_AXI_wdata;
output S00_AXI_arready, S00_AXI_awready, S00_AXI_bvalid;
output S00_AXI_rlast, S00_AXI_rvalid, S00_AXI_wready;
output [1:0] S00_AXI_bid, S00_AXI_bresp, S00_AXI_rid, S00_AXI_rresp;
output [63:0] S00_AXI_rdata;
output [30:0] SYS_CFG_APB_paddr;
output SYS_CFG_APB_penable, SYS_CFG_APB_pwrite;
output [31:0] SYS_CFG_APB_pwdata;
output SYS_CFG_APB_psel;
input [31:0] SYS_CFG_APB_prdata;
input SYS_CFG_APB_pready, SYS_CFG_APB_pslverr;
input [31:0] DMAC_CFG_AHB_hrdata;
input DMAC_CFG_AHB_hready, DMAC_CFG_AHB_hresp;
input [31:0] IOMMU_CFG_APB_prdata;
input IOMMU_CFG_APB_pready, IOMMU_CFG_APB_pslverr;
output UART_0_txd, uart0_intc;
input UART_0_rxd;
input UARTLITE_AXI_arready, UARTLITE_AXI_awready, UARTLITE_AXI_bvalid;
input UARTLITE_AXI_rlast, UARTLITE_AXI_rvalid, UARTLITE_AXI_wready;
input [1:0] UARTLITE_AXI_bid, UARTLITE_AXI_bresp;
input [1:0] UARTLITE_AXI_rid, UARTLITE_AXI_rresp;
input [63:0] UARTLITE_AXI_rdata;
input pcie_cfg_arready, pcie_cfg_awready, pcie_cfg_bvalid;
input pcie_cfg_rlast, pcie_cfg_rvalid, pcie_cfg_wready;
input [1:0] pcie_cfg_bresp, pcie_cfg_rresp;
input [31:0] pcie_cfg_rdata;
output [31:0] rom_axi_araddr, rom_axi_awaddr, rom_axi_wdata;
output [1:0] rom_axi_arburst, rom_axi_awburst;
output [3:0] rom_axi_arcache, rom_axi_arqos, rom_axi_arregion;
output [3:0] rom_axi_awcache, rom_axi_awqos, rom_axi_awregion;
output [7:0] rom_axi_arlen, rom_axi_awlen;
output rom_axi_arlock, rom_axi_awlock;
output [2:0] rom_axi_arprot, rom_axi_arsize, rom_axi_awprot, rom_axi_awsize;
output rom_axi_arvalid, rom_axi_awvalid, rom_axi_bready;
output rom_axi_rready, rom_axi_wlast, rom_axi_wvalid;
output [3:0] rom_axi_wstrb;
input rom_axi_arready, rom_axi_awready, rom_axi_bvalid;
input rom_axi_rlast, rom_axi_rvalid, rom_axi_wready;
input [1:0] rom_axi_bresp, rom_axi_rresp;
input [31:0] rom_axi_rdata;
endmodule

(* black_box, syn_black_box *)
module data_bridge (
  ACLK, ARESETN, M00_AXI_araddr, M00_AXI_arburst, M00_AXI_arcache,
  M00_AXI_arid, M00_AXI_arlen, M00_AXI_arlock, M00_AXI_arprot,
  M00_AXI_arqos, M00_AXI_arready, M00_AXI_arregion, M00_AXI_arsize,
  M00_AXI_arvalid, M00_AXI_awaddr, M00_AXI_awburst, M00_AXI_awcache,
  M00_AXI_awid, M00_AXI_awlen, M00_AXI_awlock, M00_AXI_awprot,
  M00_AXI_awqos, M00_AXI_awready, M00_AXI_awregion, M00_AXI_awsize,
  M00_AXI_awvalid, M00_AXI_bid, M00_AXI_bready, M00_AXI_bresp,
  M00_AXI_bvalid, M00_AXI_rdata, M00_AXI_rid, M00_AXI_rlast,
  M00_AXI_rready, M00_AXI_rresp, M00_AXI_rvalid, M00_AXI_wdata,
  M00_AXI_wlast, M00_AXI_wready, M00_AXI_wstrb, M00_AXI_wvalid,
  S00_AXI_araddr, S00_AXI_arburst, S00_AXI_arcache, S00_AXI_arid,
  S00_AXI_arlen, S00_AXI_arlock, S00_AXI_arprot, S00_AXI_arqos,
  S00_AXI_arready, S00_AXI_arregion, S00_AXI_arsize, S00_AXI_arvalid,
  S00_AXI_awaddr, S00_AXI_awburst, S00_AXI_awcache, S00_AXI_awid,
  S00_AXI_awlen, S00_AXI_awlock, S00_AXI_awprot, S00_AXI_awqos,
  S00_AXI_awready, S00_AXI_awregion, S00_AXI_awsize, S00_AXI_awvalid,
  S00_AXI_bid, S00_AXI_bready, S00_AXI_bresp, S00_AXI_bvalid,
  S00_AXI_rdata, S00_AXI_rid, S00_AXI_rlast, S00_AXI_rready,
  S00_AXI_rresp, S00_AXI_rvalid, S00_AXI_wdata, S00_AXI_wlast,
  S00_AXI_wready, S00_AXI_wstrb, S00_AXI_wvalid, S01_AXI_araddr,
  S01_AXI_arburst, S01_AXI_arcache, S01_AXI_arid, S01_AXI_arlen,
  S01_AXI_arlock, S01_AXI_arprot, S01_AXI_arqos, S01_AXI_arready,
  S01_AXI_arregion, S01_AXI_arsize, S01_AXI_arvalid, S01_AXI_awaddr,
  S01_AXI_awburst, S01_AXI_awcache, S01_AXI_awid, S01_AXI_awlen,
  S01_AXI_awlock, S01_AXI_awprot, S01_AXI_awqos, S01_AXI_awready,
  S01_AXI_awregion, S01_AXI_awsize, S01_AXI_awvalid, S01_AXI_bid,
  S01_AXI_bready, S01_AXI_bresp, S01_AXI_bvalid, S01_AXI_rdata,
  S01_AXI_rid, S01_AXI_rlast, S01_AXI_rready, S01_AXI_rresp,
  S01_AXI_rvalid, S01_AXI_wdata, S01_AXI_wlast, S01_AXI_wready,
  S01_AXI_wstrb, S01_AXI_wvalid
);
input ACLK, ARESETN;
output [39:0] M00_AXI_araddr, M00_AXI_awaddr;
output [0:0] M00_AXI_arid, M00_AXI_awid;
output [7:0] M00_AXI_arlen, M00_AXI_awlen;
output [1:0] M00_AXI_arburst, M00_AXI_awburst;
output [3:0] M00_AXI_arcache, M00_AXI_arqos, M00_AXI_arregion;
output [3:0] M00_AXI_awcache, M00_AXI_awqos, M00_AXI_awregion;
output [2:0] M00_AXI_arprot, M00_AXI_arsize, M00_AXI_awprot, M00_AXI_awsize;
output M00_AXI_arlock, M00_AXI_arvalid, M00_AXI_awlock, M00_AXI_awvalid;
input M00_AXI_arready, M00_AXI_awready, M00_AXI_wready;
input [0:0] M00_AXI_bid, M00_AXI_rid;
input [1:0] M00_AXI_bresp, M00_AXI_rresp;
input [255:0] M00_AXI_rdata;
input M00_AXI_bvalid, M00_AXI_rlast, M00_AXI_rvalid;
output M00_AXI_bready, M00_AXI_rready, M00_AXI_wlast, M00_AXI_wvalid;
output [255:0] M00_AXI_wdata;
output [31:0] M00_AXI_wstrb;
input [39:0] S00_AXI_araddr, S00_AXI_awaddr;
input [0:0] S00_AXI_arid, S00_AXI_awid;
input [7:0] S00_AXI_arlen, S00_AXI_awlen;
input [1:0] S00_AXI_arburst, S00_AXI_awburst;
input [3:0] S00_AXI_arcache, S00_AXI_arqos, S00_AXI_arregion;
input [3:0] S00_AXI_awcache, S00_AXI_awqos, S00_AXI_awregion;
input [2:0] S00_AXI_arprot, S00_AXI_arsize, S00_AXI_awprot, S00_AXI_awsize;
input S00_AXI_arlock, S00_AXI_arvalid, S00_AXI_awlock, S00_AXI_awvalid;
input S00_AXI_bready, S00_AXI_rready, S00_AXI_wlast, S00_AXI_wvalid;
input [31:0] S00_AXI_wdata;
input [3:0] S00_AXI_wstrb;
output S00_AXI_arready, S00_AXI_awready, S00_AXI_wready;
output [0:0] S00_AXI_bid, S00_AXI_rid;
output [1:0] S00_AXI_bresp, S00_AXI_rresp;
output [31:0] S00_AXI_rdata;
output S00_AXI_bvalid, S00_AXI_rlast, S00_AXI_rvalid;
input [39:0] S01_AXI_araddr, S01_AXI_awaddr;
input [0:0] S01_AXI_arid, S01_AXI_awid;
input [7:0] S01_AXI_arlen, S01_AXI_awlen;
input [1:0] S01_AXI_arburst, S01_AXI_awburst;
input [3:0] S01_AXI_arcache, S01_AXI_arqos, S01_AXI_arregion;
input [3:0] S01_AXI_awcache, S01_AXI_awqos, S01_AXI_awregion;
input [2:0] S01_AXI_arprot, S01_AXI_arsize, S01_AXI_awprot, S01_AXI_awsize;
input S01_AXI_arlock, S01_AXI_arvalid, S01_AXI_awlock, S01_AXI_awvalid;
input S01_AXI_bready, S01_AXI_rready, S01_AXI_wlast, S01_AXI_wvalid;
input [31:0] S01_AXI_wdata;
input [3:0] S01_AXI_wstrb;
output S01_AXI_arready, S01_AXI_awready, S01_AXI_wready;
output [0:0] S01_AXI_bid, S01_AXI_rid;
output [1:0] S01_AXI_bresp, S01_AXI_rresp;
output [31:0] S01_AXI_rdata;
output S01_AXI_bvalid, S01_AXI_rlast, S01_AXI_rvalid;
endmodule

`ifndef UVHS_EXTERNAL_UVW_AXI4_TO_DDR4
(* black_box, syn_black_box *)
module uvw_axi4_to_ddr4;
endmodule
`endif

`endif
