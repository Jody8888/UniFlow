# temp.py
import sys
import os

# 导入自定义的重试HTTP客户端（已重命名文件）
from http_client import RetryingHttpClient  # 关键：对应新文件名

if __name__ == "__main__":
    # 1. 创建客户端
    client = RetryingHttpClient()
    
    # 2. 模拟获取到反爬验证的client_id后，添加Cookie
    client.add_cookie("client_id", "xxx123456789")  # 替换为真实的client_id
    
    # 3. 发起请求（自动携带client_id Cookie）
    debug_info = []
    try:
        resp = client.get("https://nanyang.xjtu.edu.cn/xwtz/tzgg.htm", debug=debug_info)
        resp.encoding = resp.apparent_encoding
        print("✅ 响应内容（前500字符）：")
        print(resp.text[:50000])
    except Exception as e:
        print(f"❌ 请求失败：{e}")
        for msg in debug_info:
            print(f"  - {msg}")