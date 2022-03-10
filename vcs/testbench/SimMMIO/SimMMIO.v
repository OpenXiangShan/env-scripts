module SimMMIO(
  input         clock,
  input         reset,
  output        io_axi4_0_awready,
  input         io_axi4_0_awvalid,
  input  [1:0]  io_axi4_0_awid,
  input  [30:0] io_axi4_0_awaddr,
  input  [7:0]  io_axi4_0_awlen,
  input  [2:0]  io_axi4_0_awsize,
  input  [1:0]  io_axi4_0_awburst,
  input         io_axi4_0_awlock,
  input  [3:0]  io_axi4_0_awcache,
  input  [2:0]  io_axi4_0_awprot,
  input  [3:0]  io_axi4_0_awqos,
  output        io_axi4_0_wready,
  input         io_axi4_0_wvalid,
  input  [63:0] io_axi4_0_wdata,
  input  [7:0]  io_axi4_0_wstrb,
  input         io_axi4_0_wlast,
  input         io_axi4_0_bready,
  output        io_axi4_0_bvalid,
  output [1:0]  io_axi4_0_bid,
  output [1:0]  io_axi4_0_bresp,
  output        io_axi4_0_arready,
  input         io_axi4_0_arvalid,
  input  [1:0]  io_axi4_0_arid,
  input  [30:0] io_axi4_0_araddr,
  input  [7:0]  io_axi4_0_arlen,
  input  [2:0]  io_axi4_0_arsize,
  input  [1:0]  io_axi4_0_arburst,
  input         io_axi4_0_arlock,
  input  [3:0]  io_axi4_0_arcache,
  input  [2:0]  io_axi4_0_arprot,
  input  [3:0]  io_axi4_0_arqos,
  input         io_axi4_0_rready,
  output        io_axi4_0_rvalid,
  output [1:0]  io_axi4_0_rid,
  output [63:0] io_axi4_0_rdata,
  output [1:0]  io_axi4_0_rresp,
  output        io_axi4_0_rlast,
  output        io_uart_out_valid,
  output [7:0]  io_uart_out_ch,
  output        io_uart_in_valid,
  input  [7:0]  io_uart_in_ch,
  output [63:0] io_interrupt_intrVec
);
  wire  flash_clock; // @[SimMMIO.scala 30:25]
  wire  flash_reset; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_awready; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_awvalid; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_awid; // @[SimMMIO.scala 30:25]
  wire [28:0] flash_auto_in_awaddr; // @[SimMMIO.scala 30:25]
  wire [7:0] flash_auto_in_awlen; // @[SimMMIO.scala 30:25]
  wire [2:0] flash_auto_in_awsize; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_awburst; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_awlock; // @[SimMMIO.scala 30:25]
  wire [3:0] flash_auto_in_awcache; // @[SimMMIO.scala 30:25]
  wire [2:0] flash_auto_in_awprot; // @[SimMMIO.scala 30:25]
  wire [3:0] flash_auto_in_awqos; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_wready; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_wvalid; // @[SimMMIO.scala 30:25]
  wire [63:0] flash_auto_in_wdata; // @[SimMMIO.scala 30:25]
  wire [7:0] flash_auto_in_wstrb; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_wlast; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_bready; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_bvalid; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_bid; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_bresp; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_arready; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_arvalid; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_arid; // @[SimMMIO.scala 30:25]
  wire [28:0] flash_auto_in_araddr; // @[SimMMIO.scala 30:25]
  wire [7:0] flash_auto_in_arlen; // @[SimMMIO.scala 30:25]
  wire [2:0] flash_auto_in_arsize; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_arburst; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_arlock; // @[SimMMIO.scala 30:25]
  wire [3:0] flash_auto_in_arcache; // @[SimMMIO.scala 30:25]
  wire [2:0] flash_auto_in_arprot; // @[SimMMIO.scala 30:25]
  wire [3:0] flash_auto_in_arqos; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_rready; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_rvalid; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_rid; // @[SimMMIO.scala 30:25]
  wire [63:0] flash_auto_in_rdata; // @[SimMMIO.scala 30:25]
  wire [1:0] flash_auto_in_rresp; // @[SimMMIO.scala 30:25]
  wire  flash_auto_in_rlast; // @[SimMMIO.scala 30:25]
  wire  uart_clock; // @[SimMMIO.scala 31:24]
  wire  uart_reset; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_awready; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_awvalid; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_awid; // @[SimMMIO.scala 31:24]
  wire [30:0] uart_auto_in_awaddr; // @[SimMMIO.scala 31:24]
  wire [7:0] uart_auto_in_awlen; // @[SimMMIO.scala 31:24]
  wire [2:0] uart_auto_in_awsize; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_awburst; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_awlock; // @[SimMMIO.scala 31:24]
  wire [3:0] uart_auto_in_awcache; // @[SimMMIO.scala 31:24]
  wire [2:0] uart_auto_in_awprot; // @[SimMMIO.scala 31:24]
  wire [3:0] uart_auto_in_awqos; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_wready; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_wvalid; // @[SimMMIO.scala 31:24]
  wire [63:0] uart_auto_in_wdata; // @[SimMMIO.scala 31:24]
  wire [7:0] uart_auto_in_wstrb; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_wlast; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_bready; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_bvalid; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_bid; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_bresp; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_arready; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_arvalid; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_arid; // @[SimMMIO.scala 31:24]
  wire [30:0] uart_auto_in_araddr; // @[SimMMIO.scala 31:24]
  wire [7:0] uart_auto_in_arlen; // @[SimMMIO.scala 31:24]
  wire [2:0] uart_auto_in_arsize; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_arburst; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_arlock; // @[SimMMIO.scala 31:24]
  wire [3:0] uart_auto_in_arcache; // @[SimMMIO.scala 31:24]
  wire [2:0] uart_auto_in_arprot; // @[SimMMIO.scala 31:24]
  wire [3:0] uart_auto_in_arqos; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_rready; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_rvalid; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_rid; // @[SimMMIO.scala 31:24]
  wire [63:0] uart_auto_in_rdata; // @[SimMMIO.scala 31:24]
  wire [1:0] uart_auto_in_rresp; // @[SimMMIO.scala 31:24]
  wire  uart_auto_in_rlast; // @[SimMMIO.scala 31:24]
  wire  uart_io_extra_out_valid; // @[SimMMIO.scala 31:24]
  wire [7:0] uart_io_extra_out_ch; // @[SimMMIO.scala 31:24]
  wire  uart_io_extra_in_valid; // @[SimMMIO.scala 31:24]
  wire [7:0] uart_io_extra_in_ch; // @[SimMMIO.scala 31:24]
  wire  vga_clock; // @[SimMMIO.scala 32:23]
  wire  vga_reset; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_awready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_awvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_awid; // @[SimMMIO.scala 32:23]
  wire [30:0] vga_auto_in_1_awaddr; // @[SimMMIO.scala 32:23]
  wire [7:0] vga_auto_in_1_awlen; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_1_awsize; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_awburst; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_awlock; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_1_awcache; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_1_awprot; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_1_awqos; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_wready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_wvalid; // @[SimMMIO.scala 32:23]
  wire [63:0] vga_auto_in_1_wdata; // @[SimMMIO.scala 32:23]
  wire [7:0] vga_auto_in_1_wstrb; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_wlast; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_bready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_bvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_bid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_bresp; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_arready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_arvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_arid; // @[SimMMIO.scala 32:23]
  wire [30:0] vga_auto_in_1_araddr; // @[SimMMIO.scala 32:23]
  wire [7:0] vga_auto_in_1_arlen; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_1_arsize; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_arburst; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_arlock; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_1_arcache; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_1_arprot; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_1_arqos; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_rready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_rvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_rid; // @[SimMMIO.scala 32:23]
  wire [63:0] vga_auto_in_1_rdata; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_1_rresp; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_1_rlast; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_awready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_awvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_awid; // @[SimMMIO.scala 32:23]
  wire [30:0] vga_auto_in_0_awaddr; // @[SimMMIO.scala 32:23]
  wire [7:0] vga_auto_in_0_awlen; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_0_awsize; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_awburst; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_awlock; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_0_awcache; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_0_awprot; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_0_awqos; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_wready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_wvalid; // @[SimMMIO.scala 32:23]
  wire [63:0] vga_auto_in_0_wdata; // @[SimMMIO.scala 32:23]
  wire [7:0] vga_auto_in_0_wstrb; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_wlast; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_bready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_bvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_bid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_bresp; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_arvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_arid; // @[SimMMIO.scala 32:23]
  wire [7:0] vga_auto_in_0_arlen; // @[SimMMIO.scala 32:23]
  wire [2:0] vga_auto_in_0_arsize; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_arburst; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_arlock; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_0_arcache; // @[SimMMIO.scala 32:23]
  wire [3:0] vga_auto_in_0_arqos; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_rready; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_rvalid; // @[SimMMIO.scala 32:23]
  wire [1:0] vga_auto_in_0_rid; // @[SimMMIO.scala 32:23]
  wire  vga_auto_in_0_rlast; // @[SimMMIO.scala 32:23]
  wire  sd_clock; // @[SimMMIO.scala 37:22]
  wire  sd_reset; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_awready; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_awvalid; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_awid; // @[SimMMIO.scala 37:22]
  wire [30:0] sd_auto_in_awaddr; // @[SimMMIO.scala 37:22]
  wire [7:0] sd_auto_in_awlen; // @[SimMMIO.scala 37:22]
  wire [2:0] sd_auto_in_awsize; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_awburst; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_awlock; // @[SimMMIO.scala 37:22]
  wire [3:0] sd_auto_in_awcache; // @[SimMMIO.scala 37:22]
  wire [2:0] sd_auto_in_awprot; // @[SimMMIO.scala 37:22]
  wire [3:0] sd_auto_in_awqos; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_wready; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_wvalid; // @[SimMMIO.scala 37:22]
  wire [63:0] sd_auto_in_wdata; // @[SimMMIO.scala 37:22]
  wire [7:0] sd_auto_in_wstrb; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_wlast; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_bready; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_bvalid; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_bid; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_bresp; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_arready; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_arvalid; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_arid; // @[SimMMIO.scala 37:22]
  wire [30:0] sd_auto_in_araddr; // @[SimMMIO.scala 37:22]
  wire [7:0] sd_auto_in_arlen; // @[SimMMIO.scala 37:22]
  wire [2:0] sd_auto_in_arsize; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_arburst; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_arlock; // @[SimMMIO.scala 37:22]
  wire [3:0] sd_auto_in_arcache; // @[SimMMIO.scala 37:22]
  wire [2:0] sd_auto_in_arprot; // @[SimMMIO.scala 37:22]
  wire [3:0] sd_auto_in_arqos; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_rready; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_rvalid; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_rid; // @[SimMMIO.scala 37:22]
  wire [63:0] sd_auto_in_rdata; // @[SimMMIO.scala 37:22]
  wire [1:0] sd_auto_in_rresp; // @[SimMMIO.scala 37:22]
  wire  sd_auto_in_rlast; // @[SimMMIO.scala 37:22]
  wire  intrGen_clock; // @[SimMMIO.scala 38:27]
  wire  intrGen_reset; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_awready; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_awvalid; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_awid; // @[SimMMIO.scala 38:27]
  wire [30:0] intrGen_auto_in_awaddr; // @[SimMMIO.scala 38:27]
  wire [7:0] intrGen_auto_in_awlen; // @[SimMMIO.scala 38:27]
  wire [2:0] intrGen_auto_in_awsize; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_awburst; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_awlock; // @[SimMMIO.scala 38:27]
  wire [3:0] intrGen_auto_in_awcache; // @[SimMMIO.scala 38:27]
  wire [2:0] intrGen_auto_in_awprot; // @[SimMMIO.scala 38:27]
  wire [3:0] intrGen_auto_in_awqos; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_wready; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_wvalid; // @[SimMMIO.scala 38:27]
  wire [63:0] intrGen_auto_in_wdata; // @[SimMMIO.scala 38:27]
  wire [7:0] intrGen_auto_in_wstrb; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_wlast; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_bready; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_bvalid; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_bid; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_bresp; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_arready; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_arvalid; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_arid; // @[SimMMIO.scala 38:27]
  wire [30:0] intrGen_auto_in_araddr; // @[SimMMIO.scala 38:27]
  wire [7:0] intrGen_auto_in_arlen; // @[SimMMIO.scala 38:27]
  wire [2:0] intrGen_auto_in_arsize; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_arburst; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_arlock; // @[SimMMIO.scala 38:27]
  wire [3:0] intrGen_auto_in_arcache; // @[SimMMIO.scala 38:27]
  wire [2:0] intrGen_auto_in_arprot; // @[SimMMIO.scala 38:27]
  wire [3:0] intrGen_auto_in_arqos; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_rready; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_rvalid; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_rid; // @[SimMMIO.scala 38:27]
  wire [63:0] intrGen_auto_in_rdata; // @[SimMMIO.scala 38:27]
  wire [1:0] intrGen_auto_in_rresp; // @[SimMMIO.scala 38:27]
  wire  intrGen_auto_in_rlast; // @[SimMMIO.scala 38:27]
  wire [63:0] intrGen_io_extra_intrVec; // @[SimMMIO.scala 38:27]
  wire  axi4xbar_clock; // @[Xbar.scala 218:30]
  wire  axi4xbar_reset; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_awid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_in_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_in_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_in_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_in_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_arready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_arid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_in_araddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_in_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_arcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_in_arprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_in_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_rid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_in_rdata; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_in_rresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_in_rlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_awid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_5_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_5_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_5_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_5_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_arready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_arid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_5_araddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_5_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_arcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_5_arprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_5_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_rid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_5_rdata; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_5_rresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_5_rlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_awid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_4_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_4_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_4_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_4_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_arready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_arid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_4_araddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_4_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_arcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_4_arprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_4_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_rid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_4_rdata; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_4_rresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_4_rlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_awid; // @[Xbar.scala 218:30]
  wire [28:0] axi4xbar_auto_out_3_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_3_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_3_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_3_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_arready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_arid; // @[Xbar.scala 218:30]
  wire [28:0] axi4xbar_auto_out_3_araddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_3_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_arcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_3_arprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_3_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_rid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_3_rdata; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_3_rresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_3_rlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_awid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_2_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_2_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_2_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_2_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_arready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_arid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_2_araddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_2_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_arcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_2_arprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_2_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_rid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_2_rdata; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_2_rresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_2_rlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_awid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_1_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_1_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_1_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_1_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_1_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_1_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_arid; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_1_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_1_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_arcache; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_1_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_1_rid; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_1_rlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_awready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_awvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_awid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_0_awaddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_0_awlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_awsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_awburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_awlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_awcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_awprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_awqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_wready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_wvalid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_0_wdata; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_0_wstrb; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_wlast; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_bready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_bvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_bid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_bresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_arready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_arvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_arid; // @[Xbar.scala 218:30]
  wire [30:0] axi4xbar_auto_out_0_araddr; // @[Xbar.scala 218:30]
  wire [7:0] axi4xbar_auto_out_0_arlen; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_arsize; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_arburst; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_arlock; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_arcache; // @[Xbar.scala 218:30]
  wire [2:0] axi4xbar_auto_out_0_arprot; // @[Xbar.scala 218:30]
  wire [3:0] axi4xbar_auto_out_0_arqos; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_rready; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_rvalid; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_rid; // @[Xbar.scala 218:30]
  wire [63:0] axi4xbar_auto_out_0_rdata; // @[Xbar.scala 218:30]
  wire [1:0] axi4xbar_auto_out_0_rresp; // @[Xbar.scala 218:30]
  wire  axi4xbar_auto_out_0_rlast; // @[Xbar.scala 218:30]
  AXI4Flash flash ( // @[SimMMIO.scala 30:25]
    .clock(flash_clock),
    .reset(flash_reset),
    .auto_in_awready(flash_auto_in_awready),
    .auto_in_awvalid(flash_auto_in_awvalid),
    .auto_in_awid(flash_auto_in_awid),
    .auto_in_awaddr(flash_auto_in_awaddr),
    .auto_in_awlen(flash_auto_in_awlen),
    .auto_in_awsize(flash_auto_in_awsize),
    .auto_in_awburst(flash_auto_in_awburst),
    .auto_in_awlock(flash_auto_in_awlock),
    .auto_in_awcache(flash_auto_in_awcache),
    .auto_in_awprot(flash_auto_in_awprot),
    .auto_in_awqos(flash_auto_in_awqos),
    .auto_in_wready(flash_auto_in_wready),
    .auto_in_wvalid(flash_auto_in_wvalid),
    .auto_in_wdata(flash_auto_in_wdata),
    .auto_in_wstrb(flash_auto_in_wstrb),
    .auto_in_wlast(flash_auto_in_wlast),
    .auto_in_bready(flash_auto_in_bready),
    .auto_in_bvalid(flash_auto_in_bvalid),
    .auto_in_bid(flash_auto_in_bid),
    .auto_in_bresp(flash_auto_in_bresp),
    .auto_in_arready(flash_auto_in_arready),
    .auto_in_arvalid(flash_auto_in_arvalid),
    .auto_in_arid(flash_auto_in_arid),
    .auto_in_araddr(flash_auto_in_araddr),
    .auto_in_arlen(flash_auto_in_arlen),
    .auto_in_arsize(flash_auto_in_arsize),
    .auto_in_arburst(flash_auto_in_arburst),
    .auto_in_arlock(flash_auto_in_arlock),
    .auto_in_arcache(flash_auto_in_arcache),
    .auto_in_arprot(flash_auto_in_arprot),
    .auto_in_arqos(flash_auto_in_arqos),
    .auto_in_rready(flash_auto_in_rready),
    .auto_in_rvalid(flash_auto_in_rvalid),
    .auto_in_rid(flash_auto_in_rid),
    .auto_in_rdata(flash_auto_in_rdata),
    .auto_in_rresp(flash_auto_in_rresp),
    .auto_in_rlast(flash_auto_in_rlast)
  );
  AXI4UART uart ( // @[SimMMIO.scala 31:24]
    .clock(uart_clock),
    .reset(uart_reset),
    .auto_in_awready(uart_auto_in_awready),
    .auto_in_awvalid(uart_auto_in_awvalid),
    .auto_in_awid(uart_auto_in_awid),
    .auto_in_awaddr(uart_auto_in_awaddr),
    .auto_in_awlen(uart_auto_in_awlen),
    .auto_in_awsize(uart_auto_in_awsize),
    .auto_in_awburst(uart_auto_in_awburst),
    .auto_in_awlock(uart_auto_in_awlock),
    .auto_in_awcache(uart_auto_in_awcache),
    .auto_in_awprot(uart_auto_in_awprot),
    .auto_in_awqos(uart_auto_in_awqos),
    .auto_in_wready(uart_auto_in_wready),
    .auto_in_wvalid(uart_auto_in_wvalid),
    .auto_in_wdata(uart_auto_in_wdata),
    .auto_in_wstrb(uart_auto_in_wstrb),
    .auto_in_wlast(uart_auto_in_wlast),
    .auto_in_bready(uart_auto_in_bready),
    .auto_in_bvalid(uart_auto_in_bvalid),
    .auto_in_bid(uart_auto_in_bid),
    .auto_in_bresp(uart_auto_in_bresp),
    .auto_in_arready(uart_auto_in_arready),
    .auto_in_arvalid(uart_auto_in_arvalid),
    .auto_in_arid(uart_auto_in_arid),
    .auto_in_araddr(uart_auto_in_araddr),
    .auto_in_arlen(uart_auto_in_arlen),
    .auto_in_arsize(uart_auto_in_arsize),
    .auto_in_arburst(uart_auto_in_arburst),
    .auto_in_arlock(uart_auto_in_arlock),
    .auto_in_arcache(uart_auto_in_arcache),
    .auto_in_arprot(uart_auto_in_arprot),
    .auto_in_arqos(uart_auto_in_arqos),
    .auto_in_rready(uart_auto_in_rready),
    .auto_in_rvalid(uart_auto_in_rvalid),
    .auto_in_rid(uart_auto_in_rid),
    .auto_in_rdata(uart_auto_in_rdata),
    .auto_in_rresp(uart_auto_in_rresp),
    .auto_in_rlast(uart_auto_in_rlast),
    .io_extra_out_valid(uart_io_extra_out_valid),
    .io_extra_out_ch(uart_io_extra_out_ch),
    .io_extra_in_valid(uart_io_extra_in_valid),
    .io_extra_in_ch(uart_io_extra_in_ch)
  );
  AXI4VGA vga ( // @[SimMMIO.scala 32:23]
    .clock(vga_clock),
    .reset(vga_reset),
    .auto_in_1_awready(vga_auto_in_1_awready),
    .auto_in_1_awvalid(vga_auto_in_1_awvalid),
    .auto_in_1_awid(vga_auto_in_1_awid),
    .auto_in_1_awaddr(vga_auto_in_1_awaddr),
    .auto_in_1_awlen(vga_auto_in_1_awlen),
    .auto_in_1_awsize(vga_auto_in_1_awsize),
    .auto_in_1_awburst(vga_auto_in_1_awburst),
    .auto_in_1_awlock(vga_auto_in_1_awlock),
    .auto_in_1_awcache(vga_auto_in_1_awcache),
    .auto_in_1_awprot(vga_auto_in_1_awprot),
    .auto_in_1_awqos(vga_auto_in_1_awqos),
    .auto_in_1_wready(vga_auto_in_1_wready),
    .auto_in_1_wvalid(vga_auto_in_1_wvalid),
    .auto_in_1_wdata(vga_auto_in_1_wdata),
    .auto_in_1_wstrb(vga_auto_in_1_wstrb),
    .auto_in_1_wlast(vga_auto_in_1_wlast),
    .auto_in_1_bready(vga_auto_in_1_bready),
    .auto_in_1_bvalid(vga_auto_in_1_bvalid),
    .auto_in_1_bid(vga_auto_in_1_bid),
    .auto_in_1_bresp(vga_auto_in_1_bresp),
    .auto_in_1_arready(vga_auto_in_1_arready),
    .auto_in_1_arvalid(vga_auto_in_1_arvalid),
    .auto_in_1_arid(vga_auto_in_1_arid),
    .auto_in_1_araddr(vga_auto_in_1_araddr),
    .auto_in_1_arlen(vga_auto_in_1_arlen),
    .auto_in_1_arsize(vga_auto_in_1_arsize),
    .auto_in_1_arburst(vga_auto_in_1_arburst),
    .auto_in_1_arlock(vga_auto_in_1_arlock),
    .auto_in_1_arcache(vga_auto_in_1_arcache),
    .auto_in_1_arprot(vga_auto_in_1_arprot),
    .auto_in_1_arqos(vga_auto_in_1_arqos),
    .auto_in_1_rready(vga_auto_in_1_rready),
    .auto_in_1_rvalid(vga_auto_in_1_rvalid),
    .auto_in_1_rid(vga_auto_in_1_rid),
    .auto_in_1_rdata(vga_auto_in_1_rdata),
    .auto_in_1_rresp(vga_auto_in_1_rresp),
    .auto_in_1_rlast(vga_auto_in_1_rlast),
    .auto_in_0_awready(vga_auto_in_0_awready),
    .auto_in_0_awvalid(vga_auto_in_0_awvalid),
    .auto_in_0_awid(vga_auto_in_0_awid),
    .auto_in_0_awaddr(vga_auto_in_0_awaddr),
    .auto_in_0_awlen(vga_auto_in_0_awlen),
    .auto_in_0_awsize(vga_auto_in_0_awsize),
    .auto_in_0_awburst(vga_auto_in_0_awburst),
    .auto_in_0_awlock(vga_auto_in_0_awlock),
    .auto_in_0_awcache(vga_auto_in_0_awcache),
    .auto_in_0_awprot(vga_auto_in_0_awprot),
    .auto_in_0_awqos(vga_auto_in_0_awqos),
    .auto_in_0_wready(vga_auto_in_0_wready),
    .auto_in_0_wvalid(vga_auto_in_0_wvalid),
    .auto_in_0_wdata(vga_auto_in_0_wdata),
    .auto_in_0_wstrb(vga_auto_in_0_wstrb),
    .auto_in_0_wlast(vga_auto_in_0_wlast),
    .auto_in_0_bready(vga_auto_in_0_bready),
    .auto_in_0_bvalid(vga_auto_in_0_bvalid),
    .auto_in_0_bid(vga_auto_in_0_bid),
    .auto_in_0_bresp(vga_auto_in_0_bresp),
    .auto_in_0_arvalid(vga_auto_in_0_arvalid),
    .auto_in_0_arid(vga_auto_in_0_arid),
    .auto_in_0_arlen(vga_auto_in_0_arlen),
    .auto_in_0_arsize(vga_auto_in_0_arsize),
    .auto_in_0_arburst(vga_auto_in_0_arburst),
    .auto_in_0_arlock(vga_auto_in_0_arlock),
    .auto_in_0_arcache(vga_auto_in_0_arcache),
    .auto_in_0_arqos(vga_auto_in_0_arqos),
    .auto_in_0_rready(vga_auto_in_0_rready),
    .auto_in_0_rvalid(vga_auto_in_0_rvalid),
    .auto_in_0_rid(vga_auto_in_0_rid),
    .auto_in_0_rlast(vga_auto_in_0_rlast)
  );
  AXI4DummySD sd ( // @[SimMMIO.scala 37:22]
    .clock(sd_clock),
    .reset(sd_reset),
    .auto_in_awready(sd_auto_in_awready),
    .auto_in_awvalid(sd_auto_in_awvalid),
    .auto_in_awid(sd_auto_in_awid),
    .auto_in_awaddr(sd_auto_in_awaddr),
    .auto_in_awlen(sd_auto_in_awlen),
    .auto_in_awsize(sd_auto_in_awsize),
    .auto_in_awburst(sd_auto_in_awburst),
    .auto_in_awlock(sd_auto_in_awlock),
    .auto_in_awcache(sd_auto_in_awcache),
    .auto_in_awprot(sd_auto_in_awprot),
    .auto_in_awqos(sd_auto_in_awqos),
    .auto_in_wready(sd_auto_in_wready),
    .auto_in_wvalid(sd_auto_in_wvalid),
    .auto_in_wdata(sd_auto_in_wdata),
    .auto_in_wstrb(sd_auto_in_wstrb),
    .auto_in_wlast(sd_auto_in_wlast),
    .auto_in_bready(sd_auto_in_bready),
    .auto_in_bvalid(sd_auto_in_bvalid),
    .auto_in_bid(sd_auto_in_bid),
    .auto_in_bresp(sd_auto_in_bresp),
    .auto_in_arready(sd_auto_in_arready),
    .auto_in_arvalid(sd_auto_in_arvalid),
    .auto_in_arid(sd_auto_in_arid),
    .auto_in_araddr(sd_auto_in_araddr),
    .auto_in_arlen(sd_auto_in_arlen),
    .auto_in_arsize(sd_auto_in_arsize),
    .auto_in_arburst(sd_auto_in_arburst),
    .auto_in_arlock(sd_auto_in_arlock),
    .auto_in_arcache(sd_auto_in_arcache),
    .auto_in_arprot(sd_auto_in_arprot),
    .auto_in_arqos(sd_auto_in_arqos),
    .auto_in_rready(sd_auto_in_rready),
    .auto_in_rvalid(sd_auto_in_rvalid),
    .auto_in_rid(sd_auto_in_rid),
    .auto_in_rdata(sd_auto_in_rdata),
    .auto_in_rresp(sd_auto_in_rresp),
    .auto_in_rlast(sd_auto_in_rlast)
  );
  AXI4IntrGenerator intrGen ( // @[SimMMIO.scala 38:27]
    .clock(intrGen_clock),
    .reset(intrGen_reset),
    .auto_in_awready(intrGen_auto_in_awready),
    .auto_in_awvalid(intrGen_auto_in_awvalid),
    .auto_in_awid(intrGen_auto_in_awid),
    .auto_in_awaddr(intrGen_auto_in_awaddr),
    .auto_in_awlen(intrGen_auto_in_awlen),
    .auto_in_awsize(intrGen_auto_in_awsize),
    .auto_in_awburst(intrGen_auto_in_awburst),
    .auto_in_awlock(intrGen_auto_in_awlock),
    .auto_in_awcache(intrGen_auto_in_awcache),
    .auto_in_awprot(intrGen_auto_in_awprot),
    .auto_in_awqos(intrGen_auto_in_awqos),
    .auto_in_wready(intrGen_auto_in_wready),
    .auto_in_wvalid(intrGen_auto_in_wvalid),
    .auto_in_wdata(intrGen_auto_in_wdata),
    .auto_in_wstrb(intrGen_auto_in_wstrb),
    .auto_in_wlast(intrGen_auto_in_wlast),
    .auto_in_bready(intrGen_auto_in_bready),
    .auto_in_bvalid(intrGen_auto_in_bvalid),
    .auto_in_bid(intrGen_auto_in_bid),
    .auto_in_bresp(intrGen_auto_in_bresp),
    .auto_in_arready(intrGen_auto_in_arready),
    .auto_in_arvalid(intrGen_auto_in_arvalid),
    .auto_in_arid(intrGen_auto_in_arid),
    .auto_in_araddr(intrGen_auto_in_araddr),
    .auto_in_arlen(intrGen_auto_in_arlen),
    .auto_in_arsize(intrGen_auto_in_arsize),
    .auto_in_arburst(intrGen_auto_in_arburst),
    .auto_in_arlock(intrGen_auto_in_arlock),
    .auto_in_arcache(intrGen_auto_in_arcache),
    .auto_in_arprot(intrGen_auto_in_arprot),
    .auto_in_arqos(intrGen_auto_in_arqos),
    .auto_in_rready(intrGen_auto_in_rready),
    .auto_in_rvalid(intrGen_auto_in_rvalid),
    .auto_in_rid(intrGen_auto_in_rid),
    .auto_in_rdata(intrGen_auto_in_rdata),
    .auto_in_rresp(intrGen_auto_in_rresp),
    .auto_in_rlast(intrGen_auto_in_rlast),
    .io_extra_intrVec(intrGen_io_extra_intrVec)
  );
  AXI4Xbar axi4xbar ( // @[Xbar.scala 218:30]
    .clock(axi4xbar_clock),
    .reset(axi4xbar_reset),
    .auto_in_awready(axi4xbar_auto_in_awready),
    .auto_in_awvalid(axi4xbar_auto_in_awvalid),
    .auto_in_awid(axi4xbar_auto_in_awid),
    .auto_in_awaddr(axi4xbar_auto_in_awaddr),
    .auto_in_awlen(axi4xbar_auto_in_awlen),
    .auto_in_awsize(axi4xbar_auto_in_awsize),
    .auto_in_awburst(axi4xbar_auto_in_awburst),
    .auto_in_awlock(axi4xbar_auto_in_awlock),
    .auto_in_awcache(axi4xbar_auto_in_awcache),
    .auto_in_awprot(axi4xbar_auto_in_awprot),
    .auto_in_awqos(axi4xbar_auto_in_awqos),
    .auto_in_wready(axi4xbar_auto_in_wready),
    .auto_in_wvalid(axi4xbar_auto_in_wvalid),
    .auto_in_wdata(axi4xbar_auto_in_wdata),
    .auto_in_wstrb(axi4xbar_auto_in_wstrb),
    .auto_in_wlast(axi4xbar_auto_in_wlast),
    .auto_in_bready(axi4xbar_auto_in_bready),
    .auto_in_bvalid(axi4xbar_auto_in_bvalid),
    .auto_in_bid(axi4xbar_auto_in_bid),
    .auto_in_bresp(axi4xbar_auto_in_bresp),
    .auto_in_arready(axi4xbar_auto_in_arready),
    .auto_in_arvalid(axi4xbar_auto_in_arvalid),
    .auto_in_arid(axi4xbar_auto_in_arid),
    .auto_in_araddr(axi4xbar_auto_in_araddr),
    .auto_in_arlen(axi4xbar_auto_in_arlen),
    .auto_in_arsize(axi4xbar_auto_in_arsize),
    .auto_in_arburst(axi4xbar_auto_in_arburst),
    .auto_in_arlock(axi4xbar_auto_in_arlock),
    .auto_in_arcache(axi4xbar_auto_in_arcache),
    .auto_in_arprot(axi4xbar_auto_in_arprot),
    .auto_in_arqos(axi4xbar_auto_in_arqos),
    .auto_in_rready(axi4xbar_auto_in_rready),
    .auto_in_rvalid(axi4xbar_auto_in_rvalid),
    .auto_in_rid(axi4xbar_auto_in_rid),
    .auto_in_rdata(axi4xbar_auto_in_rdata),
    .auto_in_rresp(axi4xbar_auto_in_rresp),
    .auto_in_rlast(axi4xbar_auto_in_rlast),
    .auto_out_5_awready(axi4xbar_auto_out_5_awready),
    .auto_out_5_awvalid(axi4xbar_auto_out_5_awvalid),
    .auto_out_5_awid(axi4xbar_auto_out_5_awid),
    .auto_out_5_awaddr(axi4xbar_auto_out_5_awaddr),
    .auto_out_5_awlen(axi4xbar_auto_out_5_awlen),
    .auto_out_5_awsize(axi4xbar_auto_out_5_awsize),
    .auto_out_5_awburst(axi4xbar_auto_out_5_awburst),
    .auto_out_5_awlock(axi4xbar_auto_out_5_awlock),
    .auto_out_5_awcache(axi4xbar_auto_out_5_awcache),
    .auto_out_5_awprot(axi4xbar_auto_out_5_awprot),
    .auto_out_5_awqos(axi4xbar_auto_out_5_awqos),
    .auto_out_5_wready(axi4xbar_auto_out_5_wready),
    .auto_out_5_wvalid(axi4xbar_auto_out_5_wvalid),
    .auto_out_5_wdata(axi4xbar_auto_out_5_wdata),
    .auto_out_5_wstrb(axi4xbar_auto_out_5_wstrb),
    .auto_out_5_wlast(axi4xbar_auto_out_5_wlast),
    .auto_out_5_bready(axi4xbar_auto_out_5_bready),
    .auto_out_5_bvalid(axi4xbar_auto_out_5_bvalid),
    .auto_out_5_bid(axi4xbar_auto_out_5_bid),
    .auto_out_5_bresp(axi4xbar_auto_out_5_bresp),
    .auto_out_5_arready(axi4xbar_auto_out_5_arready),
    .auto_out_5_arvalid(axi4xbar_auto_out_5_arvalid),
    .auto_out_5_arid(axi4xbar_auto_out_5_arid),
    .auto_out_5_araddr(axi4xbar_auto_out_5_araddr),
    .auto_out_5_arlen(axi4xbar_auto_out_5_arlen),
    .auto_out_5_arsize(axi4xbar_auto_out_5_arsize),
    .auto_out_5_arburst(axi4xbar_auto_out_5_arburst),
    .auto_out_5_arlock(axi4xbar_auto_out_5_arlock),
    .auto_out_5_arcache(axi4xbar_auto_out_5_arcache),
    .auto_out_5_arprot(axi4xbar_auto_out_5_arprot),
    .auto_out_5_arqos(axi4xbar_auto_out_5_arqos),
    .auto_out_5_rready(axi4xbar_auto_out_5_rready),
    .auto_out_5_rvalid(axi4xbar_auto_out_5_rvalid),
    .auto_out_5_rid(axi4xbar_auto_out_5_rid),
    .auto_out_5_rdata(axi4xbar_auto_out_5_rdata),
    .auto_out_5_rresp(axi4xbar_auto_out_5_rresp),
    .auto_out_5_rlast(axi4xbar_auto_out_5_rlast),
    .auto_out_4_awready(axi4xbar_auto_out_4_awready),
    .auto_out_4_awvalid(axi4xbar_auto_out_4_awvalid),
    .auto_out_4_awid(axi4xbar_auto_out_4_awid),
    .auto_out_4_awaddr(axi4xbar_auto_out_4_awaddr),
    .auto_out_4_awlen(axi4xbar_auto_out_4_awlen),
    .auto_out_4_awsize(axi4xbar_auto_out_4_awsize),
    .auto_out_4_awburst(axi4xbar_auto_out_4_awburst),
    .auto_out_4_awlock(axi4xbar_auto_out_4_awlock),
    .auto_out_4_awcache(axi4xbar_auto_out_4_awcache),
    .auto_out_4_awprot(axi4xbar_auto_out_4_awprot),
    .auto_out_4_awqos(axi4xbar_auto_out_4_awqos),
    .auto_out_4_wready(axi4xbar_auto_out_4_wready),
    .auto_out_4_wvalid(axi4xbar_auto_out_4_wvalid),
    .auto_out_4_wdata(axi4xbar_auto_out_4_wdata),
    .auto_out_4_wstrb(axi4xbar_auto_out_4_wstrb),
    .auto_out_4_wlast(axi4xbar_auto_out_4_wlast),
    .auto_out_4_bready(axi4xbar_auto_out_4_bready),
    .auto_out_4_bvalid(axi4xbar_auto_out_4_bvalid),
    .auto_out_4_bid(axi4xbar_auto_out_4_bid),
    .auto_out_4_bresp(axi4xbar_auto_out_4_bresp),
    .auto_out_4_arready(axi4xbar_auto_out_4_arready),
    .auto_out_4_arvalid(axi4xbar_auto_out_4_arvalid),
    .auto_out_4_arid(axi4xbar_auto_out_4_arid),
    .auto_out_4_araddr(axi4xbar_auto_out_4_araddr),
    .auto_out_4_arlen(axi4xbar_auto_out_4_arlen),
    .auto_out_4_arsize(axi4xbar_auto_out_4_arsize),
    .auto_out_4_arburst(axi4xbar_auto_out_4_arburst),
    .auto_out_4_arlock(axi4xbar_auto_out_4_arlock),
    .auto_out_4_arcache(axi4xbar_auto_out_4_arcache),
    .auto_out_4_arprot(axi4xbar_auto_out_4_arprot),
    .auto_out_4_arqos(axi4xbar_auto_out_4_arqos),
    .auto_out_4_rready(axi4xbar_auto_out_4_rready),
    .auto_out_4_rvalid(axi4xbar_auto_out_4_rvalid),
    .auto_out_4_rid(axi4xbar_auto_out_4_rid),
    .auto_out_4_rdata(axi4xbar_auto_out_4_rdata),
    .auto_out_4_rresp(axi4xbar_auto_out_4_rresp),
    .auto_out_4_rlast(axi4xbar_auto_out_4_rlast),
    .auto_out_3_awready(axi4xbar_auto_out_3_awready),
    .auto_out_3_awvalid(axi4xbar_auto_out_3_awvalid),
    .auto_out_3_awid(axi4xbar_auto_out_3_awid),
    .auto_out_3_awaddr(axi4xbar_auto_out_3_awaddr),
    .auto_out_3_awlen(axi4xbar_auto_out_3_awlen),
    .auto_out_3_awsize(axi4xbar_auto_out_3_awsize),
    .auto_out_3_awburst(axi4xbar_auto_out_3_awburst),
    .auto_out_3_awlock(axi4xbar_auto_out_3_awlock),
    .auto_out_3_awcache(axi4xbar_auto_out_3_awcache),
    .auto_out_3_awprot(axi4xbar_auto_out_3_awprot),
    .auto_out_3_awqos(axi4xbar_auto_out_3_awqos),
    .auto_out_3_wready(axi4xbar_auto_out_3_wready),
    .auto_out_3_wvalid(axi4xbar_auto_out_3_wvalid),
    .auto_out_3_wdata(axi4xbar_auto_out_3_wdata),
    .auto_out_3_wstrb(axi4xbar_auto_out_3_wstrb),
    .auto_out_3_wlast(axi4xbar_auto_out_3_wlast),
    .auto_out_3_bready(axi4xbar_auto_out_3_bready),
    .auto_out_3_bvalid(axi4xbar_auto_out_3_bvalid),
    .auto_out_3_bid(axi4xbar_auto_out_3_bid),
    .auto_out_3_bresp(axi4xbar_auto_out_3_bresp),
    .auto_out_3_arready(axi4xbar_auto_out_3_arready),
    .auto_out_3_arvalid(axi4xbar_auto_out_3_arvalid),
    .auto_out_3_arid(axi4xbar_auto_out_3_arid),
    .auto_out_3_araddr(axi4xbar_auto_out_3_araddr),
    .auto_out_3_arlen(axi4xbar_auto_out_3_arlen),
    .auto_out_3_arsize(axi4xbar_auto_out_3_arsize),
    .auto_out_3_arburst(axi4xbar_auto_out_3_arburst),
    .auto_out_3_arlock(axi4xbar_auto_out_3_arlock),
    .auto_out_3_arcache(axi4xbar_auto_out_3_arcache),
    .auto_out_3_arprot(axi4xbar_auto_out_3_arprot),
    .auto_out_3_arqos(axi4xbar_auto_out_3_arqos),
    .auto_out_3_rready(axi4xbar_auto_out_3_rready),
    .auto_out_3_rvalid(axi4xbar_auto_out_3_rvalid),
    .auto_out_3_rid(axi4xbar_auto_out_3_rid),
    .auto_out_3_rdata(axi4xbar_auto_out_3_rdata),
    .auto_out_3_rresp(axi4xbar_auto_out_3_rresp),
    .auto_out_3_rlast(axi4xbar_auto_out_3_rlast),
    .auto_out_2_awready(axi4xbar_auto_out_2_awready),
    .auto_out_2_awvalid(axi4xbar_auto_out_2_awvalid),
    .auto_out_2_awid(axi4xbar_auto_out_2_awid),
    .auto_out_2_awaddr(axi4xbar_auto_out_2_awaddr),
    .auto_out_2_awlen(axi4xbar_auto_out_2_awlen),
    .auto_out_2_awsize(axi4xbar_auto_out_2_awsize),
    .auto_out_2_awburst(axi4xbar_auto_out_2_awburst),
    .auto_out_2_awlock(axi4xbar_auto_out_2_awlock),
    .auto_out_2_awcache(axi4xbar_auto_out_2_awcache),
    .auto_out_2_awprot(axi4xbar_auto_out_2_awprot),
    .auto_out_2_awqos(axi4xbar_auto_out_2_awqos),
    .auto_out_2_wready(axi4xbar_auto_out_2_wready),
    .auto_out_2_wvalid(axi4xbar_auto_out_2_wvalid),
    .auto_out_2_wdata(axi4xbar_auto_out_2_wdata),
    .auto_out_2_wstrb(axi4xbar_auto_out_2_wstrb),
    .auto_out_2_wlast(axi4xbar_auto_out_2_wlast),
    .auto_out_2_bready(axi4xbar_auto_out_2_bready),
    .auto_out_2_bvalid(axi4xbar_auto_out_2_bvalid),
    .auto_out_2_bid(axi4xbar_auto_out_2_bid),
    .auto_out_2_bresp(axi4xbar_auto_out_2_bresp),
    .auto_out_2_arready(axi4xbar_auto_out_2_arready),
    .auto_out_2_arvalid(axi4xbar_auto_out_2_arvalid),
    .auto_out_2_arid(axi4xbar_auto_out_2_arid),
    .auto_out_2_araddr(axi4xbar_auto_out_2_araddr),
    .auto_out_2_arlen(axi4xbar_auto_out_2_arlen),
    .auto_out_2_arsize(axi4xbar_auto_out_2_arsize),
    .auto_out_2_arburst(axi4xbar_auto_out_2_arburst),
    .auto_out_2_arlock(axi4xbar_auto_out_2_arlock),
    .auto_out_2_arcache(axi4xbar_auto_out_2_arcache),
    .auto_out_2_arprot(axi4xbar_auto_out_2_arprot),
    .auto_out_2_arqos(axi4xbar_auto_out_2_arqos),
    .auto_out_2_rready(axi4xbar_auto_out_2_rready),
    .auto_out_2_rvalid(axi4xbar_auto_out_2_rvalid),
    .auto_out_2_rid(axi4xbar_auto_out_2_rid),
    .auto_out_2_rdata(axi4xbar_auto_out_2_rdata),
    .auto_out_2_rresp(axi4xbar_auto_out_2_rresp),
    .auto_out_2_rlast(axi4xbar_auto_out_2_rlast),
    .auto_out_1_awready(axi4xbar_auto_out_1_awready),
    .auto_out_1_awvalid(axi4xbar_auto_out_1_awvalid),
    .auto_out_1_awid(axi4xbar_auto_out_1_awid),
    .auto_out_1_awaddr(axi4xbar_auto_out_1_awaddr),
    .auto_out_1_awlen(axi4xbar_auto_out_1_awlen),
    .auto_out_1_awsize(axi4xbar_auto_out_1_awsize),
    .auto_out_1_awburst(axi4xbar_auto_out_1_awburst),
    .auto_out_1_awlock(axi4xbar_auto_out_1_awlock),
    .auto_out_1_awcache(axi4xbar_auto_out_1_awcache),
    .auto_out_1_awprot(axi4xbar_auto_out_1_awprot),
    .auto_out_1_awqos(axi4xbar_auto_out_1_awqos),
    .auto_out_1_wready(axi4xbar_auto_out_1_wready),
    .auto_out_1_wvalid(axi4xbar_auto_out_1_wvalid),
    .auto_out_1_wdata(axi4xbar_auto_out_1_wdata),
    .auto_out_1_wstrb(axi4xbar_auto_out_1_wstrb),
    .auto_out_1_wlast(axi4xbar_auto_out_1_wlast),
    .auto_out_1_bready(axi4xbar_auto_out_1_bready),
    .auto_out_1_bvalid(axi4xbar_auto_out_1_bvalid),
    .auto_out_1_bid(axi4xbar_auto_out_1_bid),
    .auto_out_1_bresp(axi4xbar_auto_out_1_bresp),
    .auto_out_1_arvalid(axi4xbar_auto_out_1_arvalid),
    .auto_out_1_arid(axi4xbar_auto_out_1_arid),
    .auto_out_1_arlen(axi4xbar_auto_out_1_arlen),
    .auto_out_1_arsize(axi4xbar_auto_out_1_arsize),
    .auto_out_1_arburst(axi4xbar_auto_out_1_arburst),
    .auto_out_1_arlock(axi4xbar_auto_out_1_arlock),
    .auto_out_1_arcache(axi4xbar_auto_out_1_arcache),
    .auto_out_1_arqos(axi4xbar_auto_out_1_arqos),
    .auto_out_1_rready(axi4xbar_auto_out_1_rready),
    .auto_out_1_rvalid(axi4xbar_auto_out_1_rvalid),
    .auto_out_1_rid(axi4xbar_auto_out_1_rid),
    .auto_out_1_rlast(axi4xbar_auto_out_1_rlast),
    .auto_out_0_awready(axi4xbar_auto_out_0_awready),
    .auto_out_0_awvalid(axi4xbar_auto_out_0_awvalid),
    .auto_out_0_awid(axi4xbar_auto_out_0_awid),
    .auto_out_0_awaddr(axi4xbar_auto_out_0_awaddr),
    .auto_out_0_awlen(axi4xbar_auto_out_0_awlen),
    .auto_out_0_awsize(axi4xbar_auto_out_0_awsize),
    .auto_out_0_awburst(axi4xbar_auto_out_0_awburst),
    .auto_out_0_awlock(axi4xbar_auto_out_0_awlock),
    .auto_out_0_awcache(axi4xbar_auto_out_0_awcache),
    .auto_out_0_awprot(axi4xbar_auto_out_0_awprot),
    .auto_out_0_awqos(axi4xbar_auto_out_0_awqos),
    .auto_out_0_wready(axi4xbar_auto_out_0_wready),
    .auto_out_0_wvalid(axi4xbar_auto_out_0_wvalid),
    .auto_out_0_wdata(axi4xbar_auto_out_0_wdata),
    .auto_out_0_wstrb(axi4xbar_auto_out_0_wstrb),
    .auto_out_0_wlast(axi4xbar_auto_out_0_wlast),
    .auto_out_0_bready(axi4xbar_auto_out_0_bready),
    .auto_out_0_bvalid(axi4xbar_auto_out_0_bvalid),
    .auto_out_0_bid(axi4xbar_auto_out_0_bid),
    .auto_out_0_bresp(axi4xbar_auto_out_0_bresp),
    .auto_out_0_arready(axi4xbar_auto_out_0_arready),
    .auto_out_0_arvalid(axi4xbar_auto_out_0_arvalid),
    .auto_out_0_arid(axi4xbar_auto_out_0_arid),
    .auto_out_0_araddr(axi4xbar_auto_out_0_araddr),
    .auto_out_0_arlen(axi4xbar_auto_out_0_arlen),
    .auto_out_0_arsize(axi4xbar_auto_out_0_arsize),
    .auto_out_0_arburst(axi4xbar_auto_out_0_arburst),
    .auto_out_0_arlock(axi4xbar_auto_out_0_arlock),
    .auto_out_0_arcache(axi4xbar_auto_out_0_arcache),
    .auto_out_0_arprot(axi4xbar_auto_out_0_arprot),
    .auto_out_0_arqos(axi4xbar_auto_out_0_arqos),
    .auto_out_0_rready(axi4xbar_auto_out_0_rready),
    .auto_out_0_rvalid(axi4xbar_auto_out_0_rvalid),
    .auto_out_0_rid(axi4xbar_auto_out_0_rid),
    .auto_out_0_rdata(axi4xbar_auto_out_0_rdata),
    .auto_out_0_rresp(axi4xbar_auto_out_0_rresp),
    .auto_out_0_rlast(axi4xbar_auto_out_0_rlast)
  );
  assign io_axi4_0_awready = axi4xbar_auto_in_awready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_wready = axi4xbar_auto_in_wready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_bvalid = axi4xbar_auto_in_bvalid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_bid = axi4xbar_auto_in_bid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_bresp = axi4xbar_auto_in_bresp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_arready = axi4xbar_auto_in_arready; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_rvalid = axi4xbar_auto_in_rvalid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_rid = axi4xbar_auto_in_rid; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_rdata = axi4xbar_auto_in_rdata; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_rresp = axi4xbar_auto_in_rresp; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_axi4_0_rlast = axi4xbar_auto_in_rlast; // @[Nodes.scala 1207:84 LazyModule.scala 298:16]
  assign io_uart_out_valid = uart_io_extra_out_valid; // @[SimMMIO.scala 59:13]
  assign io_uart_out_ch = uart_io_extra_out_ch; // @[SimMMIO.scala 59:13]
  assign io_uart_in_valid = uart_io_extra_in_valid; // @[SimMMIO.scala 59:13]
  assign io_interrupt_intrVec = intrGen_io_extra_intrVec; // @[SimMMIO.scala 60:18]
  assign flash_clock = clock;
  assign flash_reset = reset;
  assign flash_auto_in_awvalid = axi4xbar_auto_out_3_awvalid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awid = axi4xbar_auto_out_3_awid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awaddr = axi4xbar_auto_out_3_awaddr; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awlen = axi4xbar_auto_out_3_awlen; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awsize = axi4xbar_auto_out_3_awsize; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awburst = axi4xbar_auto_out_3_awburst; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awlock = axi4xbar_auto_out_3_awlock; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awcache = axi4xbar_auto_out_3_awcache; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awprot = axi4xbar_auto_out_3_awprot; // @[LazyModule.scala 296:16]
  assign flash_auto_in_awqos = axi4xbar_auto_out_3_awqos; // @[LazyModule.scala 296:16]
  assign flash_auto_in_wvalid = axi4xbar_auto_out_3_wvalid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_wdata = axi4xbar_auto_out_3_wdata; // @[LazyModule.scala 296:16]
  assign flash_auto_in_wstrb = axi4xbar_auto_out_3_wstrb; // @[LazyModule.scala 296:16]
  assign flash_auto_in_wlast = axi4xbar_auto_out_3_wlast; // @[LazyModule.scala 296:16]
  assign flash_auto_in_bready = axi4xbar_auto_out_3_bready; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arvalid = axi4xbar_auto_out_3_arvalid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arid = axi4xbar_auto_out_3_arid; // @[LazyModule.scala 296:16]
  assign flash_auto_in_araddr = axi4xbar_auto_out_3_araddr; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arlen = axi4xbar_auto_out_3_arlen; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arsize = axi4xbar_auto_out_3_arsize; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arburst = axi4xbar_auto_out_3_arburst; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arlock = axi4xbar_auto_out_3_arlock; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arcache = axi4xbar_auto_out_3_arcache; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arprot = axi4xbar_auto_out_3_arprot; // @[LazyModule.scala 296:16]
  assign flash_auto_in_arqos = axi4xbar_auto_out_3_arqos; // @[LazyModule.scala 296:16]
  assign flash_auto_in_rready = axi4xbar_auto_out_3_rready; // @[LazyModule.scala 296:16]
  assign uart_clock = clock;
  assign uart_reset = reset;
  assign uart_auto_in_awvalid = axi4xbar_auto_out_0_awvalid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awid = axi4xbar_auto_out_0_awid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awaddr = axi4xbar_auto_out_0_awaddr; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awlen = axi4xbar_auto_out_0_awlen; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awsize = axi4xbar_auto_out_0_awsize; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awburst = axi4xbar_auto_out_0_awburst; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awlock = axi4xbar_auto_out_0_awlock; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awcache = axi4xbar_auto_out_0_awcache; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awprot = axi4xbar_auto_out_0_awprot; // @[LazyModule.scala 296:16]
  assign uart_auto_in_awqos = axi4xbar_auto_out_0_awqos; // @[LazyModule.scala 296:16]
  assign uart_auto_in_wvalid = axi4xbar_auto_out_0_wvalid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_wdata = axi4xbar_auto_out_0_wdata; // @[LazyModule.scala 296:16]
  assign uart_auto_in_wstrb = axi4xbar_auto_out_0_wstrb; // @[LazyModule.scala 296:16]
  assign uart_auto_in_wlast = axi4xbar_auto_out_0_wlast; // @[LazyModule.scala 296:16]
  assign uart_auto_in_bready = axi4xbar_auto_out_0_bready; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arvalid = axi4xbar_auto_out_0_arvalid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arid = axi4xbar_auto_out_0_arid; // @[LazyModule.scala 296:16]
  assign uart_auto_in_araddr = axi4xbar_auto_out_0_araddr; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arlen = axi4xbar_auto_out_0_arlen; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arsize = axi4xbar_auto_out_0_arsize; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arburst = axi4xbar_auto_out_0_arburst; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arlock = axi4xbar_auto_out_0_arlock; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arcache = axi4xbar_auto_out_0_arcache; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arprot = axi4xbar_auto_out_0_arprot; // @[LazyModule.scala 296:16]
  assign uart_auto_in_arqos = axi4xbar_auto_out_0_arqos; // @[LazyModule.scala 296:16]
  assign uart_auto_in_rready = axi4xbar_auto_out_0_rready; // @[LazyModule.scala 296:16]
  assign uart_io_extra_in_ch = io_uart_in_ch; // @[SimMMIO.scala 59:13]
  assign vga_clock = clock;
  assign vga_reset = reset;
  assign vga_auto_in_1_awvalid = axi4xbar_auto_out_2_awvalid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awid = axi4xbar_auto_out_2_awid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awaddr = axi4xbar_auto_out_2_awaddr; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awlen = axi4xbar_auto_out_2_awlen; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awsize = axi4xbar_auto_out_2_awsize; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awburst = axi4xbar_auto_out_2_awburst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awlock = axi4xbar_auto_out_2_awlock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awcache = axi4xbar_auto_out_2_awcache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awprot = axi4xbar_auto_out_2_awprot; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_awqos = axi4xbar_auto_out_2_awqos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_wvalid = axi4xbar_auto_out_2_wvalid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_wdata = axi4xbar_auto_out_2_wdata; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_wstrb = axi4xbar_auto_out_2_wstrb; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_wlast = axi4xbar_auto_out_2_wlast; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_bready = axi4xbar_auto_out_2_bready; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arvalid = axi4xbar_auto_out_2_arvalid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arid = axi4xbar_auto_out_2_arid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_araddr = axi4xbar_auto_out_2_araddr; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arlen = axi4xbar_auto_out_2_arlen; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arsize = axi4xbar_auto_out_2_arsize; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arburst = axi4xbar_auto_out_2_arburst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arlock = axi4xbar_auto_out_2_arlock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arcache = axi4xbar_auto_out_2_arcache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arprot = axi4xbar_auto_out_2_arprot; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_arqos = axi4xbar_auto_out_2_arqos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_1_rready = axi4xbar_auto_out_2_rready; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awvalid = axi4xbar_auto_out_1_awvalid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awid = axi4xbar_auto_out_1_awid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awaddr = axi4xbar_auto_out_1_awaddr; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awlen = axi4xbar_auto_out_1_awlen; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awsize = axi4xbar_auto_out_1_awsize; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awburst = axi4xbar_auto_out_1_awburst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awlock = axi4xbar_auto_out_1_awlock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awcache = axi4xbar_auto_out_1_awcache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awprot = axi4xbar_auto_out_1_awprot; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_awqos = axi4xbar_auto_out_1_awqos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_wvalid = axi4xbar_auto_out_1_wvalid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_wdata = axi4xbar_auto_out_1_wdata; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_wstrb = axi4xbar_auto_out_1_wstrb; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_wlast = axi4xbar_auto_out_1_wlast; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_bready = axi4xbar_auto_out_1_bready; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arvalid = axi4xbar_auto_out_1_arvalid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arid = axi4xbar_auto_out_1_arid; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arlen = axi4xbar_auto_out_1_arlen; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arsize = axi4xbar_auto_out_1_arsize; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arburst = axi4xbar_auto_out_1_arburst; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arlock = axi4xbar_auto_out_1_arlock; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arcache = axi4xbar_auto_out_1_arcache; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_arqos = axi4xbar_auto_out_1_arqos; // @[LazyModule.scala 296:16]
  assign vga_auto_in_0_rready = axi4xbar_auto_out_1_rready; // @[LazyModule.scala 296:16]
  assign sd_clock = clock;
  assign sd_reset = reset;
  assign sd_auto_in_awvalid = axi4xbar_auto_out_4_awvalid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awid = axi4xbar_auto_out_4_awid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awaddr = axi4xbar_auto_out_4_awaddr; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awlen = axi4xbar_auto_out_4_awlen; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awsize = axi4xbar_auto_out_4_awsize; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awburst = axi4xbar_auto_out_4_awburst; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awlock = axi4xbar_auto_out_4_awlock; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awcache = axi4xbar_auto_out_4_awcache; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awprot = axi4xbar_auto_out_4_awprot; // @[LazyModule.scala 296:16]
  assign sd_auto_in_awqos = axi4xbar_auto_out_4_awqos; // @[LazyModule.scala 296:16]
  assign sd_auto_in_wvalid = axi4xbar_auto_out_4_wvalid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_wdata = axi4xbar_auto_out_4_wdata; // @[LazyModule.scala 296:16]
  assign sd_auto_in_wstrb = axi4xbar_auto_out_4_wstrb; // @[LazyModule.scala 296:16]
  assign sd_auto_in_wlast = axi4xbar_auto_out_4_wlast; // @[LazyModule.scala 296:16]
  assign sd_auto_in_bready = axi4xbar_auto_out_4_bready; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arvalid = axi4xbar_auto_out_4_arvalid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arid = axi4xbar_auto_out_4_arid; // @[LazyModule.scala 296:16]
  assign sd_auto_in_araddr = axi4xbar_auto_out_4_araddr; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arlen = axi4xbar_auto_out_4_arlen; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arsize = axi4xbar_auto_out_4_arsize; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arburst = axi4xbar_auto_out_4_arburst; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arlock = axi4xbar_auto_out_4_arlock; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arcache = axi4xbar_auto_out_4_arcache; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arprot = axi4xbar_auto_out_4_arprot; // @[LazyModule.scala 296:16]
  assign sd_auto_in_arqos = axi4xbar_auto_out_4_arqos; // @[LazyModule.scala 296:16]
  assign sd_auto_in_rready = axi4xbar_auto_out_4_rready; // @[LazyModule.scala 296:16]
  assign intrGen_clock = clock;
  assign intrGen_reset = reset;
  assign intrGen_auto_in_awvalid = axi4xbar_auto_out_5_awvalid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awid = axi4xbar_auto_out_5_awid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awaddr = axi4xbar_auto_out_5_awaddr; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awlen = axi4xbar_auto_out_5_awlen; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awsize = axi4xbar_auto_out_5_awsize; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awburst = axi4xbar_auto_out_5_awburst; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awlock = axi4xbar_auto_out_5_awlock; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awcache = axi4xbar_auto_out_5_awcache; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awprot = axi4xbar_auto_out_5_awprot; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_awqos = axi4xbar_auto_out_5_awqos; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_wvalid = axi4xbar_auto_out_5_wvalid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_wdata = axi4xbar_auto_out_5_wdata; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_wstrb = axi4xbar_auto_out_5_wstrb; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_wlast = axi4xbar_auto_out_5_wlast; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_bready = axi4xbar_auto_out_5_bready; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arvalid = axi4xbar_auto_out_5_arvalid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arid = axi4xbar_auto_out_5_arid; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_araddr = axi4xbar_auto_out_5_araddr; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arlen = axi4xbar_auto_out_5_arlen; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arsize = axi4xbar_auto_out_5_arsize; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arburst = axi4xbar_auto_out_5_arburst; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arlock = axi4xbar_auto_out_5_arlock; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arcache = axi4xbar_auto_out_5_arcache; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arprot = axi4xbar_auto_out_5_arprot; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_arqos = axi4xbar_auto_out_5_arqos; // @[LazyModule.scala 296:16]
  assign intrGen_auto_in_rready = axi4xbar_auto_out_5_rready; // @[LazyModule.scala 296:16]
  assign axi4xbar_clock = clock;
  assign axi4xbar_reset = reset;
  assign axi4xbar_auto_in_awvalid = io_axi4_0_awvalid; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awid = io_axi4_0_awid; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awaddr = io_axi4_0_awaddr; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awlen = io_axi4_0_awlen; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awsize = io_axi4_0_awsize; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awburst = io_axi4_0_awburst; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awlock = io_axi4_0_awlock; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awcache = io_axi4_0_awcache; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awprot = io_axi4_0_awprot; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_awqos = io_axi4_0_awqos; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_wvalid = io_axi4_0_wvalid; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_wdata = io_axi4_0_wdata; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_wstrb = io_axi4_0_wstrb; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_wlast = io_axi4_0_wlast; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_bready = io_axi4_0_bready; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arvalid = io_axi4_0_arvalid; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arid = io_axi4_0_arid; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_araddr = io_axi4_0_araddr; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arlen = io_axi4_0_arlen; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arsize = io_axi4_0_arsize; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arburst = io_axi4_0_arburst; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arlock = io_axi4_0_arlock; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arcache = io_axi4_0_arcache; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arprot = io_axi4_0_arprot; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_arqos = io_axi4_0_arqos; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_in_rready = io_axi4_0_rready; // @[Nodes.scala 1207:84 1630:60]
  assign axi4xbar_auto_out_5_awready = intrGen_auto_in_awready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_wready = intrGen_auto_in_wready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_bvalid = intrGen_auto_in_bvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_bid = intrGen_auto_in_bid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_bresp = intrGen_auto_in_bresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_arready = intrGen_auto_in_arready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_rvalid = intrGen_auto_in_rvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_rid = intrGen_auto_in_rid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_rdata = intrGen_auto_in_rdata; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_rresp = intrGen_auto_in_rresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_5_rlast = intrGen_auto_in_rlast; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_awready = sd_auto_in_awready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_wready = sd_auto_in_wready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_bvalid = sd_auto_in_bvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_bid = sd_auto_in_bid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_bresp = sd_auto_in_bresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_arready = sd_auto_in_arready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_rvalid = sd_auto_in_rvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_rid = sd_auto_in_rid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_rdata = sd_auto_in_rdata; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_rresp = sd_auto_in_rresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_4_rlast = sd_auto_in_rlast; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_awready = flash_auto_in_awready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_wready = flash_auto_in_wready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_bvalid = flash_auto_in_bvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_bid = flash_auto_in_bid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_bresp = flash_auto_in_bresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_arready = flash_auto_in_arready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_rvalid = flash_auto_in_rvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_rid = flash_auto_in_rid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_rdata = flash_auto_in_rdata; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_rresp = flash_auto_in_rresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_3_rlast = flash_auto_in_rlast; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_awready = vga_auto_in_1_awready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_wready = vga_auto_in_1_wready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_bvalid = vga_auto_in_1_bvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_bid = vga_auto_in_1_bid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_bresp = vga_auto_in_1_bresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_arready = vga_auto_in_1_arready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_rvalid = vga_auto_in_1_rvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_rid = vga_auto_in_1_rid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_rdata = vga_auto_in_1_rdata; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_rresp = vga_auto_in_1_rresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_2_rlast = vga_auto_in_1_rlast; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_awready = vga_auto_in_0_awready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_wready = vga_auto_in_0_wready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_bvalid = vga_auto_in_0_bvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_bid = vga_auto_in_0_bid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_bresp = vga_auto_in_0_bresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_rvalid = vga_auto_in_0_rvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_rid = vga_auto_in_0_rid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_1_rlast = vga_auto_in_0_rlast; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_awready = uart_auto_in_awready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_wready = uart_auto_in_wready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_bvalid = uart_auto_in_bvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_bid = uart_auto_in_bid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_bresp = uart_auto_in_bresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_arready = uart_auto_in_arready; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_rvalid = uart_auto_in_rvalid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_rid = uart_auto_in_rid; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_rdata = uart_auto_in_rdata; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_rresp = uart_auto_in_rresp; // @[LazyModule.scala 296:16]
  assign axi4xbar_auto_out_0_rlast = uart_auto_in_rlast; // @[LazyModule.scala 296:16]
endmodule

