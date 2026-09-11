#!/usr/bin/env bash
#
# Pre-build RTL check for the UVHS fpga_diff wrapper.
#
# Catches syntax errors and unresolved identifiers in a few seconds so a typo
# does not cost a frontend run.  Passing sibling modules on the command line
# (rather than letting Verilator black-box them) also gets their port lists
# checked for width and existence.
#
# It does NOT catch everything uvsyn does.  Verilator accepts a constant
# expression connected to an *output* port, which uvsyn rejects with
# "[VERI-1180] FATAL: constant is not allowed here"; that class of error is only
# found by the real frontend.  The frontend reaches elaboration in well under a
# minute once the Vivado IP is cached, so a first `make uvhs_frontend` run is
# the authoritative gate before starting the multi-hour backend.
#
# MODMISSING errors are expected: the UVHS protected IPs (generalBD,
# uvw_general_bus), the Xilinx IP stubs, and the generated SimTop wrapper are
# supplied by the vendor flow or the release RTL.  Anything else is a failure.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
rtl="$root/src/rtl/common"
if [[ -n ${UVHS_RELEASE_GENERATED_SRC:-} ]]; then
  incdir=$UVHS_RELEASE_GENERATED_SRC
else
  # Fall back to any checked-out generated-src that supplies DifftestMacros.svh.
  incdir=$(ls -d /nfs/home/fengkehan/project/minjie-playground/XiangShan-uvhs-trace-build/build/generated-src \
    /nfs/home/fengkehan/project/minjie-playground/difftest/build/generated-src 2>/dev/null | head -1 || true)
fi
[[ -n $incdir ]] || { echo "ERROR: no generated-src with DifftestMacros.svh found; set UVHS_RELEASE_GENERATED_SRC" >&2; exit 2; }

run_lint() {
  local hostif=$1
  shift
  local defines=(
    "+define+DATA_VERSION=0" "+define+UVHS" "+define+XIANGSHAN_FPGA" "+define+SYNTHESIS"
    "+define+CONFIG_DIFFTEST_HOSTIF_${hostif}"
  )
  [[ $hostif == GBUS ]] && defines+=("+define+UVHS_FUNCTIONAL_DDR_REMOTE_LINK")

  local out
  out=$(verilator --lint-only \
    -Wno-lint -Wno-style -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN \
    -Wno-PINMISSING -Wno-PINCONNECTEMPTY -Wno-SYNCASYNCNET -Wno-WIDTH \
    -Wno-CASEINCOMPLETE -Wno-EOFNEWLINE \
    "+incdir+$incdir" "+incdir+$rtl" "${defines[@]}" "$@" 2>&1 || true)
  echo "$out" | grep -E '^%Error' | grep -vE 'MODMISSING|Exiting due to' || true
}

# Sibling modules are named explicitly so their port lists are checked.
siblings=(
  "$rtl/uvhs_axi_3master_arbiter.sv"
  "$rtl/uvhs_axi_2master_arbiter.sv"
  "$rtl/uvhs_axi3_to_axi4_adapter.sv"
  "$rtl/uvhs_axi_async_bridge.sv"
  "$rtl/uvhs_axi64_to_axi256.sv"
  "$rtl/uvhs_axi_remote_link.sv"
  "$rtl/uvhs_axis_async_fifo.sv"
  "$rtl/uvhs_async_fifo.sv"
  "$rtl/uvhs_async_status_sync.sv"
  "$rtl/uvhs_axilite_cdc_bridge.sv"
  "$rtl/uvhs_gbus_c2h_fifo.sv"
  "$rtl/uvhs_generalbd_axilite_bridge.sv"
)

status=0
for hostif in XDMA GBUS; do
  echo "== lint core_def_xdma.sv (DIFFTEST_HOSTIF=$hostif)"
  errors=$(run_lint "$hostif" "$rtl/core_def_xdma.sv" "${siblings[@]}")
  if [[ -n $errors ]]; then
    echo "$errors"
    status=1
  else
    echo "   OK (only expected black-box MODMISSING entries)"
  fi
done
exit $status
