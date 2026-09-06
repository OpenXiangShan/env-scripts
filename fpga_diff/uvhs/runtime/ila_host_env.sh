#!/usr/bin/env bash

set -euo pipefail

runtime_host=${1-}
runtime_dir=${2-}
runtime_env=${3-}
cpu=${4-}
suffix=${5-}
project_name=${6-}
trigger=${7-}
position=${8-}
clock=${9-}
gated_clock=${10-}
timeout=${11-}
depth=${12-}

[[ -n $cpu ]] || {
  echo "ERROR: CPU is not set" >&2
  exit 1
}

quote_arg() {
  printf '%q' "$1"
}

make_command() {
  local target=$1
  shift
  local command argument

  command="make -C $(quote_arg "$runtime_dir") $target FPGA_BACKEND=uvhs"
  for argument in "$@"; do
    command+=" $(quote_arg "$argument")"
  done

  if [[ -n $runtime_host ]]; then
    printf 'ssh %q %q' "$runtime_host" "$runtime_env $command"
  else
    printf '%s' "$command"
  fi
}

arm_command=$(make_command ila_arm \
  "CPU=$cpu" "SUFFIX=$suffix" "PRJ_NAME=$project_name" \
  "UVHS_ILA_TRIGGER=$trigger" \
  "UVHS_ILA_POSITION=$position" "UVHS_ILA_CLOCK=$clock" \
  "UVHS_ILA_GATED_CLOCK=$gated_clock")
upload_command=$(make_command ila_upload \
  "CPU=$cpu" "SUFFIX=$suffix" "PRJ_NAME=$project_name" \
  "UVHS_ILA_TIMEOUT=$timeout" \
  "UVHS_ILA_DEPTH=$depth" "UVHS_ILA_CLOCK=$clock")
clear_command=$(make_command ila_clear \
  "CPU=$cpu" "SUFFIX=$suffix" "PRJ_NAME=$project_name")

# Preserve an upload failure while always releasing the capture and restoring
# any clock temporarily reduced for UHD bandwidth.
upload_and_clear_command="upload_status=0; $upload_command || upload_status=\$?;"
upload_and_clear_command+=" clear_status=0; $clear_command || clear_status=\$?;"
upload_and_clear_command+=" test \$upload_status -eq 0 || exit \$upload_status;"
upload_and_clear_command+=" exit \$clear_status"

printf 'export FPGA_ILA_ARM_CMD=%q\n' "$arm_command"
printf 'export FPGA_ILA_UPLOAD_CMD=%q\n' "$upload_and_clear_command"
