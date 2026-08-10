`timescale 1ns/1ps

module ddr_memtest_strobe_code_packer #(
    parameter int unsigned AXI_DATA_WIDTH    = 256,
    parameter int unsigned FLUSH_IDLE_CYCLES = 32
) (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      enable,

    input  wire                      code_valid,
    input  wire [1:0]                code,
    output wire                      code_ready,

    output reg                       meta_fifo_wr_en,
    output reg  [AXI_DATA_WIDTH-1:0] meta_fifo_wr_data,
    input  wire                      meta_fifo_wr_full
);

    localparam int unsigned CODES_PER_WORD = AXI_DATA_WIDTH / 2;
    localparam int unsigned COUNT_WIDTH    = $clog2(CODES_PER_WORD + 1);
    localparam [1:0] STRB_CODE_INVALID     = 2'b10;
    localparam int unsigned FLUSH_IDLE_CYCLES_C =
        (FLUSH_IDLE_CYCLES < 1) ? 1 : FLUSH_IDLE_CYCLES;
    localparam int unsigned IDLE_CNT_WIDTH =
        (FLUSH_IDLE_CYCLES_C < 2) ? 1 : $clog2(FLUSH_IDLE_CYCLES_C + 1);

    reg [AXI_DATA_WIDTH-1:0] code_buf;
    reg [COUNT_WIDTH-1:0] code_count;
    reg [IDLE_CNT_WIDTH-1:0] idle_count;

    wire flush_due = enable &&
                     (code_count != {COUNT_WIDTH{1'b0}}) &&
                     (idle_count >= IDLE_CNT_WIDTH'(FLUSH_IDLE_CYCLES_C));
    wire can_finish_full_word =
        (code_count < COUNT_WIDTH'(CODES_PER_WORD - 1)) || !meta_fifo_wr_full;
    wire code_fire = code_valid && code_ready;
    wire full_word_fire = code_fire &&
                          (code_count == COUNT_WIDTH'(CODES_PER_WORD - 1));
    wire idle_flush_fire = flush_due && !meta_fifo_wr_full;

    assign code_ready = enable && !flush_due && can_finish_full_word;

    function automatic [AXI_DATA_WIDTH-1:0] invalid_word;
        begin
            invalid_word = {CODES_PER_WORD{STRB_CODE_INVALID}};
        end
    endfunction

    function automatic [AXI_DATA_WIDTH-1:0] set_code_at(
        input [AXI_DATA_WIDTH-1:0] in_word,
        input [COUNT_WIDTH-1:0]    idx,
        input [1:0]                in_code
    );
        integer i;
        begin
            set_code_at = in_word;
            for (i = 0; i < CODES_PER_WORD; i = i + 1) begin
                if (idx == COUNT_WIDTH'(i)) begin
                    set_code_at[i*2 +: 2] = in_code;
                end
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_buf          <= invalid_word();
            code_count        <= {COUNT_WIDTH{1'b0}};
            idle_count        <= {IDLE_CNT_WIDTH{1'b0}};
            meta_fifo_wr_en   <= 1'b0;
            meta_fifo_wr_data <= {AXI_DATA_WIDTH{1'b0}};
        end else begin
            meta_fifo_wr_en <= 1'b0;

            if (full_word_fire) begin
                meta_fifo_wr_en   <= 1'b1;
                meta_fifo_wr_data <= set_code_at(code_buf, code_count, code);
                code_buf          <= invalid_word();
                code_count        <= {COUNT_WIDTH{1'b0}};
                idle_count        <= {IDLE_CNT_WIDTH{1'b0}};
            end else if (idle_flush_fire) begin
                meta_fifo_wr_en   <= 1'b1;
                meta_fifo_wr_data <= code_buf;
                code_buf          <= invalid_word();
                code_count        <= {COUNT_WIDTH{1'b0}};
                idle_count        <= {IDLE_CNT_WIDTH{1'b0}};
            end else if (code_fire) begin
                code_buf   <= set_code_at(code_buf, code_count, code);
                code_count <= code_count + {{COUNT_WIDTH-1{1'b0}}, 1'b1};
                idle_count <= {IDLE_CNT_WIDTH{1'b0}};
            end else if (enable && (code_count != {COUNT_WIDTH{1'b0}})) begin
                if (idle_count != IDLE_CNT_WIDTH'(FLUSH_IDLE_CYCLES_C)) begin
                    idle_count <= idle_count + IDLE_CNT_WIDTH'(1);
                end
            end
        end
    end

endmodule
