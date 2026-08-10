`timescale 1ns/1ps

module ddr_memtest_sync_fifo #(
    parameter int unsigned DATA_WIDTH = 256,
    parameter int unsigned DEPTH      = 16
) (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  wr_full,

    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   rd_valid,
    output wire                  rd_empty
);

    localparam int unsigned PTR_WIDTH = (DEPTH <= 2) ? 1 : $clog2(DEPTH);
    localparam int unsigned CNT_WIDTH = $clog2(DEPTH + 1);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;
    reg [CNT_WIDTH-1:0] count;
    reg [31:0] wr_count;
    reg [31:0] rd_count;

    wire fifo_empty_now = (count == {CNT_WIDTH{1'b0}});
    wire fifo_full_now  = (count == CNT_WIDTH'(DEPTH));
    wire do_read = rd_en && !fifo_empty_now;
    wire do_write = wr_en && (!fifo_full_now || do_read);

    assign wr_full  = fifo_full_now && !do_read;
    assign rd_empty = fifo_empty_now;

    function automatic [PTR_WIDTH-1:0] ptr_next(input [PTR_WIDTH-1:0] ptr);
        begin
            if (ptr == PTR_WIDTH'(DEPTH - 1)) begin
                ptr_next = {PTR_WIDTH{1'b0}};
            end else begin
                ptr_next = ptr + {{PTR_WIDTH-1{1'b0}}, 1'b1};
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr   <= {PTR_WIDTH{1'b0}};
            rd_ptr   <= {PTR_WIDTH{1'b0}};
            count    <= {CNT_WIDTH{1'b0}};
            wr_count <= 32'd0;
            rd_count <= 32'd0;
            rd_data  <= {DATA_WIDTH{1'b0}};
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= 1'b0;

            if (do_write) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= ptr_next(wr_ptr);
                wr_count <= wr_count + 32'd1;
            end

            if (do_read) begin
                rd_data <= mem[rd_ptr];
                rd_ptr <= ptr_next(rd_ptr);
                rd_valid <= 1'b1;
                rd_count <= rd_count + 32'd1;
            end

            case ({do_write, do_read})
                2'b10: count <= count + {{CNT_WIDTH-1{1'b0}}, 1'b1};
                2'b01: count <= count - {{CNT_WIDTH-1{1'b0}}, 1'b1};
                default: count <= count;
            endcase
        end
    end

endmodule
