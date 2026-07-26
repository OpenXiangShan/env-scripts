#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"

required=(
  Makefile
  uvhs/uvhs.mk
  uvhs/README.md
  uvhs/frontend_run.tcl
  uvhs/backend_run.tcl
  uvhs/assemble_uvhs.tcl
  uvhs/assign_pin_u22_f2.tcl
  uvhs/async_clocks.tcl
  uvhs/timing_common.tcl
  uvhs/export_vivado_ip.tcl
  uvhs/check_modules.sh
  uvhs/filelist.awk
  uvhs/make_compat/make
  uvhs/make_compat/csh
  uvhs/patch_uvsyn_shell.sh
  user_script/hw_run_download.tcl
  src/rtl/common/uvhs_axi64_to_axi256.sv
  src/rtl/common/uvhs_ddr4_wrapper.sv
  src/tcl/common/AXI_bridge.tcl
  src/tcl/common/xdma_ep.tcl
)

for path in "${required[@]}"; do
  test -f "$root_dir/$path" || {
    echo "ERROR: missing required UVHS flow file: $path" >&2
    exit 1
  }
done

bash -n "$root_dir/uvhs/check_modules.sh"
bash -n "$root_dir/uvhs/check_flow_tools.sh"
bash -n "$root_dir/uvhs/make_compat/make"
bash -n "$root_dir/uvhs/make_compat/csh"
bash -n "$root_dir/uvhs/patch_uvsyn_shell.sh"

if command -v tclsh >/dev/null 2>&1; then
  while IFS= read -r -d '' path; do
    tclsh /dev/stdin "$path" <<'TCL'
set fh [open [lindex $argv 0] r]
set source [read $fh]
close $fh
if {![info complete $source]} { exit 1 }
TCL
  done < <(find "$root_dir/uvhs" "$root_dir/user_script" -type f -name '*.tcl' -print0)
fi

if grep -R -n -E '/home/|setenv\.local|NUTSHELL_LEGACY_DIFFTEST_HOSTIF|UVHS_XDMA_ST_LOOPBACK_SMOKE|UVHS_CPU_LIVENESS_GBD' \
  --include='*.mk' --include='*.sh' --include='*.tcl' --include='*.sv' \
  --exclude='check_flow_tools.sh' "$root_dir/uvhs" "$root_dir/user_script"; then
  echo "ERROR: removed local paths or legacy/debug controls remain in UVHS sources" >&2
  exit 1
fi

echo "OK: UVHS flow source checks passed"
