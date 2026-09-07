"""CLI entry point for the OpenXiangShan OSS statistics robot."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Dict

from dingtalk_robot.config import ConfigError, DEFAULT_CONFIG_PATH, load_config, require_string
from dingtalk_robot.robot import DingTalkError, send_markdown

from .excel import export_xlsx
from .github import GitHubClient, GitHubError
from .metrics import collect_statistics, render_markdown
from .period import resolve_period


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Collect OpenXiangShan GitHub statistics and notify DingTalk"
    )
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG_PATH)
    parser.add_argument("--output", type=Path, help="Override the JSON output path")
    parser.add_argument(
        "--xlsx-output", type=Path, help="Override the Excel output path"
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
    parser.add_argument(
        "--dry-run", action="store_true", help="Collect and print without sending DingTalk"
    )
    return parser.parse_args()


def integer_setting(
    settings: Dict[str, Any], section: str, name: str, default: int
) -> int:
    value = settings.get(name, default)
    if isinstance(value, bool) or not isinstance(value, int):
        raise ConfigError(f"{section}.{name} must be an integer")
    return value


def github_token(github_config: Dict[str, Any], config_path: Path) -> str:
    token = github_config.get("token", "")
    if isinstance(token, str) and token.strip():
        return token.strip()

    token_file = github_config.get("token_file", "")
    if not isinstance(token_file, str) or not token_file.strip():
        return ""
    token_path = Path(token_file)
    if not token_path.is_absolute():
        token_path = config_path.resolve().parent / token_path
    try:
        token = token_path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise ConfigError(f"Cannot read github.token_file: {token_path}: {exc}") from exc
    if not token:
        raise ConfigError(f"GitHub token file is empty: {token_path}")
    return token


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
        token = github_token(github_config, args.config)
        if not token:
            raise ConfigError("GitHub token is required for per-repository history")
        timezone_name = str(settings.get("timezone", "Asia/Shanghai"))
        period = resolve_period(
            timezone_name, month=args.month, start=args.start, end=args.end
        )
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
        top_repositories = integer_setting(
            settings, "oss_stats", "top_repositories", 10
        )
        message = render_markdown(report, top_repositories)

        output = args.output
        if output is None:
            configured_output = str(
                settings.get("output", "oss_stats/reports/{period}.json")
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
                settings.get("xlsx_output", "oss_stats/reports/{period}.xlsx")
            ).format(period=report["period"]["label"])
            xlsx_output = args.config.resolve().parent / configured_xlsx_output
        export_xlsx(report, xlsx_output)
        print(message)
        print(f"\nJSON report: {output}")
        print(f"Excel report: {xlsx_output}")

        if not args.dry_run:
            webhook = require_string(config, "dingtalk", "webhook")
            secret = require_string(config, "dingtalk", "secret")
            send_markdown(
                webhook,
                secret,
                f"{organization} {report['period']['label']} 开源生态统计",
                message,
            )
            print("DingTalk message sent successfully")
        return 0
    except (ConfigError, DingTalkError, GitHubError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
