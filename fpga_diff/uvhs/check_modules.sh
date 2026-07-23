#!/usr/bin/env bash
set -euo pipefail

filelist=${1:-}
required_modules=${2:-}

if [[ -z "$filelist" || ! -f "$filelist" ]]; then
  echo "Verilog filelist not found: $filelist" >&2
  exit 2
fi

if [[ -z "$required_modules" ]]; then
  echo "No required modules configured; skip module check."
  exit 0
fi

tmp_sources=$(mktemp)
trap 'rm -f "$tmp_sources"' EXIT

awk 'NF && $0 !~ /^\+/ { print }' "$filelist" > "$tmp_sources"

missing=0
for module_name in $required_modules; do
  found=0
  module_source=
  while IFS= read -r source_file; do
    [[ -f "$source_file" ]] || continue
    if grep -Eq "^[[:space:]]*module[[:space:]]+$module_name([[:space:]#(]|$)" "$source_file"; then
      found=1
      module_source=$source_file
      break
    fi
  done < "$tmp_sources"

  if [[ "$found" == 1 ]]; then
    echo "Found required module: $module_name"
    if [[ "$module_name" == SimTop ]]; then
      for port in \
        difftest_to_host_axis_tdata difftest_from_host_axis_tdata \
        difftest_cfg_axilite_awaddr difftest_cfg_axilite_rready; do
        if ! grep -Fq "$port" "$module_source"; then
          echo "Missing required SimTop FPGA DiffTest port $port in $module_source" >&2
          missing=1
        fi
      done
    fi
  else
    echo "Missing required module: $module_name" >&2
    missing=1
  fi
done

if [[ "$missing" != 0 ]]; then
  echo "Required module check failed for $filelist" >&2
  exit 1
fi
