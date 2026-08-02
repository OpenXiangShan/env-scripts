#!/usr/bin/env bash
set -euo pipefail

: "${UV_ROOT:?UV_ROOT is not set}"

runtime_library_path=${UVHS_RUNTIME_LIB_DIR:-}
if [[ -n ${UMI_LD_LIBRARY_PATH:-} ]]; then
  runtime_library_path=${runtime_library_path:+$runtime_library_path:}$UMI_LD_LIBRARY_PATH
fi
if [[ -n $runtime_library_path ]]; then
  export LD_LIBRARY_PATH=$runtime_library_path
fi

exec "$UV_ROOT/bin/uv_shell_exec" "$@"
