#!/usr/bin/env bash
set -euo pipefail

if [[ ${1-} == --cleanup ]]; then
  session=$2
  if [[ -p $session/control ]]; then
    timeout 5 bash -c 'exec 3<> "$1"; printf "stop\n" >&3' _ "$session/control" || true
  fi
  for _ in {1..50}; do
    [[ ! -f $session/daemon.log ]] && break
    grep -qx STOPPED "$session/daemon.log" && break
    sleep 0.1
  done
  rm -rf -- "$session"
  exit 0
fi
board=${XDMA_RELAY_BOARD-}
if [[ -z $board ]]; then
  echo 'ERROR: XDMA_RELAY_BOARD is required' >&2
  exit 2
fi
[[ ${DIFFTEST_HOSTIF:-XDMA} == XDMA ]] || {
  echo 'ERROR: XDMA relay requires DIFFTEST_HOSTIF=XDMA' >&2; exit 2;
}
listen=${XDMA_RELAY_LISTEN-}
port=${XDMA_RELAY_PORT:-55273}
daemon=${XDMA_RELAY_DAEMON:-fpga-xdma-relay}
[[ $port =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]] || {
  echo 'ERROR: XDMA_RELAY_PORT must be 1..65535' >&2
  exit 2
}
[[ ${XDMA_RELAY_ZSTD:-1} == 0 || ${XDMA_RELAY_ZSTD:-1} == 1 ]] || {
  echo 'ERROR: XDMA_RELAY_ZSTD must be 0 or 1' >&2; exit 2;
}
backend_env=
if (( $# )); then backend_env=$("$@"); eval "$backend_env"; fi
backend_cleanup=${FPGA_HOST_CLEANUP_CMD-:}
session=$(mktemp -d "${TMPDIR:-/tmp}/fpga-xdma-relay.XXXXXXXX")
chmod 700 "$session"
script=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/host_env.sh
cleanup() {
  bash "$script" --cleanup "$session"
  eval "$backend_cleanup"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
# The token travels over SSH stdin, never arguments or shell output.
umask 077
od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > "$session/token"
printf '\n' >> "$session/token"
mkfifo "$session/control"
remote_script=$(cat <<'REMOTE'
set -euo pipefail
session=$(mktemp -d /tmp/fpga-xdma-relay.XXXXXXXX)
umask 077
pid=
cleanup() {
  if [[ -n $pid ]]; then
    kill "$pid" 2>/dev/null || true
    for _ in {1..30}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf -- "$session"
  printf 'STOPPED\n'
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
read -r token
printf '%s\n' "$token" > "$session/token"
unset token
daemon=$(command -v -- "$1") && [[ -x $daemon ]] || {
  echo 'ERROR: relay daemon is not executable or not in PATH' >&2; exit 2;
}
connect=$2
if [[ -z $connect ]]; then
  connect=${SSH_CONNECTION-}
  connect=${connect%% *}
fi
[[ -n $connect ]] || { echo 'ERROR: set XDMA_RELAY_LISTEN for the board connection' >&2; exit 2; }
command -v fuser >/dev/null || { echo 'ERROR: fuser is required on the XDMA board host' >&2; exit 2; }
for device in /dev/xdma0_user /dev/xdma0_h2c_* /dev/xdma0_c2h_*; do
  [[ -e $device ]] || continue
  if fuser "$device" >/dev/null 2>&1; then
    echo "ERROR: XDMA device is already in use: $device" >&2; exit 2
  fi
done
args=(--connect "$connect" --port "$3" --token-file "$session/token")
[[ $4 == 0 ]] || args+=(--zstd)
"$daemon" "${args[@]}" &
pid=$!
printf 'LISTEN=%s\n' "$connect"
printf 'READY\n'
# A failed daemon releases its session even if the compute host never starts.
while kill -0 "$pid" 2>/dev/null; do
  status=0
  read -r -t 1 stop || status=$?
  [[ $status == 0 || $status == 1 ]] && break
done
REMOTE
)
printf -v remote_command 'bash -c %q -- %q %q %q %q' \
  "$remote_script" "$daemon" "$listen" "$port" "${XDMA_RELAY_ZSTD:-1}"
# Keep stdin open until cleanup writes stop; never detach the daemon.
exec 3<> "$session/control"
cat "$session/token" >&3
# A shell retains the FIFO writer; OpenSSH itself closes extra descriptors.
(
  ssh -T -o BatchMode=yes -o ConnectTimeout=10 \
    -o ServerAliveInterval=5 -o ServerAliveCountMax=2 "$board" "$remote_command" \
    < "$session/control" 3>&- &
  child=$!
  trap 'kill "$child" 2>/dev/null || true; wait "$child" 2>/dev/null || true' EXIT
  trap 'exit 1' HUP INT TERM
  wait "$child"
) > "$session/daemon.log" 2>&1 &
ssh_pid=$!
exec 3>&-
for _ in {1..150}; do
  if grep -qx READY "$session/daemon.log"; then break; fi
  if ! kill -0 "$ssh_pid" 2>/dev/null; then
    cat "$session/daemon.log" >&2
    echo 'ERROR: XDMA relay startup failed' >&2; exit 1
  fi
  sleep 0.1
done
if ! grep -qx READY "$session/daemon.log"; then
  cat "$session/daemon.log" >&2
  echo 'ERROR: timed out starting XDMA relay over SSH' >&2
  kill "$ssh_pid" 2>/dev/null || true
  exit 1
fi
if [[ -z $listen ]]; then
  listen=$(sed -n 's/^LISTEN=//p' "$session/daemon.log")
fi
printf '%s\n' "$backend_env"
printf 'export XDMA_RELAY_LISTEN=%q\n' "$listen"
printf 'export XDMA_RELAY_PORT=%q\n' "$port"
printf 'export XDMA_RELAY_TOKEN_FILE=%q\n' "$session/token"
printf 'export XDMA_RELAY_LOG=%q\n' "$session/daemon.log"
printf -v relay_cleanup 'bash %q --cleanup %q' "$script" "$session"
printf 'export FPGA_HOST_CLEANUP_CMD=%q\n' "$relay_cleanup; $backend_cleanup"
trap - EXIT
