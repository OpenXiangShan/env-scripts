import unittest
import urllib.request
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

from dingtalk_robot.robot import send_message, signed_webhook


class FakeResponse:
    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        return False

    def read(self):
        return b'{"errcode": 0, "errmsg": "ok"}'


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

    @patch("dingtalk_robot.robot.urllib.request.build_opener")
    def test_can_bypass_environment_proxies(self, build_opener):
        build_opener.return_value.open.return_value = FakeResponse()

        result = send_message(
            "https://example.test/robot/send?access_token=test-token",
            "SECtest",
            {"msgtype": "text", "text": {"content": "test"}},
            use_proxy=False,
        )

        self.assertEqual(result["errcode"], 0)
        proxy_handler = build_opener.call_args.args[0]
        self.assertIsInstance(proxy_handler, urllib.request.ProxyHandler)
        self.assertEqual(proxy_handler.proxies, {})

if __name__ == "__main__":
    unittest.main()
