#!/usr/bin/env bash
set -euo pipefail
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
obj_dir="${UVHS_GBUS_ROUTER_TEST_OBJ_DIR:-${TMPDIR:-/tmp}/uvhs_gbus_axi_read_router_$$}"
verilator -sv --binary --timing -Wno-fatal --Mdir "$obj_dir" \
  --top-module uvhs_gbus_axi_read_router_tb \
  "$root_dir/src/rtl/common/uvhs_gbus_axi_read_router.sv" \
  "$root_dir/tests/uvhs_gbus_axi_read_router_tb.sv"
timeout 120 "$obj_dir/Vuvhs_gbus_axi_read_router_tb"
