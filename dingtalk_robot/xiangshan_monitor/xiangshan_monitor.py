"""Daily OpenXiangShan progress and DingTalk praise robot.

The checked-in files under ``xiangshan_monitor/`` describe repositories, prompt
wording, scheduling, and context limits. The ignored ``dingtalk_robot/config.json``
contains DingTalk credentials and the private local AI endpoint/key.

``pull`` is Git-only, ``talk`` uses the configured local API, and ``push`` is
DingTalk-only. Long reports use an explicit map-reduce strategy: independent
commit chunks are summarized first, then one final call writes the message.
"""

from __future__ import annotations

import argparse
import json
import math
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Mapping, Optional, Sequence, Tuple, Union
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

try:
    from dingtalk_robot.config import ConfigError, DEFAULT_CONFIG_PATH, load_config, require_string
    from dingtalk_robot.robot import DingTalkError, send_text
except ModuleNotFoundError as exc:
    # Allow ``python dingtalk_robot/xiangshan_monitor/xiangshan_monitor.py``
    # as well as importing the script from the dingtalk_robot package.
    if exc.name != "dingtalk_robot":
        raise
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
    from dingtalk_robot.config import ConfigError, DEFAULT_CONFIG_PATH, load_config, require_string
    from dingtalk_robot.robot import DingTalkError, send_text


DEFAULT_TIMEZONE = "Asia/Shanghai"
DEFAULT_MONITOR_DIR = Path(__file__).resolve().parent
DEFAULT_REPOSITORY_DATA = DEFAULT_MONITOR_DIR / "repositories.json"
DEFAULT_PROMPT_PATH = DEFAULT_MONITOR_DIR / "prompt.txt"
DEFAULT_WORKDAY_CALENDAR = DEFAULT_MONITOR_DIR / "workdays.json"
DEFAULT_DELIVERY_HISTORY = DEFAULT_MONITOR_DIR / "delivery_history.json"
DEFAULT_ANALYSIS_WINDOW = "24h"
DEFAULT_CLONE_DIR = "dingtalk_robot/xiangshan_monitor/repos"
DEFAULT_REPORT_PATH = "dingtalk_robot/xiangshan_monitor/reports/{date}-{window}.json"
DEFAULT_MESSAGE_PATH = "dingtalk_robot/xiangshan_monitor/reports/{date}-{window}.md"
DEFAULT_GIT_TIMEOUT = 900.0
DEFAULT_API_TIMEOUT = 90.0
DEFAULT_CONTEXT_WINDOW_TOKENS = 120000
DEFAULT_MAX_OUTPUT_TOKENS = 1800
DEFAULT_MAX_API_CALLS = 1
DEFAULT_REASONING_EFFORT = "xhigh"
DEFAULT_DINGTALK_LAYER = "debug"
DEFAULT_HIGHLIGHT_COUNT = 1
DEFAULT_ANALYSIS_START_TIME = "17:49"
DEFAULT_DEBUG_SEND_TIME = "17:55"
DEFAULT_RELEASE_SEND_TIME = "18:00"
API_FAILURE_MESSAGE = "呜呜呜，API访问不通，我今天不知道该说什么了"
_DINGTALK_LAYERS = frozenset({"debug", "release"})
_REPOSITORY_NAME = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
_PR_MERGE_SUBJECT = re.compile(r"\bmerge\s+pull\s+request\s+#(\d+)", re.IGNORECASE)
_PR_SQUASH_SUBJECT = re.compile(r"\(#(\d+)\)")


class XiangShanMonitorError(RuntimeError):
    """Raised when a monitor stage cannot complete."""


class LocalAPIError(XiangShanMonitorError):
    """Raised when the configured local AI API does not return usable data."""


class GitHubMetadataError(XiangShanMonitorError):
    """Raised when complete GitHub repository metadata cannot be collected."""


@dataclass(frozen=True)
class RepositorySpec:
    name: str
    branch: Optional[str] = None
    remote: Optional[str] = None


@dataclass(frozen=True)
class AnalysisWindow:
    label: str
    spec: str
    timezone_name: str
    start: datetime
    end: datetime


