"""CLI entry point for local OpenXiangShan OSS statistics reports."""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict

from .config import ConfigError, DEFAULT_CONFIG_PATH, load_config, require_string

from .excel import export_xlsx
from .github import GitHubClient, GitHubError
from .metrics import collect_statistics, render_markdown
from .period import resolve_period
from .stars import apply_star_baseline, load_history, load_snapshot, previous_month_snapshot, save_snapshot


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect OpenXiangShan GitHub statistics and export local reports"
    )
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG_PATH)
    parser.add_argument("--output", type=Path, help="Override the JSON output path")
    parser.add_argument(
        "--xlsx-output", type=Path, help="Override the Excel output path"
    )
    parser.add_argument(
        "--star-baseline", type=Path,
        help="Compare current Stars with a saved snapshot or monitor report",
    )
    parser.add_argument(
        "--month", metavar="YYYY-MM", help="Report a calendar month instead of the previous month"
    )
    parser.add_argument(
        "--start", help="Custom inclusive ISO date or datetime (requires --end)"
    )
    parser.add_argument(
        "--end", help="Custom exclusive ISO date or datetime (requires --start)"
    )
    return parser.parse_args()


def integer_setting(
    settings: Dict[str, Any], section: str, name: str, default: int
) -> int:
    value = settings.get(name, default)
    if isinstance(value, bool) or not isinstance(value, int):
        raise ConfigError(f"{section}.{name} must be an integer")
    return value


def main() -> int:
    args = parse_args()
    try:
        config = load_config(args.config)
        github_config = config.get("github")
        if not isinstance(github_config, dict):
            raise ConfigError("Missing configuration object: github")
        settings = config.get("oss_stats", {})
        if not isinstance(settings, dict):
            raise ConfigError("oss_stats must be an object")

        organization = require_string(config, "github", "organization")
        token = os.environ.get("GITHUB_TOKEN", "").strip()
        if not token:
            raise ConfigError("GitHub token is required: set the GITHUB_TOKEN environment variable")
        timezone_name = str(settings.get("timezone", "Asia/Shanghai"))
        period = resolve_period(
            timezone_name, month=args.month, start=args.start, end=args.end
        )
        star_history_path = args.config.resolve().parent / str(
            settings.get("star_history", "star_history.json")
        )
        history = load_history(star_history_path)
        explicit_baseline = load_snapshot(args.star_baseline) if args.star_baseline else None
        client = GitHubClient(
            token=token,
            api_url=str(github_config.get("api_url", "https://api.github.com")),
            api_version=str(github_config.get("api_version", "2026-03-10")),
            proxy=str(github_config.get("proxy", "")),
            timeout=integer_setting(github_config, "github", "timeout_seconds", 10),
        )
        report = collect_statistics(
            client,
            organization,
            start=period.start,
            end=period.end,
            timezone_name=period.timezone_name,
            include_archived=bool(settings.get("include_archived", True)),
            include_forks=bool(settings.get("include_forks", True)),
            aggregate_forks=bool(settings.get("aggregate_forks", False)),
            max_history_pages=integer_setting(
                settings, "oss_stats", "max_history_pages", 50
            ),
            max_actions_requests=integer_setting(
                settings, "oss_stats", "max_actions_requests", 500
            ),
            progress=lambda message: print(message, flush=True),
        )
        baseline = (
            explicit_baseline if args.star_baseline else
            previous_month_snapshot(
                history, organization, report["generated_at"], timezone_name,
                report["aggregation"]["includes_fork_repositories"],
            )
        )
        snapshot = apply_star_baseline(report, baseline)
        if args.star_baseline:
            save_snapshot(star_history_path, baseline)
        save_snapshot(star_history_path, snapshot)
        top_repositories = integer_setting(
            settings, "oss_stats", "top_repositories", 10
        )
        summary_markdown = render_markdown(report, top_repositories)

        output = args.output
        if output is None:
            configured_output = str(
                settings.get("output", "reports/{period}.json")
            ).format(period=report["period"]["label"])
            output = args.config.resolve().parent / configured_output
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        xlsx_output = args.xlsx_output
        if xlsx_output is None and args.output is not None:
            xlsx_output = output.with_suffix(".xlsx")
        if xlsx_output is None:
            configured_xlsx_output = str(
                settings.get("xlsx_output", "reports/{period}.xlsx")
            ).format(period=report["period"]["label"])
            xlsx_output = args.config.resolve().parent / configured_xlsx_output
        export_xlsx(report, xlsx_output)
        print(summary_markdown)
        print(f"\nJSON report: {output}")
        print(f"Excel report: {xlsx_output}")

        return 0
    except (ConfigError, GitHubError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
