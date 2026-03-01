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

# --- Path Resolution ---
# Resolve the path to backend directory dynamically
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
SYSTEM_PROMPT = """从提供的网页源码中分析出通知的核心信息，严格按照以下JSON格式输出，仅返回JSON文本，不包含任何额外内容：
{
    "title": "事件标题（与原通知标题一致）",
    "genre": "事件类型（仅允许：考试/活动/竞赛/国际/后勤/教务/其他）",
    "importance": 0,
    "review": "用一句话概括该通知的主要内容，不超过50字",
    "timeline": [
        {"节点名称": "时间（格式：YYYY-MM-DD HH:MM:SS）"},
        {"节点名称": "时间（格式：YYYY-MM-DD HH:MM:SS）"}
    ]
}

importance字段说明：重要程度为0-10的整数。判断标准：直接影响学业的（如选课、考试、成绩）为8-10；有明确截止日期的活动/竞赛为5-7；一般性通知/公告为2-4；纯信息告知为0-1,和学生本人没啥利益关系的重要度给低，过期的通知重要度给低。
"""

#Rate Limit logic config
req_timestamps = deque()
token_timestamps = deque()

def init_pg():
    try:
        conn = psycopg2.connect(**PG_CONFIG)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS events (
                uuid UUID PRIMARY KEY,
                channel VARCHAR(100) NOT NULL,
                title VARCHAR(255) NOT NULL,
                genre VARCHAR(50),
                importance INT,
                review TEXT,
                link TEXT,
                timeline JSONB,
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
            "review": parsed.get("review", ""),
            "timeline": parsed.get("timeline", [])
        }
    except json.JSONDecodeError:
        print("JSON 解析失败，返回默认结构")
        return {"title": "", "genre": "其他", "importance": 0, "review": "", "timeline": [], "error": "JSON解析失败"}
    except Exception as e:
        print(f"Qwen API调用失败：{e}")
        return {"title": "", "genre": "其他", "importance": 0, "review": "", "timeline": [], "error": str(e)}

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
        event_uuid = uuid.uuid4()

        #Assemble data
        insert_data = (
            event_uuid,                # uuid
            channel,                   # channel
            fetch_time,                # fetch_time
            qwen_data["title"] or ori_title,  # title
            qwen_data["genre"],        # genre
            qwen_data["importance"],   # importance
            qwen_data["review"],       # review
            link,                      # link
            json.dumps(qwen_data["timeline"], ensure_ascii=False),  # timeline（JSONB）
            content                    # original_text
        )

        #Store
        try:
            pg_cur.execute("""
                INSERT INTO events (
                    uuid, channel, fetch_time, title, genre, importance, review, link, timeline, original_text
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