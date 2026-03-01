"""
api_fetcher.py  —  独立的 JSON API 数据源抓取模块

处理无法用 HTML + XPath 抓取的数据源：
  1. ss.xjtu.edu.cn   —  全校活动列表（JSON API）
  2. tuanwei.xjtu.edu.cn  —  团委通知公告 & 活动预告（Nuxt SSR 页面解析）
"""
from __future__ import annotations

import re
import traceback
from typing import Any
from datetime import datetime

import requests

# ──────────────────────────────────────────────────────────
# 公共工具
# ──────────────────────────────────────────────────────────
_SESSION = requests.Session()
_SESSION.headers.update({
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    ),
})
_TIMEOUT = 20


def _get(url: str, **kwargs: Any) -> requests.Response:
    """带基本重试的 GET 请求"""
    for attempt in range(1, 4):
        try:
            resp = _SESSION.get(url, timeout=_TIMEOUT, **kwargs)
            resp.raise_for_status()
            return resp
        except Exception:
            if attempt == 3:
                raise
    raise RuntimeError("unreachable")


def _make_result(
    channel: str,
    titles: list[str],
    links: list[str],
    contents: list[str],
    debug: list[str],
    status: str = "SUCCESS",
) -> dict[str, Any]:
    return {
        "channel": channel,
        "status": status,
        "debug_info": "\n".join(debug).strip(),
        "titles": titles,
        "links": links,
        "contents": contents,
    }


def _error_result(channel: str, exc: Exception, debug: list[str]) -> dict[str, Any]:
    debug.append(f"fatal: {type(exc).__name__}: {exc}")
    debug.append(traceback.format_exc())
    return _make_result(channel, [], [], [], debug, status="ERROR")


# ──────────────────────────────────────────────────────────
#  1. ss.xjtu.edu.cn  —  全校活动列表
# ──────────────────────────────────────────────────────────
_SS_API_URL = (
    "https://ss.xjtu.edu.cn/xsfw/sys/swmsyxsfzapp/"
    "ykHdController/getActivityList.do"
)


def _fetch_ss(max_items: int = 50) -> dict[str, Any]:
    """
    从 ss.xjtu.edu.cn 抓取校级活动列表。
    API 返回全量数据，我们按开始时间倒序取前 max_items 条。
    """
    channel = "ss.xjtu.edu.cn"
    debug: list[str] = [f"[{channel}] fetching activity list"]

    try:
        resp = _get(_SS_API_URL)
        data = resp.json()

        if str(data.get("code")) != "0":
            raise ValueError(f"API error: {data.get('msg', 'unknown')}")

        items: list[dict] = data.get("data", [])
        debug.append(f"[{channel}] total activities from API: {len(items)}")

        # 按开始时间倒序
        def _sort_key(item: dict) -> str:
            return item.get("HDKSSJ", "") or item.get("CZRQ", "") or ""

        items.sort(key=_sort_key, reverse=True)
        items = items[:max_items]

        titles: list[str] = []
        links: list[str] = []
        contents: list[str] = []

        for it in items:
            title = it.get("HDMC", "").strip()
            if not title:
                continue

            titles.append(title)
            links.append("")  # 活动无独立页面链接

            # 组装内容文本，供下游 LLM 处理
            parts = [
                f"活动名称：{title}",
                f"所属部门：{it.get('SSBM_DISPLAY', '')}",
                f"活动类型：{it.get('HDLX_DISPLAY', '')}",
                f"活动时间：{it.get('HDRQ', '')}",
                f"活动状态：{'进行中' if it.get('HDZT') == 'JXZ' else '已结束'}",
                f"素养能力：{it.get('SYNLDM_DISPLAY', '')}",
                f"参与人数：{it.get('CYRS', '')}",
                f"活动形式：{it.get('HDXS_DISPLAY', '')}",
                f"活动学分：{it.get('HDZF', '')}",
            ]
            contents.append("\n".join(p for p in parts if not p.endswith("：")))

        debug.append(f"[{channel}] extracted {len(titles)} items")
        return _make_result(channel, titles, links, contents, debug)

    except Exception as exc:
        return _error_result(channel, exc, debug)


# ──────────────────────────────────────────────────────────
#  2. tuanwei.xjtu.edu.cn  —  团委通知公告 / 活动预告（JSON API）
# ──────────────────────────────────────────────────────────
_TW_CATALOGS = [
    {"id": 9,  "name": "通知公告", "channel": "tuanwei.xjtu.edu.cn.tzgg"},
    {"id": 15, "name": "活动预告", "channel": "tuanwei.xjtu.edu.cn.hdyg"},
]
_TW_BASE = "https://tuanwei.xjtu.edu.cn"
_TW_LIST_API = f"{_TW_BASE}/api/v1/secondCatalog"
_TW_DETAIL_API = f"{_TW_BASE}/api/v1/article"


