verilog_code = '''
reg [63:0] stuck_timer_{coreid};
reg [63:0] commit_count_{coreid};
reg [63:0] cycle_count_{coreid};

`define CORE{coreid} top.l_soc.core_with_l2{module_prefix}.core
`define ROB{coreid}  `CORE{coreid}.ctrlBlock.rob
`define CSR{coreid}  `CORE{coreid}.exuBlocks.fuBlock.exeUnits_6.csr

wire has_commit_{coreid} = !`ROB{coreid}.io_commits_isWalk && `ROB{coreid}.io_commits_valid_0;

always @(posedge clock) begin
  if (reset || has_commit_{coreid})
    stuck_timer_{coreid} <= 0;
  else
    stuck_timer_{coreid} <= stuck_timer_{coreid} + 1;

  if (reset)
    commit_count_{coreid} <= 0;
  else if (!`ROB{coreid}.io_commits_isWalk)
    commit_count_{coreid} <= commit_count_{coreid}
        + `ROB{coreid}.io_commits_valid_0 + `ROB{coreid}.io_commits_valid_1 + `ROB{coreid}.io_commits_valid_2
        + `ROB{coreid}.io_commits_valid_3 + `ROB{coreid}.io_commits_valid_4 + `ROB{coreid}.io_commits_valid_5;

  if (reset)
    cycle_count_{coreid} <= 0;
  else
    cycle_count_{coreid} <= cycle_count_{coreid} + 1;

  if (!reset && stuck_timer_{coreid} > 5000) begin
    $display("no instruction commits for 5000 cycles in core {coreid}");
    $finish;
  end

  if (!reset && !`ROB{coreid}.io_commits_isWalk && `ROB{coreid}.io_commits_valid_0) begin
    // $display("CORE {coreid}: instr commit %b", {{`ROB{coreid}.io_commits_valid_0, `ROB{coreid}.io_commits_valid_1,
    //   `ROB{coreid}.io_commits_valid_2,`ROB{coreid}.io_commits_valid_3,
    //   `ROB{coreid}.io_commits_valid_4,`ROB{coreid}.io_commits_valid_5}});
  end

  if (verbose && !reset && cycle_count_{coreid} % 1000 == 0) begin
    $display("[time=%d] coreid = {coreid}, instrCnt = %d", cycle_count_{coreid}, commit_count_{coreid});
    //$display("[time=%d] mcycle=%d, minstret=%d, bpRight=%d, bpWrong=%d", cycle_count, `CSR.mcycle, `CSR.minstret, `CSR.bpRight, `CSR.bpWrong);
  end
end
'''

for id in [0, 1]:
    module_prefix = f"_{id}" if id > 0 else ""
    print(verilog_code.format(coreid=id, module_prefix=module_prefix))
