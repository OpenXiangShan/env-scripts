#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage:
  runtime_session.sh start <pid-file> <ready-file> <log-file> <command-file> \
    <timeout> <command> [argument ...]
  runtime_session.sh check <pid-file> [ready-file]
  runtime_session.sh enqueue <command-file> <timeout> <command> [argument ...]
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

write_pid() {
  local pid_file=$1
  local pid=$2
  local temp_file="${pid_file}.tmp.$$"
  printf '%s\n' "$pid" >"$temp_file"
  mv -f "$temp_file" "$pid_file"
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

tcl_quote() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//\$/\\\$}
  value=${value//\[/\\[}
  value=${value//\]/\\]}
  printf '"%s"' "$value"
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
    write_pid "$pid_file" "$pid"

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
    write_pid "$pid_file" "$runtime_pid"
    echo "INFO: UVHS runtime ready (PID $runtime_pid); log: $log_file"
    ;;
  check)
    (( $# == 1 || $# == 2 )) || usage
    pid_file=$1
    if ! pid=$(read_pid "$pid_file") || ! process_is_alive "$pid"; then
      rm -f "$pid_file"
      (( $# != 2 )) || rm -f "$2"
      echo "ERROR: UVHS runtime is not active; run make uvhs_write_bitstream first" >&2
      exit 6
    fi
    if (( $# == 2 )); then
      ready_file=$2
      if ! ready_pid=$(read_pid "$ready_file") || [[ $ready_pid != "$pid" ]]; then
        echo "ERROR: UVHS runtime PID $pid has no matching ready marker" >&2
        exit 7
      fi
      echo "INFO: UVHS runtime is ready (PID $pid)"
    else
      echo "INFO: UVHS runtime process is active (PID $pid)"
    fi
    ;;
  enqueue)
    (( $# >= 3 )) || usage
    command_file=$1
    timeout=$2
    shift 2
    validate_timeout "$timeout"
    if [[ -e $command_file || -e $command_file.running ]]; then
      echo "ERROR: a UVHS runtime command is already pending" >&2
      exit 9
    fi

    result_file="${command_file}.result.$$"
    temp_file="${command_file}.tmp.$$"
    mkdir -p "$(dirname "$command_file")"
    trap 'rm -f "$temp_file" "$result_file"' EXIT
    {
      printf 'set uvhs_result_file '
      tcl_quote "$result_file"
      printf '\nset argv [list'
      for argument in "$@"; do
        printf ' '
        tcl_quote "$argument"
      done
      printf ']\nuvhs_execute_command {*}$argv\n'
    } >"$temp_file"
    mv -n "$temp_file" "$command_file"
    [[ ! -e $temp_file ]] || {
      echo "ERROR: command file appeared while enqueueing: $command_file" >&2
      exit 10
    }
    echo "INFO: enqueued UVHS runtime command: $command_file"

    deadline=$((SECONDS + timeout))
    while [[ ! -f $result_file ]]; do
      if (( SECONDS >= deadline )); then
        echo "ERROR: timed out waiting for UVHS runtime command after ${timeout}s" >&2
        exit 11
      fi
      sleep 0.2
    done
    status=$(sed -n '1p' "$result_file")
    message=$(sed -n '2,$p' "$result_file")
    rm -f "$result_file"
    if [[ $status != 0 ]]; then
      echo "ERROR: UVHS runtime command failed: $message" >&2
      exit 12
    fi
    [[ -z $message ]] || echo "INFO: $message"
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
