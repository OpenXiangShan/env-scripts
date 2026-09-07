"""Collect GitHub Actions workflow-run metrics for a reporting period."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Iterable, List, Optional, Set

from .github import GitHubClient, GitHubError


SEARCH_RESULT_LIMIT = 1000
PAGE_SIZE = 100
MINIMUM_PARTITION = timedelta(minutes=1)


def _parse_time(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _timestamp(value: datetime) -> str:
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _ratio(numerator: int, denominator: int) -> Optional[float]:
    return round(numerator / denominator, 4) if denominator else None


def _distribution(values: Iterable[float]) -> Dict[str, Any]:
    ordered = sorted(values)
    if not ordered:
        return {
            "samples": 0,
            "total": None,
            "average": None,
            "p50": None,
            "p90": None,
        }

    def percentile(fraction: float) -> float:
        position = (len(ordered) - 1) * fraction
        lower = int(position)
        upper = min(lower + 1, len(ordered) - 1)
        weight = position - lower
        return ordered[lower] * (1 - weight) + ordered[upper] * weight

    return {
        "samples": len(ordered),
        "total": round(sum(ordered), 2),
        "average": round(sum(ordered) / len(ordered), 2),
        "p50": round(percentile(0.5), 2),
        "p90": round(percentile(0.9), 2),
    }


@dataclass
class RequestBudget:
    maximum: int
    used: int = 0

    def consume(self) -> None:
        if self.used >= self.maximum:
            raise GitHubError(
                f"GitHub Actions pagination exceeded {self.maximum} requests"
            )
        self.used += 1


@dataclass
class GitHubActionsMetrics:
    status: str = "pending"
    request_count: int = 0
    partition_count: int = 0
    runs: int = 0
    completed_runs: int = 0
    successful_runs: int = 0
    first_attempt_successes: int = 0
    rerun_runs: int = 0
    successful_after_rerun: int = 0
    status_counts: Dict[str, int] = field(default_factory=dict)
    conclusion_counts: Dict[str, int] = field(default_factory=dict)
    event_counts: Dict[str, int] = field(default_factory=dict)
    workflow_counts: Dict[str, int] = field(default_factory=dict)
    workflow_metadata: Dict[str, Dict[str, Any]] = field(default_factory=dict)
    queue_minutes: List[float] = field(default_factory=list)
    duration_minutes: List[float] = field(default_factory=list)
    head_keys: Set[str] = field(default_factory=set)
    pull_request_keys: Set[str] = field(default_factory=set)
    error: Optional[str] = None

    def add_runs(self, full_name: str, runs: Iterable[Dict[str, Any]]) -> None:
        for run in runs:
            self.runs += 1
            status = str(run.get("status") or "unknown")
            conclusion = str(run.get("conclusion") or "not_completed")
            event = str(run.get("event") or "unknown")
            workflow_id = run.get("workflow_id")
            workflow_path = str(run.get("path") or "unknown").split("@", 1)[0]
            workflow = f"{full_name}:{workflow_id}:{workflow_path}"
            self.workflow_metadata[workflow] = {
                "repository": full_name,
                "workflow_id": workflow_id,
                "path": workflow_path,
                "name": str(run.get("name") or workflow_path),
            }
            self._increment(self.status_counts, status)
            self._increment(self.conclusion_counts, conclusion)
            self._increment(self.event_counts, event)
            self._increment(self.workflow_counts, workflow)

            completed = status == "completed" or run.get("conclusion") is not None
            if completed:
                self.completed_runs += 1
            if run.get("conclusion") == "success":
                self.successful_runs += 1
                if int(run.get("run_attempt") or 1) == 1:
                    self.first_attempt_successes += 1
            attempt = int(run.get("run_attempt") or 1)
            if attempt > 1:
                self.rerun_runs += 1
                if run.get("conclusion") == "success":
                    self.successful_after_rerun += 1

            created_at = _parse_time(run.get("created_at"))
            started_at = _parse_time(run.get("run_started_at"))
            updated_at = _parse_time(run.get("updated_at"))
            if created_at and started_at and started_at >= created_at:
                self.queue_minutes.append(
                    (started_at - created_at).total_seconds() / 60
                )
            if completed and started_at and updated_at and updated_at >= started_at:
                self.duration_minutes.append(
                    (updated_at - started_at).total_seconds() / 60
                )

            head_sha = str(run.get("head_sha") or "")
            if head_sha:
                self.head_keys.add(f"{full_name}@{head_sha}")
            for pull_request in run.get("pull_requests") or []:
                if isinstance(pull_request, dict) and pull_request.get("number") is not None:
                    self.pull_request_keys.add(
                        f"{full_name}#{int(pull_request['number'])}"
                    )

    def merge(self, other: "GitHubActionsMetrics") -> None:
        for name in (
            "request_count",
            "partition_count",
            "runs",
            "completed_runs",
            "successful_runs",
            "first_attempt_successes",
            "rerun_runs",
            "successful_after_rerun",
        ):
            setattr(self, name, getattr(self, name) + getattr(other, name))
        for target, source in (
            (self.status_counts, other.status_counts),
            (self.conclusion_counts, other.conclusion_counts),
            (self.event_counts, other.event_counts),
            (self.workflow_counts, other.workflow_counts),
        ):
            for key, value in source.items():
                self._increment(target, key, value)
        self.queue_minutes.extend(other.queue_minutes)
        self.duration_minutes.extend(other.duration_minutes)
        self.head_keys.update(other.head_keys)
        self.pull_request_keys.update(other.pull_request_keys)
        self.workflow_metadata.update(other.workflow_metadata)

    def to_dict(
        self,
        commit_keys: Set[str],
        pull_request_keys: Set[str],
        pull_request_heads: Dict[str, str],
    ) -> Dict[str, Any]:
        covered_commits = len(commit_keys & self.head_keys)
        covered_pull_requests = set(pull_request_keys & self.pull_request_keys)
        for head_key in self.head_keys:
            pull_request_key = pull_request_heads.get(head_key)
            if pull_request_key:
                covered_pull_requests.add(pull_request_key)
        return {
            "provider": "github_actions",
            "status": self.status,
            "runs": self.runs,
            "completed_runs": self.completed_runs,
            "successful_runs": self.successful_runs,
            "success_rate": _ratio(self.successful_runs, self.completed_runs),
            "first_attempt_pass_rate": _ratio(
                self.first_attempt_successes, self.completed_runs
            ),
            "rerun_runs": self.rerun_runs,
            "rerun_rate": _ratio(self.rerun_runs, self.runs),
            "successful_after_rerun": self.successful_after_rerun,
            "statuses": dict(sorted(self.status_counts.items())),
            "conclusions": dict(sorted(self.conclusion_counts.items())),
            "events": dict(sorted(self.event_counts.items())),
            "workflow_count": len(self.workflow_counts),
            "workflows": [
                {**self.workflow_metadata[key], "runs": count}
                for key, count in sorted(
                    self.workflow_counts.items(), key=lambda item: (-item[1], item[0])
                )
            ],
            "queue_minutes": _distribution(self.queue_minutes),
            "duration_basis": "workflow_run_wall_clock",
            "duration_minutes": _distribution(self.duration_minutes),
            "coverage": {
                "has_runs": self.runs > 0,
                "default_branch_commits": len(commit_keys),
                "default_branch_commits_with_runs": covered_commits,
                "default_branch_commit_rate": _ratio(
                    covered_commits, len(commit_keys)
                ),
                "pull_requests": len(pull_request_keys),
                "pull_requests_with_runs": len(covered_pull_requests),
                "pull_request_rate": _ratio(
                    len(covered_pull_requests), len(pull_request_keys)
                ),
            },
            "collection": {
                "requests": self.request_count,
                "partitions": self.partition_count,
                "error": self.error,
            },
        }

    @staticmethod
    def _increment(target: Dict[str, int], key: str, amount: int = 1) -> None:
        target[key] = target.get(key, 0) + amount


def collect_github_actions(
    client: GitHubClient,
    full_name: str,
    start: datetime,
    end: datetime,
    max_requests: int = 500,
) -> GitHubActionsMetrics:
    """Collect workflow runs, splitting intervals that exceed GitHub's 1,000 cap."""
    if max_requests < 1:
        raise ValueError("max_actions_requests must be positive")
    budget = RequestBudget(max_requests)
    metrics = GitHubActionsMetrics()
    try:
        runs = _fetch_interval(client, full_name, start, end, budget, metrics)
        exact_runs = {
            int(run["id"]): run
            for run in runs
            if run.get("id") is not None
            and (created_at := _parse_time(run.get("created_at"))) is not None
            and start <= created_at < end
        }
        metrics.add_runs(full_name, exact_runs.values())
        metrics.status = "available"
    except GitHubError as exc:
        metrics.status = "error"
        metrics.error = str(exc)
    metrics.request_count = budget.used
    return metrics


