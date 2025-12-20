from __future__ import annotations

import re
from typing import Any
from urllib.parse import quote, urljoin


def normalize_text(text: str) -> str:
    text = text.replace("\u00a0", " ").replace("\u200b", "")
    lines = [line.strip() for line in text.splitlines()]
    lines = [line for line in lines if line]
    return "\n".join(lines).strip()


def first_xpath(node: Any, xpath: str) -> Any | None:
    matches = node.xpath(xpath)
    if not matches:
        return None
    return matches[0]


def to_text(node: Any) -> str:
    if node is None:
        return ""
    if isinstance(node, str):
        return node
    if hasattr(node, "text_content"):
        return node.text_content()
    return str(node)


def get_title(a_el: Any, title_cfg: dict[str, Any] | None) -> str:
    title_cfg = title_cfg or {}
    attr_name = title_cfg.get("attr")
    if attr_name:
        val = a_el.get(attr_name)
        if val:
            return normalize_text(val)

    fallback = title_cfg.get("fallback", "text")
    if fallback == "text":
        return normalize_text(to_text(a_el))
    return normalize_text(str(a_el))


def build_link(a_el: Any, link_cfg: dict[str, Any], list_url: str) -> str | None:
    source = link_cfg.get("source")
    if source == "href":
        href = a_el.get("href")
        if not href:
            return None
        return urljoin(list_url, href)

    if source == "onclick_regex":
        onclick = a_el.get("onclick") or ""
        pattern = link_cfg.get("regex")
        template = link_cfg.get("template")
        if not pattern or not template:
            return None
        m = re.search(pattern, onclick)
        if not m:
            return None

        groups = m.groupdict()
        group_name = link_cfg.get("urlencode_group")
        if group_name and group_name in groups and groups[group_name] is not None:
            groups[group_name] = quote(groups[group_name], safe="")
        return template.format(**groups)

    if source == "href_or_onclick":
        return build_link(a_el, {"source": "href"}, list_url) or build_link(
            a_el,
            {k: v for k, v in link_cfg.items() if k != "source"} | {"source": "onclick_regex"},
            list_url,
        )

    return None

