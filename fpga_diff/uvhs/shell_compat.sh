#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 wait-module MODULE_MAKEFILE | patch-pnr PNR_DIR" >&2
  exit 2
}

patch_makefile() {
  local makefile=$1

  sed -E -i \
    -e 's/until[[:space:]]+sh[[:space:]]+-c/until bash -c/' \
    -e 's#(^|[[:space:]&;@])(/[^[:space:]]*/bin/uv_shell)([[:space:]])#\1bash \2\3#g' \
    -e 's#(^|[[:space:]&;@])(uv_shell)([[:space:]])#\1bash \2\3#g' \
    -e 's#(^|[[:space:]&;(@])(bash[[:space:]]+)+(/[^[:space:]]*/bin/uv_shell)#\1bash \3#g' \
    -e 's#(^|[[:space:]&;(@])(bash[[:space:]]+)+(uv_shell)#\1bash \3#g' \
    "$makefile"
}

wait_for_module_makefile() {
  local module_makefile=$1

  for ((attempt = 0; attempt < 12000; attempt++)); do
    if [[ -f $module_makefile ]]; then
      patch_makefile "$module_makefile"
      grep -Eq 'bash[[:space:]]+([^[:space:]]*/)?uv_shell[[:space:]]' \
        "$module_makefile" || {
          echo "ERROR: failed to select Bash for $module_makefile" >&2
          exit 1
        }
      echo "INFO: selected Bash for UVHS frontend workers: $module_makefile"
      return
    fi
    sleep 0.05
  done
  echo "ERROR: timed out waiting for $module_makefile" >&2
  exit 1
}

patch_pnr_scripts() {
  local pnr_dir=$1
  local wrapper_count=0
  local makefile_count=0

  [[ -d $pnr_dir ]] || {
    echo "ERROR: PnR script directory not found: $pnr_dir" >&2
    exit 1
  }
  while IFS= read -r -d '' wrapper; do
    sed -i '1s|^#!/bin/sh$|#!/bin/bash|' "$wrapper"
    head -n 1 "$wrapper" | grep -Fxq '#!/bin/bash' || {
      echo "ERROR: unsupported generated wrapper shell: $wrapper" >&2
      exit 1
    }
    chmod 755 "$wrapper"
    ((wrapper_count += 1))
  done < <(find "$pnr_dir" -type f -name uv_vivado_wrapper.sh -print0)
  while IFS= read -r -d '' makefile; do
    patch_makefile "$makefile"
    ((makefile_count += 1))
  done < <(find "$pnr_dir" -type f -name Makefile -print0)

  ((wrapper_count > 0)) || {
    echo "ERROR: no generated Vivado wrapper found under $pnr_dir" >&2
    exit 1
  }
  ((makefile_count > 0)) || {
    echo "ERROR: no generated PnR Makefile found under $pnr_dir" >&2
    exit 1
  }
  echo "INFO: selected Bash in $wrapper_count wrappers and $makefile_count PnR Makefiles"
}

[[ $# -eq 2 ]] || usage
case $1 in
  wait-module) wait_for_module_makefile "$2" ;;
  patch-pnr) patch_pnr_scripts "$2" ;;
  *) usage ;;
esac
