#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
vivado -mode tcl -source "$script_dir/jtag_write_ddr.tcl" \
  -tclargs ./microbench-xs-no-uart.txt

rm -f ./*.jou ./*.log
