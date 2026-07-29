#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 )); then
  echo "usage: $0 <command-file> <tcl-script> [argument ...]" >&2
  exit 64
fi

command_file=$1
tcl_script=$2
shift 2

if [[ ! -f $tcl_script ]]; then
  echo "ERROR: runtime Tcl script not found: $tcl_script" >&2
  exit 2
fi
if [[ -e $command_file || -e $command_file.running ]]; then
  echo "ERROR: a UVHS runtime command is already pending" >&2
  exit 3
fi

tcl_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$/\\\$}
  value=${value//\[/\\[}
  value=${value//\]/\\]}
  printf '"%s"' "$value"
}

mkdir -p "$(dirname "$command_file")"
tmp_file="${command_file}.tmp.$$"
trap 'rm -f "$tmp_file"' EXIT

{
  printf 'set argv [list'
  for argument in "$@"; do
    printf ' '
    tcl_quote "$argument"
  done
  printf ']\nsource '
  tcl_quote "$tcl_script"
  printf '\n'
} >"$tmp_file"

mv -n "$tmp_file" "$command_file"
if [[ -e $tmp_file ]]; then
  echo "ERROR: command file appeared while enqueueing: $command_file" >&2
  exit 4
fi
trap - EXIT
echo "INFO: enqueued UVHS runtime command: $command_file"
