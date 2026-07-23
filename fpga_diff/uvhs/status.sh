#!/usr/bin/env bash
set -euo pipefail

work_dir=${1:-}
if [[ -z "$work_dir" ]]; then
  echo "Usage: $0 <uvhs-work-dir>" >&2
  exit 2
fi

if [[ ! -d "$work_dir" ]]; then
  echo "UVHS work dir not found: $work_dir" >&2
  exit 1
fi

echo "UVHS work dir: $work_dir"

echo
echo "DCPs:"
if ! find "$work_dir/rtl" -maxdepth 3 -type f -name '*.dcp' -printf '  %P %k KB\n' 2>/dev/null | sort; then
  echo "  none"
fi

summarize_log() {
  local name=$1
  local log=$2

  echo
  echo "$name:"
  if [[ ! -f "$log" ]]; then
    echo "  missing: $log"
    return
  fi

  grep -E 'Design synthesized successfully|Uvsyn Synthesis Modules Result Summary|PnR PASS fpga number|FPGA: .*PASS|Total FATAL|Total ERROR|Total WARN|WNS:' "$log" \
    | sed 's/^/  /' || true

  local fatal_count error_count
  fatal_count=$(grep -Ei 'fatal' "$log" | grep -Evc 'Total FATAL:[[:space:]]+0' || true)
  error_count=$(grep -E 'ERROR|Error' "$log" | grep -Evc 'Total ERROR:[[:space:]]+0|0 error\(s\)|No errors|maxerror|Total 0 error|Failed\(0\)|[[:space:]]0[[:space:]]+\[(ERROR|CRITICAL)\]' || true)
  echo "  non-summary fatal lines: $fatal_count"
  echo "  non-summary error lines: $error_count"
}

summarize_log "Frontend" "$work_dir/frontend_run.log"
summarize_log "Backend" "$work_dir/backend_run.log"

echo
echo "Recent serious lines:"
grep -REn 'FATAL|Fatal|ERROR|Error|failed|Failed|Timing +FAIL|Bitstream +FAIL' \
  "$work_dir/frontend_run.log" "$work_dir/backend_run.log" 2>/dev/null \
  | grep -Ev 'Total FATAL:[[:space:]]+0|Total ERROR:[[:space:]]+0|0 error\(s\)|No errors|maxerror|Total 0 error|Failed\(0\)|dmesg: read kernel buffer failed|Timing +Failed FPGAs:[[:space:]]*$|Bitstream Failed FPGAs:[[:space:]]*$|Timing +FAIL fpga number:[[:space:]]*0|Bitstream FAIL fpga number:[[:space:]]*0|[[:space:]]0[[:space:]]+\[(ERROR|CRITICAL)\]' \
  | tail -n 40 \
  | sed 's/^/  /' || true
