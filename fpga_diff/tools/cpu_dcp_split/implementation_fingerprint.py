#!/usr/bin/env python3
"""Record and compare the inputs that determine incremental implementation reuse."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

import cpu_rtl_interface as rtl_if


PROJECT_INPUTS = (
    "Makefile",
    "core_flist.awk",
    "chi_flist.awk",
    "ram_declare.py",
    "tools/gen_synth.tcl",
    "tools/gen_bitstream.tcl",
    "tools/run_impl_route.tcl",
)


sha256_file = rtl_if.sha256_file


def stable_hash(value: object) -> str:
    encoded = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def semantic_file_hash(path: Path) -> str:
    """Hash RTL after removing layout-only changes that do not reach synthesis."""
    if path.suffix.lower() not in {".v", ".sv", ".svh"}:
        return sha256_file(path)
    text = path.read_text(encoding="utf-8", errors="replace")
    return hashlib.sha256(rtl_if.normalize_ws(rtl_if.strip_comments(text)).encode()).hexdigest()


def fingerprint_files(root: Path, paths: list[Path]) -> dict[str, object]:
    files = [
        {
            "path": path.relative_to(root).as_posix(),
            "sha256": sha256_file(path),
            "semantic_sha256": semantic_file_hash(path),
        }
        for path in sorted(paths)
    ]
    semantic_files = [
        {"path": entry["path"], "sha256": entry["semantic_sha256"]}
        for entry in files
    ]
    return {
        "file_count": len(files),
        "files": files,
        "sha256": stable_hash([{key: value for key, value in entry.items() if key != "semantic_sha256"} for entry in files]),
        "semantic_sha256": stable_hash(semantic_files),
    }


def build_fingerprint(release: Path) -> dict[str, object]:
    build = release / "build"
    paths = [path for path in build.rglob("*") if path.is_file()]
    return fingerprint_files(build, paths)


def project_fingerprint(fpga_diff_dir: Path) -> dict[str, object]:
    paths = [fpga_diff_dir / rel for rel in PROJECT_INPUTS if (fpga_diff_dir / rel).is_file()]
    paths.extend(path for path in (fpga_diff_dir / "src" / "tcl").rglob("*") if path.is_file())
    return fingerprint_files(fpga_diff_dir, paths)


def interface_fingerprint(release: Path, module: str, *, cpu: bool) -> dict[str, object]:
    if not module:
        return {"module": "", "present": False, "interface_hash": "", "source_sha256": "", "semantic_sha256": ""}
    source = release / "build" / "rtl" / f"{module}.sv"
    if not source.is_file():
        return {"module": module, "present": False, "interface_hash": "", "source_sha256": "", "semantic_sha256": ""}
    interface = (
        rtl_if.read_cpu_interface(source, module)
        if cpu
        else rtl_if.read_module_interface(source, module)
    )
    return {
        "module": module,
        "present": True,
        "interface_hash": interface["interface_hash"],
        "source_sha256": interface.get("source_cpu_rtl_sha256", interface.get("source_rtl_sha256", "")),
        "semantic_sha256": semantic_file_hash(source),
        "port_count": interface["port_count"],
    }


def checkpoint_fingerprint(path_arg: str) -> dict[str, str]:
    if not path_arg:
        return {"path": "", "sha256": ""}
    path = Path(path_arg).resolve()
    return {"path": str(path), "sha256": sha256_file(path) if path.is_file() else ""}


def load_json(path_arg: str) -> dict:
    if not path_arg:
        return {}
    path = Path(path_arg).resolve()
    if not path.is_file():
        raise SystemExit(f"ERROR: reference fingerprint not found: {path}")
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ERROR: invalid reference fingerprint: {path}: {exc}") from exc


def reference_compatibility(reference: dict, current: dict) -> dict[str, object]:
    if not reference:
        return {"checked": False, "compatible": True, "reasons": []}

    reference_context = str(reference.get("implementation_context_sha256", ""))
    reference_baseline = reference.get("baseline", {})
    current_baseline = current["baseline"]
    checks = {
        "implementation_context_changed": reference_context != current["implementation_context_sha256"],
        "reference_source_does_not_match_baseline": (
            reference_baseline.get("build", {}).get("semantic_sha256", "")
            != current_baseline["build"]["semantic_sha256"]
        ),
        "cpu_interface_changed": (
            reference_baseline.get("cpu_interface", {}).get("interface_hash", "")
            != current_baseline["cpu_interface"]["interface_hash"]
        ),
        "partition_interface_changed": (
            reference_baseline.get("partition_interface", {}).get("interface_hash", "")
            != current_baseline["partition_interface"]["interface_hash"]
        ),
    }
    reasons = [name for name, failed in checks.items() if failed]
    return {"checked": True, "compatible": not reasons, "reasons": reasons}


def release_record(release: Path, cpu_module: str, partition_module: str) -> dict[str, object]:
    return {
        "path": str(release),
        "build": build_fingerprint(release),
        "cpu_interface": interface_fingerprint(release, cpu_module, cpu=True),
        "partition_interface": interface_fingerprint(release, partition_module, cpu=False),
    }


def route_decision(baseline: dict, modified: dict, reference: dict) -> dict[str, object]:
    build_changed = baseline["build"]["semantic_sha256"] != modified["build"]["semantic_sha256"]
    cpu_dcp_checked = bool(
        baseline["cpu_interface"]["present"] and modified["cpu_interface"]["present"]
    )
    cpu_source_changed = baseline["cpu_interface"]["semantic_sha256"] != modified["cpu_interface"]["semantic_sha256"]
    cpu_interface_changed = baseline["cpu_interface"]["interface_hash"] != modified["cpu_interface"]["interface_hash"]
    partition_interface_changed = (
        baseline["partition_interface"]["interface_hash"]
        != modified["partition_interface"]["interface_hash"]
    )
    if not build_changed:
        action = "no-implementation-change"
    elif not cpu_dcp_checked:
        action = "whole-project-incremental-route"
    elif cpu_interface_changed or partition_interface_changed or not reference["compatible"]:
        action = "whole-project-incremental-route"
    elif cpu_source_changed:
        action = "rebuild-cpu-dcp-and-incremental-route"
    else:
        action = "reuse-cpu-dcp-and-incremental-route"
    return {
        "route_required": build_changed,
        "cpu_dcp_checked": cpu_dcp_checked,
        "cpu_dcp_reusable": cpu_dcp_checked and not cpu_source_changed and not cpu_interface_changed and not partition_interface_changed and reference["compatible"],
        "recommended_action": action,
        "reasons": {
            "build_changed": build_changed,
            "cpu_source_changed": cpu_source_changed,
            "cpu_interface_changed": cpu_interface_changed,
            "partition_interface_changed": partition_interface_changed,
            "reference_compatible": reference["compatible"],
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Fingerprint FpgaDiff inputs and choose a safe incremental routing path"
    )
    parser.add_argument("--baseline-release", required=True)
    parser.add_argument("--modified-release", required=True)
    parser.add_argument("--fpga-diff-dir", required=True)
    parser.add_argument("--cpu", required=True)
    parser.add_argument("--cpu-module", default="")
    parser.add_argument("--partition-module", default="")
    parser.add_argument("--cpu-cell", default="")
    parser.add_argument("--vivado-version", required=True)
    parser.add_argument("--synth-incremental-mode", required=True)
    parser.add_argument("--impl-directive", required=True)
    parser.add_argument("--stop-after", required=True)
    parser.add_argument("--reference-routed-dcp", default="")
    parser.add_argument("--reference-synth-dcp", default="")
    parser.add_argument("--reference-fingerprint", default="")
    parser.add_argument("--require-reference-compatible", action="store_true")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    baseline = Path(args.baseline_release).resolve()
    modified = Path(args.modified_release).resolve()
    fpga_diff_dir = Path(args.fpga_diff_dir).resolve()
    for release in (baseline, modified):
        if not (release / "build").is_dir():
            raise SystemExit(f"ERROR: release build directory not found: {release / 'build'}")

    context = {
        "cpu": args.cpu,
        "cpu_module": args.cpu_module,
        "partition_module": args.partition_module,
        "cpu_cell": args.cpu_cell,
        "project": project_fingerprint(fpga_diff_dir),
        "vivado_version": args.vivado_version,
        "synth_incremental_mode": args.synth_incremental_mode,
        "implementation_directive": args.impl_directive,
        "stop_after": args.stop_after,
    }
    result: dict[str, object] = {
        "schema_version": 2,
        "implementation_context": context,
        "implementation_context_sha256": stable_hash(context),
        "reference_checkpoints": {
            "routed": checkpoint_fingerprint(args.reference_routed_dcp),
            "synth": checkpoint_fingerprint(args.reference_synth_dcp),
        },
        "baseline": release_record(baseline, args.cpu_module, args.partition_module),
        "modified": release_record(modified, args.cpu_module, args.partition_module),
    }
    reference = reference_compatibility(load_json(args.reference_fingerprint), result)
    result["reference_compatibility"] = reference
    result["decision"] = route_decision(result["baseline"], result["modified"], reference)

    out = Path(args.out).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    decision = result["decision"]
    print(f"Incremental fingerprint: {decision['recommended_action']}")
    print(f"Wrote implementation fingerprint: {out}")
    if args.require_reference_compatible and not reference["compatible"]:
        print("ERROR: reference fingerprint is incompatible: " + ", ".join(reference["reasons"]))
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