def load_repository_data(path: Union[Path, str] = DEFAULT_REPOSITORY_DATA) -> Dict[str, Any]:
    data_path = Path(path)
    try:
        data = json.loads(data_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigError(f"Cannot read repository data {data_path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ConfigError(f"Repository data root must be an object: {data_path}")
    data["_source_path"] = str(data_path.resolve())
    return data


def load_workday_calendar(path: Union[Path, str] = DEFAULT_WORKDAY_CALENDAR) -> Dict[str, Any]:
    calendar_path = Path(path)
    try:
        data = json.loads(calendar_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigError(f"Cannot read workday calendar {calendar_path}: {exc}") from exc
    if not isinstance(data, dict) or not isinstance(data.get("years"), dict):
        raise ConfigError(f"Workday calendar must contain a years object: {calendar_path}")
    data["_source_path"] = str(calendar_path.resolve())
    return data


def is_workday(day: date, calendar: Mapping[str, Any]) -> bool:
    """Apply explicit Chinese holiday/makeup overrides to the normal weekday rule."""
    years = calendar.get("years")
    year_data = years.get(str(day.year)) if isinstance(years, Mapping) else None
    if not isinstance(year_data, Mapping):
        raise ConfigError(f"Workday calendar has no data for {day.year}")

    def dates_for(key: str) -> set[str]:
        values = year_data.get(key)
        if not isinstance(values, list) or any(not isinstance(value, str) for value in values):
            raise ConfigError(f"Workday calendar {day.year}.{key} must be a list of dates")
        parsed: set[str] = set()
        for value in values:
            try:
                parsed_day = date.fromisoformat(value)
            except ValueError as exc:
                raise ConfigError(f"Invalid date in workday calendar {day.year}.{key}: {value!r}") from exc
            if parsed_day.year != day.year:
                raise ConfigError(f"Date {value} does not belong to workday calendar year {day.year}")
            parsed.add(value)
        return parsed

    holidays = dates_for("holidays")
    makeup_workdays = dates_for("makeup_workdays")
    overlap = holidays & makeup_workdays
    if overlap:
        raise ConfigError(f"Workday calendar marks dates as both holiday and workday: {', '.join(sorted(overlap))}")
    value = day.isoformat()
    if value in makeup_workdays:
        return True
    if value in holidays:
        return False
    return day.weekday() < 5


def _timezone(name: str) -> ZoneInfo:
    try:
        return ZoneInfo(name)
    except ZoneInfoNotFoundError as exc:
        raise ConfigError(f"Unknown analysis timezone: {name}") from exc


def resolve_time_window(spec: str = DEFAULT_ANALYSIS_WINDOW, timezone_name: str = DEFAULT_TIMEZONE, now: Optional[datetime] = None) -> AnalysisWindow:
    """Return a rolling interval such as ``24h`` or ``7d`` ending now."""
    match = re.fullmatch(r"([1-9][0-9]*)([hdw])", str(spec).strip().lower())
    if not match:
        raise ValueError("Invalid analysis window (use values such as 24h or 7d)")
    amount, unit = int(match.group(1)), match.group(2)
    duration = {"h": timedelta(hours=amount), "d": timedelta(days=amount), "w": timedelta(weeks=amount)}[unit]
    tz = _timezone(timezone_name)
    current = now or datetime.now(tz)
    if current.tzinfo is None:
        current = current.replace(tzinfo=tz)
    end = current.astimezone(tz)
    return AnalysisWindow(end.date().isoformat(), f"{amount}{unit}", timezone_name, end - duration, end)


def repository_specs(data: Mapping[str, Any]) -> List[RepositorySpec]:
    raw = data.get("repositories")
    if not isinstance(raw, list) or not raw:
        raise ConfigError("repositories.json.repositories must be a non-empty list")
    result: List[RepositorySpec] = []
    for entry in raw:
        branch: Optional[str] = None
        remote: Optional[str] = None
        if isinstance(entry, str):
            name = entry.strip()
        elif isinstance(entry, dict):
            value = entry.get("name", entry.get("repository"))
            if not isinstance(value, str):
                raise ConfigError("Each repository entry needs a name")
            name = value.strip()
            if entry.get("branch") is not None:
                if not isinstance(entry["branch"], str) or not entry["branch"].strip():
                    raise ConfigError(f"Invalid branch for repository {name!r}")
                branch = entry["branch"].strip()
            if entry.get("remote") is not None:
                if not isinstance(entry["remote"], str) or not entry["remote"].strip():
                    raise ConfigError(f"Invalid remote for repository {name!r}")
                remote = entry["remote"].strip()
        else:
            raise ConfigError("Repository entries must be strings or objects")
        if not _REPOSITORY_NAME.fullmatch(name):
            raise ConfigError(f"Invalid repository name: {name!r}")
        result.append(RepositorySpec(name, branch, remote))
    return result


def _run_git(args: Sequence[str], cwd: Optional[Path] = None, timeout: float = DEFAULT_GIT_TIMEOUT) -> str:
    command = ["git", *args]
    try:
        result = subprocess.run(command, cwd=str(cwd) if cwd is not None else None, text=True, encoding="utf-8", errors="replace", stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise XiangShanMonitorError(f"Git command failed ({' '.join(command)}): {exc}") from exc
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip() or "unknown error"
        raise XiangShanMonitorError(f"Git command failed ({' '.join(command)}): {detail}")
    return result.stdout


def _branch_name(path: Path, configured: Optional[str], git_runner: Callable[..., str]) -> str:
    if configured:
        return configured
    current = git_runner(["branch", "--show-current"], cwd=path).strip()
    if current:
        return current
    remote_head = git_runner(["symbolic-ref", "--short", "refs/remotes/origin/HEAD"], cwd=path).strip()
    return remote_head[7:] if remote_head.startswith("origin/") else (remote_head or "HEAD")


def clone_or_pull(spec: RepositorySpec, organization: str, clone_root: Path, git_runner: Callable[..., str] = _run_git, timeout: float = DEFAULT_GIT_TIMEOUT) -> Tuple[Path, str]:
    target = clone_root / spec.name
    target.parent.mkdir(parents=True, exist_ok=True)
    remote = spec.remote or f"https://github.com/{organization}/{spec.name}.git"
    if (target / ".git").is_dir():
        git_runner(["fetch", "--prune", "origin"], cwd=target, timeout=timeout)
        branch = _branch_name(target, spec.branch, git_runner)
        if branch != "HEAD":
            current = git_runner(["branch", "--show-current"], cwd=target).strip()
            if current != branch:
                git_runner(["checkout", branch], cwd=target, timeout=timeout)
            git_runner(["pull", "--ff-only", "origin", branch], cwd=target, timeout=timeout)
        return target, branch
    if target.exists() and any(target.iterdir()):
        raise XiangShanMonitorError(f"Clone destination is not an empty Git repository: {target}")
    args: List[str] = ["clone"]
    if spec.branch:
        args.extend(["--branch", spec.branch])
    args.extend([remote, str(target)])
    git_runner(args, timeout=timeout)
    return target, _branch_name(target, spec.branch, git_runner)


def _parse_numstat(lines: Iterable[str]) -> Tuple[List[str], int, int]:
    files: List[str] = []
    additions = deletions = 0
    for line in lines:
        match = re.match(r"^(\d+|-)\s+(\d+|-)\s+(.+)$", line.strip())
        if not match:
            continue
        added, removed, filename = match.groups()
        additions += int(added) if added.isdigit() else 0
        deletions += int(removed) if removed.isdigit() else 0
        files.append(filename)
    return files, additions, deletions


def parse_git_log(output: str, organization: str, repository: str) -> List[Dict[str, Any]]:
    commits: List[Dict[str, Any]] = []
    for raw_record in output.split("\x1e"):
        record = raw_record.strip("\n")
        if not record.strip():
            continue
        fields = record.split("\x1f", 6)
        if len(fields) != 7:
            if commits:
                files, additions, deletions = _parse_numstat(record.splitlines())
                commits[-1]["files"].extend(files)
                commits[-1]["additions"] += additions
                commits[-1]["deletions"] += deletions
            continue
        sha, short_sha, author, email, authored_at, subject, body_and_stats = fields
        lines = body_and_stats.splitlines()
        stat_start = next((i for i, line in enumerate(lines) if re.match(r"^(\d+|-)\s+(\d+|-)\s+.+$", line.strip())), len(lines))
        files, additions, deletions = _parse_numstat(lines[stat_start:])
        commits.append({"sha": sha, "short_sha": short_sha, "author": author, "email": email, "authored_at": authored_at, "subject": subject, "body": "\n".join(lines[:stat_start]).strip(), "files": files, "additions": additions, "deletions": deletions, "url": f"https://github.com/{organization}/{repository}/commit/{sha}"})
    return commits


def collect_repository_commits(path: Path, ref: str, window: AnalysisWindow, organization: str, repository: str, max_commits: Optional[int] = None, git_runner: Callable[..., str] = _run_git) -> List[Dict[str, Any]]:
    if max_commits is not None and max_commits <= 0:
        raise ValueError("max_commits must be greater than zero when set")
    format_string = "%x1e%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s%x1f%b"
    args = ["log", ref, f"--since={window.start.astimezone(timezone.utc).isoformat()}", f"--until={window.end.astimezone(timezone.utc).isoformat()}", "--no-color", f"--format={format_string}", "--numstat"]
    if max_commits is not None:
        args.append(f"-n{max_commits}")
    commits = parse_git_log(git_runner(args, cwd=path), organization, repository)
    for commit in commits:
        commit["diff"] = git_runner(["show", "--format=", "--patch", "--binary", "--find-renames", "--no-ext-diff", "--no-color", commit["sha"]], cwd=path)
    return commits


def _pr_counts(repositories: Iterable[Mapping[str, Any]]) -> Dict[str, int]:
    """Count PRs represented by explicit merge or squash subjects."""
    merged: set[Tuple[str, str]] = set()
    for repository in repositories:
        if not isinstance(repository, Mapping):
            continue
        name = str(repository.get("name", "unknown"))
        commits = repository.get("commits", [])
        if not isinstance(commits, list):
            continue
        for commit in commits:
            if not isinstance(commit, Mapping):
                continue
            subject = str(commit.get("subject", ""))
            merge_numbers = set(_PR_MERGE_SUBJECT.findall(subject))
            squash_numbers = set(_PR_SQUASH_SUBJECT.findall(subject))
            merged.update((name, number) for number in merge_numbers | squash_numbers)
    return {"merged_prs": len(merged)}


def _work_summary(report: Mapping[str, Any]) -> str:
    """Render a factual overview for the AI before the detailed commit data."""
    repositories = report.get("repositories", [])
    totals = report.get("totals", {})
    if not isinstance(totals, Mapping):
        totals = {}
    commit_count = totals.get("commits")
    if not isinstance(commit_count, int):
        commit_count = sum(
            len(item.get("commits", []))
            for item in repositories
            if isinstance(item, Mapping) and isinstance(item.get("commits"), list)
        )
    pr_counts = _pr_counts(repositories if isinstance(repositories, list) else [])
    merged = totals.get("merged_prs", pr_counts["merged_prs"])
    if not isinstance(merged, int):
        merged = pr_counts["merged_prs"]
    summary = (
        "窗口工作汇总（仅按主线 commit 元数据统计）："
        f"主线 commit {commit_count} 个，合入 PR {merged} 个。"
    )
    stars = report.get("stars")
    if isinstance(stars, Mapping) and isinstance(stars.get("total"), int):
        summary += f" 当前 Stars 共 {stars['total']}。"
        growth = stars.get("growth")
        if isinstance(growth, Mapping) and growth.get("available") is True:
            net_change = growth.get("net_change")
            if isinstance(net_change, int):
                sign = "+" if net_change > 0 else ""
                summary += f" 较上次正常发布净变化 {sign}{net_change}。"
            changes = growth.get("repositories")
            if isinstance(changes, Mapping) and changes:
                details = "、".join(
                    f"{name} {'+' if delta > 0 else ''}{delta}"
                    for name, delta in changes.items()
                    if isinstance(name, str) and isinstance(delta, int) and delta != 0
                )
                if details:
                    summary += f" 仓库变化：{details}。"
    return summary


def _report_period_hint(report: Mapping[str, Any]) -> str:
    """Return a natural relative period followed by its concrete date range."""
    raw_spec = str(report.get("analysis_window", DEFAULT_ANALYSIS_WINDOW)).strip().lower()
    match = re.fullmatch(r"([1-9][0-9]*)([hdw])", raw_spec)
    hours = 0
    if match:
        amount, unit = int(match.group(1)), match.group(2)
        hours = amount * {"h": 1, "d": 24, "w": 24 * 7}[unit]
    period = report.get("window")
    start_raw = period.get("start") if isinstance(period, Mapping) else None
    end_raw = period.get("end") if isinstance(period, Mapping) else None
    try:
        start = datetime.fromisoformat(str(start_raw))
        end = datetime.fromisoformat(str(end_raw))
    except (TypeError, ValueError):
        raw_date = str(report.get("date", "")).strip()
        return raw_date or "报告时间"

    def compact(value: datetime) -> str:
        return f"{value.month}月{value.day}日"

    if hours <= 24:
        return f"今天（{compact(end)}）"
    if match and match.group(2) == "d":
        descriptor = f"最近{match.group(1)}天"
    elif match and match.group(2) == "h" and hours % 24 == 0:
        descriptor = f"最近{hours // 24}天"
    else:
        descriptor = f"最近{raw_spec}"
    return f"{descriptor}（{compact(start)}-{compact(end)}）"


def default_highlight_count(window_spec: str) -> int:
    """Choose one to three highlights from a rolling window length."""
    match = re.fullmatch(r"([1-9][0-9]*)([hdw])", str(window_spec).strip().lower())
    if not match:
        raise ValueError("Invalid analysis window (use values such as 24h or 7d)")
    amount, unit = int(match.group(1)), match.group(2)
    hours = amount * {"h": 1, "d": 24, "w": 24 * 7}[unit]
    return max(DEFAULT_HIGHLIGHT_COUNT, min(3, math.ceil(hours / 24)))


def resolve_highlight_count(data: Mapping[str, Any], report: Mapping[str, Any], override: Optional[int] = None) -> int:
    """Return a configured highlight count or the window-based default."""
    value: Any = override if override is not None else data.get("highlight_count")
    if value is None:
        value = default_highlight_count(str(report.get("analysis_window", DEFAULT_ANALYSIS_WINDOW)))
    if isinstance(value, bool) or not isinstance(value, int) or not 1 <= value <= 3:
        raise ConfigError("highlight_count must be an integer from 1 to 3")
    return value


def _relative_path(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve()))
    except ValueError:
        return str(path.resolve())


def _data_path(value: Any, default: Path, root: Path) -> Path:
    configured = default if value is None else Path(str(value))
    return configured if configured.is_absolute() else root / configured


def pull_data(repository_data: Optional[Mapping[str, Any]] = None, window_spec: Optional[str] = None, *, root_dir: Union[Path, str] = ".", now: Optional[datetime] = None, analysis_window: Optional[AnalysisWindow] = None, git_runner: Callable[..., str] = _run_git) -> Dict[str, Any]:
    data = repository_data or load_repository_data()
    organization = data.get("organization")
    if not isinstance(organization, str) or not organization.strip():
        raise ConfigError("repositories.json.organization is required")
    root = Path(root_dir).resolve()
    window = analysis_window or resolve_time_window(window_spec or str(data.get("analysis_window", DEFAULT_ANALYSIS_WINDOW)), str(data.get("timezone", DEFAULT_TIMEZONE)), now)
    clone_root = _data_path(data.get("clone_dir"), Path(DEFAULT_CLONE_DIR), root)
    max_commits = data.get("max_commits")
    if max_commits is not None and (isinstance(max_commits, bool) or not isinstance(max_commits, int) or max_commits < 0):
        raise ConfigError("repositories.json.max_commits must be a non-negative integer when set")
    max_commits = None if max_commits in (None, 0) else max_commits
    timeout = data.get("git_timeout_seconds", DEFAULT_GIT_TIMEOUT)
    if isinstance(timeout, bool) or not isinstance(timeout, (int, float)) or timeout <= 0:
        raise ConfigError("repositories.json.git_timeout_seconds must be positive")
    repositories: List[Dict[str, Any]] = []
    for spec in repository_specs(data):
        item: Dict[str, Any] = {"name": spec.name, "remote": spec.remote or f"https://github.com/{organization}/{spec.name}.git", "path": _relative_path(clone_root / spec.name, root), "status": "error", "branch": spec.branch, "commits": []}
        try:
            path, branch = clone_or_pull(spec, organization, clone_root, git_runner, float(timeout))
            item["path"], item["branch"] = _relative_path(path, root), branch
            item["commits"] = collect_repository_commits(path, branch, window, organization, spec.name, max_commits, git_runner)
            item["status"] = "updated"
        except (OSError, XiangShanMonitorError, ValueError) as exc:
            item["error"] = str(exc)
        repositories.append(item)
    totals = {"repositories": len(repositories), "updated_repositories": sum(item["status"] == "updated" for item in repositories), "repositories_with_errors": sum(item["status"] == "error" for item in repositories), "commits": sum(len(item["commits"]) for item in repositories)}
    totals.update(_pr_counts(repositories))
    return {"kind": "xiangshan-monitor", "organization": organization, "date": window.label, "analysis_window": window.spec, "timezone": window.timezone_name, "window": {"start": window.start.isoformat(), "end": window.end.isoformat()}, "generated_at": datetime.now(timezone.utc).isoformat(), "repositories": repositories, "totals": totals}


def _commit_text(repository: str, commit: Mapping[str, Any]) -> str:
    lines = [f"提交仓库：{repository}", f"提交 SHA：{commit.get('short_sha', '')}", f"提交作者：{commit.get('author', 'unknown')}", f"主题：{commit.get('subject', '')}", f"统计：+{commit.get('additions', 0)}/-{commit.get('deletions', 0)}，文件 {len(commit.get('files', []))} 个"]
    if commit.get("body"):
        lines.append(f"正文：{commit['body']}")
    if commit.get("files"):
        lines.append("文件：" + ", ".join(str(item) for item in commit["files"]))
    if commit.get("diff"):
        lines.extend(["完整改动：", "```diff", str(commit["diff"]).rstrip(), "```"])
    return "\n".join(lines)


def render_pull_summary(report: Mapping[str, Any]) -> str:
    lines = [_work_summary(report), f"OpenXiangShan 最近 {report.get('analysis_window', '')} 的主线开发进展（截至 {report.get('window', {}).get('end', '')}）", f"仓库 {report.get('totals', {}).get('repositories', 0)} 个，提交 {report.get('totals', {}).get('commits', 0)} 个。"]
    for repository in report.get("repositories", []):
        if not isinstance(repository, dict):
            continue
        if repository.get("error"):
            lines.append(f"\n### {repository.get('name', 'unknown')} 拉取失败：{repository['error']}")
            continue
        commits = repository.get("commits", [])
        if not commits:
            lines.append(f"\n### {repository.get('name', 'unknown')}：这个窗口没有主线提交。")
        else:
            lines.extend(["", *(_commit_text(str(repository.get("name", "unknown")), commit) for commit in commits if isinstance(commit, dict))])
    return "\n".join(lines)


def report_path(data: Mapping[str, Any], root_dir: Union[Path, str], window: AnalysisWindow) -> Path:
    configured = data.get("output", DEFAULT_REPORT_PATH)
    if not isinstance(configured, str) or not configured.strip():
        raise ConfigError("repositories.json.output must be a non-empty path")
    path = Path(configured.format(date=window.label, window=window.spec, period=window.label))
    return path if path.is_absolute() else Path(root_dir).resolve() / path


def message_path(data: Mapping[str, Any], root_dir: Union[Path, str], window: AnalysisWindow) -> Path:
    configured = data.get("message_output", DEFAULT_MESSAGE_PATH)
    if not isinstance(configured, str) or not configured.strip():
        raise ConfigError("repositories.json.message_output must be a non-empty path")
    path = Path(configured.format(date=window.label, window=window.spec, period=window.label))
    return path if path.is_absolute() else Path(root_dir).resolve() / path


def write_report(report: Mapping[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def read_report(path: Path) -> Dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise XiangShanMonitorError(f"Cannot read pull report {path}: {exc}") from exc
    if not isinstance(data, dict) or data.get("kind") != "xiangshan-monitor":
        raise XiangShanMonitorError(f"Invalid xiangshan-monitor report: {path}")
    return data


def _required_string(mapping: Mapping[str, Any], key: str) -> str:
    value = mapping.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ConfigError(f"Missing configuration value: xiangshan_monitor.{key}")
    return value.strip()


def local_api_settings(config: Mapping[str, Any], data: Mapping[str, Any]) -> Dict[str, Any]:
    settings = config.get("xiangshan_monitor")
    if not isinstance(settings, dict):
        raise ConfigError("Missing configuration object: xiangshan_monitor")
    api_url = _required_string(settings, "api_url")
    api_key = _required_string(settings, "api_key")
    ai = data.get("ai", {})
    if not isinstance(ai, dict):
        raise ConfigError("repositories.json.ai must be an object")
    model = ai.get("model")
    wire_api = ai.get("wire_api")
    if not isinstance(model, str) or not model.strip():
        raise ConfigError("Missing configuration value: repositories.json.ai.model")
    if not isinstance(wire_api, str) or not wire_api.strip():
        raise ConfigError("Missing configuration value: repositories.json.ai.wire_api")
    context_tokens = ai.get("context_window_tokens", DEFAULT_CONTEXT_WINDOW_TOKENS)
    max_output = ai.get("max_output_tokens", DEFAULT_MAX_OUTPUT_TOKENS)
    map_output = ai.get("map_max_output_tokens", min(max_output, 800))
    timeout = ai.get("timeout_seconds", DEFAULT_API_TIMEOUT)
    max_api_calls = ai.get("max_api_calls", DEFAULT_MAX_API_CALLS)
    reasoning_effort = ai.get("reasoning_effort", DEFAULT_REASONING_EFFORT)
    store = ai.get("store", False)
    http_headers = ai.get("http_headers", {})
    if any(isinstance(value, bool) or not isinstance(value, int) or value <= 0 for value in (context_tokens, max_output, map_output, max_api_calls)):
        raise ConfigError("repositories.json.ai token/call limits must be positive integers")
    if isinstance(timeout, bool) or not isinstance(timeout, (int, float)) or timeout <= 0:
        raise ConfigError("repositories.json.ai.timeout_seconds must be positive")
    if reasoning_effort is not None and (not isinstance(reasoning_effort, str) or not reasoning_effort.strip()):
        raise ConfigError("repositories.json.ai.reasoning_effort must be a non-empty string when set")
    if not isinstance(store, bool):
        raise ConfigError("repositories.json.ai.store must be boolean")
    if not isinstance(http_headers, dict) or any(
        not isinstance(key, str) or not key.strip() or not isinstance(value, str)
        for key, value in http_headers.items()
    ):
        raise ConfigError("repositories.json.ai.http_headers must be a string map")
    wire = wire_api.lower()
    base = api_url.rstrip("/")
    if wire == "responses":
        endpoint = base if base.endswith("/responses") else f"{base}/responses"
    elif wire in {"chat", "chat_completions", "chat-completions"}:
        endpoint = base if base.endswith("/chat/completions") else f"{base}/chat/completions"
    else:
        raise ConfigError("repositories.json.ai.wire_api must be responses or chat_completions")
    return {"api_key": api_key, "endpoint": endpoint, "model": model.strip(), "wire_api": wire, "context_window_tokens": context_tokens, "max_output_tokens": max_output, "map_max_output_tokens": map_output, "timeout": float(timeout), "max_api_calls": max_api_calls, "reasoning_effort": reasoning_effort.strip() if reasoning_effort else None, "store": store, "proxy": "", "http_headers": {key.strip(): value for key, value in http_headers.items()}}


def _prompt_path(data: Mapping[str, Any], root_dir: Union[Path, str]) -> Path:
    configured = data.get("prompt_file")
    if configured is None:
        return DEFAULT_PROMPT_PATH
    path = Path(str(configured))
    return path if path.is_absolute() else Path(root_dir).resolve() / path


def _prompt_text(data: Mapping[str, Any], root_dir: Union[Path, str], source: str, section: str = "final") -> str:
    path = _prompt_path(data, root_dir)
    try:
        content = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise XiangShanMonitorError(f"Cannot read prompt file {path}: {exc}") from exc
    if not content.strip():
        raise XiangShanMonitorError(f"Prompt file is empty: {path}")
    # Keep both the final-writing and map-stage instructions in one readable file.
    marker = f"[{section}]"
    if marker in content:
        template = content.split(marker, 1)[1]
        next_marker = re.search(r"\n\[[A-Za-z0-9_-]+\]\s*\n", template)
        if next_marker:
            template = template[: next_marker.start()]
    elif section == "final":
        template = content
    else:
        raise XiangShanMonitorError(f"Prompt file has no [{section}] section: {path}")
    if not template.strip():
        raise XiangShanMonitorError(f"Prompt section is empty: [{section}] in {path}")
    return template.replace("{source}", source) if "{source}" in template else f"{template.rstrip()}\n\n{source}"


def estimate_tokens(text: str) -> int:
    """Conservative tokenizer-free estimate for UTF-8 text."""
    return max(1, math.ceil(len(text.encode("utf-8")) / 3))


def _response_text(result: Mapping[str, Any]) -> str:
    direct = result.get("output_text")
    if isinstance(direct, str) and direct.strip():
        return direct.strip()
    output = result.get("output")
    chunks: List[str] = []
    if isinstance(output, list):
        for item in output:
            if not isinstance(item, dict):
                continue
            content = item.get("content")
            if isinstance(content, str):
                chunks.append(content)
            elif isinstance(content, list):
                chunks.extend(part["text"] for part in content if isinstance(part, dict) and isinstance(part.get("text"), str))
            elif isinstance(item.get("text"), str):
                chunks.append(item["text"])
    if chunks:
        return "\n".join(chunk.strip() for chunk in chunks if chunk.strip()).strip()
    choices = result.get("choices")
    if isinstance(choices, list) and choices and isinstance(choices[0], dict):
        message = choices[0].get("message", choices[0])
        if isinstance(message, dict) and isinstance(message.get("content"), str):
            return message["content"].strip()
    return ""


def _call_local_api(prompt: str, api: Mapping[str, Any], opener: Any, max_output_tokens: Optional[int] = None) -> str:
    output_tokens = int(max_output_tokens or api["max_output_tokens"])
    if estimate_tokens(prompt) + output_tokens > int(api["context_window_tokens"]):
        raise XiangShanMonitorError("单次 API 请求仍超过 context 上限，请缩短分析窗口或提高 context_window_tokens")
    if api["wire_api"] in {"chat", "chat_completions", "chat-completions"}:
        payload = {
            "model": api["model"],
            "messages": [{"role": "user", "content": prompt}],
            # DeepSeek thinking tokens also count against max_tokens. Leave
            # headroom so the final answer is not truncated after xhigh thinking.
            "max_tokens": max(output_tokens, 8192),
            "thinking": {"type": "enabled"},
            "reasoning_effort": api.get("reasoning_effort") or DEFAULT_REASONING_EFFORT,
        }
    else:
        payload = {
            "model": api["model"],
            "input": prompt,
            "max_output_tokens": output_tokens,
            "store": api["store"],
        }
        if api.get("reasoning_effort"):
            payload["reasoning"] = {"effort": api["reasoning_effort"]}
    headers = {
        "Authorization": f"Bearer {api['api_key']}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    headers.update(api.get("http_headers", {}))
    request = urllib.request.Request(api["endpoint"], data=json.dumps(payload, ensure_ascii=False).encode("utf-8"), headers=headers, method="POST")
    try:
        with opener.open(request, timeout=api["timeout"]) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raise LocalAPIError(f"Local AI API HTTP error {exc.code}: {exc.read().decode('utf-8', errors='replace')}") from exc
    except (urllib.error.URLError, TimeoutError) as exc:
        raise LocalAPIError(f"Cannot connect to local AI API: {getattr(exc, 'reason', str(exc))}") from exc
    except json.JSONDecodeError as exc:
        raise LocalAPIError("Local AI API returned invalid JSON") from exc
    if not isinstance(result, dict):
        raise LocalAPIError("Local AI API returned an unexpected JSON value")
    text = _response_text(result)
    if not text:
        raise LocalAPIError("Local AI API response did not contain message text")
    return text


def _source_chunks(report: Mapping[str, Any], budget_tokens: int) -> List[str]:
    chunks: List[str] = []
    current: List[str] = []
    current_tokens = 0
    for repository in report.get("repositories", []):
        if not isinstance(repository, dict):
            continue
        commits = repository.get("commits", [])
        for commit in commits if isinstance(commits, list) else []:
            if not isinstance(commit, dict):
                continue
            text = _commit_text(str(repository.get("name", "unknown")), commit)
            tokens = estimate_tokens(text)
            if tokens > budget_tokens:
                if current:
                    chunks.append("\n\n".join(current))
                    current, current_tokens = [], 0
                chunks.extend(_split_text(text, budget_tokens))
                continue
            if current and current_tokens + tokens > budget_tokens:
                chunks.append("\n\n".join(current))
                current, current_tokens = [], 0
            current.append(text)
            current_tokens += tokens
    if current:
        chunks.append("\n\n".join(current))
    return chunks or ["这个窗口没有提交。"]


def _text_chunks(items: Sequence[str], budget_tokens: int) -> List[str]:
    """Pack already-generated summaries into context-sized reduce inputs."""
    chunks: List[str] = []
    current: List[str] = []
    current_tokens = 0
    for item in items:
        text = str(item)
        tokens = estimate_tokens(text)
        if tokens > budget_tokens:
            if current:
                chunks.append("\n\n".join(current))
                current, current_tokens = [], 0
            chunks.extend(_split_text(text, budget_tokens))
            continue
        if current and current_tokens + tokens > budget_tokens:
            chunks.append("\n\n".join(current))
            current, current_tokens = [], 0
        current.append(text)
        current_tokens += tokens
    if current:
        chunks.append("\n\n".join(current))
    return chunks or ["没有可用的事实摘要。"]


def _split_text(text: str, budget_tokens: int) -> List[str]:
    """Split even one huge commit without dropping bytes from its textual diff."""
    if budget_tokens <= 0:
        raise ValueError("Chunk token budget must be positive")
    max_bytes = budget_tokens * 3
    parts: List[str] = []
    current: List[str] = []
    current_bytes = 0
    for character in text:
        encoded_bytes = len(character.encode("utf-8"))
        if current and current_bytes + encoded_bytes > max_bytes:
            parts.append("".join(current))
            current, current_bytes = [], 0
        current.append(character)
        current_bytes += encoded_bytes
    if current:
        parts.append("".join(current))
    return parts


def talk(report: Mapping[str, Any], config: Mapping[str, Any], repository_data: Optional[Mapping[str, Any]] = None, *, root_dir: Union[Path, str] = ".", highlight_count: Optional[int] = None, opener: Optional[Any] = None) -> str:
    data = repository_data or load_repository_data()
    api = local_api_settings(config, data)
    selected_highlights = resolve_highlight_count(data, report, highlight_count)
    source = f"消息时间范围参考：{_report_period_hint(report)}。\n本次重点表扬人数：{selected_highlights} 人。\n\n{render_pull_summary(report)}"
    if opener is None:
        # DeepSeek is reachable directly; never inherit http(s)_proxy from the environment.
        opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    direct_prompt = _prompt_text(data, root_dir, source).replace("{highlight_count}", str(selected_highlights))
    if estimate_tokens(direct_prompt) + api["max_output_tokens"] <= api["context_window_tokens"]:
        return _call_local_api(direct_prompt, api, opener)
    strategy = str(data.get("overflow_strategy", "map_reduce")).lower()
    if strategy != "map_reduce":
        raise XiangShanMonitorError(
            f"分析窗口 {report.get('analysis_window', '')} 超过 context {api['context_window_tokens']}；请缩短窗口或启用 overflow_strategy=map_reduce"
        )
    chunk_budget = int(api["context_window_tokens"]) - int(api["max_output_tokens"]) - 1000
    if chunk_budget <= 0:
        raise XiangShanMonitorError("context_window_tokens 太小，无法为 map-reduce 留出输入空间")
    chunks = _source_chunks(report, chunk_budget)
    required_calls = len(chunks) + 1
    if required_calls > int(api["max_api_calls"]):
        raise XiangShanMonitorError(
            f"完整报告需要 {required_calls} 次 API，超过 max_api_calls={api['max_api_calls']}；请缩短窗口或提高上限"
        )
    summaries: List[str] = []
    calls_used = 0
    for index, chunk in enumerate(chunks, 1):
        map_prompt = _prompt_text(
            data,
            root_dir,
            chunk,
            section="map",
        ).replace("{chunk_index}", str(index)).replace("{chunk_total}", str(len(chunks)))
        summaries.append(_call_local_api(map_prompt, api, opener, api["map_max_output_tokens"]))
        calls_used += 1

    reduce_budget = int(api["context_window_tokens"]) - int(api["map_max_output_tokens"]) - 1000
    if reduce_budget <= 0:
        raise XiangShanMonitorError("context_window_tokens 太小，无法为摘要压缩留出输入空间")
    while True:
        final_source = "\n\n".join([f"消息时间范围参考：{_report_period_hint(report)}。", f"本次重点表扬人数：{selected_highlights} 人。", _work_summary(report), *[f"分块摘要 {i}:\n{summary}" for i, summary in enumerate(summaries, 1)]])
        final_prompt = _prompt_text(data, root_dir, final_source).replace("{highlight_count}", str(selected_highlights))
        if estimate_tokens(final_prompt) + api["max_output_tokens"] <= api["context_window_tokens"]:
            if calls_used >= int(api["max_api_calls"]):
                raise XiangShanMonitorError(
                    f"完整报告需要至少 {calls_used + 1} 次 API，超过 max_api_calls={api['max_api_calls']}；请缩短窗口或提高上限"
                )
            return _call_local_api(final_prompt, api, opener)
        if len(summaries) == 1:
            raise XiangShanMonitorError("摘要仍超过 context 上限，请提高 context_window_tokens")
        if calls_used + 1 >= int(api["max_api_calls"]):
            raise XiangShanMonitorError(
                f"摘要压缩需要更多 API 调用，超过 max_api_calls={api['max_api_calls']}；请缩短窗口或提高上限"
            )
        batches = _text_chunks(summaries, reduce_budget)
        if calls_used + len(batches) + 1 > int(api["max_api_calls"]):
            raise XiangShanMonitorError(
                f"摘要压缩需要 {calls_used + len(batches) + 1} 次 API，超过 max_api_calls={api['max_api_calls']}；请提高上限"
            )
        reduced: List[str] = []
        for batch in batches:
            reduce_prompt = _prompt_text(data, root_dir, batch, section="reduce")
            reduced.append(
                _call_local_api(
                    reduce_prompt,
                    api,
                    opener,
                    api["map_max_output_tokens"],
                )
            )
        summaries = reduced
        calls_used += len(batches)


def dingtalk_credentials(config: Mapping[str, Any], section: str = "xiangshan_monitor", layer: str = DEFAULT_DINGTALK_LAYER) -> Tuple[str, str]:
    layer = str(layer).strip().lower()
    if layer not in _DINGTALK_LAYERS:
        raise ConfigError(f"Unknown DingTalk layer: {layer!r} (use debug or release)")
    selected: Mapping[str, Any] = config
    section_value = config.get(section)
    if section_value is not None:
        if not isinstance(section_value, dict):
            raise ConfigError(f"{section} must be an object")
        # Keep `--dingtalk-section dingtalk` compatible with the old global
        # robot while supporting layered monitor credentials.
        if section == "dingtalk" and "webhook" in section_value:
            selected = {"dingtalk": section_value}
        else:
            dingtalk = section_value.get("dingtalk")
            if not isinstance(dingtalk, dict):
                raise ConfigError(f"Missing configuration object: {section}.dingtalk")
            layered = dingtalk.get(layer)
            if isinstance(layered, dict):
                selected = {"dingtalk": layered}
            elif "webhook" in dingtalk or "secret" in dingtalk:
                # Read old flat monitor configs during migration. The debug
                # layer falls back to the legacy top-level robot.
                if layer == "release":
                    selected = {"dingtalk": dingtalk}
                else:
                    selected = config
            else:
                raise ConfigError(f"Missing configuration object: {section}.dingtalk.{layer}")
    return require_string(dict(selected), "dingtalk", "webhook"), require_string(dict(selected), "dingtalk", "secret")


def _plain_text_message(message: str) -> str:
    """Remove common Markdown markers before sending DingTalk plain text."""
    text = re.sub(r"\*\*(.*?)\*\*", r"\1", message)
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"^\s{0,3}#{1,6}\s*", "", text, flags=re.MULTILINE)
    paragraphs = ["\n".join(line.strip() for line in block.splitlines() if line.strip()) for block in re.split(r"\n\s*\n", text)]
    return "\n\n".join(paragraph for paragraph in paragraphs if paragraph).strip()


def push(message: str, config: Mapping[str, Any], *, section: str = "xiangshan_monitor", layer: str = DEFAULT_DINGTALK_LAYER, use_proxy: bool = False) -> Dict[str, Any]:
    if not isinstance(message, str) or not message.strip():
        raise ValueError("DingTalk message must not be empty")
    webhook, secret = dingtalk_credentials(config, section, layer)
    return send_text(webhook, secret, _plain_text_message(message), use_proxy=use_proxy)


def _load_message(path: Path) -> str:
    try:
        message = path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise XiangShanMonitorError(f"Cannot read message file {path}: {exc}") from exc
    if not message:
        raise XiangShanMonitorError(f"Message file is empty: {path}")
    return message


def _configured_path(data: Mapping[str, Any], key: str, default: Path, root: Path) -> Path:
    raw = data.get(key)
    path = default if raw is None else Path(str(raw))
    return path if path.is_absolute() else root / path


def _delivery_times(data: Mapping[str, Any]) -> Tuple[str, str]:
    delivery = data.get("scheduled_delivery", {})
    if not isinstance(delivery, Mapping):
        raise ConfigError("repositories.json.scheduled_delivery must be an object")
    debug_time = str(delivery.get("debug_time", DEFAULT_DEBUG_SEND_TIME))
    release_time = str(delivery.get("release_time", DEFAULT_RELEASE_SEND_TIME))
    debug_parts = _parse_schedule(debug_time)
    release_parts = _parse_schedule(release_time)
    if release_parts <= debug_parts:
        raise ConfigError("scheduled_delivery.release_time must be later than debug_time")
    return debug_time, release_time


def _analysis_start_time(data: Mapping[str, Any]) -> str:
    delivery = data.get("scheduled_delivery", {})
    if not isinstance(delivery, Mapping):
        raise ConfigError("repositories.json.scheduled_delivery must be an object")
    value = str(delivery.get("analysis_start_time", DEFAULT_ANALYSIS_START_TIME))
    start = _parse_schedule(value)
    debug, _ = _delivery_times(data)
    if start >= _parse_schedule(debug):
        raise ConfigError("scheduled_delivery.analysis_start_time must be earlier than debug_time")
    return value


def previous_workday(day: date, calendar: Mapping[str, Any]) -> date:
    """Find the closest earlier workday, including holiday and makeup overrides."""
    candidate = day - timedelta(days=1)
    while True:
        years = calendar.get("years")
        known_year = isinstance(years, Mapping) and str(candidate.year) in years
        # A calendar normally contains the current year. At a year boundary,
        # use the ordinary weekday rule until that older year's official file
        # is added; current-year holiday decisions remain explicit and strict.
        if known_year:
            workday = is_workday(candidate, calendar)
        else:
            workday = candidate.weekday() < 5
        if workday:
            return candidate
        candidate -= timedelta(days=1)


def _scheduled_datetime(day: date, schedule: str, timezone_name: str) -> datetime:
    hour, minute = _parse_schedule(schedule)
    return datetime(day.year, day.month, day.day, hour, minute, tzinfo=_timezone(timezone_name))


def load_delivery_history(path: Path, timezone_name: str) -> Dict[str, Any]:
    if not path.exists():
        return {
            "version": 1,
            "timezone": timezone_name,
            "next_window_start": None,
            "last_successful_release": None,
            "attempts": [],
        }
    try:
        history = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ConfigError(f"Cannot read delivery history {path}: {exc}") from exc
    if not isinstance(history, dict) or history.get("version") != 1:
        raise ConfigError(f"Unsupported delivery history format: {path}")
    if history.get("timezone") != timezone_name:
        raise ConfigError(f"Delivery history timezone does not match {timezone_name}: {path}")
    if not isinstance(history.get("attempts"), list):
        raise ConfigError(f"Delivery history attempts must be a list: {path}")
    return history


def write_delivery_history(history: Mapping[str, Any], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(history, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def _history_window(
    day: date,
    end: datetime,
    timezone_name: str,
    calendar: Mapping[str, Any],
    history: Mapping[str, Any],
    override: Optional[str],
) -> AnalysisWindow:
    if override is not None:
        return resolve_time_window(override, timezone_name, end)
    raw_start = history.get("next_window_start")
    start: Optional[datetime] = None
    if isinstance(raw_start, str):
        try:
            parsed = datetime.fromisoformat(raw_start)
        except ValueError as exc:
            raise ConfigError(f"Invalid next_window_start in delivery history: {raw_start!r}") from exc
        if parsed.tzinfo is None:
            raise ConfigError("delivery history next_window_start must include a timezone")
        start = parsed.astimezone(_timezone(timezone_name))
        if start >= end:
            raise ConfigError("delivery history next_window_start must be earlier than the current analysis time")
    if start is None:
        prior = previous_workday(day, calendar)
        start = end.replace(year=prior.year, month=prior.month, day=prior.day)
    elapsed_days = max(1, (end.date() - start.date()).days)
    return AnalysisWindow(end.date().isoformat(), f"{elapsed_days}d", timezone_name, start, end)


def _pull_failures(report: Mapping[str, Any]) -> List[Dict[str, str]]:
    failures: List[Dict[str, str]] = []
    repositories = report.get("repositories", [])
    if not isinstance(repositories, list):
        return [{"name": "unknown", "error": "report repositories is not a list"}]
    for repository in repositories:
        if isinstance(repository, Mapping) and repository.get("error"):
            failures.append({
                "name": str(repository.get("name", "unknown")),
                "error": str(repository["error"]),
            })
    return failures


def _pull_failure_message(failures: Sequence[Mapping[str, str]]) -> str:
    names = "、".join(str(item.get("name", "unknown")) for item in failures)
    return (
        f"呜呜呜，今天有 {len(failures)} 个仓库拉取失败，数据不完整。"
        f"这次不会调用 AI，也不会发送 release，下一次会从本次尚未完成的时间起点继续汇总。"
        f"失败仓库：{names}"
    )


def _github_metadata_settings(config: Mapping[str, Any], config_path: Path) -> Dict[str, Any]:
    github = config.get("github")
    if not isinstance(github, Mapping):
        raise GitHubMetadataError("Missing configuration object: github")
    token = github.get("token", "")
    if not isinstance(token, str):
        raise GitHubMetadataError("github.token must be a string")
    token = token.strip()
    if not token:
        token_file = github.get("token_file")
        if not isinstance(token_file, str) or not token_file.strip():
            raise GitHubMetadataError("github.token or github.token_file is required for Stars")
        token_path = Path(token_file)
        if not token_path.is_absolute():
            token_path = config_path.resolve().parent / token_path
        try:
            token = token_path.read_text(encoding="utf-8").strip()
        except OSError as exc:
            raise GitHubMetadataError(f"Cannot read GitHub token file {token_path}: {exc}") from exc
        if not token:
            raise GitHubMetadataError(f"GitHub token file is empty: {token_path}")
    api_url = github.get("api_url", "https://api.github.com")
    api_version = github.get("api_version", "2026-03-10")
    proxy = github.get("proxy", "")
    timeout = github.get("timeout_seconds", 30)
    if not isinstance(api_url, str) or not api_url.strip():
        raise GitHubMetadataError("github.api_url must be a non-empty string")
    if not isinstance(api_version, str) or not api_version.strip():
        raise GitHubMetadataError("github.api_version must be a non-empty string")
    if not isinstance(proxy, str):
        raise GitHubMetadataError("github.proxy must be a string")
    if isinstance(timeout, bool) or not isinstance(timeout, (int, float)) or timeout <= 0:
        raise GitHubMetadataError("github.timeout_seconds must be positive")
    return {
        "token": token,
        "endpoint": f"{api_url.rstrip('/')}/graphql",
        "api_version": api_version.strip(),
        "proxy": proxy.strip(),
        "timeout": float(timeout),
    }


def collect_star_snapshot(
    config: Mapping[str, Any],
    repository_data: Mapping[str, Any],
    config_path: Path,
    captured_at: datetime,
    opener: Optional[Any] = None,
) -> Dict[str, Any]:
    """Fetch every monitored repository's current Stars with one GraphQL request."""
    settings = _github_metadata_settings(config, config_path)
    organization = repository_data.get("organization")
    if not isinstance(organization, str) or not organization.strip():
        raise GitHubMetadataError("repositories.json.organization is required for Stars")
    specs = repository_specs(repository_data)
    declarations = ["$owner: String!"]
    fields: List[str] = []
    variables: Dict[str, str] = {"owner": organization.strip()}
    for index, spec in enumerate(specs):
        variable = f"name{index}"
        alias = f"repo{index}"
        declarations.append(f"${variable}: String!")
        variables[variable] = spec.name
        fields.append(
            f"{alias}: repository(owner: $owner, name: ${variable}) "
            "{ name stargazerCount }"
        )
    query = f"query({', '.join(declarations)}) {{ {' '.join(fields)} }}"
    request = urllib.request.Request(
        settings["endpoint"],
        data=json.dumps({"query": query, "variables": variables}).encode("utf-8"),
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {settings['token']}",
            "Content-Type": "application/json; charset=utf-8",
            "User-Agent": "OpenXiangShan-xiangshan-monitor",
            "X-GitHub-Api-Version": settings["api_version"],
        },
        method="POST",
    )
    if opener is None:
        proxy = settings["proxy"]
        handler = urllib.request.ProxyHandler({"http": proxy, "https": proxy}) if proxy else urllib.request.ProxyHandler({})
        opener = urllib.request.build_opener(handler)
    try:
        with opener.open(request, timeout=settings["timeout"]) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise GitHubMetadataError(f"GitHub Stars HTTP error {exc.code}: {detail}") from exc
    except (urllib.error.URLError, TimeoutError) as exc:
        raise GitHubMetadataError(f"Cannot connect to GitHub Stars API: {getattr(exc, 'reason', str(exc))}") from exc
    except json.JSONDecodeError as exc:
        raise GitHubMetadataError("GitHub Stars API returned invalid JSON") from exc
    if not isinstance(result, Mapping):
        raise GitHubMetadataError("GitHub Stars API returned an unexpected value")
    errors = result.get("errors")
    if isinstance(errors, list) and errors:
        detail = "; ".join(str(item.get("message", item)) if isinstance(item, Mapping) else str(item) for item in errors)
        raise GitHubMetadataError(f"GitHub Stars GraphQL error: {detail}")
    response_data = result.get("data")
    if not isinstance(response_data, Mapping):
        raise GitHubMetadataError("GitHub Stars API response has no data object")
    repositories: Dict[str, int] = {}
    for index, spec in enumerate(specs):
        item = response_data.get(f"repo{index}")
        count = item.get("stargazerCount") if isinstance(item, Mapping) else None
        if isinstance(count, bool) or not isinstance(count, int) or count < 0:
            raise GitHubMetadataError(f"GitHub Stars data is missing for {spec.name}")
        repositories[spec.name] = count
    return {
        "captured_at": captured_at.isoformat(),
        "organization": organization.strip(),
        "repositories": repositories,
        "total": sum(repositories.values()),
    }


def star_report(snapshot: Mapping[str, Any], baseline: Any) -> Dict[str, Any]:
    repositories = snapshot.get("repositories")
    total = snapshot.get("total")
    if not isinstance(repositories, Mapping) or not isinstance(total, int):
        raise GitHubMetadataError("Invalid current Stars snapshot")
    result: Dict[str, Any] = {
        "captured_at": snapshot.get("captured_at"),
        "total": total,
        "repositories": dict(repositories),
        "growth": {"available": False},
    }
    if not isinstance(baseline, Mapping):
        return result
    previous = baseline.get("repositories")
    previous_total = baseline.get("total")
    if not isinstance(previous, Mapping) or not isinstance(previous_total, int) or set(previous) != set(repositories):
        return result
    changes = {
        name: int(repositories[name]) - int(previous[name])
        for name in repositories
        if isinstance(repositories[name], int) and isinstance(previous[name], int)
    }
    if len(changes) != len(repositories):
        return result
    result["growth"] = {
        "available": True,
        "baseline_at": baseline.get("captured_at"),
        "net_change": total - previous_total,
        "repositories": {name: delta for name, delta in changes.items() if delta != 0},
    }
    return result


def _metadata_failure_message(error: Exception) -> str:
    return (
        "呜呜呜，今天仓库代码已经拉取完成，但 Stars 数据获取失败，数据还不完整。"
        "这次不会调用 AI，也不会发送 release，下一次会从本次尚未完成的时间起点继续汇总。"
        f"原因：{error}"
    )


def _wait_until_today(schedule: str, timezone_name: str, day: date, sleep: Callable[[float], None] = time.sleep) -> None:
    hour, minute = _parse_schedule(schedule)
    tz = _timezone(timezone_name)
    while True:
        current = datetime.now(tz)
        target = current.replace(year=day.year, month=day.month, day=day.day, hour=hour, minute=minute, second=0, microsecond=0)
        delay = (target - current).total_seconds()
        if delay <= 0:
            return
        sleep(min(delay, 60.0))


def run_workday_delivery(
    config: Mapping[str, Any],
    *,
    repository_data: Optional[Mapping[str, Any]] = None,
    root_dir: Union[Path, str] = ".",
    window_spec: Optional[str] = None,
    workday_file: Optional[Path] = None,
    config_file: Path = DEFAULT_CONFIG_PATH,
    highlight_count: Optional[int] = None,
    dry_run: bool = False,
    debug_now: bool = False,
) -> None:
    """Generate once, then send the same message to debug and release on workdays."""
    data = repository_data or load_repository_data()
    root = Path(root_dir).resolve()
    timezone_name = str(data.get("timezone", DEFAULT_TIMEZONE))
    tz = _timezone(timezone_name)
    current = datetime.now(tz)
    today = current.date()
    calendar_path = workday_file or _configured_path(data, "workday_calendar", DEFAULT_WORKDAY_CALENDAR, root)
    calendar = load_workday_calendar(calendar_path)
    calendar_timezone = calendar.get("timezone")
    if calendar_timezone != timezone_name:
        raise ConfigError(
            f"Workday calendar timezone {calendar_timezone!r} does not match repository timezone {timezone_name!r}"
        )
    if not is_workday(today, calendar):
        print(f"{today.isoformat()} is not a Chinese workday; no analysis or DingTalk delivery")
        return

    debug_time, release_time = _delivery_times(data)
    analysis_start_time = _analysis_start_time(data)
    analysis_end = current if debug_now else _scheduled_datetime(today, analysis_start_time, timezone_name)
    debug_at = _scheduled_datetime(today, debug_time, timezone_name)
    history_path = _configured_path(data, "delivery_history", DEFAULT_DELIVERY_HISTORY, root)
    history = load_delivery_history(history_path, timezone_name)
    window = _history_window(today, analysis_end, timezone_name, calendar, history, window_spec)

    if dry_run:
        delivery_plan = "debug immediately (release skipped)" if debug_now else f"debug {debug_time}, release {release_time}"
        print(
            f"Dry run: {today.isoformat()} is a send day; no Git, AI, or DingTalk request was made. "
            f"Planned window: {window.start.isoformat()} to {window.end.isoformat()}; "
            f"{delivery_plan}"
        )
        return

    if not debug_now and (current < analysis_end or current >= debug_at):
        print(
            f"{current.isoformat(timespec='seconds')} is outside the permitted analysis start window "
            f"[{analysis_start_time}, {debug_time}); no Git, AI, or DingTalk request was made"
        )
        return

    report_file = report_path(data, root, window)
    message_file = message_path(data, root, window)
    if debug_now:
        report_file = report_file.with_name(f"{report_file.stem}-debug{report_file.suffix}")
        message_file = message_file.with_name(f"{message_file.stem}-debug{message_file.suffix}")
    report = pull_data(data, root_dir=root, analysis_window=window)
    write_report(report, report_file)
    totals = report.get("totals", {})
    print(
        f"Collected {totals.get('commits', 0)} commits from "
        f"{totals.get('updated_repositories', 0)}/{totals.get('repositories', 0)} repositories"
    )

    attempt: Dict[str, Any] = {
        "date": today.isoformat(),
        "started_at": current.isoformat(),
        "window": {"start": window.start.isoformat(), "end": window.end.isoformat()},
        "report": _relative_path(report_file, root),
        "pull_status": "success",
        "pull_failures": [],
        "stars_status": "not_called",
        "ai_status": "not_called",
        "debug_status": "not_attempted",
        "release_status": "not_attempted",
    }
    attempts = history["attempts"]
    attempts.append(attempt)

    failures = _pull_failures(report)
    if failures:
        attempt["pull_status"] = "failed"
        attempt["pull_failures"] = failures
        attempt["release_status"] = "skipped_incomplete_pull"
        if history.get("next_window_start") is None:
            history["next_window_start"] = window.start.isoformat()
        write_delivery_history(history, history_path)
        warning = _pull_failure_message(failures)
        if not debug_now:
            _wait_until_today(debug_time, timezone_name, today)
        try:
            push(warning, config, section="xiangshan_monitor", layer="debug", use_proxy=bool(data.get("dingtalk_use_proxy", False)))
            attempt["debug_status"] = "sent"
            attempt["debug_sent_at"] = datetime.now(tz).isoformat()
            print(f"DingTalk debug pull-failure message sent at {datetime.now(tz).isoformat(timespec='seconds')}")
        except (ConfigError, DingTalkError, OSError, ValueError) as exc:
            attempt["debug_status"] = "failed"
            attempt["debug_error"] = str(exc)
            write_delivery_history(history, history_path)
            raise XiangShanMonitorError(f"debug: {exc}") from exc
        write_delivery_history(history, history_path)
        print("Release skipped because repository data is incomplete; AI was not called")
        return

    try:
        snapshot = collect_star_snapshot(config, data, config_file, datetime.now(tz))
        attempt["stars_status"] = "success"
        report["stars"] = star_report(snapshot, history.get("last_successful_stars"))
        write_report(report, report_file)
    except GitHubMetadataError as exc:
        attempt["stars_status"] = "failed"
        attempt["stars_error"] = str(exc)
        attempt["release_status"] = "skipped_incomplete_stars"
        if history.get("next_window_start") is None:
            history["next_window_start"] = window.start.isoformat()
        write_delivery_history(history, history_path)
        warning = _metadata_failure_message(exc)
        if not debug_now:
            _wait_until_today(debug_time, timezone_name, today)
        try:
            push(warning, config, section="xiangshan_monitor", layer="debug", use_proxy=bool(data.get("dingtalk_use_proxy", False)))
            attempt["debug_status"] = "sent"
            attempt["debug_sent_at"] = datetime.now(tz).isoformat()
            print(f"DingTalk debug Stars-failure message sent at {datetime.now(tz).isoformat(timespec='seconds')}")
        except (ConfigError, DingTalkError, OSError, ValueError) as debug_exc:
            attempt["debug_status"] = "failed"
            attempt["debug_error"] = str(debug_exc)
            write_delivery_history(history, history_path)
            raise XiangShanMonitorError(f"debug: {debug_exc}") from debug_exc
        write_delivery_history(history, history_path)
        print("Release skipped because Stars data is incomplete; AI was not called")
        return

    try:
        message = talk(report, config, data, root_dir=root, highlight_count=highlight_count)
        attempt["ai_status"] = "success"
        valid_ai_result = True
    except LocalAPIError as exc:
        print(f"AI API unavailable: {exc}; using fallback DingTalk message", file=sys.stderr)
        message = API_FAILURE_MESSAGE
        attempt["ai_status"] = "failed"
        attempt["ai_error"] = str(exc)
        valid_ai_result = False
    message_file.parent.mkdir(parents=True, exist_ok=True)
    message_file.write_text(message + "\n", encoding="utf-8")
    attempt["message"] = _relative_path(message_file, root)
    write_delivery_history(history, history_path)

    use_proxy = bool(data.get("dingtalk_use_proxy", False))
    errors: List[str] = []
    deliveries = (("debug", debug_time),) if debug_now else (("debug", debug_time), ("release", release_time))
    if debug_now:
        attempt["release_status"] = "skipped_debug_only"
    for layer, schedule in deliveries:
        if not debug_now:
            _wait_until_today(schedule, timezone_name, today)
        try:
            push(message, config, section="xiangshan_monitor", layer=layer, use_proxy=use_proxy)
            attempt[f"{layer}_status"] = "sent" if valid_ai_result else "sent_api_fallback"
            attempt[f"{layer}_sent_at"] = datetime.now(tz).isoformat()
            print(f"DingTalk {layer} message sent successfully at {datetime.now(tz).isoformat(timespec='seconds')}")
            if layer == "release" and valid_ai_result:
                history["next_window_start"] = window.end.isoformat()
                history["last_successful_release"] = attempt[f"{layer}_sent_at"]
                history["last_successful_stars"] = snapshot
        except (ConfigError, DingTalkError, OSError, ValueError) as exc:
            errors.append(f"{layer}: {exc}")
            attempt[f"{layer}_status"] = "failed"
            attempt[f"{layer}_error"] = str(exc)
            print(f"DingTalk {layer} delivery failed: {exc}", file=sys.stderr)
        write_delivery_history(history, history_path)
    if errors:
        raise XiangShanMonitorError("; ".join(errors))


def run_once(config: Mapping[str, Any], *, repository_data: Optional[Mapping[str, Any]] = None, root_dir: Union[Path, str] = ".", window_spec: Optional[str] = None, stage: str = "all", report_file: Optional[Path] = None, message_file: Optional[Path] = None, dry_run: bool = False, dingtalk_section: str = "xiangshan_monitor", dingtalk_layer: str = DEFAULT_DINGTALK_LAYER, highlight_count: Optional[int] = None, git_runner: Callable[..., str] = _run_git, opener: Optional[Any] = None) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    if stage not in {"all", "pull", "talk", "push"}:
        raise ValueError(f"Unknown stage: {stage}")
    data = repository_data or load_repository_data()
    window = resolve_time_window(window_spec or str(data.get("analysis_window", DEFAULT_ANALYSIS_WINDOW)), str(data.get("timezone", DEFAULT_TIMEZONE)))
    root = Path(root_dir).resolve()
    report_file = Path(report_file) if report_file is not None else report_path(data, root, window)
    message_file = Path(message_file) if message_file is not None else message_path(data, root, window)
    if not report_file.is_absolute():
        report_file = root / report_file
    if not message_file.is_absolute():
        message_file = root / message_file
    report: Optional[Dict[str, Any]] = None
    message: Optional[str] = None
    if stage in {"all", "pull"}:
        report = pull_data(data, window.spec, root_dir=root, git_runner=git_runner)
        write_report(report, report_file)
        print(render_pull_summary(report))
    elif stage == "talk":
        report = read_report(report_file)
    if stage in {"all", "talk"}:
        assert report is not None
        try:
            message = talk(report, config, data, root_dir=root, highlight_count=highlight_count, opener=opener)
        except LocalAPIError as exc:
            print(f"AI API unavailable: {exc}; using fallback DingTalk message", file=sys.stderr)
            message = API_FAILURE_MESSAGE
        message_file.parent.mkdir(parents=True, exist_ok=True)
        message_file.write_text(message + "\n", encoding="utf-8")
        print(message)
    elif stage == "push":
        message = _load_message(message_file)
    if stage in {"all", "push"} and not dry_run:
        assert message is not None
        push(message, config, section=dingtalk_section, layer=dingtalk_layer, use_proxy=bool(data.get("dingtalk_use_proxy", False)))
        print("DingTalk message sent successfully")
    return report, message


def _parse_schedule(value: str) -> Tuple[int, int]:
    match = re.fullmatch(r"(\d{1,2}):(\d{2})", value.strip())
    if not match or int(match.group(1)) > 23 or int(match.group(2)) > 59:
        raise ValueError(f"Invalid schedule time (expected HH:MM): {value}")
    return int(match.group(1)), int(match.group(2))


def seconds_until_schedule(schedule: str, timezone_name: str, now: Optional[datetime] = None) -> float:
    hour, minute = _parse_schedule(schedule)
    tz = _timezone(timezone_name)
    current = now or datetime.now(tz)
    if current.tzinfo is None:
        current = current.replace(tzinfo=tz)
    current = current.astimezone(tz)
    target = current.replace(hour=hour, minute=minute, second=0, microsecond=0)
    if target <= current:
        target += timedelta(days=1)
    return (target - current).total_seconds()


def run_scheduler(config: Mapping[str, Any], *, repository_data: Optional[Mapping[str, Any]] = None, root_dir: Union[Path, str] = ".", window_spec: Optional[str] = None, stage: str = "all", dry_run: bool = False, dingtalk_section: str = "xiangshan_monitor", dingtalk_layer: str = DEFAULT_DINGTALK_LAYER, highlight_count: Optional[int] = None, sleep: Callable[[float], None] = time.sleep, run_job: Callable[..., Any] = run_once) -> None:
    data = repository_data or load_repository_data()
    timezone_name = str(data.get("timezone", DEFAULT_TIMEZONE))
    schedule = str(data.get("schedule", "09:00"))
    while True:
        delay = seconds_until_schedule(schedule, timezone_name)
        sleep(min(delay, 300.0))
        if delay > 300.0:
            continue
        run_job(config, repository_data=data, root_dir=root_dir, window_spec=window_spec, stage=stage, dry_run=dry_run, dingtalk_section=dingtalk_section, dingtalk_layer=dingtalk_layer, highlight_count=highlight_count)


def parse_args(argv: Optional[Sequence[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Daily OpenXiangShan praise robot")
    parser.add_argument("command", nargs="?", choices=("all", "pull", "talk", "push"))
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG_PATH)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--repositories", type=Path, default=DEFAULT_REPOSITORY_DATA)
    parser.add_argument("--window", help="Rolling analysis window such as 24h or 7d")
    parser.add_argument("--stage", choices=("all", "pull", "talk", "push"), default="all")
    parser.add_argument("--report", type=Path)
    parser.add_argument("--message", type=Path)
    parser.add_argument("--dingtalk-section", default="xiangshan_monitor")
    parser.add_argument("--dingtalk-layer", choices=("debug", "release"), default=DEFAULT_DINGTALK_LAYER)
    parser.add_argument("--highlight-count", type=int, choices=(1, 2, 3), help="Number of standout contributors (default: based on analysis window)")
    parser.add_argument("--workday-delivery", action="store_true", help="Generate once and send to debug/release at their configured workday times")
    parser.add_argument("--debug-now", action="store_true", help="Run the workday pipeline now and send only to debug without advancing release history")
    parser.add_argument("--workdays", type=Path, help="Chinese holiday and makeup-workday calendar JSON")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--daemon", action="store_true")
    args = parser.parse_args(argv)
    if args.command is not None:
        args.stage = args.command
    return args


def main(argv: Optional[Sequence[str]] = None) -> int:
    args = parse_args(argv)
    try:
        config = load_config(args.config)
        data = load_repository_data(args.repositories)
        if args.daemon and (args.workday_delivery or args.debug_now):
            raise ValueError("--daemon cannot be used with --workday-delivery or --debug-now")
        if args.workday_delivery or args.debug_now:
            run_workday_delivery(config, repository_data=data, root_dir=args.root, window_spec=args.window, workday_file=args.workdays, config_file=args.config, highlight_count=args.highlight_count, dry_run=args.dry_run, debug_now=args.debug_now)
        elif args.daemon:
            run_scheduler(config, repository_data=data, root_dir=args.root, window_spec=args.window, stage=args.stage, dry_run=args.dry_run, dingtalk_section=args.dingtalk_section, dingtalk_layer=args.dingtalk_layer, highlight_count=args.highlight_count)
        else:
            run_once(config, repository_data=data, root_dir=args.root, window_spec=args.window, stage=args.stage, report_file=args.report, message_file=args.message, dry_run=args.dry_run, dingtalk_section=args.dingtalk_section, dingtalk_layer=args.dingtalk_layer, highlight_count=args.highlight_count)
    except KeyboardInterrupt:
        print("xiangshan-monitor stopped")
        return 0
    except (ConfigError, DingTalkError, XiangShanMonitorError, OSError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
