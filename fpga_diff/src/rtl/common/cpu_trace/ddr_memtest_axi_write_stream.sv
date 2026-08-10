`timescale 1ns/1ps

module ddr_memtest_axi_write_stream #(
    parameter int unsigned AXI_DATA_WIDTH       = 256,
    parameter int unsigned ADDR_WIDTH           = 32,
    parameter int unsigned ID_WIDTH             = 4,
    parameter int unsigned BURST_LEN            = 16,
    parameter int unsigned FLUSH_IDLE_CYCLES    = 32,
    parameter int unsigned OUTSTANDING_BURSTS   = 8,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR       = {ADDR_WIDTH{1'b0}},
    parameter [ID_WIDTH-1:0]   AXI_ID          = {ID_WIDTH{1'b0}}
) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        enable,
    input  wire [ADDR_WIDTH-1:0]       cfg_base_addr,

    output reg                         fifo_rd_en,
    input  wire [AXI_DATA_WIDTH-1:0]    fifo_rd_data,
    input  wire [AXI_DATA_WIDTH/8-1:0]  fifo_rd_strb,
    input  wire                        fifo_rd_valid,
    input  wire                        fifo_empty,

    output wire [ID_WIDTH-1:0]         m_axi_awid,
    output wire [ADDR_WIDTH-1:0]       m_axi_awaddr,
    output wire [7:0]                  m_axi_awlen,
    output wire [2:0]                  m_axi_awsize,
    output wire [1:0]                  m_axi_awburst,
    output wire                        m_axi_awlock,
    output wire [3:0]                  m_axi_awcache,
    output wire [2:0]                  m_axi_awprot,
    output wire [3:0]                  m_axi_awqos,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,

    output wire [AXI_DATA_WIDTH-1:0]   m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,

    input  wire [ID_WIDTH-1:0]         m_axi_bid,
    input  wire [1:0]                  m_axi_bresp,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready
);

    localparam int unsigned DATA_BYTES = AXI_DATA_WIDTH / 8;
    localparam [2:0] AXI_SIZE = 3'($clog2(DATA_BYTES));
    localparam [8:0] BURST_LEN_C = (BURST_LEN < 1) ? 9'd1 :
                                   (BURST_LEN > 256) ? 9'd256 : 9'(BURST_LEN);
    localparam int unsigned FLUSH_IDLE_CYCLES_C =
        (FLUSH_IDLE_CYCLES < 1) ? 1 : FLUSH_IDLE_CYCLES;
    localparam int unsigned IDLE_CNT_WIDTH =
        (FLUSH_IDLE_CYCLES_C < 2) ? 1 : $clog2(FLUSH_IDLE_CYCLES_C + 1);
    localparam int unsigned OUTSTANDING_BURSTS_C =
        (OUTSTANDING_BURSTS < 1) ? 1 : OUTSTANDING_BURSTS;
    localparam int unsigned OUTSTANDING_CNT_WIDTH =
        $clog2(OUTSTANDING_BURSTS_C + 1);
    localparam [OUTSTANDING_CNT_WIDTH-1:0] OUTSTANDING_LIMIT =
        OUTSTANDING_CNT_WIDTH'(OUTSTANDING_BURSTS_C);

    localparam [1:0] S_FILL = 2'd0;
    localparam [1:0] S_AW   = 2'd1;
    localparam [1:0] S_W    = 2'd2;

    reg [1:0] state;
    reg [ADDR_WIDTH-1:0] addr;
    reg [8:0] burst_beats;
    reg [7:0] beat_index;
    reg [8:0] buf_count;
    reg [IDLE_CNT_WIDTH-1:0] idle_count;
    reg [AXI_DATA_WIDTH-1:0] buf_mem [0:255];
    reg [AXI_DATA_WIDTH/8-1:0] buf_strb [0:255];
    reg rd_pending;
    reg [ADDR_WIDTH-1:0] cfg_base_addr_seen;
    reg [OUTSTANDING_CNT_WIDTH-1:0] outstanding_count;
    reg resp_error_seen;

    function automatic [8:0] beats_to_4k_boundary(input [ADDR_WIDTH-1:0] beat_addr);
        reg [11:0] page_offset;
        reg [12:0] bytes_left;
        reg [12:0] beats_left;
        begin
            page_offset = beat_addr[11:0];
            bytes_left = 13'd4096 - {1'b0, page_offset};
            beats_left = bytes_left >> AXI_SIZE;
            if (beats_left == 13'd0) begin
                beats_to_4k_boundary = 9'd1;
            end else if (beats_left > 13'd256) begin
                beats_to_4k_boundary = 9'd256;
            end else begin
                beats_to_4k_boundary = beats_left[8:0];
            end
        end
    endfunction

    function automatic [8:0] burst_limit_for_addr(input [ADDR_WIDTH-1:0] beat_addr);
        reg [8:0] boundary_limit;
        begin
            boundary_limit = beats_to_4k_boundary(beat_addr);
            if (BURST_LEN_C < boundary_limit) begin
                burst_limit_for_addr = BURST_LEN_C;
            end else begin
                burst_limit_for_addr = boundary_limit;
            end
        end
    endfunction

    function automatic [ADDR_WIDTH-1:0] beats_to_bytes(input [8:0] beats);
        reg [ADDR_WIDTH-1:0] beats_ext;
        begin
            beats_ext = ADDR_WIDTH'(beats);
            beats_to_bytes = beats_ext << AXI_SIZE;
        end
    endfunction

    wire [8:0] current_limit = burst_limit_for_addr(addr);
    wire idle_timeout = (idle_count >= IDLE_CNT_WIDTH'(FLUSH_IDLE_CYCLES_C));
    wire buffer_full = (buf_count >= current_limit);
    wire burst_ready_now =
        (buf_count != 9'd0) &&
        !rd_pending &&
        (buffer_full || idle_timeout);
    wire burst_done = (beat_index == (burst_beats[7:0] - 8'd1));
    wire aw_fire = m_axi_awvalid && m_axi_awready;
    wire write_fire = m_axi_wvalid && m_axi_wready;
    wire b_fire = m_axi_bvalid && m_axi_bready;
    wire outstanding_room = (outstanding_count < OUTSTANDING_LIMIT);
    wire cfg_base_addr_changed = (cfg_base_addr != cfg_base_addr_seen);
    wire can_rebase_addr =
        (state == S_FILL) &&
        (buf_count == 9'd0) &&
        !rd_pending &&
        (outstanding_count == {OUTSTANDING_CNT_WIDTH{1'b0}});

    assign m_axi_awid    = AXI_ID;
    assign m_axi_awaddr  = addr;
    assign m_axi_awlen   = burst_beats[7:0] - 8'd1;
    assign m_axi_awsize  = AXI_SIZE;
    assign m_axi_awburst = 2'b01;
    assign m_axi_awlock  = 1'b0;
    assign m_axi_awcache = 4'b0011;
    assign m_axi_awprot  = 3'b000;
    assign m_axi_awqos   = 4'b0000;
    assign m_axi_awvalid = (state == S_AW) && outstanding_room;

    assign m_axi_wdata   = buf_mem[beat_index];
    assign m_axi_wstrb   = buf_strb[beat_index];
    assign m_axi_wlast   = burst_done;
    assign m_axi_wvalid  = (state == S_W);
    assign m_axi_bready  = enable && (outstanding_count != {OUTSTANDING_CNT_WIDTH{1'b0}});

    always @(*) begin
        fifo_rd_en = 1'b0;
        if (enable && (state == S_FILL) && !rd_pending && !fifo_empty &&
            !buffer_full && !burst_ready_now) begin
            fifo_rd_en = 1'b1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_FILL;
            addr         <= BASE_ADDR;
            burst_beats  <= 9'd0;
            beat_index   <= 8'd0;
            buf_count    <= 9'd0;
            idle_count   <= {IDLE_CNT_WIDTH{1'b0}};
            rd_pending   <= 1'b0;
            cfg_base_addr_seen <= BASE_ADDR;
            outstanding_count <= {OUTSTANDING_CNT_WIDTH{1'b0}};
            resp_error_seen <= 1'b0;
        end else begin
            case ({aw_fire, b_fire})
                2'b10: begin
                    if (outstanding_count != OUTSTANDING_LIMIT) begin
                        outstanding_count <= outstanding_count + OUTSTANDING_CNT_WIDTH'(1);
                    end
                end
                2'b01: begin
                    if (outstanding_count != {OUTSTANDING_CNT_WIDTH{1'b0}}) begin
                        outstanding_count <= outstanding_count - OUTSTANDING_CNT_WIDTH'(1);
                    end
                end
                default: begin
                    outstanding_count <= outstanding_count;
                end
            endcase

            if (b_fire && (m_axi_bresp != 2'b00)) begin
                resp_error_seen <= 1'b1;
            end

            if (can_rebase_addr && cfg_base_addr_changed) begin
                addr               <= cfg_base_addr;
                cfg_base_addr_seen <= cfg_base_addr;
                idle_count         <= {IDLE_CNT_WIDTH{1'b0}};
            end

            if (fifo_rd_en) begin
                rd_pending <= 1'b1;
            end

            if (fifo_rd_valid) begin
                rd_pending <= 1'b0;
                if ((state == S_FILL) && (buf_count < current_limit)) begin
                    buf_mem[buf_count[7:0]] <= fifo_rd_data;
                    buf_strb[buf_count[7:0]] <= fifo_rd_strb;
                    buf_count          <= buf_count + 9'd1;
                    idle_count         <= {IDLE_CNT_WIDTH{1'b0}};
                end
            end else if ((state == S_FILL) && (buf_count != 9'd0) && !burst_ready_now && fifo_empty && !rd_pending) begin
                if (idle_count != IDLE_CNT_WIDTH'(FLUSH_IDLE_CYCLES_C)) begin
                    idle_count <= idle_count + IDLE_CNT_WIDTH'(1);
                end
            end

            case (state)
                S_FILL: begin
                    if (burst_ready_now) begin
                        burst_beats <= buf_count;
                        beat_index  <= 8'd0;
                        state       <= S_AW;
                        idle_count  <= {IDLE_CNT_WIDTH{1'b0}};
                    end
                end

                S_AW: begin
                    if (aw_fire) begin
                        state <= S_W;
                    end
                end

                S_W: begin
                    if (write_fire) begin
                        if (burst_done) begin
                            addr        <= addr + beats_to_bytes(burst_beats);
                            buf_count   <= 9'd0;
                            beat_index  <= 8'd0;
                            idle_count  <= {IDLE_CNT_WIDTH{1'b0}};
                            state       <= S_FILL;
                        end else begin
                            beat_index <= beat_index + 8'd1;
                        end
                    end
                end

                default: begin
                    state <= S_FILL;
                end
            endcase
        end
    end

    wire unused_bresp = ^m_axi_bid ^ ^m_axi_bresp;

endmodule
