# performance counter selected for gcpt-perf-collection.py

# selected perf counter
# 0: key words of perf counter
# 1: name of perf counter

memblock_loadpipe_perfcounter_nanhu = [
  ["LoadUnit_0.load_s0: in_valid, ", "ld0_s0_in_valid"],
  ["LoadUnit_0.load_s0: in_fire, ", "ld0_s0_in_fire"],
  ["LoadUnit_0.load_s0: in_fire_first_issue, ", "ld0_s0_in_fire_first_issue"],
  ["LoadUnit_0.load_s0: addr_spec_success, ", "ld0_s0_addr_spec_success"],
  ["LoadUnit_0.load_s0: addr_spec_failed, ", "ld0_s0_addr_spec_failed"],
  ["LoadUnit_0.load_s0: addr_spec_success_once, ", "ld0_s0_addr_spec_success_once"],
  ["LoadUnit_0.load_s0: addr_spec_failed_once, ", "ld0_s0_addr_spec_failed_once"],
  ["LoadUnit_0.load_s1: in_fire, ", "ld0_s1_in_fire"],
  ["LoadUnit_0.load_s1: tlb_miss, ", "ld0_s1_tlb_miss"],
  ["LoadUnit_0.load_s1: in_fire_first_issue, ", "ld0_s1_in_fire_first_issue"],
  ["LoadUnit_0.load_s1: tlb_miss_first_issue, ", "ld0_s1_tlb_miss_first_issue"],
  ["LoadUnit_0.load_s2: in_fire, ", "ld0_s2_in_fire"],
  ["LoadUnit_0.load_s2: in_fire_first_issue, ", "ld0_s2_in_fire_first_issue"],
  ["LoadUnit_0.load_s2: dcache_miss, ", "ld0_s2_dcache_miss"],
  ["LoadUnit_0.load_s2: dcache_miss_first_issue, ", "ld0_s2_dcache_miss_first_issue"],
  ["LoadUnit_0.load_s2: full_forward, ", "ld0_s2_full_forward"],
  ["LoadUnit_0.load_s2: dcache_miss_full_forward, ", "ld0_s2_dcache_miss_full_forward"],
  ["LoadUnit_0.load_s2: replay, ", "ld0_s2_replay"],
  ["LoadUnit_0.load_s2: replay_tlb_miss, ", "ld0_s2_replay_tlb_miss"],
  ["LoadUnit_0.load_s2: replay_cache, ", "ld0_s2_replay_cache"],
  ["LoadUnit_0.load_s2: replay_from_fetch_forward, ", "ld0_s2_replay_from_fetch_forward"],
  ["LoadUnit_0.load_s2: replay_from_fetch_load_vio, ", "ld0_s2_replay_from_fetch_load_vio"],
  ["LoadUnit_0: load_to_load_forward, ", "ld0_load_to_load_forward"],

  ["LoadUnit_1.load_s0: in_valid, ", "ld1_s0_in_valid"],
  ["LoadUnit_1.load_s0: in_fire, ", "ld1_s0_in_fire"],
  ["LoadUnit_1.load_s0: in_fire_first_issue, ", "ld1_s0_in_fire_first_issue"],
  ["LoadUnit_1.load_s0: addr_spec_success, ", "ld1_s0_addr_spec_success"],
  ["LoadUnit_1.load_s0: addr_spec_failed, ", "ld1_s0_addr_spec_failed"],
  ["LoadUnit_1.load_s0: addr_spec_success_once, ", "ld1_s0_addr_spec_success_once"],
  ["LoadUnit_1.load_s0: addr_spec_failed_once, ", "ld1_s0_addr_spec_failed_once"],
  ["LoadUnit_1.load_s1: in_fire, ", "ld1_s1_in_fire"],
  ["LoadUnit_1.load_s1: tlb_miss, ", "ld1_s1_tlb_miss"],
  ["LoadUnit_1.load_s1: in_fire_first_issue, ", "ld1_s1_in_fire_first_issue"],
  ["LoadUnit_1.load_s1: tlb_miss_first_issue, ", "ld1_s1_tlb_miss_first_issue"],
  ["LoadUnit_1.load_s2: in_fire, ", "ld1_s2_in_fire"],
  ["LoadUnit_1.load_s2: in_fire_first_issue, ", "ld1_s2_in_fire_first_issue"],
  ["LoadUnit_1.load_s2: dcache_miss, ", "ld1_s2_dcache_miss"],
  ["LoadUnit_1.load_s2: dcache_miss_first_issue, ", "ld1_s2_dcache_miss_first_issue"],
  ["LoadUnit_1.load_s2: full_forward, ", "ld1_s2_full_forward"],
  ["LoadUnit_1.load_s2: dcache_miss_full_forward, ", "ld1_s2_dcache_miss_full_forward"],
  ["LoadUnit_1.load_s2: replay, ", "ld1_s2_replay"],
  ["LoadUnit_1.load_s2: replay_tlb_miss, ", "ld1_s2_replay_tlb_miss"],
  ["LoadUnit_1.load_s2: replay_cache, ", "ld1_s2_replay_cache"],
  ["LoadUnit_1.load_s2: replay_from_fetch_forward, ", "ld1_s2_replay_from_fetch_forward"],
  ["LoadUnit_1.load_s2: replay_from_fetch_load_vio, ", "ld1_s2_replay_from_fetch_load_vio"],
  ["LoadUnit_1: load_to_load_forward, ", "ld1_load_to_load_forward"],
]

