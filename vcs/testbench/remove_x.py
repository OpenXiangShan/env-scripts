need_initial = [
  # not initialized registers (from rocket-chip and chisel lib)
  # (1) RRArbiter.lastGrant; (2) PLRU replacement init state
  ("`CORE.memBlock.dcache.missReqArb.lastGrant", 2),
  ("`CORE.memBlock.dcache.missQueue.pipe_req_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.storeReplayUnit.pipe_req_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.storeReplayUnit.resp_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.probeQueue.pipe_req_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.mainPipeReqArb.lastGrant", 2),
  ("`CORE.memBlock.dcache.missReqArb.lastGrant", 2),
]
for i in range(256):
  need_initial.append((f"`CORE.l1pluscache.pipe.REG_1_{i}", 7))
for i in range(64):
  need_initial.append((f"`CORE.frontend.ifu.icache.REG_1_{i}", 3))
for i in range(64):
  need_initial.append((f"`CORE.memBlock.dcache.mainPipe.REG_4_{i}", 7))
for i in range(64):
  need_initial.append((f"`CORE.ptw.REG_19_{i}", 7))
  need_initial.append((f"`CORE.ptw.REG_38_{i}", 15))


need_force = [
  # unknown reason (fetch x?)
  ("`CORE.frontend.instrUncache.io_resp_bits_data", 256),
  ("`CORE.frontend.instrUncache.entries_0.io_resp_bits_data", 256),
  ("`CORE.frontend.ifu.icache.pds_0.io_in_data", 256),
  ("`CORE.frontend.ifu.icache.pds_1.io_in_data", 256),
  ("`CORE.frontend.ifu.icache.pds_2.io_in_data", 256),
  ("`CORE.frontend.ifu.icache.pds_3.io_in_data", 256),
  ("`CORE.frontend.ifu.icache.pds_0.io_in_mask", 16),
  ("`CORE.frontend.ifu.icache.pds_1.io_in_mask", 16),
  ("`CORE.frontend.ifu.icache.pds_2.io_in_mask", 16),
  ("`CORE.frontend.ifu.icache.pds_3.io_in_mask", 16),
  # dual-port SRAMs read and write the same index at the same clock cycle
  ("`CORE.frontend.ifu.bpu.bim.bim.array.array_2_ext.R0_data", 32),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_5.lo_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_5.hi_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_5.table_.array.array_7_ext.R0_data", 208),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_4.lo_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_4.hi_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_4.table_.array.array_7_ext.R0_data", 208),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_3.lo_us.array.array_5_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_3.hi_us.array.array_5_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_3.table_.array.array_6_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_2.hi_us.array.array_5_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_2.lo_us.array.array_5_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_2.table_.array.array_6_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_1.hi_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_1.lo_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_1.table_.array.array_4_ext.R0_data", 176),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_0.lo_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_0.hi_us.array.array_3_ext.R0_data", 16),
  ("`CORE.frontend.ifu.bpu.preds_3.tables_0.table_.array.array_4_ext.R0_data", 176),
  ("`CORE.frontend.ifu.bpu.preds_3.scTables_5.table_.array.array_8_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.scTables_4.table_.array.array_8_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.scTables_3.table_.array.array_8_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.scTables_2.table_.array.array_8_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.scTables_1.table_.array.array_8_ext.R0_data", 192),
  ("`CORE.frontend.ifu.bpu.preds_3.scTables_0.table_.array.array_8_ext.R0_data", 192),
  ("`CORE.ctrlBlock.ftq.ftq_2r_sram.SRAMTemplate_1.array.array_19_ext.R0_data", 275),
  ("`CORE.ctrlBlock.ftq.ftq_2r_sram.SRAMTemplate.array.array_19_ext.R0_data", 275),
  ("`CORE.ctrlBlock.ftq.pred_target_sram.SRAMTemplate.array.array_20_ext.R0_data", 39),
  ("`CORE.ctrlBlock.ftq.ftq_1r_sram.SRAMTemplate.array.array_21_ext.R0_data", 944),
]

def generate():
  for source, width in need_initial:
    print("initial begin")
    print(f"force {source} = $random();")
    print(f"#10 release {source};")
    print("end")

  for source, width in need_force:
    print("always @(clock) begin")
    for i in range(width):
      print(f"if ({source}[{i}] === 1'bx) begin")
      print(f"  force {source}[{i}] = $random();")
      print(f"end")
      print(f"else begin release {source}[{i}]; end")
    print("end")

if __name__ == "__main__":
  generate()
