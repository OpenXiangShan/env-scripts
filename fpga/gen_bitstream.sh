
# Usage: zsh/bash gen_bitstream.sh whichxsdir(abs path) whichdir(abs path)

xsDir=$1
bsDir=$2

cp -r /nfs/home/share/fpga/vivado/scripts_v2 $bsDir
cd $bsDir
cp -r $xsDir/build $(pwd)
make update_core_flist CORE_DIR=$(pwd)/build
make nanhu CORE_DIR=$(pwd)/build
make bitstream CORE_DIR=$(pwd)/build
