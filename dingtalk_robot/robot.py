"""Low-level helpers for signed DingTalk custom-robot messages."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict, Optional


class DingTalkError(RuntimeError):
    """Raised when a DingTalk message cannot be delivered."""


def signed_webhook(webhook: str, secret: str, timestamp: Optional[int] = None) -> str:
    """Return a webhook URL with DingTalk's timestamp and HMAC-SHA256 signature."""
    timestamp = timestamp if timestamp is not None else int(time.time() * 1000)
    string_to_sign = f"{timestamp}\n{secret}".encode("utf-8")
    digest = hmac.new(secret.encode("utf-8"), string_to_sign, hashlib.sha256).digest()
    sign = base64.b64encode(digest).decode("ascii")

    parsed = urllib.parse.urlsplit(webhook)
    query = urllib.parse.parse_qsl(parsed.query, keep_blank_values=True)
    query = [(key, value) for key, value in query if key not in {"timestamp", "sign"}]
    query.extend((("timestamp", str(timestamp)), ("sign", sign)))
    return urllib.parse.urlunsplit(parsed._replace(query=urllib.parse.urlencode(query)))


def send_message(
    webhook: str,
    secret: str,
    payload: Dict[str, Any],
    timeout: float = 15,
) -> Dict[str, Any]:
    """Send a raw DingTalk robot payload and validate the API response."""
    request = urllib.request.Request(
        signed_webhook(webhook, secret),
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise DingTalkError(f"DingTalk HTTP error {exc.code}: {detail}") from exc
    except (urllib.error.URLError, TimeoutError) as exc:
        reason = getattr(exc, "reason", str(exc))
        raise DingTalkError(f"Cannot connect to DingTalk: {reason}") from exc
    except json.JSONDecodeError as exc:
        raise DingTalkError("DingTalk returned invalid JSON") from exc

    if not isinstance(result, dict):
        raise DingTalkError("DingTalk returned an unexpected JSON value")
    if result.get("errcode") != 0:
        raise DingTalkError(
            "DingTalk rejected the message: "
            f"errcode={result.get('errcode')}, errmsg={result.get('errmsg')}"
        )
    return result


def send_text(
    webhook: str, secret: str, content: str, timeout: float = 15
) -> Dict[str, Any]:
    return send_message(
        webhook,
        secret,
        {"msgtype": "text", "text": {"content": content}},
        timeout,
    )


def send_markdown(
    webhook: str,
    secret: str,
    title: str,
    content: str,
    timeout: float = 15,
) -> Dict[str, Any]:
    return send_message(
        webhook,
        secret,
        {"msgtype": "markdown", "markdown": {"title": title, "text": content}},
        timeout,
    )
