`timescale 1ns/1ps

module ddr_memtest_cpu_axi_passive_ingress #(
    parameter int unsigned CPU_AXI_DATA_WIDTH = 4096,
    parameter int unsigned ID_WIDTH           = 4,
    parameter int unsigned ADDR_WIDTH         = 32,
    parameter int unsigned OUTSTANDING_BURSTS = 8
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           enable,
    input  wire [CPU_AXI_DATA_WIDTH/8-1:0] cfg_partial_wstrb,

    input  wire [ID_WIDTH-1:0]            s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]          s_axi_awaddr,
    input  wire [7:0]                     s_axi_awlen,
    input  wire [2:0]                     s_axi_awsize,
    input  wire [1:0]                     s_axi_awburst,
    input  wire                           s_axi_awvalid,
    output wire                           s_axi_awready,

    input  wire [CPU_AXI_DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [CPU_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                           s_axi_wlast,
    input  wire                           s_axi_wvalid,
    output wire                           s_axi_wready,

    output reg  [ID_WIDTH-1:0]            s_axi_bid,
    output reg  [1:0]                     s_axi_bresp,
    output reg                            s_axi_bvalid,
    input  wire                           s_axi_bready,

    output wire                           fifo_wr_en,
    output wire [CPU_AXI_DATA_WIDTH+2-1:0] fifo_wr_data,
    input  wire                           fifo_wr_full
);

    localparam int unsigned DATA_BYTES = CPU_AXI_DATA_WIDTH / 8;
    localparam [2:0] AXI_SIZE = (DATA_BYTES >= 128) ? 3'd7 : 3'($clog2(DATA_BYTES));
    localparam [ID_WIDTH-1:0] ZERO_ID = {ID_WIDTH{1'b0}};
    localparam int unsigned AW_DESC_WIDTH = ID_WIDTH + 9;
    localparam int unsigned RESP_WIDTH = ID_WIDTH + 2;
    localparam [1:0] STRB_CODE_PARTIAL = 2'b00;
    localparam [1:0] STRB_CODE_BAD     = 2'b10;
    localparam [1:0] STRB_CODE_FULL    = 2'b11;

    reg [ID_WIDTH-1:0] aw_id;
    reg [8:0]          aw_beats_left;
    reg                aw_active;
    reg                burst_error;
    reg                aw_load_pending;
    reg                resp_load_pending;
    reg                b_valid;
    reg [ID_WIDTH-1:0] b_id;
    reg [1:0]          b_resp;

    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid  && s_axi_wready;
    wire b_fire  = b_valid && s_axi_bready;
    wire full_strobe = &s_axi_wstrb;
    wire partial_strobe = (s_axi_wstrb == cfg_partial_wstrb);
    wire supported_strobe = full_strobe || partial_strobe;
    wire [1:0] strobe_code = full_strobe ? STRB_CODE_FULL :
                              partial_strobe ? STRB_CODE_PARTIAL :
                              STRB_CODE_BAD;
    wire aw_bad = (s_axi_awsize != AXI_SIZE) || (s_axi_awburst != 2'b01);
    wire wlast_expected = (aw_beats_left == 9'd1);
    wire wlast_bad = (s_axi_wlast != wlast_expected);
    wire burst_done = wlast_expected || s_axi_wlast;
    wire resp_code_error = burst_error || !supported_strobe || wlast_bad;

    wire [AW_DESC_WIDTH-1:0] aw_desc_wr_data = {aw_bad, s_axi_awlen, s_axi_awid};
    wire [AW_DESC_WIDTH-1:0] aw_desc_rd_data;
    wire aw_desc_wr_en = aw_fire;
    wire aw_desc_rd_en;
    wire aw_desc_wr_full;
    wire aw_desc_rd_valid;
    wire aw_desc_empty;

    wire [RESP_WIDTH-1:0] resp_fifo_wr_data = {aw_id, resp_code_error ? 2'b10 : 2'b00};
    wire [RESP_WIDTH-1:0] resp_fifo_rd_data;
    wire resp_fifo_wr_en = w_fire && burst_done;
    wire resp_fifo_rd_en;
    wire resp_fifo_wr_full;
    wire resp_fifo_rd_valid;
    wire resp_fifo_empty;
    wire aw_desc_space_available;
    wire resp_space_available;

    assign aw_desc_space_available = !aw_desc_wr_full || aw_desc_rd_en;
    assign resp_space_available = !resp_fifo_wr_full || resp_fifo_rd_en;

    assign s_axi_awready = enable && aw_desc_space_available;
    assign s_axi_wready  = enable && aw_active && !fifo_wr_full &&
                           (!wlast_expected || resp_space_available);
    assign fifo_wr_en    = w_fire && supported_strobe;
    assign fifo_wr_data  = {strobe_code, s_axi_wdata};

    assign aw_desc_rd_en = enable && !aw_active && !aw_load_pending && !aw_desc_empty;
    assign resp_fifo_rd_en = enable && !b_valid && !resp_load_pending && !resp_fifo_empty;

    ddr_memtest_sync_fifo #(
        .DATA_WIDTH (AW_DESC_WIDTH),
        .DEPTH      (OUTSTANDING_BURSTS)
    ) u_aw_desc_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (aw_desc_wr_en),
        .wr_data  (aw_desc_wr_data),
        .wr_full  (aw_desc_wr_full),
        .rd_en    (aw_desc_rd_en),
        .rd_data  (aw_desc_rd_data),
        .rd_valid (aw_desc_rd_valid),
        .rd_empty (aw_desc_empty)
    );

    ddr_memtest_sync_fifo #(
        .DATA_WIDTH (RESP_WIDTH),
        .DEPTH      (OUTSTANDING_BURSTS)
    ) u_resp_fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (resp_fifo_wr_en),
        .wr_data  (resp_fifo_wr_data),
        .wr_full  (resp_fifo_wr_full),
        .rd_en    (resp_fifo_rd_en),
        .rd_data  (resp_fifo_rd_data),
        .rd_valid (resp_fifo_rd_valid),
        .rd_empty (resp_fifo_empty)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_id           <= ZERO_ID;
            aw_beats_left   <= 9'd0;
            aw_active       <= 1'b0;
            burst_error     <= 1'b0;
            s_axi_bid       <= ZERO_ID;
            s_axi_bresp     <= 2'b00;
            b_valid         <= 1'b0;
            aw_load_pending <= 1'b0;
            resp_load_pending <= 1'b0;
            b_id            <= ZERO_ID;
            b_resp          <= 2'b00;
        end else begin
            if (b_fire) begin
                b_valid <= 1'b0;
            end

            if (aw_desc_rd_valid) begin
                aw_id           <= aw_desc_rd_data[ID_WIDTH-1:0];
                aw_beats_left   <= {1'b0, aw_desc_rd_data[ID_WIDTH +: 8]} + 9'd1;
                aw_active       <= 1'b1;
                burst_error     <= aw_desc_rd_data[AW_DESC_WIDTH-1];
                aw_load_pending <= 1'b0;
            end else if (aw_desc_rd_en) begin
                aw_load_pending <= 1'b1;
            end

            if (w_fire) begin
                if (!supported_strobe || wlast_bad) begin
                    burst_error    <= 1'b1;
                end

                if (burst_done) begin
                    aw_active    <= 1'b0;
                    aw_beats_left <= 9'd0;
                    burst_error   <= 1'b0;
                end else begin
                    aw_beats_left <= aw_beats_left - 9'd1;
                end
            end

            if (resp_fifo_rd_valid) begin
                b_id            <= resp_fifo_rd_data[RESP_WIDTH-1:2];
                b_resp          <= resp_fifo_rd_data[1:0];
                b_valid         <= 1'b1;
                resp_load_pending <= 1'b0;
                s_axi_bid       <= resp_fifo_rd_data[RESP_WIDTH-1:2];
                s_axi_bresp     <= resp_fifo_rd_data[1:0];
            end else if (resp_fifo_rd_en) begin
                resp_load_pending <= 1'b1;
            end

            if (resp_fifo_wr_en) begin
                s_axi_bid   <= aw_id;
                s_axi_bresp <= resp_code_error ? 2'b10 : 2'b00;
                if (!b_valid && !resp_load_pending && resp_fifo_empty) begin
                    b_id   <= aw_id;
                    b_resp <= resp_code_error ? 2'b10 : 2'b00;
                end
            end
        end
    end

    wire unused_awaddr = ^s_axi_awaddr;

    assign s_axi_bvalid = b_valid;

endmodule
