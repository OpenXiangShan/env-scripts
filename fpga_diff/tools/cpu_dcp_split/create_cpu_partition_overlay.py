#!/usr/bin/env python3
import argparse
import json
import re
import shutil
import sys
from pathlib import Path

import cpu_rtl_interface as cpu_if


def sha256_file(path: Path) -> str:
    return cpu_if.sha256_file(path)


def replace_cpu_instance(
    simtop_text: str,
    cpu_module: str,
    partition_module: str,
    cpu_instance: str,
) -> tuple[str, int]:
    pattern = re.compile(
        rf"(?m)^(\s*){re.escape(cpu_module)}(\s+{re.escape(cpu_instance)}\s*\()"
    )
    replaced, count = pattern.subn(rf"\1{partition_module}\2", simtop_text)
    return replaced, count


def copy_release(src: Path, dst: Path) -> None:
    if dst.exists():
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def create_ooc_release(
    release: Path,
    out_dir: Path,
    cpu_module: str,
    partition_module: str,
) -> dict:
    copy_release(release, out_dir)
    rtl_dir = out_dir / "build" / "rtl"
    source_cpu = release / "build" / "rtl" / f"{cpu_module}.sv"
    target_wrapper = rtl_dir / f"{partition_module}.sv"

    try:
        interface = cpu_if.read_cpu_interface(source_cpu, cpu_module)
    except ValueError as exc:
        raise SystemExit(f"ERROR: {exc}") from exc
    header = str(interface["header"])
    wrapper_text = cpu_if.make_wrapper(header, cpu_module, partition_module, source_cpu)
    write_text(target_wrapper, wrapper_text)

    return {
        "kind": "ooc_release",
        "release": str(out_dir),
        "generated_rtl": str(target_wrapper),
        "generated_rtl_sha256": sha256_file(target_wrapper),
        "cpu_interface_hash": interface["interface_hash"],
        "cpu_port_count": interface["port_count"],
        "header_line_count": len(header.splitlines()),
        "wrapper_line_count": len(wrapper_text.splitlines()),
    }


def create_top_release(
    release: Path,
    out_dir: Path,
    cpu_module: str,
    partition_module: str,
    simtop_module: str,
    cpu_instance: str,
) -> dict:
    copy_release(release, out_dir)
    rtl_dir = out_dir / "build" / "rtl"
    source_cpu = release / "build" / "rtl" / f"{cpu_module}.sv"
    source_simtop = release / "build" / "rtl" / f"{simtop_module}.sv"
    target_stub = rtl_dir / f"{partition_module}.sv"
    target_simtop = rtl_dir / f"{simtop_module}.sv"

    try:
        interface = cpu_if.read_cpu_interface(source_cpu, cpu_module)
    except ValueError as exc:
        raise SystemExit(f"ERROR: {exc}") from exc
    header = str(interface["header"])
    stub_text = cpu_if.make_stub(header, cpu_module, partition_module, source_cpu)
    write_text(target_stub, stub_text)

    simtop_text = target_simtop.read_text(encoding="utf-8")
    new_simtop, replacements = replace_cpu_instance(
        simtop_text,
        cpu_module=cpu_module,
        partition_module=partition_module,
        cpu_instance=cpu_instance,
    )
    if replacements != 1:
        raise SystemExit(
            "ERROR: expected exactly one CPU instance replacement in "
            f"{target_simtop}, got {replacements}"
        )
    write_text(target_simtop, new_simtop)

    return {
        "kind": "top_release",
        "release": str(out_dir),
        "generated_stub": str(target_stub),
        "generated_stub_sha256": sha256_file(target_stub),
        "cpu_interface_hash": interface["interface_hash"],
        "cpu_port_count": interface["port_count"],
        "modified_simtop": str(target_simtop),
        "modified_simtop_sha256": sha256_file(target_simtop),
        "simtop_instance_replacements": replacements,
        "header_line_count": len(header.splitlines()),
        "stub_line_count": len(stub_text.splitlines()),
    }


def create_blackbox_release(
    release: Path,
    out_dir: Path,
    cpu_module: str,
) -> dict:
    copy_release(release, out_dir)
    rtl_dir = out_dir / "build" / "rtl"
    source_cpu = release / "build" / "rtl" / f"{cpu_module}.sv"
    target_stub = rtl_dir / f"{cpu_module}.sv"

    try:
        interface = cpu_if.read_cpu_interface(source_cpu, cpu_module)
    except ValueError as exc:
        raise SystemExit(f"ERROR: {exc}") from exc
    header = str(interface["header"])
    stub_text = cpu_if.make_stub(header, cpu_module, cpu_module, source_cpu)
    write_text(target_stub, stub_text)

    return {
        "kind": "blackbox_release",
        "release": str(out_dir),
        "generated_stub": str(target_stub),
        "generated_stub_sha256": sha256_file(target_stub),
        "cpu_interface_hash": interface["interface_hash"],
        "cpu_port_count": interface["port_count"],
        "header_line_count": len(header.splitlines()),
        "stub_line_count": len(stub_text.splitlines()),
    }


