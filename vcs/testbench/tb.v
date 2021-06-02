import "DPI-C" function void init_ram();
import "DPI-C" function void init_sd();
import "DPI-C" function void init_uart();

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
    $vcdplusfile("fix.vpd");
    $vcdpluson;
  end
  #100 reset = 0;
end

always #1 clock = ~clock;

sim_top sim (
  .clock(clock),
  .reset(reset)
);

reg [63:0] stuck_timer;
reg [63:0] commit_count;
reg [63:0] cycle_count;

`define CORE sim.CPU.core
`define ROQ  `CORE.ctrlBlock.roq
`define CSR  `CORE.integerBlock.jmpExeUnit.csr

wire has_commit = !`ROQ.io_commits_isWalk && `ROQ.io_commits_valid_0;

always @(posedge clock) begin
  if (reset || has_commit)
    stuck_timer <= 0;
  else
    stuck_timer <= stuck_timer + 1;

  if (reset)
    commit_count <= 0;
  else if (!`ROQ.io_commits_isWalk)
    commit_count <= commit_count + `ROQ.io_commits_valid_0 + `ROQ.io_commits_valid_1 + `ROQ.io_commits_valid_2 + `ROQ.io_commits_valid_3 + `ROQ.io_commits_valid_4 + `ROQ.io_commits_valid_5;

  if (reset)
    cycle_count <= 0;
  else
    cycle_count <= cycle_count + 1;

  if (!reset && stuck_timer > 2000) begin
    $display("no instruction commits for 2000 cycles");
    $finish;
  end
  if (!reset && !`ROQ.io_commits_isWalk && `ROQ.io_commits_valid_0) begin
    // $display("instr commit %b", {`ROQ.io_commits_valid_0,`ROQ.io_commits_valid_1,`ROQ.io_commits_valid_2,`ROQ.io_commits_valid_3,`ROQ.io_commits_valid_4,`ROQ.io_commits_valid_5});
  end
  if (!reset && cycle_count % 10000 == 0) begin
    $display("[time=%d] instrCnt = %d", cycle_count, commit_count);
    //$display("[time=%d] mcycle=%d, minstret=%d, bpRight=%d, bpWrong=%d", cycle_count, `CSR.mcycle, `CSR.minstret, `CSR.bpRight, `CSR.bpWrong);
  end

  if (!reset && sim.mmio.io_uart_in_valid) begin
    $display("[time=%d] uart query, instrCnt = %d", cycle_count, commit_count);
  end
end

`include "testbench/force.h"

endmodule

