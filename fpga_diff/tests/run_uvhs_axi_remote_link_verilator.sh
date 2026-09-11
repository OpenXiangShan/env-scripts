#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
obj_dir="${TMPDIR:-/tmp}/uvhs_axi_remote_link_obj_${USER}"
rm -rf "$obj_dir"
verilator --binary --timing -Wall -Wno-fatal \
  --top-module uvhs_axi_remote_link_tb \
  --Mdir "$obj_dir" \
  "$root/src/rtl/common/cpu_trace/uvhs_axi_remote_link.sv" \
  "$root/tests/uvhs_axi_remote_link_tb.sv"
"$obj_dir/Vuvhs_axi_remote_link_tb"
