#!/usr/bin/env bash
set -euo pipefail

target_fpgas=${1-}
query_log=${2-}

[[ -n $target_fpgas ]] || {
  echo "ERROR: no target FPGAs were provided" >&2
  exit 2
}
[[ -s $query_log ]] || {
  echo "ERROR: UVHS FPGA query log is missing or empty: $query_log" >&2
  exit 2
}

status=0
for target in $target_fpgas; do
  target=${target^^}
  row=$(awk -v target="$target" \
    '$2 == target || $3 == target { print; exit }' "$query_log")
  if [[ -z $row ]]; then
    echo "ERROR: target FPGA $target is absent from the UVHS status table" >&2
    status=1
    continue
  fi

  link_status=$(awk '{ print tolower($5 " " $6) }' <<<"$row")
  owner=$(awk 'NF >= 8 { print tolower($(NF - 1)) }' <<<"$row")
  booked=$(awk '{ print tolower($NF) }' <<<"$row")
  if [[ $link_status != "link down" || $booked != false || \
        ( -n $owner && $owner != - ) ]]; then
    echo "ERROR: target FPGA $target is occupied or booked: $row" >&2
    status=1
    continue
  fi
  echo "INFO: target FPGA $target is available"
done

exit "$status"
