import json
import tempfile
import unittest
from datetime import date
from pathlib import Path
from unittest.mock import patch

from dingtalk_robot.config import ConfigError
from dingtalk_robot.xiangshan_monitor.xiangshan_monitor import (
    COMMIT_PITY_THRESHOLD,
    GIFT_KIND_COMMIT_PITY,
    GIFT_KIND_HIGHLIGHT_PITY,
    GIFT_KIND_MID_AUTUMN,
    GIFT_KIND_WEEKLY_PITY,
    RANDOM_GIFT_DENOMINATOR,
    RepositorySpec,
    apply_gift_result,
    clone_or_pull,
    default_gift_settings,
    empty_gift_history,
    persist_gift_result,
    extract_highlights,
    format_gift_fallback,
    gift_settings,
    load_repository_data,
    random_gift_slots,
    resolve_gift_awards,
    talk,
    _analysis_start_time,
    _delivery_times,
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


def _gift_report(day="2026-09-21", commits=None, head=None):
    return {
        "date": day,
        "timezone": "Asia/Shanghai",
        "repositories": [
            {
                "name": "XiangShan",
                "head_sha": head or ("a" * 40),
                "commits": commits or [],
            }
        ],
    }


def _commit(author, email, sha, authored_at="2026-09-21T10:00:00+08:00"):
    return {"sha": sha, "author": author, "email": email, "authored_at": authored_at, "subject": "work"}


def _person(name="Alice", email="alice@example.com", slot=1):
    return {"key": f"email:{email.lower()}", "name": name, "email": email, "slot": slot}


class XiangShanGiftPityTest(unittest.TestCase):
    def test_gift_settings_read_from_config(self):
        settings = gift_settings({
            "xiangshan_monitor": {
                "gifts": {
                    "win_denominator": 2,
                    "tracking_start": "2026-09-21",
                    "special_gifts": [{
                        "id": "new_year",
                        "name": "新年礼物",
                        "enabled": False,
                        "windows": [{"start": "2026-09-22", "end": "2026-09-23"}],
                        "per_day": 2,
                    }],
                    "highlight_pity": {"threshold": 4},
                    "commit_pity": {"enabled": False, "threshold": 10},
                    "weekly_pity": {"window_days": 3},
                }
            }
        })
        self.assertEqual(settings["win_denominator"], 2)
        self.assertEqual(settings["tracking_start"].isoformat(), "2026-09-21")
        self.assertEqual(settings["special_gifts"][0]["id"], "new_year")
        self.assertFalse(settings["special_gifts"][0]["enabled"])
        self.assertEqual(settings["special_gifts"][0]["per_day"], 2)
        self.assertEqual(settings["special_gifts"][0]["windows"][0][0].isoformat(), "2026-09-22")
        self.assertEqual(settings["highlight_pity"]["threshold"], 4)
        self.assertFalse(settings["commit_pity"]["enabled"])
        self.assertEqual(settings["weekly_pity"]["window_days"], 3)

    def test_gift_settings_reject_invalid_odds(self):
        with self.assertRaises(ConfigError):
            gift_settings({"xiangshan_monitor": {"gifts": {"win_denominator": 0}}})

    def test_win_denominator_one_always_hits(self):
        report = _gift_report(day="2026-09-30")
        settings = default_gift_settings()
        settings["win_denominator"] = 1
        self.assertEqual(random_gift_slots(report, 2, settings), [1, 2])

    def test_disabled_special_gifts_do_not_force_a_gift(self):
        settings = default_gift_settings()
        settings["special_gifts"] = []
        settings["weekly_pity"]["enabled"] = False
        report = _gift_report(commits=[_commit("Alice", "alice@example.com", "1" * 40)])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], empty_gift_history("Asia/Shanghai"), 1, settings)
        self.assertEqual(result["awards"], [])

    def test_configured_highlight_threshold(self):
        settings = default_gift_settings()
        settings["special_gifts"] = []
        settings["weekly_pity"]["enabled"] = False
        settings["highlight_pity"]["threshold"] = 2
        history = empty_gift_history("Asia/Shanghai")
        history["people"]["email:alice@example.com"] = {
            "name": "Alice",
            "email": "alice@example.com",
            "highlights_since_gift": 1,
            "wins": 0,
            "commits_since_gift": 0,
            "total_commits": 0,
            "last_gift_date": None,
        }
        report = _gift_report(day="2026-09-30")
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], history, 1, settings)
        self.assertEqual(result["awards"][0]["kind"], GIFT_KIND_HIGHLIGHT_PITY)

    def test_workday_debug_moves_to_1745(self):
        data = load_repository_data()
        debug_time, release_time = _delivery_times(data)
        self.assertEqual(debug_time, "17:45")
        self.assertEqual(release_time, "18:00")
        self.assertEqual(_analysis_start_time(data), "17:39")

    def test_extract_highlights_from_structured_block(self):
        report = _gift_report(commits=[_commit("Alice", "alice@example.com", "1" * 40)])
        praise, people = extract_highlights(
            "今天 Alice 很棒。\n\n<<<xiangshan-highlights>>>\n1. Alice <alice@example.com>\n<<<xiangshan-highlights-end>>>\n",
            report,
            1,
        )
        self.assertEqual(praise, "今天 Alice 很棒。")
        self.assertEqual(people[0]["email"], "alice@example.com")
        self.assertEqual(people[0]["slot"], 1)

    def test_special_gift_converts_a_random_win(self):
        report = _gift_report()
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[1],
        ):
            result = resolve_gift_awards(report, [_person()], empty_gift_history("Asia/Shanghai"), 1)
        self.assertEqual([award["kind"] for award in result["awards"]], [GIFT_KIND_MID_AUTUMN])
        self.assertEqual(result["awards"][0]["label"], "中秋礼物")
        self.assertTrue(result["pity"])

    def test_special_gift_forces_one_copy_when_random_misses(self):
        report = _gift_report(commits=[_commit("Alice", "alice@example.com", "1" * 40)])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], empty_gift_history("Asia/Shanghai"), 1)
        self.assertEqual(len(result["awards"]), 1)
        self.assertEqual(result["awards"][0]["kind"], GIFT_KIND_MID_AUTUMN)
        self.assertEqual(result["awards"][0]["name"], "Alice")

    def test_special_gift_per_day_can_award_multiple_people(self):
        settings = default_gift_settings()
        settings["special_gifts"] = [{
            "id": "festival",
            "name": "节日礼物",
            "enabled": True,
            "windows": [(date(2026, 9, 21), date(2026, 9, 21))],
            "per_day": 2,
        }]
        settings["weekly_pity"]["enabled"] = False
        report = _gift_report(commits=[
            _commit("Alice", "alice@example.com", "1" * 40),
            _commit("Bob", "bob@example.com", "2" * 40),
        ])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(
                report,
                [_person(), _person("Bob", "bob@example.com", 2)],
                empty_gift_history("Asia/Shanghai"),
                2,
                settings,
            )
        self.assertEqual(len(result["awards"]), 2)
        self.assertEqual({award["name"] for award in result["awards"]}, {"Alice", "Bob"})
        self.assertEqual({award["label"] for award in result["awards"]}, {"节日礼物"})

    def test_special_gift_remaining_zero_skips_the_award(self):
        settings = default_gift_settings()
        settings["weekly_pity"]["enabled"] = False
        report = _gift_report(commits=[_commit("Alice", "alice@example.com", "1" * 40)])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(
                report,
                [_person()],
                empty_gift_history("Asia/Shanghai"),
                1,
                settings,
                {"random": 20, "mid_autumn": 0},
            )
        self.assertEqual(result["awards"], [])
        self.assertEqual(result["inventory"]["random"], 20)
        self.assertEqual(result["inventory"]["mid_autumn"], 0)

    def test_special_day_does_not_consume_random_inventory(self):
        settings = default_gift_settings()
        settings["weekly_pity"]["enabled"] = False
        report = _gift_report()
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[1],
        ):
            result = resolve_gift_awards(
                report,
                [_person()],
                empty_gift_history("Asia/Shanghai"),
                1,
                settings,
                {"random": 20, "mid_autumn": 5},
            )
        self.assertEqual(result["awards"][0]["kind"], GIFT_KIND_MID_AUTUMN)
        self.assertEqual(result["awards"][0]["label"], "中秋礼物")
        self.assertEqual(result["inventory"]["random"], 20)
        self.assertEqual(result["inventory"]["mid_autumn"], 4)

    def test_ordinary_day_consumes_random_inventory(self):
        settings = default_gift_settings()
        settings["special_gifts"] = []
        report = _gift_report(day="2026-09-30")
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[1],
        ):
            result = resolve_gift_awards(
                report,
                [_person()],
                empty_gift_history("Asia/Shanghai"),
                1,
                settings,
                {"random": 20},
            )
        self.assertEqual(result["awards"][0]["kind"], "random")
        self.assertEqual(result["awards"][0]["label"], "一盒随机口味哈根达斯（或一罐无糖可乐）")
        self.assertEqual(result["inventory"]["random"], 19)

    def test_persist_writes_inventory_into_delivery_history(self):
        with tempfile.TemporaryDirectory() as directory_name:
            root = Path(directory_name)
            gift_path = root / "gift.json"
            delivery_path = root / "delivery.json"
            data = {
                "gift_history": str(gift_path),
                "delivery_history": str(delivery_path),
            }
            config = {
                "xiangshan_monitor": {
                    "gifts": {
                        "special_gifts": [{
                            "id": "mid_autumn",
                            "name": "中秋礼物",
                            "start": "2026-09-20",
                            "end": "2026-09-24",
                            "per_day": 1,
                        }]
                    }
                }
            }
            report = _gift_report()
            result = {
                "date": "2026-09-21",
                "pity": True,
                "highlights": [],
                "awards": [{
                    "key": "email:alice@example.com",
                    "name": "Alice",
                    "email": "alice@example.com",
                    "kind": GIFT_KIND_MID_AUTUMN,
                    "special_id": "mid_autumn",
                }],
                "new_commits": [],
                "inventory": {"random": None, "mid_autumn": 4},
            }
            persist_gift_result(data, root, "Asia/Shanghai", result, report, config)
            persist_gift_result(data, root, "Asia/Shanghai", result, report, config)
            delivery = json.loads(delivery_path.read_text(encoding="utf-8"))
            self.assertEqual(delivery["gift_inventory"]["mid_autumn"]["remaining"], 4)
            self.assertNotIn("stock", delivery["gift_inventory"]["mid_autumn"])

    def test_three_highlights_without_a_win_trigger_pity(self):
        history = empty_gift_history("Asia/Shanghai")
        history["people"]["email:alice@example.com"] = {
            "name": "Alice",
            "email": "alice@example.com",
            "highlights_since_gift": 2,
            "wins": 0,
            "commits_since_gift": 1,
            "total_commits": 1,
            "last_gift_date": None,
        }
        report = _gift_report(day="2026-09-30")
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], history, 1)
        self.assertEqual(result["awards"][0]["kind"], GIFT_KIND_HIGHLIGHT_PITY)
        self.assertTrue(result["pity"])

    def test_fifty_commits_without_a_gift_trigger_pity(self):
        history = empty_gift_history("Asia/Shanghai")
        history["people"]["email:bob@example.com"] = {
            "name": "Bob",
            "email": "bob@example.com",
            "highlights_since_gift": 0,
            "wins": 0,
            "commits_since_gift": COMMIT_PITY_THRESHOLD - 1,
            "total_commits": COMMIT_PITY_THRESHOLD - 1,
            "last_gift_date": None,
        }
        report = _gift_report(
            day="2026-09-30",
            commits=[
                _commit("Alice", "alice@example.com", "1" * 40, "2026-09-30T10:00:00+08:00"),
                _commit("Bob", "bob@example.com", "2" * 40, "2026-09-30T11:00:00+08:00"),
            ],
        )
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], history, 1)
        kinds = {award["email"]: award["kind"] for award in result["awards"]}
        self.assertEqual(kinds["bob@example.com"], GIFT_KIND_COMMIT_PITY)
        self.assertTrue(result["pity"])

    def test_weekly_window_forces_one_gift_without_recent_win(self):
        history = empty_gift_history("Asia/Shanghai")
        history["days"] = [{
            "date": "2026-09-22",
            "pity": False,
            "highlights": [],
            "awards": [{"key": "email:old@example.com", "name": "Old", "kind": "random"}],
        }]
        report = _gift_report(day="2026-09-30", commits=[_commit("Alice", "alice@example.com", "1" * 40, "2026-09-30T10:00:00+08:00")])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], history, 1)
        self.assertEqual(result["awards"][0]["kind"], GIFT_KIND_WEEKLY_PITY)

    def test_weekly_window_stays_quiet_when_any_recent_win_exists(self):
        history = empty_gift_history("Asia/Shanghai")
        history["days"] = [{
            "date": "2026-09-24",
            "pity": False,
            "highlights": [],
            "awards": [{"key": "email:alice@example.com", "name": "Alice", "kind": "random"}],
        }]
        report = _gift_report(day="2026-09-30", commits=[_commit("Alice", "alice@example.com", "1" * 40, "2026-09-30T10:00:00+08:00")])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ):
            result = resolve_gift_awards(report, [_person()], history, 1)
        self.assertEqual(result["awards"], [])
        self.assertFalse(result["pity"])

    def test_weekly_window_stays_quiet_when_today_already_won(self):
        report = _gift_report(day="2026-09-30", commits=[_commit("Alice", "alice@example.com", "1" * 40, "2026-09-30T10:00:00+08:00")])
        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[1],
        ):
            result = resolve_gift_awards(report, [_person()], empty_gift_history("Asia/Shanghai"), 1)
        self.assertEqual([award["kind"] for award in result["awards"]], ["random"])
        self.assertFalse(result["pity"])

    def test_apply_gift_result_is_idempotent_and_resets_counters(self):
        history = empty_gift_history("Asia/Shanghai")
        report = _gift_report(commits=[_commit("Alice", "alice@example.com", "1" * 40)])
        result = {
            "date": "2026-09-21",
            "pity": True,
            "highlights": [_person()],
            "awards": [{"key": "email:alice@example.com", "name": "Alice", "email": "alice@example.com", "kind": GIFT_KIND_MID_AUTUMN, "label": "中秋礼物", "reason": "x", "slot": 1}],
            "new_commits": [{"token": "XiangShan:" + "1" * 40, "key": "email:alice@example.com", "name": "Alice", "email": "alice@example.com"}],
        }
        apply_gift_result(history, result, report)
        apply_gift_result(history, result, report)
        person = history["people"]["email:alice@example.com"]
        self.assertEqual(person["wins"], 1)
        self.assertEqual(person["commits_since_gift"], 0)
        self.assertEqual(person["highlights_since_gift"], 0)
        self.assertEqual(len(history["days"]), 1)
        self.assertEqual(len(history["counted_shas"]), 1)

    def test_talk_uses_structured_highlights_and_award_copy(self):
        report = _gift_report(commits=[_commit("Alice", "alice@example.com", "1" * 40)])
        config = {"xiangshan_monitor": {"api_url": "http://example.invalid/v1", "api_key": "x"}}
        data = {
            "highlight_count": 1,
            "prompt_file": str(Path("dingtalk_robot/xiangshan_monitor/prompt.txt").resolve()),
            "ai": {
                "model": "deepseek-flash",
                "wire_api": "chat_completions",
                "context_window_tokens": 100000,
                "max_output_tokens": 200,
                "max_api_calls": 4,
                "timeout_seconds": 1,
            },
        }
        calls = []

        def fake_api(prompt, api, opener, max_output_tokens=None):
            calls.append(prompt)
            if "中奖名单（不要增删改）" in prompt:
                return "恭喜 Alice 抽中中秋礼物！"
            return (
                "今天（9月21日）主线很稳。\n\n"
                "Alice，这提交写得漂亮。\n\n"
                "<<<xiangshan-highlights>>>\n"
                "1. Alice <alice@example.com>\n"
                "<<<xiangshan-highlights-end>>>"
            )

        with patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor.random_gift_slots",
            return_value=[],
        ), patch(
            "dingtalk_robot.xiangshan_monitor.xiangshan_monitor._call_local_api",
            side_effect=fake_api,
        ):
            message, result = talk(report, config, data, opener=object(), gift_history=empty_gift_history("Asia/Shanghai"))
        self.assertNotIn("<<<xiangshan-highlights>>>", message)
        self.assertIn("恭喜 Alice 抽中中秋礼物！", message)
        self.assertEqual(result["awards"][0]["kind"], GIFT_KIND_MID_AUTUMN)
        self.assertEqual(len(calls), 2)

    def test_fallback_award_text_names_people(self):
        text = format_gift_fallback({
            "awards": [{
                "kind": GIFT_KIND_MID_AUTUMN,
                "label": "中秋礼物",
                "name": "Alice",
                "reason": "中秋活动，今日保底一份",
            }]
        })
        self.assertIn("中秋礼物：Alice", text)


if __name__ == "__main__":
    unittest.main()
