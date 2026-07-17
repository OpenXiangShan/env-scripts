#!/usr/bin/env python3
import argparse
import csv
import json
import re
import shutil
import sys
from pathlib import Path

import cpu_rtl_interface as rtl_if


INSTANCE_RE = re.compile(
    r"(?m)^\s*([A-Za-z_][A-Za-z0-9_$]*)\s+"
    r"(?:#\s*\((?:.|\n)*?\)\s*)?"
    r"([A-Za-z_][A-Za-z0-9_$]*)\s*\("
)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def rtl_dir(release: Path) -> Path:
    return release / "build" / "rtl"


def read_modules(release: Path) -> dict[str, Path]:
    root = rtl_dir(release)
    if not root.is_dir():
        raise ValueError(f"RTL directory not found: {root}")
    result: dict[str, Path] = {}
    for path in root.glob("*.sv"):
        text = read_text(path)
        for match in re.finditer(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b", text):
            result.setdefault(match.group(1), path)
    return result


def module_body(text: str, module: str) -> str:
    header = rtl_if.extract_module_header(text, module)
    start = text.find(header)
    if start < 0:
        return text
    start += len(header)
    match = re.search(r"(?m)^\s*endmodule\b", text[start:])
    if not match:
        return text[start:]
    return text[start:start + match.start()]


def module_text(text: str, module: str) -> str:
    header = rtl_if.extract_module_header(text, module)
    start = text.find(header)
    if start < 0:
        raise ValueError(f"module header not found: {module}")
    after_header = start + len(header)
    match = re.search(r"(?m)^\s*endmodule\b", text[after_header:])
    if not match:
        raise ValueError(f"endmodule not found for module: {module}")
    end = after_header + match.end()
    return text[start:end]


def module_instances(release: Path, module: str, modules: dict[str, Path]) -> list[dict[str, str]]:
    path = modules.get(module)
    if path is None:
        return []
    body = module_body(read_text(path), module)
    result: list[dict[str, str]] = []
    for match in INSTANCE_RE.finditer(body):
        child_module = match.group(1)
        inst = match.group(2)
        if child_module in {"if", "for", "while", "case", "assign", "always", "initial"}:
            continue
        if child_module not in modules:
            continue
        result.append({"module": child_module, "instance": inst})
    return result


def find_partition(
    release: Path,
    cpu_module: str,
    modules: dict[str, Path],
    role: str,
    module_regex: str,
) -> dict[str, object]:
    pattern = re.compile(module_regex)
    queue: list[tuple[str, list[str], list[str]]] = [(cpu_module, [], [])]
    visited: set[tuple[str, tuple[str, ...]]] = set()
    candidates: list[dict[str, object]] = []

    while queue:
        module, inst_path, module_path_parts = queue.pop(0)
        key = (module, tuple(inst_path))
        if key in visited:
            continue
        visited.add(key)

        if inst_path and pattern.search(module):
            candidates.append({
                "role": role,
                "module": module,
                "instance_path": "/".join(inst_path),
                "module_path": "/".join(module_path_parts + [module]),
                "depth": len(inst_path),
            })
            continue

        for child in module_instances(release, module, modules):
            queue.append((
                child["module"],
                inst_path + [child["instance"]],
                module_path_parts + [module],
            ))

    if not candidates:
        raise ValueError(
            f"could not find {role} partition below {cpu_module} with regex {module_regex!r}"
        )
    candidates.sort(key=lambda item: (int(item["depth"]), str(item["module"])))
    return candidates[0]


def dependency_closure(release: Path, top: str, modules: dict[str, Path]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []

    def visit(module: str) -> None:
        if module in seen:
            return
        seen.add(module)
        ordered.append(module)
        for child in module_instances(release, module, modules):
            visit(child["module"])

    visit(top)
    return ordered


def closure_hash(release: Path, top: str, modules: dict[str, Path]) -> tuple[str, list[str]]:
    closure = dependency_closure(release, top, modules)
    signature: list[dict[str, str]] = []
    for module in closure:
        path = modules.get(module)
        if path is None:
            continue
        text = read_text(path)
        signature.append({
            "module": module,
            "relative_path": str(path.relative_to(rtl_dir(release))),
            "sha256": rtl_if.sha256_text(
                rtl_if.strip_comments(module_text(text, module))
            ),
        })
    return rtl_if.stable_json_hash(signature), closure


def write_tsv(path: Path, rows: list[list[str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join("\t".join(str(col) for col in row) for row in rows) + "\n",
        encoding="utf-8",
    )


def changed_cpu_modules(module_boundary_csv: Path) -> list[str]:
    if not module_boundary_csv.is_file():
        return []
    result: list[str] = []
    with module_boundary_csv.open(newline="") as f:
        for row in csv.DictReader(f):
            if row.get("status") in {"added", "removed", "changed"} and row.get("area") == "cpu":
                module = row.get("module", "")
                if module:
                    result.append(module)
    return sorted(set(result))


def modules_in_file(release: Path, rel_path: str) -> list[str]:
    path = rtl_dir(release) / rel_path
    if not path.is_file():
        return []
    text = read_text(path)
    return [
        match.group(1)
        for match in re.finditer(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b", text)
    ]


def changed_cpu_file_modules(summary_csv: Path, baseline: Path, modified: Path) -> list[str]:
    if not summary_csv.is_file():
        return []
    result: list[str] = []
    with summary_csv.open(newline="") as f:
        for row in csv.DictReader(f):
            if row.get("status") not in {"added", "removed", "changed"} or row.get("area") != "cpu":
                continue
            rel_path = row.get("path", "")
            if not rel_path:
                continue
            release = baseline if row.get("status") == "removed" else modified
            modules = modules_in_file(release, rel_path)
            if modules:
                result.extend(modules)
            else:
                result.append(f"file:{rel_path}")
    return sorted(set(result))


def build_plan_rows(partitions: list[dict[str, object]], which: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for part in partitions:
        if which == "current" and not part.get("changed"):
            continue
        dcp = part[f"{which}_dcp"]
        rows.append([
            str(part["role"]),
            str(part["module"]),
            str(part[f"{which}_source_release"]),
            str(Path(str(dcp)).parent),
            str(dcp),
        ])
    return rows


def import_rows(partitions: list[dict[str, object]], which: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for part in partitions:
        rows.append([
            str(part["role"]),
            str(part["cell"]),
            str(part[f"{which}_dcp"]),
        ])
    return rows


def run_plan(args: argparse.Namespace) -> int:
    baseline = Path(args.baseline_release).resolve()
    modified = Path(args.modified_release).resolve()
    dcp_root = Path(args.dcp_root).resolve()
    try:
        baseline_modules = read_modules(baseline)
        modified_modules = read_modules(modified)
        roles = [
            ("frontend", args.frontend_regex),
            ("backend", args.backend_regex),
        ]
        partitions: list[dict[str, object]] = []
        for role, module_regex in roles:
            part = find_partition(
                modified,
                args.cpu_module,
                modified_modules,
                role,
                module_regex,
            )
            module = str(part["module"])
            if module not in baseline_modules:
                raise ValueError(f"{role} module not found in baseline RTL: {module}")
            baseline_hash, baseline_closure = closure_hash(baseline, module, baseline_modules)
            modified_hash, modified_closure = closure_hash(modified, module, modified_modules)
            changed = baseline_hash != modified_hash
            cell = f"{args.cpu_cell.rstrip('/')}/{part['instance_path']}"
            reference_dcp = dcp_root / "reference" / role / "cpu-synth.dcp"
            current_dcp = (
                dcp_root / "current" / role / "cpu-synth.dcp"
                if changed else reference_dcp
            )
            current_source = modified if changed else baseline
            part.update({
                "cell": cell,
                "module_regex": module_regex,
                "baseline_rtl": str(baseline_modules[module].relative_to(rtl_dir(baseline))),
                "modified_rtl": str(modified_modules[module].relative_to(rtl_dir(modified))),
                "baseline_closure_hash": baseline_hash,
                "modified_closure_hash": modified_hash,
                "changed": changed,
                "baseline_closure": baseline_closure,
                "modified_closure": modified_closure,
                "current_source_release": str(current_source),
                "reference_source_release": str(baseline),
                "current_dcp": str(current_dcp),
                "reference_dcp": str(reference_dcp),
            })
            partitions.append(part)
        cpu_changes = changed_cpu_modules(Path(args.module_boundary_csv)) if args.module_boundary_csv else []
        cpu_file_changes = (
            changed_cpu_file_modules(Path(args.file_summary_csv), baseline, modified)
            if args.file_summary_csv else []
        )
        cpu_changes = sorted(set(cpu_changes + cpu_file_changes))
        covered_modules = set()
        for part in partitions:
            covered_modules.update(str(module) for module in part.get("modified_closure", []))
            covered_modules.update(str(module) for module in part.get("baseline_closure", []))
        uncovered_cpu_changes = sorted(module for module in cpu_changes if module not in covered_modules)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    manifest = {
        "schema_version": 1,
        "preset": args.preset,
        "baseline_release": str(baseline),
        "modified_release": str(modified),
        "cpu_module": args.cpu_module,
        "cpu_cell": args.cpu_cell,
        "dcp_root": str(dcp_root),
        "partitions": partitions,
        "changed_cpu_modules": cpu_changes,
        "changed_cpu_file_modules": cpu_file_changes,
        "uncovered_cpu_changes": uncovered_cpu_changes,
        "subpartition_reuse_candidate": not uncovered_cpu_changes,
    }

    json_out = Path(args.json_out).resolve()
    json_out.parent.mkdir(parents=True, exist_ok=True)
    json_out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_tsv(Path(args.current_import_tsv).resolve(), import_rows(partitions, "current"))
    write_tsv(Path(args.reference_import_tsv).resolve(), import_rows(partitions, "reference"))
    write_tsv(Path(args.current_build_tsv).resolve(), build_plan_rows(partitions, "current"))
    write_tsv(Path(args.reference_build_tsv).resolve(), build_plan_rows(partitions, "reference"))

    for part in partitions:
        print(
            f"{part['role']}: module={part['module']} cell={part['cell']} "
            f"changed={part['changed']}"
        )
    if uncovered_cpu_changes:
        print(
            "ERROR: CPU changes outside selected subpartitions: "
            + ", ".join(uncovered_cpu_changes),
            file=sys.stderr,
        )
        return 1
    print(f"Wrote partition plan: {json_out}")
    return 0


def copy_release(src: Path, dst: Path, force: bool) -> None:
    if dst.exists():
        if not force:
            raise ValueError(f"output directory already exists: {dst}")
        shutil.rmtree(dst)
    shutil.copytree(src, dst)


def replace_module_text(text: str, module: str, replacement: str) -> str:
    original = module_text(text, module)
    start = text.find(original)
    if start < 0:
        raise ValueError(f"module body not found for replacement: {module}")
    return text[:start] + replacement.rstrip() + "\n" + text[start + len(original):]


def write_stub(
    release: Path,
    out_release: Path,
    module: str,
    rtl_rel_path: str | None,
) -> dict[str, object]:
    source = rtl_dir(release) / (rtl_rel_path or f"{module}.sv")
    target = rtl_dir(out_release) / (rtl_rel_path or f"{module}.sv")
    if not source.is_file():
        raise ValueError(f"partition module RTL not found: {source}")
    interface = rtl_if.read_cpu_interface(source, module)
    stub = rtl_if.make_stub(str(interface["header"]), module, module, source)
    if not target.is_file():
        raise ValueError(f"overlay RTL target not found: {target}")
    target_text = target.read_text(encoding="utf-8", errors="replace")
    target.write_text(replace_module_text(target_text, module, stub), encoding="utf-8")
    return {
        "module": module,
        "source_rtl": str(source),
        "source_rtl_sha256": rtl_if.sha256_file(source),
        "stub_rtl": str(target),
        "stub_rtl_sha256": rtl_if.sha256_file(target),
        "interface_hash": interface["interface_hash"],
        "port_count": interface["port_count"],
    }


def partition_rtl_rel_path(part: dict[str, object], release: Path, plan: dict[str, object]) -> str | None:
    baseline_release = Path(str(plan.get("baseline_release", ""))).resolve()
    modified_release = Path(str(plan.get("modified_release", ""))).resolve()
    if release == baseline_release:
        return str(part.get("baseline_rtl", "")) or None
    if release == modified_release:
        return str(part.get("modified_rtl", "")) or None

    for key in ("modified_rtl", "baseline_rtl"):
        rel_path = str(part.get(key, ""))
        if rel_path and (rtl_dir(release) / rel_path).is_file():
            return rel_path
    return None


def run_overlay(args: argparse.Namespace) -> int:
    release = Path(args.release).resolve()
    out_dir = Path(args.out_dir).resolve()
    plan_path = Path(args.partitions_json).resolve()
    if not release.is_dir():
        print(f"ERROR: release directory not found: {release}", file=sys.stderr)
        return 1
    if not plan_path.is_file():
        print(f"ERROR: partition plan not found: {plan_path}", file=sys.stderr)
        return 1

    try:
        plan = json.loads(plan_path.read_text(encoding="utf-8"))
        partitions = plan.get("partitions", [])
        if not partitions:
            raise ValueError(f"no partitions in {plan_path}")
        copy_release(release, out_dir, args.force)
        stubs = []
        for part in partitions:
            module = str(part.get("module", ""))
            if not module:
                raise ValueError(f"partition missing module: {part}")
            rtl_rel_path = partition_rtl_rel_path(part, release, plan)
            stubs.append(write_stub(release, out_dir, module, rtl_rel_path))
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    manifest = {
        "schema_version": 1,
        "kind": "cpu_subpartition_overlay",
        "source_release": str(release),
        "out_release": str(out_dir),
        "partitions_json": str(plan_path),
        "preset": plan.get("preset", ""),
        "stubs": stubs,
    }
    manifest_path = Path(args.json_out).resolve() if args.json_out else out_dir / "cpu-subpartition-overlay.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    print(f"Wrote CPU subpartition overlay manifest: {manifest_path}")
    for stub in stubs:
        print(f"Wrote black-box stub: {stub['stub_rtl']}")
    return 0


def add_plan_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "plan",
        help="plan frontend/backend CPU subpartition DCP reuse from generated RTL",
    )
    parser.add_argument("--baseline-release", required=True)
    parser.add_argument("--modified-release", required=True)
    parser.add_argument("--cpu-module", required=True)
    parser.add_argument("--cpu-cell", required=True)
    parser.add_argument("--preset", choices=["frontend-backend"], default="frontend-backend")
    parser.add_argument("--dcp-root", required=True)
    parser.add_argument("--json-out", required=True)
    parser.add_argument("--current-import-tsv", required=True)
    parser.add_argument("--reference-import-tsv", required=True)
    parser.add_argument("--current-build-tsv", required=True)
    parser.add_argument("--reference-build-tsv", required=True)
    parser.add_argument("--module-boundary-csv", default="")
    parser.add_argument("--file-summary-csv", default="")
    parser.add_argument("--frontend-regex", default=r"Frontend")
    parser.add_argument("--backend-regex", default=r"Backend")
    parser.set_defaults(func=run_plan)


def add_overlay_parser(subparsers: argparse._SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "overlay",
        help="create a release overlay with selected CPU submodules as black boxes",
    )
    parser.add_argument("--release", required=True, help="Source release directory")
    parser.add_argument("--partitions-json", required=True, help="Partition plan JSON")
    parser.add_argument("--out-dir", required=True, help="Output release directory")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--json-out", help="Optional overlay manifest")
    parser.set_defaults(func=run_overlay)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Plan and materialize CPU subpartition DCP reuse overlays")
    subparsers = parser.add_subparsers(dest="command")
    add_plan_parser(subparsers)
    add_overlay_parser(subparsers)
    args = parser.parse_args()
    if not hasattr(args, "func"):
        parser.print_help(sys.stderr)
        return 2
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
