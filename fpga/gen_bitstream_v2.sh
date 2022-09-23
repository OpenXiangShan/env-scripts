# Usage: zsh ../xs_bs_cp.sh tag
# NOTE: should execute this scripts at XiangShan

bsTag=$1

make verilog -j17 NOOP_HOME=$(pwd) NEMU_HOME=$(pwd)

cp -r /nfs/home/share/fpga/vivado/scripts_v2 ../bitgen-$bsTag
cp -r $(pwd)/build ../bitgen-$bsTag/

cd ../bitgen-$bsTag
make update_core_flist CORE_DIR=$(pwd)/build
make nanhu CORE_DIR=$(pwd)/build
make bitstream CORE_DIR=$(pwd)/build
