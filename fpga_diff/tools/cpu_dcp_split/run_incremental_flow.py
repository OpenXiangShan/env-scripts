#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path

import flow_common as flow


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build baseline and modified FpgaDiff Vivado projects and run "
            "whole-project incremental synthesis and implementation."
        )
    )
    parser.add_argument("--baseline-release", required=True)
    parser.add_argument("--modified-release", required=True)
    parser.add_argument("--cpu", choices=["kmh", "nutshell", "nanhu"], default="kmh")
    parser.add_argument("--jobs", default=os.environ.get("VIVADO_JOBS", ""))
    parser.add_argument("--out-dir")
    parser.add_argument("--vivado", default=os.environ.get("VIVADO", "vivado"))
    parser.add_argument("--stop-after", choices=["route", "bitstream"], default="bitstream")
    parser.add_argument(
        "--synth-incremental-mode",
        choices=["quick", "default", "aggressive", "off"],
        default="default",
    )
    parser.add_argument(
        "--impl-directive",
        choices=["Default", "RuntimeOptimized"],
        default="RuntimeOptimized",
        help="implementation directive for the routed checkpoint reuse path",
    )
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = flow.init_paths(__file__)
    flow.require_positive_int("--jobs", args.jobs or None)
    jobs = flow.default_jobs(args.jobs or None)

    baseline_release = Path(args.baseline_release).resolve()
    modified_release = Path(args.modified_release).resolve()
    flow.require_release_dirs(baseline_release, modified_release)

    vivado_cmd = flow.resolve_vivado(args.vivado, args.dry_run)
    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    out_dir = flow.resolve_m(args.out_dir) if args.out_dir else (
        paths.repo_root / "build" / "fpga-diff-incremental" / f"{timestamp}-{args.cpu}"
    )
    (out_dir / "logs").mkdir(parents=True, exist_ok=True)
    (out_dir / "checkpoints").mkdir(parents=True, exist_ok=True)

    base_suffix = f"inc-base-{timestamp}"
    diff_suffix = f"inc-diff-{timestamp}"
    base_prj_name = f"fpga_{args.cpu}-{base_suffix}"
    diff_prj_name = f"fpga_{args.cpu}-{diff_suffix}"
    base_xpr = paths.fpga_diff_dir / base_prj_name / f"{base_prj_name}.xpr"
    diff_xpr = paths.fpga_diff_dir / diff_prj_name / f"{diff_prj_name}.xpr"
    base_synth_dcp = out_dir / "checkpoints" / "base-synth.dcp"
    base_impl_dcp = out_dir / "checkpoints" / "base-routed.dcp"

    runner = flow.FlowRunner(out_dir, dry_run=args.dry_run)

    def fpga_make(target: str, suffix: str, core_dir: Path | None = None) -> list[str]:
        return flow.make_cmd(
            paths.fpga_diff_dir,
            target,
            args.cpu,
            suffix,
            core_dir=core_dir,
            jobs=jobs if target != "all" else None,
        )

    def write_manifest() -> None:
        flow.write_lines(
            out_dir / "manifest.env",
            [
                f"repo_root={paths.repo_root}",
                f"cpu={args.cpu}",
                f"jobs={jobs}",
                f"baseline_release={baseline_release}",
                f"modified_release={modified_release}",
                f"baseline_project={base_xpr}",
                f"incremental_project={diff_xpr}",
                f"baseline_synth_dcp={base_synth_dcp}",
                f"baseline_impl_dcp={base_impl_dcp}",
                f"dry_run={int(args.dry_run)}",
                f"stop_after={args.stop_after}",
                f"synth_incremental_mode={args.synth_incremental_mode}",
                f"implementation_directive={args.impl_directive}",
                f"vivado_command={vivado_cmd}",
                f"vivado_version={flow.vivado_version(vivado_cmd, args.dry_run)}",
            ],
        )

    write_manifest()

    runner.run(
        "baseline-project",
        fpga_make("all", base_suffix, baseline_release / "build"),
    )
    runner.run(
        "baseline-synth",
        flow.vivado_batch_cmd(
            vivado_cmd,
            paths.script_dir / "run_incremental_synth_checkpoint.tcl",
            base_xpr,
            base_synth_dcp,
            "synth_1",
            jobs,
        ),
    )
    if args.stop_after == "route":
        runner.run(
            "baseline-route",
            fpga_make("route", base_suffix),
        )
    else:
        runner.run(
            "baseline-bitstream",
            fpga_make("bitstream", base_suffix),
        )
    runner.run(
        "baseline-impl-dcp",
        flow.vivado_batch_cmd(
            vivado_cmd,
            paths.script_dir / "write_run_checkpoint.tcl",
            base_xpr,
            "impl_1",
            base_impl_dcp,
        ),
    )
    runner.run(
        "incremental-project",
        fpga_make("all", diff_suffix, modified_release / "build"),
    )
    runner.run(
        "incremental-run",
        flow.vivado_batch_cmd(
            vivado_cmd,
            paths.script_dir / "run_incremental_impl.tcl",
            diff_xpr,
            base_impl_dcp,
            "impl_1",
            jobs,
            base_synth_dcp,
            args.synth_incremental_mode,
            args.stop_after,
            args.impl_directive,
        ),
    )

    print(f"INFO: whole-project incremental flow complete: {out_dir}")
    print(f"INFO: incremental project: {diff_xpr}")
    print(f"INFO: incremental reports: {diff_xpr.parent / 'incremental-reports' / 'impl_1'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
