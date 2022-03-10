import "DPI-C" function void init_ram();
import "DPI-C" function void init_sd();
import "DPI-C" function void init_uart();
import "DPI-C" function void uart_putc(input byte c);
import "DPI-C" function byte uart_getc();

module tb_top();

reg clock;
reg reset;
wire uart_valid;
wire [7:0] uart_ch;

initial begin
  init_ram();
  init_sd();
  clock = 0;
  reset = 1;
  if ($test$plusargs("dump-wave")) begin
    $vcdplusfile("simv.vpd");
    $vcdpluson;
  end
  #100 reset = 0;
end

always #1 clock = ~clock;

SimTop top (
  .clock                (clock     ),
  .reset                (reset     ),
  .io_logCtrl_log_begin (64'h0     ),
  .io_logCtrl_log_end   (64'h0     ),
  .io_logCtrl_log_level (64'h0     ),
  .io_perfInfo_clean    (1'h0      ),
  .io_perfInfo_dump     (1'h0      ),
  .io_uart_out_valid    (uart_valid),
  .io_uart_out_ch       (uart_ch   ),
  .io_uart_in_valid     (          ),
  .io_uart_in_ch        (8'h0      )
);

always @(posedge clock) begin
  if (uart_valid) begin
    uart_putc(uart_ch);
  end
end

`include "testbench/check.h"
// `include "testbench/force.h"

endmodule
