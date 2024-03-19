import sys
import argparse
import sqlite3
import matplotlib.pyplot as plt
import numpy as np
import os

topDown_rename_map_def = {
  'OverrideBubble': 'MergeOtherFrontend',
  'FtqFullStall': 'MergeOtherFrontend',
  'FtqUpdateBubble': 'MergeBadSpecBubble',
  'TAGEMissBubble': 'MergeBadSpecBubble',
  'SCMissBubble': 'MergeBadSpecBubble',
  'ITTAGEMissBubble': 'MergeBadSpecBubble',
  'RASMissBubble': 'MergeBadSpecBubble',
  'ICacheMissBubble': 'ICacheBubble',
  'ITLBMissBubble': 'ITlbBubble',
  'BTBMissBubble': 'MergeBadSpecBubble',
  'FetchFragBubble': 'FragmentBubble',

  'DivStall': 'LongExecute',
  'IntNotReadyStall': 'MergeInstNotReady',
  'FPNotReadyStall': 'MergeInstNotReady',

  'MemNotReadyStall': 'MemNotReady',

  'IntFlStall': 'MergeFreelistStall',
  'FpFlStall': 'MergeFreelistStall',

  'IntDqStall': 'MergeDispatchQueueStall',
  'FpDqStall': 'MergeDispatchQueueStall',
  'LsDqStall': 'MergeDispatchQueueStall',

  'LoadTLBStall': 'DTlbStall',
  'LoadL1Stall': 'LoadL1Bound',
  'LoadL2Stall': 'LoadL2Bound',
  'LoadL3Stall': 'LoadL3Bound',
  'LoadMemStall': 'LoadMemBound',
  'StoreStall': 'MergeStoreBound',

  'AtomicStall': 'SerializeStall',

  'FlushedInsts': 'BadSpecInst',
  'LoadVioReplayStall': None,

  'LoadMSHRReplayStall': None,

  'ControlRecoveryStall': 'MergeBadSpecWalking',
  'MemVioRecoveryStall': 'MergeBadSpecWalking',
  'OtherRecoveryStall': 'MergeBadSpecWalking',

  'OtherCoreStall': 'MergeMisc',
  'NoStall': None,
  # 'NoStall': 'NoStall',

  'MemVioRedirectBubble': 'MergeBadSpecBubble',
  'OtherRedirectBubble': 'MergeMisc',

  # 'commitInstr': 'Insts',
  # 'total_cycles': 'Cycles',
}

topDown_rename_map_simple = {
  'OverrideBubble': 'MergeFrontend',
  'FtqFullStall': 'MergeFrontend',
  'FtqUpdateBubble': 'MergeBadSpecBubble',
  'TAGEMissBubble': 'MergeBadSpecBubble',
  'SCMissBubble': 'MergeBadSpecBubble',
  'ITTAGEMissBubble': 'MergeBadSpecBubble',
  'RASMissBubble': 'MergeBadSpecBubble',
  # 'ICacheMissBubble': 'ICacheBubble',
  # 'ITLBMissBubble': 'ITlbBubble',
  'ICacheMissBubble': 'MergeFrontend',
  'ITLBMissBubble': 'MergeFrontend',
  'BTBMissBubble': 'MergeBadSpecBubble',
  'FetchFragBubble': 'MergeFrontend',#'FragmentBubble',

  'DivStall': 'MergeInstNotReady',# 'LongExecute',
  'IntNotReadyStall': 'MergeInstNotReady',
  'FPNotReadyStall': 'MergeInstNotReady',

  'MemNotReadyStall': 'MemNotReady',

  'IntFlStall': 'MergeFreelistStall',
  'FpFlStall': 'MergeFreelistStall',

  'IntDqStall': 'MergeDispatchQueueStall',
  'FpDqStall': 'MergeDispatchQueueStall',
  'LsDqStall': 'MergeDispatchQueueStall',

  # 'LoadTLBStall': 'DTlbStall',
  # 'LoadL1Stall': 'LoadL1Bound',
  # 'LoadL2Stall': 'LoadL2Bound',
  # 'LoadL3Stall': 'LoadL3Bound',
  # 'LoadMemStall': 'LoadMemBound',
  'LoadTLBStall': 'MergeLoadBound',
  'LoadL1Stall': 'MergeLoadBound', #'LoadL1Bound',
  'LoadL2Stall': 'MergeLoadBound', #'LoadL2Bound',
  'LoadL3Stall': 'MergeLoadBound', #'LoadL3Bound',
  'LoadMemStall': 'MergeLoadBound', #'LoadMemBound',
  'StoreStall': 'MergeStoreBound',

  # 'AtomicStall': 'SerializeStall',
  'AtomicStall': 'MergeMisc',

  'FlushedInsts': 'BadSpecInst',
  'LoadVioReplayStall': 'MergeMisc',

  'LoadMSHRReplayStall': "MergeMisc",

  'ControlRecoveryStall': 'MergeBadSpecWalking',
  'MemVioRecoveryStall': 'MergeBadSpecWalking',
  'OtherRecoveryStall': 'MergeBadSpecWalking',

  'OtherCoreStall': 'MergeMisc',
  'NoStall': None,
  # 'NoStall': 'NoStall',

  'MemVioRedirectBubble': 'MergeBadSpecBubble',
  'OtherRedirectBubble': 'MergeMisc',

  # 'commitInstr': 'Insts',
  # 'total_cycles': 'Cycles',
}