memblock_storepipe_perfcounter_nanhu = [
  ["StoreUnit_0.store_s1: in_fire,", "st0_s1_in_fire"],
  ["StoreUnit_0.store_s1: in_fire_first_issue,", "st0_s1_in_fire_first_issue"],
  ["StoreUnit_0.store_s1: tlb_miss,", "st0_s1_tlb_miss"],
  ["StoreUnit_0.store_s1: tlb_miss_first_issue,", "st0_s1_tlb_miss_first_issue"],

  ["StoreUnit_1.store_s1: in_fire,", "st1_s1_in_fire"],
  ["StoreUnit_1.store_s1: in_fire_first_issue,", "st1_s1_in_fire_first_issue"],
  ["StoreUnit_1.store_s1: tlb_miss,", "st1_s1_tlb_miss"],
  ["StoreUnit_1.store_s1: tlb_miss_first_issue,", "st1_s1_tlb_miss_first_issue"],
]

memblock_lq_perfcounter_nanhu = [
  ["memBlock.lsq.loadQueue: full, ", "lq_full"],
  ["memBlock.lsq.loadQueue: exHalf, ", "lq_exHalf"],
  ["memBlock.lsq.loadQueue: empty, ", "lq_empty"],
  ["memBlock.lsq.loadQueue: rollback, ", "lq_rollback"],
  ["memBlock.lsq.loadQueue: mmioCycle, ", "lq_mmioCycle"],
  ["memBlock.lsq.loadQueue: mmioCnt, ", "lq_mmioCnt"],
  ["memBlock.lsq.loadQueue: refill, ", "lq_refill"],
  ["memBlock.lsq.loadQueue: writeback_success, ", "lq_writeback_success"],
  ["memBlock.lsq.loadQueue: writeback_blocked, ", "lq_writeback_blocked"],
]

memblock_sq_perfcounter_nanhu = [
  ["memBlock.lsq.storeQueue: vaddr_match_really_failed, ", "sq_vaddr_match_really_failed"],
  ["memBlock.lsq.storeQueue: full, ", "sq_full"],
  ["memBlock.lsq.storeQueue: exHalf, ", "sq_exHalf"],
  ["memBlock.lsq.storeQueue: empty, ", "sq_empty"],
  ["memBlock.lsq.storeQueue: mmioCycle, ", "sq_mmioCycle"],
  ["memBlock.lsq.storeQueue: mmioCnt, ", "sq_mmioCnt"],
]

