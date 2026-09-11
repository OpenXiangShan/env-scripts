#!/usr/bin/env bash

# Shared RTL_INCLUDE parser. Call rtl_flist_parse_inputs BASE_DIR INPUT...
# after sourcing this file, then consume rtl_flist_files and
# rtl_flist_include_dirs.

declare -a rtl_flist_files=()
declare -a rtl_flist_include_dirs=()
declare -A rtl_flist_seen_files=()
declare -A rtl_flist_seen_dirs=()
declare -A rtl_flist_active_lists=()

rtl_flist_fail() {
  echo "ERROR: $*" >&2
  exit 1
}

rtl_flist_resolve_path() {
  local base_dir=$1
  local path=$2

  if [[ $path != /* ]]; then
    path="$base_dir/$path"
  fi
  realpath -e -- "$path"
}

rtl_flist_add_include_dir() {
  local base_dir=$1
  local path=$2
  local resolved

  resolved=$(rtl_flist_resolve_path "$base_dir" "$path") ||
    rtl_flist_fail "RTL include directory not found: $path"
  [[ -d $resolved ]] || rtl_flist_fail "RTL include path is not a directory: $path"
  if [[ -z ${rtl_flist_seen_dirs[$resolved]+x} ]]; then
    rtl_flist_seen_dirs[$resolved]=1
    rtl_flist_include_dirs+=("$resolved")
  fi
}

rtl_flist_add_file() {
  local base_dir=$1
  local path=$2
  local resolved

  resolved=$(rtl_flist_resolve_path "$base_dir" "$path") ||
    rtl_flist_fail "RTL source not found: $path"
  [[ -f $resolved ]] || rtl_flist_fail "RTL source is not a file: $path"
  case $resolved in
    *.v|*.sv|*.vh|*.svh) ;;
    *) rtl_flist_fail "unsupported RTL source: $path" ;;
  esac

  if [[ -z ${rtl_flist_seen_files[$resolved]+x} ]]; then
    rtl_flist_seen_files[$resolved]=1
    rtl_flist_files+=("$resolved")
  fi
  rtl_flist_add_include_dir / "$(dirname -- "$resolved")"
}

rtl_flist_add_dir() {
  local base_dir=$1
  local path=$2
  local recursive=$3
  local resolved
  local -a find_depth=()

  resolved=$(rtl_flist_resolve_path "$base_dir" "$path") ||
    rtl_flist_fail "RTL directory not found: $path"
  [[ -d $resolved ]] || rtl_flist_fail "RTL path is not a directory: $path"
  rtl_flist_add_include_dir / "$resolved"
  if [[ $recursive == 0 ]]; then
    find_depth=(-maxdepth 1)
  fi
  while IFS= read -r -d '' rtl_file; do
    rtl_flist_add_file / "$rtl_file"
  done < <(
    find "$resolved" "${find_depth[@]}" -type f \
      \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
      -print0 | LC_ALL=C sort -z
  )
}

rtl_flist_parse_filelist() {
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

  filelist=$(rtl_flist_resolve_path "$caller_dir" "$path") ||
    rtl_flist_fail "RTL file list not found: $path"
  [[ -f $filelist ]] || rtl_flist_fail "RTL file list is not a file: $path"
  if [[ -n ${rtl_flist_active_lists[$filelist]+x} ]]; then
    rtl_flist_fail "recursive RTL file list: $filelist"
  fi

  rtl_flist_active_lists[$filelist]=1
  filelist_dir=$(dirname -- "$filelist")
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    line=${line%%//*}
    line=${line%%#*}
    read -r -a tokens <<< "$line"
    for token in "${tokens[@]}"; do
      if [[ -n $pending ]]; then
        case $pending in
          filelist) rtl_flist_parse_filelist "$filelist_dir" "$token" ;;
          library) rtl_flist_add_dir "$filelist_dir" "$token" 0 ;;
          source) rtl_flist_add_file "$filelist_dir" "$token" ;;
          include) rtl_flist_add_include_dir "$filelist_dir" "$token" ;;
        esac
        pending=""
        continue
      fi

      case $token in
        -f|-F) pending=filelist ;;
        -y) pending=library ;;
        -v) pending=source ;;
        -I) pending=include ;;
        -f*|-F*) rtl_flist_parse_filelist "$filelist_dir" "${token:2}" ;;
        -y*) rtl_flist_add_dir "$filelist_dir" "${token:2}" 0 ;;
        -v*) rtl_flist_add_file "$filelist_dir" "${token:2}" ;;
        -I*) rtl_flist_add_include_dir "$filelist_dir" "${token:2}" ;;
        +incdir+*)
          IFS=+ read -r -a values <<< "${token#+incdir+}"
          for value in "${values[@]}"; do
            [[ -n $value ]] && rtl_flist_add_include_dir "$filelist_dir" "$value"
          done
          ;;
        +libext+*) ;;
        *.v|*.sv|*.vh|*.svh) rtl_flist_add_file "$filelist_dir" "$token" ;;
        *) rtl_flist_fail "unsupported option in $filelist: $token" ;;
      esac
    done
  done < "$filelist"
  [[ -z $pending ]] || rtl_flist_fail "missing argument after file-list option in $filelist"
  unset 'rtl_flist_active_lists[$filelist]'
}

rtl_flist_parse_inputs() {
  local base_dir=$1
  local input
  local resolved
  shift

  for input in "$@"; do
    resolved=$(rtl_flist_resolve_path "$base_dir" "$input") ||
      rtl_flist_fail "RTL_INCLUDE path not found: $input"
    if [[ -d $resolved ]]; then
      rtl_flist_add_dir / "$resolved" 1
    elif [[ -f $resolved ]]; then
      case $input in
        *.f|*.flist|*.list) rtl_flist_parse_filelist / "$resolved" ;;
        *) rtl_flist_add_file / "$resolved" ;;
      esac
    else
      rtl_flist_fail "RTL_INCLUDE path not found: $input"
    fi
  done
}
