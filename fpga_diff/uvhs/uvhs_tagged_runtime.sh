#!/usr/bin/env bash
set -euo pipefail

TAG="${UVHS_RUN_TAG:?set a unique UVHS_RUN_TAG}"
STAGE="${UVHS_STAGE_DIR:?set UVHS_STAGE_DIR}"
UV_SHELL="${UVHS_UV_SHELL:-/home/data/UVHS/2506p4_0210/bin/uv_shell}"
SESSION="${UVHS_TMUX_SESSION:-uvhs_${TAG}}"
DB_PATH="${UVHS_DB_PATH:-$STAGE/hw.dat}"
DOWNLOAD_SCRIPT="${UVHS_DOWNLOAD_SCRIPT:-$STAGE/user_script/hw_run_download.tcl}"
DDR_RTL="${UVHS_DDR_RTL:-fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4}"
COMMAND_FILE="${UVHS_COMMAND_FILE:-$STAGE/commands/${TAG}.command.tcl}"
WORKDIR="${UVHS_DOWNLOAD_WORKDIR:-$STAGE/workdir/${TAG}}"
LOG="${UVHS_DOWNLOAD_LOG:-$STAGE/logs/${TAG}.download.log}"
ALLOW_DOWNLOAD="${UVHS_ALLOW_DOWNLOAD:-0}"
ALLOW_DOWNLOAD_TAG="${UVHS_ALLOW_DOWNLOAD_TAG:-}"
WAIT_AFTER_START="${UVHS_WAIT_READY_AFTER_START:-1}"
READY_WAIT_SEC="${UVHS_READY_WAIT_SEC:-600}"
READY_POLL_SEC="${UVHS_READY_POLL_SEC:-2}"

ts() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_tagged_value() {
  local label="$1"
  local value="$2"
  case "$value" in
    *"$TAG"*) ;;
    *) die "$label must contain the exact current run tag '$TAG': $value" ;;
  esac
}

validate_run_identity() {
  case "$TAG" in
    ""|*[!A-Za-z0-9_.-]*)
      die "UVHS_RUN_TAG must be non-empty and contain only A-Z, a-z, 0-9, '.', '_' or '-': $TAG"
      ;;
  esac
  if [ "${#TAG}" -gt 120 ]; then
    die "UVHS_RUN_TAG is longer than 120 characters"
  fi
  require_tagged_value UVHS_STAGE_DIR "$STAGE"
  require_tagged_value UVHS_TMUX_SESSION "$SESSION"
  require_tagged_value UVHS_COMMAND_FILE "$COMMAND_FILE"
  require_tagged_value UVHS_DOWNLOAD_WORKDIR "$WORKDIR"
  require_tagged_value UVHS_DOWNLOAD_LOG "$LOG"
  case "$WAIT_AFTER_START" in
    0|1) ;;
    *) die "UVHS_WAIT_READY_AFTER_START must be 0 or 1" ;;
  esac
  local item name value
  for item in "UVHS_READY_WAIT_SEC:$READY_WAIT_SEC" "UVHS_READY_POLL_SEC:$READY_POLL_SEC"; do
    name="${item%%:*}"
    value="${item#*:}"
    case "$value" in
      ''|*[!0-9]*|0*) die "$name must be a positive integer" ;;
    esac
  done
}

require_fresh_start_artifacts() {
  local run_script existing
  run_script="$STAGE/commands/${TAG}.start-download.sh"
  for existing in \
    "$COMMAND_FILE" \
    "$COMMAND_FILE.running" \
    "$WORKDIR" \
    "$LOG" \
    "$run_script"; do
    if [ -e "$existing" ]; then
      die "refusing reused UVHS_RUN_TAG; artifact already exists: $existing"
    fi
  done
}

has_exact_session() {
  tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -Fxq "$SESSION"
}

show_exact_matches() {
  echo "## tmux exact tag matches"
  tmux ls 2>/dev/null | grep -F "$TAG" || true
  echo "## ps exact tag matches"
  ps -eo pid,ppid,user,etime,stat,wchan:24,cmd \
    | awk -v tag="$TAG" -v self="$$" -v parent="$PPID" \
        '$1 != self && $1 != parent && index($0, tag) && $0 !~ /awk -v tag=/ {print}' || true
}

