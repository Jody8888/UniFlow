import os
import sys
import json
import time
import uuid
import glob
from dotenv import load_dotenv
from pathlib import Path
import psycopg2
import requests
from datetime import datetime
from collections import deque
from psycopg2.extras import RealDictCursor

load_dotenv("../../.env")

# 路径配置
STORE_DIR = Path(__file__).resolve().parent
BACKEND_DIR = STORE_DIR.parent
FETCH_DIR = BACKEND_DIR / "fetch"
CONFIG_DIR = FETCH_DIR / "config_json"

sys.path.insert(0, str(BACKEND_DIR))

#QWEN2.5-7B-Instruct API(Slicon Flow)
QWEN_API_URL = os.getenv("QWEN_API_URL", "")
QWEN_API_KEY = os.getenv("QWEN_API_KEY", "")
QWEN_MODEL = os.getenv("QWEN_MODEL", "")

MAX_RPM = 1000
MAX_TPM = 50000
WINDOW = 60

#PostgreSQL
PG_CONFIG = {
    "host": os.getenv("PG_HOST", "127.0.0.1"),
    "port": int(os.getenv("PG_PORT", 5432)),
    "user": os.getenv("PG_USER", "test"),
    "password": os.getenv("PG_PASSWD", "passwd"),
    "dbname": os.getenv("PG_DBNAME", "uniflow")
}

#System Prompt
with open(os.getenv("SYSTEM_PROMPT","system_prompt.prompt"),"r",encoding="UTF-8") as pro:
    SYSTEM_PROMPT = pro.read()

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

def call_qwen(content: str, ori_title: str = "", link: str = "", metadata_time: str = "", max_retries: int = 3) -> dict:
    """调用Qwen API，返回解析后的结构化字典，带重试机制"""
    for attempt in range(max_retries):
        try:
            check_rate_limit(len(content) + 500)
            
            # 将相关元数据也一并传给模型，提供更好的判定参考
            user_msg = (
                f"参考标题：{ori_title}\n"
                f"原文链接：{link}\n"
                f"参考时间（发布时间）：{metadata_time}\n\n"
                f"提取以下正文内容：\n\n{content}"
            )
            
            payload = {
                "model": QWEN_MODEL,
                "messages": [
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_msg}
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
        except json.JSONDecodeError as e:
            print(f"JSON 解析失败 (尝试 {attempt + 1}/{max_retries}): {e}")
            if attempt == max_retries - 1:
                return {"title": "", "genre": "其他", "importance": 0, "source": "其他", "review": "", "keywords": "", "timeline": [], "attachment": [], "error": "JSON解析失败"}
        except Exception as e:
            print(f"Qwen API调用失败 (尝试 {attempt + 1}/{max_retries}): {e}")
            if attempt == max_retries - 1:
                return {"title": "", "genre": "其他", "importance": 0, "source": "其他", "review": "", "keywords": "", "timeline": [], "attachment": [], "error": str(e)}
            time.sleep(1) # 重试前稍作等待

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

        # Skip if empty
        if not titles:
            print(f"  -> 第{idx+1}条内容为空，跳过")
            continue

        # 将标题、链接、抓取时间传给模型作为上下文
        qwen_data = call_qwen(content, ori_title=ori_title, link=link, metadata_time=str(fetch_time))

        if "error" in qwen_data:
            print(f"  -> 大模型解析失败，跳过入库：{qwen_data['error']}")
            continue

        # 校验并清洗 timeline 时间格式
        valid_timeline = []
        if isinstance(qwen_data.get("timeline"), list):
            for item in qwen_data["timeline"]:
                if not isinstance(item, dict):
                    continue
                cleaned_item = {}
                for k, v in item.items():
                    try:
                        # 查验时间格式是否严格复合 "%Y-%m-%d %H:%M:%S"，且为合法真实时间
                        datetime.strptime(str(v).strip(), "%Y-%m-%d %H:%M:%S")
                        cleaned_item[k] = str(v).strip()
                    except ValueError:
                        print(f"  -> [警告] 时间格式非法，自动剔除该节点: '{k}': '{v}'")
                if cleaned_item:
                    valid_timeline.append(cleaned_item)
        qwen_data["timeline"] = valid_timeline

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
                    uuid, channel, fetch_time, title, genre, importance, source, review, link, keywords, timeline, attachment, original_text
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);
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