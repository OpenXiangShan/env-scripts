import argparse
import sqlite3
import os
import pickle
from tl_const import *
from utils import *
from txn_model import *
from trace import Trace


class TxnPool:
    def __init__(self):
        if not os.path.exists("./csv"):
            os.mkdir("./csv")
        pass

    def set_txns(self, txns):
        self.txns = txns
        self.sub_txns = dict()
        print("Total txns: " + str(len(txns)))

    def type_profile(self):
        print("============ Type Profiling ============")
        print("ICache Get: "     + str(len(list(filter(func_icache_get,     self.txns)))))
        print("ICache Hint: "    + str(len(list(filter(func_icache_hint,    self.txns)))))
        print("DCache Acquire: " + str(len(list(filter(func_dcache_acquire, self.txns)))))
        print("DCache Release: " + str(len(list(filter(func_dcache_release, self.txns)))))
        print("DCache Hint: "    + str(len(list(filter(func_dcache_hint,    self.txns)))))
        print("L2 Release: "     + str(len(list(filter(func_l2_release,     self.txns)))))
        print("L3 Release: "     + str(len(list(filter(func_l3_release,     self.txns)))))
        print("L2 Probe: "       + str(len(list(filter(func_l2_probe,       self.txns)))))
        print("L3 Probe: "       + str(len(list(filter(func_l3_probe,       self.txns)))))
        print("========================================")

        self.sub_txns[TxnType.ICacheGet.value] = list(filter(func_icache_get, self.txns))
        self.sub_txns[TxnType.ICacheHint.value] = list(filter(func_icache_hint, self.txns))
        self.sub_txns[TxnType.DCacheAcquire.value] = list(filter(func_dcache_acquire, self.txns))
        self.sub_txns[TxnType.DCacheRelease.value] = list(filter(func_dcache_release, self.txns))
        self.sub_txns[TxnType.DCacheHint.value] = list(filter(func_dcache_hint, self.txns))
        self.sub_txns[TxnType.L2Release.value] = list(filter(func_l2_release, self.txns))
        self.sub_txns[TxnType.L3Release.value] = list(filter(func_l3_release, self.txns))
        self.sub_txns[TxnType.L2Probe.value] = list(filter(func_l2_probe, self.txns))
        self.sub_txns[TxnType.L3Probe.value] = list(filter(func_l3_probe, self.txns))

    def matrix_derive(self, f_func, m_func, dump=False):
        f = list(filter(f_func, self.txns))
        matrix = list(map(m_func, f))
        if dump:
            for txn in f:
                txn.dump()
                print()
        draw_hist(matrix, f_func.__name__)

    def split_dcache_acquire(self, dump=False):
        for txn in self.sub_txns[TxnType.DCacheAcquire.value]:
            assert txn.len() == 2 or txn.len() == 4 or txn.len() == 6

        # count overall transaction latency
        l2hit_txn = list(filter(lambda x: x.len() == 2, self.sub_txns[TxnType.DCacheAcquire.value]))
        print("dcache acquire l2 hit: " + str(len(l2hit_txn)))
        if dump:
            for txn in l2hit_txn:
                txn.dump()
        hit_latency = list(map(lifetime, l2hit_txn))
        draw_hist(hit_latency, "dcache_hit_latency")

        l3hit_txn = list(filter(lambda x: x.len() == 4, self.sub_txns[TxnType.DCacheAcquire.value]))
        print("dcache acquire l3 hit: " + str(len(l3hit_txn)))
        if dump:
            for txn in l3hit_txn:
                txn.dump()
        hit_latency = list(map(lifetime, l3hit_txn))
        draw_hist(hit_latency, "dcache_l3hit_latency")

        allmiss_txn = list(filter(lambda x: x.len() == 6, self.sub_txns[TxnType.DCacheAcquire.value]))
        print("dcache all miss: " + str(len(allmiss_txn)))
        if dump:
            for txn in allmiss_txn:
                txn.dump()
        hit_latency = list(map(lifetime, allmiss_txn))
        draw_hist(hit_latency, "dcache_miss_latency")

        # separate L3 hit latency
        l3hit_acquiregap_lat = list(map(acquire_gap_latency, l3hit_txn))
        l3hit_l3process_lat = list(map(l3_process_latency, l3hit_txn))
        l3hit_l3l2grant_lat = list(map(l3l2_grant_latency, l3hit_txn))
        draw_hist(l3hit_acquiregap_lat, "dcache_l3hit_latency1")
        draw_hist(l3hit_l3process_lat, "dcache_l3hit_latency2")
        draw_hist(l3hit_l3l2grant_lat, "dcache_l3hit_latency3")

        # separate All miss latency
        allmiss_mem_lat = list(map(mem_process_latency, allmiss_txn))
        draw_hist(allmiss_mem_lat, "dcache_miss_latency1")

    def split_prefetch_acquire(self, dump=False):
        for txn in self.sub_txns[TxnType.DCacheHint.value]:
            assert txn.len() == 2 or txn.len() == 4
        l2hit_txn = list(filter(lambda x: x.len() == 2, self.sub_txns[TxnType.DCacheHint.value]))
        print("dcache hint l3 hit: " + str(len(l2hit_txn)))
        if dump:
            for txn in l2hit_txn:
                txn.dump()
        hit_latency = list(map(lifetime, l2hit_txn))
        draw_hist(hit_latency, "dcache_hint_l3hit_latency")

        allmiss_txn = list(filter(lambda x: x.len() == 4, self.sub_txns[TxnType.DCacheHint.value]))
        print("dcache hint all miss: " + str(len(allmiss_txn)))
        if dump:
            for txn in allmiss_txn:
                txn.dump()
        hit_latency = list(map(lifetime, allmiss_txn))
        draw_hist(hit_latency, "dcache_hint_allmiss_latency")

    def derive_addr_distrib(self):
        acquire_sets = list(map(lambda x: x.address, self.sub_txns[TxnType.DCacheAcquire.value]))
        draw_hist(acquire_sets, "dcache_acquire_addrs")
        hint_sets = list(map(lambda x: x.address, self.sub_txns[TxnType.DCacheHint.value]))
        draw_hist(hint_sets, "dcache_hint_addrs")

    def plot_dcache_acquire_trace(self, txntype):
        trace = Trace(list(map(lambda x: x.get_top(), self.sub_txns[txntype.value])))
        trace.plot_memtrace(0)


