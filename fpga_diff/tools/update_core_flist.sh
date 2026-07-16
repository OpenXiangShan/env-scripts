#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

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

[[ -d $core_dir ]] || fail "CORE_DIR is not a directory: $core_dir"

fpga_diff_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
awk_script="$fpga_diff_dir/core_flist.awk"
output_tcl="$fpga_diff_dir/src/tcl/cpu_files.tcl"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

declare -a rtl_files=()
declare -a rtl_include_dirs=()
declare -A seen_files=()
declare -A seen_dirs=()
declare -A active_filelists=()

resolve_path() {
  local base_dir=$1
  local path=$2

  if [[ $path != /* ]]; then
    path="$base_dir/$path"
  fi
  realpath -e -- "$path"
}

add_include_dir() {
  local base_dir=$1
  local path=$2
  local resolved

  resolved=$(resolve_path "$base_dir" "$path") ||
    fail "RTL include directory not found: $path"
  [[ -d $resolved ]] || fail "RTL include path is not a directory: $path"
  if [[ -z ${seen_dirs[$resolved]+x} ]]; then
    seen_dirs[$resolved]=1
    rtl_include_dirs+=("$resolved")
  fi
}

add_rtl_file() {
  local base_dir=$1
  local path=$2
  local resolved

  resolved=$(resolve_path "$base_dir" "$path") || fail "RTL source not found: $path"
  [[ -f $resolved ]] || fail "RTL source is not a file: $path"
  case $resolved in
    *.v|*.sv|*.vh|*.svh) ;;
    *)
      fail "unsupported RTL source: $path"
      ;;
  esac

  if [[ -z ${seen_files[$resolved]+x} ]]; then
    seen_files[$resolved]=1
    rtl_files+=("$resolved")
  fi
  add_include_dir / "$(dirname -- "$resolved")"
}

add_rtl_dir() {
  local base_dir=$1
  local path=$2
  local recursive=$3
  local resolved
  local -a find_depth=()

  resolved=$(resolve_path "$base_dir" "$path") || fail "RTL directory not found: $path"
  [[ -d $resolved ]] || fail "RTL path is not a directory: $path"
  add_include_dir / "$resolved"
  if [[ $recursive == 0 ]]; then
    find_depth=(-maxdepth 1)
  fi
  while IFS= read -r -d '' rtl_file; do
    add_rtl_file / "$rtl_file"
  done < <(
    find "$resolved" "${find_depth[@]}" -type f \
      \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
      -print0 | LC_ALL=C sort -z
  )
}

parse_filelist() {
  local caller_dir=$1
  local path=$2
  local filelist
  local filelist_dir
  local line
  local token
  local pending=""
  local value
  local -a tokens=()
  local -a values=()

  filelist=$(resolve_path "$caller_dir" "$path") ||
    fail "RTL file list not found: $path"
  [[ -f $filelist ]] || fail "RTL file list is not a file: $path"
  if [[ -n ${active_filelists[$filelist]+x} ]]; then
    fail "recursive RTL file list: $filelist"
  fi

  active_filelists[$filelist]=1
  filelist_dir=$(dirname -- "$filelist")
  # Match -F semantics: relative entries belong to the containing file list.
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    line=${line%%//*}
    line=${line%%#*}
    read -r -a tokens <<< "$line"
    for token in "${tokens[@]}"; do
      if [[ -n $pending ]]; then
        case $pending in
          filelist) parse_filelist "$filelist_dir" "$token" ;;
          library) add_rtl_dir "$filelist_dir" "$token" 0 ;;
          source) add_rtl_file "$filelist_dir" "$token" ;;
          include) add_include_dir "$filelist_dir" "$token" ;;
        esac
        pending=""
        continue
      fi

      case $token in
        -f|-F) pending=filelist ;;
        -y) pending=library ;;
        -v) pending=source ;;
        -I) pending=include ;;
        -f*|-F*) parse_filelist "$filelist_dir" "${token:2}" ;;
        -y*) add_rtl_dir "$filelist_dir" "${token:2}" 0 ;;
        -v*) add_rtl_file "$filelist_dir" "${token:2}" ;;
        -I*) add_include_dir "$filelist_dir" "${token:2}" ;;
        +incdir+*)
          IFS=+ read -r -a values <<< "${token#+incdir+}"
          for value in "${values[@]}"; do
            [[ -n $value ]] && add_include_dir "$filelist_dir" "$value"
          done
          ;;
        +libext+*) ;;
        *.v|*.sv|*.vh|*.svh) add_rtl_file "$filelist_dir" "$token" ;;
        *) fail "unsupported option in $filelist: $token" ;;
      esac
    done
  done < "$filelist"
  [[ -z $pending ]] || fail "missing argument after file-list option in $filelist"
  unset 'active_filelists[$filelist]'
}

for rtl_include in "$@"; do
  if [[ -d $rtl_include ]]; then
    add_rtl_dir "$PWD" "$rtl_include" 1
  elif [[ -f $rtl_include ]]; then
    case $rtl_include in
      *.f|*.flist|*.list) parse_filelist "$PWD" "$rtl_include" ;;
      *) add_rtl_file "$PWD" "$rtl_include" ;;
    esac
  else
    fail "RTL_INCLUDE path not found: $rtl_include"
  fi
done

core_dir=$(realpath -e -- "$core_dir")
find "$core_dir" -path "$core_dir/rtl/verification" -prune -o \
  -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
  -print | LC_ALL=C sort > "$tmp_dir/cpu_files"
: > "$tmp_dir/rtl_files"
: > "$tmp_dir/rtl_include_dirs"
if ((${#rtl_files[@]})); then
  printf '%s\n' "${rtl_files[@]}" > "$tmp_dir/rtl_files"
fi
if ((${#rtl_include_dirs[@]})); then
  printf '%s\n' "${rtl_include_dirs[@]}" > "$tmp_dir/rtl_include_dirs"
fi

tmp_output="$tmp_dir/cpu_files.tcl"
awk -v var=cpu_files -v detect_simtop_dma=1 -f "$awk_script" \
  "$tmp_dir/cpu_files" > "$tmp_output"
awk -v var=rtl_include_files -f "$awk_script" \
  "$tmp_dir/rtl_files" >> "$tmp_output"
awk -v var=rtl_include_dirs -f "$awk_script" \
  "$tmp_dir/rtl_include_dirs" >> "$tmp_output"
mv -- "$tmp_output" "$output_tcl"

echo "INFO: generated $output_tcl with ${#rtl_files[@]} external RTL files"
