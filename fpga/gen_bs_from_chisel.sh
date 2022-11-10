#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path)
# from chisel. User should prepare all-ready chisel
set -v

fpga_dir=/nfs/home/share/fpga/fpga-gen

xsDir=$1
bsTag=$2

echo "generating verilog..."
cd $xsDir
export NOOP_HOME=$(pwd)
export NEMU_HOME=$(pwd)
make clean
make verilog -j17
cd -

zsh gen_bs_from_verilog.sh $xsDir/build $bsTag
