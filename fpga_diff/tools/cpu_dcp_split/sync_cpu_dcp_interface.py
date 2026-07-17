#!/usr/bin/env python3
import argparse
import json
import sys
from pathlib import Path

from cpu_rtl_interface import (
    make_partition_rtl,
    read_cpu_interface,
    read_module_interface,
    sha256_file,
)
from extract_simtop_partition_contract import extract_contract, locate_simtop


def infer_cpu_module(release: Path, simtop_module: str) -> tuple[str, str, str]:
    simtop_path, release_root = locate_simtop(str(release), simtop_module)
    contract = extract_contract(simtop_path, release_root, simtop_module)
    cpu_instances = contract.get("cpu_instances", [])
    if len(cpu_instances) != 1:
        raise ValueError(
            f"expected exactly one CPU instance in {simtop_path}, got {len(cpu_instances)}"
        )
    cpu_inst = cpu_instances[0]
    return (
        str(cpu_inst.get("module", "")),
        str(cpu_inst.get("name", "")),
        str(simtop_path),
    )


def default_output_path(release: Path, partition_module: str) -> Path:
    return release / "build" / "rtl" / f"{partition_module}.sv"


def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Read the generated CPU RTL port list and copy that interface onto "
            "a CpuDcpTop-style partition RTL module."
        )
    )
    parser.add_argument("--release", required=True, help="Release directory containing build/rtl")
    parser.add_argument("--cpu-module", default="", help="CPU RTL module name; inferred from SimTop if omitted")
    parser.add_argument("--simtop-module", default="SimTop", help="Generated top module used for inference")
    parser.add_argument("--partition-module", default="CpuDcpTop", help="Output partition module name")
    parser.add_argument(
        "--mode",
        choices=["stub", "wrapper"],
        default="stub",
        help="Generate a black-box top stub or an OOC wrapper around the CPU module",
    )
    parser.add_argument(
        "--out",
        help=(
            "Output RTL path. Defaults to <release>/build/rtl/<partition-module>.sv "
            "when --write-default is set."
        ),
    )
    parser.add_argument(
        "--write-default",
        action="store_true",
        help="Write to <release>/build/rtl/<partition-module>.sv when --out is omitted",
    )
    parser.add_argument("--force", action="store_true", help="Overwrite an existing output RTL")
    parser.add_argument("--json-out", help="Optional interface manifest path")
    parser.add_argument(
        "--check-existing",
        help="Compare an existing partition RTL module against the CPU RTL interface",
    )
    parser.add_argument(
        "--print-ports",
        action="store_true",
        help="Print one port per line as: direction range name",
    )
    args = parser.parse_args()

    release = Path(args.release).resolve()
    rtl_dir = release / "build" / "rtl"
    if not release.is_dir():
        print(f"ERROR: release directory not found: {release}", file=sys.stderr)
        return 1
    if not rtl_dir.is_dir():
        print(f"ERROR: release RTL directory not found: {rtl_dir}", file=sys.stderr)
        return 1

    cpu_module = args.cpu_module
    cpu_instance = ""
    simtop_path = ""
    if not cpu_module:
        try:
            cpu_module, cpu_instance, simtop_path = infer_cpu_module(release, args.simtop_module)
        except (OSError, SystemExit, ValueError) as exc:
            print(f"ERROR: cannot infer CPU module from {release}: {exc}", file=sys.stderr)
            return 1

    cpu_rtl = rtl_dir / f"{cpu_module}.sv"
    if not cpu_rtl.is_file():
        print(f"ERROR: CPU RTL not found: {cpu_rtl}", file=sys.stderr)
        return 1

    try:
        cpu_interface = read_cpu_interface(cpu_rtl, cpu_module)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    out_path: Path | None = None
    if args.out:
        out_path = Path(args.out).resolve()
    elif args.write_default:
        out_path = default_output_path(release, args.partition_module).resolve()

    generated_rtl = make_partition_rtl(
        cpu_interface,
        partition_module=args.partition_module,
        mode=args.mode,
    )

    check_result: dict[str, object] = {}
    if args.check_existing:
        check_path = Path(args.check_existing).resolve()
        if not check_path.is_file():
            print(f"ERROR: existing partition RTL not found: {check_path}", file=sys.stderr)
            return 1
        try:
            existing = read_module_interface(check_path, args.partition_module)
        except ValueError as exc:
            print(f"ERROR: cannot parse existing partition RTL: {exc}", file=sys.stderr)
            return 1
        matches = existing["port_signature"] == cpu_interface["port_signature"]
        check_result = {
            "path": str(check_path),
            "matches_cpu_interface": matches,
            "existing_interface_hash": existing["interface_hash"],
            "cpu_interface_hash": cpu_interface["interface_hash"],
            "existing_port_count": existing["port_count"],
            "cpu_port_count": cpu_interface["port_count"],
        }

    if out_path:
        if out_path.exists() and not args.force:
            print(f"ERROR: output RTL already exists: {out_path}", file=sys.stderr)
            print("Use --force to overwrite it.", file=sys.stderr)
            return 1
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(generated_rtl, encoding="utf-8")

    manifest = {
        "schema_version": 1,
        "purpose": "CpuDcpTop interface copied from generated CPU RTL",
        "release": str(release),
        "simtop_module": args.simtop_module,
        "simtop_path": simtop_path,
        "cpu_module": cpu_module,
        "cpu_instance": cpu_instance,
        "partition_module": args.partition_module,
        "mode": args.mode,
        "source_cpu_rtl": str(cpu_rtl),
        "source_cpu_rtl_sha256": cpu_interface["source_cpu_rtl_sha256"],
        "generated_rtl": str(out_path) if out_path else "",
        "generated_rtl_sha256": sha256_file(out_path) if out_path and out_path.is_file() else "",
        "port_count": cpu_interface["port_count"],
        "interface_hash": cpu_interface["interface_hash"],
        "ports": cpu_interface["port_signature"],
        "check_existing": check_result,
        "notes": [
            "This copies the RTL module interface onto the partition shell.",
            "Vivado still requires the imported DCP top ports to match the target cell ports.",
            "If the real CPU implementation ports changed, rebuild the CPU DCP or add a deliberate adapter.",
        ],
    }

    if args.json_out:
        write_json(Path(args.json_out).resolve(), manifest)

    if args.print_ports:
        for port in cpu_interface["port_signature"]:
            direction = port["direction"] or "-"
            range_text = port["range"] or "-"
            print(f"{direction:6} {range_text:12} {port['name']}")
    elif not args.json_out and not out_path:
        print(json.dumps(manifest, indent=2, sort_keys=True))

    if out_path:
        print(f"Wrote {args.partition_module} {args.mode}: {out_path}")
    if args.json_out:
        print(f"Wrote interface manifest: {Path(args.json_out).resolve()}")
    if check_result:
        state = "matches" if check_result["matches_cpu_interface"] else "differs"
        print(f"Existing partition interface {state}: {check_result['path']}")
        if not check_result["matches_cpu_interface"]:
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
