`timescale 1ns/1ps

module ddr_memtest_cpu_axi_passive_stripe_dispatch #(
    parameter int unsigned AXI_DATA_WIDTH     = 256,
    parameter int unsigned MAX_CPU_DATA_WIDTH = 4096
) (
    input  wire                        clk,
    input  wire                        rst_n,
    input  wire                        enable,
    input  wire [MAX_CPU_DATA_WIDTH/8-1:0] cfg_partial_wstrb,

    output reg                         cpu_fifo_rd_en,
    input  wire [MAX_CPU_DATA_WIDTH+2-1:0] cpu_fifo_rd_data,
    input  wire                        cpu_fifo_rd_valid,
    input  wire                        cpu_fifo_empty,

    output reg                         ch0_fifo_wr_en,
    output reg  [AXI_DATA_WIDTH-1:0]   ch0_fifo_wr_data,
    output reg  [AXI_DATA_WIDTH/8-1:0] ch0_fifo_wr_strb,
    input  wire                        ch0_fifo_wr_full,

    output reg                         ch1_fifo_wr_en,
    output reg  [AXI_DATA_WIDTH-1:0]   ch1_fifo_wr_data,
    output reg  [AXI_DATA_WIDTH/8-1:0] ch1_fifo_wr_strb,
    input  wire                        ch1_fifo_wr_full,

    output wire                        strobe_code_valid,
    output wire [1:0]                  strobe_code,
    input  wire                        strobe_code_ready
);

    localparam [15:0] MAX_CPU_CHUNKS =
        16'(MAX_CPU_DATA_WIDTH / AXI_DATA_WIDTH);
    localparam int unsigned CPU_STRB_WIDTH = MAX_CPU_DATA_WIDTH / 8;
    localparam int unsigned AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;

    localparam [1:0] STRB_CODE_PARTIAL = 2'b00;
    localparam [1:0] STRB_CODE_FULL    = 2'b11;

    localparam [1:0] S_READ     = 2'd0;
    localparam [1:0] S_DISPATCH = 2'd1;

    reg [1:0] state;
    reg [MAX_CPU_DATA_WIDTH-1:0] cpu_word_buf;
    reg [1:0] cpu_word_strobe_code;
    reg [MAX_CPU_DATA_WIDTH-1:0] pending_word_buf;
    reg [1:0] pending_word_strobe_code;
    reg pending_word_valid;
    reg [15:0] pair_chunk;
    reg ch0_pair_sent;
    reg ch1_pair_sent;
    reg rd_pending;
    reg strobe_code_pending;

    wire dispatch_enable = enable && !strobe_code_pending;
    wire ch0_needed = (pair_chunk < MAX_CPU_CHUNKS);
    wire ch1_needed = ((pair_chunk + 16'd1) < MAX_CPU_CHUNKS);
    wire ch0_can_send =
        dispatch_enable && (state == S_DISPATCH) && ch0_needed &&
        !ch0_pair_sent && !ch0_fifo_wr_full;
    wire ch1_can_send =
        dispatch_enable && (state == S_DISPATCH) && ch1_needed &&
        !ch1_pair_sent && !ch1_fifo_wr_full;
    wire ch0_pair_complete = !ch0_needed || ch0_pair_sent || ch0_can_send;
    wire ch1_pair_complete = !ch1_needed || ch1_pair_sent || ch1_can_send;
    wire pair_complete = ch0_pair_complete && ch1_pair_complete;
    wire last_pair_for_word = ((pair_chunk + 16'd2) >= MAX_CPU_CHUNKS);
    wire [15:0] pair_chunk_next = pair_chunk + 16'd2;
    wire strobe_code_fire = strobe_code_valid && strobe_code_ready;

    assign strobe_code_valid = strobe_code_pending;
    assign strobe_code = cpu_word_strobe_code;

    function automatic [AXI_DATA_WIDTH-1:0] select_chunk(
        input [MAX_CPU_DATA_WIDTH-1:0] word_data,
        input [15:0]                   chunk_id
    );
        integer i;
        begin
            select_chunk = {AXI_DATA_WIDTH{1'b0}};
            for (i = 0; i < MAX_CPU_CHUNKS; i = i + 1) begin
                if (chunk_id == 16'(i)) begin
                    select_chunk = word_data[i*AXI_DATA_WIDTH +: AXI_DATA_WIDTH];
                end
            end
        end
    endfunction

    function automatic [CPU_STRB_WIDTH-1:0] decode_cpu_strb(
        input [1:0] code
    );
        begin
            case (code)
                STRB_CODE_FULL: begin
                    decode_cpu_strb = {CPU_STRB_WIDTH{1'b1}};
                end
                STRB_CODE_PARTIAL: begin
                    decode_cpu_strb = cfg_partial_wstrb;
                end
                default: begin
                    decode_cpu_strb = {CPU_STRB_WIDTH{1'b0}};
                end
            endcase
        end
    endfunction

    function automatic [AXI_STRB_WIDTH-1:0] select_strb(
        input [CPU_STRB_WIDTH-1:0] word_strb,
        input [15:0]               chunk_id
    );
        integer i;
        begin
            select_strb = {AXI_STRB_WIDTH{1'b0}};
            for (i = 0; i < MAX_CPU_CHUNKS; i = i + 1) begin
                if (chunk_id == 16'(i)) begin
                    select_strb = word_strb[i*AXI_STRB_WIDTH +: AXI_STRB_WIDTH];
                end
            end
        end
    endfunction

    always @(*) begin
        cpu_fifo_rd_en = 1'b0;
        if (enable && (state == S_READ) && !pending_word_valid &&
            !rd_pending && !cpu_fifo_empty) begin
            cpu_fifo_rd_en = 1'b1;
        end
    end

    always @(*) begin
        ch0_fifo_wr_en   = 1'b0;
        ch1_fifo_wr_en   = 1'b0;
        ch0_fifo_wr_data = select_chunk(cpu_word_buf, pair_chunk);
        ch1_fifo_wr_data = select_chunk(cpu_word_buf, pair_chunk + 16'd1);
        ch0_fifo_wr_strb = select_strb(decode_cpu_strb(cpu_word_strobe_code), pair_chunk);
        ch1_fifo_wr_strb = select_strb(decode_cpu_strb(cpu_word_strobe_code), pair_chunk + 16'd1);

        ch0_fifo_wr_en = ch0_can_send;
        ch1_fifo_wr_en = ch1_can_send;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_READ;
            cpu_word_buf   <= {MAX_CPU_DATA_WIDTH{1'b0}};
            cpu_word_strobe_code <= STRB_CODE_FULL;
            pending_word_buf <= {MAX_CPU_DATA_WIDTH{1'b0}};
            pending_word_strobe_code <= STRB_CODE_FULL;
            pending_word_valid <= 1'b0;
            pair_chunk     <= 16'd0;
            ch0_pair_sent  <= 1'b0;
            ch1_pair_sent  <= 1'b0;
            rd_pending     <= 1'b0;
            strobe_code_pending <= 1'b0;
        end else begin
            if (strobe_code_fire) begin
                strobe_code_pending <= 1'b0;
            end

            if (cpu_fifo_rd_en) begin
                rd_pending <= 1'b1;
            end

            if (cpu_fifo_rd_valid) begin
                rd_pending <= 1'b0;
            end

            case (state)
                S_READ: begin
                    if (pending_word_valid) begin
                        cpu_word_buf <= pending_word_buf;
                        cpu_word_strobe_code <= pending_word_strobe_code;
                        pair_chunk <= 16'd0;
                        ch0_pair_sent <= 1'b0;
                        ch1_pair_sent <= 1'b0;
                        strobe_code_pending <= 1'b1;
                        state <= S_DISPATCH;

                        if (cpu_fifo_rd_valid) begin
                            pending_word_buf <= cpu_fifo_rd_data[MAX_CPU_DATA_WIDTH-1:0];
                            pending_word_strobe_code <= cpu_fifo_rd_data[MAX_CPU_DATA_WIDTH +: 2];
                            pending_word_valid <= 1'b1;
                        end else begin
                            pending_word_valid <= 1'b0;
                        end
                    end else if (cpu_fifo_rd_valid) begin
                        cpu_word_buf <= cpu_fifo_rd_data[MAX_CPU_DATA_WIDTH-1:0];
                        cpu_word_strobe_code <= cpu_fifo_rd_data[MAX_CPU_DATA_WIDTH +: 2];
                        pair_chunk <= 16'd0;
                        ch0_pair_sent <= 1'b0;
                        ch1_pair_sent <= 1'b0;
                        strobe_code_pending <= 1'b1;
                        state <= S_DISPATCH;
                    end
                end

                S_DISPATCH: begin
                    if (cpu_fifo_rd_valid && !pending_word_valid) begin
                        pending_word_buf <= cpu_fifo_rd_data[MAX_CPU_DATA_WIDTH-1:0];
                        pending_word_strobe_code <= cpu_fifo_rd_data[MAX_CPU_DATA_WIDTH +: 2];
                        pending_word_valid <= 1'b1;
                    end

                    if (ch0_can_send) begin
                        ch0_pair_sent <= 1'b1;
                    end
                    if (ch1_can_send) begin
                        ch1_pair_sent <= 1'b1;
                    end

                    if (pair_complete) begin
                        if (last_pair_for_word) begin
                            pair_chunk    <= 16'd0;
                            ch0_pair_sent <= 1'b0;
                            ch1_pair_sent <= 1'b0;
                            state         <= S_READ;
                        end else begin
                            pair_chunk    <= pair_chunk_next;
                            ch0_pair_sent <= 1'b0;
                            ch1_pair_sent <= 1'b0;
                        end
                    end
                end

                default: begin
                    state <= S_READ;
                end
            endcase
        end
    end

endmodule