def _strip_html(html_str: str) -> str:
    """简单去除 HTML 标签，提取纯文本"""
    text = re.sub(r"<[^>]+>", "", html_str)
    text = re.sub(r"&nbsp;", " ", text)
    text = re.sub(r"&[a-z]+;", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _fetch_tuanwei_catalog(
    catalog_id: int,
    catalog_name: str,
    channel: str,
    max_items: int = 20,
) -> dict[str, Any]:
    """
    使用团委 JSON API 抓取文章列表和详情。
    列表: GET /api/v1/secondCatalog?catalogId=X&page=1&limit=N
    详情: GET /api/v1/article?articleId=NNN
    """
    debug: list[str] = [f"[{channel}] catalog={catalog_name} id={catalog_id}"]

    try:
        # ---- 1. 获取文章列表 ----
        list_url = f"{_TW_LIST_API}?catalogId={catalog_id}&page=1&limit={max_items}"
        debug.append(f"[{channel}] list api={list_url}")
        list_resp = _get(list_url)
        list_data = list_resp.json()

        if not list_data.get("success"):
            raise ValueError(f"API error: {list_data}")

        articles = list_data.get("data", {}).get("data", [])
        total = list_data.get("data", {}).get("total", 0)
        debug.append(f"[{channel}] total={total}, fetched={len(articles)}")

        titles: list[str] = []
        links: list[str] = []
        contents: list[str] = []

        # ---- 2. 逐篇获取文章详情 ----
        for art in articles:
            article_id = art.get("articleId")
            headline = art.get("headline", "").strip()
            if not article_id or not headline:
                continue

            titles.append(headline)
            links.append(f"{_TW_BASE}/passage?id={article_id}")

            try:
                detail_url = f"{_TW_DETAIL_API}?articleId={article_id}"
                debug.append(f"[{channel}] detail api articleId={article_id}")
                detail_resp = _get(detail_url)
                detail_data = detail_resp.json()

                if not detail_data.get("success"):
                    debug.append(f"[{channel}] detail api failed for {article_id}")
                    contents.append("")
                    continue

                d = detail_data.get("data", {})
                raw_content = d.get("content", "")
                plain_text = _strip_html(raw_content)

                # 组装：标题 + 来源 + 日期 + 正文
                parts = [
                    f"标题：{d.get('headline', headline)}",
                    f"来源：{d.get('source', '')}",
                    f"日期：{d.get('publish', '')}",
                    f"正文：{plain_text}",
                ]
                contents.append("\n".join(p for p in parts if not p.endswith("：")))

            except Exception as exc:
                debug.append(f"[{channel}] detail error id={article_id} exc={exc}")
                contents.append("")

        debug.append(f"[{channel}] extracted {len(titles)} items")
        return _make_result(channel, titles, links, contents, debug)

    except Exception as exc:
        return _error_result(channel, exc, debug)


def _fetch_tuanwei(max_items: int = 20) -> list[dict[str, Any]]:
    """抓取团委全部 catalog（通知公告 + 活动预告），返回结果列表"""
    results = []
    for cat in _TW_CATALOGS:
        results.append(
            _fetch_tuanwei_catalog(
                catalog_id=cat["id"],
                catalog_name=cat["name"],
                channel=cat["channel"],
                max_items=max_items,
            )
        )
    return results


# ──────────────────────────────────────────────────────────
#  统一入口
# ──────────────────────────────────────────────────────────
def fetch_api_sources() -> list[dict[str, Any]]:
    """
    抓取所有 API 类数据源，返回结果列表。
    每个元素格式与 AnnouncementFetcher.fetch() 的返回值一致：
    {channel, status, debug_info, titles, links, contents}
    """
    results: list[dict[str, Any]] = []

    # ss.xjtu.edu.cn
    results.append(_fetch_ss(max_items=50))

    # tuanwei.xjtu.edu.cn（两个 catalog）
    results.extend(_fetch_tuanwei(max_items=20))

    return results


# ──────────────────────────────────────────────────────────
#  单独运行测试
# ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    import sys
    sys.stdout = open(sys.stdout.fileno(), mode="w", encoding="utf-8", buffering=1)

    print("=" * 60)
    print("API Fetcher 测试运行")
    print("=" * 60)

    all_results = fetch_api_sources()

    for r in all_results:
        print(f"\n{'─' * 40}")
        print(f"Channel:  {r['channel']}")
        print(f"Status:   {r['status']}")
        print(f"Items:    {len(r['titles'])}")

        if r["status"] != "SUCCESS":
            print(f"Error:\n{r['debug_info']}")
            continue

        for i, (t, l, c) in enumerate(zip(r["titles"], r["links"], r["contents"])):
            if i >= 3:
                print(f"  ... ({len(r['titles']) - 3} more)")
                break
            print(f"  [{i+1}] {t[:60]}")
            if l:
                print(f"       link: {l}")
            print(f"       content: {c[:80]}..." if len(c) > 80 else f"       content: {c}")

    print(f"\n{'=' * 60}")
    print("完成")
