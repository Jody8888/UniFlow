import os
import sys
import json
import time
import uuid
import glob
from pathlib import Path
import psycopg2
import requests
from datetime import datetime
from collections import deque
from psycopg2.extras import RealDictCursor

# 路径配置
STORE_DIR = Path(__file__).resolve().parent
BACKEND_DIR = STORE_DIR.parent
FETCH_DIR = BACKEND_DIR / "fetch"
CONFIG_DIR = FETCH_DIR / "config_json"

sys.path.insert(0, str(BACKEND_DIR))

#QWEN2.5-7B-Instruct API(Slicon Flow)
QWEN_API_URL = "https://api.siliconflow.cn/v1/chat/completions"
QWEN_API_KEY = "sk-jtqjtcosjdnwqsyuqpsdxpfsierzlejkwtldfyhasomsirpx"
QWEN_MODEL = "Qwen/Qwen2.5-7B-Instruct"


MAX_RPM = 1000
MAX_TPM = 50000
WINDOW = 60

#PostgreSQL
PG_CONFIG = {
    "host": "127.0.0.1",
    "port": 5432,
    "user": "test",
    "password": "passwd",
    "dbname": "uniflow"
}

#System Prompt
SYSTEM_PROMPT = SYSTEM_PROMPT = """
# 角色定位
你是西安交通大学校园通知专属结构化解析助手，仅输出符合要求的合法JSON，无任何额外内容。

---
## 【最高优先级】核心输出铁则
1.  **仅返回纯JSON文本**：绝对禁止任何前置解释、后置说明、markdown代码块、```json包裹、注释、多余换行/空格，输出内容必须能直接被json.loads()解析。
2.  **禁止编造信息**：所有字段内容必须完全来自提供的原文，原文无对应信息的字段必须使用指定兜底值，不得虚构内容。
3.  **严格遵守JSON语法**：确保所有引号、逗号、括号完全闭合，数组/对象格式完全合法，无任何语法错误。

---
## 严格JSON输出格式（必须1:1匹配结构）
{
    "title": "事件标题",
    "genre": "事件类型",
    "importance": 0,
    "source": "发布机构",
    "review": "一句话摘要",
    "keywords": "#关键词1;#关键词2;#关键词3",
    "timeline": [
        {"节点名称": "YYYY-MM-DD HH:MM:SS"},
        {"节点名称": "YYYY-MM-DD HH:MM:SS"}
    ],
    "attachment": [
        {"附件名称": "对应完整链接"},
        {"附件名称": "对应完整链接"}
    ]
}

---
## 字段详细定义与强制约束
### 3.1 title（事件标题）
- 要求：与原通知标题完全一致，不修改、不缩写、不增减内容；
- 兜底：原文无明确标题时，取原文第一句完整语义的句子；无任何有效内容时填"无标题"。

### 3.2 genre（事件类型）
- 要求：**必须从以下枚举值中唯一选择，禁止自定义**：
  考试/活动/竞赛/国际/后勤/教务/其他
- 兜底：无法明确分类时填"其他"。

### 3.3 importance（重要程度）
- 要求：仅返回0-10之间的整数，严格按以下规则评分：
  1. 直接影响学业的（选课、考试、成绩、学籍、毕业相关）：≥8分；
  2. 有明确截止日期的活动/竞赛：≥5分（校级≥7分，院级≥5分，级别越高分数越高）；
  3. 无明确截止、不影响核心学业的一般性通知：4-7分；
  4. 与在校学生无直接关联的纯告知类内容：≤4分；
  5. 已过期的通知（按原文最晚截止时间判断）：≤2分；
- 兜底：无法判断时填3分。

### 3.4 source（发布机构）
- 要求：**必须从以下枚举值中唯一选择，禁止自定义**：
  教务处/党委/团委/彭康书院/文治书院/宗濂书院/启德书院/仲英书院/励志书院/崇实书院/南洋书院/数学学院/物理学院/化学学院/前沿院/机械学院/电气学院/能动学院/电信学部/人工智能学院/材料学院/人居学院/生命学院/航天学院/化工学院/仪器科学与技术学院/医学部/经金学院/金禾经济中心/管理学院/公管学院/人文学院/新媒体学院/马克思主义学院/法学院/外国语学院/体育学院/继续（网络）教育学院/国际教育学院/钱学森学院/创新创业学院/未来技术学院/西交米兰学院/其他
- 兜底：无法明确机构时填"其他"。

### 3.5 review（一句话摘要）
- 要求：用1句话完整概括通知核心内容，严格控制在50字以内，无冗余信息；
- 兜底：无法概括时取原文前50个字符，无有效内容时填"无有效摘要"。

### 3.6 keywords（关键词）
- 要求：
  1. 提取3-10个与事件核心强相关的实体关键词，禁止无意义通用词；
  2. 每个关键词以英文#开头，关键词之间用英文分号;间隔；
  3. 关键词简洁准确，无重复、无冗余；
- 正确示例：#选课;#2026春季;#教务处;#报名截止
- 兜底：无法提取时填"#通知;#校园;#其他"。

### 3.7 timeline（时间线）
- 要求：
  1. 提取原文中所有明确的时间节点，按时间从早到晚升序排列；
  2. 时间格式严格统一为「YYYY-MM-DD HH:MM:SS」，原文无具体时分秒时填「00:00:00」；
  3. 「节点名称」必须是描述事件动作的短语（如"报名截止""初赛开始"），禁止用时间作为节点名；
- 正确示例：[{"报名截止": "2026-04-05 23:59:59"}, {"初赛评选": "2026-04-15 09:00:00"}]
- 兜底：原文无明确时间节点时，返回空数组[]。

### 3.8 attachment（附件列表）
- 要求：
  1. 提取原文中所有明确的附件名称+对应的完整访问链接，一一对应；
  2. 附件名称必须与原文显示的文件名完全一致，链接必须保留原文提供的完整路径；
  3. 仅提取原文真实存在的附件，禁止编造；
- 正确示例：[{"2026春季选课操作指南.pdf": "https://jwc.xjtu.edu.cn/attachment/20260305.pdf"}, {"参赛报名表.docx": "https://jwc.xjtu.edu.cn/attachment/signup.docx"}]
- 兜底：原文无附件、无有效链接时，返回空数组[]。

---
## 【必做】最终输出自检清单
返回前必须逐一核对，确保完全符合：
1.  输出内容只有纯JSON，无任何其他字符、解释、代码块；
2.  JSON语法完全合法，所有括号、引号、逗号正确闭合，无语法错误；
3.  所有字段严格遵守上述约束，枚举值无自定义、内容无编造；
4.  时间格式、关键词格式、附件格式完全符合要求；
5.  无有效信息的字段已使用指定兜底值，无空值、无null。

现在开始解析以下原文：
"""

