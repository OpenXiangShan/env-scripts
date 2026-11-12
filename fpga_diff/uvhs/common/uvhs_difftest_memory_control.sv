`timescale 1ns/1ps

// Observe the accepted BAR write, not the host-side GeneralBD request. AW and W
// may arrive independently; the memory controller resets on a configuration write.
module uvhs_difftest_memory_control (
  input wire clk, input wire rstn,
  input wire [31:0] awaddr, input wire awvalid, input wire awready,
  input wire [31:0] wdata, input wire [3:0] wstrb,
  input wire wvalid, input wire wready,
  output reg cpu_mode
);
  reg aw_pending, w_pending;
  reg [31:0] awaddr_q, wdata_q;
  reg [3:0] wstrb_q;
  wire aw_take = awvalid && awready;
  wire w_take = wvalid && wready;
  wire assembled = (aw_pending || aw_take) && (w_pending || w_take);
  wire [31:0] address = aw_take ? awaddr : awaddr_q;
  wire [31:0] data = w_take ? wdata : wdata_q;
  wire [3:0] strb = w_take ? wstrb : wstrb_q;
  wire cfg_reset = assembled && (address >> 2) == 0 && (strb & 4'd1) != 0 && (data & 32'd1) != 0;

  always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      aw_pending <= 1'b0;
      w_pending <= 1'b0;
      awaddr_q <= 0;
      wdata_q <= 0;
      wstrb_q <= 0;
      cpu_mode <= 1'b0;
    end else begin
      if (aw_take) awaddr_q <= awaddr;
      if (w_take) begin wdata_q <= wdata; wstrb_q <= wstrb; end
      aw_pending <= !assembled && (aw_pending || aw_take);
      w_pending <= !assembled && (w_pending || w_take);
      if (cfg_reset)
        cpu_mode <= 1'b0;
      else if (assembled && (strb & 4'd1) != 0) begin
        if (((address >> 2) == 8 || (address >> 2) == 10) && (data & 32'd1) != 0)
          cpu_mode <= 1'b0;
        else if ((address >> 2) == 9)
          cpu_mode <= (data & 32'd1) != 0;
      end
    end
  end
endmodule
