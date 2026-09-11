#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
obj_dir="${TMPDIR:-/tmp}/uvhs_gbus_c2h_fifo_obj_${USER}"
rm -rf "$obj_dir"
verilator --binary --timing -Wall -Wno-fatal \
  --top-module uvhs_gbus_c2h_fifo_tb \
  --Mdir "$obj_dir" \
  "$root/src/rtl/common/uvhs_gbus_c2h_fifo.sv" \
  "$root/src/rtl/common/uvhs_axis_async_fifo.sv" \
  "$root/tests/uvhs_gbus_c2h_fifo_tb.sv"
"$obj_dir/Vuvhs_gbus_c2h_fifo_tb"