#Rate Limit logic config
req_timestamps = deque()
token_timestamps = deque()

def init_pg():
    try:
        conn = psycopg2.connect(**PG_CONFIG,client_encoding="utf8")
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS events (
                uuid UUID PRIMARY KEY,
                channel VARCHAR(100) NOT NULL,
                title VARCHAR(255) NOT NULL,
                genre VARCHAR(50),
                importance INT,
                source VARCHAR(20),
                review TEXT,
                link TEXT,
                keywords VARCHAR(255),
                timeline JSONB,
                attachment JSONB,
                original_text TEXT,
                fetch_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        cur.close()
        print("PostgreSQL连接成功，events表已就绪")
        return conn
    except Exception as e:
        print(f"PG初始化失败：{e}")
        sys.exit(1)

def check_rate_limit(tokens):
    now = time.time()
    while req_timestamps and now - req_timestamps[0] > WINDOW:
        req_timestamps.popleft()
    while token_timestamps and now - token_timestamps[0][0] > WINDOW:
        token_timestamps.popleft()
        
    current_rpm = len(req_timestamps)
    current_tpm = sum(t[1] for t in token_timestamps)

    if current_rpm >= MAX_RPM or current_tpm + tokens >= MAX_TPM:
        time.sleep(1)
        return check_rate_limit(tokens)
        
    req_timestamps.append(now)
    token_timestamps.append((now, tokens))

def call_qwen(content: str) -> dict:
    """调用Qwen API，返回解析后的结构化字典"""
    try:
        check_rate_limit(len(content) + 500)
        
        payload = {
            "model": QWEN_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": f"提取以下内容：\n\n{content}"}
            ],
            "temperature": 0.0,
            "stream": False
        }
        
        headers = {
            "Authorization": f"Bearer {QWEN_API_KEY}",
            "Content-Type": "application/json"
        }
        
        response = requests.post(QWEN_API_URL, json=payload, headers=headers)
        response.raise_for_status()
        
        result_json = response.json()["choices"][0]["message"]["content"]
        # print(f"DEBUG LLM RETURN:\n{result_json}")
        
        parsed = json.loads(result_json)
        return {
            "title": parsed.get("title", ""),
            "genre": parsed.get("genre", "其他"),
            "importance": parsed.get("importance", 0),
            "source": parsed.get("source", "其他"),
            "review": parsed.get("review", ""),
            "keywords": parsed.get("keywords", ""),
            "timeline": parsed.get("timeline", []),
            "attachment": parsed.get("attachment", [])
        }
    except json.JSONDecodeError:
        print("JSON 解析失败，返回默认结构")
        return {"title": "", "genre": "其他", "importance": 0, "source": "其他", "review": "", "keywords": "", "timeline": [], "attachment": [], "error": "JSON解析失败"}
    except Exception as e:
        print(f"Qwen API调用失败：{e}")
        return {"title": "", "genre": "其他", "importance": 0, "source": "其他", "review": "", "keywords": "", "timeline": [], "attachment": [], "error": str(e)}

