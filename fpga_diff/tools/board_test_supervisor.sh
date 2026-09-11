#!/usr/bin/env bash
# Explicit authorization is required even when called by a background build.
# BOARD_TEST_AUTHORIZE=YES permits upload/programming; --status is read-only.
# FPGA_HOST_DIR is now a donor only. A unique sibling is created for each run.
set -euo pipefail
exec python3 "$(dirname "$(readlink -f "$0")")/gbus_supervisor.py" supervise "$@"
