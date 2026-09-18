`timescale 1ns/1ps

// Payload, byte enables and packet boundaries cross together under
// ready/valid backpressure. Both ports may also share the host clock.
module uvhs_axis_async_fifo #(
    parameter integer DATA_WIDTH = 256,
    parameter integer KEEP_WIDTH = DATA_WIDTH / 8,
    parameter integer ADDR_WIDTH = 4
) (
    input  wire                  s_clk,
    input  wire                  s_rstn,
    input  wire [DATA_WIDTH-1:0] s_tdata,
    input  wire [KEEP_WIDTH-1:0] s_tkeep,
    input  wire                  s_tlast,
    input  wire                  s_tvalid,
    output wire                  s_tready,
    output wire                  s_has_data,

    input  wire                  m_clk,
    input  wire                  m_rstn,
    output wire [DATA_WIDTH-1:0] m_tdata,
    output wire [KEEP_WIDTH-1:0] m_tkeep,
    output wire                  m_tlast,
    output wire                  m_tvalid,
    input  wire                  m_tready,
    // Occupancy seen by the read domain, including the prefetch register.  A
    // register-window consumer needs this to tell "stream finished" from
    // "nothing has arrived yet".
    output wire                  m_has_data
);
  localparam integer PTR_WIDTH = ADDR_WIDTH + 1;
  localparam integer PAYLOAD_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1;
  localparam integer DEPTH = 1 << ADDR_WIDTH;

  (* ram_style = "block" *) reg [PAYLOAD_WIDTH-1:0] mem [0:DEPTH-1];
  reg [PTR_WIDTH-1:0] wbin, wgray;
  reg [PTR_WIDTH-1:0] rbin, rgray;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [PTR_WIDTH-1:0] rgray_wsync1, rgray_wsync2;
  (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [PTR_WIDTH-1:0] wgray_rsync1, wgray_rsync2;
  reg [PAYLOAD_WIDTH-1:0] out_payload;
  reg out_valid;

  wire [PTR_WIDTH-1:0] wbin_incremented = wbin + 1'b1;
  wire [PTR_WIDTH-1:0] wgray_incremented = (wbin_incremented >> 1) ^ wbin_incremented;
  wire [PTR_WIDTH-1:0] full_compare = {
      ~rgray_wsync2[PTR_WIDTH-1:PTR_WIDTH-2],
      rgray_wsync2[PTR_WIDTH-3:0]
  };
  wire full = wgray_incremented == full_compare;
  wire fifo_not_empty = rgray != wgray_rsync2;
  assign s_tready = !full;
  // This occupancy indication is already in s_clk through the synchronized
  // read pointer.  A caller may use it to keep a gated destination clock alive
  // until all accepted stream data has drained.
  assign s_has_data = wgray != rgray_wsync2;
  assign m_has_data = fifo_not_empty | out_valid;
  assign {m_tlast, m_tkeep, m_tdata} = out_payload;
  assign m_tvalid = out_valid;

  always @(posedge s_clk or negedge s_rstn) begin
    if (!s_rstn) begin
      wbin <= 0;
      wgray <= 0;
      rgray_wsync1 <= 0;
      rgray_wsync2 <= 0;
    end else begin
      rgray_wsync1 <= rgray;
      rgray_wsync2 <= rgray_wsync1;
      if (s_tvalid && s_tready) begin
        mem[wbin[ADDR_WIDTH-1:0]] <= {s_tlast, s_tkeep, s_tdata};
        wbin <= wbin_incremented;
        wgray <= wgray_incremented;
      end
    end
  end

  always @(posedge m_clk or negedge m_rstn) begin
    if (!m_rstn) begin
      rbin <= 0;
      rgray <= 0;
      wgray_rsync1 <= 0;
      wgray_rsync2 <= 0;
      out_payload <= 0;
      out_valid <= 1'b0;
    end else begin
      wgray_rsync1 <= wgray;
      wgray_rsync2 <= wgray_rsync1;
      if (!out_valid || m_tready) begin
        if (fifo_not_empty) begin
          out_payload <= mem[rbin[ADDR_WIDTH-1:0]];
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
