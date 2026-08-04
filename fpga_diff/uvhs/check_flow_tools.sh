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
  uvhs/hejian_pcie_x4_env.sh uvhs/frontend_run.tcl uvhs/backend_run.tcl \
  uvhs/assemble_uvhs.tcl uvhs/assign_pin_nutshell_f2.tcl uvhs/async_clocks.tcl \
  uvhs/probe_template.tcl uvhs/partition_capture_ddr_f3.tcl \
  uvhs/uvhs_preflight_status.sh uvhs/uvhs_tagged_runtime.sh \
  uvhs/uvhs_queue_uhd_capture.sh \
  uvhs/tools/build/patch_nutshell_cdc.sh \
  user_script/hw_run_download.tcl user_script/hw_capture_uhd.tcl \
  user_script/uhd_c2h.ini \
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
require_text uvhs/uvhs_queue_uhd_capture.sh 'UVHS_RUN_TAG:?set the exact active UVHS_RUN_TAG'
require_text uvhs/probe_template.tcl 'trigger_net -add -group $group -clock $clock -signal $signals'
require_text uvhs/partition_capture_ddr_f3.tcl 'get_cells core_def/U_UVHS_UVW_AXI4_TO_DDR4'
require_text user_script/uhd_c2h.ini 'difftest_to_host_axis_tvalid_io = 1'
require_text uvhs/Makefile 'UVHS_PROBE_FILE ?= $(ROOT_DIR)/uvhs/probe_template.tcl'
require_text uvhs/Makefile 'UVHS_ENABLE_PROBE_NET ?= 0'
require_text uvhs/Makefile 'uvhs_hejian_pcie_x4_nutshell_probe_all: UVHS_FPGA_COUNT = 2'
require_text uvhs/Makefile 'uvhs_hejian_pcie_x4_nutshell_probe_all: UVHS_KEEP_FPGAS = b0.f2 b0.f3'
require_text uvhs/Makefile 'uvhs_hejian_pcie_x4_nutshell_probe_all: UVHS_PARTITION_FILE = $(ROOT_DIR)/uvhs/partition_capture_ddr_f3.tcl'
require_text uvhs/Makefile 'uvhs_hejian_pcie_x4_nutshell_probe_all: UVHS_LOCALIZE_CLOCKS = SOC_GATED_CLK'
require_text uvhs/frontend_run.tcl 'enabled UVHS probe file is missing or empty'

if git -C "$root_dir" grep -En 'UVHS_UHD_CAPTURE_DDR|pddr4dme_f2_uhd_inst' -- \
  uvhs/Makefile uvhs/assemble_uvhs.tcl; then
  fail "unverified UHD capture daughter-card overlay remains"
fi

if command -v tclsh >/dev/null 2>&1; then
  if ! UVHS_ENABLE_PROBE_NET=1 UVHS_ENABLE_TRIGGER_NET=1 \
    tclsh /dev/stdin "$root_dir/uvhs/probe_template.tcl" <<'TCL'
set probe_calls {}
set trigger_calls {}
proc probe_net {args} { lappend ::probe_calls $args }
proc trigger_net {args} { lappend ::trigger_calls $args }
source [lindex $argv 0]
if {[llength $probe_calls] != 15 || [llength $trigger_calls] != 2} {
    error "standard probe template expected 15 probes and 2 trigger groups; got [llength $probe_calls] and [llength $trigger_calls]"
}
TCL
  then
    fail "standard probe/trigger template behavior"
  fi
fi
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