memblock_sbuffer_perfcounter_nanhu = [
  ["memBlock.sbuffer: do_uarch_drain, ", "wcb_do_uarch_drain"],
  ["memBlock.sbuffer: vaddr_match_failed, ", "wcb_vaddr_match_failed"],
  ["memBlock.sbuffer: util_15_16, ", "wcb_full"],
  ["memBlock.sbuffer: sbuffer_req_valid, ", "wcb_sbuffer_req_valid"],
  ["memBlock.sbuffer: sbuffer_req_fire, ", "wcb_sbuffer_req_fire"],
  ["memBlock.sbuffer: sbuffer_merge, ", "wcb_sbuffer_merge"],
  ["memBlock.sbuffer: sbuffer_newline, ", "wcb_sbuffer_newline"],
  ["memBlock.sbuffer: dcache_req_valid, ", "wcb_dcache_req_valid"],
  ["memBlock.sbuffer: dcache_req_fire, ", "wcb_dcache_req_fire"],
  ["memBlock.sbuffer: sbuffer_flush, ", "wcb_sbuffer_flush"],
  ["memBlock.sbuffer: sbuffer_replace, ", "wcb_sbuffer_replace"],
  ["memBlock.sbuffer: mainpipe_resp_valid, ", "wcb_mainpipe_resp_valid"],
  ["memBlock.sbuffer: refill_resp_valid, ", "wcb_refill_resp_valid"],
  ["memBlock.sbuffer: replay_resp_valid, ", "wcb_replay_resp_valid"],
  ["memBlock.sbuffer: coh_timeout, ", "wcb_coh_timeout"],
]

memblock_dcache_perfcounter_nanhu = [
  ["dcache.mainPipe: mainpipe_tag_write, ", "mainpipe_tag_write"],

  ["dcache.dcache: num_loads, ", "dc_num_loads"],
  ["dcache.dcache: access_early_replace, ", "dc_access_early_replace"],
  ["dcache.dcache.wb: wb_req, ", "dc_wb_req"],
  ["dcache.bankedDataArray: data_array_multi_read, ", "dc_data_array_multi_read"],
  ["dcache.bankedDataArray: data_array_rr_bank_conflict, ", "dc_data_array_rr_bank_conflict"],
  ["bankedDataArray: data_array_rrl_bank_conflict(0), ", "dc_data_array_rrl_bank_conflict_0"],
  ["bankedDataArray: data_array_rrl_bank_conflict(1), ", "dc_data_array_rrl_bank_conflict_1"],
  ["bankedDataArray: data_array_rw_bank_conflict_0, ", "dc_data_array_rw_bank_conflict_0"],
  ["bankedDataArray: data_array_rw_bank_conflict_1, ", "dc_data_array_rw_bank_conflict_1"],
  ["bankedDataArray: data_array_read_line, ", "dc_data_array_read_line"],
  ["bankedDataArray: data_array_write, ", "dc_data_array_write"],

  ["dcache.ldu_0: load_replay_for_data_nack, ", "dcld0_load_replay_for_data_nack"], 
  ["dcache.ldu_0: load_replay_for_no_mshr, ", "dcld0_load_replay_for_no_mshr"], 
  ["dcache.ldu_0: load_replay_for_conflict, ", "dcld0_load_replay_for_conflict"], 
  ["dcache.ldu_0: load_hit, ", "dcld0_load_hit"], 
  ["dcache.ldu_0: load_miss, ", "dcld0_load_miss"], 
  ["dcache.ldu_0: load_succeed, ", "dcld0_load_succeed"], 
  ["dcache.ldu_0: load_miss_or_conflict, ", "dcld0_load_miss_or_conflict"], 
  ["dcache.ldu_0: load_req, ", "dcld0_load_req"], 
  ["dcache.ldu_1: load_replay_for_data_nack, ", "dcld1_load_replay_for_data_nack"], 
  ["dcache.ldu_1: load_replay_for_no_mshr, ", "dcld1_load_replay_for_no_mshr"], 
  ["dcache.ldu_1: load_replay_for_conflict, ", "dcld1_load_replay_for_conflict"], 
  ["dcache.ldu_1: load_hit, ", "dcld1_load_hit"], 
  ["dcache.ldu_1: load_miss, ", "dcld1_load_miss"], 
  ["dcache.ldu_1: load_succeed, ", "dcld1_load_succeed"], 
  ["dcache.ldu_1: load_miss_or_conflict, ", "dcld1_load_miss_or_conflict"], 
  ["dcache.ldu_1: load_req, ", "dcld1_load_req"], 
  ["dcache.missQueue: miss_req, ", "dcmq_miss_req_fire"],
  ["dcache.missQueue: miss_req_allocate, ", "dcmq_miss_req_allocate"],
  ["dcache.missQueue: miss_req_merge_load, ", "dcmq_miss_req_merge_load"],
  ["dcache.missQueue: miss_req_reject_load, ", "dcmq_miss_req_reject_load"],
  ["dcache.missQueue: probe_blocked_by_miss, ", "dcmq_probe_blocked_by_miss"],
  ["dcache.missQueue: full, ", "dcmq_full"],
  ["dcache.missQueue: exHalf, ", "dcmq_exHalf"],
  ["dcache.missQueue: empty, ", "dcmq_empty"],
  ["dcache.wb: wb_req, ", "dc_wb_req"],
]

