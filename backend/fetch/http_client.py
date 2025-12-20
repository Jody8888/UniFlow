from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Any

import requests


DEFAULT_HEADERS: dict[str, str] = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.7",
}


@dataclass(frozen=True)
class RetryPolicy:
    max_attempts: int = 5
    sleep_step_seconds: float = 10.0


class RetryingHttpClient:
    def __init__(
        self,
        *,
        timeout_seconds: float = 20.0,
        retry_policy: RetryPolicy | None = None,
        headers: dict[str, str] | None = None,
        session: requests.Session | None = None,
    ) -> None:
        self._timeout_seconds = timeout_seconds
        self._retry_policy = retry_policy or RetryPolicy()
        self._session = session or requests.Session()
        self._session.headers.update(DEFAULT_HEADERS)
        if headers:
            self._session.headers.update(headers)

    def get(self, url: str, *, debug: list[str] | None = None, **kwargs: Any) -> requests.Response:
        debug = debug if debug is not None else []
        last_exc: Exception | None = None

        for attempt in range(1, self._retry_policy.max_attempts + 1):
            if attempt > 1:
                sleep_s = self._retry_policy.sleep_step_seconds * (attempt - 1)
                debug.append(f"http retry sleep={sleep_s:.0f}s url={url}")
                time.sleep(sleep_s)

            try:
                debug.append(f"http GET attempt={attempt}/{self._retry_policy.max_attempts} url={url}")
                resp = self._session.get(url, timeout=self._timeout_seconds, **kwargs)
                debug.append(f"http status={resp.status_code} url={url}")
                resp.raise_for_status()
                return resp
            except Exception as exc:  # noqa: BLE001
                last_exc = exc
                debug.append(f"http error attempt={attempt} url={url} exc={type(exc).__name__}: {exc}")

        raise RuntimeError(f"GET failed after {self._retry_policy.max_attempts} attempts: {url}") from last_exc

