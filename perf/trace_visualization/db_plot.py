#! /usr/bin/env python3

import os
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
        self.trace_y = []
        self.trace_y_e = []
        self.trace_x = []
        self.trace_x_e = []
        self.cnt = 1
        self.limit = -1

    def set_address(self, addr_col):
        self.addr_col = addr_col

    def set_time_stamp(self, stamp_col):
        self.stamp_col = stamp_col

    def set_emphasis(self, emphasis_col):
        self.emphasis_col = emphasis_col

    def set_limit(self, limit):
        self.limit = limit

    def release(self):
        self.conn.close()

    def derive_trace(self, debug=False):
        addr_query = self.conn.cursor().execute('SELECT {} FROM {} LIMIT {}'.format(self.addr_col, self.table, self.limit))
        stamp_query = self.conn.cursor()
        emphasis_query = self.conn.cursor()
        if self.stamp_col is not None:
            stamp_query = self.conn.cursor().execute('SELECT {} FROM {} LIMIT {}'.format(self.stamp_col, self.table, self.limit))
        if self.emphasis_col is not None:
            emphasis_query = self.conn.cursor().execute('SELECT {} FROM {} LIMIT {}'.format(self.emphasis_col, self.table, self.limit))
        for addr_q in addr_query:
            addr = addr_q[0]
            if self.emphasis_col is None:
                self.trace_y.append(addr)
                if self.stamp_col is None:
                    self.trace_x.append(self.cnt)
                else:
                    self.trace_x.append(stamp_query.fetchone()[0])
            else:
                if emphasis_query.fetchone()[0] == 1:
                    self.trace_y_e.append(addr)
                    if self.stamp_col is None:
                        self.trace_x_e.append(self.cnt)
                    else:
                        self.trace_x_e.append(stamp_query.fetchone()[0])
                else:
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

    def plot(self, r):
        print("Painting...")
        plt.scatter(self.trace_x, self.trace_y, c='#000000',alpha=1, s=50)
        plt.scatter(self.trace_x_e, self.trace_y_e, c='#FF0000', alpha=1, s=50)
        plt.show()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('arch_db', action='store', type=str, help="Architecture database")
    parser.add_argument('table', action='store', type=str, help="Table that interests")
    parser.add_argument('-a', '--address', action='store', type=str, help='Address column of database')
    parser.add_argument('-t', '--time-stamp', action='store', type=str, help='Time stamp column of database')
    parser.add_argument('-e', '--emphasis', action='store', type=str, help='Emphasis flag column of database')
    parser.add_argument('-l', '--limit', action='store', type=str, help='Limit of datapoints')
    args = parser.parse_args()

    if args.address is None:
        print("Please provide valid address and time stamp column of the database")
        exit(-1)

    trace = DBTrace(args.arch_db, args.table)
    trace.set_address(args.address)
    trace.set_time_stamp(args.time_stamp)
    if args.emphasis is not None:
        trace.set_emphasis(args.emphasis)
    if args.limit is not None:
        trace.set_limit(args.limit)
    trace.derive_trace()
    trace.plot(-1)
    trace.release()
