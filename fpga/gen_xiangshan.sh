#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path) whichpatch
set -v

fpga_dir=/nfs/home/share/fpga/fpga-gen
if [ $# -ne 3 ]; then
    echo "Usage: $0 whichbranch(or commit id) whichdir(abs path) whichpatch"
    echo "$(ls $fpga_dir/patch) : patch"
    echo "patch is splited into several sub-patch-es"
    echo "example: $0 nanhu nanhu-6MBL3 6MBL3-90delay"
    exit 1
fi

xsBranch=$1
xsDir=$2
xsPatch=$3

rm -rf $xsDir
git clone https://github.com/OpenXiangShan/XiangShan.git $xsDir

cd $xsDir
git checkout $xsBranch
make init

git apply $fpga_dir/patch/base.patch
mod_array=(${xsPatch//-/ })
for mod in ${mod_array[@]}
do
  if [ -f $fpga_dir/patch/$mod.patch ]; then
    git apply $fpga_dir/patch/$mod.patch --allow-empty
  else
    echo "$mod.patch not found at $fpga_dir/patch"
    exit 1
  fi
done

export NOOP_HOME=$(pwd)
export NEMU_HOME=$(pwd)
make verilog -j16
