// ...existing code...
module XDMA_AXI4LiteBar(
  input         clock,
  input         reset,

  // AXI4-Lite Write Address
  input  [31:0] io_axi_write_awaddr,
  input         io_axi_write_awvalid,
  output        io_axi_write_awready,

  // AXI4-Lite Write Data
  input  [31:0] io_axi_write_wdata,
  input  [3:0]  io_axi_write_wstrb,
  input         io_axi_write_wvalid,
  output        io_axi_write_wready,

  // AXI4-Lite Write Response
  output [1:0]  io_axi_write_bresp,
  output        io_axi_write_bvalid,
  input         io_axi_write_bready,

  // AXI4-Lite Read Address
  input  [31:0] io_axi_read_araddr,
  input         io_axi_read_arvalid,
  output        io_axi_read_arready,

  // AXI4-Lite Read Data
  output [31:0] io_axi_read_rdata,
  output [1:0]  io_axi_read_rresp,
  output        io_axi_read_rvalid,
  input         io_axi_read_rready,

  // sideband
  output        io_host_reset
);

  // 8 x 32-bit BAR
  reg [31:0] regfile_0, regfile_1, regfile_2, regfile_3;
  reg [31:0] regfile_4, regfile_5, regfile_6, regfile_7;

  // Write channel handshake/staging
  reg        aw_captured;
  reg [31:0] awaddr_r;
  reg        w_captured;
  reg [31:0] wdata_r;
  reg [3:0]  wstrb_r;
  reg        bvalid_r;

  // Read channel handshake/staging
  reg        ar_busy;
  reg [31:0] araddr_r;
  reg        rvalid_r;
  reg [31:0] rdata_r;

  // ready/valid
  assign io_axi_write_awready = ~aw_captured;
  assign io_axi_write_wready  = ~w_captured;
  assign io_axi_write_bresp   = 2'b00; // OKAY
  assign io_axi_write_bvalid  = bvalid_r;

  assign io_axi_read_arready  = ~ar_busy & ~rvalid_r;
  assign io_axi_read_rresp    = 2'b00; // OKAY
  assign io_axi_read_rvalid   = rvalid_r;
  assign io_axi_read_rdata    = rdata_r;

  // Sideband signals
  assign io_host_reset             = regfile_0[0];

  // Byte-lane masked write
  function automatic [31:0] mask_write32(
    input [31:0] oldv, input [31:0] newv, input [3:0] strb
  );
    mask_write32 = oldv;
    if (strb[0]) mask_write32[ 7: 0] = newv[ 7: 0];
    if (strb[1]) mask_write32[15: 8] = newv[15: 8];
    if (strb[2]) mask_write32[23:16] = newv[23:16];
    if (strb[3]) mask_write32[31:24] = newv[31:24];
  endfunction

  wire aw_fire = io_axi_write_awvalid & io_axi_write_awready;
  wire w_fire  = io_axi_write_wvalid  & io_axi_write_wready;
  wire ar_fire = io_axi_read_arvalid  & io_axi_read_arready;

  always @(posedge clock) begin
    if (reset) begin
      regfile_0 <= 32'h0; regfile_1 <= 32'h0; regfile_2 <= 32'h0; regfile_3 <= 32'h0;
      regfile_4 <= 32'h0; regfile_5 <= 32'h0; regfile_6 <= 32'h0; regfile_7 <= 32'h0;

      aw_captured <= 1'b0; awaddr_r <= 32'h0;
      w_captured  <= 1'b0; wdata_r  <= 32'h0; wstrb_r <= 4'h0;
      bvalid_r    <= 1'b0;

      ar_busy <= 1'b0; araddr_r <= 32'h0;
      rvalid_r <= 1'b0; rdata_r <= 32'h0;
    end else begin
      // Capture write address/data
      if (aw_fire) begin
        aw_captured <= 1'b1;
        awaddr_r    <= io_axi_write_awaddr;
      end
      if (w_fire) begin
        w_captured <= 1'b1;
        wdata_r    <= io_axi_write_wdata;
        wstrb_r    <= io_axi_write_wstrb;
      end

      // Perform write and issue B response
      if (~bvalid_r && aw_captured && w_captured) begin
        case (awaddr_r[4:2])
          3'd0: regfile_0 <= mask_write32(regfile_0, wdata_r, wstrb_r);
          3'd1: regfile_1 <= mask_write32(regfile_1, wdata_r, wstrb_r);
          3'd2: regfile_2 <= mask_write32(regfile_2, wdata_r, wstrb_r);
          3'd3: regfile_3 <= mask_write32(regfile_3, wdata_r, wstrb_r);
          3'd4: regfile_4 <= mask_write32(regfile_4, wdata_r, wstrb_r);
          3'd5: regfile_5 <= mask_write32(regfile_5, wdata_r, wstrb_r);
          3'd6: regfile_6 <= mask_write32(regfile_6, wdata_r, wstrb_r);
          3'd7: regfile_7 <= mask_write32(regfile_7, wdata_r, wstrb_r);
          default: /* do nothing */;
        endcase
        bvalid_r    <= 1'b1;
        aw_captured <= 1'b0;
        w_captured  <= 1'b0;
      end
      if (bvalid_r && io_axi_write_bready) begin
        bvalid_r <= 1'b0;
      end

      // Capture read address and return data
      if (ar_fire) begin
        ar_busy  <= 1'b1;
        araddr_r <= io_axi_read_araddr;
        case (io_axi_read_araddr[4:2])
          3'd0: rdata_r <= regfile_0;
          3'd1: rdata_r <= regfile_1;
          3'd2: rdata_r <= regfile_2;
          3'd3: rdata_r <= regfile_3;
          3'd4: rdata_r <= regfile_4;
          3'd5: rdata_r <= regfile_5;
          3'd6: rdata_r <= regfile_6;
          3'd7: rdata_r <= regfile_7;
          default: rdata_r <= 32'h0;
        endcase
        rvalid_r <= 1'b1;
      end
      if (rvalid_r && io_axi_read_rready) begin
        rvalid_r <= 1'b0;
        ar_busy  <= 1'b0;
      end
    end
  end
endmodule