topDown_rename_map_top = {
  'OverrideBubble': 'MergeFrontend',
  'FtqFullStall': 'MergeFrontend',
  'FtqUpdateBubble': 'MergeFrontend',
  'TAGEMissBubble': 'MergeFrontend',
  'SCMissBubble': 'MergeFrontend',
  'ITTAGEMissBubble': 'MergeFrontend',
  'RASMissBubble': 'MergeFrontend',
  # 'ICacheMissBubble': 'ICacheBubble',
  # 'ITLBMissBubble': 'ITlbBubble',
  'ICacheMissBubble': 'MergeFrontend',
  'ITLBMissBubble':  'MergeFrontend',
  'BTBMissBubble':   'MergeFrontend',
  'FetchFragBubble': 'MergeFrontend',#'FragmentBubble',

  'DivStall': 'MergeBackend',# 'LongExecute',
  'IntNotReadyStall': 'MergeBackend',
  'FPNotReadyStall': 'MergeBackend',

  'MemNotReadyStall': 'MergeMemory',

  'IntFlStall': 'MergeBackend',
  'FpFlStall': 'MergeBackend',

  'IntDqStall':'MergeBackend', # 'MergeDispatchQueueStall',
  'FpDqStall': 'MergeBackend', # 'MergeDispatchQueueStall',
  'LsDqStall': 'MergeBackend', # 'MergeDispatchQueueStall',

  # 'LoadTLBStall': 'DTlbStall',
  # 'LoadL1Stall': 'LoadL1Bound',
  # 'LoadL2Stall': 'LoadL2Bound',
  # 'LoadL3Stall': 'LoadL3Bound',
  # 'LoadMemStall': 'LoadMemBound',
  'LoadTLBStall': 'MergeMemory', #'MergeLoadBound',
  'LoadL1Stall':  'MergeMemory', #'MergeLoadBound', #'LoadL1Bound',
  'LoadL2Stall':  'MergeMemory', #'MergeLoadBound', #'LoadL2Bound',
  'LoadL3Stall':  'MergeMemory', #'MergeLoadBound', #'LoadL3Bound',
  'LoadMemStall': 'MergeMemory', #'MergeLoadBound', #'LoadMemBound',
  'StoreStall':   'MergeMemory', #'MergeStoreBound',

  # 'AtomicStall': 'SerializeStall',
  'AtomicStall': 'MergeMemory',

  'FlushedInsts': 'MergeFrontend',
  'LoadVioReplayStall': 'MergeMemory',

  'LoadMSHRReplayStall': "MergeMemory",

  'ControlRecoveryStall': 'MergeFrontend',
  'MemVioRecoveryStall': 'MergeMemory',
  'OtherRecoveryStall': 'MergeMisc',

  'OtherCoreStall': 'MergeMisc',
  'NoStall': None,
  # 'NoStall': 'NoStall',

  'MemVioRedirectBubble': 'MergeMemory',
  'OtherRedirectBubble': 'MergeMisc',

  # 'commitInstr': 'Insts',
  # 'total_cycles': 'Cycles',
}

