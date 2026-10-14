# OSS statistics

Collect monthly GitHub organization activity and export local JSON and Excel
reports. The command also prints a Markdown summary. Python 3.9 or newer is
required.

## Setup

Run from the repository root:

```bash
python3 -m pip install -r oss_stats/requirements.txt
cp oss_stats/config.example.json oss_stats/config.json
export GITHUB_TOKEN='YOUR_GITHUB_TOKEN'
```

The collector uses GraphQL for repository history, so a GitHub personal access
token with public repository read access is required. Set `GITHUB_TOKEN` in the
environment before running the command. Local configuration, snapshots, and
generated reports are ignored by Git.

Set `github.organization` to choose the organization. Set `github.proxy` when
needed; an empty value uses the process proxy environment. The request timeout
is `github.timeout_seconds`. This tool uses its own configuration and has no
DingTalk configuration or delivery step.

## Usage

```bash
# Previous complete calendar month in the configured timezone
python3 -m oss_stats

# A specified month
python3 -m oss_stats --month 2026-09

# A custom interval; --end is exclusive
python3 -m oss_stats --start 2026-09-10 --end 2026-09-20

# Use an existing report as the Star baseline
python3 -m oss_stats --star-baseline /path/to/previous-report.json

# Override configuration or output files
python3 -m oss_stats --config /path/to/config.json \
  --output /path/to/report.json --xlsx-output /path/to/report.xlsx
```

The default configuration is `oss_stats/config.json`. Paths configured in that
file are relative to its directory. With the example
configuration, reports are saved to `oss_stats/reports/YYYY-MM.json` and
`oss_stats/reports/YYYY-MM.xlsx`; Star snapshots are saved to
`oss_stats/star_history.json`. Explicit output arguments are relative to the
working directory. On October 1, the default reporting period is September 1
through September 30 in `oss_stats.timezone` (default `Asia/Shanghai`).

The workbook contains organization totals, repository activity, collaboration,
GitHub Actions quality, CI coverage, workflow details, and metric definitions.
For monthly automation, run the command from cron or a systemd timer.

## Metrics and reporting rules

Metrics follow the [OSS Compass V3 community ecosystem health dimensions](https://oss-compass.org/zh/docs/docs/v3-assessment/Community%20Ecosystem%20Health%20Assessment/Overview/)
where public GitHub history provides the necessary data:

- Activity: new forks, default-branch commits, added/deleted lines, issues, PRs,
  comments, reviews, and contributors.
- Developer base: code, non-code, and combined contributor identities, deduplicated
  across repositories in the organization summary.
- Collaboration: response and resolution time, unresponsive rates, PR merge rate,
  review participation, interactions, and links to issues.
- CI: GitHub Actions run results, success and rerun rates, queue and execution
  duration, workflows, and repository/PR/default-branch-commit coverage.

All public repositories, including archived repositories and forks, are collected
by default. Organization totals exclude forks unless `aggregate_forks` is true.
Set `include_archived` or `include_forks` to false to skip collecting those
repositories. Commit counts and changed lines cover the default branch only.

### PR creation and merging

Created PRs are counted by `createdAt`. Merged PRs are counted independently by
`mergedAt`, including PRs created before the reporting period. The creation-cohort
merge rate is PRs created and merged in the period divided by PRs created in the
period, so its numerator can differ from the independent merged PR count.

Issue/PR collaboration metrics still use items created in the reporting period and
their interactions or closure within that period. They do not include every
interaction on older items.

### New repository code lines

Repositories created in or after the reporting period have added, deleted, and
changed lines set to zero. The collector skips their commit line-count fields to
avoid treating imported history as new code. Commit counts and other activity are
still collected for repositories created during the period. Repositories created
after the interval are not queried for history in that interval. Creation times
and zeroed line-count exceptions are recorded in the reports.

### Star net growth

Star net growth is the current total minus the previous month's saved total,
including the effect of unstars. No stargazer identities or `starred_at` timestamps
are requested.

Each run saves its snapshot to `oss_stats.star_history`. The baseline is the latest
complete organization snapshot saved during the previous local calendar month. If
only partial snapshots exist, the latest is used and comparable repository coverage
is reported. Both snapshot dates appear separately from the activity reporting
period. The first run records a snapshot and labels the comparison as missing a
baseline.

`--star-baseline PATH` accepts a previous OSS report, daily XiangShan monitor report,
or standalone Star snapshot. Imported baselines are retained alongside new
snapshots; repeated runs do not overwrite the previous month's baseline. Complete
organization snapshots account for added or removed repositories using the report's
fork setting. Partial snapshots compare repositories with known totals; newly
created repositories have a baseline of zero if they postdate the snapshot.

## Coverage and limitations

The collector queries each repository's history rather than GitHub's limited public
event stream. `max_history_pages` caps history pagination; `max_actions_requests`
caps Actions requests per repository. High-volume Actions intervals are split to
avoid GitHub's 1,000-run filtered-search limit.

Check the JSON `coverage` field for errors and truncation even when the command
exits successfully. Nested comments and reviews are limited to 100 per item, and
affected connections are counted. CI covers GitHub Actions only. Run duration is
the approximate wall-clock time from `run_started_at` to `updated_at`, not summed
parallel-job runner time or billing time. Public data cannot reliably identify
organization-versus-individual manager roles, so open governance is unavailable.
