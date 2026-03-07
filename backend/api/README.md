# UniFlow Backend API 文档

本文档描述了 UniFlow 后端（基于 FastAPI）面向前端和小程序提供的 RESTful 接口。

## 基础信息
- **本地默认请求根地址**: `http://127.0.0.1:8000`
- **自动交互式文档**: 服务启动后，可直接访问 `http://127.0.0.1:8000/docs` 使用 Swagger UI 调试所有接口。
- **跨域支持 (CORS)**: 接口已配置允许跨域(`Allow-Origins: *`)，前端开发阶段（如 `localhost:5173`) 可直接发起 AJAX 请求，无需配置额外代理。

---

## 接口详情

### 1. 获取通知列表 (分页查询)
根据指定的参数查询校园事件库，支持按分类、信源过滤，支持多种维度的复合排序。

**接口地址**: `GET /api/events`

**Query 参数 (均可选)**:
| 参数名 | 类型 | 默认值 | 约束 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `page` | `init` | `1` | `>= 1` | 当前请求的页码 |
| `limit` | `int` | `20` | `1 ~ 100` | 每页返回的数据条数 |
| `genre` | `string` | - | - | 通知分类，如 "学术讲座" / "校园活动" / "竞赛" |
| `channel` | `string` | - | - | 数据源渠道过滤，如 "dean.xjtu.edu.cn" |
| `days_ago` | `int` | - | `>= 0` | 筛选过去 N 天内发生的事件数据 |
| `sort_by` | `string` | `fetch_time` | 见下方枚举 | 结果的排序方式 |

**`sort_by` 字段支持的枚举值**:
- `fetch_time`: 按最新抓取/发布时间倒序排（最新鲜在最前）
- `importance`: 纯按 AI 判定的重要度倒序排（10分最高在最前）
- `importance_time`: 复合排序，先以重要度为主排序，同一重要度级别下按抓取时间倒序合并。
- `trending` (推荐): **时间衰减算法**。Score = Importance / (HoursAgo + 2)^1.5，让重要度高的新鲜事排在最前面，但随着时间推移分数平滑衰减，即使重要度再高，过了很久也会为新事件让路。

**返回结构示例**:
```json
{
  "success": true,
  "data": {
    "page": 1,
    "limit": 30,
    "total": 356,           // 满足条件的总条数
    "total_pages": 18,      // 总页数
    "items": [
      {
        "uuid": "8f38c352-32a2-4a0b-9df0-7d0e12b21c43",
        "channel": "dean.xjtu.edu.cn",
        "title": "关于退课名单的通知",
        "genre": "教务",
        "importance": 10,
        "review": "直接关联学期课表和个人情况的重要教务操作",
        "fetch_time": "2026-03-01T21:40:02.134Z"
      }
      // ... 更多 items
    ]
  }
}
```

---

### 2. 获取单条事件详细信息
通常通过列表页点击跳转后，使用获取到的 `uuid` 请求该接口来展示一篇文章的全貌（包括大模型梳理的 timeline 和原始长文本内容）。

**接口地址**: `GET /api/events/{event_id}`

**Path 路径参数**:
| 参数名 | 类型 | 必填 | 说明 |
| :--- | :--- | :--- | :--- |
| `event_id` | `string` | 是 | 从列表接口获取到的该事件的唯一 UUID |

**返回结构示例**:
```json
{
  "success": true,
  "data": {
    "uuid": "8f38c352-32a2-4a0b-9df0-7d0e12b21c43",
    "channel": "dean.xjtu.edu.cn",
    "title": "关于组织参加第十八届全国大学生机器人竞赛的通知",
    "genre": "竞赛",
    "importance": 7,
    "review": "理工科本科及研究生重要级别赛事",
    "link": "https://dean.xjtu.edu.cn/info/1175/9655.htm",
    "timeline": [
      {
        "time": "2026-04-05",
        "event": "校内选拔报名截止时间"
      },
      {
        "time": "2026-04-15",
        "event": "初赛评选"
      }
    ],
    "original_text": "此处是抓取阶段保留的页面脱水纯净原文字符串...",
    "fetch_time": "2026-03-01T21:40:02.134Z"
  }
}
```

*注意：如果该 `uuid` 在数据库中不存在，接口会返回 `HTTP 404` (Event not found) 错误。*
