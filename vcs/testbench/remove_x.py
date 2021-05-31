import sys

need_initial = [
  # not initialized registers (from rocket-chip and chisel lib)
  # (1) RRArbiter.lastGrant; (2) PLRU replacement init state
  ("`CORE.memBlock.dcache.missReqArb.lastGrant", 2),
  ("`CORE.memBlock.dcache.missQueue.pipe_req_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.storeReplayUnit.pipe_req_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.storeReplayUnit.resp_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.probeQueue.pipe_req_arb.lastGrant", 4),
  ("`CORE.memBlock.dcache.mainPipeReqArb.lastGrant", 2),
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
  ("`CORE.frontend.ifu.io_redirect_bits_cfiUpdate_pc", 39),#X cause LOOP to be X
  ("`CORE.frontend.ifu.io_redirect_bits_cfiUpdate_target", 39),#X cause LOOP to be X
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
  #("`CORE.ctrlBlock.ftq.ftq_1r_sram.SRAMTemplate.array.array_21_ext.R0_data", 944),
  ("`CORE.ctrlBlock.rename.FreeList_1.io_req_canAlloc", 1),
  ("tb_top.sim.CPU.axi4deint.REG_1", 5),
]

need_force_1 = [
   ("`CORE.ctrlBlock.ftq.ftq_1r_sram.SRAMTemplate.array.array_21_ext.R0_data", 944),
   ("`CORE.frontend.ifu.icache.icacheMissQueue.io_resp_bits_data", 512),
]

# QN
all_modules = [
  ("`CORE.l1pluscache.pipe.", "/home/xyn/debug/gate/vcs_newgate/20210530-gate/XSCore/L1plusCachePipe.v", "REG_1_"),
  ("`CORE.frontend.ifu.icache.", "/home/xyn/debug/gate/vcs_newgate/20210530-gate/XSCore/ICache.v", "REG_1_"),
  ("`CORE.memBlock.dcache.mainPipe.", "/home/xyn/debug/gate/vcs_newgate/20210530-gate/XSCore/DCache_MainPipe_0.v", "REG_4_"),
  ("`CORE.ptw.", "/home/xyn/debug/gate/vcs_newgate/20210530-gate/XSCore/PTW.v", "REG_19_"),
  ("`CORE.ptw.", "/home/xyn/debug/gate/vcs_newgate/20210530-gate/XSCore/PTW.v", "REG_38_"),
]

def find_qn(level, filename, prefix):
  all_qn = []
  last_line = ""
  with open(filename) as f:
    for line in f:
      if ".QN(" in line:
        cell_name = last_line.split()[1]
        if cell_name.startswith(prefix):
          all_qn.append(level + cell_name)
        # if not cell_name.startswith("REG_"):
        #   all_remove = [" l3v", " l2v", " l3_", " l3g", " l1v", " l2_", "ppn_", " l1_", " l1g_", " sp_"]
        #   found = False
        #   for x in all_remove:
        #     if x in last_line or x in line:
        #       found = True
        #       continue
        #   if not found:
        #     print(last_line.strip() + line)
      else:
        last_line = line
  return all_qn

def rtl_generate():
  for source, width in need_initial:
    assert(width < 64)
    source_name = f"{source}"
    print("initial begin")
    print(f"  force {source_name} = $random();")
    print(f"  #10 release {source_name};")
    print("end")

  print("always @(clock) begin")
  for source, width in need_force + need_force_1:
    for i in range(width):
      source_name = f"{source}"
      if width > 1:
        source_name += f"[{i}]"
      print(f"if ({source_name} === 1'bx) begin")
      print(f"  force {source_name} = $random();")
      print(f"end")
      print(f"else begin release {source_name}; end")
  print("end")


def netlist_generate():
  print("always @(clock) begin")
  for source, width in need_force_1:
    for i in range(width):
      source_name = f"{source}_{i}_"
      if "io_resp_bits_data" in source and i in [328, 135, 79]:
        source_name += "_BAR"
      print(f"if ({source_name} === 1'bx) begin")
      print(f"  force {source_name} = $random();")
      print(f"end")
      print(f"else begin release {source_name}; end")

  for source, width in need_initial:
    for i in range(width):
      source_name = f"{source}_reg_{i}_.Q"
      print(f"if ({source_name} === 1'bx) begin")
      print(f"  force {source_name} = $random();")
      print(f"end")
      print(f"else begin release {source_name}; end")

  need_qn = []
  for level, module, prefix in all_modules:
    need_qn += find_qn(level, module, prefix)

  for source in need_qn:
      source_name = f"{source}.QN"
      print(f"if ({source_name} === 1'bx) begin")
      print(f"  force {source_name} = $random();")
      print(f"end")
      print(f"else begin release {source_name}; end")
 
  for source, width in need_force:
    for i in range(width):
      source_name = f"{source}"
      if width > 1:
        source_name += f"[{i}]"
      print(f"if ({source_name} === 1'bx) begin")
      print(f"  force {source_name} = $random();")
      print(f"end")
      print(f"else begin release {source_name}; end")
  print("end")

if __name__ == "__main__":
  func_map = {
    "rtl": rtl_generate,
    "netlist": netlist_generate
  }
  func_map[sys.argv[1]]()

