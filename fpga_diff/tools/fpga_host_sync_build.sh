#!/usr/bin/env bash
# HOST_BUILD_AUTHORIZE=YES permits an isolated host upload/build, never board use.
# Required: RELEASE_DIR, FPGA_HOST_DONOR_DIR (or legacy FPGA_HOST_DIR).
# Generated ABI inputs come only from RELEASE_DIR/build/generated-src.
# The helper records the allocated directory and build proof in OUT_DIR.
set -euo pipefail
exec python3 "$(dirname "$(readlink -f "$0")")/gbus_supervisor.py" build "$@"
