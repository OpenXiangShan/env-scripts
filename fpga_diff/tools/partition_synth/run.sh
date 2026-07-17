#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
origin_dir="$(cd "$script_dir/../.." && pwd)"
out_dir=""
partitions=""
jobs_per_partition=""
parallel=16
project=""
project_runs=0
dry_run=0

usage() {
  cat <<'EOF'
Usage:
  tools/partition_synth/run.sh [options]

Options:
  --origin-dir DIR          fpga_diff directory, default is this script's parent
  --out-dir DIR             output directory, default partition-synth-<timestamp>
  --partitions LIST         comma-separated partitions; overrides list expansion
  --jobs-per-partition N    Vivado maxThreads per partition process
  --parallel N              max concurrent Vivado partition processes
  --project XPR             link partition DCPs into this top-level project
  --project-runs            create GUI-visible OOC runs in --project
  --dry-run                 validate file lists without launching synth_design
  --help                    show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --origin-dir)
      origin_dir="$(cd "$2" && pwd)"
      shift 2
      ;;
    --out-dir)
      out_dir="$2"
      shift 2
      ;;
    --partitions)
      partitions="$2"
      shift 2
      ;;
    --jobs-per-partition)
      jobs_per_partition="$2"
      shift 2
      ;;
    --parallel)
      parallel="$2"
      shift 2
      ;;
    --project)
      project="$(realpath "$2")"
      shift 2
      ;;
    --project-runs)
      project_runs=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! [[ "$parallel" =~ ^[0-9]+$ ]] || [[ "$parallel" -lt 1 ]]; then
  echo "ERROR: --parallel must be a positive integer" >&2
  exit 1
fi

if [[ -n "$jobs_per_partition" ]]; then
  if ! [[ "$jobs_per_partition" =~ ^[0-9]+$ ]] || [[ "$jobs_per_partition" -lt 1 ]]; then
    echo "ERROR: --jobs-per-partition must be a positive integer" >&2
    exit 1
  fi
fi

if [[ -n "$project" && ! -f "$project" ]]; then
  echo "ERROR: project not found: $project" >&2
  exit 1
fi

if [[ "$project_runs" -eq 1 && -z "$project" ]]; then
  echo "ERROR: --project-runs requires --project" >&2
  exit 1
fi

if [[ "$project_runs" -eq 1 && "$dry_run" -eq 1 ]]; then
  echo "ERROR: --project-runs cannot be used with --dry-run" >&2
  exit 1
fi

if [[ -z "$out_dir" ]]; then
  out_dir="$origin_dir/partition-synth-$(date +%Y%m%d-%H%M%S)"
fi

if [[ -z "$partitions" ]]; then
  if ! command -v tclsh >/dev/null 2>&1; then
    echo "ERROR: tclsh is required to expand partitions.tcl" >&2
    exit 1
  fi
  partitions="$(tclsh "$script_dir/defs.tcl" partitions)"
fi

mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"
log_dir="$out_dir/logs"
mkdir -p "$log_dir"

IFS=',' read -r -a partition_array <<< "$partitions"

echo "INFO: origin_dir=$origin_dir"
echo "INFO: out_dir=$out_dir"
echo "INFO: partitions=${partition_array[*]}"
echo "INFO: parallel=$parallel"
if [[ -n "$jobs_per_partition" ]]; then
  echo "INFO: jobs_per_partition=$jobs_per_partition"
fi
if [[ "$dry_run" -eq 1 ]]; then
  echo "INFO: dry_run=1"
fi
if [[ "$project_runs" -eq 1 ]]; then
  echo "INFO: project_runs=1"
fi

failed=0

wait_for_slot() {
  while (( $(jobs -rp | wc -l) >= parallel )); do
    wait -n || failed=1
  done
}

