#! /usr/bin/env python3

import os
import sys
import matplotlib.pyplot as plt
import argparse
import sqlite3


class DBTrace(object):

    def __init__(self, dbname, table):
        print("Opening database: " + dbname)
        self.conn = sqlite3.connect(dbname)
        self.cursor = self.conn.cursor()
        self.table = table
        self.addr_col = None
        self.stamp_col = None
        self.emphasis_col = None
        self.emphasis_value = 1
        self.trace_y = []
        self.trace_y_e = []
        self.trace_x = []
        self.trace_x_e = []
        self.emphasis_trace = []
        self.cnt = 1
        self.start = 1
        self.finish = sys.maxsize

    def set_address(self, addr_col):
        self.addr_col = addr_col

    def set_time_stamp(self, stamp_col):
        self.stamp_col = stamp_col

    def set_emphasis(self, emphasis_col):
        self.emphasis_col = emphasis_col

    def set_start(self, s):
        self.start = s

    def set_finish(self, f):
        self.finish = f

    def reverse_emphasis(self):
        self.emphasis_value = 1 - self.emphasis_value

    def release(self):
        self.conn.close()

    def derive_trace(self, debug=False):
        addr_sql = 'SELECT {} FROM {} WHERE ID BETWEEN {} AND {}'.format(
            self.addr_col, self.table, self.start, self.finish)
        stamp_sql = 'SELECT {} FROM {} WHERE ID BETWEEN {} AND {}'.format(
            self.stamp_col, self.table, self.start, self.finish)
        emphasis_sql = 'SELECT {} FROM {} WHERE ID BETWEEN {} AND {}'.format(
            self.emphasis_col, self.table, self.start, self.finish)

        addr_query = self.conn.cursor().execute(addr_sql)
        stamp_query = self.conn.cursor()
        emphasis_query = self.conn.cursor()

        if self.stamp_col is not None:
            stamp_query = self.conn.cursor().execute(stamp_sql)
        if self.emphasis_col is not None:
            emphasis_query = self.conn.cursor().execute(emphasis_sql)
        for addr_q in addr_query:
            addr = addr_q[0]
            if self.emphasis_col is None:
                self.trace_y.append(addr)
                if self.stamp_col is None:
                    self.trace_x.append(self.cnt)
                else:
                    self.trace_x.append(stamp_query.fetchone()[0])
            else:
                if emphasis_query.fetchone()[0] == self.emphasis_value:
                    self.emphasis_trace.append(1)
                    self.trace_y_e.append(addr)
                    if self.stamp_col is None:
                        self.trace_x_e.append(self.cnt)
                    else:
                        self.trace_x_e.append(stamp_query.fetchone()[0])
                else:
                    self.emphasis_trace.append(0)
                    self.trace_y.append(addr)
                    if self.stamp_col is None:
                        self.trace_x.append(self.cnt)
                    else:
                        self.trace_x.append(stamp_query.fetchone()[0])
            self.cnt += 1
        if debug:
            for i in range(100):
                print(self.trace_x[i])
            print()
            for i in range(100):
                print(self.trace_y[i])
            if self.emphasis_col is not None:
                for i in range(100):
                    print(self.trace_y_e[i])

    def emphasis_rate_rolling(self, aggregate=1):
        aggcnt = 0
        aggydata = 0
        ydata = []
        for p in self.emphasis_trace:
            aggcnt += 1
            aggydata += p
            if aggcnt == aggregate:
                ydata.append(aggydata / aggregate)
                aggcnt = 0
                aggydata = 0
        xdata = range(len(ydata))
        plt.plot(xdata, ydata, c='#000000', alpha=1, lw=1, ls='-')
        plt.show()

    def plot(self, r, emphasis_only):
        print("Painting...")
        if emphasis_only is None:
            plt.scatter(list(map(lambda x:x-self.trace_x[0], self.trace_x)), self.trace_y, c='#000000',alpha=1, s=1)
        plt.scatter(list(map(lambda x:x-self.trace_x_e[0], self.trace_x_e)), self.trace_y_e, c='#FF0000', alpha=1, s=1)
        plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('arch_db', action='store', type=str, help="Architecture database")
    parser.add_argument('table', action='store', type=str, help="Table that interests")
    parser.add_argument('-a', '--address', action='store', type=str, help='Address column of database')
    parser.add_argument('-t', '--time-stamp', action='store', type=str, help='Time stamp column of database')
    parser.add_argument('-e', '--emphasis', action='store', type=str, help='Emphasis flag column of database')
    parser.add_argument('-r', '--reverse', action='store_true', default=None, help='Reverse emphasis')
    parser.add_argument('-s', '--start', action='store', type=int, help='Start limit of datapoints')
    parser.add_argument('-f', '--finish', action='store', type=int, help='Finish limit of datapoints')
    parser.add_argument('--emphasis-only', action='store_true', default=None, help='Show emphasis only')
    parser.add_argument('--emphasis-rate-rolling', action='store_true', default=None, help='Show emphasis rate rolling')
    parser.add_argument('-g', '--rolling-aggregation', action='store', type=int, help='Rolling aggregation')
    args = parser.parse_args()

    if args.address is None:
        print("Please provide valid address and time stamp column of the database")
        exit(-1)

    trace = DBTrace(args.arch_db, args.table)
    trace.set_address(args.address)
    trace.set_time_stamp(args.time_stamp)
    if args.emphasis is not None:
        trace.set_emphasis(args.emphasis)
    if args.start is not None:
        trace.set_start(args.start)
    if args.finish is not None:
        trace.set_finish(args.finish)
    if args.reverse is not None:
        trace.reverse_emphasis()
    trace.derive_trace()
    trace.plot(-1, args.emphasis_only)
    if args.emphasis_rate_rolling is not None:
        trace.emphasis_rate_rolling(1 if args.rolling_aggregation is None else args.rolling_aggregation)
    trace.release()
