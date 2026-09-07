import unittest
from urllib.parse import parse_qs, urlsplit

from dingtalk_robot.robot import signed_webhook


class SignedWebhookTest(unittest.TestCase):
    def test_known_signature(self):
        url = signed_webhook(
            "https://example.test/robot/send?access_token=test-token",
            "SECtest",
            1700000000000,
        )
        query = parse_qs(urlsplit(url).query)
        self.assertEqual(query["access_token"], ["test-token"])
        self.assertEqual(query["timestamp"], ["1700000000000"])
        self.assertEqual(
            query["sign"], ["aZLLrriXgn05YbwaGR7knYsLeJADjr9NwLaNNKpxh4g="]
        )

if __name__ == "__main__":
    unittest.main()
