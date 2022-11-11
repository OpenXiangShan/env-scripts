#! /usr/bin/env zsh
# Usage: zsh/bash me.sh xsbranch(or commitId) bitStreamTag patch-list
# e.g. zsh me.sh nanhu v1111-6MBL3-90delay 6MBL3-90delay
# NOTE: patch-list will be split by "-"
set -v

fpga_dir=/nfs/home/share/fpga/fpga-gen

if [ $# -ne 3 ]; then
    echo "Usage: $0 whichbranch whichdir(abs path) whichpatch"
    echo "patch path : $fpga_dir/patch"
    echo "$(ls $fpga_dir/patch) : patch"
    echo "example: $0 nanhu nanhu-6MBL3 fpga-6MBL3.patch"
    exit 1
fi

xsBranch=$1
bsTag=$2
bsDir=$fpga_dir/bitgen-$bsTag
xsDir=$fpga_dir/xs-$bsTag
xsPatch=$3

echo "generating verilog..."
bash gen_xiangshan.sh $xsBranch $xsDir $xsPatch
if [ $? -ne 0 ]; then
    echo "gen_xiangshan.sh failed"
    exit 1
fi

zsh gen_bs_from_chisel.sh $xsDir $bsTag