def write_manifest(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Create generated-RTL CpuDcpTop overlays for FpgaDiff CPU-DCP "
            "split flows."
        )
    )
    parser.add_argument("--release", required=True, help="Source release directory containing build/rtl")
    parser.add_argument("--cpu-module", required=True, help="Original generated CPU module, for example NutShell")
    parser.add_argument("--partition-module", default="CpuDcpTop", help="Generated CPU partition module name")
    parser.add_argument("--simtop-module", default="SimTop", help="Generated top module containing the CPU instance")
    parser.add_argument("--cpu-instance", default="cpu", help="CPU instance name inside SimTop")
    parser.add_argument(
        "--mode",
        choices=["both", "ooc", "top", "blackbox"],
        default="both",
        help="Which overlay release(s) to create",
    )
    parser.add_argument("--out-dir", required=True, help="Output directory or release directory")
    parser.add_argument("--force", action="store_true", help="Remove an existing output directory first")
    parser.add_argument("--json-out", help="Optional manifest path")
    args = parser.parse_args()

    release = Path(args.release).resolve()
    out_dir = Path(args.out_dir).resolve()
    rtl_dir = release / "build" / "rtl"
    cpu_rtl = rtl_dir / f"{args.cpu_module}.sv"
    simtop_rtl = rtl_dir / f"{args.simtop_module}.sv"

    if not release.is_dir():
        print(f"ERROR: release directory not found: {release}", file=sys.stderr)
        return 1
    if not rtl_dir.is_dir():
        print(f"ERROR: release RTL directory not found: {rtl_dir}", file=sys.stderr)
        return 1
    if not cpu_rtl.is_file():
        print(f"ERROR: CPU module RTL not found: {cpu_rtl}", file=sys.stderr)
        return 1
    if args.mode in {"both", "top"} and not simtop_rtl.is_file():
        print(f"ERROR: SimTop RTL not found: {simtop_rtl}", file=sys.stderr)
        return 1

    if out_dir.exists():
        if not args.force:
            print(f"ERROR: output directory already exists: {out_dir}", file=sys.stderr)
            print("Use --force to replace it.", file=sys.stderr)
            return 1
        shutil.rmtree(out_dir)

    created: list[dict] = []
    if args.mode == "both":
        out_dir.mkdir(parents=True)
        ooc_dir = out_dir / "ooc-release"
        top_dir = out_dir / "top-release"
        created.append(create_ooc_release(release, ooc_dir, args.cpu_module, args.partition_module))
        created.append(create_top_release(
            release,
            top_dir,
            args.cpu_module,
            args.partition_module,
            args.simtop_module,
            args.cpu_instance,
        ))
        default_manifest = out_dir / "cpu-partition-overlay.json"
    elif args.mode == "ooc":
        created.append(create_ooc_release(release, out_dir, args.cpu_module, args.partition_module))
        default_manifest = out_dir / "cpu-partition-overlay.json"
    elif args.mode == "top":
        created.append(create_top_release(
            release,
            out_dir,
            args.cpu_module,
            args.partition_module,
            args.simtop_module,
            args.cpu_instance,
        ))
        default_manifest = out_dir / "cpu-partition-overlay.json"
    else:
        created.append(create_blackbox_release(release, out_dir, args.cpu_module))
        default_manifest = out_dir / "cpu-blackbox-overlay.json"

    effective_partition_module = args.cpu_module if args.mode == "blackbox" else args.partition_module
    manifest = {
        "schema_version": 1,
        "source_release": str(release),
        "mode": args.mode,
        "cpu_module": args.cpu_module,
        "partition_module": effective_partition_module,
        "simtop_module": args.simtop_module,
        "cpu_instance": args.cpu_instance,
        "source_cpu_rtl": str(cpu_rtl),
        "source_cpu_rtl_sha256": sha256_file(cpu_rtl),
        "source_simtop_rtl": str(simtop_rtl) if simtop_rtl.is_file() else "",
        "source_simtop_rtl_sha256": sha256_file(simtop_rtl) if simtop_rtl.is_file() else "",
        "created": created,
    }
    manifest_path = Path(args.json_out).resolve() if args.json_out else default_manifest
    write_manifest(manifest_path, manifest)

    print(f"Wrote CPU partition overlay manifest: {manifest_path}")
    for item in created:
        print(f"Wrote {item['kind']}: {item['release']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
