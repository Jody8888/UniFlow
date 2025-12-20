# UniFlow Fetch 模块

该目录提供“公告抓取(fetch)”的独立模块：通过 **每个站点一个 JSON 配置文件** 来驱动抓取逻辑，避免为新增/修改站点频繁改代码。

## 目录结构

- `config_json/`：站点配置（每个网站一个 `*.json`）
- `fetcher.py`：核心抓取器（面向对象）
- `http_client.py`：HTTP + 重试策略
- `parser.py`：XPath/文本/链接解析工具
- `main.py`：仅用于开发调试的单配置运行入口（非业务集成方式）

## 返回数据结构

抓取器返回一个字典（Python `dict`），包含：

- `channel`：抓取渠道（建议与配置文件名一致，如 `oa.xjtu.edu.cn`）
- `status`：`SUCCESS` 或 `ERROR`
- `debug_info`：详细日志（包含请求、重试、解析异常等）
- `titles`：所有通告标题（`list[str]`）
- `links`：所有通告全文链接（`list[str]`）
- `contents`：所有通告全文内容（`list[str]`，若某条详情页失败则为空字符串）

## 重试机制

所有 HTTP GET 请求默认最多重试 **5 次**：

- 第 1 次：立即请求
- 第 2~5 次：分别 sleep `10s/20s/30s/40s` 后重试

全部关键步骤失败（例如：列表页抓取失败、XPath 匹配不到容器、提取到 0 条公告）会返回 `status=ERROR`，并在 `debug_info` 中记录异常栈与上下文。

## JSON 配置格式

每个站点一个 JSON 文件（建议命名 `<domain>.json`），最小结构如下：

```json
{
  "channel": "example.com",
  "list": {
    "url": "https://example.com/list",
    "container_xpath": "/html/body/...",
    "item_xpath": ".//a[@href]",
    "title": { "attr": "title", "fallback": "text" },
    "link": { "source": "href" }
  },
  "detail": {
    "content_xpath": "/html/body/...",
    "content_type": "text"
  },
  "limits": {
    "max_items": 20
  }
}
```

### 字段说明

- `channel`：渠道标识；若缺省，默认取配置文件名（不含 `.json`）
- `list.url`：列表页 URL
- `list.container_xpath`：用于定位“公告列表区域”的 XPath（后续 `item_xpath` 在该节点下执行）
- `list.item_xpath`：在 container 下筛选公告链接的 XPath（默认 `.//a`）
- `list.title`：标题提取方式
  - `attr`：优先从指定属性取标题（如 `title`）
  - `fallback`：当 `attr` 为空时的回退策略，当前支持 `text`
- `list.link`：链接提取方式
  - `source: "href"`：从 `a@href` 取值并自动 `urljoin(list.url, href)`
  - `source: "onclick_regex"`：用正则从 `a@onclick` 抽取字段，并通过 `template` 拼接
    - `regex`：例如 `gotodetail\\('(?P<id>[^']+)'\\)`
    - `template`：例如 `https://oa.xjtu.edu.cn/zxgg_infonew.jsp?processInsId={id}`
    - `urlencode_group`：可选，指定要进行 URL 编码的 group 名（如 `id`）
- `detail.content_xpath`：详情页正文区域 XPath
- `detail.content_type`：`text` 或 `html`（默认 `text`）
- `limits.max_items`：最多抓取多少条公告（默认 20）；业务集成时建议由上层控制

## 如何在代码中调用（推荐）

由于本模块位于 `backend/fetch` 目录，建议将 `D:\UniFlow\backend` 加入 `PYTHONPATH` 后再导入：

```python
import os
import sys

sys.path.insert(0, r"D:\UniFlow\backend")

from fetch.fetcher import AnnouncementFetcher

fetcher = AnnouncementFetcher()
result = fetcher.fetch(r"D:\UniFlow\backend\fetch\config_json\oa.xjtu.edu.cn.json", max_items=20)
```

`result` 即为上述“返回数据结构”中的字典。

## 开发调试运行（不建议作为业务集成方式）

```powershell
$py = "$env:USERPROFILE\\.conda\\envs\\uniflow\\python.exe"
& $py backend\\fetch\\main.py --config backend\\fetch\\config_json\\oa.xjtu.edu.cn.json --max-items 5
```

