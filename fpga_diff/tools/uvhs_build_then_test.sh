#!/usr/bin/env bash
#
# Build a UVHS bitstream and then hand it to the board-test supervisor.
#
# The frontend and backend are run as two steps on purpose: an elaboration or
# partition error shows up in minutes, and the supervisor is only started once
# the runtime database is actually committed.  Everything after that -- waiting
# for the board, programming it, running fpga-host, collecting logs -- is the
# supervisor's job, so this script can be left running unattended.
#
# Usage:
#   PRJ=fpga_uvhs_kmh-... TAG=... CORE_DIR=... IP_DONOR=... \
#   FPGA_HOST_KEY=... FPGA_HOST_DIR=... \
#     env-scripts/fpga_diff/tools/uvhs_build_then_test.sh
#
# Required: PRJ, TAG, CORE_DIR, IP_DONOR, FPGA_HOST_KEY, FPGA_HOST_DIR.
# Set BUILD_ONLY=1 to stop after the backend.
set -uo pipefail

PRJ=${PRJ:?PRJ is required}
TAG=${TAG:?TAG is required}
CORE_DIR=${CORE_DIR:?CORE_DIR is required (release build dir)}
# The prepared IP (generalBus, DDR, AXI bridges) is reused from a previous
# project directory; it only needs regenerating when the vendor IP changes.
IP_DONOR=${IP_DONOR:?IP_DONOR is required (previous project dir with rtl/soc/*.dcp)}
FPGA_HOST_DIR=${FPGA_HOST_DIR:?FPGA_HOST_DIR is required}
FPGA_HOST=${FPGA_HOST:?FPGA_HOST is required}
FPGA_HOST_KEY=${FPGA_HOST_KEY:?FPGA_HOST_KEY is required}
BUILD_ONLY=${BUILD_ONLY:-0}

ROOT=${ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}
FPGA_DIFF=$ROOT/env-scripts/fpga_diff
LOG_DIR=${LOG_DIR:-$ROOT/build_logs/uvhs_build_$TAG}
mkdir -p "$LOG_DIR"

export UV_ROOT=${UV_ROOT:-/nfs/tools/UVHS}
export UV_XILINX_VIVADO=${UV_XILINX_VIVADO:-/nfs/tools/xilinx/2024.2/Vivado/2024.2}
export UV_LICENSE=${UV_LICENSE:-8273@172.18.60.1}
CPU=${CPU:-kmh}
DIFFTEST_HOSTIF=${DIFFTEST_HOSTIF:-GBUS}
UVHS_FUNCTIONAL_DDR_REMOTE_LINK=${UVHS_FUNCTIONAL_DDR_REMOTE_LINK:-1}
VIVADO_JOBS=${VIVADO_JOBS:-4}

MAKE_ARGS=(
  FPGA_BACKEND=uvhs CPU="$CPU" DIFFTEST_HOSTIF="$DIFFTEST_HOSTIF"
  UVHS_FUNCTIONAL_DDR_REMOTE_LINK="$UVHS_FUNCTIONAL_DDR_REMOTE_LINK"
  UVHS_GBUS_C2H_DMA="${UVHS_GBUS_C2H_DMA:-0}"
  PRJ_NAME="$PRJ" CORE_DIR="$CORE_DIR"
  UVHS_TEMPLATE_DIR="$IP_DONOR" UVHS_UVW_AXI4_TO_DDR4_SRC="$IP_DONOR"
  VIVADO_JOBS="$VIVADO_JOBS"
)

log() { printf '[%s] [build] %s\n' "$(date '+%F %T')" "$*"; }

cd "$FPGA_DIFF"
log "frontend: $PRJ"
make uvhs_frontend "${MAKE_ARGS[@]}" > "$LOG_DIR/frontend.log" 2>&1
rc=$?
if [[ $rc -ne 0 ]] || ! grep -q UVHS_FRONTEND_SUCCESS "$FPGA_DIFF/$PRJ/frontend_run.log" 2>/dev/null; then
  log "FAIL: frontend rc=$rc; see $LOG_DIR/frontend.log and $FPGA_DIFF/$PRJ/frontend_run.log"
  exit 1
fi
log "frontend OK"

log "backend: $PRJ (this is the long step)"
make uvhs_backend "${MAKE_ARGS[@]}" > "$LOG_DIR/backend.log" 2>&1
rc=$?
if [[ $rc -ne 0 ]] || ! grep -q UVHS_BACKEND_SUCCESS "$FPGA_DIFF/$PRJ/backend_run.log" 2>/dev/null; then
  log "FAIL: backend rc=$rc; see $LOG_DIR/backend.log and $FPGA_DIFF/$PRJ/backend_run.log"
  exit 1
fi
log "backend OK (runtime database committed)"

if (( BUILD_ONLY )); then
  log "BUILD_ONLY=1: stopping before the board test"
  exit 0
fi

if [[ -f "$FPGA_DIFF/$PRJ/.external-board-supervisor" ]]; then
  log "board testing is assigned to the separately tracked supervisor"
  exit 0
fi

log "handing off to the board-test supervisor"
exec env TAG="$TAG" PRJ="$PRJ" \
  FPGA_HOST="$FPGA_HOST" FPGA_HOST_KEY="$FPGA_HOST_KEY" FPGA_HOST_DIR="$FPGA_HOST_DIR" \
  LOGICAL_PROJECT="${LOGICAL_PROJECT:-minjie_xsmini_gbus_pr954}" \
  UART_DEVICE="${UART_DEVICE:-/dev/ttyUSB0}" UART_BAUD="${UART_BAUD:-115200}" \
  "$FPGA_DIFF/tools/board_test_supervisor.sh"
