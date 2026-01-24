import os
import sys
import json
import time
import uuid
import psycopg2
import requests
from datetime import datetime
from collections import deque
from psycopg2.extras import RealDictCursor

sys.path.insert(0, r"D:\Dev\Github\UniFlow\backend")
BACKEND_PATH = r"D:\Dev\Github\UniFlow\backend\fetch"
CONFIG_FILE_PATH = r"D:\Dev\Github\UniFlow\backend\fetch\config_json\oa.xjtu.edu.cn.json"

#QWEN2.5-7B-Instruct API(Slicon Flow)
QWEN_API_URL = "https://api.siliconflow.cn/v1/chat/completions"
QWEN_API_KEY = "sk-jtqjtcosjdnwqsyuqpsdxpfsierzlejkwtldfyhasomsirpx"
QWEN_MODEL = "qwen2.5-7b-instruct"

MAX_RPM = 1000
MAX_TPM = 50000
WINDOW = 60

#PostgreSQL
PG_CONFIG = {
    "host": "127.0.0.1",
    "port": 5432,
    "user": "test",
    "password": "passwd",
    "database": "uniflow"
}

#System Prompt
SYSTEM_PROMPT = """从提供的网页源码中分析出通知的核心信息，严格按照以下JSON格式输出，仅返回JSON文本，不包含任何额外内容：
{
    "title": "事件标题（与原通知标题一致）",
    "genre": "事件类型（仅允许：考试/活动/讲座/其他）",
    "timeline": [
        {"节点名称": "时间（格式：YYYY-MM-DD HH:MM:SS）"},
        {"节点名称": "时间（格式：YYYY-MM-DD HH:MM:SS）"}
    ]
}
"""

#API Limit
request_timestamps = deque()  #RPM
token_consumption = deque()   #TPM
def can_send_request(input_tokens: int, output_tokens: int) -> bool:

    current_time = time.time()
    total_tokens = input_tokens + output_tokens

    while request_timestamps and current_time - request_timestamps[0] > WINDOW:
        request_timestamps.popleft()
    while token_consumption and current_time - token_consumption[0][1] > WINDOW:
        token_consumption.popleft()

    #Current Rate
    current_rpm = len(request_timestamps)
    current_tpm = sum(t[0] for t in token_consumption)

    #Wait at limit
    if current_rpm >= MAX_RPM or current_tpm + total_tokens > MAX_TPM:
        return False
    return True

def init_pg():
    try:
        conn = psycopg2.connect(**PG_CONFIG)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS events (
                uuid UUID NOT NULL PRIMARY KEY,
                channel VARCHAR(100) NOT NULL,
                fetch_time TIMESTAMP NOT NULL,
                title VARCHAR(255) NOT NULL,
                genre VARCHAR(50) NOT NULL,
                timeline JSONB NOT NULL,
                original_text TEXT
            );
        """)
        conn.commit()
        cur.close()
        print("PostgreSQL连接成功，events表已就绪")
        return conn
    except Exception as e:
        print(f"PG初始化失败：{e}")
        sys.exit(1)

#Get json from api
def call_qwen(content: str) -> dict:
    """调用Qwen API，返回解析后的结构化字典"""
    #Token calc
    input_tokens = len(content) * 2 + len(SYSTEM_PROMPT) * 2
    output_tokens = 1024

    #Limit alloc
    while not can_send_request(input_tokens, output_tokens):
        time.sleep(0.1)

    #API request
    headers = {
        "Authorization": f"Bearer {QWEN_API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": QWEN_MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": content}
        ],
        "temperature": 0.0,
        "stream": False
    }

    try:
        current_time = time.time()
        resp = requests.post(QWEN_API_URL, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        resp_json = resp.json()

        #Update
        request_timestamps.append(current_time)
        actual_tokens = resp_json["usage"]["prompt_tokens"] + resp_json["usage"]["completion_tokens"]
        token_consumption.append((actual_tokens, current_time))

        #Resolve json returned
        qwen_raw = resp_json["choices"][0]["message"]["content"].strip()
        qwen_data = json.loads(qwen_raw)

        #Set deafault
        qwen_data["title"] = qwen_data.get("title", "")
        qwen_data["genre"] = qwen_data.get("genre", "其他")
        qwen_data["timeline"] = qwen_data.get("timeline", [])

        return qwen_data

    except json.JSONDecodeError as e:
        print(f"Qwen返回非JSON格式：{qwen_raw} | 错误：{e}")
        return {"title": "", "genre": "其他", "timeline": [], "error": "JSON解析失败"}
    except Exception as e:
        print(f"Qwen API调用失败：{e}")
        return {"title": "", "genre": "其他", "timeline": [], "error": str(e)}

def main():
    #
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)
    sys.stderr = open(sys.stderr.fileno(), mode='w', encoding='utf-8', buffering=1)

    #Inport fetcher
    sys.path.insert(0, BACKEND_PATH)
    try:
        from fetch.fetcher import AnnouncementFetcher
    except ImportError as e:
        print(f"导入抓取器失败：{e} | 请检查BACKEND_PATH是否正确")
        sys.exit(1)

    #Init pg
    pg_conn = init_pg()
    pg_cur = pg_conn.cursor(cursor_factory=RealDictCursor)

    #Init fetcher and fetch
    fetcher = AnnouncementFetcher()
    print(f"开始抓取：{CONFIG_FILE_PATH}")
    fetch_result = fetcher.fetch(CONFIG_FILE_PATH, max_items=20)

    if fetch_result["status"] != "SUCCESS":
        print(f"抓取失败：{fetch_result['debug_info']}")
        pg_conn.close()
        return

    #Go through records
    channel = fetch_result["channel"]
    fetch_time = datetime.now()

    for idx, (ori_title, link, content) in enumerate(zip(
        fetch_result["titles"], fetch_result["links"], fetch_result["contents"]
    )):
        print(f"\n处理第{idx+1}条：{ori_title[:50]}...")

        #Skip if empty
        if not content:
            print(f"第{idx+1}条内容为空，跳过")
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
            json.dumps(qwen_data["timeline"], ensure_ascii=False),  # timeline（JSONB）
            content                    # original_text
        )

        #Store
        try:
            pg_cur.execute("""
                INSERT INTO events (
                    uuid, channel, fetch_time, title, genre, timeline, original_text
                ) VALUES (%s, %s, %s, %s, %s, %s, %s);
            """, insert_data)
            pg_conn.commit()
            print(f"第{idx+1}条入库成功 | UUID：{event_uuid}")
        except Exception as e:
            pg_conn.rollback()
            print(f"第{idx+1}条入库失败：{e}")
            continue

    pg_cur.close()
    pg_conn.close()
    print("\n===== 处理完成 =====")

if __name__ == "__main__":
    main()