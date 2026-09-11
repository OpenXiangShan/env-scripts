`timescale 1ns/1ps

// Single-outstanding AXI4-Lite clock-domain bridge.
//
// Request/response payloads are held stable until the opposite domain returns
// a toggle acknowledgement.  Control toggles use three synchronizer stages;
// payload buses use two stages and therefore settle before the third control
// stage is observed.  AW and W may arrive independently, as required by AXI4-
// Lite.  No timing exception is required for this owned-RTL CDC.
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
    localparam integer WRITE_PAYLOAD_WIDTH = ADDR_WIDTH + 3 + DATA_WIDTH + STRB_WIDTH;
    localparam integer READ_PAYLOAD_WIDTH = ADDR_WIDTH + 3;

    reg [ADDR_WIDTH-1:0] s_awaddr_q;
    reg [2:0]            s_awprot_q;
    reg                  s_aw_pending;
    reg [DATA_WIDTH-1:0] s_wdata_q;
    reg [STRB_WIDTH-1:0] s_wstrb_q;
    reg                  s_w_pending;
    reg                  s_write_busy;
    reg                  s_write_req_toggle;
    reg [1:0]            s_bresp_q;
    reg                  s_bvalid_q;

    reg [ADDR_WIDTH-1:0] s_araddr_q;
    reg [2:0]            s_arprot_q;
    reg                  s_read_busy;
    reg                  s_read_req_toggle;
    reg [DATA_WIDTH-1:0] s_rdata_q;
    reg [1:0]            s_rresp_q;
    reg                  s_rvalid_q;

    wire s_aw_fire = s_awvalid && s_awready;
    wire s_w_fire = s_wvalid && s_wready;
    wire s_write_payload_ready = (s_aw_pending || s_aw_fire) &&
                                 (s_w_pending || s_w_fire);

    assign s_awready = s_resetn && !s_write_busy && !s_aw_pending;
    assign s_wready = s_resetn && !s_write_busy && !s_w_pending;
    assign s_bresp = s_bresp_q;
    assign s_bvalid = s_bvalid_q;
    assign s_arready = s_resetn && !s_read_busy;
    assign s_rdata = s_rdata_q;
    assign s_rresp = s_rresp_q;
    assign s_rvalid = s_rvalid_q;

    wire [WRITE_PAYLOAD_WIDTH-1:0] s_write_payload = {
        s_awaddr_q, s_awprot_q, s_wdata_q, s_wstrb_q
    };
    wire [READ_PAYLOAD_WIDTH-1:0] s_read_payload = {s_araddr_q, s_arprot_q};

    reg [1:0] m_write_resp_payload;
    reg       m_write_resp_toggle;
    reg [DATA_WIDTH+1:0] m_read_resp_payload;
    reg                  m_read_resp_toggle;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] s_write_resp_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] s_write_resp_data_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] s_write_resp_data_sync2;
    reg s_write_resp_seen;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] s_read_resp_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [DATA_WIDTH+1:0] s_read_resp_data_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [DATA_WIDTH+1:0] s_read_resp_data_sync2;
    reg s_read_resp_seen;

    always @(posedge s_clk) begin
        if (!s_resetn) begin
            s_awaddr_q <= {ADDR_WIDTH{1'b0}};
            s_awprot_q <= 3'b0;
            s_aw_pending <= 1'b0;
            s_wdata_q <= {DATA_WIDTH{1'b0}};
            s_wstrb_q <= {STRB_WIDTH{1'b0}};
            s_w_pending <= 1'b0;
            s_write_busy <= 1'b0;
            s_write_req_toggle <= 1'b0;
            s_bresp_q <= 2'b0;
            s_bvalid_q <= 1'b0;
            s_araddr_q <= {ADDR_WIDTH{1'b0}};
            s_arprot_q <= 3'b0;
            s_read_busy <= 1'b0;
            s_read_req_toggle <= 1'b0;
            s_rdata_q <= {DATA_WIDTH{1'b0}};
            s_rresp_q <= 2'b0;
            s_rvalid_q <= 1'b0;
            s_write_resp_sync <= 3'b0;
            s_write_resp_data_sync1 <= 2'b0;
            s_write_resp_data_sync2 <= 2'b0;
            s_write_resp_seen <= 1'b0;
            s_read_resp_sync <= 3'b0;
            s_read_resp_data_sync1 <= {(DATA_WIDTH+2){1'b0}};
            s_read_resp_data_sync2 <= {(DATA_WIDTH+2){1'b0}};
            s_read_resp_seen <= 1'b0;
        end else begin
            s_write_resp_sync <= {s_write_resp_sync[1:0], m_write_resp_toggle};
            s_write_resp_data_sync1 <= m_write_resp_payload;
            s_write_resp_data_sync2 <= s_write_resp_data_sync1;
            s_read_resp_sync <= {s_read_resp_sync[1:0], m_read_resp_toggle};
            s_read_resp_data_sync1 <= m_read_resp_payload;
            s_read_resp_data_sync2 <= s_read_resp_data_sync1;

            if (s_aw_fire) begin
                s_awaddr_q <= s_awaddr;
                s_awprot_q <= s_awprot;
                s_aw_pending <= 1'b1;
            end
            if (s_w_fire) begin
                s_wdata_q <= s_wdata;
                s_wstrb_q <= s_wstrb;
                s_w_pending <= 1'b1;
            end
            if (!s_write_busy && s_write_payload_ready) begin
                s_aw_pending <= 1'b0;
                s_w_pending <= 1'b0;
                s_write_busy <= 1'b1;
                s_write_req_toggle <= ~s_write_req_toggle;
            end
            if (s_write_busy && !s_bvalid_q &&
                s_write_resp_sync[2] != s_write_resp_seen) begin
                s_write_resp_seen <= s_write_resp_sync[2];
                s_bresp_q <= s_write_resp_data_sync2;
                s_bvalid_q <= 1'b1;
            end
            if (s_bvalid_q && s_bready) begin
                s_bvalid_q <= 1'b0;
                s_write_busy <= 1'b0;
            end

            if (s_arvalid && s_arready) begin
                s_araddr_q <= s_araddr;
                s_arprot_q <= s_arprot;
                s_read_busy <= 1'b1;
                s_read_req_toggle <= ~s_read_req_toggle;
            end
            if (s_read_busy && !s_rvalid_q &&
                s_read_resp_sync[2] != s_read_resp_seen) begin
                s_read_resp_seen <= s_read_resp_sync[2];
                s_rdata_q <= s_read_resp_data_sync2[DATA_WIDTH+1:2];
                s_rresp_q <= s_read_resp_data_sync2[1:0];
                s_rvalid_q <= 1'b1;
            end
            if (s_rvalid_q && s_rready) begin
                s_rvalid_q <= 1'b0;
                s_read_busy <= 1'b0;
            end
        end
    end

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] m_write_req_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [WRITE_PAYLOAD_WIDTH-1:0] m_write_payload_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [WRITE_PAYLOAD_WIDTH-1:0] m_write_payload_sync2;
    reg m_write_req_seen;
    reg [ADDR_WIDTH-1:0] m_awaddr_q;
    reg [2:0]            m_awprot_q;
    reg                  m_awvalid_q;
    reg [DATA_WIDTH-1:0] m_wdata_q;
    reg [STRB_WIDTH-1:0] m_wstrb_q;
    reg                  m_wvalid_q;
    reg                  m_write_active;
    reg                  m_write_wait_b;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] m_read_req_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [READ_PAYLOAD_WIDTH-1:0] m_read_payload_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [READ_PAYLOAD_WIDTH-1:0] m_read_payload_sync2;
    reg m_read_req_seen;
    reg [ADDR_WIDTH-1:0] m_araddr_q;
    reg [2:0]            m_arprot_q;
    reg                  m_arvalid_q;
    reg                  m_read_wait_r;

    assign m_awaddr = m_awaddr_q;
    assign m_awprot = m_awprot_q;
    assign m_awvalid = m_awvalid_q;
    assign m_wdata = m_wdata_q;
    assign m_wstrb = m_wstrb_q;
    assign m_wvalid = m_wvalid_q;
    assign m_bready = m_write_wait_b;
    assign m_araddr = m_araddr_q;
    assign m_arprot = m_arprot_q;
    assign m_arvalid = m_arvalid_q;
    assign m_rready = m_read_wait_r;

    always @(posedge m_clk) begin
        if (!m_resetn) begin
            m_write_req_sync <= 3'b0;
            m_write_payload_sync1 <= {WRITE_PAYLOAD_WIDTH{1'b0}};
            m_write_payload_sync2 <= {WRITE_PAYLOAD_WIDTH{1'b0}};
            m_write_req_seen <= 1'b0;
            m_awaddr_q <= {ADDR_WIDTH{1'b0}};
            m_awprot_q <= 3'b0;
            m_awvalid_q <= 1'b0;
            m_wdata_q <= {DATA_WIDTH{1'b0}};
            m_wstrb_q <= {STRB_WIDTH{1'b0}};
            m_wvalid_q <= 1'b0;
            m_write_active <= 1'b0;
            m_write_wait_b <= 1'b0;
            m_write_resp_payload <= 2'b0;
            m_write_resp_toggle <= 1'b0;
            m_read_req_sync <= 3'b0;
            m_read_payload_sync1 <= {READ_PAYLOAD_WIDTH{1'b0}};
            m_read_payload_sync2 <= {READ_PAYLOAD_WIDTH{1'b0}};
            m_read_req_seen <= 1'b0;
            m_araddr_q <= {ADDR_WIDTH{1'b0}};
            m_arprot_q <= 3'b0;
            m_arvalid_q <= 1'b0;
            m_read_wait_r <= 1'b0;
            m_read_resp_payload <= {(DATA_WIDTH+2){1'b0}};
            m_read_resp_toggle <= 1'b0;
        end else begin
            m_write_req_sync <= {m_write_req_sync[1:0], s_write_req_toggle};
            m_write_payload_sync1 <= s_write_payload;
            m_write_payload_sync2 <= m_write_payload_sync1;
            m_read_req_sync <= {m_read_req_sync[1:0], s_read_req_toggle};
            m_read_payload_sync1 <= s_read_payload;
            m_read_payload_sync2 <= m_read_payload_sync1;

            if (!m_write_active && !m_write_wait_b &&
                m_write_req_sync[2] != m_write_req_seen) begin
                m_write_req_seen <= m_write_req_sync[2];
                {m_awaddr_q, m_awprot_q, m_wdata_q, m_wstrb_q} <= m_write_payload_sync2;
                m_awvalid_q <= 1'b1;
                m_wvalid_q <= 1'b1;
                m_write_active <= 1'b1;
            end
            if (m_write_active) begin
                if (m_awvalid_q && m_awready)
                    m_awvalid_q <= 1'b0;
                if (m_wvalid_q && m_wready)
                    m_wvalid_q <= 1'b0;
                if ((!m_awvalid_q || m_awready) && (!m_wvalid_q || m_wready)) begin
                    m_write_active <= 1'b0;
                    m_write_wait_b <= 1'b1;
                end
            end
            if (m_write_wait_b && m_bvalid) begin
                m_write_resp_payload <= m_bresp;
                m_write_resp_toggle <= ~m_write_resp_toggle;
                m_write_wait_b <= 1'b0;
            end

            if (!m_arvalid_q && !m_read_wait_r &&
                m_read_req_sync[2] != m_read_req_seen) begin
                m_read_req_seen <= m_read_req_sync[2];
                {m_araddr_q, m_arprot_q} <= m_read_payload_sync2;
                m_arvalid_q <= 1'b1;
            end
            if (m_arvalid_q && m_arready) begin
                m_arvalid_q <= 1'b0;
                m_read_wait_r <= 1'b1;
            end
            if (m_read_wait_r && m_rvalid) begin
                m_read_resp_payload <= {m_rdata, m_rresp};
                m_read_resp_toggle <= ~m_read_resp_toggle;
                m_read_wait_r <= 1'b0;
            end
        end
    end

endmodule
