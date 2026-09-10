#!/usr/bin/env bash

set -euo pipefail

runtime_host=${FPGA_RUNTIME-}
remote_env=${REMOTE_ENV-}

if [[ -z $runtime_host ]]; then
  printf 'export FPGA_UART_PORT=%q\n' /dev/ttyUSB0
  exit 0
fi

command -v socat >/dev/null || {
  echo "ERROR: socat is required on the FPGA host" >&2
  exit 2
}

host_uart="/tmp/fpga-remote-uart-${UID}-$$"
uart_log="${host_uart}.log"
remote_uart_check="$remote_env command -v fuser >/dev/null || {"
remote_uart_check+=" echo 'ERROR: fuser is required on the FPGA runtime' >&2; exit 127; };"
remote_uart_check+=" if fuser /dev/ttyUSB0 >/dev/null 2>&1; then"
remote_uart_check+=" echo 'ERROR: /dev/ttyUSB0 already has a reader' >&2;"
remote_uart_check+=" fuser -v /dev/ttyUSB0 >&2; exit 1; fi"
env LC_ALL=C ssh -T "$runtime_host" "$remote_uart_check"

remote_uart_command="$remote_env exec socat - /dev/ttyUSB0,rawer,b115200"
printf -v ssh_command 'env LC_ALL=C ssh -T %q %q' "$runtime_host" "$remote_uart_command"

socat -d -d "pty,link=$host_uart,rawer,echo=0,waitslave" \
  "EXEC:$ssh_command,nofork" </dev/null >"$uart_log" 2>&1 &
bridge_pid=$!

cleanup_bridge() {
  kill "$bridge_pid" 2>/dev/null || true
  rm -f -- "$host_uart" "$uart_log"
}
trap cleanup_bridge EXIT

for _ in {1..50}; do
  [[ -L $host_uart ]] && break
  kill -0 "$bridge_pid" 2>/dev/null || {
    cat "$uart_log" >&2
    echo "ERROR: failed to start UART bridge" >&2
    exit 1
  }
  sleep 0.1
done
[[ -L $host_uart ]] || {
  echo "ERROR: UART PTY was not created; see $uart_log" >&2
  exit 1
}

printf -v cleanup_command \
  'kill %q 2>/dev/null || true; rm -f -- %q %q' \
  "$bridge_pid" "$host_uart" "$uart_log"
printf 'export FPGA_UART_PORT=%q\n' "$host_uart"
printf 'export FPGA_HOST_CLEANUP_CMD=%q\n' "$cleanup_command"
trap - EXIT
