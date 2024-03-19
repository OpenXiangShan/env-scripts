from txn_extract import Transaction
from tl_const import *
import matplotlib.pyplot as plt
import pandas as pd


def func_icache_hint(x: Transaction):
    return x.byHint


def func_icache_get(x: Transaction):
    r = x.records[0]
    return r.is_get() and up_node(r.location.value) == Node.L1I


def func_ptw_get(x: Transaction):
    r = x.records[0]
    return r.is_get() and up_node(r.location.value) == Node.PTW


def func_dcache_hint(x: Transaction):
    r = x.records[0]
    return r.is_acquire() and up_node(r.location.value) == Node.L2


def func_dcache_acquire(x: Transaction):
    r = x.records[0]
    return r.is_acquire() and up_node(r.location.value) == Node.L1D


def func_dcache_release(x: Transaction):
    r = x.records[0]
    return r.is_release() and up_node(r.location.value) == Node.L1D


def func_l2_release(x: Transaction):
    r = x.records[0]
    return r.is_release() and up_node(r.location.value) == Node.L2


def func_l3_release(x: Transaction):
    r = x.records[0]
    return r.is_release() and up_node(r.location.value) == Node.L3


def func_l2_probe(x: Transaction):
    r = x.records[0]
    return r.is_probe() and down_node(r.location.value) == Node.L2


def func_l3_probe(x: Transaction):
    r = x.records[0]
    return r.is_probe() and down_node(r.location.value) == Node.L3


def lifetime(x: Transaction):
    return x.records[-1].time - x.records[0].time


def acquire_gap_latency(x: Transaction):
    assert x.records[0].is_acquire() and x.records[1].is_acquire()
    assert x.records[0].location == Location.L2_L1D_0 and x.records[1].location == Location.L3_L2_0
    return x.records[1].time - x.records[0].time


def l3_process_latency(x: Transaction):
    assert x.records[1].is_acquire() and x.records[2].is_grant()
    assert x.records[1].location == Location.L3_L2_0 and x.records[2].location == Location.L3_L2_0
    return x.records[2].time - x.records[1].time


def l3l2_grant_latency(x: Transaction):
    assert x.records[2].is_grant() and x.records[3].is_grant()
    assert x.records[2].location == Location.L3_L2_0 and x.records[3].location == Location.L2_L1D_0
    return x.records[3].time - x.records[2].time


def mem_process_latency(x: Transaction):
    assert x.records[2].location == Location.MEM_L3 and x.records[3].location == Location.MEM_L3
    assert x.records[2].is_acquire() and x.records[3].is_grant()
    return x.records[3].time - x.records[2].time


def draw_hist(m: list, name):
    df = pd.DataFrame(m)
    df.to_csv("./csv/" + name + ".csv")


def get_set(addr):
    print