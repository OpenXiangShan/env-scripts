#!/usr/bin/env bash
set -euo pipefail

: "${UV_ROOT:?UV_ROOT is not set}"
: "${UVHS_RUNTIME_LIB_DIR:?UVHS_RUNTIME_LIB_DIR is not set}"

find_library() {
  ldconfig -p | awk -v soname="$1" '$1 == soname && !found { print $NF; found = 1 }'
}

mkdir -p "$UVHS_RUNTIME_LIB_DIR"

ensure_link() {
  local source=$1 destination=$2
  if [[ -e $destination ]]; then
    [[ -r $destination ]] || {
      echo "ERROR: unreadable runtime link: $destination" >&2
      return 1
    }
    [[ "$(readlink -f "$destination")" == "$(readlink -f "$source")" ]] || {
      echo "ERROR: runtime link points to the wrong library: $destination" >&2
      return 1
    }
    return 0
  fi
  ln -s "$source" "$destination" 2>/dev/null || [[ -e $destination ]]
  [[ -r $destination ]] && [[ "$(readlink -f "$destination")" == "$(readlink -f "$source")" ]]
}

ffi=$(find_library libffi.so.6)
if [[ -z $ffi ]]; then
  ffi=$(find_library libffi.so.8)
fi
[[ -n $ffi ]] || {
  echo "ERROR: libffi.so.6 or libffi.so.8 is required by uv_shell_exec" >&2
  exit 1
}
ensure_link "$ffi" "$UVHS_RUNTIME_LIB_DIR/libffi.so.6"

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
    ensure_link "$pcre" "$UVHS_RUNTIME_LIB_DIR/libpcre.so.1"
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

if [[ -n ${UVHS_COMPAT_BIN:-} ]]; then
  export PATH=$UVHS_COMPAT_BIN:$PATH
fi

executable="$UV_ROOT/bin/uv_shell_exec"
case ${0##*/} in
  python|python3) executable="$UV_ROOT/lib/venv3.8/bin/${0##*/}" ;;
esac
exec "$executable" "$@"