require_stage() {
  for p in "$STAGE" "$DB_PATH" "$DOWNLOAD_SCRIPT"; do
    if [ ! -e "$p" ]; then
      echo "ERROR: missing required path: $p" >&2
      exit 2
    fi
  done
  if [ ! -x "$UV_SHELL" ]; then
    echo "ERROR: uv_shell not executable: $UV_SHELL" >&2
    exit 3
  fi
}

last_log_match() {
  local pattern="$1"
  grep -Ein "$pattern" "$LOG" 2>/dev/null | tail -n 1 || true
}

emit_log_evidence() {
  local label="$1"
  local match="$2"
  local line text_value
  line="${match%%:*}"
  text_value="${match#*:}"
  echo "${label}_evidence=$LOG:$line:$text_value"
}

wait_ready_runtime() {
  local deadline error_match load_match download_match link_match init_match
  local ddr_match reset4_match reset5_match reset6_match
  deadline=$(( $(date +%s) + READY_WAIT_SEC ))
  echo "## uvhs_tagged_runtime wait-ready $(ts)"
  echo "tag=$TAG"
  echo "session=$SESSION"
  echo "log=$LOG"
  echo "ready_wait_sec=$READY_WAIT_SEC"
  echo "ready_poll_sec=$READY_POLL_SEC"

  while [ "$(date +%s)" -lt "$deadline" ]; do
    if [ -f "$LOG" ]; then
      error_match="$(last_log_match '(^|[[:space:]])ERROR:|[[]RTM-[0-9]+[]].*ERROR|download.*fail|initializ(e|ation).*fail|Load_DB.*fail')"
      if [ -n "$error_match" ]; then
        echo "runtime_ready=0"
        emit_log_evidence runtime_error "$error_match"
        return 10
      fi

      load_match="$(last_log_match 'INFO: loading runtime database|load_db.*success')"
      download_match="$(last_log_match 'Done: download success|download.*success')"
      link_match="$(last_log_match 'linked up|(^|[[:space:]])link up')"
      init_match="$(last_log_match 'Done: initialization complete success|systembus initialize success|ps initialize success')"
      ddr_match="$(last_log_match 'DDR4 initialize success')"
      reset4_match="$(last_log_match 'rstn_sw4[^0-9]*1')"
      reset5_match="$(last_log_match 'rstn_sw5[^0-9]*1')"
      reset6_match="$(last_log_match 'rstn_sw6[^0-9]*1')"

      if [ -n "$load_match" ] && [ -n "$download_match" ] && [ -n "$link_match" ] && \
         [ -n "$init_match" ] && [ -n "$ddr_match" ] && \
         [ -n "$reset4_match" ] && [ -n "$reset5_match" ] && [ -n "$reset6_match" ]; then
        echo "runtime_ready=1"
        emit_log_evidence load_db "$load_match"
        emit_log_evidence download "$download_match"
        emit_log_evidence link "$link_match"
        emit_log_evidence initialize "$init_match"
        emit_log_evidence ddr_initialize "$ddr_match"
        emit_log_evidence reset_sw4 "$reset4_match"
        emit_log_evidence reset_sw5 "$reset5_match"
        emit_log_evidence reset_sw6 "$reset6_match"
        return 0
      fi
    fi

    if ! has_exact_session; then
      echo "runtime_ready=0"
      echo "runtime_ready_reason=session_exited"
      return 11
    fi
    sleep "$READY_POLL_SEC"
  done

  echo "runtime_ready=0"
  echo "runtime_ready_reason=timeout"
  [ -f "$LOG" ] && tail -120 "$LOG" || true
  return 12
}

