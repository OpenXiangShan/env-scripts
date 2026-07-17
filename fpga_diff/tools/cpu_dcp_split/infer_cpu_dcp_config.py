#!/usr/bin/env python3
import argparse
import json
import re
import shlex
import sys
from pathlib import Path

import cpu_rtl_interface as rtl_if
from extract_simtop_partition_contract import extract_contract, locate_simtop


def infer_wrapper_instance(
    fpga_diff_dir: Path,
    cpu: str,
    simtop_module: str,
) -> tuple[str, list[str], str]:
    wrapper = fpga_diff_dir / "src" / "rtl" / cpu / "SimTop_wrapper.sv"
    if not wrapper.is_file():
        return "", [], str(wrapper)

    text = rtl_if.strip_comments_preserve_offsets(wrapper.read_text(errors="replace"))
    pattern = re.compile(
        rf"(?m)^\s*{re.escape(simtop_module)}\s+"
        r"(?:#\s*\((?:.|\n)*?\)\s*)?"
        r"([A-Za-z_][A-Za-z0-9_$]*)\s*\("
    )
    matches = pattern.findall(text)
    unique = sorted(set(matches))
    if len(unique) == 1:
        return unique[0], unique, str(wrapper)
    return "", unique, str(wrapper)


def infer_cpu_kind(cpu_module: str) -> str:
    if cpu_module == "NutShell":
        return "nutshell"
    if cpu_module in {"XSTop", "XSCore", "XSTile"}:
        return "kmh"
    return ""


def shell_assign(data: dict[str, object]) -> str:
    lines = []
    for key, value in data.items():
        if isinstance(value, (dict, list)):
            continue
        lines.append(f"{key}={shlex.quote(str(value))}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Infer CPU-DCP split parameters from a generated release")
    parser.add_argument("--release", required=True, help="Release directory containing build/rtl")
    parser.add_argument("--fpga-diff-dir", required=True, help="env-scripts/fpga_diff directory")
    parser.add_argument("--cpu", default="", help="FpgaDiff CPU target, for wrapper hierarchy inference")
    parser.add_argument("--simtop-module", default="SimTop")
    parser.add_argument("--cell-prefix", default="core_def/U_CPU_TOP")
    parser.add_argument("--json-out", help="Optional JSON output path")
    parser.add_argument("--shell", action="store_true", help="Print shell assignments")
    args = parser.parse_args()

    release = Path(args.release).resolve()
    fpga_diff_dir = Path(args.fpga_diff_dir).resolve()
    try:
        simtop_path, release_root = locate_simtop(str(release), args.simtop_module)
        contract = extract_contract(simtop_path, release_root, args.simtop_module)
    except (OSError, SystemExit, ValueError) as exc:
        print(f"ERROR: cannot infer CPU partition from {release}: {exc}", file=sys.stderr)
        return 1

    cpu_instances = contract.get("cpu_instances", [])
    if len(cpu_instances) != 1:
        print(
            "ERROR: expected exactly one CPU instance in "
            f"{simtop_path}, got {len(cpu_instances)}",
            file=sys.stderr,
        )
        return 1

    cpu_inst = cpu_instances[0]
    cpu_module = str(cpu_inst.get("module", ""))
    cpu_instance = str(cpu_inst.get("name", ""))
    cpu = args.cpu or infer_cpu_kind(cpu_module)
    wrapper_instance = ""
    wrapper_candidates: list[str] = []
    wrapper_path = ""
    if cpu:
        wrapper_instance, wrapper_candidates, wrapper_path = infer_wrapper_instance(
            fpga_diff_dir,
            cpu,
            args.simtop_module,
        )

    cpu_cell = ""
    if wrapper_instance and cpu_instance:
        cpu_cell = f"{args.cell_prefix}/{wrapper_instance}/{cpu_instance}"

    result: dict[str, object] = {
        "release": str(release),
        "simtop_path": str(simtop_path),
        "simtop_module": args.simtop_module,
        "cpu": cpu,
        "cpu_module": cpu_module,
        "cpu_instance": cpu_instance,
        "simtop_wrapper": wrapper_path,
        "simtop_wrapper_instance": wrapper_instance,
        "simtop_wrapper_instance_candidates": wrapper_candidates,
        "cpu_cell": cpu_cell,
        "cpu_partition_interface_hash": contract.get("cpu_partition_manifest", {}).get("interface_hash", ""),
    }

    if args.json_out:
        Path(args.json_out).write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    if args.shell:
        print(shell_assign(result), end="")
    else:
        print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if cpu_module and cpu_instance else 1


if __name__ == "__main__":
    raise SystemExit(main())
