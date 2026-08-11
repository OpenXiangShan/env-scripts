`timescale 1ns/1ps

// Gray-pointer asynchronous FIFO with storage split into beat-width banks.
module Difftest2AXI4AsyncFIFO #(
  parameter integer DATA_WIDTH = 1,
  parameter integer BANK_WIDTH = 1,
  parameter integer DEPTH = 16,
  parameter integer ADDR_WIDTH = $clog2(DEPTH)
) (
  input  wire                    wr_clk,
  input  wire                    wr_ctrl_clk,
  input  wire                    wr_resetn,
  input  wire [DATA_WIDTH-1:0]   wr_data,
  input  wire                    wr_valid,
  output wire                    wr_ready,
  input  wire                    rd_clk,
  input  wire                    rd_resetn,
  output wire [DATA_WIDTH-1:0]   rd_data,
  output wire                    rd_valid,
  input  wire                    rd_ready
);

  localparam integer STORAGE_BANK_WIDTH =
    (BANK_WIDTH < DATA_WIDTH) ? BANK_WIDTH : DATA_WIDTH;
  localparam integer NUM_BANKS =
    (DATA_WIDTH + STORAGE_BANK_WIDTH - 1) / STORAGE_BANK_WIDTH;
  localparam integer PADDED_WIDTH = NUM_BANKS * STORAGE_BANK_WIDTH;
  localparam integer PTR_WIDTH = ADDR_WIDTH + 1;

  wire [PADDED_WIDTH-1:0] wr_data_padded =
    {{(PADDED_WIDTH-DATA_WIDTH){1'b0}}, wr_data};
  wire [PADDED_WIDTH-1:0] rd_data_padded;

  reg [PTR_WIDTH-1:0] wr_bin;
  reg [PTR_WIDTH-1:0] wr_gray;
  reg [PTR_WIDTH-1:0] rd_bin;
  reg [PTR_WIDTH-1:0] rd_gray;

  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rd_gray_sync_1;
  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] rd_gray_sync_2;
  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wr_gray_sync_1;
  (* ASYNC_REG = "TRUE" *) reg [PTR_WIDTH-1:0] wr_gray_sync_2;

  wire [PTR_WIDTH-1:0] wr_bin_incremented = wr_bin + 1'b1;
  wire [PTR_WIDTH-1:0] wr_gray_incremented =
    (wr_bin_incremented >> 1) ^ wr_bin_incremented;
  wire [PTR_WIDTH-1:0] rd_gray_full_compare = {
    ~rd_gray_sync_2[PTR_WIDTH-1:PTR_WIDTH-2],
    rd_gray_sync_2[PTR_WIDTH-3:0]
  };
  wire wr_full = wr_gray_incremented == rd_gray_full_compare;
  wire wr_push = wr_valid && wr_ready;

  wire rd_empty = rd_gray == wr_gray_sync_2;
  wire rd_pop = rd_valid && rd_ready;
  wire [PTR_WIDTH-1:0] rd_bin_incremented = rd_bin + 1'b1;
  wire [PTR_WIDTH-1:0] rd_gray_incremented =
    (rd_bin_incremented >> 1) ^ rd_bin_incremented;

  assign wr_ready = wr_resetn && !wr_full;
  assign rd_valid = rd_resetn && !rd_empty;
  assign rd_data = rd_data_padded[DATA_WIDTH-1:0];

  genvar bank_idx;
  generate
    for (bank_idx = 0; bank_idx < NUM_BANKS; bank_idx = bank_idx + 1) begin : gen_fifo_banks
      reg [STORAGE_BANK_WIDTH-1:0] memory [0:DEPTH-1];

      always @(posedge wr_clk) begin
        if (wr_push)
          memory[wr_bin[ADDR_WIDTH-1:0]] <=
            wr_data_padded[bank_idx*STORAGE_BANK_WIDTH +: STORAGE_BANK_WIDTH];
      end

      assign rd_data_padded[bank_idx*STORAGE_BANK_WIDTH +: STORAGE_BANK_WIDTH] =
        memory[rd_bin[ADDR_WIDTH-1:0]];
    end
  endgenerate

  always @(posedge wr_clk) begin
    if (!wr_resetn) begin
      wr_bin <= {PTR_WIDTH{1'b0}};
      wr_gray <= {PTR_WIDTH{1'b0}};
    end else if (wr_push) begin
      wr_bin <= wr_bin_incremented;
      wr_gray <= wr_gray_incremented;
    end
  end

  always @(posedge rd_clk) begin
    if (!rd_resetn) begin
      rd_bin <= {PTR_WIDTH{1'b0}};
      rd_gray <= {PTR_WIDTH{1'b0}};
    end else if (rd_pop) begin
      rd_bin <= rd_bin_incremented;
      rd_gray <= rd_gray_incremented;
    end
  end

  // Keep pointer synchronization alive when wr_clk is stopped by backpressure.
  always @(posedge wr_ctrl_clk) begin
    if (!wr_resetn) begin
      rd_gray_sync_1 <= {PTR_WIDTH{1'b0}};
      rd_gray_sync_2 <= {PTR_WIDTH{1'b0}};
    end else begin
      rd_gray_sync_1 <= rd_gray;
      rd_gray_sync_2 <= rd_gray_sync_1;
    end
  end

  always @(posedge rd_clk) begin
    if (!rd_resetn) begin
      wr_gray_sync_1 <= {PTR_WIDTH{1'b0}};
      wr_gray_sync_2 <= {PTR_WIDTH{1'b0}};
    end else begin
      wr_gray_sync_1 <= wr_gray;
      wr_gray_sync_2 <= wr_gray_sync_1;
    end
  end

`ifndef SYNTHESIS
  initial begin
    if (DATA_WIDTH < 1)
      $error("DATA_WIDTH must be positive");
    if (BANK_WIDTH < 1)
      $error("BANK_WIDTH must be positive");
    if ((DEPTH < 4) || ((DEPTH & (DEPTH - 1)) != 0))
      $error("DEPTH must be a power of two and at least 4");
    if (ADDR_WIDTH != $clog2(DEPTH))
      $error("ADDR_WIDTH must equal clog2(DEPTH)");
  end
`endif

endmodule
