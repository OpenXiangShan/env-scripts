import perf
import sys
import matplotlib.pyplot as plt
import numpy as np

class TopDown:
  """TopDown node"""
  def __init__(self, name, percentage):
    self.name = name
    if isinstance(percentage, TopDown):
      self.percentage = percentage.percentage
    else:
      self.percentage = percentage
    self.down = []
    self.top = None
    self.level = 0

  def __add__(self, rhs):
    if isinstance(rhs, TopDown):
      return self.percentage + rhs.percentage
    return self.percentage + rhs

  def __radd__(self, lhs):
    if isinstance(lhs, TopDown):
      return lhs.percentage + self.percentage
    return lhs + self.percentage

  def __sub__(self, rhs):
    if isinstance(rhs, TopDown):
      return self.percentage - rhs.percentage
    return self.percentage - rhs

  def __rsub__(self, lhs):
    if isinstance(lhs, TopDown):
      return lhs.percentage - self.percentage
    return lhs - self.percentage

  def __mul__(self, rhs):
    if isinstance(rhs, TopDown):
      return self.percentage * rhs.percentage
    return self.percentage * rhs

  def __rmul__(self, lhs):
    if isinstance(lhs, TopDown):
      return lhs.percentage * self.percentage
    return lhs * self.percentage

  def __truediv__(self, rhs):
    if isinstance(rhs, TopDown):
      return self.percentage / rhs.percentage
    return self.percentage / rhs

  def __rtruediv__(self, lhs):
    if isinstance(lhs, TopDown):
      return lhs.percentage / self.percentage
    return lhs / self.percentage

  def add_down(self, name, percentage):
    """Add a leaf node

    Args:
      name (str): Name of leaf node
      percentage (float): Percentage of leaf node

    Returns:
      TopDown: leaf
    """
    self.down.append(TopDown(name, percentage))
    self.down[-1].top = self
    self.down[-1].level = self.level + 1
    return self.down[-1]

  def get_nodes(self):
    """Get nodes with subnode(s)

    Returns:
        _type_: _description_
    """
    items = []
    if self.down:
      for value in self.down:
        items.extend(value.get_nodes())
      items.append(self)
    return items


def process_one(ctr):
  """Process one

  Args:
    ctr (dict): counters

  Returns:
    Nodes with subnode(s)
  """

  stall_cycles_core = ctr['stall_cycle_fp'] + ctr['stall_cycle_int'] + ctr['stall_cycle_rob_blame'] + ctr['stall_cycle_int_blame'] + ctr['stall_cycle_fp_blame'] + ctr['ls_dq_bound_cycles']

  top = TopDown("Top", 1.0)

# top
  frontend_bound = top.add_down("Frontend Bound", ctr['decode_bubbles'] / ctr['total_slots'])
  bad_speculation = top.add_down("Bad Speculation", (ctr['slots_issued'] - ctr['slots_retired'] + ctr['recovery_bubbles']) / ctr['total_slots'])
  retiring = top.add_down("Retiring", ctr['slots_retired'] / ctr['total_slots'])
  backend_bound = top.add_down("Backend Bound", top - frontend_bound - bad_speculation - retiring)

# top->frontend_bound
  fetch_latency = frontend_bound.add_down("Fetch Latency", ctr['fetch_bubbles'] / ctr['total_slots'])
  fetch_bandwidth = frontend_bound.add_down("Fetch Bandwidth", frontend_bound - fetch_latency)

# top->frontend_bound->fetch_latency
  itlb_miss = fetch_latency.add_down("iTLB Miss", ctr['itlb_miss_cycles'] / ctr['total_cycles'])
  icache_miss = fetch_latency.add_down("iCache Miss", ctr['icache_miss_cycles'] / ctr['total_cycles'])
  stage2_redirect_cycles = fetch_latency.add_down("Stage2 Redirect", ctr['stage2_redirect_cycles'] / ctr['total_cycles'])
  if2id_bandwidth = fetch_latency.add_down("IF2ID Bandwidth", ctr['ifu2id_hvButNotFull_slots'] / ctr['total_slots'])
  fetch_latency_others = fetch_latency.add_down("Fetch Latency Others", fetch_latency - itlb_miss - icache_miss - stage2_redirect_cycles - if2id_bandwidth)

