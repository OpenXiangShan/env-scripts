#!/usr/bin/env bash
set -euo pipefail

: "${UV_ROOT:?UV_ROOT is not set}"
: "${UVHS_RUNTIME_LIB_DIR:?UVHS_RUNTIME_LIB_DIR is not set}"

find_library() {
  ldconfig -p | awk -v soname="$1" '$1 == soname && !found { print $NF; found = 1 }'
}

mkdir -p "$UVHS_RUNTIME_LIB_DIR"

ffi=$(find_library libffi.so.6)
if [[ -z $ffi ]]; then
  ffi=$(find_library libffi.so.8)
fi
[[ -n $ffi ]] || {
  echo "ERROR: libffi.so.6 or libffi.so.8 is required by uv_shell_exec" >&2
  exit 1
}
ln -sfn "$ffi" "$UVHS_RUNTIME_LIB_DIR/libffi.so.6"

if ldd "$UV_ROOT/bin/uv_shell_exec" 2>/dev/null | grep -q 'libpcre[.]so[.]1 => not found'; then
  pcre=
  for candidate in \
    "$UVHS_RUNTIME_LIB_DIR/libpcre.so.1" \
    "$UV_ROOT/shlib_install/libpcre.so.1" \
    "$UV_ROOT/shlib/libpcre.so.1" \
    "$(find_library libpcre.so.3)"; do
    if [[ -n $candidate && -f $candidate ]]; then
      pcre=$candidate
      break
    fi
  done
  [[ -n $pcre ]] || {
    echo "ERROR: uv_shell_exec needs PCRE1 (libpcre.so.1 or libpcre.so.3)" >&2
    exit 1
  }
  if [[ $pcre != "$UVHS_RUNTIME_LIB_DIR/libpcre.so.1" ]]; then
    ln -sfn "$pcre" "$UVHS_RUNTIME_LIB_DIR/libpcre.so.1"
  fi
fi

runtime_library_path=$UVHS_RUNTIME_LIB_DIR
if [[ -n ${UMI_LD_LIBRARY_PATH:-} ]]; then
  runtime_library_path=$runtime_library_path:$UMI_LD_LIBRARY_PATH
fi
if [[ -n ${LD_LIBRARY_PATH:-} ]]; then
  runtime_library_path=$runtime_library_path:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH=$runtime_library_path

exec "$UV_ROOT/bin/uv_shell_exec" "$@"
