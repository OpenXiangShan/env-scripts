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
  uvhs/vivado_pre_opt.tcl
  uvhs/export_vivado_ip.tcl
  uvhs/check_modules.sh
  uvhs/shell_compat.sh
  uvhs/enqueue_runtime_command.sh
  uvhs/runtime_session.sh
  uvhs/uv_shell_exec_compat.sh
  uvhs/hw_run_download.tcl
  uvhs/runtime_control.tcl
  uvhs/runtime_command.tcl
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
bash -n "$root_dir/uvhs/shell_compat.sh"
bash -n "$root_dir/uvhs/enqueue_runtime_command.sh"
bash -n "$root_dir/uvhs/runtime_session.sh"
bash -n "$root_dir/uvhs/uv_shell_exec_compat.sh"

if command -v tclsh >/dev/null 2>&1; then
  while IFS= read -r -d '' path; do
    tclsh /dev/stdin "$path" <<'TCL'
set fh [open [lindex $argv 0] r]
set source [read $fh]
close $fh
if {![info complete $source]} { exit 1 }
TCL
  done < <(find "$root_dir/uvhs" -type f -name '*.tcl' -print0)
fi

if grep -R -n -E '/home/|setenv\.local|NUTSHELL_LEGACY_DIFFTEST_HOSTIF|UVHS_XDMA_ST_LOOPBACK_SMOKE|UVHS_CPU_LIVENESS_GBD' \
  --include='*.mk' --include='*.sh' --include='*.tcl' --include='*.sv' \
  --exclude='check_flow_tools.sh' "$root_dir/uvhs"; then
  echo "ERROR: removed local paths or legacy/debug controls remain in UVHS sources" >&2
  exit 1
fi

echo "OK: UVHS flow source checks passed"
