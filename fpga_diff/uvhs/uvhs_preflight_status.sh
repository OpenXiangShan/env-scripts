#!/usr/bin/env bash
set -euo pipefail

STAGE="${UVHS_STAGE_DIR:?set UVHS_STAGE_DIR}"
TAG="${UVHS_RUN_TAG:-$(basename "$STAGE")}"
RUNDIR="${UVHS_PNR_RUNDIR:-$STAGE/hw.dat/Compile/PnR/B0/F2/vivado/Rundir/Strategy_uv_high_fanout_explore}"
COMMAND_FILE="${UVHS_COMMAND_FILE:-$STAGE/commands/${TAG}.command.tcl}"
SESSION="${UVHS_TMUX_SESSION:-uvhs_${TAG}}"

ts() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

show_path() {
  local label="$1"
  local path="$2"
  if [ -e "$path" ]; then
    stat -c "$label=%n size=%s mtime=%y" "$path"
  else
    echo "MISSING $label=$path"
  fi
}

echo "## uvhs_preflight_status $(ts)"
echo "tag=$TAG"
echo "stage=$STAGE"
echo "rundir=$RUNDIR"
echo "session=$SESSION"
echo "command_file=$COMMAND_FILE"

echo "## required paths"
show_path stage "$STAGE"
show_path hw_dat "$STAGE/hw.dat"
show_path pnr_bit "$RUNDIR/bitstream/pnr.bit"
show_path pnr_bin "$RUNDIR/bitstream/pnr.bin"
show_path pnr_routed_dcp "$RUNDIR/bitstream/pnr_routed.dcp"
show_path cdc_regular "$RUNDIR/bitstream/timing/pnr_cdc.rpt"
show_path cdc_details "$RUNDIR/bitstream/timing/pnr_cdc_details_codex.rpt"
show_path timing_summary "$RUNDIR/bitstream/timing/pnr_timing_summary_codex.rpt"
show_path cdc_classification "$RUNDIR/bitstream/timing/cdc_classification_codex.txt"
show_path runtime_script "$STAGE/uvhs_tagged_runtime.sh"
show_path download_script "$STAGE/user_script/hw_run_download.tcl"
show_path workload_hello "$STAGE/ready-to-run/hello-xs.txt"

echo "## helper hashes"
sha256sum \
  "$STAGE/uvhs_tagged_runtime.sh" \
  "$STAGE/user_script/hw_run_download.tcl" \
  2>/dev/null || true

echo "## cdc/timing gates"
if [ -f "$RUNDIR/bitstream/timing/cdc_classification_codex.txt" ]; then
  awk '
    /severity_counts:/ || /owned_critical_count:/ || /difftest_cfg_rows:/ {print}
    /critical_category_counts:/ {print; show=1; next}
    show && /^[^[:space:]]/ {show=0}
    show && /^[[:space:]]/ {print}
  ' "$RUNDIR/bitstream/timing/cdc_classification_codex.txt" || true
fi
if [ -f "$RUNDIR/bitstream/timing/pnr_timing_summary_codex.rpt" ]; then
  awk '
    /Design Timing Summary/ {flag=1}
    flag && /WNS\(ns\)/ {print; header=1; next}
    header && /^[[:space:]]*-+/ {next}
    header && /[0-9]/ {print; exit}
  ' "$RUNDIR/bitstream/timing/pnr_timing_summary_codex.rpt" || true
  grep -m1 'All user specified timing constraints are met' "$RUNDIR/bitstream/timing/pnr_timing_summary_codex.rpt" || true
fi

echo "## command-file residue"
ls -l "$COMMAND_FILE" "$COMMAND_FILE.running" 2>/dev/null || true

echo "## tmux exact tag matches"
tmux ls 2>/dev/null | grep -F "$TAG" || true

echo "## ps exact tag matches"
ps -eo pid,ppid,user,etime,stat,wchan:24,cmd \
  | awk -v tag="$TAG" -v self="$$" -v parent="$PPID" \
      '$1 != self && $1 != parent && index($0, tag) && $0 !~ /awk -v tag=/ {print}' || true

echo "## preflight note"
echo "No download/programming is performed by this script."
