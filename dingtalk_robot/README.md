# DingTalk robots

This directory contains reusable DingTalk custom-robot helpers and concrete robot
jobs. Python 3.9 or newer is sufficient. Install the Excel export dependency with:

```bash
python3 -m pip install -r dingtalk_robot/requirements.txt
```

## Configuration

`config.json` is the local runtime configuration. It is ignored by Git and should
remain readable only by its owner. Start from `config.example.json` on a new host.

```json
{
  "dingtalk": {
    "webhook": "https://oapi.dingtalk.com/robot/send?access_token=...",
    "secret": "SEC..."
  },
  "github": {
    "organization": "OpenXiangShan",
    "token": "",
    "token_file": "token",
    "proxy": ""
  }
}
```

Put the fine-grained PAT in the ignored `token` file and keep `github.token_file` as
shown. Alternatively, place it directly in `github.token`. The token is only sent in
the HTTPS `Authorization` header and is never included in reports or logs. Public
repository read access is sufficient. The history collector requires a token because
it uses GitHub GraphQL; an empty token is rejected with a configuration error.

Set `github.proxy` when GitHub must be reached through a proxy. Leave it empty to use
the standard process proxy environment or a direct connection. The per-request timeout
is controlled by `github.timeout_seconds`.

## Reusable DingTalk API

`robot.py` provides `signed_webhook`, `send_message`, `send_text`, and
`send_markdown`. Credentials are passed by callers after loading `config.json`.

## OSS stats robot

Run from the repository root:

```bash
# Previous full calendar month in oss_stats.timezone (the default)
python3 -m dingtalk_robot.oss_stats --dry-run

# A specified calendar month
python3 -m dingtalk_robot.oss_stats --month 2026-08 --dry-run

# A custom interval; --end is exclusive
python3 -m dingtalk_robot.oss_stats \
  --start 2026-08-10 --end 2026-08-20 --dry-run

# Collect the default period and send the summary to DingTalk
python3 -m dingtalk_robot.oss_stats
```

On September 1, for example, the default period is the whole of August. The job
writes the organization and per-repository report to
`dingtalk_robot/oss_stats/reports/YYYY-MM.json` and an Excel workbook to the same
directory. The workbook contains organization totals, all repository metrics, GitHub
Actions quality and coverage, workflow details, and metric definitions. Use
`--xlsx-output PATH` to override its location. The DingTalk message contains the
organization summary and the most active repositories. Report files are local runtime
artifacts and are ignored by Git.

Metrics follow the [OSS Compass V3 community ecosystem health dimensions](https://oss-compass.org/zh/docs/docs/v3-assessment/Community%20Ecosystem%20Health%20Assessment/Overview/)
where they can be derived from GitHub's repository history:

- Community vitality: new forks, default-branch commits and changed lines, issues,
  pull requests, comments, reviews, and contributors.
- Developer base: code, non-code, and combined contributors observed in the period.
- Collaboration efficiency: first-response and resolution time, merge rate, review
  participation, issue links, and interactions.
- Continuous integration: GitHub Actions run counts, conclusions, queue and execution
  duration (total, average, P50, and P90), reruns, and
  repository/PR/default-branch-commit coverage.
- Open governance: reported as unavailable because public GitHub API data does not
  expose organization-versus-individual manager roles reliably.

The collector first enumerates every public organization repository, then queries each
repository's commit, issue, pull-request, and fork history directly. It does not use
GitHub's 300-item public event stream. `max_history_pages` caps pagination per
repository and any truncation or per-repository error is recorded in the report.

Commit and changed-line counts cover the default branch. Issue/PR collaboration
metrics form a cohort from items created in the period and consider interactions on
those items within the same period. GitHub limits nested comments and reviews to 100
per item in this implementation; affected connections are counted in coverage.
GitHub restricted stargazer identity/timestamp access in July 2026. This collector
therefore reports historical new Stars as `N/A`; current total Stars remain available.

All public repositories, including forks, are collected by default. To prevent an
upstream mirror's commits from dominating organization health, `aggregate_forks` is
`false` by default; fork results remain available in the per-repository JSON. Set it
to `true` only when upstream activity is intentionally part of the organization total.

CI metrics intentionally cover GitHub Actions only. The collector first queries the
whole interval and automatically splits high-volume intervals when GitHub's 1,000-run
filtered-search limit would truncate data. `max_actions_requests` is a per-repository
safety limit. Run duration is approximated from `run_started_at` to `updated_at` and
reported as workflow-run wall-clock time. It is not parallel-job runner or billing
time; job and log downloads are not required.

Run tests with:

```bash
python3 -m unittest discover -s dingtalk_robot/tests -v
```
