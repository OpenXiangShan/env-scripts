import "DPI-C" function void init_ram();

module tb_top();

reg clock;
reg reset;
wire uart_valid;
wire [7:0] uart_ch;

initial begin
  init_ram();
  clock = 0;
  reset = 1;
  // $vcdpluson;
  #100 reset = 0;
  // #100000000 $finish;
end

always #1 clock = ~clock;

sim_top sim (
  .clock(clock),
  .reset(reset),
  .uart_valid(uart_valid),
  .uart_ch(uart_ch)
);

always @(posedge clock) begin
  if (uart_valid) begin
    $write("%c", uart_ch);
  end
end

reg [31:0] commit_count;
wire has_commit = !sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_isWalk && sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_0;

always @(posedge clock) begin
  if (reset || has_commit)
    commit_count <= 0;
  else
    commit_count <= commit_count + 1;

  if (commit_count > 5000) begin
    $display("no instruction commits for 5000 cycles");
    $fatal;
  end
  if (!sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_isWalk && sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_0) begin
    // $display("instr commit %b", {sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_0,sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_1,sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_2,sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_3,sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_4,sim.CPU.core_with_l2.core.ctrlBlock.roq.io_commits_valid_5});
  end
end

endmodule

