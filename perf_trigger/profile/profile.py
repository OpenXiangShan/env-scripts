#!/usr/bin/env python3
"""Update and inspect SPEC checkpoint runtime profiles."""

import argparse
from collections import defaultdict, deque
import json
from pathlib import Path
import re
import statistics
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


def load_profile(profile_path: Path) -> dict:
    with profile_path.open("r", encoding="utf-8") as profile_file:
        profile = json.load(profile_file)

    if not isinstance(profile, dict):
        raise ValueError(f"Profile must contain a JSON object: {profile_path}")
    return profile


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
    if len(parts) != 3:
        return None
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
                # Match a success line first.
                match = SUCCESS_RE.search(line)
                if match:
                    checkpoint = parse_checkpoint_name(
                        match.group("checkpoint"), known
                    )
                    pending[match.group("progress")].append(checkpoint)
                    continue

                # The next line should be an elapsed line.
                match = ELAPSED_RE.search(line)
                if not match:
                    continue

                progress = match.group("progress")
                queue = pending.get(progress)
                if not queue:
                    continue

                checkpoint = queue.popleft()
                if not queue:
                    del pending[progress]
                if checkpoint is not None:
                    runtimes[checkpoint].append(float(match.group("elapsed")))

    return dict(runtimes)


def update_profile(profile_path: Path, log_files: list[Path]) -> tuple[int, int]:
    """Replace profile runtimes with averages found in runner logs."""
    profile = load_profile(profile_path)
    known = get_known_checkpoints(profile)
    runtimes = get_runtimes(log_files, known)

    for (benchmark, point), samples in runtimes.items():
        profile[benchmark]["points"][point] = sum(samples) / len(samples)

    with profile_path.open("w", encoding="utf-8") as profile_file:
        json.dump(profile, profile_file, indent=4, ensure_ascii=False)

    return len(runtimes), sum(len(samples) for samples in runtimes.values())


def get_profile_runtimes(profile: dict) -> dict[str, list[float]]:
    """Return numeric point runtimes grouped by benchmark."""
    runtimes: dict[str, list[float]] = {}
    for benchmark, benchmark_profile in profile.items():
        if not isinstance(benchmark_profile, dict):
            continue
        points = benchmark_profile.get("points")
        if not isinstance(points, dict):
            continue

        benchmark_runtimes = []
        for runtime in points.values():
            if isinstance(runtime, bool):
                continue
            try:
                benchmark_runtimes.append(float(runtime))
            except (TypeError, ValueError):
                continue
        runtimes[str(benchmark)] = benchmark_runtimes
    return runtimes


def runtime_distribution(runtimes: list[float]) -> list[tuple[str, int]]:
    distribution = {
        "< 0": 0,
        "0": 0,
        "(0, 5,000]": 0,
        "(5,000, 7,500]": 0,
        "(7,500, 10,000]": 0,
        "(10,000, 15,000]": 0,
        "(15,000, 20,000]": 0,
        "(20,000, 30,000]": 0,
        "(30,000, 40,000]": 0,
        "> 40,000": 0,
    }
    for runtime in runtimes:
        if runtime < 0:
            bucket = "< 0"
        elif runtime == 0:
            bucket = "0"
        elif runtime <= 5000:
            bucket = "(0, 5,000]"
        elif runtime <= 7500:
            bucket = "(5,000, 7,500]"
        elif runtime <= 10000:
            bucket = "(7,500, 10,000]"
        elif runtime <= 15000:
            bucket = "(10,000, 15,000]"
        elif runtime <= 20000:
            bucket = "(15,000, 20,000]"
        elif runtime <= 30000:
            bucket = "(20,000, 30,000]"
        elif runtime <= 40000:
            bucket = "(30,000, 40,000]"
        else:
            bucket = "> 40,000"
        distribution[bucket] += 1
    return list(distribution.items())


def format_seconds(value: float) -> str:
    return f"{value:.6g}"


def show_profile(profile_path: Path) -> None:
    profile = load_profile(profile_path)
    benchmark_runtimes = get_profile_runtimes(profile)
    runtimes = [
        runtime
        for values in benchmark_runtimes.values()
        for runtime in values
    ]
    measured = [runtime for runtime in runtimes if runtime > 0]
    unmeasured = sum(runtime == 0 for runtime in runtimes)

    print(f"Profile: {profile_path}")
    print(f"Benchmarks: {len(benchmark_runtimes)}")
    print(f"Checkpoints: {len(runtimes)}")
    print(f"Measured checkpoints: {len(measured)}")
    print(f"Unmeasured checkpoints: {unmeasured}")

    print("\nRuntime statistics (measured checkpoints, seconds):")
    if measured:
        print(f"  Average: {format_seconds(statistics.mean(measured))}")
        print(f"  Median:  {format_seconds(statistics.median(measured))}")
        print(f"  Minimum: {format_seconds(min(measured))}")
        print(f"  Maximum: {format_seconds(max(measured))}")
    else:
        print("  No measured runtimes.")

    print("\nRuntime distribution (seconds):")
    total = len(runtimes)
    for bucket, count in runtime_distribution(runtimes):
        percentage = count / total * 100 if total else 0
        print(f"  {bucket:>18}: {count:4d} ({percentage:5.1f}%)")

    print("\nBenchmark statistics (seconds):")
    print(
        f"  {'Benchmark':<30} {'Points':>6} {'Measured':>9} "
        f"{'Average':>12} {'Minimum':>12} {'Maximum':>12}"
    )
    for benchmark in sorted(benchmark_runtimes):
        values = benchmark_runtimes[benchmark]
        measured_values = [runtime for runtime in values if runtime > 0]
        if measured_values:
            average = format_seconds(statistics.mean(measured_values))
            minimum = format_seconds(min(measured_values))
            maximum = format_seconds(max(measured_values))
        else:
            average = minimum = maximum = "-"
        print(
            f"  {benchmark:<30} {len(values):6d} {len(measured_values):9d} "
            f"{average:>12} {minimum:>12} {maximum:>12}"
        )


def main():
    parser = argparse.ArgumentParser(
        description="Update or inspect SPEC checkpoint runtime profiles."
    )
    parser.add_argument(
        "--update",
        action="store_true",
        help="Update profile runtimes from runner logs",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="Show profile runtime statistics",
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
        help=f"Profile JSON to update or show (default: {DEFAULT_PROFILE_PATH})",
    )

    args = parser.parse_args()

    if not args.update and not args.show:
        parser.print_help()
        return
    if not args.profile.is_file():
        raise FileNotFoundError(f"profile does not exist: {args.profile}")

    if args.update:
        if not args.log_root.is_dir():
            raise ValueError(f"log_path is not a directory: {args.log_root}")

        files = sorted(
            path for path in args.log_root.glob("*/runner*.log") if path.is_file()
        )
        if not files:
            print(
                f"No runner logs found under {args.log_root}; "
                "profile was not changed."
            )
        else:
            updated, samples = update_profile(args.profile, files)
            print(
                f"Updated {updated} checkpoints from {samples} runtime samples "
                f"in {len(files)} runner logs."
            )

    if args.show:
        show_profile(args.profile)


if __name__ == "__main__":
    main()
