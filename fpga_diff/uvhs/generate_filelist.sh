#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 CORE_BUILD_DIR UVHS_WORK_DIR CPU OUTPUT [--] [RTL_INCLUDE ...]" >&2
  exit 2
}

[[ $# -ge 4 ]] || usage
core_dir=$(realpath -e -- "$1")
work_dir=$(realpath -e -- "$2")
cpu=$3
output=$4
shift 4
if [[ ${1:-} == -- ]]; then
  shift
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fpga_diff_dir=$(cd -- "$script_dir/.." && pwd)
source "$fpga_diff_dir/tools/rtl_filelist_lib.sh"
rtl_flist_parse_inputs "$PWD" "$@"

core_rtl_dir="$core_dir/rtl"
core_generated_dir="$core_dir/generated-src"
[[ -d $core_rtl_dir ]] || rtl_flist_fail "FPGA release RTL not found: $core_rtl_dir"

mkdir -p "$(dirname -- "$output")"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
tmp_output="$tmp_dir/filelist.f"

{
  printf '+define+SYNTHESIS\n+define+XIANGSHAN_FPGA\n+define+UVHS\n'
  printf '+define+DDR4_16G_X8\n+define+DQ64\n+define+DDR4_2400\n'
  printf '+define+DQ=64\n+define+MICRON_DDR\n+define+DDR4_16Gbx8\n'
  printf '+define+DDR4\n+define+SRAM_SYN\n+define+DATA_VERSION=0\n'
  if [[ $cpu == nutshell ]]; then
    printf '+define+CPU_NUTSHELL\n'
  fi
  if [[ $cpu == kmh ]] &&
    grep -Eq '^[[:space:]]*(input|output)[[:space:]].*dma_awready' "$core_rtl_dir/SimTop.sv"; then
    printf '+define+CONFIG_SIMTOP_HAS_DMA\n'
  fi

  printf '+incdir+%s\n' "$core_dir" "$core_rtl_dir"
  if [[ -d $core_generated_dir ]]; then
    printf '+incdir+%s\n' "$core_generated_dir"
  fi
  printf '+incdir+%s/src/rtl/common\n' "$fpga_diff_dir"

  find "$fpga_diff_dir/src/rtl/common" -type f \
    \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
    ! -name 'u0_xdma.v' -print | LC_ALL=C sort
  if [[ -d $work_dir/rtl/stubs ]]; then
    find "$work_dir/rtl/stubs" -type f -name '*.v' -print | LC_ALL=C sort
  fi
  if [[ -d $fpga_diff_dir/src/rtl/$cpu ]]; then
    find "$fpga_diff_dir/src/rtl/$cpu" -type f \
      \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
      -print | LC_ALL=C sort
  fi
  find "$core_rtl_dir" -type f \
    \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
    -print | LC_ALL=C sort
  if ((${#rtl_flist_include_dirs[@]})); then
    printf '+incdir+%s\n' "${rtl_flist_include_dirs[@]}"
  fi
  if ((${#rtl_flist_files[@]})); then
    printf '%s\n' "${rtl_flist_files[@]}"
  fi
} > "$tmp_output"

mv -- "$tmp_output" "$output"

case $cpu in
  kmh|nutshell) required_modules=(SimTop) ;;
  nanhu) required_modules=(XlnFpgaTop) ;;
  *) required_modules=() ;;
esac

for module_name in "${required_modules[@]}"; do
  found=0
  while IFS= read -r source_file; do
    [[ $source_file != +* && -f $source_file ]] || continue
    if grep -Eq "^[[:space:]]*module[[:space:]]+$module_name([[:space:]#(]|$)" "$source_file"; then
      found=1
      break
    fi
  done < "$output"
  [[ $found == 1 ]] || rtl_flist_fail "required module not found: $module_name"
  echo "INFO: found required module: $module_name"
done

echo "INFO: generated UVHS file list $output"
