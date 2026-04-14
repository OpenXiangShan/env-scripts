module h2c_s2mm_bridge #(
    parameter [32:0] BASE_ADDR = 33'd0
) (
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME clk, ASSOCIATED_BUSIF S_AXIS:M_AXIS:M_AXIS_S2MM_CMD:S_AXIS_S2MM_STS, ASSOCIATED_RESET rstn" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk CLK" *)
    input clk,
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME rstn, POLARITY ACTIVE_LOW" *)
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rstn RST" *)
    input rstn,

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXIS, HAS_TKEEP 1, HAS_TLAST 1, HAS_TREADY 1, TDATA_NUM_BYTES 32" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input [255:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TKEEP" *)
    input [31:0] s_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TLAST" *)
    input s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TREADY" *)
    output s_axis_tready,

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS, HAS_TKEEP 1, HAS_TLAST 1, HAS_TREADY 1, TDATA_NUM_BYTES 32" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output [255:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TKEEP" *)
    output [31:0] m_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TLAST" *)
    output m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TREADY" *)
    input m_axis_tready,

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXIS_S2MM_CMD, HAS_TREADY 1, TDATA_NUM_BYTES 10" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM_CMD TDATA" *)
    output [79:0] m_axis_s2mm_cmd_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM_CMD TVALID" *)
    output m_axis_s2mm_cmd_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS_S2MM_CMD TREADY" *)
    input m_axis_s2mm_cmd_tready,

    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME S_AXIS_S2MM_STS, HAS_TKEEP 1, HAS_TLAST 1, HAS_TREADY 1, TDATA_NUM_BYTES 4" *)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TDATA" *)
    input [31:0] s_axis_s2mm_sts_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TKEEP" *)
    input [3:0] s_axis_s2mm_sts_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TLAST" *)
    input s_axis_s2mm_sts_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TVALID" *)
    input s_axis_s2mm_sts_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS_S2MM_STS TREADY" *)
    output s_axis_s2mm_sts_tready
);

  localparam [22:0] INDET_BTT_MAX = 23'h7fffff;

  reg packet_active;
  reg status_pending;
  reg [32:0] addr_q;
  reg [3:0] tag_q;

  wire start_packet;
  wire cmd_fire;
  wire data_fire;
  wire sts_fire;

  assign start_packet = ~packet_active & ~status_pending & s_axis_tvalid;
  assign cmd_fire = m_axis_s2mm_cmd_tvalid & m_axis_s2mm_cmd_tready;
  assign data_fire = m_axis_tvalid & m_axis_tready;
  assign sts_fire = s_axis_s2mm_sts_tvalid & s_axis_s2mm_sts_tready;

  assign s_axis_tready = m_axis_tready & (packet_active | (start_packet & m_axis_s2mm_cmd_tready));

  assign m_axis_tdata = s_axis_tdata;
  assign m_axis_tkeep = s_axis_tkeep;
  assign m_axis_tlast = s_axis_tlast;
  assign m_axis_tvalid = s_axis_tvalid & (packet_active | (start_packet & m_axis_s2mm_cmd_tready));

  assign m_axis_s2mm_cmd_tvalid = start_packet;
  assign m_axis_s2mm_cmd_tdata = {
      4'd0,
      tag_q,
      7'd0, addr_q,
      1'b1,
      1'b1,
      6'd0,
      1'b1,
      INDET_BTT_MAX
  };

  assign s_axis_s2mm_sts_tready = 1'b1;

  always @(posedge clk) begin
    if (!rstn) begin
      packet_active <= 1'b0;
      status_pending <= 1'b0;
      addr_q <= BASE_ADDR;
      tag_q <= 4'd0;
    end else begin
      if (cmd_fire) begin
        status_pending <= 1'b1;
        packet_active <= ~(data_fire & s_axis_tlast);
      end else if (data_fire && packet_active && s_axis_tlast) begin
        packet_active <= 1'b0;
      end

      if (sts_fire) begin
        status_pending <= 1'b0;
        addr_q <= addr_q + s_axis_s2mm_sts_tdata[30:8];
        tag_q <= tag_q + 4'd1;
      end
    end
  end

endmodule
