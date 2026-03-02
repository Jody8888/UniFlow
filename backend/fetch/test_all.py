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
        # 为了不刷屏，每个来源只详细打印前 3 条结果
        if i >= 3:
            print(f"  ... 还有 {len(titles) - 3} 条结果已折叠。")
            break
        print(f"[{i+1}] 标题: {t}")
        if l:
            print(f"    链接: {l}")
        # 如果内容太长则截断，展示前200字符
        preview = c.replace('\n', '  ')[:1000]
        print(f"    正文: {preview}{'...' if len(c) > 200 else ''}")

def main():
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)
    sys.stderr = open(sys.stderr.fileno(), mode='w', encoding='utf-8', buffering=1)

    print("启动抓取测试系统 (完全离线模式，无数据库，无LLM)\n")
    
    # 1. 运行所有 HTML JSON 抓取规则
    fetcher = AnnouncementFetcher()
    config_files = glob.glob(str(CONFIG_DIR / "*.json"))
    
    print(f">>> 发现 {len(config_files)} 个 JSON HTML 抓取源，开始测试...")
    for config_path in config_files:
        print(f"\n正在抓取 -> {os.path.basename(config_path)}")
        # 这里为了测试速度，我们给一个较小的 max_items 参数（比如 3 篇）
        # 很多网站每次加载如果都跑20篇，测试会很慢
        fetch_result = fetcher.fetch(config_path, max_items=3)
        print_result(fetch_result)

    # 2. 运行所有 API 抓取
    print(f"\n\n>>> 开始测试 API 数据源...")
    api_results = fetch_api_sources()  # 这会返回多个数据源的结果列表
    for res in api_results:
        print_result(res)

    print("\n测试运行完毕！")

if __name__ == "__main__":
    main()
