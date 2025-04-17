from news_analysis_chain import analyze_news
from news_sources import NewsAggregator
from vector_db import NewsVectorDB

stock = "TSLA"  # 股票代碼
# vector_db = NewsVectorDB()
aggregator = NewsAggregator()
# 抓取最新金融新聞
news_list = aggregator.get_all_news(stock)
for i, news in enumerate(news_list, 1):
    print(f"\n📌 新聞 {i}：")
    print("內容：", news)
    result = analyze_news(news)
    print(f"🔍 情緒分析：\n{result}")
