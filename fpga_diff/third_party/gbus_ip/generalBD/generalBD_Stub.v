// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.2 (lin64) Build 3367213 Tue Oct 19 02:47:39 MDT 2021
// Date        : Mon May 29 08:49:53 2023
// Host        : hjsh-emu50.rd.univista-isg.com running 64-bit CentOS Linux release 7.8.2003 (Core)
// Command     : write_verilog -mode synth_stub ././output/generalBD_stub.v
// Design      : generalBD
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu19p-fsva3824-1-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* uvw_generalBD = 1 *)
(* UV_HW_IP="type:<GENERALBD>,toSysbus:<uvw_generalBD>,targetPlatform:<U2>" *)
module generalBD(i_clk, i_rstn, i_clk_en, o_wr_en, o_wr_addr,
  o_wdata, o_rd_en, o_rd_addr, i_rdata, i_rdata_vld, gbd_sysbus_i, gbd_sysbus_o)
/* synthesis syn_black_box black_box_pad_pin="i_clk,i_rstn,i_clk_en,o_wr_en,o_wr_addr[15:0],o_wdata[31:0],o_rd_en,o_rd_addr[15:0],i_rdata[31:0],i_rdata_vld,gbd_sysbus_i[255:0],gbd_sysbus_o[255:0]" */;
  input i_clk;
  input i_rstn;
  input i_clk_en;
  output o_wr_en;
  output [15:0]o_wr_addr;
  output [31:0]o_wdata;
  output o_rd_en;
  output [15:0]o_rd_addr;
  input [31:0]i_rdata;
  input i_rdata_vld;
  input [255:0]gbd_sysbus_i;
  output [255:0]gbd_sysbus_o;
endmodule
