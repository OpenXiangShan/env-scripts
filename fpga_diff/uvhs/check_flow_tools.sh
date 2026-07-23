#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root_dir="$(cd "$script_dir/.." && pwd)"
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

require_file() {
  [ -f "$root_dir/$1" ] || fail "missing required flow file: $1"
}

require_text() {
  local path="$1"
  local text="$2"
  grep -Fq "$text" "$root_dir/$path" || fail "$path does not contain required text: $text"
}

for path in \
  Makefile README.md \
  uvhs/Makefile uvhs/flow.md uvhs/setenv.sh uvhs/setenv.local.example.sh \
  uvhs/hejian_pcie_x4_env.sh uvhs/frontend_run_uvhs.tcl uvhs/backend_run.tcl \
  uvhs/assemble_uvhs.tcl uvhs/assign_pin_nutshell_f2.tcl uvhs/async_clocks.tcl \
  uvhs/uvhs_preflight_status.sh uvhs/uvhs_tagged_runtime.sh \
  uvhs/tools/build/patch_nutshell_cdc.sh \
  user_script/hw_run_download.tcl \
  tools/report_post_route_cdc.tcl tools/report_pcie_route_evidence.tcl \
  src/rtl/common/core_def_xdma.sv src/rtl/common/uvhs_axi64_to_axi256.sv \
  src/rtl/common/uvhs_axilite_cdc_bridge.sv src/rtl/common/uvhs_blackbox_stubs.v \
  src/tcl/common/AXI_bridge.tcl; do
  require_file "$path"
done

echo "## Shell syntax"
while IFS= read -r -d '' path; do
  bash -n "$root_dir/$path" || fail "shell syntax: $path"
done < <(git -C "$root_dir" ls-files -z 'uvhs/**/*.sh' | sort -z)

echo "## Python syntax"
while IFS= read -r -d '' path; do
  if ! python3 - "$root_dir/$path" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
compile(path.read_bytes(), str(path), "exec")
PY
  then
    fail "python syntax: $path"
  fi
done < <(git -C "$root_dir" ls-files -z 'uvhs/**/*.py' | sort -z)

echo "## Tcl completeness"
if command -v tclsh >/dev/null 2>&1; then
  while IFS= read -r -d '' path; do
    if ! tclsh /dev/stdin "$root_dir/$path" <<'TCL'
set path [lindex $argv 0]
set fh [open $path r]
set data [read $fh]
close $fh
if {![info complete $data]} {
    puts stderr "incomplete Tcl input: $path"
    exit 1
}
TCL
    then
      fail "Tcl completeness: $path"
    fi
  done < <(git -C "$root_dir" ls-files -z \
    'uvhs/**/*.tcl' 'tools/**/*.tcl' 'user_script/**/*.tcl' | sort -z)
else
  fail "tclsh is required for Tcl completeness checks"
fi

echo "## Safety defaults"
require_text uvhs/uvhs_tagged_runtime.sh 'UVHS_RUN_TAG:?set a unique UVHS_RUN_TAG'
require_text src/rtl/common/uvhs_axi_to_mem_array.sv '`define UVHS_CPU_DDR_AXI_DATA_WIDTH 64'
require_text src/rtl/common/uvhs_axi_to_mem_array.sv '`define UVHS_CPU_DDR_AXI_DATA_WIDTH 256'
require_text src/rtl/common/uvhs_axi_to_mem_array.sv '.UVW_USE_DATA_WIDTH({4{UVW_AXI_DATA_WIDTH}})'

if git -C "$root_dir" grep -En '/home/(user01|data/test/(fengkehan|codex))' -- uvhs; then
  fail "personal or historical runtime path remains in UVHS tools"
fi
if git -C "$root_dir" grep -En '/sys/bus/pci/(devices/.*/remove|devices/.*/reset|drivers/.*/unbind)' -- uvhs; then
  fail "forbidden PCIe remove/reset/unbind operation found"
fi

if [ "$failures" -ne 0 ]; then
  echo "FAIL: $failures UVHS flow tool check(s) failed" >&2
  exit 1
fi
echo "OK: UVHS flow tools are complete and statically valid"
