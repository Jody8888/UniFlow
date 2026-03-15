import os
import sys
import glob
from pathlib import Path

# --- Path Resolution ---
# Resolve the path to backend directory dynamically
FETCH_DIR = Path(__file__).resolve().parent
BACKEND_DIR = FETCH_DIR.parent
CONFIG_DIR = FETCH_DIR / "config_json"
sys.path.insert(0, str(BACKEND_DIR))

try:
    from fetch.fetcher import AnnouncementFetcher
    from fetch.api_fetcher import fetch_api_sources
except ImportError as e:
    print(f"导入抓取器失败：{e} | 请检查 python 路径，当前 sys.path: {sys.path}")
    sys.exit(1)

def print_result(fetch_result):
    channel = fetch_result.get("channel", "unknown")
    status = fetch_result.get("status", "ERROR")
    titles = fetch_result.get("titles", [])
    links = fetch_result.get("links", [])
    contents = fetch_result.get("contents", [])
    
    print(f"\n==============================================")
    print(f"数据源(Channel): {channel}")
    print(f"状态(Status):    {status}")
    print(f"抓取数量(Items): {len(titles)}")
    print(f"==============================================")
    
    if status != "SUCCESS":
        print(f"错误信息:\n{fetch_result.get('debug_info', '')}")
        return
        
    for i, (t, l, c) in enumerate(zip(titles, links, contents)):
        print(f"[{i+1}] 标题: {t}")
        if l:
            print(f"    链接: {l}")
        # 如果内容太长则截断，展示前500字符
        preview = c.replace('\n', '  ')[:200]
        print(f"    正文: {preview}{'...' if len(c) > 200 else ''}")

# 2. 运行所有 API 抓取
print(f"\n\n>>> 开始测试 API 数据源...")
api_results = fetch_api_sources()  # 这会返回多个数据源的结果列表
for res in api_results:
    print_result(res)
print("\n测试运行完毕！")