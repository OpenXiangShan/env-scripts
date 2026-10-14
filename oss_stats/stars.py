"""Compare saved repository Star totals without reading stargazer identities."""

from __future__ import annotations

import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, Iterable, Optional
from zoneinfo import ZoneInfo


def _time(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError("Star snapshot timestamps must include a timezone")
    return parsed


def normalize_snapshot(data: Dict[str, Any]) -> Dict[str, Any]:
    """Accept an OSS report, a monitor report, or a standalone snapshot."""
    organization = data.get("organization")
    source = data.get("stars", data)
    captured_at = source.get("captured_at") or data.get("generated_at")
    repositories = source.get("repositories")
    aggregate_forks = source.get("aggregate_forks", False)
    complete_scope = source.get("complete_scope", False)
    repository_forks = source.get("repository_forks", {})
    if isinstance(repositories, list):
        repository_forks = {repo["full_name"]: bool(repo["fork"]) for repo in repositories}
        aggregate_forks = data["aggregation"]["includes_fork_repositories"]
        complete_scope = True
        repositories = {repo["full_name"]: repo["current"]["stars"] for repo in repositories}
    if not isinstance(organization, str) or not isinstance(captured_at, str):
        raise ValueError("Star snapshot requires organization and captured_at")
    _time(captured_at)
    if not isinstance(repositories, dict):
        raise ValueError("Star snapshot requires repository totals")
    normalized = {}
    for name, count in repositories.items():
        if not isinstance(name, str) or isinstance(count, bool) or not isinstance(count, int) or count < 0:
            raise ValueError("Invalid repository Star total in snapshot")
        full_name = name if "/" in name else f"{organization}/{name}"
        if not full_name.startswith(f"{organization}/"):
            raise ValueError("Star snapshot contains another organization's repository")
        normalized[full_name] = count
    return {
        "organization": organization,
        "captured_at": captured_at,
        "repositories": normalized,
        "total": sum(normalized.values()),
        "complete_scope": complete_scope,
        "aggregate_forks": aggregate_forks,
        "repository_forks": repository_forks,
        "aggregate_total": sum(
            count for name, count in normalized.items()
            if aggregate_forks or not repository_forks.get(name, False)
        ),
    }


def load_snapshot(path: Path) -> Dict[str, Any]:
    try:
        return normalize_snapshot(json.loads(path.read_text(encoding="utf-8")))
    except (OSError, KeyError, TypeError, AttributeError) as exc:
        raise ValueError(f"Cannot load Star snapshot {path}: {exc}") from exc


def load_history(path: Path) -> list:
    if not path.exists():
        return []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict) or not isinstance(data.get("snapshots"), list):
            raise ValueError("Star history requires a snapshots list")
        return [normalize_snapshot(item) for item in data["snapshots"]]
    except (OSError, KeyError, TypeError, AttributeError) as exc:
        raise ValueError(f"Cannot load Star history {path}: {exc}") from exc


def previous_month_snapshot(
    snapshots: Iterable[Dict[str, Any]], organization: str,
    current_at: str, timezone_name: str, aggregate_forks: bool = False,
) -> Optional[Dict[str, Any]]:
    zone = ZoneInfo(timezone_name)
    current = _time(current_at).astimezone(zone)
    month_start = current.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    previous_month = (month_start - timedelta(days=1)).strftime("%Y-%m")
    candidates = [
        snapshot for snapshot in snapshots
        if snapshot["organization"] == organization
        and _time(snapshot["captured_at"]).astimezone(zone).strftime("%Y-%m") == previous_month
    ]
    complete = [
        item for item in candidates
        if item["complete_scope"] and item["aggregate_forks"] == aggregate_forks
    ]
    return max(complete or candidates, key=lambda item: _time(item["captured_at"]), default=None)


