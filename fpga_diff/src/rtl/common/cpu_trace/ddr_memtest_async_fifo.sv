`timescale 1ns/1ps

module ddr_memtest_async_fifo #(
    parameter int unsigned DATA_WIDTH = 512,
    parameter int unsigned DEPTH      = 1024,
    parameter int unsigned ADDR_WIDTH = $clog2(DEPTH)
) (
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  wr_full,

    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output reg                   rd_valid,
    output reg                   rd_empty
);

    localparam int unsigned PTR_WIDTH = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [PTR_WIDTH-1:0] wr_bin;
    reg [PTR_WIDTH-1:0] wr_gray;
    reg [PTR_WIDTH-1:0] rd_bin;
    reg [PTR_WIDTH-1:0] rd_gray;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [PTR_WIDTH-1:0] rd_gray_wrclk_1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [PTR_WIDTH-1:0] rd_gray_wrclk_2;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [PTR_WIDTH-1:0] wr_gray_rdclk_1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [PTR_WIDTH-1:0] wr_gray_rdclk_2;

    function automatic [PTR_WIDTH-1:0] bin2gray(input [PTR_WIDTH-1:0] bin);
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    function automatic [PTR_WIDTH-1:0] invert_top_two(input [PTR_WIDTH-1:0] value);
        begin
            invert_top_two = value;
            invert_top_two[PTR_WIDTH-1] = ~value[PTR_WIDTH-1];
            invert_top_two[PTR_WIDTH-2] = ~value[PTR_WIDTH-2];
        end
    endfunction

    assign wr_full = (wr_gray == invert_top_two(rd_gray_wrclk_2));

    wire wr_fire = wr_en && !wr_full;
    wire [PTR_WIDTH-1:0] wr_bin_next  = wr_bin + {{PTR_WIDTH-1{1'b0}}, wr_fire};
    wire [PTR_WIDTH-1:0] wr_gray_next = bin2gray(wr_bin_next);

    // rd_empty remains registered to avoid a combinational loop through
    // axi_write's combinational fifo_rd_en.
    wire rd_fire = rd_en && !rd_empty;
    wire [PTR_WIDTH-1:0] rd_bin_next  = rd_bin + {{PTR_WIDTH-1{1'b0}}, rd_fire};
    wire [PTR_WIDTH-1:0] rd_gray_next = bin2gray(rd_bin_next);
    wire rd_empty_next = (rd_gray_next == wr_gray_rdclk_2);

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_wrclk_1 <= {PTR_WIDTH{1'b0}};
            rd_gray_wrclk_2 <= {PTR_WIDTH{1'b0}};
        end else begin
            rd_gray_wrclk_1 <= rd_gray;
            rd_gray_wrclk_2 <= rd_gray_wrclk_1;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_rdclk_1 <= {PTR_WIDTH{1'b0}};
            wr_gray_rdclk_2 <= {PTR_WIDTH{1'b0}};
        end else begin
            wr_gray_rdclk_1 <= wr_gray;
            wr_gray_rdclk_2 <= wr_gray_rdclk_1;
        end
    end

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= {PTR_WIDTH{1'b0}};
            wr_gray <= {PTR_WIDTH{1'b0}};
        end else begin
            if (wr_fire) begin
                mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
            end
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin   <= {PTR_WIDTH{1'b0}};
            rd_gray  <= {PTR_WIDTH{1'b0}};
            rd_data  <= {DATA_WIDTH{1'b0}};
            rd_valid <= 1'b0;
            rd_empty <= 1'b1;
        end else begin
            rd_valid <= rd_fire;
            if (rd_fire) begin
                rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
            end
            rd_bin   <= rd_bin_next;
            rd_gray  <= rd_gray_next;
            rd_empty <= rd_empty_next;
        end
    end

endmodule