# top->frontend_bound->fetch_latency->stage2_redirect_cycles
  branch_resteers = stage2_redirect_cycles.add_down("Branch Resteers", ctr['branch_resteers_cycles'] / ctr['total_cycles'])
  robFlush_bubble = stage2_redirect_cycles.add_down("RobFlush Bubble", ctr['robFlush_bubble_cycles'] / ctr['total_cycles'])
  ldReplay_bubble = stage2_redirect_cycles.add_down("LdReplay Bubble", ctr['ldReplay_bubble_cycles'] / ctr['total_cycles'])

# top->bad_speculation
  branch_mispredicts = bad_speculation.add_down("Branch Mispredicts", bad_speculation)

# top->backend_bound
  memory_bound = backend_bound.add_down("Memory Bound", backend_bound * (ctr['store_bound_cycles'] + ctr['load_bound_cycles']) / (
    stall_cycles_core + ctr['store_bound_cycles'] + ctr['load_bound_cycles']))
  core_bound = backend_bound.add_down("Core Bound", backend_bound - memory_bound)

# top->backend_bound->memory_bound
  stores_bound = memory_bound.add_down("Stores Bound", ctr['store_bound_cycles'] / ctr['total_cycles'])
  loads_bound = memory_bound.add_down("Loads Bound", ctr['load_bound_cycles'] / ctr['total_cycles'])

# top->backend_bound->core_bound
  integer_dq = core_bound.add_down("Integer DQ", core_bound * ctr['stall_cycle_int_blame'] / stall_cycles_core)
  floatpoint_dq = core_bound.add_down("Floatpoint DQ", core_bound * ctr['stall_cycle_fp_blame'] / stall_cycles_core)
  rob = core_bound.add_down("ROB", core_bound * ctr['stall_cycle_rob_blame'] / stall_cycles_core)
  integer_prf = core_bound.add_down("Integer PRF", core_bound * ctr['stall_cycle_int'] / stall_cycles_core)
  floatpoint_prf = core_bound.add_down("Floatpoint PRF", core_bound * ctr['stall_cycle_fp'] / stall_cycles_core)
  lsu_ports = core_bound.add_down("LSU Ports", core_bound * ctr['ls_dq_bound_cycles'] / stall_cycles_core)

# top->backend_bound->memory_bound->loads_bound
  l1d_loads_bound = loads_bound.add_down("L1D Loads", ctr['l1d_loads_bound_cycles'] / ctr['total_cycles'])
  l2_loads_bound = loads_bound.add_down("L2 Loads", ctr['l2_loads_bound_cycles'] / ctr['total_cycles'])
  l3_loads_bound = loads_bound.add_down("L3 Loads", ctr['l3_loads_bound_cycles'] / ctr['total_cycles'])
  ddr_loads_bound = loads_bound.add_down("DDR Loads", ctr['ddr_loads_bound_cycles'] / ctr['total_cycles'])

# # top->backend_bound->memory_bound->loads_bound->l1d_loads_bound
#   l1d_loads_mshr_bound = l1d_loads_bound.add_down("L1D Loads MSHR", ctr['l1d_loads_mshr_bound'] / ctr['total_cycles'])
#   l1d_loads_tlb_bound = l1d_loads_bound.add_down("L1D Loads TLB", ctr['l1d_loads_tlb_bound'] / ctr['total_cycles'])
#   l1d_loads_store_data_bound = l1d_loads_bound.add_down("L1D Loads sdata", ctr['l1d_loads_store_data_bound'] / ctr['total_cycles'])
#   l1d_loads_bank_conflict_bound = l1d_loads_bound.add_down("L1D Loads\nBank Conflict", ctr['l1d_loads_bank_conflict_bound'] / ctr['total_cycles'])
#   l1d_loads_vio_check_redo_bound = l1d_loads_bound.add_down("L1D Loads VioRedo", ctr['l1d_loads_vio_check_redo_bound'] / ctr['total_cycles'])

  return list(reversed(top.get_nodes()))