def process_and_store(fetch_result, pg_conn, pg_cur):
    """提取的通用处理和入库逻辑"""
    if fetch_result.get("status") != "SUCCESS":
        print(f"[{fetch_result.get('channel', 'unknown')}] 抓取失败：{fetch_result.get('debug_info', '')}")
        return

    channel = fetch_result["channel"]
    fetch_time = datetime.now()
    titles = fetch_result.get("titles", [])
    links = fetch_result.get("links", [])
    contents = fetch_result.get("contents", [])

    print(f"\n开始处理 [{channel}] 的 {len(titles)} 条数据...")

    for idx, (ori_title, link, content) in enumerate(zip(titles, links, contents)):
        print(f"  处理第{idx+1}条：{ori_title[:50]}...")

        # 查重：避免重复调用大模型和重复入库
        if link:
            pg_cur.execute("SELECT 1 FROM events WHERE channel = %s AND link = %s", (channel, link))
        else:
            pg_cur.execute("SELECT 1 FROM events WHERE channel = %s AND title = %s", (channel, ori_title))
            
        if pg_cur.fetchone():
            print(f"  -> 已存在数据库中，跳过")
            continue

        #Skip if empty
        if not titles:
            print(f"  -> 第{idx+1}条内容为空，跳过")
            continue

        #Resolve timeline
        qwen_data = call_qwen(content)

        #Gen uuid
        event_uuid = str(uuid.uuid4())

        #Assemble data
        insert_data = (
            event_uuid,                # uuid
            channel,                   # channel
            fetch_time,                # fetch_time
            qwen_data["title"] or ori_title,  # title
            qwen_data["genre"],        # genre
            qwen_data["importance"],   # importance
            qwen_data["source"],       # source
            qwen_data["review"],       # review
            link,                      # link
            qwen_data["keywords"],     # keywords
            json.dumps(qwen_data["timeline"], ensure_ascii=False),  # timeline（JSONB）
            json.dumps(qwen_data["attachment"], ensure_ascii=False),  # attachment（JSONB）
            content                    # original_text
        )

        #Store
        try:
            pg_cur.execute("""
                INSERT INTO events (
                    uuid, channel, fetch_time, title, genre, importance, source, review, keywords, link, timeline, attachment, original_text
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
            """, insert_data)
            pg_conn.commit()
            print(f"  -> 第{idx+1}条入库成功 | UUID：{event_uuid}")
        except Exception as e:
            pg_conn.rollback()
            print(f"  -> 第{idx+1}条入库失败：{e}")
            continue


def main():
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)
    sys.stderr = open(sys.stderr.fileno(), mode='w', encoding='utf-8', buffering=1)

    # 导入 fetcher
    try:
        from fetch.fetcher import AnnouncementFetcher
        from fetch.api_fetcher import fetch_api_sources
    except ImportError as e:
        print(f"导入抓取器失败：{e} | 请检查 python 路径，当前 sys.path: {sys.path}")
        sys.exit(1)

    # 初始化数据库
    pg_conn = init_pg()
    pg_cur = pg_conn.cursor(cursor_factory=RealDictCursor)

    # 1. 运行所有基于 JSON 配置的 HTML 抓取
    fetcher = AnnouncementFetcher()
    config_files = glob.glob(str(CONFIG_DIR / "*.json"))
    
    print(f"发现 {len(config_files)} 个 JSON 配置文件，开始 HTML 抓取...")
    for config_path in config_files:
        print(f"\n{'='*40}\n执行配置文件: {os.path.basename(config_path)}")
        fetch_result = fetcher.fetch(config_path, max_items=20)
        process_and_store(fetch_result, pg_conn, pg_cur)

    # 2. 运行所有 API 抓取
    print(f"\n{'='*40}\n开始执行 API 抓取 (ss.xjtu / tuanwei)...")
    api_results = fetch_api_sources()
    for api_result in api_results:
        process_and_store(api_result, pg_conn, pg_cur)

    pg_cur.close()
    pg_conn.close()
    print("\n===== 全部处理完成 =====")

if __name__ == "__main__":
    main()