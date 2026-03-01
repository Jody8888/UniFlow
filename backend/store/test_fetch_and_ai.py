import os
import sys
import glob
import json
from pathlib import Path

# --- Path Resolution ---
STORE_DIR = Path(__file__).resolve().parent
BACKEND_DIR = STORE_DIR.parent
CONFIG_DIR = BACKEND_DIR / "fetch" / "config_json"
sys.path.insert(0, str(BACKEND_DIR))

try:
    from fetch.fetcher import AnnouncementFetcher
    from fetch.api_fetcher import fetch_api_sources
    from store import call_qwen
except ImportError as e:
    print(f"导入依赖失败：{e} | 请检查 python 路径。")
    sys.exit(1)

def process_and_test_ai(fetch_result):
    """提取的测试处理逻辑，替代了原有的入库流程"""
    if fetch_result.get("status") != "SUCCESS":
        print(f"[{fetch_result.get('channel', 'unknown')}] 抓取失败：{fetch_result.get('debug_info', '')}")
        return

    channel = fetch_result["channel"]
    titles = fetch_result.get("titles", [])
    links = fetch_result.get("links", [])
    contents = fetch_result.get("contents", [])

    print(f"\n==============================================")
    print(f"📥 开始处理数据源 [{channel}] 的 {len(titles)} 条数据...")
    print(f"==============================================\n")

    for idx, (ori_title, link, content) in enumerate(zip(titles, links, contents)):
        print(f"[{idx+1}/{len(titles)}] 正在通过 Qwen 分析：{ori_title[:60]}...")
        
        # 跳过空内容
        if not content:
            print(f"  -> 内容为空，跳过")
            print("-" * 40)
            continue

        try:
            # 直接调用大模型
            qwen_data = call_qwen(content)
            
            # 美观地序列化打印出分析结果
            output = {
                "标题 (LLM提取)": qwen_data.get("title") or ori_title,
                "原始链接": link,
                "分类 (Genre)": qwen_data.get("genre"),
                "重要性 (Importance)": qwen_data.get("importance"),
                "一句话简评 (Review)": qwen_data.get("review"),
                "时间线 (Timeline)": qwen_data.get("timeline")
            }
            print(json.dumps(output, ensure_ascii=False, indent=2))
            
        except Exception as e:
            print(f"  -> ❌ AI 解析出错: {e}")
            
        print("-" * 50)


def main():
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)
    sys.stderr = open(sys.stderr.fileno(), mode='w', encoding='utf-8', buffering=1)

    print("启动【全量抓取 + AI 解析】测试管道 (无数据库模式)\n")
    print("⚠️ 警告: 该测试会完整抓取网页并对每一篇调用 Qwen API。")
    print("整个过程可能消耗较多 Token 及时间，请耐心等待。\n")

    # 1. 运行所有基于 JSON 配置的 HTML 抓取
    fetcher = AnnouncementFetcher()
    config_files = glob.glob(str(CONFIG_DIR / "*.json"))
    
    print(f">>> 发现 {len(config_files)} 个 JSON HTML 抓取源，开始执行...")
    for config_path in config_files:
        print(f"\n\n{'*'*40}\n执行配置文件: {os.path.basename(config_path)}")
        # 注意: 这里去掉了测试版的 max_items 限制，按照各网站真实的配置 (通常是 15-20)
        fetch_result = fetcher.fetch(config_path)
        process_and_test_ai(fetch_result)

    # 2. 运行所有 API 抓取
    print(f"\n{'*'*40}\n>>> 开始执行 API 抓取 (ss.xjtu / tuanwei)...")
    api_results = fetch_api_sources()
    for api_result in api_results:
        process_and_test_ai(api_result)

    print("\n===== 全部全量测试处理完成 =====")

if __name__ == "__main__":
    main()
