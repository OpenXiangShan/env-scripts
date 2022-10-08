module tb_top();

  // clock generation
  reg clock;

`ifdef VCS
  always #1 clock = ~clock;
  initial begin
    clock = 0;
  end
`endif // VCS

`ifdef PALLADIUM
  IXCclkgen #(1) (clock);
`endif // PALLADIUM

  // reset generation
  reg reset;
  reg [7:0] reset_cycles;

  initial begin
    reset = 1;
    reset_cycles = 0;
  end

  always @(posedge clock) begin
    reset_cycles <= reset_cycles + 8'd1;
    if (reset && (&reset_cycles)) begin
      reset <= 1'b0;
    end
  end

  // Other simulation arguments
  initial begin
`ifdef VCS
    // enable waveform
    if ($test$plusargs("dump-wave")) begin
      $vcdplusfile("simv.vpd");
      $vcdpluson;
    end
`endif // VCS
  end

`ifdef SIM_UART
  wire       uart_out_valid;
  wire [7:0] uart_out_ch;
  wire       uart_in_valid;
  wire [7:0] uart_in_ch;

  assign uart_in_ch    = 8'hff;

  always @(posedge clock) begin
    if (!reset) begin
      if (uart_out_valid) begin
        // print to stderr
        $fwrite(32'h80000002, "%c", uart_out_ch);
        $fflush(32'h80000002);
      end
    end
  end
`endif // SIM_UART

  `TOP_MODULE top (
    .clock             (clock          ),
    .reset             (reset          )
`ifdef SIM_UART
    ,
    .io_uart_out_valid (uart_out_valid ),
    .io_uart_out_ch    (uart_out_ch    ),
    .io_uart_in_valid  (uart_in_valid  ),
    .io_uart_in_ch     (uart_in_ch     )
`endif // SIM_UART
  );

endmodule
