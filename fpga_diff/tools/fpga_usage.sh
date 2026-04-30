#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")
LOCK_ROOT="${FPGA_USED_DIR:-$HOME/.fpga_used}"
BOARD_NAME="${FPGA_BOARD_NAME:-vu19p}"
STATUS_FILE="$LOCK_ROOT/${BOARD_NAME}.status"
IN_USE_FILE="$LOCK_ROOT/${BOARD_NAME}.in_use"
IDLE_FILE="$LOCK_ROOT/${BOARD_NAME}.idle"

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME init
  $SCRIPT_NAME status
  $SCRIPT_NAME check
  $SCRIPT_NAME acquire [reason]
  $SCRIPT_NAME release [reason]
  $SCRIPT_NAME with-lock <reason> <command> [args...]

Environment:
  FPGA_BOARD_NAME   board name recorded in status files (default: vu19p)
  FPGA_USED_DIR     status directory (default: ~/.fpga_used)
EOF
}

timestamp() {
  date '+%Y-%m-%d %H:%M:%S %z'
}

host_name() {
  hostname -s 2>/dev/null || hostname
}

current_user() {
  id -un
}

status_field() {
  local key="$1"
  [ -f "$STATUS_FILE" ] || return 1
  awk -F= -v key="$key" '$1 == key { print substr($0, length(key) + 2); exit }' "$STATUS_FILE"
}

current_state() {
  status_field state 2>/dev/null || echo "idle"
}

mkdir_root() {
  mkdir -p "$LOCK_ROOT"
}

write_status() {
  local state="$1"
  local reason="${2:-}"
  local command_text="${3:-}"
  local tmp_file

  mkdir_root
  tmp_file=$(mktemp "$LOCK_ROOT/.${BOARD_NAME}.status.XXXXXX")
  cat >"$tmp_file" <<EOF
state=$state
board=$BOARD_NAME
user=$(current_user)
host=$(host_name)
pid=$$
cwd=$(pwd)
time=$(timestamp)
reason=$reason
command=$command_text
EOF
  mv "$tmp_file" "$STATUS_FILE"

  if [ "$state" = "in_use" ]; then
    rm -f "$IDLE_FILE"
    cp "$STATUS_FILE" "$IN_USE_FILE"
  else
    rm -f "$IN_USE_FILE"
    cp "$STATUS_FILE" "$IDLE_FILE"
  fi
}

print_status() {
  local state owner host time reason cwd command_text
  state=$(current_state)
  owner=$(status_field user 2>/dev/null || true)
  host=$(status_field host 2>/dev/null || true)
  time=$(status_field time 2>/dev/null || true)
  reason=$(status_field reason 2>/dev/null || true)
  cwd=$(status_field cwd 2>/dev/null || true)
  command_text=$(status_field command 2>/dev/null || true)

  printf 'board=%s\n' "$BOARD_NAME"
  printf 'state=%s\n' "$state"
  if [ -n "$owner" ]; then
    printf 'user=%s\n' "$owner"
  fi
  if [ -n "$host" ]; then
    printf 'host=%s\n' "$host"
  fi
  if [ -n "$time" ]; then
    printf 'time=%s\n' "$time"
  fi
  if [ -n "$reason" ]; then
    printf 'reason=%s\n' "$reason"
  fi
  if [ -n "$cwd" ]; then
    printf 'cwd=%s\n' "$cwd"
  fi
  if [ -n "$command_text" ]; then
    printf 'command=%s\n' "$command_text"
  fi
  printf 'status_file=%s\n' "$STATUS_FILE"
  printf 'in_use_file=%s\n' "$IN_USE_FILE"
  printf 'idle_file=%s\n' "$IDLE_FILE"
}

ensure_available() {
  local state owner host time
  state=$(current_state)
  owner=$(status_field user 2>/dev/null || true)
  host=$(status_field host 2>/dev/null || true)
  time=$(status_field time 2>/dev/null || true)

  if [ "$state" = "in_use" ] && [ -n "$owner" ] && [ "$owner" != "$(current_user)" ]; then
    echo "ERROR: $BOARD_NAME is already in use by $owner on ${host:-unknown} since ${time:-unknown}." >&2
    echo "Inspect $IN_USE_FILE for details." >&2
    return 1
  fi
}

acquire_lock() {
  local reason="${1:-manual claim}"
  local command_text="${2:-}"

  ensure_available
  write_status "in_use" "$reason" "$command_text"
  echo "$BOARD_NAME is now marked in use by $(current_user)."
}

release_lock() {
  local reason="${1:-manual release}"
  local command_text="${2:-}"
  local state owner

  state=$(current_state)
  owner=$(status_field user 2>/dev/null || true)

  if [ "$state" = "in_use" ] && [ -n "$owner" ] && [ "$owner" != "$(current_user)" ]; then
    echo "ERROR: $BOARD_NAME is owned by $owner; refusing to release it as $(current_user)." >&2
    return 1
  fi

  write_status "idle" "$reason" "$command_text"
  echo "$BOARD_NAME is now marked idle by $(current_user)."
}

with_lock() {
  local reason="$1"
  shift
  local command_text rc

  if [ "$#" -eq 0 ]; then
    echo "ERROR: with-lock requires a command to run." >&2
    exit 1
  fi

  command_text=$(printf '%q ' "$@")
  command_text=${command_text% }
  acquire_lock "$reason" "$command_text"

  cleanup() {
    rc=$?
    release_lock "command exit rc=$rc: $reason" "$command_text" >/dev/null 2>&1 || true
    exit "$rc"
  }

  trap cleanup EXIT INT TERM
  "$@"
}

main() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    init)
      mkdir_root
      if [ ! -f "$STATUS_FILE" ]; then
        write_status "idle" "initialized by $SCRIPT_NAME" ""
      fi
      print_status
      ;;
    status)
      print_status
      ;;
    check)
      ensure_available
      print_status
      ;;
    acquire)
      acquire_lock "${1:-manual claim}" ""
      ;;
    release)
      release_lock "${1:-manual release}" ""
      ;;
    with-lock)
      if [ "$#" -lt 2 ]; then
        usage >&2
        exit 1
      fi
      with_lock "$@"
      ;;
    ""|-h|--help|help)
      usage
      ;;
    *)
      echo "ERROR: unknown command: $cmd" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