topDown_rename_map_backend = {
  # 'OverrideBubble': 'MergeOtherFrontend',
  # 'FtqFullStall': 'MergeOtherFrontend',
  # 'FtqUpdateBubble': 'MergeBadSpecBubble',
  # 'TAGEMissBubble': 'MergeBadSpecBubble',
  # 'SCMissBubble': 'MergeBadSpecBubble',
  # 'ITTAGEMissBubble': 'MergeBadSpecBubble',
  # 'RASMissBubble': 'MergeBadSpecBubble',
  # 'ICacheMissBubble': 'ICacheBubble',
  # 'ITLBMissBubble': 'ITlbBubble',
  # 'BTBMissBubble': 'MergeBadSpecBubble',
  # 'FetchFragBubble': 'FragmentBubble',

  # 'DivStall': 'LongExecute',
  'IntNotReadyStall': 'IntInstNotReady',
  'FPNotReadyStall': 'FpInstNotReady',

  # 'MemNotReadyStall': 'MemNotReady',

  'IntFlStall': 'FreelistStall',
  'FpFlStall': 'FreelistStall',

  'IntDqStall': 'DispatchQueueStall',
  'FpDqStall': 'DispatchQueueStall',
  'LsDqStall': 'DispatchQueueStall',

  # 'LoadTLBStall': 'DTlbStall',
  # 'LoadL1Stall': 'LoadL1Bound',
  # 'LoadL2Stall': 'LoadL2Bound',
  # 'LoadL3Stall': 'LoadL3Bound',
  # 'LoadMemStall': 'LoadMemBound',
  # 'StoreStall': 'MergeStoreBound',

  # 'AtomicStall': 'SerializeStall',

  # 'FlushedInsts': 'BadSpecInst',
  # 'LoadVioReplayStall': None,

  # 'LoadMSHRReplayStall': None,

  # 'ControlRecoveryStall': 'MergeBadSpecWalking',
  # 'MemVioRecoveryStall': 'MergeBadSpecWalking',
  # 'OtherRecoveryStall': 'MergeBadSpecWalking',

  # 'OtherCoreStall': 'MergeMisc',
  # 'NoStall': None,
  # 'NoStall': 'NoStall',

  # 'MemVioRedirectBubble': 'MergeBadSpecBubble',
  # 'OtherRedirectBubble': 'MergeMisc',

  # 'commitInstr': 'Insts',
  # 'total_cycles': 'Cycles',
}

def read(csv_path):
  dic = {}
  with open(csv_path, "r") as f:
    lines = f.readlines()
    title = lines[0].strip().split(",")[1:]
    for line in lines[1:]:
      dic_spec = {}

      values = line.strip().split(",")
      spec_name = values[0]
      value_list = values[1:]
      for (t, v) in zip(title, value_list):
        dic_spec[t] = float(v)

      dic[spec_name] = dic_spec

  l = []
  for (spec, spec_data) in dic.items():
    l.append((spec, spec_data, spec_data["ipc"]))
  l.sort(key=lambda x: x[2], reverse=False)

  sorted_dic = {}
  for li in l:
    sorted_dic[li[0]] = li[1]

  return sorted_dic

def rename(dic, rename_map):
  # print(dic)
  new_dic = {}
  for (spec, spec_data) in dic.items():
    new_spec_data = {}
    for (origin_name, new_name) in rename_map.items():
      if new_name == None:
        continue

      if new_name not in new_spec_data.keys():
        new_spec_data[new_name] = spec_data[origin_name]
      else:
        new_spec_data[new_name] = new_spec_data[new_name] + spec_data[origin_name]
    new_dic[spec] = new_spec_data
  return new_dic

def draw_stacked_bar(result, name = None):
  xbar_label = result.keys()

  # print("result:")
  # print(result)
  ybar_stack_dict = {}
  for (spec, final_dic) in result.items():
    # print(f"spec: {spec}")
    # print(f"final_dic: {final_dic}")
    for (m, v) in final_dic.items():
      # print(f"m: {m} v: {v}")
      if m not in ybar_stack_dict.keys():
        ybar_stack_dict[m] = [v]
      else:
        ybar_stack_dict[m].append(v)
      # print(f"ybar_stack_dict[m]: {ybar_stack_dict[m]}")
  # print("ybar_stack_dict:")
  # print(ybar_stack_dict)

  # for (cpi, final_dic) in result.values():
  #   sum_of_stall = sum(final_dic.values())
  #   for (m, v) in final_dic.items():
  #     v = (v / sum_of_stall) * (cpi - (1/6))
  #     if m not in ybar_stack_dict.keys():
  #       ybar_stack_dict[m] = [v]
  #     else:
  #       ybar_stack_dict[m].append(v)

  width = 0.6
  bottom = np.zeros(len(xbar_label), dtype=float)

  plt.figure(figsize=(25, 10))

  for ybar_label,ybar_value in ybar_stack_dict.items():
    plt.bar(xbar_label, ybar_value, width, label=ybar_label, bottom=bottom)
    bottom += ybar_value

  # handler, labels = plt.gca().get_legend_handles_labels()
  # plt.legend(reversed(handler), reversed(labels), loc="best")
  # ax = plt.plot()#.barh()
  # ax.invert_yaxis()

  plt.title("")
  plt.legend(loc="best", fontsize=30)
  plt.tick_params(axis='x', labelrotation= 270, labelsize=12)


  if name == None:
    plt.show()
  else:
    plt.savefig(name)

if __name__ == '__main__':
  csv_path = sys.argv[1]
  if len(sys.argv) > 2:
    svg_path = sys.argv[2]
  else:
    svg_path = None
  dic = read(csv_path)
  new_dic = rename(dic, topDown_rename_map_backend)
  # new_dic = rename(dic, topDown_rename_map_top)
  draw_stacked_bar(new_dic, name = svg_path)