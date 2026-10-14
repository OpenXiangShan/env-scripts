#!/usr/bin/env bash
# BOARD_TEST_AUTHORIZE=YES permits upload/programming; --status is read-only.
set -euo pipefail
exec python3 "$(dirname "$(readlink -f "$0")")/gbus_supervisor.py" supervise "$@"
