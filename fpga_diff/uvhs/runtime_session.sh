#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage:
  runtime_session.sh start <pid-file> <ready-file> <log-file> <command-file> \
    <timeout> <command> [argument ...]
  runtime_session.sh active <pid-file>
  runtime_session.sh check <pid-file> <ready-file>
  runtime_session.sh wait <pid-file> <ready-file> <command-file> <timeout>
EOF
  exit 64
}

read_pid() {
  local pid_file=$1
  local pid
  [[ -f $pid_file ]] || return 1
  IFS= read -r pid <"$pid_file" || return 1
  [[ $pid =~ ^[1-9][0-9]*$ ]] || return 1
  printf '%s\n' "$pid"
}

process_is_alive() {
  kill -0 "$1" 2>/dev/null
}

validate_timeout() {
  [[ $1 =~ ^[1-9][0-9]*$ ]] || {
    echo "ERROR: UVHS runtime timeout must be a positive integer" >&2
    exit 64
  }
}

show_log_tail() {
  local log_file=$1
  if [[ -f $log_file ]]; then
    echo "----- UVHS runtime log tail: $log_file -----" >&2
    tail -40 "$log_file" >&2
  fi
}

action=${1:-}
[[ -n $action ]] || usage
shift

case $action in
  start)
    (( $# >= 6 )) || usage
    pid_file=$1
    ready_file=$2
    log_file=$3
    command_file=$4
    timeout=$5
    shift 5
    validate_timeout "$timeout"

    if pid=$(read_pid "$pid_file") && process_is_alive "$pid"; then
      echo "ERROR: UVHS runtime is already active with PID $pid" >&2
      echo "Run make uvhs_runtime_stop before programming again." >&2
      exit 2
    fi

    mkdir -p "$(dirname "$pid_file")" "$(dirname "$ready_file")" \
      "$(dirname "$log_file")" "$(dirname "$command_file")"
    rm -f "$pid_file" "$ready_file" "$command_file" "${command_file}.running"

    nohup "$@" </dev/null >"$log_file" 2>&1 &
    pid=$!
    pid_temp="${pid_file}.tmp.$$"
    printf '%s\n' "$pid" >"$pid_temp"
    mv -f "$pid_temp" "$pid_file"

    deadline=$((SECONDS + timeout))
    while [[ ! -f $ready_file ]]; do
      if ! process_is_alive "$pid"; then
        set +e
        wait "$pid"
        status=$?
        set -e
        rm -f "$pid_file" "$ready_file"
        show_log_tail "$log_file"
        echo "ERROR: UVHS runtime exited before it became ready (status $status)" >&2
        exit 3
      fi
      if (( SECONDS >= deadline )); then
        kill "$pid" 2>/dev/null || true
        wait "$pid" 2>/dev/null || true
        rm -f "$pid_file" "$ready_file"
        show_log_tail "$log_file"
        echo "ERROR: timed out waiting for UVHS runtime after ${timeout}s" >&2
        exit 4
      fi
      sleep 0.2
    done

    if ! runtime_pid=$(read_pid "$ready_file") || ! process_is_alive "$runtime_pid"; then
      rm -f "$pid_file" "$ready_file"
      show_log_tail "$log_file"
      echo "ERROR: UVHS runtime published an invalid ready PID" >&2
      exit 5
    fi
    pid_temp="${pid_file}.tmp.$$"
    printf '%s\n' "$runtime_pid" >"$pid_temp"
    mv -f "$pid_temp" "$pid_file"
    echo "INFO: UVHS runtime ready (PID $runtime_pid); log: $log_file"
    ;;
  active)
    (( $# == 1 )) || usage
    pid_file=$1
    if pid=$(read_pid "$pid_file") && process_is_alive "$pid"; then
      echo "INFO: UVHS runtime process is active (PID $pid)"
      exit 0
    fi
    rm -f "$pid_file"
    exit 1
    ;;
  check)
    (( $# == 2 )) || usage
    pid_file=$1
    ready_file=$2
    if ! pid=$(read_pid "$pid_file") || ! process_is_alive "$pid"; then
      rm -f "$pid_file" "$ready_file"
      echo "ERROR: UVHS runtime is not active; run make uvhs_write_bitstream first" >&2
      exit 6
    fi
    if ! ready_pid=$(read_pid "$ready_file") || [[ $ready_pid != "$pid" ]]; then
      echo "ERROR: UVHS runtime PID $pid has no matching ready marker" >&2
      exit 7
    fi
    echo "INFO: UVHS runtime is ready (PID $pid)"
    ;;
  wait)
    (( $# == 4 )) || usage
    pid_file=$1
    ready_file=$2
    command_file=$3
    timeout=$4
    validate_timeout "$timeout"

    if ! pid=$(read_pid "$pid_file"); then
      rm -f "$ready_file" "$command_file" "${command_file}.running"
      exit 0
    fi
    deadline=$((SECONDS + timeout))
    while process_is_alive "$pid"; do
      if (( SECONDS >= deadline )); then
        echo "ERROR: timed out waiting for UVHS runtime PID $pid to stop" >&2
        exit 8
      fi
      sleep 0.2
    done
    rm -f "$pid_file" "$ready_file" "$command_file" "${command_file}.running"
    echo "INFO: UVHS runtime stopped"
    ;;
  *)
    usage
    ;;
esac