def top_down_get_ctr(perf_path):
  counters = perf.PerfCounters(perf_path)
  # when the spec has not finished, clock_cycle may be None
  if counters[f"core_with_l2.core.ctrlBlock.rob.clock_cycle"] is None:
    print("clock_cycle not found in", gcpt.benchspec, gcpt.point, gcpt.weight)

  ctr = dict()
  ctr['total_cycles'                  ] = float(counters[f"core_with_l2.core.ctrlBlock.rob.clock_cycle"]                                       )
  ctr['fetch_bubbles'                 ] = float(counters[f"core_with_l2.core.ctrlBlock.decode.fetch_bubbles"]                                  )
  ctr['decode_bubbles'                ] = float(counters[f"core_with_l2.core.ctrlBlock.decode.decode_bubbles"]                                 )
  ctr['slots_issued'                  ] = float(counters[f"core_with_l2.core.ctrlBlock.decode.slots_issued"]                                   )
  ctr['recovery_bubbles'              ] = float(counters[f"core_with_l2.core.ctrlBlock.rename.recovery_bubbles"]                               )
  ctr['slots_retired'                 ] = float(counters[f"core_with_l2.core.ctrlBlock.rob.commitUop"]                                         )
  ctr['br_mispred_retired'            ] = float(counters[f"core_with_l2.core.frontend.ftq.mispredictRedirect"]                                 )
  ctr['icache_miss_cycles'            ] = float(counters[f"core_with_l2.core.frontend.icache.mainPipe.icache_bubble_s2_miss"]                  )
  ctr['itlb_miss_cycles'              ] = float(counters[f"core_with_l2.core.frontend.icache.mainPipe.icache_bubble_s0_tlb_miss"]              )
  ctr['s2_redirect_cycles'            ] = float(counters[f"core_with_l2.core.frontend.bpu.s2_redirect"]                                        )
  ctr['s3_redirect_cycles'            ] = float(counters[f"core_with_l2.core.frontend.bpu.s3_redirect"]                                        )
  ctr['store_bound_cycles'            ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.stall_stores_bound"]                          )
  ctr['load_bound_cycles'             ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.stall_loads_bound"]                           )
  ctr['ls_dq_bound_cycles'            ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.stall_ls_bandwidth_bound"]                    )
  ctr['stall_cycle_rob_blame'         ] = float(counters[f"core_with_l2.core.ctrlBlock.dispatch.stall_cycle_rob_blame"]                        )
  ctr['stall_cycle_int_blame'         ] = float(counters[f"core_with_l2.core.ctrlBlock.dispatch.stall_cycle_int_blame"]                        )
  ctr['stall_cycle_fp_blame'          ] = float(counters[f"core_with_l2.core.ctrlBlock.dispatch.stall_cycle_fp_blame"]                         )
  ctr['stall_cycle_ls_blame'          ] = float(counters[f"core_with_l2.core.ctrlBlock.dispatch.stall_cycle_ls_blame"]                         )
  ctr['stall_cycle_fp'                ] = float(counters[f"core_with_l2.core.ctrlBlock.rename.stall_cycle_fp"]                                 )
  ctr['stall_cycle_int'               ] = float(counters[f"core_with_l2.core.ctrlBlock.rename.stall_cycle_int"]                                )
  ctr['l1d_loads_bound_cycles'        ] = float(counters[f"core_with_l2.core.memBlock.lsq.loadQueue.l1d_loads_bound"]                          )
  ctr['l1d_loads_mshr_bound'          ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.rs_3.loadRS_0.l1d_loads_mshr_bound"]          )
  ctr['l1d_loads_tlb_bound'           ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.rs_3.loadRS_0.l1d_loads_tlb_bound"]           )
  ctr['l1d_loads_store_data_bound'    ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.rs_3.loadRS_0.l1d_loads_store_data_bound"]    )
  ctr['l1d_loads_bank_conflict_bound' ] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.rs_3.loadRS_0.l1d_loads_bank_conflict_bound"] )
  ctr['l1d_loads_vio_check_redo_bound'] = float(counters[f"core_with_l2.core.exuBlocks.scheduler.rs_3.loadRS_0.l1d_loads_vio_check_redo_bound"])
  ctr['l2_loads_bound_cycles'         ] = float(counters[f"core_with_l2.l2cache.l2_loads_bound"]                                               )
  ctr['l3_loads_bound_cycles'         ] = float(counters[f"l3cacheOpt.l3_loads_bound"]                                                         )
  ctr['ddr_loads_bound_cycles'        ] = float(counters[f"l3cacheOpt.ddr_loads_bound"]                                                        )
  ctr['stage2_redirect_cycles'        ] = float(counters[f"core_with_l2.core.ctrlBlock.stage2_redirect_cycles"]                                )
  ctr['branch_resteers_cycles'        ] = float(counters[f"core_with_l2.core.ctrlBlock.branch_resteers_cycles"]                                )
  ctr['robFlush_bubble_cycles'        ] = float(counters[f"core_with_l2.core.ctrlBlock.robFlush_bubble_cycles"]                                )
  ctr['ldReplay_bubble_cycles'        ] = float(counters[f"core_with_l2.core.ctrlBlock.ldReplay_bubble_cycles"]                                )
  ctr['ifu2id_allNO_cycle'            ] = float(counters[f"core_with_l2.core.ctrlBlock.decode.ifu2id_allNO_cycle"]                             )
  ctr['total_slots'                   ] = ctr['total_cycles'] * 6
  ctr['ifu2id_allNO_slots'            ] = ctr['ifu2id_allNO_cycle'] * 6
  ctr['ifu2id_hvButNotFull_slots'     ] = ctr['fetch_bubbles'] - ctr['ifu2id_allNO_slots']
  return ctr
  


def xs_report_top_down_tf(perf_base_path, all_gcpt, gcpt_top_down):
  for gcpt in all_gcpt:
    perf_path = gcpt.err_path(perf_base_path)
    ctr = top_down_get_ctr(perf_path)
    
    for k,v in ctr.items():
      if k in gcpt_top_down[gcpt.benchspec.split("_")[0]].keys():
        gcpt_top_down[gcpt.benchspec.split("_")[0]][k] += v * float(gcpt.weight)
      else:
        gcpt_top_down[gcpt.benchspec.split("_")[0]][k] = v * float(gcpt.weight)

  graph_num = 0
  for k,v in gcpt_top_down.items():
    gcpt_top_down[k] = process_one(gcpt_top_down[k])
    graph_num = len(gcpt_top_down[k])
  return graph_num

if __name__ == "__main__":
  perf_path = sys.argv[1]
  prog_name = sys.argv[2]
  ctr = top_down_get_ctr(perf_path)
  topdown = process_one(ctr)
  graph_num = len(topdown)
  plt.figure(figsize=(25,45))
  for i in range(graph_num):
    plt.subplot((graph_num + 1) // 2, 2, i + 1)
    boundname = []
    lst = []
    topname = topdown[i].name
    for value in topdown[i].down:
      boundname.append(value.name)
      lst.append(value.percentage)

    bottom = [0.0]
    for zipped in zip(boundname, lst):
      plt.bar([prog_name], zipped[1], bottom=bottom, label=zipped[0])
      bottom = list(map(lambda x: x + zipped[1], bottom))
    plt.legend()
    plt.title(topname)
  plt.savefig(f'{prog_name}_topdown.svg', bbox_inches='tight')
  
  
  