"""Collect OSS Compass-aligned metrics from each GitHub repository's history."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from statistics import mean
from typing import Any, Callable, Dict, Iterable, List, Optional, Set
from zoneinfo import ZoneInfo

from .ci import GitHubActionsMetrics, collect_github_actions
from .github import GitHubClient, GitHubError


ISSUE_LINK = re.compile(
    r"(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+[\w.-]+/[\w.-]+#\d+"
    r"|(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#\d+"
    r"|(?<![\w/])#\d+",
    re.IGNORECASE,
)

REPOSITORY_MONTH_QUERY = """
query RepositoryMonth(
  $owner: String!
  $name: String!
  $since: GitTimestamp!
  $until: GitTimestamp!
  $issueQuery: String!
  $pullRequestQuery: String!
  $commitCursor: String
  $issueCursor: String
  $pullRequestCursor: String
  $forkCursor: String
  $includeCommits: Boolean!
  $includeIssues: Boolean!
  $includePullRequests: Boolean!
  $includeForks: Boolean!
) {
  repository(owner: $owner, name: $name) {
    defaultBranchRef {
      target {
        ... on Commit {
          history(
            first: 100
            after: $commitCursor
            since: $since
            until: $until
          ) @include(if: $includeCommits) {
            totalCount
            pageInfo { hasNextPage endCursor }
            nodes {
              oid
              additions
              deletions
              author { name email user { login } }
            }
          }
        }
      }
    }
    forks(
      first: 100
      after: $forkCursor
      orderBy: {field: CREATED_AT, direction: DESC}
    ) @include(if: $includeForks) {
      pageInfo { hasNextPage endCursor }
      nodes { createdAt }
    }
  }
  issues: search(
    query: $issueQuery
    type: ISSUE
    first: 25
    after: $issueCursor
  ) @include(if: $includeIssues) {
    issueCount
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on Issue {
        number
        createdAt
        closedAt
        body
        author { login }
        comments(first: 100) {
          totalCount
          nodes { createdAt author { login } }
        }
      }
    }
  }
  pullRequests: search(
    query: $pullRequestQuery
    type: ISSUE
    first: 25
    after: $pullRequestCursor
  ) @include(if: $includePullRequests) {
    issueCount
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on PullRequest {
        number
        createdAt
        closedAt
        mergedAt
        headRefOid
        additions
        deletions
        body
        author { login }
        comments(first: 100) {
          totalCount
          nodes { createdAt author { login } }
        }
        reviews(first: 100) {
          totalCount
          nodes { submittedAt author { login } }
        }
      }
    }
  }
  rateLimit { cost limit remaining resetAt used }
}
"""


def parse_time(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def _login(value: Any) -> str:
    return value.get("login", "") if isinstance(value, dict) else ""


def _in_period(value: Optional[str], start: datetime, end: datetime) -> bool:
    parsed = parse_time(value)
    return bool(parsed and start <= parsed < end)


def _average(values: Iterable[float]) -> Optional[float]:
    values = list(values)
    return round(mean(values), 2) if values else None


def _ratio(numerator: int, denominator: int) -> Optional[float]:
    return round(numerator / denominator, 4) if denominator else None


@dataclass
class RepoMetrics:
    name: str
    full_name: str
    url: str
    archived: bool = False
    fork: bool = False
    stars_total: int = 0
    forks_total: int = 0
    open_items: int = 0
    stars_added: Optional[int] = None
    forks_added: int = 0
    commits: int = 0
    additions: int = 0
    deletions: int = 0
    issues_opened: int = 0
    issue_comments: int = 0
    issues_closed: int = 0
    issues_responded: int = 0
    prs_opened: int = 0
    pr_comments: int = 0
    pr_reviews: int = 0
    prs_closed: int = 0
    prs_merged: int = 0
    prs_responded: int = 0
    prs_reviewed: int = 0
    linked_prs: int = 0
    contributors: Set[str] = field(default_factory=set)
    code_contributors: Set[str] = field(default_factory=set)
    non_code_contributors: Set[str] = field(default_factory=set)
    issue_response_hours: List[float] = field(default_factory=list)
    issue_close_hours: List[float] = field(default_factory=list)
    pr_response_hours: List[float] = field(default_factory=list)
    pr_close_hours: List[float] = field(default_factory=list)
    pr_interactions: List[int] = field(default_factory=list)
    history_status: str = "pending"
    history_pages: int = 0
    truncated_sections: List[str] = field(default_factory=list)
    interaction_connections_truncated: int = 0
    commit_keys: Set[str] = field(default_factory=set)
    pull_request_keys: Set[str] = field(default_factory=set)
    pull_request_heads: Dict[str, str] = field(default_factory=dict)
    github_actions: GitHubActionsMetrics = field(default_factory=GitHubActionsMetrics)

    @property
    def activity_score(self) -> int:
        return sum(
            (
                self.forks_added,
                self.commits,
                self.issues_opened,
                self.issue_comments,
                self.prs_opened,
                self.pr_comments,
                self.pr_reviews,
                self.prs_merged,
            )
        )

    def add_commits(self, nodes: Iterable[Dict[str, Any]]) -> None:
        for node in nodes:
            self.commits += 1
            self.additions += int(node.get("additions") or 0)
            self.deletions += int(node.get("deletions") or 0)
            oid = str(node.get("oid") or "")
            if oid:
                self.commit_keys.add(f"{self.full_name}@{oid}")
            author = node.get("author") or {}
            identity = _login(author.get("user")) or author.get("email") or author.get("name")
            self._add_code_contributor(str(identity or ""))

    def add_forks(
        self, nodes: Iterable[Dict[str, Any]], start: datetime, end: datetime
    ) -> None:
        self.forks_added += sum(
            1 for node in nodes if _in_period(node.get("createdAt"), start, end)
        )

    def add_item(self, item: Dict[str, Any], start: datetime, end: datetime) -> None:
        if not _in_period(item.get("createdAt"), start, end):
            return
        if "mergedAt" not in item:
            self._add_issue(item, start, end)
        else:
            self._add_pull_request(item, start, end)

    def _add_issue(self, issue: Dict[str, Any], start: datetime, end: datetime) -> None:
        self.issues_opened += 1
        author = _login(issue.get("author"))
        self._add_non_code_contributor(author)
        comments = self._period_nodes(issue.get("comments"), "createdAt", start, end)
        self.issue_comments += len(comments)
        response_times = []
        created_at = parse_time(issue.get("createdAt"))
        for comment in comments:
            commenter = _login(comment.get("author"))
            self._add_non_code_contributor(commenter)
            comment_time = parse_time(comment.get("createdAt"))
            if commenter and commenter != author and created_at and comment_time:
                response_times.append((comment_time - created_at).total_seconds() / 3600)
        if response_times:
            self.issues_responded += 1
            self.issue_response_hours.append(min(response_times))

        closed_at = parse_time(issue.get("closedAt"))
        if created_at and closed_at and start <= closed_at < end:
            self.issues_closed += 1
            self.issue_close_hours.append((closed_at - created_at).total_seconds() / 3600)

    def _add_pull_request(
        self, pull_request: Dict[str, Any], start: datetime, end: datetime
    ) -> None:
        self.prs_opened += 1
        number = pull_request.get("number")
        pull_request_key = (
            f"{self.full_name}#{int(number)}" if number is not None else ""
        )
        if pull_request_key:
            self.pull_request_keys.add(pull_request_key)
        head_oid = str(pull_request.get("headRefOid") or "")
        if head_oid and pull_request_key:
            self.pull_request_heads[
                f"{self.full_name}@{head_oid}"
            ] = pull_request_key
        author = _login(pull_request.get("author"))
        self._add_code_contributor(author)
        if ISSUE_LINK.search(pull_request.get("body") or ""):
            self.linked_prs += 1

        comments = self._period_nodes(
            pull_request.get("comments"), "createdAt", start, end
        )
        reviews = self._period_nodes(
            pull_request.get("reviews"), "submittedAt", start, end
        )
        self.pr_comments += len(comments)
        self.pr_reviews += len(reviews)
        self.pr_interactions.append(len(comments) + len(reviews))
        if reviews:
            self.prs_reviewed += 1

        created_at = parse_time(pull_request.get("createdAt"))
        response_times = []
        for entry, timestamp_key in [
            *((comment, "createdAt") for comment in comments),
            *((review, "submittedAt") for review in reviews),
        ]:
            responder = _login(entry.get("author"))
            self._add_non_code_contributor(responder)
            response_at = parse_time(entry.get(timestamp_key))
            if responder and responder != author and created_at and response_at:
                response_times.append((response_at - created_at).total_seconds() / 3600)
        if response_times:
            self.prs_responded += 1
            self.pr_response_hours.append(min(response_times))

        closed_at = parse_time(pull_request.get("closedAt"))
        if created_at and closed_at and start <= closed_at < end:
            self.prs_closed += 1
            self.pr_close_hours.append((closed_at - created_at).total_seconds() / 3600)
        merged_at = parse_time(pull_request.get("mergedAt"))
        if merged_at and start <= merged_at < end:
            self.prs_merged += 1

    def _period_nodes(
        self,
        connection: Any,
        timestamp_key: str,
        start: datetime,
        end: datetime,
    ) -> List[Dict[str, Any]]:
        if not isinstance(connection, dict):
            return []
        nodes = [node for node in connection.get("nodes") or [] if isinstance(node, dict)]
        if int(connection.get("totalCount") or 0) > len(nodes):
            self.interaction_connections_truncated += 1
        return [node for node in nodes if _in_period(node.get(timestamp_key), start, end)]

    def _add_code_contributor(self, actor: str) -> None:
        if actor:
            self.code_contributors.add(actor)
            self.contributors.add(actor)

    def _add_non_code_contributor(self, actor: str) -> None:
        if actor:
            self.non_code_contributors.add(actor)
            self.contributors.add(actor)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "full_name": self.full_name,
            "url": self.url,
            "archived": self.archived,
            "fork": self.fork,
            "current": {
                "stars": self.stars_total,
                "forks": self.forks_total,
                "open_issues_and_prs": self.open_items,
            },
            "community_vitality": {
                "stars_added": self.stars_added,
                "stars_added_status": "unavailable_github_access_restriction",
                "forks_added": self.forks_added,
                "commits": self.commits,
                "additions": self.additions,
                "deletions": self.deletions,
                "lines_changed": self.additions + self.deletions,
                "commit_scope": "default_branch",
                "issues_opened": self.issues_opened,
                "issue_comments": self.issue_comments,
                "prs_opened": self.prs_opened,
                "pr_comments": self.pr_comments,
            },
            "developer_base": {
                "contributors": len(self.contributors),
                "code_contributors": len(self.code_contributors),
                "non_code_contributors": len(self.non_code_contributors),
            },
            "collaboration_efficiency": {
                "issues_closed": self.issues_closed,
                "issue_unresponsive_rate": _ratio(
                    self.issues_opened - self.issues_responded, self.issues_opened
                ),
                "issue_first_response_hours": _average(self.issue_response_hours),
                "issue_resolution_hours": _average(self.issue_close_hours),
                "prs_closed": self.prs_closed,
                "prs_merged": self.prs_merged,
                "pr_merge_rate": _ratio(self.prs_merged, self.prs_opened),
                "pr_unresponsive_rate": _ratio(
                    self.prs_opened - self.prs_responded, self.prs_opened
                ),
                "pr_first_response_hours": _average(self.pr_response_hours),
                "pr_resolution_hours": _average(self.pr_close_hours),
                "pr_issue_link_rate": _ratio(self.linked_prs, self.prs_opened),
                "pr_review_participation_rate": _ratio(
                    self.prs_reviewed, self.prs_opened
                ),
                "pr_average_interactions": _average(self.pr_interactions),
                "pr_reviews": self.pr_reviews,
            },
            "continuous_integration": self.github_actions.to_dict(
                self.commit_keys,
                self.pull_request_keys,
                self.pull_request_heads,
            ),
            "activity_score": self.activity_score,
            "history": {
                "status": self.history_status,
                "graphql_pages": self.history_pages,
                "truncated_sections": self.truncated_sections,
                "interaction_connections_truncated": self.interaction_connections_truncated,
            },
        }


def _repo_from_api(repo: Dict[str, Any]) -> RepoMetrics:
    return RepoMetrics(
        name=repo.get("name", ""),
        full_name=repo.get("full_name", ""),
        url=repo.get("html_url", ""),
        archived=bool(repo.get("archived")),
        fork=bool(repo.get("fork")),
        stars_total=int(repo.get("stargazers_count") or 0),
        forks_total=int(repo.get("forks_count") or 0),
        open_items=int(repo.get("open_issues_count") or 0),
    )


def _github_timestamp(value: datetime) -> str:
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _search_query(
    full_name: str, start: datetime, end: datetime, item_type: str
) -> str:
    if item_type not in {"issue", "pr"}:
        raise ValueError(f"Unsupported GitHub search item type: {item_type}")
    first_date = start.astimezone(timezone.utc).date().isoformat()
    last_date = (end - timedelta(microseconds=1)).astimezone(timezone.utc).date().isoformat()
    return (
        f"repo:{full_name} is:{item_type} "
        f"created:{first_date}..{last_date}"
    )


def _collect_repository_history(
    client: GitHubClient,
    metrics: RepoMetrics,
    start: datetime,
    end: datetime,
    max_pages: int,
) -> None:
    owner, name = metrics.full_name.split("/", 1)
    commit_cursor: Optional[str] = None
    issue_cursor: Optional[str] = None
    pull_request_cursor: Optional[str] = None
    fork_cursor: Optional[str] = None
    include_commits = True
    include_issues = True
    include_pull_requests = True
    include_forks = True
    expected_issues: Optional[int] = None
    expected_pull_requests: Optional[int] = None
    loaded_issues = 0
    loaded_pull_requests = 0

    while (
        include_commits or include_issues or include_pull_requests or include_forks
    ) and metrics.history_pages < max_pages:
        data = client.graphql(
            REPOSITORY_MONTH_QUERY,
            {
                "owner": owner,
                "name": name,
                "since": _github_timestamp(start),
                "until": _github_timestamp(end),
                "issueQuery": _search_query(metrics.full_name, start, end, "issue"),
                "pullRequestQuery": _search_query(metrics.full_name, start, end, "pr"),
                "commitCursor": commit_cursor,
                "issueCursor": issue_cursor,
                "pullRequestCursor": pull_request_cursor,
                "forkCursor": fork_cursor,
                "includeCommits": include_commits,
                "includeIssues": include_issues,
                "includePullRequests": include_pull_requests,
                "includeForks": include_forks,
            },
        )
        metrics.history_pages += 1
        repository = data.get("repository")
        if not isinstance(repository, dict):
            raise GitHubError(f"Repository disappeared during collection: {metrics.full_name}")

        if include_commits:
            branch = repository.get("defaultBranchRef") or {}
            target = branch.get("target") or {}
            history = target.get("history")
            if not isinstance(history, dict):
                include_commits = False
            else:
                metrics.add_commits(history.get("nodes") or [])
                page_info = history.get("pageInfo") or {}
                include_commits = bool(page_info.get("hasNextPage"))
                commit_cursor = page_info.get("endCursor")

        if include_issues:
            search = data.get("issues") or {}
            if expected_issues is None:
                expected_issues = int(search.get("issueCount") or 0)
            nodes = [node for node in search.get("nodes") or [] if isinstance(node, dict)]
            loaded_issues += len(nodes)
            for node in nodes:
                metrics.add_item(node, start, end)
            page_info = search.get("pageInfo") or {}
            include_issues = bool(page_info.get("hasNextPage"))
            issue_cursor = page_info.get("endCursor")

        if include_pull_requests:
            search = data.get("pullRequests") or {}
            if expected_pull_requests is None:
                expected_pull_requests = int(search.get("issueCount") or 0)
            nodes = [node for node in search.get("nodes") or [] if isinstance(node, dict)]
            loaded_pull_requests += len(nodes)
            for node in nodes:
                metrics.add_item(node, start, end)
            page_info = search.get("pageInfo") or {}
            include_pull_requests = bool(page_info.get("hasNextPage"))
            pull_request_cursor = page_info.get("endCursor")

        if include_forks:
            forks = repository.get("forks") or {}
            nodes = [node for node in forks.get("nodes") or [] if isinstance(node, dict)]
            metrics.add_forks(nodes, start, end)
            oldest = min(
                (parse_time(node.get("createdAt")) for node in nodes), default=None
            )
            page_info = forks.get("pageInfo") or {}
            include_forks = bool(
                nodes
                and page_info.get("hasNextPage")
                and oldest
                and oldest >= start
            )
            fork_cursor = page_info.get("endCursor")

    if include_commits:
        metrics.truncated_sections.append("commits")
    if include_issues or (
        expected_issues is not None and loaded_issues < expected_issues
    ):
        metrics.truncated_sections.append("issues")
    if include_pull_requests or (
        expected_pull_requests is not None
        and loaded_pull_requests < expected_pull_requests
    ):
        metrics.truncated_sections.append("pull_requests")
    if include_forks:
        metrics.truncated_sections.append("forks")
    metrics.history_status = "truncated" if metrics.truncated_sections else "available"


def _aggregate(
    organization: str, repositories: Iterable[RepoMetrics]
) -> Dict[str, Any]:
    result = RepoMetrics(
        name=organization,
        full_name=organization,
        url=f"https://github.com/{organization}",
        history_status="available",
    )
    result.github_actions.status = "available"
    for repo in repositories:
        result.stars_total += repo.stars_total
        result.forks_total += repo.forks_total
        result.open_items += repo.open_items
        for name in (
            "forks_added",
            "commits",
            "additions",
            "deletions",
            "issues_opened",
            "issue_comments",
            "issues_closed",
            "issues_responded",
            "prs_opened",
            "pr_comments",
            "pr_reviews",
            "prs_closed",
            "prs_merged",
            "prs_responded",
            "prs_reviewed",
            "linked_prs",
            "history_pages",
            "interaction_connections_truncated",
        ):
            setattr(result, name, getattr(result, name) + getattr(repo, name))
        result.contributors.update(repo.contributors)
        result.code_contributors.update(repo.code_contributors)
        result.non_code_contributors.update(repo.non_code_contributors)
        result.issue_response_hours.extend(repo.issue_response_hours)
        result.issue_close_hours.extend(repo.issue_close_hours)
        result.pr_response_hours.extend(repo.pr_response_hours)
        result.pr_close_hours.extend(repo.pr_close_hours)
        result.pr_interactions.extend(repo.pr_interactions)
        result.commit_keys.update(repo.commit_keys)
        result.pull_request_keys.update(repo.pull_request_keys)
        result.pull_request_heads.update(repo.pull_request_heads)
        result.github_actions.merge(repo.github_actions)
        if repo.history_status != "available":
            result.history_status = "partially_available"
        if repo.github_actions.status != "available":
            result.github_actions.status = "partially_available"
    return result.to_dict()


def collect_statistics(
    client: GitHubClient,
    organization: str,
    start: datetime,
    end: datetime,
    timezone_name: str = "UTC",
    include_archived: bool = True,
    include_forks: bool = True,
    aggregate_forks: bool = False,
    max_history_pages: int = 20,
    max_actions_requests: int = 500,
    progress: Optional[Callable[[str], None]] = None,
) -> Dict[str, Any]:
    if start.tzinfo is None or end.tzinfo is None:
        raise ValueError("Reporting period boundaries must be timezone-aware")
    if start >= end:
        raise ValueError("Reporting period start must be before end")
    if max_history_pages < 1:
        raise ValueError("max_history_pages must be positive")
    if max_actions_requests < 1:
        raise ValueError("max_actions_requests must be positive")

    if progress:
        progress("Loading public repositories")
    repositories = client.paginate(
        f"orgs/{organization}/repos", {"type": "public", "sort": "full_name"}
    )
    selected = [
        repo
        for repo in repositories
        if (include_archived or not repo.get("archived"))
        and (include_forks or not repo.get("fork"))
    ]
    metrics = [_repo_from_api(repo) for repo in selected]
    errors: Dict[str, str] = {}
    for index, repo_metrics in enumerate(metrics, 1):
        if progress:
            progress(f"Repository history {index}/{len(metrics)}: {repo_metrics.full_name}")
        try:
            _collect_repository_history(
                client, repo_metrics, start, end, max_history_pages
            )
        except GitHubError as exc:
            repo_metrics.history_status = "error"
            errors[repo_metrics.full_name] = str(exc)

    if metrics and len(errors) == len(metrics):
        raise GitHubError("Every repository history query failed")

    actions_errors: Dict[str, str] = {}
    for index, repo_metrics in enumerate(metrics, 1):
        if progress:
            progress(
                f"GitHub Actions {index}/{len(metrics)}: {repo_metrics.full_name}"
            )
        repo_metrics.github_actions = collect_github_actions(
            client,
            repo_metrics.full_name,
            start,
            end,
            max_requests=max_actions_requests,
        )
        if repo_metrics.github_actions.error:
            actions_errors[repo_metrics.full_name] = repo_metrics.github_actions.error

    repository_results = sorted(
        (item.to_dict() for item in metrics),
        key=lambda item: (-item["activity_score"], item["name"].lower()),
    )
    zone = ZoneInfo(timezone_name)
    local_start = start.astimezone(zone)
    local_end = end.astimezone(zone)
    complete = sum(item.history_status == "available" for item in metrics)
    truncated = [
        item.full_name for item in metrics if item.history_status == "truncated"
    ]
    aggregate_metrics = metrics if aggregate_forks else [item for item in metrics if not item.fork]
    actions_complete = sum(
        item.github_actions.status == "available" for item in metrics
    )
    actions_with_runs = sum(
        item.github_actions.runs > 0 for item in aggregate_metrics
    )
    next_month = (local_start.replace(day=28) + timedelta(days=4)).replace(day=1)
    is_calendar_month = (
        local_start.day == 1
        and local_start.time().replace(tzinfo=None) == datetime.min.time()
        and local_end == next_month
    )
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "organization": organization,
        "period": {
            "start": start.astimezone(timezone.utc).isoformat(),
            "end_exclusive": end.astimezone(timezone.utc).isoformat(),
            "timezone": timezone_name,
            "local_start": local_start.isoformat(),
            "local_end_exclusive": local_end.isoformat(),
            "kind": "calendar_month" if is_calendar_month else "custom",
            "label": (
                f"{local_start:%Y-%m}"
                if is_calendar_month
                else f"{local_start:%Y%m%dT%H%M}-{local_end:%Y%m%dT%H%M}"
            ),
        },
        "coverage": {
            "source": "GitHub GraphQL per-repository history",
            "complete_repositories": complete,
            "total_repositories": len(metrics),
            "error_repositories": errors,
            "truncated_repositories": truncated,
            "interaction_connections_truncated": sum(
                item.interaction_connections_truncated for item in metrics
            ),
            "new_stars": "unavailable_since_2026_07_github_access_restriction",
            "github_actions": {
                "provider": "github_actions",
                "complete_repositories": actions_complete,
                "total_repositories": len(metrics),
                "error_repositories": actions_errors,
                "aggregate_repositories": len(aggregate_metrics),
                "repositories_with_runs": actions_with_runs,
                "repository_run_coverage_rate": _ratio(
                    actions_with_runs, len(aggregate_metrics)
                ),
            },
        },
        "authentication": "fine_grained_token" if client.authenticated else "anonymous",
        "rate_limit": client.rate_limit,
        "repository_count": len(repository_results),
        "aggregation": {
            "includes_fork_repositories": aggregate_forks,
            "repository_count": len(aggregate_metrics),
        },
        "summary": _aggregate(organization, aggregate_metrics),
        "repositories": repository_results,
        "limitations": [
            "Commit counts and changed lines cover each repository's default branch only.",
            "Issue and pull request interaction metrics use items created in the period and interactions on those items within the same period.",
            "GitHub GraphQL returns at most 100 comments or reviews per item in this report; coverage records truncated connections.",
            "GitHub restricted stargazer identity/timestamp lists in July 2026, so period star additions are unavailable without repository collaborator access.",
            "Organization/individual manager roles are not available reliably from public GitHub data.",
            "The organization summary excludes fork repositories by default to avoid counting imported upstream activity; per-repository results still include them.",
            "CI metrics cover GitHub Actions only. Run duration uses updated_at minus run_started_at and is an API-level approximation.",
        ],
    }


def _markdown_table(headers: List[str], rows: Iterable[Iterable[Any]]) -> List[str]:
    def cell(value: Any) -> str:
        return str(value).replace("|", "\\|").replace("\n", "<br>")

    return [
        "| " + " | ".join(cell(header) for header in headers) + " |",
        "| " + " | ".join("---" if index == 0 else "---:" for index in range(len(headers))) + " |",
        *[
            "| " + " | ".join(cell(value) for value in row) + " |"
            for row in rows
        ],
    ]


def render_markdown(report: Dict[str, Any], top_repositories: int = 10) -> str:
    summary = report["summary"]
    vitality = summary["community_vitality"]
    developers = summary["developer_base"]
    collaboration = summary["collaboration_efficiency"]
    actions = summary["continuous_integration"]
    coverage = report["coverage"]
    aggregation = report["aggregation"]
    period = report["period"]
    local_end = parse_time(period["local_end_exclusive"])
    inclusive_end = local_end - timedelta(days=1) if local_end else None
    warning = (
        ""
        if coverage["complete_repositories"] == coverage["total_repositories"]
        else "；存在数据缺口"
    )

    lines = [
        f"## {report['organization']} {period['label']} 开源生态统计",
        "",
        (
            f"> 自然月：{period['local_start'][:10]} 至 "
            f"{inclusive_end:%Y-%m-%d}（{period['timezone']}）{warning}"
            if period.get("kind") == "calendar_month"
            else f"> 统计区间：{period['local_start']} 至 "
            f"{period['local_end_exclusive']}（结束时间不包含）{warning}"
        ),
        "",
        "### 组织汇总",
        "",
        "#### 活跃度",
        "",
    ]
    lines.extend(
        _markdown_table(
            ["范围", "公开仓库", "汇总仓库", "当前 Stars", "当前 Forks"],
            [[
                report["organization"],
                report["repository_count"],
                aggregation["repository_count"],
                summary["current"]["stars"],
                summary["current"]["forks"],
            ]],
        )
    )
    lines.extend([""])
    lines.extend(
        _markdown_table(
            ["当月指标", "数值"],
            [
                ["新增 Stars", "N/A"],
                ["新增 Forks", vitality["forks_added"]],
                ["默认分支 Commits", vitality["commits"]],
                ["代码变更行", _number(vitality["lines_changed"])],
                ["新建 Issue", vitality["issues_opened"]],
                ["Issue 评论", vitality["issue_comments"]],
                ["新建 PR", vitality["prs_opened"]],
                ["合并 PR", collaboration["prs_merged"]],
                ["PR 评审", collaboration["pr_reviews"]],
                ["活跃贡献者", developers["contributors"]],
                ["代码贡献者", developers["code_contributors"]],
                ["非代码贡献者", developers["non_code_contributors"]],
            ],
        )
    )
    lines.extend(["", "#### 协作质量", ""])
    lines.extend(
        _markdown_table(
            ["对象", "未响应率", "首次响应", "处理时长"],
            [
                [
                    "Issue",
                    _percent(collaboration["issue_unresponsive_rate"]),
                    _hours(collaboration["issue_first_response_hours"]),
                    _hours(collaboration["issue_resolution_hours"]),
                ],
                [
                    "PR",
                    _percent(collaboration["pr_unresponsive_rate"]),
                    _hours(collaboration["pr_first_response_hours"]),
                    _hours(collaboration["pr_resolution_hours"]),
                ],
            ],
        )
    )
    lines.extend([""])
    lines.extend(
        _markdown_table(
            ["PR 指标", "数值"],
            [
                ["合并率", _percent(collaboration["pr_merge_rate"])],
                [
                    "评审参与率",
                    _percent(collaboration["pr_review_participation_rate"]),
                ],
                ["平均交互", collaboration["pr_average_interactions"] or "N/A"],
                ["PR/Issue 关联率", _percent(collaboration["pr_issue_link_rate"])],
            ],
        )
    )
    lines.extend(["", "#### GitHub Actions 质量", ""])
    lines.extend(
        _markdown_table(
            ["Runs", "成功", "失败", "取消", "跳过"],
            [[
                actions["runs"],
                actions["successful_runs"],
                actions["conclusions"].get("failure", 0),
                actions["conclusions"].get("cancelled", 0),
                actions["conclusions"].get("skipped", 0),
            ]],
        )
    )
    lines.extend([""])
    lines.extend(
        _markdown_table(
            ["成功率", "首次通过率", "重跑次数", "重跑率"],
            [[
                _percent(actions["success_rate"]),
                _percent(actions["first_attempt_pass_rate"]),
                actions["rerun_runs"],
                _percent(actions["rerun_rate"]),
            ]],
        )
    )
    lines.extend([""])
    lines.extend(
        _markdown_table(
            ["Run 墙钟时长", "总计", "平均", "P50", "P90"],
            [[
                "统计值",
                _total_minutes(actions["duration_minutes"]["total"]),
                _minutes(actions["duration_minutes"]["average"]),
                _minutes(actions["duration_minutes"]["p50"]),
                _minutes(actions["duration_minutes"]["p90"]),
            ]],
        )
    )
    lines.extend([""])
    lines.extend(
        _markdown_table(
            ["排队时长", "平均", "P50", "P90"],
            [[
                "统计值",
                _minutes(actions["queue_minutes"]["average"]),
                _minutes(actions["queue_minutes"]["p50"]),
                _minutes(actions["queue_minutes"]["p90"]),
            ]],
        )
    )
    lines.extend([""])
    lines.extend(
        _markdown_table(
            ["覆盖点", "Workflow", "仓库", "PR", "默认分支 Commit"],
            [[
                "GitHub Actions",
                actions["workflow_count"],
                f"{coverage['github_actions']['repositories_with_runs']}/"
                f"{coverage['github_actions']['aggregate_repositories']}",
                _percent(actions["coverage"]["pull_request_rate"]),
                _percent(actions["coverage"]["default_branch_commit_rate"]),
            ]],
        )
    )
    lines.extend(
        ["", f"### 重点仓库汇总（活跃度 Top {top_repositories}）", ""]
    )
    active = [
        repo
        for repo in report["repositories"]
        if repo["activity_score"] > 0
        and (aggregation["includes_fork_repositories"] or not repo["fork"])
    ]
    selected = active[:top_repositories]
    if selected:
        lines.extend(["#### 仓库活跃度", ""])
        lines.extend(
            _markdown_table(
                ["仓库", "Commits", "变更行", "Issue", "PR", "合并"],
                [
                    [
                        f"{index}. [{repo['name']}]({repo['url']})",
                        repo["community_vitality"]["commits"],
                        _number(repo["community_vitality"]["lines_changed"]),
                        repo["community_vitality"]["issues_opened"],
                        repo["community_vitality"]["prs_opened"],
                        repo["collaboration_efficiency"]["prs_merged"],
                    ]
                    for index, repo in enumerate(selected, 1)
                ],
            )
        )

        lines.extend(["", "#### 协作质量", ""])
        lines.extend(
            _markdown_table(
                ["仓库", "Issue 响应", "PR 响应", "评审参与", "合并率"],
                [
                    [
                        f"{index}. [{repo['name']}]({repo['url']})",
                        _hours(
                            repo["collaboration_efficiency"][
                                "issue_first_response_hours"
                            ]
                        ),
                        _hours(
                            repo["collaboration_efficiency"][
                                "pr_first_response_hours"
                            ]
                        ),
                        _percent(
                            repo["collaboration_efficiency"][
                                "pr_review_participation_rate"
                            ]
                        ),
                        _percent(
                            repo["collaboration_efficiency"]["pr_merge_rate"]
                        ),
                    ]
                    for index, repo in enumerate(selected, 1)
                ],
            )
        )

        lines.extend(["", "#### GitHub Actions 质量", ""])
        lines.extend(
            _markdown_table(
                ["仓库", "Runs", "成功率", "首次通过", "总时长", "P50", "P90"],
                [
                    [
                        f"{index}. [{repo['name']}]({repo['url']})",
                        repo["continuous_integration"]["runs"],
                        _percent(
                            repo["continuous_integration"]["success_rate"]
                        ),
                        _percent(
                            repo["continuous_integration"][
                                "first_attempt_pass_rate"
                            ]
                        ),
                        _total_minutes(
                            repo["continuous_integration"]["duration_minutes"][
                                "total"
                            ]
                        ),
                        _minutes(
                            repo["continuous_integration"]["duration_minutes"][
                                "p50"
                            ]
                        ),
                        _minutes(
                            repo["continuous_integration"]["duration_minutes"][
                                "p90"
                            ]
                        ),
                    ]
                    for index, repo in enumerate(selected, 1)
                ],
            )
        )

        lines.extend(["", "#### CI 覆盖", ""])
        lines.extend(
            _markdown_table(
                ["仓库", "Workflow", "PR 覆盖", "默认分支 Commit 覆盖"],
                [
                    [
                        f"{index}. [{repo['name']}]({repo['url']})",
                        repo["continuous_integration"]["workflow_count"],
                        _percent(
                            repo["continuous_integration"]["coverage"][
                                "pull_request_rate"
                            ]
                        ),
                        _percent(
                            repo["continuous_integration"]["coverage"][
                                "default_branch_commit_rate"
                            ]
                        ),
                    ]
                    for index, repo in enumerate(selected, 1)
                ],
            )
        )
    if not active:
        lines.append("本期没有采集到公开活动。")
    lines.extend(
        [
            "",
            f"> 指标参考 OSS Compass V3。仓库历史完整覆盖 "
            f"{coverage['complete_repositories']}/{coverage['total_repositories']}；"
            f"Actions 完整覆盖 {coverage['github_actions']['complete_repositories']}/"
            f"{coverage['github_actions']['total_repositories']}。新增 Stars 因 GitHub "
            "访问限制为 N/A；完整仓库明细见 JSON 报告。",
        ]
    )
    return "\n".join(lines)


def _hours(value: Optional[float]) -> str:
    if value is None:
        return "N/A"
    if value >= 24:
        return f"{value / 24:.1f} 天"
    return f"{value:.1f} 小时"


def _percent(value: Optional[float]) -> str:
    return "N/A" if value is None else f"{value * 100:.1f}%"


def _number(value: Optional[int]) -> str:
    return "N/A" if value is None else f"{value:,}"


def _minutes(value: Optional[float]) -> str:
    if value is None:
        return "N/A"
    if value >= 60:
        return f"{value / 60:.1f} 小时"
    return f"{value:.1f} 分钟"


def _total_minutes(value: Optional[float]) -> str:
    if value is None:
        return "N/A"
    return f"{value / 60:,.1f} 小时"
