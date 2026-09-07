#!/usr/bin/env bash

set -euo pipefail

runtime_host=${FPGA_RUNTIME-}
runtime_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
remote_env=${REMOTE_ENV-}
cpu=${CPU-}
suffix=${SUFFIX-}
workload=${WORKLOAD-}
trigger=${UVHS_ILA_TRIGGER-}
position=${UVHS_ILA_POSITION-}
clock=${UVHS_ILA_CLOCK-}
gated_clock=${UVHS_ILA_GATED_CLOCK-}
timeout=${UVHS_ILA_TIMEOUT-}
depth=${UVHS_ILA_DEPTH-}

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
    printf 'ssh %q %q' "$runtime_host" "$remote_env $command"
  else
    printf '%s' "$command"
  fi
}

arm_command=$(make_command ila_arm \
  "CPU=$cpu" "SUFFIX=$suffix" \
  "UVHS_ILA_TRIGGER=$trigger" \
  "UVHS_ILA_POSITION=$position" "UVHS_ILA_CLOCK=$clock" \
  "UVHS_ILA_GATED_CLOCK=$gated_clock")
upload_command=$(make_command ila_upload \
  "CPU=$cpu" "SUFFIX=$suffix" \
  "UVHS_ILA_TIMEOUT=$timeout" \
  "UVHS_ILA_DEPTH=$depth" "UVHS_ILA_CLOCK=$clock")
clear_command=$(make_command ila_clear \
  "CPU=$cpu" "SUFFIX=$suffix")

# Preserve an upload failure while always releasing capture state and restoring
# any clock temporarily reduced for UHD bandwidth.
upload_and_clear_command="upload_status=0; $upload_command || upload_status=\$?;"
upload_and_clear_command+=" clear_status=0; $clear_command || clear_status=\$?;"
upload_and_clear_command+=" test \$upload_status -eq 0 || exit \$upload_status;"
upload_and_clear_command+=" exit \$clear_status"

printf 'export FPGA_ILA_ARM_CMD=%q\n' "$arm_command"
printf 'export FPGA_ILA_UPLOAD_CMD=%q\n' "$upload_and_clear_command"

if [[ -n $workload ]]; then
  write_ddr_command=$(make_command write_ddr \
    "CPU=$cpu" "SUFFIX=$suffix" "WORKLOAD=$workload")
  reset_cpu_command=$(make_command reset_cpu \
    "CPU=$cpu" "SUFFIX=$suffix")
  printf 'export FPGA_DDR_LOAD_CMD=%q\n' \
    "$write_ddr_command && $reset_cpu_command"
fi
