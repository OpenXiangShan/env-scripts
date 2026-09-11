`timescale 1ns/1ps

// Generic dual-clock ready/valid FIFO.  Payload and pointer CDC use the same
// Gray-pointer structure as the proven GBus AXI-stream FIFO.
module uvhs_async_fifo #(
    parameter integer WIDTH = 32,
    parameter integer ADDR_WIDTH = 3
) (
    input  wire             s_clk,
    input  wire             s_rstn,
    input  wire [WIDTH-1:0] s_data,
    input  wire             s_valid,
    output wire             s_ready,

    input  wire             m_clk,
    input  wire             m_rstn,
    output wire [WIDTH-1:0] m_data,
    output wire             m_valid,
    input  wire             m_ready
);
  localparam integer PTR_WIDTH = ADDR_WIDTH + 1;
  localparam integer DEPTH = 1 << ADDR_WIDTH;

  (* ram_style = "distributed" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
  reg [PTR_WIDTH-1:0] wbin, wgray;
  reg [PTR_WIDTH-1:0] rbin, rgray;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  reg [PTR_WIDTH-1:0] rgray_wsync1, rgray_wsync2;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
  reg [PTR_WIDTH-1:0] wgray_rsync1, wgray_rsync2;
  reg [WIDTH-1:0] out_data;
  reg out_valid;

  wire [PTR_WIDTH-1:0] wbin_next = wbin + 1'b1;
  wire [PTR_WIDTH-1:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
  wire [PTR_WIDTH-1:0] full_compare = {
      ~rgray_wsync2[PTR_WIDTH-1:PTR_WIDTH-2],
      rgray_wsync2[PTR_WIDTH-3:0]
  };
  wire full = wgray_next == full_compare;
  wire not_empty = rgray != wgray_rsync2;

  assign s_ready = s_rstn && !full;
  assign m_data = out_data;
  assign m_valid = out_valid;

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
        mem[wbin[ADDR_WIDTH-1:0]] <= s_data;
        wbin <= wbin_next;
        wgray <= wgray_next;
      end
    end
  end

  always @(posedge m_clk or negedge m_rstn) begin
    if (!m_rstn) begin
      rbin <= 0;
      rgray <= 0;
      wgray_rsync1 <= 0;
      wgray_rsync2 <= 0;
      out_data <= 0;
      out_valid <= 1'b0;
    end else begin
      wgray_rsync1 <= wgray;
      wgray_rsync2 <= wgray_rsync1;
      if (!out_valid || m_ready) begin
        if (not_empty) begin
          out_data <= mem[rbin[ADDR_WIDTH-1:0]];
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
