# performance counter selected for gcpt-perf-collection.py

# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter

perf_conter = [
  ["ctrlBlock.fusionDecoder: fused_instr, ", "fused_instr"],
  ["ctrlBlock.rename: fused_lui_load_instr_count, ", "fused_lui_load"],
  ["ctrlBlock.rename: in,   ", "rename_in"],
  ["ctrlBlock.rename: move_instr_count,  ", "move_elimination"],
  ["ctrlBlock.rob: fmac_instr_cnt_fma,  ", "fmac_instr_cnt"],
  ["ctrlBlock.rob: fmac_latency_execute_fma,   ", "fmac_latency_execute"],
  ["ctrlBlock.rob: commitInstrMoveElim,   ", "moveElim"],
  ["ctrlBlock.rob: commitInstrFused,  ", "commitFused"]
]
extra_counter_name = ",fused+luiload,fused,luiload,move,fmalatency,commitFuesd"

def get_perf_counter():
  return perf_conter

def get_perf_counter_name():
  return extra_counter_name

def iprint(str):
  print(","+str, end="")

def print_extra_counter(spec):
  iprint("%.4f"%((spec.record["fused_instr"]+spec.record["fused_lui_load"])/spec.record["rename_in"]))
  iprint("%.4f"%(spec.record["fused_instr"] / spec.record["rename_in"]))
  iprint("%.4f"%(spec.record["fused_lui_load"]/spec.record["rename_in"]))
  iprint("%.4f"%(spec.record["moveElim"] / spec.record["instrCnt"]))
  if (spec.record["fmac_instr_cnt"] == 0):
    iprint("0")
  else:
    iprint("%.4f"%(spec.record["fmac_latency_execute"]/spec.record["fmac_instr_cnt"]))
  iprint("%.4f"%(spec.record["commitFused"]/spec.record["instrCnt"]))