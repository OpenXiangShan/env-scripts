//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
//Date        : Wed Sep  3 17:09:17 2025
//Host        : open18 running 64-bit Ubuntu 22.04.3 LTS
//Command     : generate_target xdma_trace_wrapper.bd
//Design      : xdma_trace_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module xdma_trace_wrapper
   (M00_AXIS_0_tdata,
    M00_AXIS_0_tkeep,
    M00_AXIS_0_tlast,
    M00_AXIS_0_tready,
    M00_AXIS_0_tvalid,
    cpu_clk,
    cpu_rstn,
    pci_exp_rxn,
    pci_exp_rxp,
    pci_exp_txn,
    pci_exp_txp,
    pcie_ep_gt_ref_clk_n,
    pcie_ep_gt_ref_clk_p,
    pcie_ep_lnk_up,
    pcie_ep_perstn);
  output [511:0]M00_AXIS_0_tdata;
  output [63:0]M00_AXIS_0_tkeep;
  output M00_AXIS_0_tlast;
  input M00_AXIS_0_tready;
  output M00_AXIS_0_tvalid;
  input cpu_clk;
  input cpu_rstn;
  input [7:0]pci_exp_rxn;
  input [7:0]pci_exp_rxp;
  output [7:0]pci_exp_txn;
  output [7:0]pci_exp_txp;
  input [0:0]pcie_ep_gt_ref_clk_n;
  input [0:0]pcie_ep_gt_ref_clk_p;
  output pcie_ep_lnk_up;
  input pcie_ep_perstn;

  wire [511:0]M00_AXIS_0_tdata;
  wire [63:0]M00_AXIS_0_tkeep;
  wire M00_AXIS_0_tlast;
  wire M00_AXIS_0_tready;
  wire M00_AXIS_0_tvalid;
  wire cpu_clk;
  wire cpu_rstn;
  wire [7:0]pci_exp_rxn;
  wire [7:0]pci_exp_rxp;
  wire [7:0]pci_exp_txn;
  wire [7:0]pci_exp_txp;
  wire [0:0]pcie_ep_gt_ref_clk_n;
  wire [0:0]pcie_ep_gt_ref_clk_p;
  wire pcie_ep_lnk_up;
  wire pcie_ep_perstn;

  xdma_trace xdma_trace_i
       (.M00_AXIS_0_tdata(M00_AXIS_0_tdata),
        .M00_AXIS_0_tkeep(M00_AXIS_0_tkeep),
        .M00_AXIS_0_tlast(M00_AXIS_0_tlast),
        .M00_AXIS_0_tready(M00_AXIS_0_tready),
        .M00_AXIS_0_tvalid(M00_AXIS_0_tvalid),
        .cpu_clk(cpu_clk),
        .cpu_rstn(cpu_rstn),
        .pci_exp_rxn(pci_exp_rxn),
        .pci_exp_rxp(pci_exp_rxp),
        .pci_exp_txn(pci_exp_txn),
        .pci_exp_txp(pci_exp_txp),
        .pcie_ep_gt_ref_clk_n(pcie_ep_gt_ref_clk_n),
        .pcie_ep_gt_ref_clk_p(pcie_ep_gt_ref_clk_p),
        .pcie_ep_lnk_up(pcie_ep_lnk_up),
        .pcie_ep_perstn(pcie_ep_perstn));
endmodule
