`timescale 1ns/1ps

module ddr_memtest_axi_write_arbiter2 #(
    parameter int unsigned AXI_DATA_WIDTH = 256,
    parameter int unsigned ADDR_WIDTH     = 32,
    parameter int unsigned ID_WIDTH       = 4,
    parameter int unsigned RESP_QUEUE_DEPTH = 16
) (
    input  wire                         clk,
    input  wire                         rst_n,

    input  wire [ID_WIDTH-1:0]          s0_axi_awid,
    input  wire [ADDR_WIDTH-1:0]        s0_axi_awaddr,
    input  wire [7:0]                   s0_axi_awlen,
    input  wire [2:0]                   s0_axi_awsize,
    input  wire [1:0]                   s0_axi_awburst,
    input  wire                         s0_axi_awlock,
    input  wire [3:0]                   s0_axi_awcache,
    input  wire [2:0]                   s0_axi_awprot,
    input  wire [3:0]                   s0_axi_awqos,
    input  wire                         s0_axi_awvalid,
    output wire                         s0_axi_awready,
    input  wire [AXI_DATA_WIDTH-1:0]    s0_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0]  s0_axi_wstrb,
    input  wire                         s0_axi_wlast,
    input  wire                         s0_axi_wvalid,
    output wire                         s0_axi_wready,
    output wire [ID_WIDTH-1:0]          s0_axi_bid,
    output wire [1:0]                   s0_axi_bresp,
    output wire                         s0_axi_bvalid,
    input  wire                         s0_axi_bready,

    input  wire [ID_WIDTH-1:0]          s1_axi_awid,
    input  wire [ADDR_WIDTH-1:0]        s1_axi_awaddr,
    input  wire [7:0]                   s1_axi_awlen,
    input  wire [2:0]                   s1_axi_awsize,
    input  wire [1:0]                   s1_axi_awburst,
    input  wire                         s1_axi_awlock,
    input  wire [3:0]                   s1_axi_awcache,
    input  wire [2:0]                   s1_axi_awprot,
    input  wire [3:0]                   s1_axi_awqos,
    input  wire                         s1_axi_awvalid,
    output wire                         s1_axi_awready,
    input  wire [AXI_DATA_WIDTH-1:0]    s1_axi_wdata,
    input  wire [AXI_DATA_WIDTH/8-1:0]  s1_axi_wstrb,
    input  wire                         s1_axi_wlast,
    input  wire                         s1_axi_wvalid,
    output wire                         s1_axi_wready,
    output wire [ID_WIDTH-1:0]          s1_axi_bid,
    output wire [1:0]                   s1_axi_bresp,
    output wire                         s1_axi_bvalid,
    input  wire                         s1_axi_bready,

    output wire [ID_WIDTH-1:0]          m_axi_awid,
    output wire [ADDR_WIDTH-1:0]        m_axi_awaddr,
    output wire [7:0]                   m_axi_awlen,
    output wire [2:0]                   m_axi_awsize,
    output wire [1:0]                   m_axi_awburst,
    output wire                         m_axi_awlock,
    output wire [3:0]                   m_axi_awcache,
    output wire [2:0]                   m_axi_awprot,
    output wire [3:0]                   m_axi_awqos,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0]  m_axi_wstrb,
    output wire                         m_axi_wlast,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,
    input  wire [ID_WIDTH-1:0]          m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready
);

    localparam [2:0] S_IDLE    = 3'd0;
    localparam [2:0] S0_AW     = 3'd1;
    localparam [2:0] S0_BODY   = 3'd2;
    localparam [2:0] S1_AW     = 3'd3;
    localparam [2:0] S1_BODY   = 3'd4;
    localparam int unsigned RESP_PTR_WIDTH =
        (RESP_QUEUE_DEPTH <= 2) ? 1 : $clog2(RESP_QUEUE_DEPTH);
    localparam int unsigned RESP_CNT_WIDTH = $clog2(RESP_QUEUE_DEPTH + 1);

    reg [2:0] state;
    reg last_sel;
    reg resp_src_mem [0:RESP_QUEUE_DEPTH-1];
    reg [RESP_PTR_WIDTH-1:0] resp_wr_ptr;
    reg [RESP_PTR_WIDTH-1:0] resp_rd_ptr;
    reg [RESP_CNT_WIDTH-1:0] resp_count;

    wire choose_s0 = s0_axi_awvalid && (!s1_axi_awvalid || last_sel);
    wire choose_s1 = s1_axi_awvalid && (!s0_axi_awvalid || !last_sel);
    wire ids_unique = (s0_axi_awid != s1_axi_awid);
    wire resp_queue_empty = (resp_count == {RESP_CNT_WIDTH{1'b0}});
    wire resp_queue_full = (resp_count == RESP_CNT_WIDTH'(RESP_QUEUE_DEPTH));
    wire resp_head_is_s1 = resp_src_mem[resp_rd_ptr];
    wire ordered_resp_mode = !ids_unique;
    wire aw_route_s1 = (state == S1_AW);
    wire aw_queue_room = !ordered_resp_mode || !resp_queue_full;
    wire aw_fire = m_axi_awvalid && m_axi_awready;
    wire w_fire = m_axi_wvalid && m_axi_wready;
    wire wlast_fire = w_fire && m_axi_wlast;
    wire b_to_s0_by_id = ids_unique && (m_axi_bid == s0_axi_awid);
    wire b_to_s1_by_id = ids_unique && (m_axi_bid == s1_axi_awid);
    wire b_to_s0_by_order = ordered_resp_mode && !resp_queue_empty && !resp_head_is_s1;
    wire b_to_s1_by_order = ordered_resp_mode && !resp_queue_empty && resp_head_is_s1;
    wire b_to_s0 = m_axi_bvalid && (b_to_s0_by_id || b_to_s0_by_order);
    wire b_to_s1 = m_axi_bvalid && (b_to_s1_by_id || b_to_s1_by_order);
    wire b_fire = m_axi_bvalid && m_axi_bready;

    assign s0_axi_awready = (state == S0_AW) && aw_queue_room && m_axi_awready;
    assign s1_axi_awready = (state == S1_AW) && aw_queue_room && m_axi_awready;
    assign s0_axi_wready  = (state == S0_BODY) && m_axi_wready;
    assign s1_axi_wready  = (state == S1_BODY) && m_axi_wready;
    assign s0_axi_bvalid  = b_to_s0;
    assign s1_axi_bvalid  = b_to_s1;
    assign s0_axi_bid     = b_to_s0 ? m_axi_bid : {ID_WIDTH{1'b0}};
    assign s1_axi_bid     = b_to_s1 ? m_axi_bid : {ID_WIDTH{1'b0}};
    assign s0_axi_bresp   = b_to_s0 ? m_axi_bresp : 2'b00;
    assign s1_axi_bresp   = b_to_s1 ? m_axi_bresp : 2'b00;

    assign m_axi_awid     = (state == S0_AW) ? s0_axi_awid    :
                            (state == S1_AW) ? s1_axi_awid    : {ID_WIDTH{1'b0}};
    assign m_axi_awaddr   = (state == S0_AW) ? s0_axi_awaddr  :
                            (state == S1_AW) ? s1_axi_awaddr  : {ADDR_WIDTH{1'b0}};
    assign m_axi_awlen    = (state == S0_AW) ? s0_axi_awlen   :
                            (state == S1_AW) ? s1_axi_awlen   : 8'd0;
    assign m_axi_awsize   = (state == S0_AW) ? s0_axi_awsize  :
                            (state == S1_AW) ? s1_axi_awsize  : 3'd0;
    assign m_axi_awburst  = (state == S0_AW) ? s0_axi_awburst :
                            (state == S1_AW) ? s1_axi_awburst : 2'b01;
    assign m_axi_awlock   = (state == S0_AW) ? s0_axi_awlock  :
                            (state == S1_AW) ? s1_axi_awlock  : 1'b0;
    assign m_axi_awcache  = (state == S0_AW) ? s0_axi_awcache :
                            (state == S1_AW) ? s1_axi_awcache : 4'b0011;
    assign m_axi_awprot   = (state == S0_AW) ? s0_axi_awprot  :
                            (state == S1_AW) ? s1_axi_awprot  : 3'b000;
    assign m_axi_awqos    = (state == S0_AW) ? s0_axi_awqos   :
                            (state == S1_AW) ? s1_axi_awqos   : 4'b0000;
    assign m_axi_awvalid  = (state == S0_AW) ? (s0_axi_awvalid && aw_queue_room) :
                            (state == S1_AW) ? (s1_axi_awvalid && aw_queue_room) : 1'b0;

    assign m_axi_wdata    = (state == S0_BODY) ? s0_axi_wdata  :
                            (state == S1_BODY) ? s1_axi_wdata  : {AXI_DATA_WIDTH{1'b0}};
    assign m_axi_wstrb    = (state == S0_BODY) ? s0_axi_wstrb  :
                            (state == S1_BODY) ? s1_axi_wstrb  : {(AXI_DATA_WIDTH/8){1'b0}};
    assign m_axi_wlast    = (state == S0_BODY) ? s0_axi_wlast  :
                            (state == S1_BODY) ? s1_axi_wlast  : 1'b0;
    assign m_axi_wvalid   = (state == S0_BODY) ? s0_axi_wvalid :
                            (state == S1_BODY) ? s1_axi_wvalid : 1'b0;
    assign m_axi_bready   = b_to_s0 ? s0_axi_bready :
                            b_to_s1 ? s1_axi_bready :
                            m_axi_bvalid ? 1'b0 : 1'b0;

    function automatic [RESP_PTR_WIDTH-1:0] resp_ptr_next(
        input [RESP_PTR_WIDTH-1:0] ptr
    );
        begin
            if (ptr == RESP_PTR_WIDTH'(RESP_QUEUE_DEPTH - 1)) begin
                resp_ptr_next = {RESP_PTR_WIDTH{1'b0}};
            end else begin
                resp_ptr_next = ptr + RESP_PTR_WIDTH'(1);
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            last_sel <= 1'b1;
            resp_wr_ptr <= {RESP_PTR_WIDTH{1'b0}};
            resp_rd_ptr <= {RESP_PTR_WIDTH{1'b0}};
            resp_count  <= {RESP_CNT_WIDTH{1'b0}};
        end else begin
            if (ordered_resp_mode && aw_fire) begin
                resp_src_mem[resp_wr_ptr] <= aw_route_s1;
                resp_wr_ptr <= resp_ptr_next(resp_wr_ptr);
            end

            if (ordered_resp_mode && b_fire) begin
                resp_rd_ptr <= resp_ptr_next(resp_rd_ptr);
            end

            if (ordered_resp_mode) begin
                case ({aw_fire, b_fire})
                    2'b10: begin
                        if (resp_count != RESP_CNT_WIDTH'(RESP_QUEUE_DEPTH)) begin
                            resp_count <= resp_count + RESP_CNT_WIDTH'(1);
                        end
                    end
                    2'b01: begin
                        if (resp_count != {RESP_CNT_WIDTH{1'b0}}) begin
                            resp_count <= resp_count - RESP_CNT_WIDTH'(1);
                        end
                    end
                    default: begin
                        resp_count <= resp_count;
                    end
                endcase
            end else begin
                resp_wr_ptr <= {RESP_PTR_WIDTH{1'b0}};
                resp_rd_ptr <= {RESP_PTR_WIDTH{1'b0}};
                resp_count  <= {RESP_CNT_WIDTH{1'b0}};
            end

            case (state)
                S_IDLE: begin
                    if (choose_s0) begin
                        state <= S0_AW;
                    end else if (choose_s1) begin
                        state <= S1_AW;
                    end
                end

                S0_AW: begin
                    if (!s0_axi_awvalid) begin
                        state <= S_IDLE;
                    end else if (aw_fire) begin
                        state <= S0_BODY;
                    end
                end

                S0_BODY: begin
                    if (wlast_fire) begin
                        state    <= S_IDLE;
                        last_sel <= 1'b0;
                    end
                end

                S1_AW: begin
                    if (!s1_axi_awvalid) begin
                        state <= S_IDLE;
                    end else if (aw_fire) begin
                        state <= S1_BODY;
                    end
                end

                S1_BODY: begin
                    if (wlast_fire) begin
                        state    <= S_IDLE;
                        last_sel <= 1'b1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
