#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path)
set -v

fpga_dir=/nfs/home/zhangzifei/fpga/fpga-gen

xsBranch=$1
bsTag=$2
bsDir=$fpga_dir/bitgen-$bsTag
xsDir=$fpga_dir/xs-$bsTag

echo "generating verilog..."
zsh gen_xiangshan.sh $xsBranch $xsDir

echo "generating bitstream..."
zsh gen_bitstream.sh $bsDir $xsDir/build

echo "keep watching bitstream log"
zsh watch_runme.sh $bsDir

echo "cp bitstream to $bsTag"
zsh cp_bitstream.sh $bsDir $bsTag

echo "send email"
python3 send_email_standalone.py "bitstream generated $bsTag" "bsDir: $bsDir"
