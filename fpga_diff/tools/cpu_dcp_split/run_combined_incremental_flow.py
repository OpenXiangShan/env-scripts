#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import shlex
import subprocess
from pathlib import Path

import flow_common as flow


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run whole-project incremental compile and CPU-DCP hot-path flows "
            "for the same baseline and modified releases."
        )
    )
    parser.add_argument("--baseline-release", required=True)
    parser.add_argument("--modified-release", required=True)
    parser.add_argument("--cpu", choices=["kmh", "nanhu", "nutshell"])
    parser.add_argument("--module")
    parser.add_argument("--cpu-instance")
    parser.add_argument("--cpu-cell")
    parser.add_argument("--subpartition-preset", choices=["frontend-backend"])
    parser.add_argument("--out-dir")
    parser.add_argument("--vivado")
    parser.add_argument("--jobs")
    parser.add_argument("--stop-after", choices=["route", "bitstream"], default="route")
    parser.add_argument(
        "--synth-incremental-mode",
        choices=["quick", "default", "aggressive", "off"],
        default="default",
    )
    parser.add_argument(
        "--impl-directive",
        choices=["Default", "RuntimeOptimized"],
        default="RuntimeOptimized",
    )
    parser.add_argument("--extra-args", default="")
    parser.add_argument("--whole-extra-args", default="")
    parser.add_argument("--cpu-dcp-extra-args", default="")
    return parser.parse_args()


def infer_cpu(paths: flow.FlowPaths, modified_release: Path) -> str:
    cpu = flow.infer_cpu_dcp_config(paths, modified_release, required=True).get("cpu", "")
    if not cpu:
        raise SystemExit(f"ERROR: could not infer CPU target from {modified_release}; pass --cpu explicitly.")
    print(f"INFO: inferred CPU target: {cpu}")
    return cpu


def run(cmd: list[str]) -> None:
    print("INFO:", shlex.join(cmd), flush=True)
    subprocess.run(cmd, check=True)


def main() -> int:
    args = parse_args()
    paths = flow.init_paths(__file__)
    baseline_release = Path(args.baseline_release).resolve()
    modified_release = Path(args.modified_release).resolve()
    flow.require_release_dirs(baseline_release, modified_release)

    cpu = args.cpu or infer_cpu(paths, modified_release)
    out_dir = flow.resolve_m(args.out_dir) if args.out_dir else (
        paths.repo_root
        / "build"
        / "fpga-diff-combined"
        / f"combined-{dt.datetime.now().strftime('%Y%m%d-%H%M%S')}"
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    whole_dir = out_dir / "whole-project"
    cpu_dcp_dir = out_dir / "cpu-dcp"

    common_extra = shlex.split(args.extra_args)
    whole_extra = shlex.split(args.whole_extra_args)
    cpu_dcp_extra = shlex.split(args.cpu_dcp_extra_args)
    vivado_arg = ["--vivado", args.vivado] if args.vivado else []
    jobs_arg = ["--jobs", args.jobs] if args.jobs else []
    module_arg = ["--module", args.module] if args.module else []
    cpu_instance_arg = ["--cpu-instance", args.cpu_instance] if args.cpu_instance else []
    cpu_cell_arg = ["--cpu-cell", args.cpu_cell] if args.cpu_cell else []
    partition_args = (
        ["--subpartition-preset", args.subpartition_preset]
        if args.subpartition_preset
        else ["--partition-module", "CpuDcpTop"]
    )

    print(f"INFO: [whole-project] output: {whole_dir}", flush=True)
    run(
        [
            str(paths.script_dir / "run_incremental_flow.py"),
            "--baseline-release",
            str(baseline_release),
            "--modified-release",
            str(modified_release),
            "--cpu",
            cpu,
            "--out-dir",
            str(whole_dir),
            "--stop-after",
            args.stop_after,
            "--synth-incremental-mode",
            args.synth_incremental_mode,
            "--impl-directive",
            args.impl_directive,
            *vivado_arg,
            *jobs_arg,
            *common_extra,
            *whole_extra,
        ]
    )

    print(f"INFO: [cpu-dcp] output: {cpu_dcp_dir}", flush=True)
    run(
        [
            str(paths.script_dir / "run_cpu_dcp_flow.py"),
            "--baseline-release",
            str(baseline_release),
            "--modified-release",
            str(modified_release),
            "--cpu",
            cpu,
            *module_arg,
            *cpu_instance_arg,
            *cpu_cell_arg,
            *partition_args,
            "--build-reference",
            "--out-dir",
            str(cpu_dcp_dir),
            "--stop-after",
            args.stop_after,
            "--synth-incremental-mode",
            args.synth_incremental_mode,
            "--impl-directive",
            args.impl_directive,
            *vivado_arg,
            *jobs_arg,
            *common_extra,
            *cpu_dcp_extra,
        ]
    )

    print(f"INFO: combined incremental flow complete: {out_dir}")
    print(f"INFO: whole-project output: {whole_dir}")
    print(f"INFO: CPU-DCP output: {cpu_dcp_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
