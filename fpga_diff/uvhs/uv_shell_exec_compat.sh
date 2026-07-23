#!/usr/bin/env bash
set -euo pipefail

: "${UV_ROOT:?UV_ROOT is required}"
: "${UVHS_PCRE_COMPAT_DIR:?UVHS_PCRE_COMPAT_DIR is required}"

pcre="$UVHS_PCRE_COMPAT_DIR/libpcre.so.1"
test -s "$pcre"

compat_path="$UVHS_PCRE_COMPAT_DIR"
if [ -n "${UVHS_LIBFFI_COMPAT_DIR:-}" ]; then
  test -s "$UVHS_LIBFFI_COMPAT_DIR/libffi.so.6"
  compat_path="$compat_path:$UVHS_LIBFFI_COMPAT_DIR"
fi

# uv_common intentionally clears LD_LIBRARY_PATH before launching the selected
# executable. Restore only the caller-selected compatibility directory here,
# then execute the UVHS binary from the active UV_ROOT.
export LD_LIBRARY_PATH="$compat_path${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$UV_ROOT/bin/uv_shell_exec" "$@"
