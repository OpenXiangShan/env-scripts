#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import os
import shutil
import sys
from pathlib import Path

import flow_common as flow


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the CPU-DCP split flow for FpgaDiff."
    )
    parser.add_argument("--baseline-release", required=True)
    parser.add_argument("--modified-release", required=True)
    parser.add_argument("--reference-routed-dcp")
    parser.add_argument("--reference-synth-dcp")
    parser.add_argument(
        "--reference-fingerprint",
        help="fingerprint JSON created with the routed reference DCP; reject incompatible reuse",
    )
    parser.add_argument("--cpu", choices=["kmh", "nanhu", "nutshell"])
    parser.add_argument("--module", dest="cpu_module")
    parser.add_argument("--cpu-instance")
    parser.add_argument("--partition-module")
    parser.add_argument("--subpartition-preset", choices=["frontend-backend"])
    parser.add_argument("--cpu-cell")
    parser.add_argument("--cpu-dcp")
    parser.add_argument("--out-dir")
    parser.add_argument("--vivado", default=os.environ.get("VIVADO", "vivado"))
    parser.add_argument("--jobs", default=os.environ.get("VIVADO_JOBS", ""))
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
        help="directive for incremental placement and routing after CPU-DCP import",
    )
    parser.add_argument("--build-reference", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.subpartition_preset and args.partition_module:
        parser.error("--subpartition-preset and --partition-module are mutually exclusive")
    return args


def main() -> int:
    args = parse_args()
    paths = flow.init_paths(__file__)
    flow.require_positive_int("--jobs", args.jobs or None)
    jobs = flow.default_jobs(args.jobs or None)

    baseline_release = Path(args.baseline_release).resolve()
    modified_release = Path(args.modified_release).resolve()
    flow.require_release_dirs(baseline_release, modified_release)

    inferred: dict[str, str] = {}
    if not args.cpu_module or not args.cpu_instance or not args.cpu_cell or not args.cpu:
        inferred = flow.infer_cpu_dcp_config(paths, modified_release, args.cpu)

    cpu = args.cpu or inferred.get("cpu") or "kmh"
    if cpu not in {"kmh", "nanhu", "nutshell"}:
        raise SystemExit(f"ERROR: --cpu must be kmh, nanhu, or nutshell, got {cpu}")
    cpu_module = args.cpu_module or inferred.get("cpu_module") or ("NutShell" if cpu == "nutshell" else "XSTop")
    cpu_instance = args.cpu_instance or inferred.get("cpu_instance") or "cpu"
    cpu_cell = args.cpu_cell or inferred.get("cpu_cell") or ""
    if not cpu_cell and cpu == "nutshell":
        cpu_cell = f"core_def/U_CPU_TOP/u_SimTop/{cpu_instance}"
    if not cpu_cell:
        raise SystemExit(
            f"ERROR: could not infer --cpu-cell for cpu={cpu}.\n"
            "Pass --cpu-cell explicitly, for example core_def/U_CPU_TOP/<SimTop-wrapper-instance>/cpu."
        )

    reference_routed_dcp = Path(args.reference_routed_dcp).resolve() if args.reference_routed_dcp else None
    if reference_routed_dcp and not reference_routed_dcp.is_file():
        raise SystemExit(f"ERROR: reference routed DCP not found: {reference_routed_dcp}")
    if not reference_routed_dcp and not args.build_reference:
        raise SystemExit("ERROR: pass --reference-routed-dcp or --build-reference")
    reference_synth_dcp_arg = Path(args.reference_synth_dcp).resolve() if args.reference_synth_dcp else None
    if reference_synth_dcp_arg and not reference_synth_dcp_arg.is_file():
        raise SystemExit(f"ERROR: reference synthesis DCP not found: {reference_synth_dcp_arg}")

    cpu_dcp_arg = Path(args.cpu_dcp).resolve() if args.cpu_dcp and not args.subpartition_preset else None
    if cpu_dcp_arg and not cpu_dcp_arg.is_file():
        raise SystemExit(f"ERROR: CPU DCP not found: {cpu_dcp_arg}")

    vivado_cmd = flow.resolve_vivado(args.vivado, args.dry_run)
    timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    out_dir = flow.resolve_m(args.out_dir) if args.out_dir else (
        paths.repo_root / "build" / "fpga-diff-cpu-dcp" / cpu / f"split-{timestamp}"
    )
    for d in ("logs", "checkpoints", "releases"):
        (out_dir / d).mkdir(parents=True, exist_ok=True)

    cpu_ooc_dir = out_dir / "cpu-ooc"
    cpu_dcp = cpu_dcp_arg or (cpu_ooc_dir / "cpu-synth.dcp")
    subpartition_dir = out_dir / "subpartitions"
    subpartition_plan_json = subpartition_dir / "partitions.json"
    subpartition_current_import_tsv = subpartition_dir / "current-import.tsv"
    subpartition_reference_import_tsv = subpartition_dir / "reference-import.tsv"
    subpartition_current_build_tsv = subpartition_dir / "current-build.tsv"
    subpartition_reference_build_tsv = subpartition_dir / "reference-build.tsv"
    overlay_release = out_dir / "releases" / "modified-cpu-bb"
    partition_ooc_release = out_dir / "releases" / "baseline-cpu-partition-ooc"
    reference_partition_release = out_dir / "releases" / "baseline-cpu-partition-top"
    overlay_core_dir = overlay_release / "build"
    cpu_ooc_release = baseline_release
    cpu_ooc_top = cpu_module
    overlay_module = cpu_module

    reference_suffix = f"cpu-dcp-ref-{timestamp}"
    if args.partition_module:
        overlay_release = out_dir / "releases" / "modified-cpu-partition-top"
        overlay_core_dir = overlay_release / "build"
        cpu_ooc_top = args.partition_module
        overlay_module = args.partition_module
        overlay_suffix = f"cpu-dcp-part-{timestamp}"
    else:
        overlay_suffix = f"cpu-dcp-bb-{timestamp}"
    if args.subpartition_preset:
        overlay_release = out_dir / "releases" / "modified-cpu-subpartition-top"
        overlay_core_dir = overlay_release / "build"
        overlay_module = cpu_module
        overlay_suffix = f"cpu-dcp-subpart-{timestamp}"
        reference_partition_release = out_dir / "releases" / "baseline-cpu-subpartition-top"

    import_cell_arg = cpu_cell
    import_dcp_arg = str(cpu_dcp)
    reference_import_cell_arg = cpu_cell
    reference_import_dcp_arg = str(cpu_dcp)
    if args.subpartition_preset:
        import_cell_arg = f"@{subpartition_current_import_tsv}"
        import_dcp_arg = "-"
        reference_import_cell_arg = f"@{subpartition_reference_import_tsv}"
        reference_import_dcp_arg = "-"
        cpu_dcp = subpartition_current_import_tsv

    reference_prj_name = f"fpga_{cpu}-{reference_suffix}"
    overlay_prj_name = f"fpga_{cpu}-{overlay_suffix}"
    reference_xpr = paths.fpga_diff_dir / reference_prj_name / f"{reference_prj_name}.xpr"
    overlay_xpr = paths.fpga_diff_dir / overlay_prj_name / f"{overlay_prj_name}.xpr"
    if not reference_routed_dcp and args.build_reference:
        reference_routed_dcp = out_dir / "checkpoints" / "reference-routed.dcp"
    reference_synth_dcp = reference_synth_dcp_arg or (out_dir / "checkpoints" / "reference-synth.dcp")
    if not reference_synth_dcp_arg and reference_routed_dcp and reference_routed_dcp.name == "reference-routed.dcp":
        sibling_synth_dcp = reference_routed_dcp.with_name("reference-synth.dcp")
        if sibling_synth_dcp.is_file():
            reference_synth_dcp = sibling_synth_dcp

    def dry_skip(label: str) -> bool:
        run_in_dry = {
            "rtl-diff",
            "cpu-dcp-interface",
            "cpu-ooc-dcp",
            "cpu-subpartition-plan",
            "cpu-partition-ooc-overlay",
            "cpu-partition-top-overlay",
            "reference-partition-top-overlay",
            "reference-subpartition-top-overlay",
            "cpu-subpartition-top-overlay",
            "reference-synth-dcp",
            "implementation-fingerprint",
        }
        return label not in run_in_dry

    runner = flow.FlowRunner(out_dir, dry_run=args.dry_run, dry_skip=dry_skip)
    vivado_version = flow.vivado_version(vivado_cmd, args.dry_run)

    def write_manifest() -> None:
        flow.write_lines(
            out_dir / "manifest.env",
            [
                f"repo_root={paths.repo_root}",
                f"cpu={cpu}",
                f"cpu_module={cpu_module}",
                f"cpu_instance={cpu_instance}",
                f"cpu_cell={cpu_cell}",
                f"subpartition_preset={args.subpartition_preset or ''}",
                f"subpartition_plan={subpartition_plan_json}",
                f"subpartition_current_import={subpartition_current_import_tsv}",
                f"subpartition_reference_import={subpartition_reference_import_tsv}",
                f"jobs={jobs}",
                f"baseline_release={baseline_release}",
                f"modified_release={modified_release}",
                f"overlay_release={overlay_release}",
                f"partition_module={args.partition_module or ''}",
                f"overlay_module={overlay_module}",
                f"cpu_ooc_release={cpu_ooc_release}",
                f"cpu_ooc_top={cpu_ooc_top}",
                f"reference_project={reference_xpr}",
                f"overlay_project={overlay_xpr}",
                f"reference_routed_dcp={reference_routed_dcp or ''}",
                f"reference_synth_dcp={reference_synth_dcp}",
                f"reference_fingerprint={args.reference_fingerprint or ''}",
                f"cpu_dcp={cpu_dcp}",
                f"stop_after={args.stop_after}",
                f"synth_incremental_mode={args.synth_incremental_mode}",
                f"implementation_directive={args.impl_directive}",
                f"build_reference={int(args.build_reference)}",
                f"dry_run={int(args.dry_run)}",
                f"vivado_command={vivado_cmd}",
                f"vivado_version={vivado_version}",
            ],
        )

    def capture_reference_synth_dcp(project_xpr: Path) -> None:
        run_dcp = Path(str(project_xpr).removesuffix(".xpr") + ".runs/synth_1/fpga_top_debug.dcp")
        log_file = out_dir / "logs" / "reference-synth-dcp.log"
        time_file = out_dir / "logs" / "reference-synth-dcp.time"
        if args.dry_run:
            flow.write_lines(
                log_file,
                [
                    f"dry_run_command=capture_reference_synth_dcp {project_xpr}",
                    f"expected_source={run_dcp}",
                    f"target={reference_synth_dcp}",
                ],
            )
            flow.write_lines(time_file, ["elapsed_sec=", "mode=dry-run"])
            return
        if run_dcp.is_file():
            shutil.copy2(run_dcp, reference_synth_dcp)
            flow.write_lines(log_file, ["Copied reference synthesis DCP", f"source={run_dcp}", f"target={reference_synth_dcp}"])
            flow.write_lines(time_file, ["elapsed_sec=", "mode=copied-project-synth-dcp", f"source={run_dcp}"])
        else:
            runner.run(
                "reference-synth-dcp",
                flow.vivado_batch_cmd(
                    vivado_cmd,
                    paths.script_dir / "write_run_checkpoint.tcl",
                    project_xpr,
                    "synth_1",
                    reference_synth_dcp,
                    "normal",
                ),
            )

    def fpga_make(target: str, suffix: str, core_dir: Path | None = None) -> list[str]:
        jobs_arg = jobs if target != "all" else None
        return flow.make_cmd(paths.fpga_diff_dir, target, cpu, suffix, core_dir=core_dir, jobs=jobs_arg)

    def run_reference_project(core_dir: Path) -> None:
        runner.run("reference-project", fpga_make("all", reference_suffix, core_dir))
        runner.run("reference-synth", fpga_make("synth", reference_suffix))
        capture_reference_synth_dcp(reference_xpr)

    def write_reference_import_checkpoint() -> None:
        source = out_dir / "reference-import-impl" / "post-route-cpu-dcp-import.dcp"
        if args.dry_run:
            with (out_dir / "logs" / "reference-routed-dcp.log").open("a", encoding="utf-8") as f:
                f.write(f"dry_run_reference_routed_dcp={reference_routed_dcp}\n")
                f.write(f"expected_source={source}\n")
        else:
            shutil.copy2(source, reference_routed_dcp)

    def run_reference_import(cell_arg: str, dcp_arg: str) -> None:
        runner.run(
            "reference-routed-dcp",
            flow.vivado_batch_cmd(
                vivado_cmd,
                paths.script_dir / "cpu_dcp_import.tcl",
                "impl",
                reference_xpr,
                cell_arg,
                dcp_arg,
                "synth_1",
                out_dir / "reference-import-impl",
                "",
                "route",
            ),
        )
        write_reference_import_checkpoint()

    def run_checkpoint_writer(label: str, project_xpr: Path, run_name: str, checkpoint: Path) -> None:
        runner.run(
            label,
            flow.vivado_batch_cmd(
                vivado_cmd,
                paths.script_dir / "write_run_checkpoint.tcl",
                project_xpr,
                run_name,
                checkpoint,
            ),
        )

    def partition_overlay_cmd(release: Path, mode: str, out_release: Path) -> list[str]:
        cmd = [
            str(paths.script_dir / "create_cpu_partition_overlay.py"),
            "--release",
            str(release),
            "--cpu-module",
            cpu_module,
            "--mode",
            mode,
            "--out-dir",
            str(out_release),
            "--force",
        ]
        if args.partition_module:
            cmd.extend(["--cpu-instance", cpu_instance, "--partition-module", args.partition_module])
        return cmd

    def subpartition_overlay_cmd(release: Path, out_release: Path, json_out: Path) -> list[str]:
        return [
            str(paths.script_dir / "cpu_subpartition.py"),
            "overlay",
            "--release",
            str(release),
            "--partitions-json",
            str(subpartition_plan_json),
            "--out-dir",
            str(out_release),
            "--force",
            "--json-out",
            str(json_out),
        ]

    def build_subpartition_dcps(label_prefix: str, build_tsv: Path) -> None:
        if not build_tsv.is_file():
            return
        for line in build_tsv.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            role, module, source_release, part_out_dir, dcp_path = line.split("\t")[:5]
            dcp = Path(dcp_path)
            if dcp.is_file():
                flow.write_empty_stage(out_dir, f"{label_prefix}-{role}", f"Using existing {role} DCP: {dcp}")
                continue
            cmd = [
                str(paths.script_dir / "build_cpu_ooc_dcp.py"),
                "--release",
                source_release,
                "--cpu",
                cpu,
                "--top",
                module,
                "--out-dir",
                part_out_dir,
                "--vivado",
                vivado_cmd,
            ]
            if args.dry_run:
                cmd.append("--dry-run")
            runner.run(f"{label_prefix}-{role}", cmd)

    write_manifest()
    fingerprint_cmd = [
        sys.executable, str(paths.script_dir / "implementation_fingerprint.py"),
        "--baseline-release", str(baseline_release),
        "--modified-release", str(modified_release),
        "--fpga-diff-dir", str(paths.fpga_diff_dir),
        "--cpu", cpu,
        "--cpu-module", cpu_module,
        "--partition-module", args.partition_module or cpu_module,
        "--cpu-cell", cpu_cell,
        "--vivado-version", vivado_version,
        "--synth-incremental-mode", args.synth_incremental_mode,
        "--impl-directive", args.impl_directive,
        "--stop-after", args.stop_after,
        "--reference-routed-dcp", str(reference_routed_dcp or ""),
        "--reference-synth-dcp", str(reference_synth_dcp),
        "--out", str(out_dir / "implementation-fingerprint.json"),
    ]
    if args.reference_fingerprint:
        fingerprint_cmd.extend([
            "--reference-fingerprint", args.reference_fingerprint,
            "--require-reference-compatible",
        ])
    runner.run("implementation-fingerprint", fingerprint_cmd)

    runner.run(
        "rtl-diff",
        [str(paths.script_dir / "check_cpu_dcp_reuse.py"), str(baseline_release), str(modified_release), str(out_dir / "rtl-diff")],
    )
    gate_json = out_dir / "rtl-diff" / "cpu-difftest-gate.json"
    gate_rc = flow.read_json(gate_json).get("exit_code", 3)
    if gate_rc == 1 and not args.subpartition_preset:
        raise SystemExit("ERROR: CPU-DCP reuse gate failed because CPU RTL changed")
    if gate_rc == 1 and args.subpartition_preset:
        print(
            "WARNING: CPU-DCP whole-CPU reuse gate failed; "
            f"subpartition plan will check whether CPU changes are covered by {args.subpartition_preset}."
        )
    elif gate_rc == 2:
        print("WARNING: CPU-DCP reuse gate needs manual review; continuing.")
    elif gate_rc != 0:
        raise SystemExit(gate_rc)

    if args.subpartition_preset:
        subpartition_dir.mkdir(parents=True, exist_ok=True)
        runner.run(
            "cpu-subpartition-plan",
            [
                str(paths.script_dir / "cpu_subpartition.py"),
                "plan",
                "--baseline-release",
                str(baseline_release),
                "--modified-release",
                str(modified_release),
                "--cpu-module",
                cpu_module,
                "--cpu-cell",
                cpu_cell,
                "--preset",
                args.subpartition_preset,
                "--dcp-root",
                str(subpartition_dir / "dcp"),
                "--json-out",
                str(subpartition_plan_json),
                "--current-import-tsv",
                str(subpartition_current_import_tsv),
                "--reference-import-tsv",
                str(subpartition_reference_import_tsv),
                "--current-build-tsv",
                str(subpartition_current_build_tsv),
                "--reference-build-tsv",
                str(subpartition_reference_build_tsv),
                "--module-boundary-csv",
                str(out_dir / "rtl-diff" / "module-boundary.csv"),
                "--file-summary-csv",
                str(out_dir / "rtl-diff" / "summary.csv"),
            ],
        )
        build_subpartition_dcps("cpu-subpartition-ooc-reference", subpartition_reference_build_tsv)
        build_subpartition_dcps("cpu-subpartition-ooc-current", subpartition_current_build_tsv)
    elif Path(cpu_dcp).is_file():
        flow.write_empty_stage(out_dir, "cpu-ooc-dcp", f"Using existing CPU DCP: {cpu_dcp}")
    else:
        if args.partition_module:
            runner.run(
                "cpu-partition-ooc-overlay",
                partition_overlay_cmd(baseline_release, "ooc", partition_ooc_release),
            )
            cpu_ooc_release = partition_ooc_release
            write_manifest()
        cpu_ooc_cmd = [
            str(paths.script_dir / "build_cpu_ooc_dcp.py"),
            "--release",
            str(cpu_ooc_release),
            "--cpu",
            cpu,
            "--top",
            cpu_ooc_top,
            "--out-dir",
            str(cpu_ooc_dir),
            "--vivado",
            vivado_cmd,
        ]
        if args.dry_run:
            cpu_ooc_cmd.append("--dry-run")
        runner.run("cpu-ooc-dcp", cpu_ooc_cmd)

    if args.build_reference and reference_routed_dcp and not reference_routed_dcp.is_file():
        if args.subpartition_preset:
            runner.run(
                "reference-subpartition-top-overlay",
                subpartition_overlay_cmd(
                    baseline_release,
                    reference_partition_release,
                    out_dir / "subpartitions" / "reference-overlay.json",
                ),
            )
            run_reference_project(reference_partition_release / "build")
            run_reference_import(reference_import_cell_arg, reference_import_dcp_arg)
        elif args.partition_module:
            runner.run(
                "reference-partition-top-overlay",
                partition_overlay_cmd(baseline_release, "top", reference_partition_release),
            )
            run_reference_project(reference_partition_release / "build")
            run_reference_import(cpu_cell, str(cpu_dcp))
        else:
            run_reference_project(baseline_release / "build")
            runner.run("reference-bitstream", fpga_make("bitstream", reference_suffix))
            run_checkpoint_writer("reference-routed-dcp", reference_xpr, "impl_1", reference_routed_dcp)

    if args.subpartition_preset:
        runner.run(
            "cpu-subpartition-top-overlay",
            subpartition_overlay_cmd(
                modified_release,
                overlay_release,
                out_dir / "subpartitions" / "current-overlay.json",
            ),
        )
    elif args.partition_module:
        runner.run(
            "cpu-partition-top-overlay",
            partition_overlay_cmd(modified_release, "top", overlay_release),
        )
        runner.run(
            "cpu-dcp-interface",
            [
                str(paths.script_dir / "sync_cpu_dcp_interface.py"),
                "--release",
                str(modified_release),
                "--cpu-module",
                cpu_module,
                "--partition-module",
                args.partition_module,
                "--mode",
                "stub",
                "--check-existing",
                str(overlay_release / "build" / "rtl" / f"{args.partition_module}.sv"),
                "--json-out",
                str(out_dir / "partition-contract" / "modified-cpudcptop-interface.json"),
            ],
        )
    else:
        runner.run(
            "cpu-blackbox-overlay",
            partition_overlay_cmd(modified_release, "blackbox", overlay_release),
        )

    runner.run("overlay-project", fpga_make("all", overlay_suffix, overlay_core_dir))
    if (args.dry_run or reference_synth_dcp.is_file()) and args.synth_incremental_mode != "off":
        runner.run(
            "overlay-synth",
            flow.vivado_batch_cmd(
                vivado_cmd,
                paths.script_dir / "run_incremental_synth_only.tcl",
                overlay_xpr,
                reference_synth_dcp,
                "synth_1",
                jobs,
                args.synth_incremental_mode,
            ),
        )
    else:
        runner.run("overlay-synth", fpga_make("synth", overlay_suffix))

    runner.run(
        "cpu-dcp-import-probe",
        flow.vivado_batch_cmd(
            vivado_cmd,
            paths.script_dir / "cpu_dcp_import.tcl",
            "probe",
            overlay_xpr,
            import_cell_arg,
            import_dcp_arg,
            "synth_1",
            out_dir / "import-probe",
        ),
    )
    runner.run(
        "cpu-dcp-import-impl",
        flow.vivado_batch_cmd(
            vivado_cmd,
            paths.script_dir / "cpu_dcp_import.tcl",
            "impl",
            overlay_xpr,
            import_cell_arg,
            import_dcp_arg,
            "synth_1",
            out_dir / "import-impl",
            reference_routed_dcp or "",
            args.stop_after,
            args.impl_directive,
        ),
    )

    print(f"INFO: CPU-DCP flow complete: {out_dir}")
    print(f"INFO: implementation manifest: {out_dir / 'import-impl' / 'cpu-dcp-import-impl.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
