#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  update_core_flist.sh vivado CORE_DIR OUTPUT [--] [RTL_INCLUDE ...]
  update_core_flist.sh uvhs CORE_DIR WORK_DIR CPU OUTPUT [--] [RTL_INCLUDE ...]
EOF
  exit 2
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fpga_diff_dir=$(cd -- "$script_dir/.." && pwd)
source "$script_dir/rtl_filelist_lib.sh"

generate_vivado_filelist() {
  local core_dir=$1
  local output=$2
  local top_module=SimTop
  local tmp_dir
  local tmp_output
  shift 2

  [[ -d $core_dir ]] || rtl_flist_fail "CORE_DIR is not a directory: $core_dir"
  core_dir=$(realpath -e -- "$core_dir")
  output=$(realpath -m -- "$output")
  if [[ ${NO_DIFF:-0} == 1 ]]; then
    top_module=XSTop
  fi
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
  awk -v var=cpu_files -v detect_simtop_dma=1 -v top_module="$top_module" \
    -f "$fpga_diff_dir/core_flist.awk" \
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

  local hostif=${DIFFTEST_HOSTIF:-XDMA}
  local c2h_dma=${UVHS_GBUS_C2H_DMA:-0}
  [[ $c2h_dma == 0 || $c2h_dma == 1 ]] || rtl_flist_fail "UVHS_GBUS_C2H_DMA must be 0 or 1"
  [[ $c2h_dma == 0 || $hostif == GBUS ]] || rtl_flist_fail "UVHS_GBUS_C2H_DMA=1 requires GBUS"
  local functional_ddr_remote_link=${UVHS_FUNCTIONAL_DDR_REMOTE_LINK:-0}
  [[ $hostif == XDMA || $hostif == GBUS ]] ||
    rtl_flist_fail "DIFFTEST_HOSTIF must be XDMA or GBUS: $hostif"
  [[ $functional_ddr_remote_link == 0 || $functional_ddr_remote_link == 1 ]] ||
    rtl_flist_fail "UVHS_FUNCTIONAL_DDR_REMOTE_LINK must be 0 or 1: $functional_ddr_remote_link"
  if [[ $functional_ddr_remote_link == 1 && $hostif != GBUS ]]; then
    rtl_flist_fail "UVHS_FUNCTIONAL_DDR_REMOTE_LINK=1 requires DIFFTEST_HOSTIF=GBUS"
  fi

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
    # UVHS supplies the board clocking, DDR, and platform wrappers.  Keep the
    # same synthesis/configuration defines used by the established UVHS flow;
    # without UVHS the shared top incorrectly selects Vivado-only primitives.
    # XiangShan UVHS builds require the platform adaptation and external DDR
    # contract used by the known-good fpgamini GBus release.  Without these
    # defines the shared core falls back to the reduced Vivado-only path.
    if [[ $cpu == kmh ]]; then
      printf '+define+UVHS_SOC_ADAPT\n+define+UVHS_NO_XILINX_CLK_PRIMS\n'
      printf '+define+UVHS_EXTERNAL_UVW_AXI4_TO_DDR4\n+define+UVHS_UVW_AXI4_TO_DDR4\n'
      printf '+define+UVHS_CPU_DEBUG_CLK\n+define+CONFIG_USE_XSCORE_AXI\n'
    fi
    if [[ $hostif == GBUS ]]; then
      printf '+define+CONFIG_DIFFTEST_HOSTIF_GBUS\n'
      if [[ $c2h_dma == 1 ]]; then
        printf '+define+UVHS_GBUS_C2H_DMA\n'
      fi
      if [[ $functional_ddr_remote_link == 1 ]]; then
        printf '+define+UVHS_FUNCTIONAL_DDR_REMOTE_LINK\n'
      fi
    fi
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
  # XiangShan's top is supplied by the generated release RTL and does not
  # require an additional wrapper module check here.  Keep the loop safe for
  # CPUs without an explicit required-module list under `set -u`.
  if ((${#required_modules[@]})); then
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
  fi
  echo "INFO: generated UVHS file list $output"
}

mode=${1:-}
[[ -n $mode ]] || usage
shift
case $mode in
  vivado)
    [[ $# -ge 2 ]] || usage
    core_dir=$1
    output=$2
    shift 2
    [[ ${1:-} != -- ]] || shift
    generate_vivado_filelist "$core_dir" "$output" "$@"
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
