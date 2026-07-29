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

timeout=${UVHS_RUNTIME_COMMAND_TIMEOUT:-600}
if [[ ! $timeout =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: UVHS_RUNTIME_COMMAND_TIMEOUT must be a positive integer" >&2
  exit 64
fi
result_file="${command_file}.result.$$"

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
trap 'rm -f "$tmp_file" "$result_file"' EXIT

{
  printf 'set uvhs_result_file '
  tcl_quote "$result_file"
  printf '\n'
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

deadline=$((SECONDS + timeout))
while [[ ! -f $result_file ]]; do
  if (( SECONDS >= deadline )); then
    echo "ERROR: timed out waiting for UVHS runtime command after ${timeout}s" >&2
    exit 5
  fi
  sleep 0.2
done

status=$(sed -n '1p' "$result_file")
message=$(sed -n '2,$p' "$result_file")
rm -f "$result_file"
if [[ $status != 0 ]]; then
  echo "ERROR: UVHS runtime command failed: $message" >&2
  exit 6
fi
if [[ -n $message ]]; then
  echo "INFO: $message"
fi