memblock_extracounter_nanhu_list = [
  "addr_spec_succeed",
  "ldld_fwd_rate",
  "ld_tlb_hit_rate_1stissue",
  "ld_dcache_hit_rate_1stissue",
  "vfwd_fail",
  "vfwd_fail_div_ld",
  "vfwd_fail_pki",
  "ldld_vio_div_ld",
  "ldst_vio_div_ld",
  "ldld_vio_pki",
  "ldst_vio_pki",
  "st_tlb_hit_rate_1stissue",
  "lq_full_rate",
  "sq_full_rate",
  "sq_vaddr_match_really_failed",
  "sbuffer_full_rate",
  "sbuffer_allocate_rate",
  "sbuffer_merge_rate",
  "st_dcache_stall_rate",
  "st_dcache_hit_rate",
  "st_dcache_replay_rate",
  "wcb_coh_timeout",
  "dc_access_early_replace_rate",
  "dc_miss_allocate_rate",
  "dc_miss_merge_rate",
  "dc_miss_reject_rate",
  "dc_miss_fire_merge_rate",
  "dc_missq_full_rate",
]

perf_counter = memblock_loadpipe_perfcounter_nanhu + memblock_storepipe_perfcounter_nanhu + memblock_lq_perfcounter_nanhu + memblock_sq_perfcounter_nanhu + memblock_sbuffer_perfcounter_nanhu + memblock_dcache_perfcounter_nanhu
extra_counter_name = ""
for name in memblock_extracounter_nanhu_list:
  extra_counter_name = extra_counter_name + "," + name

def iprint(str):
  print(","+str, end="")

def get_perf_counter():
    return perf_counter

def get_perf_counter_name():
    return extra_counter_name

