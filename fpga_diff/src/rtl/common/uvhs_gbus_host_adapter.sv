// GBus replacement contract for the XDMA endpoint.
// The board-specific general-bus DCP replaces this quiescent shell adapter.
module uvhs_gbus_host_adapter (
  output wire [255:0] M00_AXIS_0_tdata, output wire [31:0] M00_AXIS_0_tkeep,
  output wire M00_AXIS_0_tlast, input wire M00_AXIS_0_tready, output wire M00_AXIS_0_tvalid,
  input wire [255:0] S00_AXIS_0_tdata, input wire [31:0] S00_AXIS_0_tkeep,
  input wire S00_AXIS_0_tlast, output wire S00_AXIS_0_tready, input wire S00_AXIS_0_tvalid,
  output wire TO_DIFFTEST_PCIE_CLK,
  output wire [31:0] XDMA_AXI_LITE_araddr, output wire [2:0] XDMA_AXI_LITE_arprot,
  input wire XDMA_AXI_LITE_arready, output wire XDMA_AXI_LITE_arvalid,
  output wire [31:0] XDMA_AXI_LITE_awaddr, output wire [2:0] XDMA_AXI_LITE_awprot,
  input wire XDMA_AXI_LITE_awready, output wire XDMA_AXI_LITE_awvalid,
  output wire XDMA_AXI_LITE_bready, input wire [1:0] XDMA_AXI_LITE_bresp,
  input wire XDMA_AXI_LITE_bvalid, input wire [31:0] XDMA_AXI_LITE_rdata,
  output wire XDMA_AXI_LITE_rready, input wire XDMA_AXI_LITE_rvalid,
  input wire [1:0] XDMA_AXI_LITE_rresp, output wire [31:0] XDMA_AXI_LITE_wdata,
  input wire XDMA_AXI_LITE_wready, output wire [3:0] XDMA_AXI_LITE_wstrb,
  output wire XDMA_AXI_LITE_wvalid,
  input wire cpu_clk, input wire cpu_rstn,
  input wire [3:0] pci_exp_rxn, input wire [3:0] pci_exp_rxp,
  output wire [3:0] pci_exp_txn, output wire [3:0] pci_exp_txp,
  input wire pcie_ep_gt_ref_clk_n, input wire pcie_ep_gt_ref_clk_p,
  input wire pcie_ep_perstn, output wire pcie_ep_lnk_up
);
  assign TO_DIFFTEST_PCIE_CLK = cpu_clk;
  assign pcie_ep_lnk_up = 1'b0;
  assign pci_exp_txn = 4'b0; assign pci_exp_txp = 4'b0;
  assign S00_AXIS_0_tready = 1'b0;
  assign M00_AXIS_0_tdata = 256'b0; assign M00_AXIS_0_tkeep = 32'b0;
  assign M00_AXIS_0_tlast = 1'b0; assign M00_AXIS_0_tvalid = 1'b0;
  assign XDMA_AXI_LITE_araddr = 32'b0; assign XDMA_AXI_LITE_arprot = 3'b0;
  assign XDMA_AXI_LITE_arvalid = 1'b0; assign XDMA_AXI_LITE_awaddr = 32'b0;
  assign XDMA_AXI_LITE_awprot = 3'b0; assign XDMA_AXI_LITE_awvalid = 1'b0;
  assign XDMA_AXI_LITE_bready = 1'b0; assign XDMA_AXI_LITE_rready = 1'b0;
  assign XDMA_AXI_LITE_wdata = 32'b0; assign XDMA_AXI_LITE_wstrb = 4'b0;
  assign XDMA_AXI_LITE_wvalid = 1'b0;
endmodule
