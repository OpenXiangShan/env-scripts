#!/usr/bin/env python3
"""Update SPEC checkpoint runtime profiles from perf-trigger runner logs."""

import argparse
from collections import defaultdict, deque
import json
from pathlib import Path
import re
from typing import Deque

DEFAULT_LOG_ROOT = Path("/nfs/home/ci-runner/perf-report")
DEFAULT_PROFILE_PATH = (
    Path(__file__).resolve().parent / "spec06_gcc15_rv64gcb_base_260604.json"
)

SUCCESS_RE = re.compile(
    r"\[(?P<progress>[^\]]+)\]\s+" r"(?P<checkpoint>\S+)\s+succeeded\s+on\b"
)
ELAPSED_RE = re.compile(
    r"\[(?P<progress>[^\]]+)\]\s+\.\.\.\s+elapsed:\s+"
    r"(?P<elapsed>[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\b"
)


def get_known_checkpoints(profile: dict) -> set[tuple[str, str]]:
    """Return checkpoint identifiers represented by the profile."""
    checkpoints: set[tuple[str, str]] = set()
    for benchmark, benchmark_profile in profile.items():
        if not isinstance(benchmark_profile, dict):
            continue
        points = benchmark_profile.get("points")
        if not isinstance(points, dict):
            continue
        checkpoints.update((str(benchmark), str(point)) for point in points)
    return checkpoints


def parse_checkpoint_name(
    name: str, known: set[tuple[str, str]]
) -> tuple[str, str] | None:
    """Map ``benchmark_point_weight`` to a checkpoint in the profile."""
    parts = name.rsplit("_", 2)
    checkpoint = (parts[0], parts[1])
    return checkpoint if checkpoint in known else None


def get_runtimes(
    log_files: list[Path],
    known: set[tuple[str, str]],
) -> dict[tuple[str, str], list[float]]:
    """Collect all complete checkpoint runtime samples from runner logs."""
    runtimes: dict[tuple[str, str], list[float]] = defaultdict(list)
    for log_path in log_files:
        pending: dict[str, Deque[tuple[str, str] | None]] = defaultdict(deque)

        with log_path.open("r", encoding="utf-8", errors="replace") as log_file:
            for line in log_file:
                # match a success line first
                m = SUCCESS_RE.search(line)
                if m:
                    checkpoint = parse_checkpoint_name(m.group("checkpoint"), known)
                    pending[m.group("progress")].append(checkpoint)
                    continue

                # the next line should be an elapsed line
                m = ELAPSED_RE.search(line)
                if not m:
                    continue

                progress = m.group("progress")
                queue = pending.get(progress)
                if not queue:
                    continue

                checkpoint = queue.popleft()
                if not queue:
                    del pending[progress]
                if checkpoint is not None:
                    runtimes[checkpoint].append(float(m.group("elapsed")))

    return dict(runtimes)


def update_profile(profile_path: Path, log_files: list[Path]) -> tuple[int, int]:
    """Replace profile runtimes with averages found in runner logs."""
    with profile_path.open("r", encoding="utf-8") as profile_file:
        profile = json.load(profile_file)

    if not isinstance(profile, dict):
        raise ValueError(f"Profile must contain a JSON object: {profile_path}")

    known = get_known_checkpoints(profile)
    runtimes = get_runtimes(log_files, known)

    # calculate averages
    for (benchmark, point), samples in runtimes.items():
        profile[benchmark]["points"][point] = sum(samples) / len(samples)

    with profile_path.open("w", encoding="utf-8") as profile_file:
        json.dump(profile, profile_file, indent=4, ensure_ascii=False)

    return len(runtimes), sum(len(samples) for samples in runtimes.values())


def main():
    parser = argparse.ArgumentParser(
        description="Update checkpoint runtime averages from runner logs."
    )
    parser.add_argument(
        "--log-root",
        type=Path,
        default=DEFAULT_LOG_ROOT,
        help=f"Root containing */runner*.log (default: {DEFAULT_LOG_ROOT})",
    )
    parser.add_argument(
        "--profile",
        type=Path,
        default=DEFAULT_PROFILE_PATH,
        help=f"Profile JSON to update (default: {DEFAULT_PROFILE_PATH})",
    )

    args = parser.parse_args()

    if not args.log_root.is_dir():
        raise ValueError(f"log_path is not a directory: {args.log_root}")
    if not args.profile.is_file():
        raise FileNotFoundError(f"profile does not exist: {args.profile}")

    files = sorted(
        path for path in args.log_root.glob("*/runner*.log") if path.is_file()
    )
    if not files:
        print(f"No runner logs found under {args.log_root}; profile was not changed.")
        return

    updated, samples = update_profile(args.profile, files)
    print(
        f"Updated {updated} checkpoints from {samples} runtime samples "
        f"in {len(files)} runner logs."
    )


if __name__ == "__main__":
    main()
