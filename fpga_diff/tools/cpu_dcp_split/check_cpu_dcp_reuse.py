#!/usr/bin/env python3
import argparse
import csv
import json
import re
from dataclasses import dataclass
from pathlib import Path

import cpu_rtl_interface as rtl_if

MODULE_RE = re.compile(r"(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b")
ENDMODULE_RE = re.compile(r"(?m)^\s*endmodule\b")


@dataclass(frozen=True)
class ModuleInfo:
    name: str
    rel_path: str
    digest: str


def classify_name(name: str, rel_path: str) -> str:
    haystack = f"{name} {rel_path}"
    if re.search(r"Difftest|DiffTest|Gateway|Batch|Delta|Host|XDMA|DifftestClockGate", haystack):
        return "difftest"
    if re.search(
        r"XSTop|XSCore|XSTile|xiangshan|XiangShan|NutShell|NutCore|CpuDcpTop|"
        r"Frontend|Backend|IFU|BPU|IDU|ISU|EXU|LSU|WBU|CSR|ALU|MDU|"
        r"Cache|TLB|SRAMTemplate|array_|rf_",
        haystack,
    ):
        return "cpu"
    if name == "SimTop" or "SimTop" in rel_path:
        return "mixed-boundary"
    return "unknown"


def iter_rtl_files(root: Path) -> list[Path]:
    return sorted(
        path for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in {".v", ".sv", ".svh"}
    )


def digest(text: str) -> str:
    return rtl_if.sha256_text(rtl_if.strip_comments(text))


def file_digest(path: Path) -> str:
    return digest(path.read_text(encoding="utf-8", errors="replace"))


def compare_files(baseline_rtl: Path, modified_rtl: Path) -> list[dict[str, str]]:
    baseline_files = [path.relative_to(baseline_rtl).as_posix() for path in iter_rtl_files(baseline_rtl)]
    modified_files = [path.relative_to(modified_rtl).as_posix() for path in iter_rtl_files(modified_rtl)]
    baseline_set = set(baseline_files)
    modified_set = set(modified_files)
    common_files = sorted(baseline_set & modified_set)

    added_files = sorted(modified_set - baseline_set)
    removed_files = sorted(baseline_set - modified_set)
    changed_files = [
        rel for rel in common_files
        if file_digest(baseline_rtl / rel) != file_digest(modified_rtl / rel)
    ]

    rows: list[dict[str, str]] = []
    for status, files in (
        ("added", added_files),
        ("removed", removed_files),
        ("changed", changed_files),
    ):
        for rel in files:
            rows.append({
                "status": status,
                "area": classify_name("", rel),
                "path": rel,
            })
    return rows


def extract_modules(rtl_root: Path) -> dict[str, ModuleInfo]:
    modules: dict[str, ModuleInfo] = {}
    for path in iter_rtl_files(rtl_root):
        rel_path = path.relative_to(rtl_root).as_posix()
        text = path.read_text(errors="replace")
        matches = list(MODULE_RE.finditer(text))
        if not matches:
            modules[f"file:{rel_path}"] = ModuleInfo(
                name=f"file:{rel_path}",
                rel_path=rel_path,
                digest=digest(text),
            )
            continue

        for idx, match in enumerate(matches):
            start = match.start()
            next_start = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
            end_match = ENDMODULE_RE.search(text, match.end(), next_start)
            end = end_match.end() if end_match else next_start
            name = match.group(1)
            key = name if name not in modules else f"{name}@{rel_path}"
            modules[key] = ModuleInfo(name=name, rel_path=rel_path, digest=digest(text[start:end]))
    return modules


def compare_modules(base: dict[str, ModuleInfo], mod: dict[str, ModuleInfo]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for key in sorted(set(base) | set(mod)):
        before = base.get(key)
        after = mod.get(key)
        info = after or before
        assert info is not None
        if before is None:
            status = "added"
        elif after is None:
            status = "removed"
        elif before.digest != after.digest:
            status = "changed"
        else:
            continue
        rows.append({
            "status": status,
            "area": classify_name(info.name, info.rel_path),
            "module": info.name,
            "path": info.rel_path,
        })
    return rows


def count_by(rows: list[dict[str, str]], key: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for row in rows:
        value = row.get(key) or "unknown"
        counts[value] = counts.get(value, 0) + 1
    return counts


def gate_from_rows(rows: list[dict[str, str]]) -> dict[str, object]:
    area_counts = count_by(rows, "area")
    examples: dict[str, list[str]] = {}
    for row in rows:
        area = row.get("area") or "unknown"
        examples.setdefault(area, [])
        if len(examples[area]) < 8:
            module = row.get("module") or row.get("path") or ""
            examples[area].append(f"{module} ({row.get('path', '')})")

    cpu_changed = area_counts.get("cpu", 0) > 0
    unknown_changed = area_counts.get("unknown", 0) > 0
    mixed_changed = area_counts.get("mixed-boundary", 0) > 0

    if not rows:
        verdict = "no-change"
        reason = "No generated RTL changes were detected."
        exit_code = 0
    elif cpu_changed:
        verdict = "cpu-dcp-invalid"
        reason = "CPU-area module changes were detected; do not assume a baseline CPU checkpoint is reusable."
        exit_code = 1
    elif unknown_changed:
        verdict = "needs-review"
        reason = "Unknown-area module changes were detected; review them before treating the run as DiffTest-only."
        exit_code = 2
    elif mixed_changed:
        verdict = "mixed-boundary-only"
        reason = "No CPU-area modules changed, but mixed SimTop boundary modules changed; whole-project incremental is valid, true CPU DCP reuse still needs a separated boundary."
        exit_code = 0
    else:
        verdict = "difftest-only"
        reason = "Only DiffTest-area modules changed; this is the best case for incremental reuse."
        exit_code = 0

    return {
        "verdict": verdict,
        "reason": reason,
        "area_counts": area_counts,
        "examples": examples,
        "exit_code": exit_code,
    }


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare FpgaDiff release RTL changes and gate CPU-DCP reuse")
    parser.add_argument("baseline_release")
    parser.add_argument("modified_release")
    parser.add_argument("out_dir")
    args = parser.parse_args()

    baseline_release = Path(args.baseline_release).resolve()
    modified_release = Path(args.modified_release).resolve()
    baseline_rtl = baseline_release / "build" / "rtl"
    modified_rtl = modified_release / "build" / "rtl"
    out_dir = Path(args.out_dir).resolve()
    for path in (baseline_rtl, modified_rtl):
        if not path.is_dir():
            raise SystemExit(f"ERROR: RTL directory not found: {path}")
    out_dir.mkdir(parents=True, exist_ok=True)

    file_rows = compare_files(baseline_rtl, modified_rtl)
    write_csv(out_dir / "summary.csv", ["status", "area", "path"], file_rows)

    rows = compare_modules(extract_modules(baseline_rtl), extract_modules(modified_rtl))
    csv_path = out_dir / "module-boundary.csv"
    write_csv(csv_path, ["status", "area", "module", "path"], rows)

    gate = gate_from_rows(file_rows + rows)
    (out_dir / "cpu-difftest-gate.json").write_text(json.dumps(gate, indent=2, sort_keys=True) + "\n")
    print(f"CPU-DCP gate: {gate['verdict']}")
    print(f"Reason: {gate['reason']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
