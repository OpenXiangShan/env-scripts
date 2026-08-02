#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  generate_rtl_filelist.sh vivado CORE_DIR [--] [RTL_INCLUDE ...]
  generate_rtl_filelist.sh uvhs CORE_DIR WORK_DIR CPU OUTPUT [--] [RTL_INCLUDE ...]
EOF
  exit 2
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fpga_diff_dir=$(cd -- "$script_dir/.." && pwd)
source "$script_dir/rtl_filelist_lib.sh"

generate_vivado_filelist() {
  local core_dir=$1
  local output=$fpga_diff_dir/src/tcl/cpu_files.tcl
  local tmp_dir
  local tmp_output
  shift

  [[ -d $core_dir ]] || rtl_flist_fail "CORE_DIR is not a directory: $core_dir"
  core_dir=$(realpath -e -- "$core_dir")
  rtl_flist_parse_inputs "$PWD" "$@"

  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' RETURN
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

  tmp_output=$tmp_dir/cpu_files.tcl
  awk -v var=cpu_files -v detect_simtop_dma=1 -f "$fpga_diff_dir/core_flist.awk" \
    "$tmp_dir/cpu_files" > "$tmp_output"
  awk -v var=rtl_include_files -f "$fpga_diff_dir/core_flist.awk" \
    "$tmp_dir/rtl_files" >> "$tmp_output"
  awk -v var=rtl_include_dirs -f "$fpga_diff_dir/core_flist.awk" \
    "$tmp_dir/rtl_include_dirs" >> "$tmp_output"
  mkdir -p "$(dirname -- "$output")"
  mv -- "$tmp_output" "$output"
  echo "INFO: generated $output with ${#rtl_flist_files[@]} external RTL files"
}

generate_uvhs_filelist() {
  local core_dir=$1
  local work_dir=$2
  local cpu=$3
  local output=$4
  local core_rtl_dir
  local core_generated_dir
  local module_name
  local source_file
  local found
  local tmp_dir
  local tmp_output
  local -a required_modules=()
  shift 4

  core_dir=$(realpath -e -- "$core_dir")
  work_dir=$(realpath -e -- "$work_dir")
  core_rtl_dir=$core_dir/rtl
  core_generated_dir=$core_dir/generated-src
  [[ -d $core_rtl_dir ]] || rtl_flist_fail "FPGA release RTL not found: $core_rtl_dir"
  rtl_flist_parse_inputs "$PWD" "$@"

  mkdir -p "$(dirname -- "$output")"
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' RETURN
  tmp_output=$tmp_dir/filelist.f

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
}

mode=${1:-}
[[ -n $mode ]] || usage
shift
case $mode in
  vivado)
    [[ $# -ge 1 ]] || usage
    core_dir=$1
    shift
    [[ ${1:-} != -- ]] || shift
    generate_vivado_filelist "$core_dir" "$@"
    ;;
  uvhs)
    [[ $# -ge 4 ]] || usage
    core_dir=$1
    work_dir=$2
    cpu=$3
    output=$4
    shift 4
    [[ ${1:-} != -- ]] || shift
    generate_uvhs_filelist "$core_dir" "$work_dir" "$cpu" "$output" "$@"
    ;;
  *) usage ;;
esac
