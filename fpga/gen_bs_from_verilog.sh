#! /usr/bin/env zsh
# Usage: zsh/bash gen_xs_bitstream.sh whichbranch whichdir(abs path)
# from chisel. User should prepare all-ready chisel
set -v

fpga_dir=/nfs/home/share/fpga/fpga-gen

verilogDir=$1
bsTag=$2
bsDir=$fpga_dir/bitgen-$bsTag

echo "generating bitstream..."
zsh gen_bitstream.sh $bsDir $verilogDir
if [ $? -ne 0 ]; then
    echo "gen_bitstream.sh failed"
    python3 send_email_standalone.py "bitstream generated failed at gen bitstream" "failed"
    exit 1
fi

echo "keep watching bitstream log"
zsh watch_runme.sh $bsDir
if [ $? -ne 0 ]; then
    echo "watch_runme.sh failed"
    python3 send_email_standalone.py "bitstream generated failed at watch runme" "failed"
    exit 1
fi

echo "cp bitstream to $bsTag"
zsh cp_bitstream.sh $bsDir $bsTag
if [ $? -ne 0 ]; then
    echo "cp_bitstream.sh failed"
    python3 send_email_standalone.py "bitstream generated failed at cp bitstream" "failed"
    exit 1
fi

echo "send email"
python3 send_email_standalone.py "bitstream generated $bsTag" "bsDir: $bsDir"
