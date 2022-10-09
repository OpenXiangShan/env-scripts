#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path)
set -v

xsBranch=$1
xsDir=$2

git clone https://github.com/OpenXiangShan/XiangShan.git $xsDir

cd $xsDir
git checkout $xsBranch
make init
git apply /nfs/home/share/zzf/fpga.patch
export NOOP_HOME=$(pwd)
export NEMU_HOME=$(pwd)
make verilog -j17
