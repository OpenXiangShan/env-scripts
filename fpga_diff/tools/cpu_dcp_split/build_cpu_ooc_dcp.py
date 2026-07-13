#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import os
import shlex
from pathlib import Path

import flow_common as flow


DEFAULT_DEFINES = (
    "XIANGSHAN_FPGA,RANDOMIZE_GARBAGE_ASSIGN,RANDOMIZE_REG_INIT,"
    "RANDOMIZE_MEM_INIT,RANDOMIZE_DELAY=1,SRAM_SYN"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build an out-of-context CPU synthesis checkpoint "
            "from a FpgaDiff release RTL directory."
        )
    )
    parser.add_argument("--release", required=True, help="Release directory")
    parser.add_argument("--cpu", choices=["kmh", "nanhu", "nutshell"], default="kmh")
    parser.add_argument("--top", help="OOC top module")
    parser.add_argument("--out-dir", help="Output directory")
    parser.add_argument("--vivado", default=os.environ.get("VIVADO", "vivado"))
    parser.add_argument("--defines", default=DEFAULT_DEFINES)
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    paths = flow.init_paths(__file__)
    release_dir = Path(args.release).resolve()
    rtl_dir = release_dir / "build" / "rtl"
    flow.require_existing_dir(rtl_dir, "RTL directory")

    top_module = args.top
    if not top_module:
        top_module = "NutShell" if args.cpu == "nutshell" else "XSTop"

    if args.out_dir:
        out_dir = flow.resolve_m(args.out_dir)
    else:
        stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        out_dir = paths.repo_root / "build" / "fpga-diff-cpu-dcp" / args.cpu / f"{stamp}-{top_module}"
    (out_dir / "logs").mkdir(parents=True, exist_ok=True)

    vivado_cmd = flow.resolve_vivado(args.vivado, args.dry_run)
    manifest = [
        f"repo_root={paths.repo_root}",
        f"release_dir={release_dir}",
        f"rtl_dir={rtl_dir}",
        f"cpu={args.cpu}",
        f"top_module={top_module}",
        f"out_dir={out_dir}",
        f"defines={args.defines}",
        f"dry_run={int(args.dry_run)}",
        f"vivado_command={vivado_cmd}",
    ]
    flow.write_lines(out_dir / "manifest.env", manifest)

    cmd = [
        vivado_cmd,
        "-mode",
        "batch",
        "-source",
        str(paths.script_dir / "build_cpu_ooc_dcp.tcl"),
        "-tclargs",
        str(rtl_dir),
        top_module,
        str(out_dir),
        "xcvu19p-fsva3824-2-e",
        args.defines,
    ]
    command_log = out_dir / "logs" / "vivado-command.log"
    command_log.write_text(shlex.join(cmd) + "\n", encoding="utf-8")

    runner = flow.FlowRunner(out_dir, dry_run=args.dry_run)
    runner.run("vivado", cmd)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
