import sys
import argparse
import sqlite3
import matplotlib.pyplot as plt
import numpy as np
import os

# Input: db, interval instr start, interval instr end
# Output: cpi in the interval; top-down data in the interval

# TopDown
# Change This Map for TopDown Figure show
topDown_rename_map = {
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

  'MemVioRedirectBubble': 'MergeBadSpecBubble',
  'OtherRedirectBubble': 'MergeMisc',

  # 'commitInstr': 'Insts',
  # 'total_cycles': 'Cycles',
}

def td_tablename(origin_name):
  return "td_" + origin_name + "_rolling_0"

def read_db(db_path, start_instr, end_instr):
  final_dic = {}

  if not os.path.exists(db_path):
    print(f"data base file {db_path} does not exist")
    sys.exit(0)

  conn = sqlite3.connect(db_path)
  db_cur = conn.cursor()
  db_table_list = db_cur.execute(f"SELECT name FROM sqlite_master")
  db_table_list = list(map(lambda x: x[0], db_table_list))

  for origin_name in topDown_rename_map.keys():
    table_name = td_tablename(origin_name)
    if table_name not in db_table_list:
      print(f"table {table_name} not in {db_path}")
      sys.exit(0)

  # find cpi data in the database from start to end
  INSTR_KEY = "XAXISPT"
  DATA_KEY = "YAXISPT"
  cpi_TABLE_NAME = "cpi_rolling_0"
  db_data = db_cur.execute(f"SELECT {INSTR_KEY} FROM {cpi_TABLE_NAME}")
  instr_data = (list(map(lambda x: x[0], db_data.fetchall())))
  db_data = db_cur.execute(f"SELECT {DATA_KEY} FROM {cpi_TABLE_NAME}")
  cycle_data = (list(map(lambda x: x[0], db_data.fetchall())))

  def same_index(instr, instr_wanted):
    return (instr >= (instr_wanted - 20)) and (instr < (instr_wanted + 20))

  start_index = 0
  end_index = 0
  inside_interval = False
  sum_of_cycle = 0
  for ((i, instr), cycle) in zip(enumerate(instr_data), cycle_data):
    if same_index(instr, start_instr):
      start_index = i
      inside_interval = True

    if inside_interval:
      sum_of_cycle += cycle

    if same_index(instr, end_instr):
      end_index = i
      inside_interval = False
      break

  for (origin_name, renamed_name) in topDown_rename_map.items():
    if renamed_name is None:
      continue

    table_name = td_tablename(origin_name)
    db_data = db_cur.execute(f"SELECT {DATA_KEY} FROM {table_name}")
    db_data = list(map(lambda x: x[0], db_data.fetchall()))
    if renamed_name in final_dic.keys():
      final_dic[renamed_name] = final_dic[renamed_name] + sum(db_data[start_index:end_index+1])
    else:
      final_dic[renamed_name] = sum(db_data[start_index:end_index+1])

  # return cpi, top_down_dic
  return (sum_of_cycle / (end_index - start_index + 1), final_dic)

def draw_stacked_bar(result):
  name_list = result.keys()

  xbar_label = result.keys()

  ybar_stack_dict = {}
  for (cpi, final_dic) in result.values():
    sum_of_stall = sum(final_dic.values())
    for (m, v) in final_dic.items():
      v = (v / sum_of_stall) * (cpi - (1/6))
      if m not in ybar_stack_dict.keys():
        ybar_stack_dict[m] = [v]
      else:
        ybar_stack_dict[m].append(v)

  width = 0.4
  bottom = np.zeros(len(xbar_label), dtype=float)

  for ybar_label,ybar_value in ybar_stack_dict.items():
    plt.bar(xbar_label, ybar_value, width, label=ybar_label, bottom=bottom)
    bottom += ybar_value

  plt.title("")
  plt.legend(loc="best")
  plt.tick_params(axis='x', labelrotation= 270, labelsize=8)
  plt.show()


# Main Start From Here

start_instr = int(sys.argv[1])
end_instr   = int(sys.argv[2])
db_path_list= sys.argv[3:]
# print("db_path_list")
# print(db_path_list)
result = {}

for (index, db_path) in enumerate(db_path_list):
  result[str(index)] = read_db(db_path, start_instr, end_instr)

# print(result)
draw_stacked_bar(result)
