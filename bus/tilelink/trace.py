#! /usr/bin/env python3

import os
import re
import matplotlib.pyplot as plt
from txn_model import *


class Trace(object):
    memtrace = []
    cnt = 0

    def append_record(self, record: Record):
        self.memtrace.append((record.time, record.address))
        self.cnt += 1

    def __init__(self, records):
        for record in records:
            self.append_record(record)
        print("Trace cnt: " + str(self.cnt))

    def plot_memtrace(self, r):
        print("Painting...")

        plt.scatter([x[0] for x in self.memtrace], [x[1] for x in self.memtrace], c='#000000',alpha=1, s=1)
        plt.show()
