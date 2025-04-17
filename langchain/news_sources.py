# news_sources.py
from typing import List, Dict
import requests, feedparser, hashlib
import tweepy
import datetime
import os
from dotenv import load_dotenv
from newspaper import Article

load_dotenv()

NEWS_API_KEY = os.getenv("NEWS_API_KEY")
TWITTER_BEARER = os.getenv("TWITTER_BEARER")


class NewsAggregator:
    def __init__(self):
        self.twitter_client = tweepy.Client(
            bearer_token=TWITTER_BEARER, wait_on_rate_limit=True
        )
        self.fetched_urls = set()  # 防止重複
        self.max_news = 5

    def fetch_full_article(self, url):
        article = Article(url)
        article.download()
        article.parse()
        return article.title, article.text

    def fetch_newsapi(self, query="Tesla"):
        url = "https://newsapi.org/v2/everything"
        params = {
            "q": query,
            "language": "en",
            "sortBy": "publishedAt",
            "pageSize": self.max_news,
            "apiKey": NEWS_API_KEY,
        }
        try:
            res = requests.get(url, params=params, timeout=10)
            data = res.json()
            results = []
            for article in data.get("articles", []):
                if article["url"] not in self.fetched_urls:
                    self.fetched_urls.add(article["url"])
                    results.append(
                        {
                            "title": article.get("title", "No title"),
                            "content": f"{article['title']}\n{article.get('description', '')}".strip(),
                            "metadata": {
                                "source": article.get("source", {}).get(
                                    "name", "NewsAPI"
                                ),
                                "published_at": article.get("publishedAt", ""),
                                "url": article.get("url", ""),
                                "author": article.get("author", ""),
                            },
                        }
                    )
            return results
        except requests.exceptions.RequestException as e:
            print(f"❌ Network Error: {str(e)}")
        except ValueError as e:
            print("❌ Invalid JSON response")
        except KeyError as e:
            print(f"❌ Missing expected data field: {str(e)}")
        return []

    def fetch_rss(self, feed_url="https://finance.yahoo.com/rss/"):
        feed = feedparser.parse(feed_url)
        results = []
        for entry in feed.entries[: self.max_news]:
            uid = hashlib.md5(entry.link.encode()).hexdigest()
            if uid not in self.fetched_urls:
                try:
                    link = entry.link
                    print(f"Fetching full article from {link}...")
                    content = self.fetch_full_article(link)
                    self.fetched_urls.add(uid)

                    results.append(
                        {
                            "title": entry.title,
                            "content": content,
                            "metadata": {
                                "source": entry.get("source", "Yahoo Finance"),
                                "published_at": entry.get("pubDate", ""),
                                "url": entry.get("link", ""),
                            },
                            "url": entry.link,
                            "source": "RSS",
                        }
                    )
                except Exception as e:
                    print(f"Error fetching full article: {e}")
        return results

    def fetch_twitter(self, query="TSLA"):
        results = []
        tweets = self.twitter_client.search_recent_tweets(
            query=query, max_results=self.max_news
        )
        for tweet in tweets.data:
            print(tweet)
            uid = hashlib.md5(tweet.text.encode()).hexdigest()
            if uid not in self.fetched_urls:
                self.fetched_urls.add(uid)
                results.append(
                    {
                        "title": f"Tweet: {tweet.id}",
                        "content": tweet.text,
                        "url": f"https://twitter.com/i/web/status/{tweet.id}",
                        "source": "Twitter",
                    }
                )
        return results

    def get_all_news(self, query="TSLA") -> List[Dict]:
        return self.fetch_newsapi(query)
