`timescale 1ns/1ps

// AXIS view of uvhs_async_fifo.  TDATA/TKEEP/TLAST cross together.
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
    output wire                  m_has_data
);
  localparam integer PAYLOAD_WIDTH = DATA_WIDTH + KEEP_WIDTH + 1;
  wire [PAYLOAD_WIDTH-1:0] s_payload = {s_tlast, s_tkeep, s_tdata};
  wire [PAYLOAD_WIDTH-1:0] m_payload;

  uvhs_async_fifo #(
      .WIDTH(PAYLOAD_WIDTH),
      .ADDR_WIDTH(ADDR_WIDTH)
  ) u_fifo (
      .s_clk(s_clk),
      .s_rstn(s_rstn),
      .s_data(s_payload),
      .s_valid(s_tvalid),
      .s_ready(s_tready),
      .s_has_data(s_has_data),
      .m_clk(m_clk),
      .m_rstn(m_rstn),
      .m_data(m_payload),
      .m_valid(m_tvalid),
      .m_ready(m_tready),
      .m_has_data(m_has_data)
  );

  assign {m_tlast, m_tkeep, m_tdata} = m_payload;
endmodule
