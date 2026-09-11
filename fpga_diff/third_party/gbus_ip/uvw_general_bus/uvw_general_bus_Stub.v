// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
// Date        : Thu Aug 13 18:38:52 2026
// Host        : node003.bosccluster.com running 64-bit Ubuntu 24.04.3 LTS
// Command     : write_verilog -mode synth_stub .//uvw_general_bus_stub.v
// Design      : uvw_general_bus
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu19p-fsva3824-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* ADDR_WIDTH = "32" *) (* DATA_WIDTH = "256" *) (* DUT_IO_NUM = "1" *) 
(* ID_WIDTH = "8" *) (* RDI_HAS_ANNOTATION = "1" *) (* STRB_WIDTH = "32" *) 
(* uvw_generalBus = 1 *)
(* UV_HW_IP = "type:<GENERALBUS>,toSysbus:<uvw_generalHBD>,targetPlatform:<U2>" *)
module uvw_general_bus(dut_axi_aclk, dut_axi_aclk_en, 
  dut_axi_aresetn, dut_axi_awid, dut_axi_awaddr, dut_axi_awlen, dut_axi_awsize, 
  dut_axi_awburst, dut_axi_awlock, dut_axi_awcache, dut_axi_awprot, dut_axi_awqos, 
  dut_axi_awvalid, dut_axi_awready, dut_axi_wid, dut_axi_wdata, dut_axi_wstrb, dut_axi_wlast, 
  dut_axi_wvalid, dut_axi_wready, dut_axi_bid, dut_axi_bresp, dut_axi_bvalid, dut_axi_bready, 
  dut_axi_arid, dut_axi_araddr, dut_axi_arlen, dut_axi_arsize, dut_axi_arburst, 
  dut_axi_arlock, dut_axi_arcache, dut_axi_arprot, dut_axi_arqos, dut_axi_arvalid, 
  dut_axi_arready, dut_axi_rid, dut_axi_rdata, dut_axi_rresp, dut_axi_rlast, dut_axi_rvalid, 
  dut_axi_rready, sysbus_ghbd_o, sysbus_ghbd_i)
/* synthesis syn_black_box black_box_pad_pin="dut_axi_aclk_en,dut_axi_aresetn,dut_axi_awid[7:0],dut_axi_awaddr[31:0],dut_axi_awlen[3:0],dut_axi_awsize[2:0],dut_axi_awburst[1:0],dut_axi_awlock[1:0],dut_axi_awcache[3:0],dut_axi_awprot[2:0],dut_axi_awqos[3:0],dut_axi_awvalid,dut_axi_awready,dut_axi_wid[7:0],dut_axi_wdata[255:0],dut_axi_wstrb[31:0],dut_axi_wlast,dut_axi_wvalid,dut_axi_wready,dut_axi_bid[7:0],dut_axi_bresp[1:0],dut_axi_bvalid,dut_axi_bready,dut_axi_arid[7:0],dut_axi_araddr[31:0],dut_axi_arlen[3:0],dut_axi_arsize[2:0],dut_axi_arburst[1:0],dut_axi_arlock[1:0],dut_axi_arcache[3:0],dut_axi_arprot[2:0],dut_axi_arqos[3:0],dut_axi_arvalid,dut_axi_arready,dut_axi_rid[7:0],dut_axi_rdata[255:0],dut_axi_rresp[1:0],dut_axi_rlast,dut_axi_rvalid,dut_axi_rready,sysbus_ghbd_o[255:0],sysbus_ghbd_i[255:0]" */
/* synthesis syn_force_seq_prim="dut_axi_aclk" */;
  input dut_axi_aclk /* synthesis syn_isclock = 1 */;
  input dut_axi_aclk_en;
  input dut_axi_aresetn;
  output [7:0]dut_axi_awid;
  output [31:0]dut_axi_awaddr;
  output [3:0]dut_axi_awlen;
  output [2:0]dut_axi_awsize;
  output [1:0]dut_axi_awburst;
  output [1:0]dut_axi_awlock;
  output [3:0]dut_axi_awcache;
  output [2:0]dut_axi_awprot;
  output [3:0]dut_axi_awqos;
  output dut_axi_awvalid;
  input dut_axi_awready;
  output [7:0]dut_axi_wid;
  output [255:0]dut_axi_wdata;
  output [31:0]dut_axi_wstrb;
  output dut_axi_wlast;
  output dut_axi_wvalid;
  input dut_axi_wready;
  input [7:0]dut_axi_bid;
  input [1:0]dut_axi_bresp;
  input dut_axi_bvalid;
  output dut_axi_bready;
  output [7:0]dut_axi_arid;
  output [31:0]dut_axi_araddr;
  output [3:0]dut_axi_arlen;
  output [2:0]dut_axi_arsize;
  output [1:0]dut_axi_arburst;
  output [1:0]dut_axi_arlock;
  output [3:0]dut_axi_arcache;
  output [2:0]dut_axi_arprot;
  output [3:0]dut_axi_arqos;
  output dut_axi_arvalid;
  input dut_axi_arready;
  input [7:0]dut_axi_rid;
  input [255:0]dut_axi_rdata;
  input [1:0]dut_axi_rresp;
  input dut_axi_rlast;
  input dut_axi_rvalid;
  output dut_axi_rready;
  output [255:0]sysbus_ghbd_o;
  input [255:0]sysbus_ghbd_i;


`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "Univista"
`pragma protect encrypt_agent_info = "univista-isg uv_enc 2023.11.08-35533ce"
`pragma protect data_method = "aes128-cbc"

`pragma protect key_keyowner = "Univista"
`pragma protect key_keyname = "UV-ENC-RSA-1"
`pragma protect key_method = "RSA"
`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 256)
`pragma protect key_block
BGis06JCl/nKW1S0trM9oiO3AOKGcjQBcoWTscy8gX+hpp039zUUG8u/Wzsh+v5a5wS0Uii3VbcU
yaon/C3SmUSWiyx+rVSecIIpSvMG5qrkJbVgb7wRGhqbUyr056/U8CyaFttSMB8qis9J2APCureF
fkYVZ95vqmn6leLVtkhIZ8hN+2fpQcVjmjfBRTFI6cK8MdkpdfffQ7J5ZKbgtrTp/1x7KNieGOXm
STWnLhrJF6mOcB6P/cQ2S0X1X50m2NKrMIKIenKPO+WVRa8srLP7VIFn3dvzIUrutQUvdIb7tWM3
AF57iv+9BXcQY238Hqg/EXip2f8E2rftObFDXw==

`pragma protect encoding = (enctype = "base64", line_length = 76, bytes = 240)
`pragma protect data_block
Cn/uTD9lWoN5B+wielgDP85xdGTXfl9KkeOg1akMyz8l3biTiWUn19HK2O21jk9TZjwfUazzm7nX
PQe20IFex48LbHreAxjaoGs5ZjLo+DsibfIWS55W++bEbMuV0RQmJQuuF/bQvAcQNishqv2UkQ8r
ZzAEux8KBxqt/8wPB6jbKOUUY4dTy66K/Mr3XKB8hyaA6dr0cY2ZS0TTFypRpiWXngqfJcBAsDZE
W5OXO2h7thSjrPmugX0NoJ5YbeBO0YU21CvoyCnUo+l2fttTRqusqK/RL+IKhtat6xwq8royqHcn
/TsTHjbkikbQzW2QkU/qnAp2TVKfMZtg77mQxw==

`pragma protect end_protected

endmodule
