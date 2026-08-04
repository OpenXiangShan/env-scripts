#!/usr/bin/env bash
set -euo pipefail

TAG="${UVHS_RUN_TAG:?set the exact active UVHS_RUN_TAG}"
STAGE="${UVHS_STAGE_DIR:?set the exact active UVHS_STAGE_DIR}"
COMMAND_FILE="${UVHS_COMMAND_FILE:-$STAGE/commands/${TAG}.command.tcl}"
CAPTURE_SCRIPT="${UVHS_UHD_CAPTURE_SCRIPT:-$STAGE/user_script/hw_capture_uhd.tcl}"
TRIGGER_INI="${UVHS_UHD_TRIGGER_INI:-$STAGE/user_script/uhd_c2h.ini}"
WORKDIR="${UVHS_RUNTIME_WORKDIR:-$STAGE/workdir/$TAG}"
OUTPUT="${UVHS_UHD_OUTPUT:-uvhs_c2h_capture}"
DEPTH="${UVHS_UHD_CAPTURE_DEPTH:-20000}"
POSITION="${UVHS_UHD_TRIGGER_POSITION:-50}"
WAIT_SEC="${UVHS_UHD_TRIGGER_WAIT_SEC:-420}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

case "$TAG" in
  ''|*[!A-Za-z0-9_.-]*) die "invalid UVHS_RUN_TAG: $TAG" ;;
esac
for item in "UVHS_STAGE_DIR:$STAGE" "UVHS_COMMAND_FILE:$COMMAND_FILE" "UVHS_RUNTIME_WORKDIR:$WORKDIR"; do
  name="${item%%:*}"
  value="${item#*:}"
  case "$value" in
    *"$TAG"*) ;;
    *) die "$name must contain the exact tag '$TAG': $value" ;;
  esac
done
case "$OUTPUT" in
  ''|.|..|*[!A-Za-z0-9_.-]*) die "invalid UVHS_UHD_OUTPUT: $OUTPUT" ;;
esac
for item in "UVHS_UHD_CAPTURE_DEPTH:$DEPTH" "UVHS_UHD_TRIGGER_POSITION:$POSITION" "UVHS_UHD_TRIGGER_WAIT_SEC:$WAIT_SEC"; do
  name="${item%%:*}"
  value="${item#*:}"
  case "$value" in
    ''|*[!0-9]*|0*) die "$name must be a positive integer" ;;
  esac
done
test -f "$CAPTURE_SCRIPT" || die "capture script not found: $CAPTURE_SCRIPT"
test -f "$TRIGGER_INI" || die "trigger condition not found: $TRIGGER_INI"
if [ -e "$COMMAND_FILE" ] || [ -e "$COMMAND_FILE.running" ]; then
  die "runtime command is already queued or running: $COMMAND_FILE"
fi

mkdir -p "$(dirname "$COMMAND_FILE")"
tmp="${COMMAND_FILE}.tmp.$$"
trap 'rm -f "$tmp"' EXIT
printf 'set ::env(UVHS_RUNTIME_WORKDIR) {%s}\n' "$WORKDIR" >"$tmp"
printf 'set ::env(UVHS_UHD_TRIGGER_INI) {%s}\n' "$TRIGGER_INI" >>"$tmp"
printf 'set ::env(UVHS_UHD_OUTPUT) {%s}\n' "$OUTPUT" >>"$tmp"
printf 'set ::env(UVHS_UHD_CAPTURE_DEPTH) {%s}\n' "$DEPTH" >>"$tmp"
printf 'set ::env(UVHS_UHD_TRIGGER_POSITION) {%s}\n' "$POSITION" >>"$tmp"
printf 'set ::env(UVHS_UHD_TRIGGER_WAIT_SEC) {%s}\n' "$WAIT_SEC" >>"$tmp"
printf 'source {%s}\n' "$CAPTURE_SCRIPT" >>"$tmp"
mv -n "$tmp" "$COMMAND_FILE"
if [ -e "$tmp" ]; then
  die "command file appeared concurrently; capture was not queued"
fi
trap - EXIT
echo "queued_tag=$TAG"
echo "queued_command=$COMMAND_FILE"
echo "capture_output=$WORKDIR/UHD/$OUTPUT"
