"""Small GitHub REST and GraphQL client for public organization data."""

from __future__ import annotations

import json
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple


class GitHubError(RuntimeError):
    """Raised when GitHub data cannot be fetched."""

    def __init__(self, message: str, status: Optional[int] = None) -> None:
        super().__init__(message)
        self.status = status


class GitHubClient:
    def __init__(
        self,
        token: str = "",
        api_url: str = "https://api.github.com",
        api_version: str = "2026-03-10",
        proxy: str = "",
        timeout: float = 30,
    ) -> None:
        self.token = token.strip()
        self.api_url = api_url.rstrip("/")
        self.api_version = api_version
        self.timeout = timeout
        self.rate_limit: Dict[str, Any] = {}
        self.opener = (
            urllib.request.build_opener(
                urllib.request.ProxyHandler({"http": proxy, "https": proxy})
            )
            if proxy
            else urllib.request.build_opener()
        )

    @property
    def authenticated(self) -> bool:
        return bool(self.token)

    def get(
        self, path: str, params: Optional[Dict[str, Any]] = None
    ) -> Tuple[Any, Dict[str, str]]:
        data, headers, _ = self.get_with_status(path, params)
        return data, headers

    def get_with_status(
        self, path: str, params: Optional[Dict[str, Any]] = None
    ) -> Tuple[Any, Dict[str, str], int]:
        query = urllib.parse.urlencode(params or {})
        url = f"{self.api_url}/{path.lstrip('/')}"
        if query:
            url = f"{url}?{query}"
        headers = {
            "Accept": "application/vnd.github+json",
            "User-Agent": "OpenXiangShan-oss-stats",
            "X-GitHub-Api-Version": self.api_version,
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"

        request = urllib.request.Request(url, headers=headers)
        try:
            with self.opener.open(request, timeout=self.timeout) as response:
                response_headers = {key.lower(): value for key, value in response.headers.items()}
                self._remember_rate_limit(response_headers)
                body = response.read()
                data = json.loads(body.decode("utf-8")) if body else None
                return data, response_headers, response.status
        except urllib.error.HTTPError as exc:
            response_headers = {key.lower(): value for key, value in exc.headers.items()}
            self._remember_rate_limit(response_headers)
            detail = exc.read().decode("utf-8", errors="replace")
            try:
                message = json.loads(detail).get("message", detail)
            except json.JSONDecodeError:
                message = detail
            reset = self.rate_limit.get("reset_at")
            suffix = f"; rate limit resets at {reset}" if reset else ""
            raise GitHubError(
                f"GitHub HTTP error {exc.code}: {message}{suffix}", status=exc.code
            ) from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            reason = getattr(exc, "reason", str(exc))
            raise GitHubError(f"Cannot connect to GitHub: {reason}") from exc
        except json.JSONDecodeError as exc:
            raise GitHubError("GitHub returned invalid JSON") from exc

    def graphql(self, query: str, variables: Dict[str, Any]) -> Dict[str, Any]:
        if not self.token:
            raise GitHubError("GitHub GraphQL requests require github.token or token_file")
        request = urllib.request.Request(
            f"{self.api_url}/graphql",
            data=json.dumps({"query": query, "variables": variables}).encode("utf-8"),
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json; charset=utf-8",
                "User-Agent": "OpenXiangShan-oss-stats",
            },
            method="POST",
        )
        try:
            with self.opener.open(request, timeout=self.timeout) as response:
                result = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            try:
                message = json.loads(detail).get("message", detail)
            except json.JSONDecodeError:
                message = detail
            raise GitHubError(
                f"GitHub GraphQL HTTP error {exc.code}: {message}", status=exc.code
            ) from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            reason = getattr(exc, "reason", str(exc))
            raise GitHubError(f"Cannot connect to GitHub GraphQL: {reason}") from exc
        except json.JSONDecodeError as exc:
            raise GitHubError("GitHub GraphQL returned invalid JSON") from exc

        errors = result.get("errors") or []
        if errors:
            messages = "; ".join(str(item.get("message", item)) for item in errors)
            raise GitHubError(f"GitHub GraphQL error: {messages}")
        data = result.get("data")
        if not isinstance(data, dict):
            raise GitHubError("GitHub GraphQL response has no data object")
        rate = data.get("rateLimit")
        if isinstance(rate, dict):
            self.rate_limit = {
                "limit": rate.get("limit"),
                "remaining": rate.get("remaining"),
                "used": rate.get("used"),
                "cost": rate.get("cost"),
                "resource": "graphql",
                "reset_at": rate.get("resetAt"),
            }
        return data

    def paginate(
        self,
        path: str,
        params: Optional[Dict[str, Any]] = None,
        max_items: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        items: List[Dict[str, Any]] = []
        page = 1
        while True:
            page_params = dict(params or {})
            page_params.update({"per_page": 100, "page": page})
            data, _ = self.get(path, page_params)
            if not isinstance(data, list):
                raise GitHubError(f"Expected a list from GitHub endpoint: {path}")
            items.extend(item for item in data if isinstance(item, dict))
            if max_items is not None and len(items) >= max_items:
                return items[:max_items]
            if len(data) < 100:
                return items
            page += 1

    def _remember_rate_limit(self, headers: Dict[str, str]) -> None:
        if "x-ratelimit-limit" not in headers:
            return
        reset = int(headers.get("x-ratelimit-reset", "0"))
        self.rate_limit = {
            "limit": int(headers["x-ratelimit-limit"]),
            "remaining": int(headers.get("x-ratelimit-remaining", "0")),
            "used": int(headers.get("x-ratelimit-used", "0")),
            "resource": headers.get("x-ratelimit-resource", "core"),
            "reset_at": datetime.fromtimestamp(reset, timezone.utc).isoformat()
            if reset
            else None,
        }