def _fetch_interval(
    client: GitHubClient,
    full_name: str,
    start: datetime,
    end: datetime,
    budget: RequestBudget,
    metrics: GitHubActionsMetrics,
) -> List[Dict[str, Any]]:
    data = _get_runs_page(client, full_name, start, end, 1, budget)
    total_count = int(data.get("total_count") or 0)
    first_page = [
        run for run in data.get("workflow_runs") or [] if isinstance(run, dict)
    ]
    if total_count > SEARCH_RESULT_LIMIT:
        if end - start <= MINIMUM_PARTITION:
            raise GitHubError(
                f"More than {SEARCH_RESULT_LIMIT} GitHub Actions runs in one minute"
            )
        midpoint = start + (end - start) / 2
        metrics.partition_count += 1
        return _fetch_interval(
            client, full_name, start, midpoint, budget, metrics
        ) + _fetch_interval(client, full_name, midpoint, end, budget, metrics)

    runs = first_page
    page = 2
    while len(runs) < total_count:
        page_data = _get_runs_page(client, full_name, start, end, page, budget)
        page_runs = [
            run
            for run in page_data.get("workflow_runs") or []
            if isinstance(run, dict)
        ]
        if not page_runs:
            break
        runs.extend(page_runs)
        page += 1
    if len(runs) < total_count:
        raise GitHubError(
            f"GitHub Actions returned {len(runs)} of {total_count} workflow runs"
        )
    return runs


def _get_runs_page(
    client: GitHubClient,
    full_name: str,
    start: datetime,
    end: datetime,
    page: int,
    budget: RequestBudget,
) -> Dict[str, Any]:
    budget.consume()
    inclusive_end = end - timedelta(microseconds=1)
    data, _ = client.get(
        f"repos/{full_name}/actions/runs",
        {
            "created": f"{_timestamp(start)}..{_timestamp(inclusive_end)}",
            "per_page": PAGE_SIZE,
            "page": page,
        },
    )
    if not isinstance(data, dict):
        raise GitHubError(f"Invalid GitHub Actions response for {full_name}")
    return data
