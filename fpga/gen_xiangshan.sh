#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path) whichpatch
set -v

fpga_dir=/nfs/home/share/fpga/fpga-gen
if [ $# -ne 3 ]; then
    echo "Usage: $0 whichbranch whichdir(abs path) whichpatch"
    echo "$(ls $fpga_dir/patch) : patch"
    exit 1
fi

xsBranch=$1
xsDir=$2
xsPatch=$3

git clone https://github.com/OpenXiangShan/XiangShan.git $xsDir

cd $xsDir
git checkout $xsBranch
make init

if [ $xsPatch != "nopatch" ]; then
    if [ -f $fpga_dir/patch/$xsPatch ]; then
        git apply $fpga_dir/patch/$xsPatch
    else
        echo "patch file not found"
        exit 1
    fi
fi

export NOOP_HOME=$(pwd)
export NEMU_HOME=$(pwd)
make verilog -j16

