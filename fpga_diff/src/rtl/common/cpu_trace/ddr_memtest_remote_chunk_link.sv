`timescale 1ns/1ps

// Registered, backpressured serializer for a partition boundary.  Keeping the
// forward cut below one UVHS LVDS route avoids TDM-expanding a complete AXI
// write channel across two FPGAs.
module ddr_memtest_remote_chunk_source #(
    parameter int unsigned DATA_WIDTH = 256,
    parameter int unsigned STRB_WIDTH = DATA_WIDTH / 8,
    parameter int unsigned FLIT_WIDTH = 128
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  chunk_wr_en,
    input  wire [DATA_WIDTH-1:0] chunk_wr_data,
    input  wire [STRB_WIDTH-1:0] chunk_wr_strb,
    output wire                  chunk_wr_full,
    output wire [FLIT_WIDTH-1:0] tx_data,
    output wire                  tx_valid,
    input  wire                  tx_ready
);
    localparam int unsigned PAYLOAD_WIDTH = DATA_WIDTH + STRB_WIDTH;
    localparam int unsigned NUM_FLITS =
        (PAYLOAD_WIDTH + FLIT_WIDTH - 1) / FLIT_WIDTH;
    localparam int unsigned PADDED_WIDTH = NUM_FLITS * FLIT_WIDTH;
    localparam int unsigned COUNT_WIDTH =
        (NUM_FLITS < 2) ? 1 : $clog2(NUM_FLITS + 1);

    reg [PADDED_WIDTH-1:0] payload_shift;
    reg [COUNT_WIDTH-1:0] flits_left;

    assign tx_valid = (flits_left != {COUNT_WIDTH{1'b0}});
    assign tx_data = payload_shift[FLIT_WIDTH-1:0];
    assign chunk_wr_full = tx_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            payload_shift <= {PADDED_WIDTH{1'b0}};
            flits_left <= {COUNT_WIDTH{1'b0}};
        end else begin
            if (tx_valid && tx_ready) begin
                payload_shift <= payload_shift >> FLIT_WIDTH;
                flits_left <= flits_left - COUNT_WIDTH'(1);
            end

            if (chunk_wr_en && !chunk_wr_full) begin
                payload_shift <= {
                    {(PADDED_WIDTH-PAYLOAD_WIDTH){1'b0}},
                    chunk_wr_strb,
                    chunk_wr_data
                };
                flits_left <= COUNT_WIDTH'(NUM_FLITS);
            end
        end
    end
endmodule

// The sink, local FIFO, and AXI writer are one hierarchy so the partition
// constraint can keep all full-width AXI traffic beside the CH1 DDR on F1.
module ddr_memtest_remote_chunk_sink #(
    parameter int unsigned AXI_DATA_WIDTH = 256,
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned ID_WIDTH = 4,
    parameter int unsigned FIFO_DEPTH = 1024,
    parameter int unsigned BURST_LEN = 16,
    parameter int unsigned FLUSH_IDLE_CYCLES = 32,
    parameter int unsigned OUTSTANDING_BURSTS = 8,
    parameter int unsigned FLIT_WIDTH = 128,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = {ADDR_WIDTH{1'b0}},
    parameter [ID_WIDTH-1:0] AXI_ID = {ID_WIDTH{1'b0}}
) (
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       enable,
    input  wire [ADDR_WIDTH-1:0]      cfg_base_addr,
    input  wire [FLIT_WIDTH-1:0]      rx_data,
    input  wire                       rx_valid,
    output wire                       rx_ready,

    output wire [ID_WIDTH-1:0]        m_axi_awid,
    output wire [ADDR_WIDTH-1:0]      m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire [3:0]                 m_axi_awqos,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [ID_WIDTH-1:0]        m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready
);
    localparam int unsigned STRB_WIDTH = AXI_DATA_WIDTH / 8;
    localparam int unsigned PAYLOAD_WIDTH = AXI_DATA_WIDTH + STRB_WIDTH;
    localparam int unsigned NUM_FLITS =
        (PAYLOAD_WIDTH + FLIT_WIDTH - 1) / FLIT_WIDTH;
    localparam int unsigned PADDED_WIDTH = NUM_FLITS * FLIT_WIDTH;
    localparam int unsigned INDEX_WIDTH =
        (NUM_FLITS < 2) ? 1 : $clog2(NUM_FLITS);

    reg [PADDED_WIDTH-1:0] assembly;
    reg [INDEX_WIDTH-1:0] flit_index;
    reg [PADDED_WIDTH-1:0] assembly_next;
    integer i;

    wire fifo_full;
    wire fifo_empty;
    wire fifo_rd_en;
    wire fifo_rd_valid;
    wire [PAYLOAD_WIDTH-1:0] fifo_rd_payload;
    wire rx_fire = rx_valid && rx_ready;
    wire last_flit = (flit_index == INDEX_WIDTH'(NUM_FLITS - 1));
    wire fifo_wr_en = rx_fire && last_flit;
    wire [PAYLOAD_WIDTH-1:0] fifo_wr_payload =
        assembly_next[PAYLOAD_WIDTH-1:0];

    always @(*) begin
        assembly_next = assembly;
        for (i = 0; i < NUM_FLITS; i = i + 1) begin
            if (flit_index == INDEX_WIDTH'(i)) begin
                assembly_next[i*FLIT_WIDTH +: FLIT_WIDTH] = rx_data;
            end
        end
    end

    // Backpressure may cross the partition as one registered-source control
    // path.  The payload remains stable at the source until this is asserted.
    assign rx_ready = !fifo_full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            assembly <= {PADDED_WIDTH{1'b0}};
            flit_index <= {INDEX_WIDTH{1'b0}};
        end else if (rx_fire) begin
            if (last_flit) begin
                assembly <= {PADDED_WIDTH{1'b0}};
                flit_index <= {INDEX_WIDTH{1'b0}};
            end else begin
                assembly <= assembly_next;
                flit_index <= flit_index + INDEX_WIDTH'(1);
            end
        end
    end

    ddr_memtest_sync_fifo #(
        .DATA_WIDTH (PAYLOAD_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) u_chunk_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (fifo_wr_en),
        .wr_data  (fifo_wr_payload),
        .wr_full  (fifo_full),
        .rd_en    (fifo_rd_en),
        .rd_data  (fifo_rd_payload),
        .rd_valid (fifo_rd_valid),
        .rd_empty (fifo_empty)
    );

    ddr_memtest_axi_write_stream #(
        .AXI_DATA_WIDTH     (AXI_DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .BURST_LEN          (BURST_LEN),
        .FLUSH_IDLE_CYCLES  (FLUSH_IDLE_CYCLES),
        .OUTSTANDING_BURSTS (OUTSTANDING_BURSTS),
        .BASE_ADDR          (BASE_ADDR),
        .AXI_ID             (AXI_ID)
    ) u_write_stream (
        .clk           (clk),
        .rst_n         (rst_n),
        .enable        (enable),
        .cfg_base_addr (cfg_base_addr),
        .fifo_rd_en    (fifo_rd_en),
        .fifo_rd_data  (fifo_rd_payload[AXI_DATA_WIDTH-1:0]),
        .fifo_rd_strb  (fifo_rd_payload[AXI_DATA_WIDTH +: STRB_WIDTH]),
        .fifo_rd_valid (fifo_rd_valid),
        .fifo_empty    (fifo_empty),
        .m_axi_awid    (m_axi_awid),
        .m_axi_awaddr  (m_axi_awaddr),
        .m_axi_awlen   (m_axi_awlen),
        .m_axi_awsize  (m_axi_awsize),
        .m_axi_awburst (m_axi_awburst),
        .m_axi_awlock  (m_axi_awlock),
        .m_axi_awcache (m_axi_awcache),
        .m_axi_awprot  (m_axi_awprot),
        .m_axi_awqos   (m_axi_awqos),
        .m_axi_awvalid (m_axi_awvalid),
        .m_axi_awready (m_axi_awready),
        .m_axi_wdata   (m_axi_wdata),
        .m_axi_wstrb   (m_axi_wstrb),
        .m_axi_wlast   (m_axi_wlast),
        .m_axi_wvalid  (m_axi_wvalid),
        .m_axi_wready  (m_axi_wready),
        .m_axi_bid     (m_axi_bid),
        .m_axi_bresp   (m_axi_bresp),
        .m_axi_bvalid  (m_axi_bvalid),
        .m_axi_bready  (m_axi_bready)
    );
endmodule
