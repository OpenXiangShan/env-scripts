`timescale 1ns/1ps

module nutshell_commit_trace_pack_tb;
  reg clk = 1'b0;
  reg resetn = 1'b0;
  reg commit_valid = 1'b0;
  reg [38:0] commit_pc = 39'h40_0000_0000;
  reg [31:0] commit_instr = 32'h0000_0013;
  reg commit_skip = 1'b0;
  reg commit_rfwen = 1'b0;
  reg [4:0] commit_rfdest = 5'd0;
  reg [63:0] commit_rfdata = 64'd0;
  reg redirect_valid = 1'b0;
  reg [38:0] redirect_target = 39'd0;
  reg [2:0] fu_type = 3'd0;
  reg [63:0] payload0 = 64'h10;
  reg [63:0] payload1 = 64'h11;
  reg [63:0] payload2 = 64'h12;
  reg [63:0] payload3 = 64'h13;
  wire [691:0] trace_data;
  wire trace_valid;

  always #5 clk = ~clk;

  nutshell_commit_trace_pack dut (
    .clk(clk), .resetn(resetn), .commit_valid(commit_valid),
    .commit_pc(commit_pc), .commit_instr(commit_instr),
    .commit_skip(commit_skip), .commit_rfwen(commit_rfwen),
    .commit_rfdest(commit_rfdest), .commit_rfdata(commit_rfdata),
    .redirect_valid(redirect_valid), .redirect_target(redirect_target),
    .fu_type(fu_type), .commit_payload_0(payload0),
    .commit_payload_1(payload1), .commit_payload_2(payload2),
    .commit_payload_3(payload3), .trace_data(trace_data),
    .trace_valid(trace_valid)
  );

  initial begin
    repeat (3) @(posedge clk);
    if (trace_valid !== 1'b0) $fatal(1, "trace valid during reset");
    @(negedge clk);
    resetn = 1'b1;
    repeat (4) begin
      @(negedge clk);
      if (trace_valid !== 1'b0)
        $fatal(1, "idle WBU state must not produce a trace record");
    end
    commit_valid = 1'b1;
    commit_instr = 32'h00c5_85b3;
    commit_rfwen = 1'b1;
    commit_rfdest = 5'd11;
    commit_rfdata = 64'h1234_5678_9abc_def0;
    redirect_valid = 1'b1;
    redirect_target = 39'h40_0000_0100;
    fu_type = 3'd5;
    @(negedge clk);
    if (!trace_valid || !trace_data[0]) $fatal(1, "missing commit snapshot");
    if (trace_data[64:1] !== {{25{commit_pc[38]}}, commit_pc}) $fatal(1, "PC schema mismatch");
    if (trace_data[96:65] !== commit_instr) $fatal(1, "instruction schema mismatch");
    if (trace_data[104:100] !== 5'd11 || trace_data[168:105] !== commit_rfdata)
      $fatal(1, "RF schema mismatch");
    if (trace_data[208:170] !== redirect_target || trace_data[211:209] !== 3'd5)
      $fatal(1, "redirect/FU schema mismatch");
    if (trace_data[275:212] !== payload0 || trace_data[467:404] !== payload3)
      $fatal(1, "payload schema mismatch");
    if (trace_data[627:596] !== 32'h4e55_5453 || trace_data[635:628] !== 8'd1)
      $fatal(1, "magic/version mismatch");
    if (trace_data[691:636] !== 56'd0) $fatal(1, "reserved bits are not zero");

    commit_valid = 1'b0;
    commit_instr = 32'h0000_0001;
    repeat (2) @(negedge clk);
    if (trace_valid !== 1'b0)
      $fatal(1, "trace valid remained asserted after commit");
    if (trace_data[0] !== 1'b0 || trace_data[98] !== 1'b1)
      $fatal(1, "idle/RVC schema mismatch");
    if (trace_data[531:468] !== 64'd7 || trace_data[595:532] !== 64'd1)
      $fatal(1, "sequence counter mismatch cycle=%0d commit=%0d",
             trace_data[531:468], trace_data[595:532]);
    $display("PASS nutshell_commit_trace_pack schema");
    $finish;
  end
endmodule
