#!/usr/bin/env python3
"""Shared helpers for the FpgaDiff incremental build flows."""

from __future__ import annotations

import json
import os
import resource
import shlex
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable, Sequence


@dataclass(frozen=True)
class FlowPaths:
    script_dir: Path
    fpga_diff_dir: Path
    repo_root: Path


def resolve_m(path: str | Path) -> Path:
    """Approximate `realpath -m`: absolute, normalized, and not strict."""
    return Path(path).expanduser().resolve(strict=False)


def init_paths(caller: str | Path) -> FlowPaths:
    script_dir = Path(caller).resolve(strict=False).parent
    if (script_dir / "../..").is_dir() and (script_dir / "../../Makefile").is_file():
        fpga_diff_dir = resolve_m(script_dir / "../..")
        repo_root = resolve_m(script_dir / "../../../..")
    elif (script_dir / "../../env-scripts/fpga_diff").is_dir():
        repo_root = resolve_m(script_dir / "../..")
        fpga_diff_dir = repo_root / "env-scripts" / "fpga_diff"
    else:
        raise SystemExit(f"ERROR: cannot locate fpga_diff Makefile from {script_dir}")
    return FlowPaths(script_dir=script_dir, fpga_diff_dir=fpga_diff_dir, repo_root=repo_root)


def require_existing_dir(path: Path, label: str = "directory") -> None:
    if not path.is_dir():
        raise SystemExit(f"ERROR: {label} not found: {path}")


def require_release_dirs(*releases: Path) -> None:
    for release in releases:
        require_existing_dir(release)
        require_existing_dir(release / "build")


def require_positive_int(name: str, value: str | None) -> None:
    if value and (not value.isdecimal() or int(value) <= 0):
        raise SystemExit(f"ERROR: {name} must be a positive integer, got {value}")


def read_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(errors="replace"))
    except json.JSONDecodeError:
        return {}


def infer_cpu_dcp_config(paths: FlowPaths, release: Path, cpu: str | None = None, *, required: bool = False) -> dict[str, str]:
    cmd = [
        str(paths.script_dir / "infer_cpu_dcp_config.py"),
        "--release",
        str(release),
        "--fpga-diff-dir",
        str(paths.fpga_diff_dir),
    ]
    if cpu:
        cmd += ["--cpu", cpu]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=False)
    if proc.returncode != 0:
        lines = proc.stderr.splitlines()[:5]
        message = f"could not auto-infer CPU-DCP parameters from {release}"
        if required:
            detail = "\n".join(lines)
            raise SystemExit(f"ERROR: {message}\n{detail}\nPass --cpu kmh, --cpu nanhu, or --cpu nutshell explicitly.")
        print(f"WARNING: {message}:")
        print("\n".join(lines))
        return {}
    return {key: str(value) for key, value in json.loads(proc.stdout).items() if not isinstance(value, (dict, list))}


