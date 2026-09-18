import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from dingtalk_robot.xiangshan_monitor.xiangshan_monitor import (
    RANDOM_GIFT_DENOMINATOR,
    RepositorySpec,
    clone_or_pull,
    random_gift_slots,
)


class _FixedDigest:
    def __init__(self, value: int):
        self._value = value

    def digest(self):
        return self._value.to_bytes(32, "big")


class XiangShanMonitorSyncTest(unittest.TestCase):
    def test_existing_clone_force_checkouts_origin_default_without_pull(self):
        calls = []

        def fake_git(args, cwd=None, timeout=None):
            calls.append(list(args))
            if args[:3] == ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"]:
                return "origin/kunminghu-v3\n"
            return ""

        with tempfile.TemporaryDirectory() as directory_name:
            clone_root = Path(directory_name)
            repo = clone_root / "XiangShan"
            (repo / ".git").mkdir(parents=True)
            path, branch = clone_or_pull(
                RepositorySpec("XiangShan", branch="ignored-local"),
                "OpenXiangShan",
                clone_root,
                fake_git,
            )

        self.assertEqual(path, repo)
        self.assertEqual(branch, "kunminghu-v3")
        self.assertEqual(calls[0], ["fetch", "--prune", "origin"])
        self.assertEqual(calls[1], ["remote", "set-head", "origin", "--auto"])
        self.assertEqual(calls[2], ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"])
        self.assertEqual(calls[3], ["checkout", "--force", "--detach", "origin/kunminghu-v3"])
        self.assertFalse(any(call and call[0] == "pull" for call in calls))

    def test_fresh_clone_does_not_pin_a_configured_branch(self):
        calls = []

        def fake_git(args, cwd=None, timeout=None):
            calls.append(list(args))
            if args[:3] == ["symbolic-ref", "--short", "refs/remotes/origin/HEAD"]:
                return "origin/master\n"
            return ""

        with tempfile.TemporaryDirectory() as directory_name:
            clone_root = Path(directory_name)
            path, branch = clone_or_pull(
                RepositorySpec("NEMU", branch="master"),
                "OpenXiangShan",
                clone_root,
                fake_git,
            )
            self.assertEqual(path, clone_root / "NEMU")

        self.assertEqual(branch, "master")
        self.assertEqual(calls[0][0], "clone")
        self.assertNotIn("--branch", calls[0])
        self.assertFalse(any(call and call[0] == "pull" for call in calls))

    def test_random_gift_odds_are_one_in_five(self):
        self.assertEqual(RANDOM_GIFT_DENOMINATOR, 5)
        report = {
            "date": "2026-09-18",
            "repositories": [{"name": "XiangShan", "head_sha": "a" * 40}],
        }
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.hashlib.sha256",
            return_value=_FixedDigest(5),
        ):
            self.assertEqual(random_gift_slots(report, 1), [1])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.hashlib.sha256",
            return_value=_FixedDigest(7),
        ):
            self.assertEqual(random_gift_slots(report, 1), [])


if __name__ == "__main__":
    unittest.main()
