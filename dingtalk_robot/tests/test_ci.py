import unittest
from datetime import datetime, timezone

from dingtalk_robot.oss_stats.ci import collect_github_actions


class FakeGitHubClient:
    def __init__(self):
        self.params = []

    def get(self, path, params=None):
        self.params.append(params)
        return {
            "total_count": 2,
            "workflow_runs": [
                {
                    "id": 1,
                    "name": "CI",
                    "workflow_id": 100,
                    "path": ".github/workflows/ci.yml",
                    "event": "pull_request",
                    "status": "completed",
                    "conclusion": "success",
                    "run_attempt": 1,
                    "created_at": "2026-08-02T00:00:00Z",
                    "run_started_at": "2026-08-02T00:02:00Z",
                    "updated_at": "2026-08-02T00:12:00Z",
                    "head_sha": "commit-one",
                    "pull_requests": [{"number": 10}],
                },
                {
                    "id": 2,
                    "name": "CI",
                    "workflow_id": 100,
                    "path": ".github/workflows/ci.yml",
                    "event": "push",
                    "status": "completed",
                    "conclusion": "failure",
                    "run_attempt": 2,
                    "created_at": "2026-08-03T00:00:00Z",
                    "run_started_at": "2026-08-03T00:01:00Z",
                    "updated_at": "2026-08-03T00:21:00Z",
                    "head_sha": "other-commit",
                    "pull_requests": [],
                },
            ],
        }, {}


class GitHubActionsMetricsTest(unittest.TestCase):
    def test_counts_duration_and_coverage(self):
        client = FakeGitHubClient()
        metrics = collect_github_actions(
            client,
            "OpenXiangShan/demo",
            datetime(2026, 8, 1, tzinfo=timezone.utc),
            datetime(2026, 9, 1, tzinfo=timezone.utc),
        )
        result = metrics.to_dict(
            {
                "OpenXiangShan/demo@commit-one",
                "OpenXiangShan/demo@commit-two",
            },
            {"OpenXiangShan/demo#10", "OpenXiangShan/demo#11"},
            {},
        )
        self.assertEqual(result["runs"], 2)
        self.assertEqual(result["conclusions"], {"failure": 1, "success": 1})
        self.assertEqual(result["success_rate"], 0.5)
        self.assertEqual(result["first_attempt_pass_rate"], 0.5)
        self.assertEqual(result["rerun_rate"], 0.5)
        self.assertEqual(result["workflow_count"], 1)
        self.assertEqual(result["workflows"][0]["path"], ".github/workflows/ci.yml")
        self.assertEqual(result["workflows"][0]["runs"], 2)
        self.assertEqual(result["queue_minutes"]["p50"], 1.5)
        self.assertEqual(result["duration_basis"], "workflow_run_wall_clock")
        self.assertEqual(result["duration_minutes"]["total"], 30.0)
        self.assertEqual(result["duration_minutes"]["p50"], 15.0)
        self.assertEqual(result["coverage"]["default_branch_commit_rate"], 0.5)
        self.assertEqual(result["coverage"]["pull_request_rate"], 0.5)
        self.assertIn("T00:00:00Z..", client.params[0]["created"])


if __name__ == "__main__":
    unittest.main()
