import sys
import os
abs_path=os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(abs_path))
from calculation_base import Calculator

# performance counter selected for gcpt-perf-collection.py

# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter

class CalculatorExample(Calculator):
  parse_map = [
    ["ctrlBlock.rob: commitInstr, ", "instrCnt"],
    ["ctrlBlock.rob: clock_cycle, ", "clockCycle"],
    ["ctrlBlock.fusionDecoder: fused_instr, ", "fused_instr"],
    ["ctrlBlock.rename: fused_lui_load_instr_count, ", "fused_lui_load"],
    ["ctrlBlock.rename: in,   ", "rename_in"],
    ["ctrlBlock.rename: move_instr_count,  ", "move_elimination"],
    ["ctrlBlock.rob: fmac_instr_cnt_fma,  ", "fmac_instr_cnt"],
    ["ctrlBlock.rob: fmac_latency_execute_fma,   ", "fmac_latency_execute"],
    ["ctrlBlock.rob: commitInstrMoveElim,   ", "moveElim"],
    ["ctrlBlock.rob: commitInstrFused,  ", "commitFused"]
  ]

  """
  A example for re:
    1. the re str, should have fullMatch to generate the "From" str
    2. when use re, the second element should be a func, which can generate the "To" str, func's param is the re result
    3. the third element is optional, if it is True, the "To" str will be shown in the final result

  parse_map = [
    ["backend.dataPath: IntRegFileWrite_hist_sampled, ", "IRFW_sampled", True],
    [r'^.+(?P<fullMatch>backend.dataPath: IntRegFileRead_hist_(?P<indexNum>\d+)_\d+, )\s+\d+$',
     lambda x:f'W_{x.group("indexNum")}', True],
  ]
  """

  calculation_list = {
    "ipc": lambda dic: dic["instrCnt"] / dic["clockCycle"],
    # "fused+luiload": lambda dic: (dic["fused_instr"]+dic["fused_lui_load"])/dic["rename_in"],
    # "fused": lambda dic: dic["fused_instr"] / dic["rename_in"],
    # "luiload": lambda dic: dic["fused_lui_load"]/dic["rename_in"],
    # "move": lambda dic: dic["moveElim"] / dic["instrCnt"],
    # "fmalatency": lambda dic: 0 if (dic["fmac_instr_cnt"] == 0) else dic["fmac_latency_execute"]/dic["fmac_instr_cnt"],
    # "commitFused": lambda dic:dic["commitFused"]/dic["instrCnt"]
  }