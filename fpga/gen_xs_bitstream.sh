
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path)

xsBranch=$1
bsDir=$2
xsDir=$bsDir/xs

cp -r /nfs/home/share/fpga/vivado/scripts_v2 $bsDir
git clone https://github.com/OpenXiangShan/XiangShan.git -b $xsBranch $bsDir/xs

cd $xsDir
make init
git apply /nfs/home/share/zzf/fpga.patch
export NOOP_HOME=$(pwd)
export NEMU_HOME=$(pwd)
make verilog -j17

cd $bsDir
make update_core_flist CORE_DIR=$(pwd)/xs/build
make nanhu CORE_DIR=$(pwd)/xs/build
make bitstream CORE_DIR=$(pwd)/xs/build