if [[ "$project_runs" -eq 1 ]]; then
  setup_args=(
    -mode batch
    -source "$script_dir/project_runs.tcl"
    -tclargs
    --project "$project"
    --origin-dir "$origin_dir"
    --out-dir "$out_dir"
    --partitions "$partitions"
  )
  if [[ -n "$jobs_per_partition" ]]; then
    setup_args+=(--jobs "$jobs_per_partition")
  fi

  echo "INFO: creating project OOC runs in $project"
  (cd "$origin_dir" && vivado "${setup_args[@]}") >"$log_dir/project_runs_setup.log" 2>&1

  manifest="$out_dir/project_runs/manifest.tsv"
  if [[ ! -s "$manifest" ]]; then
    echo "ERROR: missing project run manifest: $manifest" >&2
    exit 1
  fi

  declare -a project_partitions=()
  declare -a project_tops=()
  declare -a project_run_dirs=()
  while IFS=$'\t' read -r partition top_module run_name run_dir; do
    [[ -n "$partition" ]] || continue
    project_partitions+=("$partition")
    project_tops+=("$top_module")
    project_run_dirs+=("$run_dir")
    rm -f "$out_dir/$partition.dcp" \
      "$out_dir/${partition}_utilization_synth.rpt" \
      "$out_dir/${partition}_clocks_synth.rpt" \
      "$log_dir/${partition}.log"
    ln -s "$run_dir/runme.log" "$log_dir/${partition}.log"
  done < "$manifest"

  launch_args=(
    -mode batch
    -source "$script_dir/project_launch.tcl"
    -tclargs
    --project "$project"
    --manifest "$manifest"
    --parallel "$parallel"
  )
  echo "INFO: launching project OOC runs through Vivado"
  (cd "$origin_dir" && vivado "${launch_args[@]}") >"$log_dir/project_runs_launch.log" 2>&1
else
  for partition in "${partition_array[@]}"; do
    args=(
      -mode batch
      -source "$script_dir/synth.tcl"
      -tclargs
      --origin-dir "$origin_dir"
      --out-dir "$out_dir"
      --partition "$partition"
    )
    if [[ -n "$jobs_per_partition" ]]; then
      args+=(--jobs "$jobs_per_partition")
    fi
    if [[ "$dry_run" -eq 1 ]]; then
      args+=(--dry-run)
    fi

    echo "INFO: launching partition $partition"
    (cd "$origin_dir" && vivado "${args[@]}") >"$log_dir/${partition}.log" 2>&1 &
    wait_for_slot
  done
fi

while (( $(jobs -rp | wc -l) )); do
  wait -n || failed=1
done

if [[ "$failed" -ne 0 ]]; then
  echo "ERROR: one or more partitions failed; see $log_dir" >&2
  exit 1
fi

if [[ "$project_runs" -eq 1 ]]; then
  for index in "${!project_partitions[@]}"; do
    partition="${project_partitions[$index]}"
    top_module="${project_tops[$index]}"
    run_dir="${project_run_dirs[$index]}"
    run_dcp="$run_dir/$top_module.dcp"
    run_complete="$run_dir/__synthesis_is_complete__"
    if [[ ! -f "$run_dcp" || ! -f "$run_complete" ]]; then
      echo "ERROR: project run did not complete successfully: $partition" >&2
      failed=1
      continue
    fi
    cp -f "$run_dcp" "$out_dir/$partition.dcp"
  done
  if [[ "$failed" -ne 0 ]]; then
    exit 1
  fi
fi

if [[ -n "$project" && "$dry_run" -eq 0 ]]; then
  link_args=(
    -mode batch
    -source "$script_dir/link.tcl"
    -tclargs
    --out-dir "$out_dir"
  )

  echo "INFO: linking partition DCPs"
  (cd "$origin_dir" && vivado "${link_args[@]}") >"$log_dir/link.log" 2>&1

  project_link_args=(
    -mode batch
    -source "$script_dir/project_link.tcl"
    -tclargs
    --project "$project"
    --out-dir "$out_dir"
  )
  if [[ -n "$jobs_per_partition" ]]; then
    project_link_args+=(--jobs "$jobs_per_partition")
  fi

  echo "INFO: linking root partition into $project"
  (cd "$origin_dir" && vivado "${project_link_args[@]}") >"$log_dir/project_link.log" 2>&1
fi

echo "INFO: partition synthesis run finished: $out_dir"
