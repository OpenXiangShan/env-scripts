`timescale 1ns/1ps

// Dual-clock Gray-pointer FIFO.  UVHS uvsyn infers block RAM and cannot
// instantiate Xilinx XPM, so this is the owned equivalent of xpm_fifo_async.
module uvhs_async_fifo #(
    parameter integer WIDTH = 8,
    parameter integer ADDR_WIDTH = 4
) (
    input  wire              s_clk,
    input  wire              s_rstn,
    input  wire [WIDTH-1:0]  s_data,
    input  wire              s_valid,
    output wire              s_ready,
    output wire              s_has_data,

    input  wire              m_clk,
    input  wire              m_rstn,
    output wire [WIDTH-1:0]  m_data,
    output wire              m_valid,
    input  wire              m_ready,
    output wire              m_has_data
);
  localparam integer PTR_WIDTH = ADDR_WIDTH + 1;
  localparam integer DEPTH = 1 << ADDR_WIDTH;

  (* ram_style = "block" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [PTR_WIDTH-1:0] wbin, wgray;
  reg [PTR_WIDTH-1:0] rbin, rgray;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [PTR_WIDTH-1:0] rgray_wsync1, rgray_wsync2;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [PTR_WIDTH-1:0] wgray_rsync1, wgray_rsync2;
  reg [WIDTH-1:0] out_data;
  reg out_valid;

  wire [PTR_WIDTH-1:0] wbin_incremented = wbin + 1'b1;
  wire [PTR_WIDTH-1:0] wgray_incremented = (wbin_incremented >> 1) ^ wbin_incremented;
  wire [PTR_WIDTH-1:0] full_compare = {
      ~rgray_wsync2[PTR_WIDTH-1:PTR_WIDTH-2],
      rgray_wsync2[PTR_WIDTH-3:0]
  };
  wire full = wgray_incremented == full_compare;
  wire fifo_not_empty = rgray != wgray_rsync2;
  assign s_ready = !full;
  assign s_has_data = wgray != rgray_wsync2;
  assign m_has_data = fifo_not_empty | out_valid;
  assign m_data = out_data;
  assign m_valid = out_valid;

  always @(posedge s_clk) begin
    if (s_valid && s_ready)
      mem[wbin[ADDR_WIDTH-1:0]] <= s_data;
  end

  always @(posedge s_clk or negedge s_rstn) begin
    if (!s_rstn) begin
      wbin <= 0;
      wgray <= 0;
      rgray_wsync1 <= 0;
      rgray_wsync2 <= 0;
    end else begin
      rgray_wsync1 <= rgray;
      rgray_wsync2 <= rgray_wsync1;
      if (s_valid && s_ready) begin
        wbin <= wbin_incremented;
        wgray <= wgray_incremented;
      end
    end
  end

  always @(posedge m_clk) begin
    if (!out_valid || m_ready) begin
      if (fifo_not_empty)
        out_data <= mem[rbin[ADDR_WIDTH-1:0]];
    end
  end

  always @(posedge m_clk or negedge m_rstn) begin
    if (!m_rstn) begin
      rbin <= 0;
      rgray <= 0;
      wgray_rsync1 <= 0;
      wgray_rsync2 <= 0;
      out_valid <= 1'b0;
    end else begin
      wgray_rsync1 <= wgray;
      wgray_rsync2 <= wgray_rsync1;
      if (!out_valid || m_ready) begin
        if (fifo_not_empty) begin
          rbin <= rbin + 1'b1;
          rgray <= ((rbin + 1'b1) >> 1) ^ (rbin + 1'b1);
          out_valid <= 1'b1;
        end else begin
          out_valid <= 1'b0;
        end
      end
    end
  end
endmodule
