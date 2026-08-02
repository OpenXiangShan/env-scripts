#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 CORE_DIR [--] [RTL_INCLUDE ...]" >&2
  exit 2
}

[[ $# -ge 1 ]] || usage
core_dir=$1
shift
if [[ ${1:-} == -- ]]; then
  shift
fi
[[ -d $core_dir ]] || {
  echo "ERROR: CORE_DIR is not a directory: $core_dir" >&2
  exit 1
}

fpga_diff_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source "$fpga_diff_dir/tools/rtl_filelist_lib.sh"
rtl_flist_parse_inputs "$PWD" "$@"

core_dir=$(realpath -e -- "$core_dir")
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

find "$core_dir" -path "$core_dir/rtl/verification" -prune -o \
  -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print | LC_ALL=C sort > "$tmp_dir/cpu_files"
: > "$tmp_dir/rtl_files"
: > "$tmp_dir/rtl_include_dirs"
if ((${#rtl_flist_files[@]})); then
  printf '%s\n' "${rtl_flist_files[@]}" > "$tmp_dir/rtl_files"
fi
if ((${#rtl_flist_include_dirs[@]})); then
  printf '%s\n' "${rtl_flist_include_dirs[@]}" > "$tmp_dir/rtl_include_dirs"
fi

awk_script="$fpga_diff_dir/core_flist.awk"
output_tcl="$fpga_diff_dir/src/tcl/cpu_files.tcl"
tmp_output="$tmp_dir/cpu_files.tcl"
awk -v var=cpu_files -v detect_simtop_dma=1 -f "$awk_script" \
  "$tmp_dir/cpu_files" > "$tmp_output"
awk -v var=rtl_include_files -f "$awk_script" \
  "$tmp_dir/rtl_files" >> "$tmp_output"
awk -v var=rtl_include_dirs -f "$awk_script" \
  "$tmp_dir/rtl_include_dirs" >> "$tmp_output"
mkdir -p "$(dirname -- "$output_tcl")"
mv -- "$tmp_output" "$output_tcl"

echo "INFO: generated $output_tcl with ${#rtl_flist_files[@]} external RTL files"
