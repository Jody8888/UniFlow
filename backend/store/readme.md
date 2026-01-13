# 存储消息的数据库
使用Postgres
## 数据库：uniflow
### 表：events
| 键名 | 描述 | 数据类型 | 非空 | 备注 |
| --- | --- | --- | --- | --- |
| uuid | 事件的uuid | uuid | NOT NULL | PRIMARY KEY |
| channel | 抓取渠道 | VARCHAR | NOT NULL |  |
| fetch_time | 抓取时间 | TIMESTAMP | NOT NULL |  |
| title | 事件标题 | VARCHAR | NOT NULL |  |
| genre | 事件类型 | VARCHAR | NOT NULL |  |
| timeline | 时间线 | JSONB | NOT NULL |  |
| original_text | 原文 | TEXT |  |  |