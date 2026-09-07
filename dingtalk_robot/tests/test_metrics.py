import unittest
from datetime import datetime, timezone

from dingtalk_robot.oss_stats.metrics import collect_statistics, render_markdown


class FakeGitHubClient:
    authenticated = True
    rate_limit = {"remaining": 4998, "limit": 5000}

    def paginate(self, path, params=None, max_items=None):
        return [
            {
                "name": "demo",
                "full_name": "OpenXiangShan/demo",
                "html_url": "https://github.com/OpenXiangShan/demo",
                "stargazers_count": 10,
                "forks_count": 2,
                "open_issues_count": 1,
                "archived": False,
                "fork": False,
            }
        ]

    def get(self, path, params=None):
        return {"total_count": 0, "workflow_runs": []}, {}

    def graphql(self, query, variables):
        return {
            "repository": {
                "defaultBranchRef": {
                    "target": {
                        "history": {
                            "totalCount": 1,
                            "pageInfo": {"hasNextPage": False, "endCursor": None},
                            "nodes": [
                                {
                                    "oid": "abc123",
                                    "additions": 100,
                                    "deletions": 20,
                                    "author": {
                                        "name": "Alice",
                                        "email": "alice@example.test",
                                        "user": {"login": "alice"},
                                    },
                                }
                            ],
                        }
                    }
                },
                "forks": {
                    "pageInfo": {"hasNextPage": False, "endCursor": None},
                    "nodes": [{"createdAt": "2026-08-03T00:00:00Z"}],
                },
            },
            "issues": {
                "issueCount": 1,
                "pageInfo": {"hasNextPage": False, "endCursor": None},
                "nodes": [
                    {
                        "number": 1,
                        "createdAt": "2026-08-02T00:00:00Z",
                        "closedAt": None,
                        "body": "",
                        "author": {"login": "bob"},
                        "comments": {
                            "totalCount": 1,
                            "nodes": [
                                {
                                    "createdAt": "2026-08-02T02:00:00Z",
                                    "author": {"login": "alice"},
                                }
                            ],
                        },
                    }
                ],
            },
            "pullRequests": {
                "issueCount": 0,
                "pageInfo": {"hasNextPage": False, "endCursor": None},
                "nodes": [],
            },
            "rateLimit": {"cost": 1, "remaining": 4998},
        }


class MetricsTest(unittest.TestCase):
    def test_repository_history_aggregation(self):
        report = collect_statistics(
            FakeGitHubClient(),
            "OpenXiangShan",
            start=datetime(2026, 8, 1, tzinfo=timezone.utc),
            end=datetime(2026, 9, 1, tzinfo=timezone.utc),
        )
        summary = report["summary"]
        vitality = summary["community_vitality"]
        self.assertEqual(vitality["commits"], 1)
        self.assertEqual(vitality["lines_changed"], 120)
        self.assertEqual(vitality["forks_added"], 1)
        self.assertEqual(vitality["issues_opened"], 1)
        self.assertEqual(
            summary["collaboration_efficiency"]["issue_first_response_hours"], 2.0
        )
        self.assertEqual(summary["developer_base"]["contributors"], 2)
        self.assertEqual(report["coverage"]["complete_repositories"], 1)
        self.assertEqual(report["repositories"][0]["current"]["stars"], 10)
        ci = report["summary"]["continuous_integration"]
        self.assertEqual(ci["provider"], "github_actions")
        self.assertEqual(ci["runs"], 0)
        self.assertNotIn(
            "pr_non_author_merge_rate", summary["collaboration_efficiency"]
        )
        message = render_markdown(report, top_repositories=1)
        self.assertIn("### 组织汇总", message)
        self.assertIn("#### 协作质量", message)
        self.assertIn("#### GitHub Actions 质量", message)
        self.assertIn("| Run 墙钟时长 | 总计 | 平均 | P50 | P90 |", message)
        self.assertIn("### 重点仓库汇总（活跃度 Top 1）", message)
        self.assertIn("#### 仓库活跃度", message)
        self.assertIn("#### 协作质量", message)
        self.assertIn("#### CI 覆盖", message)
        self.assertIn("| 仓库 | Runs | 成功率 | 首次通过 | 总时长 | P50 | P90 |", message)
        self.assertIn(
            "| 仓库 | Workflow | PR 覆盖 | 默认分支 Commit 覆盖 |", message
        )
        self.assertIn("| --- | ---: |", message)


if __name__ == "__main__":
    unittest.main()
