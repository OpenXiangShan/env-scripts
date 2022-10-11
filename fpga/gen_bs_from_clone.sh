#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path) whichpatch
set -v

fpga_dir=/nfs/home/share/fpga/fpga-gen

if [ $# -ne 3 ]; then
    echo "Usage: $0 whichbranch whichdir(abs path) whichpatch"
    echo "patch path : $fpga_dir/patch"
    echo "$(ls $fpga_dir/patch) : patch"
    exit 1
fi

xsBranch=$1
bsTag=$2
bsDir=$fpga_dir/bitgen-$bsTag
xsDir=$fpga_dir/xs-$bsTag
xsPatch=$3
    

echo "generating verilog..."
zsh gen_xiangshan.sh $xsBranch $xsDir $xsPatch

if [ $? -ne 0 ]; then
    echo "gen_xiangshan.sh failed"
    exit 1
fi

echo "generating bitstream..."
zsh gen_bitstream.sh $bsDir $xsDir/build

echo "keep watching bitstream log"
zsh watch_runme.sh $bsDir

echo "cp bitstream to $bsTag"
zsh cp_bitstream.sh $bsDir $bsTag

echo "send email"
python3 send_email_standalone.py "bitstream generated $bsTag" "bsDir: $bsDir"
