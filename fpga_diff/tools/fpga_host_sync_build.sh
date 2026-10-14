#!/usr/bin/env bash
# HOST_BUILD_AUTHORIZE=YES permits an isolated host upload/build, never board use.
set -euo pipefail
exec python3 "$(dirname "$(readlink -f "$0")")/gbus_supervisor.py" build "$@"
