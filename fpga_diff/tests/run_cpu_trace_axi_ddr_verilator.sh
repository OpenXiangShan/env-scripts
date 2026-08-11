#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
obj_dir="${CPU_TRACE_TEST_OBJ_DIR:-$root_dir/tests/obj_cpu_trace_axi_ddr}"
rm -rf "$obj_dir"

mapfile -t rtl < <(find "$root_dir/src/rtl/common/cpu_trace" -maxdepth 1 -type f -name '*.sv' -print | sort)
verilator -sv --binary --timing -Wno-fatal \
  --Mdir "$obj_dir" \
  --top-module cpu_trace_axi_ddr_tb \
  "${rtl[@]}" "$root_dir/tests/cpu_trace_axi_ddr_tb.sv"

timeout 120 "$obj_dir/Vcpu_trace_axi_ddr_tb"

schema_obj_dir="${CPU_TRACE_SCHEMA_TEST_OBJ_DIR:-$root_dir/tests/obj_nutshell_commit_trace_pack}"
rm -rf "$schema_obj_dir"
verilator -sv --binary --timing -Wno-fatal \
  --Mdir "$schema_obj_dir" \
  --top-module nutshell_commit_trace_pack_tb \
  "$root_dir/src/rtl/common/cpu_trace/nutshell_commit_trace_pack.sv" \
  "$root_dir/tests/nutshell_commit_trace_pack_tb.sv"

timeout 120 "$schema_obj_dir/Vnutshell_commit_trace_pack_tb"
