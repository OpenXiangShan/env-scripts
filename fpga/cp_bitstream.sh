#! /usr/bin/env zsh
# Usage: zsh cp_bs.sh bsDir bsTag

bsSrc=$1
bsDest=/nfs/home/share/fpga/bits/$2

mkdir $bsDest
cp $bsSrc/xs_nanhu/xs_nanhu.runs/impl_1/xs_fpga_top_debug.bit $bsDest
cp $bsSrc/xs_nanhu/xs_nanhu.runs/impl_1/xs_fpga_top_debug.ltx $bsDest