def save_snapshot(path: Path, snapshot: Dict[str, Any]) -> None:
    snapshots = load_history(path)
    key = (snapshot["organization"], snapshot["captured_at"])
    snapshots = [item for item in snapshots if (item["organization"], item["captured_at"]) != key]
    snapshots.append(snapshot)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    try:
        temporary.write_text(json.dumps({"version": 1, "snapshots": snapshots}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary.replace(path)
    except OSError as exc:
        raise ValueError(f"Cannot save Star history {path}: {exc}") from exc


def apply_star_baseline(
    report: Dict[str, Any], baseline: Optional[Dict[str, Any]],
) -> Dict[str, Any]:
    current = normalize_snapshot(report)
    if baseline is not None:
        baseline = normalize_snapshot(baseline)
        if baseline["organization"] != current["organization"]:
            raise ValueError("Star baseline belongs to another organization")
        if _time(baseline["captured_at"]) >= _time(current["captured_at"]):
            raise ValueError("Star baseline must predate the current snapshot")
    previous = baseline["repositories"] if baseline else {}
    include_forks = report["aggregation"]["includes_fork_repositories"]
    complete_baseline = bool(
        baseline and baseline["complete_scope"] and baseline["aggregate_forks"] == include_forks
    )
    aggregate = [repo for repo in report["repositories"] if include_forks or not repo["fork"]]
    comparable = []
    for repo in report["repositories"]:
        name = repo["full_name"]
        previous_count = previous.get(name)
        status = "available" if previous_count is not None else "missing_baseline"
        created_at = repo.get("created_at")
        if complete_baseline and previous_count is None:
            previous_count = 0
            status = "zero_repository_not_in_baseline"
        elif baseline and previous_count is None and created_at and _time(created_at) > _time(baseline["captured_at"]):
            previous_count = 0
            status = "zero_repository_created_after_baseline"
        vitality = repo["community_vitality"]
        vitality.pop("stars_added", None)
        vitality.pop("stars_added_status", None)
        vitality.update({
            "stars_baseline_total": previous_count,
            "stars_net_change": repo["current"]["stars"] - previous_count if previous_count is not None else None,
            "stars_comparison_status": status,
        })
        if (include_forks or not repo["fork"]) and previous_count is not None:
            comparable.append(repo)
    missing = [repo["full_name"] for repo in aggregate if repo["community_vitality"]["stars_net_change"] is None]
    baseline_total = sum(repo["community_vitality"]["stars_baseline_total"] for repo in comparable) if comparable else None
    comparable_total = sum(repo["current"]["stars"] for repo in comparable) if comparable else None
    net_change = comparable_total - baseline_total if comparable else None
    organization_net_change = (
        sum(repo["current"]["stars"] for repo in aggregate) - baseline["aggregate_total"]
        if complete_baseline else net_change if not missing else None
    )
    status = "missing_baseline" if baseline is None else "available" if not missing else "partial" if comparable else "missing_baseline"
    report["star_growth"] = {
        "basis": "snapshot_net_change",
        "scope": "organization_totals" if complete_baseline else "current_aggregate_repositories",
        "status": status,
        "baseline_at": baseline["captured_at"] if baseline else None,
        "current_at": current["captured_at"],
        "aggregate_repositories": len(aggregate),
        "comparable_repositories": len(comparable),
        "missing_baseline_repositories": missing,
        "baseline_total_comparable": baseline_total,
        "current_total_comparable": comparable_total,
        "comparable_net_change": net_change,
        "net_change": organization_net_change,
        "organization_baseline_total": baseline["aggregate_total"] if complete_baseline else baseline_total if not missing else None,
        "organization_current_total": sum(repo["current"]["stars"] for repo in aggregate),
        "removed_repositories": [
            name for name in previous
            if complete_baseline
            and (include_forks or not baseline["repository_forks"].get(name, False))
            and name not in {repo["full_name"] for repo in aggregate}
        ],
    }
    vitality = report["summary"]["community_vitality"]
    vitality.pop("stars_added", None)
    vitality.pop("stars_added_status", None)
    vitality.update({"stars_net_change": organization_net_change, "stars_comparison_status": status})
    report["coverage"].pop("new_stars", None)
    report["coverage"]["stars_net_change"] = status
    report["limitations"] = [item for item in report["limitations"] if "stargazer" not in item.lower()]
    definition = "Star net change compares the previous month's saved totals with the current snapshot; snapshot dates and comparable repository coverage are reported separately from the activity period."
    if definition not in report["limitations"]:
        report["limitations"].append(definition)
    return current
