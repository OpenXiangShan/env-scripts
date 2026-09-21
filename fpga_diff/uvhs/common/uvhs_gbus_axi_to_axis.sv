`timescale 1ns/1ps

// Convert GeneralBus AXI3 writes into the existing DifftestMemCtrl AXI-stream
// H2C engine.  H2CAXIs2Mem ignores AXI addresses and writes physical DRAM from
// 0x80000000 using HOST_IO_H2C_SIZE_MB, so this shim only forwards write data,
// keep, and last.  Reads complete with DECERR because the H2C engine is
// write-only.  AXI3 burst metadata is unused.
module uvhs_gbus_axi_to_axis #(
    parameter integer ID_WIDTH = 8,
    parameter integer DATA_WIDTH = 256
) (
    input wire clk,
    input wire rstn,

    input wire [ID_WIDTH-1:0] s_awid,
    input wire s_awvalid,
    output wire s_awready,
    input wire [DATA_WIDTH-1:0] s_wdata,
    input wire [DATA_WIDTH/8-1:0] s_wstrb,
    input wire s_wlast,
    input wire s_wvalid,
    output wire s_wready,
    output wire [ID_WIDTH-1:0] s_bid,
    output wire [1:0] s_bresp,
    output wire s_bvalid,
    input wire s_bready,

    input wire [ID_WIDTH-1:0] s_arid,
    input wire s_arvalid,
    output wire s_arready,
    output wire [ID_WIDTH-1:0] s_rid,
    output wire [DATA_WIDTH-1:0] s_rdata,
    output wire [1:0] s_rresp,
    output wire s_rlast,
    output wire s_rvalid,
    input wire s_rready,

    output wire m_tvalid,
    output wire [DATA_WIDTH-1:0] m_tdata,
    output wire [DATA_WIDTH/8-1:0] m_tkeep,
    output wire m_tlast,
    input wire m_tready
);
    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_DATA = 2'd1;
    localparam [1:0] ST_RESP = 2'd2;

    reg [1:0] state;
    reg [ID_WIDTH-1:0] awid_q;
    reg [ID_WIDTH-1:0] arid_q;
    reg rvalid_q;

    wire aw_fire = s_awvalid & s_awready;
    wire w_fire = s_wvalid & s_wready;
    wire b_fire = s_bvalid & s_bready;
    wire ar_fire = s_arvalid & s_arready;
    wire r_fire = s_rvalid & s_rready;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= ST_IDLE;
            awid_q <= {ID_WIDTH{1'b0}};
        end else begin
            case (state)
                ST_IDLE: begin
                    if (aw_fire) begin
                        awid_q <= s_awid;
                        state <= ST_DATA;
                    end
                end
                ST_DATA: begin
                    if (w_fire && s_wlast)
                        state <= ST_RESP;
                end
                ST_RESP: begin
                    if (b_fire)
                        state <= ST_IDLE;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

    assign s_awready = (state == ST_IDLE);
    assign s_wready = (state == ST_DATA) && m_tready;
    assign m_tvalid = (state == ST_DATA) && s_wvalid;
    assign m_tdata = s_wdata;
    assign m_tkeep = s_wstrb;
    assign m_tlast = s_wlast;
    assign s_bid = awid_q;
    assign s_bresp = 2'b00;
    assign s_bvalid = (state == ST_RESP);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rvalid_q <= 1'b0;
            arid_q <= {ID_WIDTH{1'b0}};
        end else begin
            if (ar_fire) begin
                rvalid_q <= 1'b1;
                arid_q <= s_arid;
            end else if (r_fire) begin
                rvalid_q <= 1'b0;
            end
        end
    end

    assign s_arready = ~rvalid_q;
    assign s_rvalid = rvalid_q;
    assign s_rid = arid_q;
    assign s_rdata = {DATA_WIDTH{1'b0}};
    assign s_rresp = 2'b10;
    assign s_rlast = 1'b1;
endmodule
