`timescale 1ns/1ps

// AXI4-Lite clock crossing built from uvhs_async_fifo.  AW/W assemble on the
// slave clock, then one write and one read outstanding cross the FIFOs.
module uvhs_axilite_cdc_bridge #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                      s_clk,
    input  wire                      s_resetn,
    input  wire [ADDR_WIDTH-1:0]     s_awaddr,
    input  wire [2:0]                s_awprot,
    input  wire                      s_awvalid,
    output wire                      s_awready,
    input  wire [DATA_WIDTH-1:0]     s_wdata,
    input  wire [DATA_WIDTH/8-1:0]   s_wstrb,
    input  wire                      s_wvalid,
    output wire                      s_wready,
    output wire [1:0]                s_bresp,
    output wire                      s_bvalid,
    input  wire                      s_bready,
    input  wire [ADDR_WIDTH-1:0]     s_araddr,
    input  wire [2:0]                s_arprot,
    input  wire                      s_arvalid,
    output wire                      s_arready,
    output wire [DATA_WIDTH-1:0]     s_rdata,
    output wire [1:0]                s_rresp,
    output wire                      s_rvalid,
    input  wire                      s_rready,

    input  wire                      m_clk,
    input  wire                      m_resetn,
    output wire [ADDR_WIDTH-1:0]     m_awaddr,
    output wire [2:0]                m_awprot,
    output wire                      m_awvalid,
    input  wire                      m_awready,
    output wire [DATA_WIDTH-1:0]     m_wdata,
    output wire [DATA_WIDTH/8-1:0]   m_wstrb,
    output wire                      m_wvalid,
    input  wire                      m_wready,
    input  wire [1:0]                m_bresp,
    input  wire                      m_bvalid,
    output wire                      m_bready,
    output wire [ADDR_WIDTH-1:0]     m_araddr,
    output wire [2:0]                m_arprot,
    output wire                      m_arvalid,
    input  wire                      m_arready,
    input  wire [DATA_WIDTH-1:0]     m_rdata,
    input  wire [1:0]                m_rresp,
    input  wire                      m_rvalid,
    output wire                      m_rready
);

    localparam integer STRB_WIDTH = DATA_WIDTH / 8;
    localparam integer WRITE_REQ_WIDTH = ADDR_WIDTH + 3 + DATA_WIDTH + STRB_WIDTH;
    localparam integer READ_REQ_WIDTH = ADDR_WIDTH + 3;
    localparam integer READ_RESP_WIDTH = DATA_WIDTH + 2;

    wire s_write_req_ready;
    wire s_read_req_ready;
    wire m_write_resp_ready;
    wire m_read_resp_ready;
    wire [WRITE_REQ_WIDTH-1:0] m_write_req;
    wire m_write_req_valid;
    wire [READ_REQ_WIDTH-1:0] m_read_req;
    wire m_read_req_valid;
    wire [1:0] s_bresp_fifo;
    wire [READ_RESP_WIDTH-1:0] s_read_resp;
    assign s_bresp = s_bresp_fifo;
    assign {s_rdata, s_rresp} = s_read_resp;

    reg [ADDR_WIDTH-1:0] s_awaddr_q;
    reg [2:0]            s_awprot_q;
    reg                  s_aw_hold;
    reg [DATA_WIDTH-1:0] s_wdata_q;
    reg [STRB_WIDTH-1:0] s_wstrb_q;
    reg                  s_w_hold;
    reg                  s_write_busy;
    reg                  s_read_busy;

    wire s_write_req_valid = s_aw_hold && s_w_hold;
    wire [WRITE_REQ_WIDTH-1:0] s_write_req = {
        s_awaddr_q, s_awprot_q, s_wdata_q, s_wstrb_q
    };
    wire s_write_push = s_write_req_valid && s_write_req_ready;
    wire s_read_push = s_arvalid && s_arready;

    assign s_awready = s_resetn && !s_write_busy && !s_aw_hold;
    assign s_wready  = s_resetn && !s_write_busy && !s_w_hold;
    assign s_arready = s_resetn && !s_read_busy && s_read_req_ready;

    always @(posedge s_clk or negedge s_resetn) begin
      if (!s_resetn) begin
        s_awaddr_q <= {ADDR_WIDTH{1'b0}};
        s_awprot_q <= 3'b0;
        s_aw_hold <= 1'b0;
        s_wdata_q <= {DATA_WIDTH{1'b0}};
        s_wstrb_q <= {STRB_WIDTH{1'b0}};
        s_w_hold <= 1'b0;
        s_write_busy <= 1'b0;
        s_read_busy <= 1'b0;
      end else begin
        if (s_awvalid && s_awready) begin
          s_awaddr_q <= s_awaddr;
          s_awprot_q <= s_awprot;
          s_aw_hold <= 1'b1;
        end
        if (s_wvalid && s_wready) begin
          s_wdata_q <= s_wdata;
          s_wstrb_q <= s_wstrb;
          s_w_hold <= 1'b1;
        end
        if (s_write_push) begin
          s_aw_hold <= 1'b0;
          s_w_hold <= 1'b0;
          s_write_busy <= 1'b1;
        end
        if (s_bvalid && s_bready)
          s_write_busy <= 1'b0;
        if (s_read_push)
          s_read_busy <= 1'b1;
        if (s_rvalid && s_rready)
          s_read_busy <= 1'b0;
      end
    end

    reg                  m_write_busy;
    reg                  m_awvalid_q;
    reg                  m_wvalid_q;
    reg [ADDR_WIDTH-1:0] m_awaddr_q;
    reg [2:0]            m_awprot_q;
    reg [DATA_WIDTH-1:0] m_wdata_q;
    reg [STRB_WIDTH-1:0] m_wstrb_q;
    reg                  m_read_busy;
    reg                  m_arvalid_q;
    reg                  m_wait_r;
    reg [ADDR_WIDTH-1:0] m_araddr_q;
    reg [2:0]            m_arprot_q;

    wire m_write_idle = !m_write_busy;
    wire m_read_idle = !m_read_busy;
    wire m_write_pop = m_write_req_valid && m_write_idle;
    wire m_read_pop = m_read_req_valid && m_read_idle;
    wire m_write_issued = m_write_busy && !m_awvalid_q && !m_wvalid_q;
    wire m_write_resp_push = m_write_issued && m_bvalid && m_write_resp_ready;
    wire m_read_resp_push = m_wait_r && m_rvalid && m_read_resp_ready;

    assign m_awaddr = m_awaddr_q;
    assign m_awprot = m_awprot_q;
    assign m_awvalid = m_awvalid_q;
    assign m_wdata = m_wdata_q;
    assign m_wstrb = m_wstrb_q;
    assign m_wvalid = m_wvalid_q;
    assign m_bready = m_write_issued && m_write_resp_ready;
    assign m_araddr = m_araddr_q;
    assign m_arprot = m_arprot_q;
    assign m_arvalid = m_arvalid_q;
    assign m_rready = m_wait_r && m_read_resp_ready;

    always @(posedge m_clk or negedge m_resetn) begin
      if (!m_resetn) begin
        m_write_busy <= 1'b0;
        m_awvalid_q <= 1'b0;
        m_wvalid_q <= 1'b0;
        m_awaddr_q <= {ADDR_WIDTH{1'b0}};
        m_awprot_q <= 3'b0;
        m_wdata_q <= {DATA_WIDTH{1'b0}};
        m_wstrb_q <= {STRB_WIDTH{1'b0}};
        m_read_busy <= 1'b0;
        m_arvalid_q <= 1'b0;
        m_wait_r <= 1'b0;
        m_araddr_q <= {ADDR_WIDTH{1'b0}};
        m_arprot_q <= 3'b0;
      end else begin
        if (m_write_pop) begin
          {m_awaddr_q, m_awprot_q, m_wdata_q, m_wstrb_q} <= m_write_req;
          m_awvalid_q <= 1'b1;
          m_wvalid_q <= 1'b1;
          m_write_busy <= 1'b1;
        end else begin
          if (m_awvalid_q && m_awready)
            m_awvalid_q <= 1'b0;
          if (m_wvalid_q && m_wready)
            m_wvalid_q <= 1'b0;
          if (m_write_resp_push)
            m_write_busy <= 1'b0;
        end

        if (m_read_pop) begin
          {m_araddr_q, m_arprot_q} <= m_read_req;
          m_arvalid_q <= 1'b1;
          m_read_busy <= 1'b1;
        end else begin
          if (m_arvalid_q && m_arready) begin
            m_arvalid_q <= 1'b0;
            m_wait_r <= 1'b1;
          end
          if (m_read_resp_push) begin
            m_wait_r <= 1'b0;
            m_read_busy <= 1'b0;
          end
        end
      end
    end

    uvhs_async_fifo #(.WIDTH(WRITE_REQ_WIDTH), .ADDR_WIDTH(2)) u_write_req (
        .s_clk(s_clk), .s_rstn(s_resetn),
        .s_data(s_write_req), .s_valid(s_write_req_valid),
        .s_ready(s_write_req_ready), .s_has_data(),
        .m_clk(m_clk), .m_rstn(m_resetn),
        .m_data(m_write_req), .m_valid(m_write_req_valid),
        .m_ready(m_write_idle), .m_has_data()
    );
    uvhs_async_fifo #(.WIDTH(2), .ADDR_WIDTH(2)) u_write_resp (
        .s_clk(m_clk), .s_rstn(m_resetn),
        .s_data(m_bresp), .s_valid(m_write_resp_push),
        .s_ready(m_write_resp_ready), .s_has_data(),
        .m_clk(s_clk), .m_rstn(s_resetn),
        .m_data(s_bresp_fifo), .m_valid(s_bvalid),
        .m_ready(s_bready), .m_has_data()
    );
    uvhs_async_fifo #(.WIDTH(READ_REQ_WIDTH), .ADDR_WIDTH(2)) u_read_req (
        .s_clk(s_clk), .s_rstn(s_resetn),
        .s_data({s_araddr, s_arprot}), .s_valid(s_read_push),
        .s_ready(s_read_req_ready), .s_has_data(),
        .m_clk(m_clk), .m_rstn(m_resetn),
        .m_data(m_read_req), .m_valid(m_read_req_valid),
        .m_ready(m_read_idle), .m_has_data()
    );
    uvhs_async_fifo #(.WIDTH(READ_RESP_WIDTH), .ADDR_WIDTH(2)) u_read_resp (
        .s_clk(m_clk), .s_rstn(m_resetn),
        .s_data({m_rdata, m_rresp}), .s_valid(m_read_resp_push),
        .s_ready(m_read_resp_ready), .s_has_data(),
        .m_clk(s_clk), .m_rstn(s_resetn),
        .m_data(s_read_resp), .m_valid(s_rvalid),
        .m_ready(s_rready), .m_has_data()
    );
endmodule
