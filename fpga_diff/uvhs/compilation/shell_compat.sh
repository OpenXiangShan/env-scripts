#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 wait-module MODULE_MAKEFILE | patch-pnr PNR_DIR | patch-signoff SIGNOFF_DIR" >&2
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

patch_signoff_worker() {
  local worker=$1
  local helper=$2
  local marker='# fpga_diff UVHS signoff compatibility'
  local temporary="${worker}.fpga-diff.$$"

  if grep -Fxq "$marker" "$worker"; then
    return
  fi
  if ! awk -v marker="$marker" -v helper="$helper" '
    $0 == "if {[file exists $dumpPath/cstr.tcl]} {" {
      print marker
      print "exec bash {" helper "} patch-signoff $dumpPath"
      inserted++
    }
    { print }
    END { if (inserted != 1) exit 1 }
  ' "$worker" > "$temporary"; then
    rm -f "$temporary"
    echo "ERROR: unsupported generated signoff worker: $worker" >&2
    exit 1
  fi
  chmod --reference="$worker" "$temporary"
  mv "$temporary" "$worker"
}

patch_signoff_constraints() {
  local signoff_dir=$1
  local udc="$signoff_dir/cstr/FPGA_filtered.udc"
  local clock_map="$signoff_dir/cstr.tcl"
  local alias_count
  local supported_alias_count
  local identity_map_count
  local mapped_count
  local mmcm_count
  local reset_count
  local multiplier_count_before
  local multiplier_count_after

  [[ -f $udc && -f $clock_map ]] || {
    echo "ERROR: signoff constraints not found under $signoff_dir" >&2
    exit 1
  }

  alias_count=$(grep -c '^create_generated_clock -name DDR_UI_CLK ' "$udc" || true)
  supported_alias_count=$(grep -cE \
    '^create_generated_clock -name DDR_UI_CLK .* -master_clock \[get_clocks mmcm_clkout0\] \[get_pins .*/ddr4ip_ddr4_user_clk\]$' \
    "$udc" || true)
  identity_map_count=$(grep -cF '{DDR_UI_CLK DDR_UI_CLK}' "$clock_map" || true)
  mapped_count=$(grep -cF '{DDR_UI_CLK mmcm_clkout0}' "$clock_map" || true)
  mmcm_count=$(grep -c '^create_generated_clock -name mmcm_clkout0 ' "$udc" || true)

  ((alias_count <= 1 && identity_map_count <= 1 && mapped_count <= 1 &&
    identity_map_count + mapped_count <= 1)) || {
    echo "ERROR: ambiguous DDR signoff clock constraints in $signoff_dir" >&2
    exit 1
  }
  ((alias_count == supported_alias_count)) || {
    echo "ERROR: unsupported DDR signoff clock alias in $udc" >&2
    exit 1
  }
  if ((alias_count == 1)); then
    ((identity_map_count == 1 && mapped_count == 0 && mmcm_count == 1)) || {
      echo "ERROR: DDR signoff clock mapping has no unique MIG MMCM clock" >&2
      exit 1
    }
    sed -i 's/{DDR_UI_CLK DDR_UI_CLK}/{DDR_UI_CLK mmcm_clkout0}/' \
      "$clock_map"
    sed -i '/^create_generated_clock -name DDR_UI_CLK .*\/ddr4ip_ddr4_user_clk]$/d' \
      "$udc"
  fi

  reset_count=$(awk '
    /^set_multicycle_path / && / -reset_path / { count++ }
    END { print count + 0 }
  ' "$udc")
  multiplier_count_before=$(grep -c ' -path_multiplier ' "$udc" || true)
  if ((reset_count > 0)); then
    sed -E -i '
      /^set_multicycle_path .* -reset_path .* [0-9]+$/ {
        s/ -reset_path//
        s/ ([0-9]+)$/ -path_multiplier \1/
      }
    ' "$udc"
  fi
  multiplier_count_after=$(grep -c ' -path_multiplier ' "$udc" || true)

  ! grep -q '^create_generated_clock -name DDR_UI_CLK ' "$udc" || {
    echo "ERROR: failed to remove DDR signoff clock alias" >&2
    exit 1
  }
  ! grep -q '^set_multicycle_path .* -reset_path ' "$udc" || {
    echo "ERROR: failed to translate Vivado reset-path constraints" >&2
    exit 1
  }
  ((multiplier_count_after == multiplier_count_before + reset_count)) || {
    echo "ERROR: incomplete multicycle-path translation in $udc" >&2
    exit 1
  }
  echo "INFO: normalized UVHS signoff constraints: DDR aliases=$alias_count, reset paths=$reset_count"
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
  local helper
  local wrapper_count=0
  local makefile_count=0
  local worker_count=0

  helper=$(realpath "$0")

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
  while IFS= read -r -d '' worker; do
    patch_signoff_worker "$worker" "$helper"
    ((worker_count += 1))
  done < <(find "$pnr_dir" -type f -name signoff_worker.tcl -print0)

  ((wrapper_count > 0)) || {
    echo "ERROR: no generated Vivado wrapper found under $pnr_dir" >&2
    exit 1
  }
  ((makefile_count > 0)) || {
    echo "ERROR: no generated PnR Makefile found under $pnr_dir" >&2
    exit 1
  }
  ((worker_count > 0)) || {
    echo "ERROR: no generated signoff worker found under $pnr_dir" >&2
    exit 1
  }
  echo "INFO: selected Bash in $wrapper_count wrappers and $makefile_count PnR Makefiles; patched $worker_count signoff workers"
}

[[ $# -eq 2 ]] || usage
case $1 in
  wait-module) wait_for_module_makefile "$2" ;;
  patch-pnr) patch_pnr_scripts "$2" ;;
  patch-signoff) patch_signoff_constraints "$2" ;;
  *) usage ;;
esac