def print_extra_counter(spec):
  # addr_spec_succeed
  iprint("%.4f"%((spec.record["ld0_s0_addr_spec_success"]+spec.record["ld1_s0_addr_spec_success"])/(spec.record["ld0_s0_addr_spec_success"] + spec.record["ld1_s0_addr_spec_success"] + spec.record["ld0_s0_addr_spec_failed"] + spec.record["ld1_s0_addr_spec_failed"])))
  # ldld_fwd_rate
  iprint("%.4f"%((spec.record["ld0_load_to_load_forward"]+spec.record["ld1_load_to_load_forward"]) / (spec.record["ld0_s0_in_fire_first_issue"]+spec.record["ld1_s0_in_fire_first_issue"])))
  # ld_tlb_hit_rate_1stissue
  iprint("%.4f"%(1-(spec.record["ld0_s1_tlb_miss_first_issue"]+spec.record["ld1_s1_tlb_miss_first_issue"]) / (spec.record["ld0_s1_in_fire_first_issue"]+spec.record["ld1_s1_in_fire_first_issue"])))
  # ld_dcache_hit_rate_1stissue
  iprint("%.4f"%(1-(spec.record["ld0_s2_dcache_miss_first_issue"]+spec.record["ld1_s2_dcache_miss_first_issue"]) / (spec.record["ld0_s2_in_fire_first_issue"]+spec.record["ld1_s2_in_fire_first_issue"])))
  # vfwd_fail
  iprint("%.4f"%(spec.record["ld0_s2_replay_from_fetch_forward"]+spec.record["ld1_s2_replay_from_fetch_forward"]))
  # vfwd_fail_div_ld
  iprint("%.4f"%((spec.record["ld0_s2_replay_from_fetch_forward"]+spec.record["ld1_s2_replay_from_fetch_forward"]) / (spec.record["ld0_s1_in_fire_first_issue"]+spec.record["ld1_s1_in_fire_first_issue"])))
  # vfwd_fail_pki
  iprint("%.4f"%((spec.record["ld0_s2_replay_from_fetch_forward"]+spec.record["ld1_s2_replay_from_fetch_forward"]) / spec.record["instrCnt"] * 1000))
  # ldld_vio_div_ld
  iprint("%.4f"%((spec.record["ld0_s2_replay_from_fetch_load_vio"]+spec.record["ld1_s2_replay_from_fetch_load_vio"]) / (spec.record["ld0_s1_in_fire_first_issue"]+spec.record["ld1_s1_in_fire_first_issue"])))
  # ldst_vio_div_ld
  iprint("%.4f"%(spec.record["lq_rollback"] / (spec.record["ld0_s1_in_fire_first_issue"]+spec.record["ld1_s1_in_fire_first_issue"])))
  # ldld_vio_pki
  iprint("%.4f"%((spec.record["ld0_s2_replay_from_fetch_load_vio"]+spec.record["ld1_s2_replay_from_fetch_load_vio"]) / spec.record["instrCnt"] * 1000))
  # ldst_vio_pki
  iprint("%.4f"%(spec.record["lq_rollback"] / spec.record["instrCnt"] * 1000))
  # st_tlb_hit_rate_1stissue
  iprint("%.4f"%((spec.record["st0_s1_tlb_miss_first_issue"]+spec.record["st1_s1_tlb_miss_first_issue"]) / (spec.record["st0_s1_in_fire_first_issue"]+spec.record["st1_s1_in_fire_first_issue"])))
  # lq_full_rate
  iprint("%.4f"%(spec.record["lq_full"] / spec.record["clockCycle"]))
  # sq_full_rate
  iprint("%.4f"%(spec.record["sq_full"] / spec.record["clockCycle"]))
  # sq_vaddr_match_really_failed
  iprint("%.4f"%(spec.record["sq_vaddr_match_really_failed"]))
  # sbuffer_full_rate
  iprint("%.4f"%(spec.record["wcb_full"] / spec.record["clockCycle"]))
  # sbuffer_allocate_rate
  iprint("%.4f"%(spec.record["wcb_sbuffer_newline"] / spec.record["wcb_sbuffer_req_fire"]))
  # sbuffer_merge_rate
  iprint("%.4f"%(spec.record["wcb_sbuffer_merge"] / spec.record["wcb_sbuffer_req_fire"]))
  # st_dcache_stall_rate
  iprint("%.4f"%(1 - (spec.record["wcb_dcache_req_fire"] / spec.record["wcb_dcache_req_valid"])))
  # st_dcache_hit_rate
  iprint("%.4f"%(spec.record["wcb_mainpipe_resp_valid"] / spec.record["wcb_dcache_req_fire"]))
  # st_dcache_replay_rate
  iprint("%.4f"%(spec.record["wcb_replay_resp_valid"] / (spec.record["wcb_mainpipe_resp_valid"]+spec.record["wcb_refill_resp_valid"]+spec.record["wcb_replay_resp_valid"])))
  # wcb_coh_timeout
  iprint("%.4f"%(spec.record["wcb_coh_timeout"]))
  # dc_access_early_replace_rate
  iprint("%.4f"%(spec.record["dc_access_early_replace"] / spec.record["dc_num_loads"]))
  # dc_miss_allocate_rate
  iprint("%.4f"%(spec.record["dcmq_miss_req_allocate"] / (spec.record["dcmq_miss_req_fire"]+spec.record["dcmq_miss_req_reject_load"])))
  # dc_miss_merge_rate
  iprint("%.4f"%(spec.record["dcmq_miss_req_merge_load"] / (spec.record["dcmq_miss_req_fire"]+spec.record["dcmq_miss_req_reject_load"])))
  # dc_miss_reject_rate
  iprint("%.4f"%(spec.record["dcmq_miss_req_reject_load"] / (spec.record["dcmq_miss_req_fire"]+spec.record["dcmq_miss_req_reject_load"])))
  # dc_miss_fire_merge_rate
  iprint("%.4f"%(spec.record["dcmq_miss_req_merge_load"] / spec.record["dcmq_miss_req_fire"]))
  # dc_missq_full_rate
  iprint("%.4f"%(spec.record["dcmq_full"] / spec.record["clockCycle"]))

  # iprint("%.4f"%(spec.record["instrCnt"] / spec.record["clockCycle"]))
