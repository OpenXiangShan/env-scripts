import unittest
from datetime import datetime, timezone

from dingtalk_robot.oss_stats.period import resolve_period


class ReportingPeriodTest(unittest.TestCase):
    def test_default_is_previous_calendar_month(self):
        period = resolve_period(
            "Asia/Shanghai", now=datetime(2026, 9, 4, tzinfo=timezone.utc)
        )
        self.assertEqual(period.label, "2026-08")
        self.assertEqual(period.start.isoformat(), "2026-07-31T16:00:00+00:00")
        self.assertEqual(period.end.isoformat(), "2026-08-31T16:00:00+00:00")

    def test_month_override(self):
        period = resolve_period("UTC", month="2026-07")
        self.assertEqual(period.start.isoformat(), "2026-07-01T00:00:00+00:00")
        self.assertEqual(period.end.isoformat(), "2026-08-01T00:00:00+00:00")

    def test_custom_range_requires_both_boundaries(self):
        with self.assertRaisesRegex(ValueError, "specified together"):
            resolve_period("UTC", start="2026-08-01")


if __name__ == "__main__":
    unittest.main()
