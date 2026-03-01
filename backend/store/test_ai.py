import os
import sys
import json
from pathlib import Path

# Resolve path
STORE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(STORE_DIR))

# Import Qwen call function from store.py
try:
    from store import call_qwen
except ImportError as e:
    print(f"导入 store.py 失败: {e}")
    sys.exit(1)

# --------------
# 准备不同类型的测试语料
# --------------

TEST_CASES = [
    {
        "desc": "学术讲座测试档",
        "text": """
关于举办“科学大讲堂”系列讲座（第十五期）的通知
各学院、书院：
为浓厚校园学术氛围，拓宽本科生学术视野，定于下周二举办“科学大讲堂”第十五讲。
讲座主题：人工智能大模型前沿技术分析
主讲人：张三教授（计算机学院）
时间：2026年3月10日（周二）下午 14:30-16:00
地点：创新港涵英楼5-103
参与人员：全校师生
报名方式：请通过教务系统报名，报名截止时间为3月9日12:00。参加本次讲座可计入课外素养学分。/教务处/2026-03-01
"""
    },
    {
        "desc": "竞赛报名测试档",
        "text": """
关于组织参加第十八届全国大学生机器人竞赛的通知
全校学生：
第十八届“挑战杯”机器人竞赛校内选拔赛即将启动。
1. 报名要求：本科生、研究生均可组队报名，每队不超过5人。
2. 报名时间：即日起至2026年4月5日中午12:00。
3. 比赛时间：初赛定于2026年4月15日，决赛在5月中旬。
请各参赛队伍在实践教学中心网站提交报名表。/实践教学中心/2026-03-02
"""
    },
    {
        "desc": "简单公示测试档",
        "text": """
西安交通大学2025-2026学年秋季学期奖学金评定结果公示
经各书院评议推荐、学生处审核，现将本学年校级以上奖学金拟获得者名单予以公示（名单见附件）。
公示期：2026年1月5日-1月10日
如有异议，请在公示期内向学生处反映。联系电话：82660001
"""
    }
]

def main():
    print("=" * 60)
    print(" 启动大模型 (Qwen) 提取逻辑测试 (单机无需连数据库)")
    print("=" * 60)
    
    for idx, case in enumerate(TEST_CASES, start=1):
        print(f"\n[{idx}] 正在测试场景: {case['desc']}")
        print(f"原文片段: {case['text'].strip()[:60]}...")
        print("-" * 40)
        
        try:
            result = call_qwen(case['text'])
            print(json.dumps(result, ensure_ascii=False, indent=2))
            
            # 简单校验
            if not isinstance(result, dict) or "title" not in result or "genre" not in result:
                print("❌ 警告：返回的结果格式不满足 JSON 要求！")
            else:
                print("✅ 解析成功！")
                
        except Exception as e:
            print(f"❌ 测试失败: {e}")
            
    print("\n" + "=" * 60)
    print("所有 AI 测试完成。")

if __name__ == "__main__":
    main()