def default_jobs(value: str | None) -> str:
    if value:
        return value
    count = os.cpu_count() or 1
    return str(max(1, (count + 1) // 2))


def find_vivado() -> str:
    vivado = os.environ.get("VIVADO", "")
    if vivado and os.access(vivado, os.X_OK):
        return str(resolve_m(vivado))

    found = shutil.which("vivado")
    if found:
        return found

    roots: list[str] = []
    roots.extend(v for v in (os.environ.get("VIVADO_HOME"), os.environ.get("XILINX_VIVADO")) if v)
    for root in roots:
        for candidate in (Path(root) / "bin" / "vivado", Path(root) / "Vivado" / "bin" / "vivado"):
            if os.access(candidate, os.X_OK):
                return str(resolve_m(candidate))

    settings_candidates: list[Path] = []
    if os.environ.get("XILINX_SETTINGS64"):
        settings_candidates.append(Path(os.environ["XILINX_SETTINGS64"]))
    for root in roots:
        settings_candidates.extend([Path(root) / "settings64.sh", Path(root) / "Vivado" / "settings64.sh"])

    for settings in settings_candidates:
        if not settings.is_file():
            continue
        proc = subprocess.run(
            [
                "bash",
                "-lc",
                'source "$1" >/dev/null 2>&1 || exit 0; '
                'vivado_path=$(command -v vivado || true); '
                '[ -n "$vivado_path" ] || exit 0; '
                'printf "%s\\n__ENV__\\n" "$vivado_path"; env -0',
                "bash",
                str(settings),
            ],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=False,
        )
        if proc.returncode != 0 or b"\n__ENV__\n" not in proc.stdout:
            continue
        vivado_bytes, env_bytes = proc.stdout.split(b"\n__ENV__\n", 1)
        vivado_path = vivado_bytes.decode(errors="replace").strip()
        for item in env_bytes.split(b"\0"):
            if not item or b"=" not in item:
                continue
            key, value = item.split(b"=", 1)
            os.environ[key.decode(errors="replace")] = value.decode(errors="replace")
        if vivado_path:
            return vivado_path

    raise SystemExit(
        "ERROR: vivado not found. Put vivado in PATH, set VIVADO=/path/to/vivado, "
        "or set VIVADO_HOME/XILINX_VIVADO/XILINX_SETTINGS64."
    )


def resolve_vivado(vivado_bin: str, dry_run: bool) -> str:
    if dry_run:
        return vivado_bin

    resolved = shutil.which(vivado_bin)
    if resolved is None and vivado_bin == "vivado":
        resolved = find_vivado()
    if resolved is None:
        raise SystemExit(
            f"ERROR: vivado not found: {vivado_bin}\n"
            "Set --vivado /path/to/vivado or run this on the Vivado host with vivado in PATH."
        )
    if not os.access(resolved, os.X_OK):
        raise SystemExit(f"ERROR: vivado not executable: {resolved}")

    os.environ["PATH"] = str(Path(resolved).parent) + os.pathsep + os.environ.get("PATH", "")
    return resolved


def vivado_version(vivado_cmd: str, dry_run: bool) -> str:
    if dry_run:
        return "dry-run"
    try:
        proc = subprocess.run(
            [vivado_cmd, "-version"],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except OSError:
        return ""
    return proc.stdout.splitlines()[0] if proc.stdout.splitlines() else ""


def write_lines(path: Path, lines: Iterable[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def make_cmd(
    fpga_diff_dir: Path,
    target: str,
    cpu: str,
    suffix: str,
    *,
    core_dir: Path | None = None,
    jobs: str | None = None,
) -> list[str]:
    cmd = ["make", "-C", str(fpga_diff_dir), target, f"CPU={cpu}", f"SUFFIX={suffix}"]
    if core_dir is not None:
        cmd.append(f"CORE_DIR={core_dir}")
    if jobs:
        cmd.append(f"VIVADO_JOBS={jobs}")
    return cmd


def vivado_batch_cmd(vivado_cmd: str, source: Path, *tclargs: object) -> list[str]:
    return [
        vivado_cmd,
        "-mode",
        "batch",
        "-source",
        str(source),
        "-tclargs",
        *[str(arg) for arg in tclargs],
    ]


def write_empty_stage(out_dir: Path, label: str, message: str) -> None:
    log = out_dir / "logs" / f"{label}.log"
    time_file = out_dir / "logs" / f"{label}.time"
    write_lines(log, [message.rstrip()])
    write_lines(time_file, ["elapsed_sec="])
    print(message)


class FlowRunner:
    def __init__(
        self,
        out_dir: Path,
        dry_run: bool = False,
        dry_skip: Callable[[str], bool] | None = None,
    ) -> None:
        self.out_dir = out_dir
        self.logs_dir = out_dir / "logs"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.dry_run = dry_run
        self.dry_skip = dry_skip or (lambda _label: True)

    def record_dry_run(self, label: str, cmd: Sequence[str]) -> int:
        log_file = self.logs_dir / f"{label}.log"
        time_file = self.logs_dir / f"{label}.time"
        command = shlex.join(str(part) for part in cmd)
        time_file.write_text(f"dry_run_command={command}\n", encoding="utf-8")
        log_file.write_text(command + "\n", encoding="utf-8")
        print(command)
        return 0

    def run(self, label: str, cmd: Sequence[str], check: bool = True) -> int:
        cmd = [str(part) for part in cmd]
        log_file = self.logs_dir / f"{label}.log"
        time_file = self.logs_dir / f"{label}.time"
        print(f"INFO: [{label}] {shlex.join(cmd)}")
        if self.dry_run and self.dry_skip(label):
            return self.record_dry_run(label, cmd)

        start = time.monotonic()
        before = resource.getrusage(resource.RUSAGE_CHILDREN)
        with log_file.open("w", encoding="utf-8", errors="replace") as log:
            try:
                proc = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    errors="replace",
                )
            except OSError as exc:
                log.write(f"ERROR: {exc}\n")
                if check:
                    raise SystemExit(1) from exc
                return 1
            assert proc.stdout is not None
            for line in proc.stdout:
                sys.stdout.write(line)
                log.write(line)
            rc = proc.wait()
        after = resource.getrusage(resource.RUSAGE_CHILDREN)
        elapsed = time.monotonic() - start
        user = max(0.0, after.ru_utime - before.ru_utime)
        sys_sec = max(0.0, after.ru_stime - before.ru_stime)
        max_rss = max(0, after.ru_maxrss - before.ru_maxrss)
        time_file.write_text(
            f"elapsed_sec={elapsed:.2f}\n"
            f"user_sec={user:.2f}\n"
            f"sys_sec={sys_sec:.2f}\n"
            f"max_rss_kb={max_rss}\n",
            encoding="utf-8",
        )
        if rc != 0 and check:
            raise SystemExit(rc)
        return rc
