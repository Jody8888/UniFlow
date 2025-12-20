from __future__ import annotations

import os
import traceback
from typing import Any

try:
    from lxml import html as lxml_html
except ModuleNotFoundError as exc:  # pragma: no cover
    raise RuntimeError(
        "Missing dependency 'lxml'.\n"
        "Recommended setup:\n"
        "  conda create -n uniflow -y python=3.11\n"
        "  conda install -n uniflow -y lxml requests\n"
    ) from exc

from .config import load_config, validate_config
from .http_client import RetryingHttpClient, RetryPolicy
from .parser import build_link, first_xpath, get_title, normalize_text, to_text


class AnnouncementFetcher:
    def __init__(
        self,
        *,
        timeout_seconds: float = 20.0,
        retry_policy: RetryPolicy | None = None,
        headers: dict[str, str] | None = None,
    ) -> None:
        self._client = RetryingHttpClient(
            timeout_seconds=timeout_seconds,
            retry_policy=retry_policy or RetryPolicy(max_attempts=5, sleep_step_seconds=10.0),
            headers=headers,
        )

    def fetch(self, config_path: str, *, max_items: int | None = None) -> dict[str, Any]:
        debug: list[str] = []
        cfg: dict[str, Any]

        try:
            cfg = load_config(config_path)
            validate_config(cfg)
        except Exception as exc:  # noqa: BLE001
            return {
                "channel": os.path.splitext(os.path.basename(config_path))[0],
                "status": "ERROR",
                "debug_info": f"config error: {type(exc).__name__}: {exc}\n{traceback.format_exc()}",
                "titles": [],
                "links": [],
                "contents": [],
            }

        channel = cfg.get("channel") or os.path.splitext(os.path.basename(config_path))[0]
        try:
            result = _fetch_from_config(cfg, self._client, debug=debug, max_items=max_items)
            result["status"] = "SUCCESS"
            result["debug_info"] = "\n".join(debug).strip()
            return result
        except Exception as exc:  # noqa: BLE001
            debug.append(f"fatal error: {type(exc).__name__}: {exc}")
            debug.append(traceback.format_exc())
            return {
                "channel": channel,
                "status": "ERROR",
                "debug_info": "\n".join(debug).strip(),
                "titles": [],
                "links": [],
                "contents": [],
            }


def fetch_once(config_path: str, *, max_items: int | None = None) -> dict[str, Any]:
    return AnnouncementFetcher().fetch(config_path, max_items=max_items)


def _fetch_from_config(
    cfg: dict[str, Any],
    client: RetryingHttpClient,
    *,
    debug: list[str],
    max_items: int | None,
) -> dict[str, Any]:
    channel = cfg.get("channel") or "unknown"
    list_cfg = cfg["list"]
    detail_cfg = cfg["detail"]

    list_url: str = list_cfg["url"]
    container_xpath: str = list_cfg["container_xpath"]
    item_xpath: str = list_cfg.get("item_xpath", ".//a")
    title_cfg: dict[str, Any] | None = list_cfg.get("title")
    link_cfg: dict[str, Any] = list_cfg["link"]

    content_xpath: str = detail_cfg["content_xpath"]
    content_type: str = detail_cfg.get("content_type", "text")

    limit_cfg = cfg.get("limits", {}) if isinstance(cfg.get("limits", {}), dict) else {}
    resolved_max_items = max_items if max_items is not None else int(limit_cfg.get("max_items", 20))

    debug.append(f"[{channel}] list url={list_url}")
    list_resp = client.get(list_url, debug=debug)
    list_tree = lxml_html.fromstring(list_resp.content)

    container = first_xpath(list_tree, container_xpath)
    if container is None:
        raise ValueError(f"[{channel}] container_xpath matched nothing: {container_xpath}")

    a_tags: list[Any] = list(container.xpath(item_xpath))
    debug.append(f"[{channel}] list items candidates={len(a_tags)}")

    titles: list[str] = []
    links: list[str] = []
    contents: list[str] = []

    for a_el in a_tags:
        if len(links) >= resolved_max_items:
            break

        title = get_title(a_el, title_cfg)
        link = build_link(a_el, link_cfg, list_url)
        if not title or not link:
            continue

        titles.append(title)
        links.append(link)

    if not links:
        raise ValueError(f"[{channel}] extracted 0 items (check item_xpath/title/link config)")

    debug.append(f"[{channel}] extracted items={len(links)}")

    for idx, link in enumerate(links, start=1):
        debug.append(f"[{channel}] detail {idx}/{len(links)} url={link}")
        try:
            detail_resp = client.get(link, debug=debug)
            detail_tree = lxml_html.fromstring(detail_resp.content)
            nodes = detail_tree.xpath(content_xpath)
            if not nodes:
                debug.append(f"[{channel}] detail xpath matched 0 nodes: {content_xpath} url={link}")
                contents.append("")
                continue

            if content_type == "html":
                from lxml import html as _html  # local import

                html_chunks = [
                    _html.tostring(n, encoding="unicode", method="html") for n in nodes if n is not None
                ]
                contents.append("\n".join(html_chunks).strip())
            else:
                text = "\n".join(to_text(n) for n in nodes)
                contents.append(normalize_text(text))
        except Exception as exc:  # noqa: BLE001
            debug.append(f"[{channel}] detail error url={link} exc={type(exc).__name__}: {exc}")
            contents.append("")

    return {"channel": channel, "titles": titles, "links": links, "contents": contents}
