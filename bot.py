import requests
import random
import time
import logging
from typing import List

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("chatbot.log"),
        logging.StreamHandler()
    ]
)

# 配置
BASE_URL = "https://pengu.gaia.domains"
MODEL = "qwen2-0.5b-instruct"
MAX_RETRIES = 100  # 几乎无限重试
RETRY_DELAY = 5  # 重试间隔秒数
QUESTION_DELAY = 1  # 成功提问后的间隔秒数

QUESTIONS = [
    "什么是无代码开发？",
    "为什么使用无代码开发网站？",
    "哪些无代码工具适合网站开发？",
    "选择无代码平台时需要注意什么？",
    "如何开始一个无代码网站？",
    "如何在无代码平台中添加页面？",
    "如何自定义无代码网站的外观？",
    "无代码平台可以与其他服务集成吗？",
    "如何让无代码网站适配移动设备？",
    "如何通过无代码平台发布网站？",
    "无代码平台可以处理电子商务吗？",
    "无代码平台的局限性有哪些？",
    "如何在无代码网站上管理SEO？",
    "在哪里学习无代码网站建设？",
    "专业人士可以帮助无代码网站建设吗？",
    "无代码网站建设的成本是多少？",
    "无代码平台可以使用自定义域名吗？",
    "如何获取无代码问题的支持？",
    "如何更新无代码网站？",
    "有哪些用无代码构建的网站示例？",
    "无代码可以构建哪些类型的网站？",
    "如何在无代码平台中添加自定义代码？",
    "如何使用无代码添加表单？",
    "无代码平台提供哪些托管选项？",
    "如何用无代码创建登陆页面？",
    "如何确保无代码网站的 accessibility？",
    "如何在无代码平台中管理媒体？",
    "如何用无代码添加博客？",
    "无代码可以构建商业网站吗？",
    "如何用无代码添加电子邮件表单？",
    "如何在无代码平台中跟踪分析？",
    "无代码可以创建作品集网站吗？",
    "如何将社交媒体与无代码平台集成？",
    "无代码可以用于非营利组织吗？",
    "如何在无代码平台中添加搜索功能？",
    "如何保护无代码网站的安全？",
    "如何通过无代码平台发布网站？",
    "如何用无代码添加支付功能？",
    "无代码可以创建本地商业网站吗？",
    "如何优化无代码网站的速度？",
    "如何在无代码平台中添加网站图标？",
    "如何用无代码添加谷歌地图？",
    "如何在无代码平台中整合电子邮件营销？",
    "如何用无代码添加评论功能？",
    "如何用无代码添加联系表单？",
    "在哪里找到无代码问题排查帮助？",
    "无代码可以创建社区网站吗？",
    "如何用无代码添加图片画廊？",
    "如何用无代码自定义字体？",
    "如何使用无代码进行应用开发？",
    "无代码应用的优点是什么？",
    "无代码可以创建哪些类型的应用？",
    "哪些无代码平台适合应用开发？",
    "如何选择无代码应用平台？",
    "如何开始用无代码设计应用？",
    "如何在无代码应用中管理数据？",
    "如何在无代码应用中整合服务？",
    "如何用无代码自定义应用界面？",
    "如何在无代码应用中管理用户？",
    "如何保护无代码应用的安全？",
    "如何在无代码应用中进行用户认证？",
    "如何测试无代码应用？",
    "如何部署无代码应用？",
    "如何在无代码应用中迁移数据？",
    "可以在无代码应用中添加自定义代码吗？",
    "如何在无代码应用中添加用户内容？",
    "如何扩展无代码应用？",
    "无代码可以创建移动应用吗？",
    "如何在无代码应用中处理支付？",
    "如何在无代码应用中发送通知？",
    "如何在无代码应用中使用推送通知？",
    "如何跟踪无代码应用的使用情况？",
    "如何处理无代码应用的错误？",
    "如何收集无代码应用的反馈？",
    "如何在无代码应用中整合API？",
    "在哪里学习更多无代码应用知识？",
    "如何在无代码应用中管理数据库？",
    "无代码可以创建实时应用吗？",
    "如何在无代码应用中管理角色？",
    "如何确保无代码应用的隐私？",
    "如何在无代码项目上协作？",
    "如何备份无代码应用？",
    "如何维护无代码应用？",
    "无代码可以创建企业应用吗？",
    "如何在无代码中与其他系统集成？",
    "如何在无代码应用中链接社交媒体？",
    "如何优化无代码应用的性能？",
    "如何在无代码应用中吸引用户？",
    "如何在无代码应用中细分用户？",
    "如何个性化无代码应用？",
    "如何在无代码应用中引导用户？",
    "如何留住无代码应用的用户？",
    "如何支持无代码应用的用户？",
    "如何在无代码应用中整合CRM？",
    "如何在无代码中使用营销自动化？",
    "如何本地化无代码应用？",
    "如何在无代码中遵守数据法规？",
    "如何在无代码应用中可视化数据？",
    "如何在无代码应用中管理文件存储？",
    "如何在无代码应用中管理任务？"
]

def chat_with_ai(api_key: str, question: str) -> str:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {api_key}"
    }

    messages = [
        {"role": "user", "content": question}
    ]

    data = {
        "model": MODEL,
        "messages": messages,
        "temperature": 0.7
    }

    for attempt in range(MAX_RETRIES):
        try:
            logging.info(f"尝试 {attempt+1} 次，问题：{question[:50]}...")
            response = requests.post(
                f"{BASE_URL}/v1/chat/completions",
                headers=headers,
                json=data,
                timeout=30
            )

            if response.status_code == 200:
                return response.json()["choices"][0]["message"]["content"]

            logging.warning(f"API错误 ({response.status_code})：{response.text}")
            time.sleep(RETRY_DELAY)

        except Exception as e:
            logging.error(f"请求失败：{str(e)}")
            time.sleep(RETRY_DELAY)

    raise Exception("超过最大重试次数")

def run_bot(api_key: str):
    while True:  # 外层循环，重复提问直到停止
        random.shuffle(QUESTIONS)
        logging.info(f"启动聊天机器人，共有 {len(QUESTIONS)} 个问题，随机排序")

        for i, question in enumerate(QUESTIONS, 1):
            logging.info(f"\n处理问题 {i}/{len(QUESTIONS)}")
            logging.info(f"问题：{question}")

            start_time = time.time()
            try:
                response = chat_with_ai(api_key, question)
                elapsed = time.time() - start_time

                # 打印完整响应
                print(f"对 '{question[:50]}...' 的回答：\n{response}")

                logging.info(f"在 {elapsed:.2f}秒 内收到完整响应")
                logging.info(f"响应长度：{len(response)} 个字符")

                # 确保脚本在收到完整响应后再继续
                time.sleep(QUESTION_DELAY)  # 在下一个问题前等待

            except Exception as e:
                logging.error(f"处理问题失败：{str(e)}")
                continue

def main():
    print("标题：GaiaAI 聊天")
    api_key = input("请输入你的 API 密钥：")
    run_bot(api_key)

if __name__ == "__main__":
    main()