start_runtime() {
  require_stage
  echo "## uvhs_tagged_runtime start $(ts)"
  echo "tag=$TAG"
  echo "stage=$STAGE"
  echo "session=$SESSION"
  echo "db_path=$DB_PATH"
  echo "download_script=$DOWNLOAD_SCRIPT"
  echo "command_file=$COMMAND_FILE"
  echo "workdir=$WORKDIR"
  echo "log=$LOG"
  echo "allow_download=$ALLOW_DOWNLOAD"
  echo "allow_download_tag=$ALLOW_DOWNLOAD_TAG"
  echo "wait_ready_after_start=$WAIT_AFTER_START"
  show_exact_matches

  if has_exact_session; then
    echo "ERROR: tmux session already exists: $SESSION" >&2
    exit 4
  fi
  if [ "$ALLOW_DOWNLOAD" != 1 ] || [ "$ALLOW_DOWNLOAD_TAG" != "$TAG" ]; then
    echo "DRY_RUN: set UVHS_ALLOW_DOWNLOAD=1 and UVHS_ALLOW_DOWNLOAD_TAG=$TAG to start tmux/uv_shell download"
    return 0
  fi

  require_fresh_start_artifacts

  mkdir -p "$(dirname "$COMMAND_FILE")" "$WORKDIR" "$(dirname "$LOG")"

  local run_script
  run_script="$STAGE/commands/${TAG}.start-download.sh"
  cat > "$run_script" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export UVHS_DB_PATH=$(printf '%q' "$DB_PATH")
export UVHS_COMMAND_FILE=$(printf '%q' "$COMMAND_FILE")
export UVHS_DDR_RTL=$(printf '%q' "$DDR_RTL")
cd $(printf '%q' "$STAGE")
exec $(printf '%q' "$UV_SHELL") -rt_shell -workdir $(printf '%q' "$WORKDIR") -script $(printf '%q' "$DOWNLOAD_SCRIPT")
EOF
  chmod +x "$run_script"

  tmux new-session -d -s "$SESSION" "bash -lc 'exec \"$run_script\" >>\"$LOG\" 2>&1'"
  echo "started_session=$SESSION"
  echo "started_log=$LOG"
  if [ "$WAIT_AFTER_START" = 1 ]; then
    wait_ready_runtime
  fi
}

status_runtime() {
  echo "## uvhs_tagged_runtime status $(ts)"
  echo "tag=$TAG"
  echo "session=$SESSION"
  echo "log=$LOG"
  show_exact_matches
  if [ -f "$LOG" ]; then
    echo "## log tail"
    tail -120 "$LOG" || true
  fi
}

cleanup_runtime() {
  echo "## uvhs_tagged_runtime cleanup $(ts)"
  echo "tag=$TAG"
  echo "session=$SESSION"
  echo "command_file=$COMMAND_FILE"
  show_exact_matches

  if has_exact_session; then
    local wait_left
    wait_left="${UVHS_COMMAND_IDLE_WAIT_SEC:-10}"
    case "$wait_left" in
      ''|*[!0-9]*|0[0-9]*) die "UVHS_COMMAND_IDLE_WAIT_SEC must be a non-negative integer" ;;
    esac
    while { [ -e "$COMMAND_FILE" ] || [ -e "$COMMAND_FILE.running" ]; } && [ "$wait_left" -gt 0 ]; do
      echo "waiting_for_existing_command_file seconds_left=$wait_left"
      sleep 1
      wait_left=$((wait_left - 1))
    done
    if [ -e "$COMMAND_FILE" ] || [ -e "$COMMAND_FILE.running" ]; then
      die "refusing to overwrite active/stale command file during cleanup: $COMMAND_FILE"
    fi
    mkdir -p "$(dirname "$COMMAND_FILE")"
    cat > "$COMMAND_FILE.tmp" <<'EOF'
set ::uvhs_keepalive 1
EOF
    mv -n "$COMMAND_FILE.tmp" "$COMMAND_FILE"
    if [ -e "$COMMAND_FILE.tmp" ]; then
      rm -f "$COMMAND_FILE.tmp"
      die "command file appeared during cleanup; refusing overwrite: $COMMAND_FILE"
    fi
    sleep "${UVHS_CLEANUP_GRACE_SEC:-3}"
  fi

  if has_exact_session; then
    echo "## exact matches immediately before forced session cleanup"
    show_exact_matches
    # has_exact_session above already proves a full-name match.  Older tmux
    # releases on the runtime host do not accept the newer "=name" syntax.
    tmux kill-session -t "$SESSION"
    echo "killed_session=$SESSION"
  else
    echo "no_session=$SESSION"
  fi

  echo "## post-cleanup exact tag matches"
  show_exact_matches
}

validate_run_identity

case "${1:-status}" in
  start) start_runtime ;;
  wait-ready) wait_ready_runtime ;;
  status) status_runtime ;;
  cleanup) cleanup_runtime ;;
  *)
    echo "usage: $0 {start|wait-ready|status|cleanup}" >&2
    exit 64
    ;;
esac