def extract_by_addr(c, addr):
    cursor = c.execute("SELECT * FROM TLLOG WHERE ADDRESS='" + str(addr) + "'")
    generate_txn(cursor)


def extract_all(c):
    cursor = c.execute("SELECT * FROM TLLOG")
    generate_txn(cursor)


def extract_by_limit(c, limit):
    cursor = c.execute("SELECT * FROM TLLOG LIMIT " + str(limit))
    generate_txn(cursor)


def generate_txn(cursor, dump=False):
    pending_txns = []
    finished_txns = []
    data_flag = True
    datapool = set()
    i = 0
    for row in cursor:
        record = Record(row)
        # print(record)
        i += 1
        if i % 10000 == 0:
            print('.', end="", flush=True)
            pass
        append_flag = True
        if record.has_data():
            if record.address not in datapool:
                datapool.add(record.address)
                continue
            else:
                datapool.remove(record.address)
        for txn in pending_txns:
            if (record.address == txn.address) and (txn.merge(record)):
                append_flag = False
            if txn.state == TxnState.Finished:
                finished_txns.append(txn)
                pending_txns.remove(txn)
                break
        if append_flag:
            txn = Transaction(record)
            pending_txns.append(txn)

    # clear standalone hint
    pending_txns_real = []
    for tnx in pending_txns:
        if not (tnx.byHint and tnx.len() == 1):
            pending_txns_real.append(tnx)
    print()
    if dump:
        print("\nnrPendingTxn: " + str(len(pending_txns_real)))
        print("nrFinishedTxn: " + str(len(finished_txns)))
        for txn in finished_txns:
            txn.dump()
            print()
        print("=================================================================")
        for txn in pending_txns_real:
            txn.dump()
            print()
    global txnpool
    txnpool.set_txns(finished_txns)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('object', action='store', type=str, help="Load database or pickle")
    parser.add_argument('-p', "--pickle", action='store_true', default=None, help='Save txnpool to pickle')
    args = parser.parse_args()
    assert (os.path.exists(args.object))
    txnpool = TxnPool()

    extract_db = args.object[-3:] == ".db"
    extract_pickle = args.object[-4:] == ".pkl"
    dump_pickle = args.pickle is not None
    assert extract_db or extract_pickle
    assert not (extract_pickle and dump_pickle)

    if extract_db:
        print("Opening database: " + args.object)
        conn = sqlite3.connect(args.object)
        c = conn.cursor()
        cursor = c.execute("SELECT COUNT(*) FROM TLLOG")
        print("Total records: " + str(cursor.fetchone()[0]))
        # extract_by_addr(c, 0x80002700)
        # extract_by_limit(c, 40000000)
        extract_all(c)
        conn.close()

    if extract_pickle:
        print("Opening pickle: " + args.object)
        with open(args.object, 'rb') as f:
            txnpool = pickle.load(f)
        f.close()

    if dump_pickle:
        with open('txnpool.pkl', 'wb') as f:
            pickle.dump(txnpool, f)
        f.close()

    txnpool.type_profile()
    txnpool.matrix_derive(func_dcache_acquire, lifetime)
    txnpool.split_dcache_acquire()
    txnpool.split_prefetch_acquire()
    txnpool.derive_addr_distrib()
    txnpool.plot_dcache_acquire_trace(TxnType.DCacheHint)
