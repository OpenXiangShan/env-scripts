#! /usr/bin/env python3

import argparse
import os
from parser import VCollection

import generator


def main(files):
    collection = VCollection()
    for f in files:
        collection.load_modules(f)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Verilog helper')
    parser.add_argument('vfiles', metavar='filename', type=str, nargs='+',
                        help='input verilog file')
    # parser.add_argument('--sum', dest='accumulate', action='store_const',
    #                     const=sum, default=max,
    #                     help='sum the integers (default: find the max)')

    args = parser.parse_args()

    main(args.vfiles)

