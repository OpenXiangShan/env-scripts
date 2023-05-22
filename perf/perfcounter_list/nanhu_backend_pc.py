import sys
import os
abs_path=os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(abs_path))
from calculation_base import Calculator
# performance counter selected for gcpt-perf-collection.py

# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter

class CalculatorBackend(Calculator):
  parse_map = [
    ["ctrlBlock.rob: clock_cycle,  ", "clock_cycle"],
    ["frontend.ibuffer: utilization,  ", "ibuffer_util"],
    ["ctrlBlock.decode: utilization,   ", "decode_util"],
    ["ctrlBlock.dispatch: utilization,   ", "dp_util"],
    ["ctrlBlock.rob: utilization,   ", "rob_util"],
    ["ctrlBlock.rename: utilization,   ", "rename_util"],
    ["ctrlBlock.fpDq: utilization,   ", "fpDq_util"],
    ["ctrlBlock.intDq: utilization,   ", "intDq_util"],
    ["ctrlBlock.lsDq: utilization,   ", "lsDq_util"],
    ["ctrlBlock.dispatch: waitInstr,   ", "dp_stall"],
    ["ctrlBlock.dispatch: stall_cycle_rob,   ", "dp_stall_rob"],
    ["ctrlBlock.dispatch: stall_cycle_int_dq,   ", "dp_stall_intq"],
    ["ctrlBlock.dispatch: stall_cycle_fp_dq,   ", "dp_stall_fpq"],
    ["ctrlBlock.dispatch: stall_cycle_ls_dq,   ", "dp_stall_lsq"],
  ]

  def all_dp_stall(dic):
    return dic["dp_stall_rob"] + dic["dp_stall_intq"] + \
      dic["dp_stall_fpq"] + dic["dp_stall_lsq"]

  calculation_list = {
    # "ibuffer_util": lambda dic: (dic["ibuffer_util"]/dic["clock_cycle"]),
    # "decode_util": lambda dic: (dic["decode_util"]/dic["clock_cycle"]),
    # "rename_util": lambda dic: (dic["rename_util"]/dic["clock_cycle"]),
    # "dp_util": lambda dic: (dic["dp_util"]/dic["clock_cycle"]),
    # "fpDq_util": lambda dic: (dic["fpDq_util"]/dic["clock_cycle"]),
    # "intDq_util": lambda dic: (dic["intDq_util"]/dic["clock_cycle"]),
    # "lsDq_util": lambda dic: (dic["lsDq_util"]/dic["clock_cycle"]),
    # "rob_util": lambda dic: (dic["rob_util"]/dic["clock_cycle"]),
    "dp_stall_all": lambda dic: dic["dp_stall_rob"] + dic["dp_stall_intq"] + \
      dic["dp_stall_fpq"] + dic["dp_stall_lsq"],
    "dp_stall_rob_rate": lambda dic: (dic["dp_stall_rob"]/dic["dp_stall_all"]),
    "dp_stall_intq_rate": lambda dic: (dic["dp_stall_intq"]/dic["dp_stall_all"]),
    "dp_stall_fpq_rate": lambda dic: (dic["dp_stall_fpq"]/dic["dp_stall_all"]),
    "dp_stall_lsq_rate": lambda dic: (dic["dp_stall_lsq"]/dic["dp_stall_all"]),
  }