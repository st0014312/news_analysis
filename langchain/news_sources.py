# news_sources.py
from typing import List, Dict, Optional, Set
import requests
import feedparser
import hashlib
import tweepy
import datetime
import os
import time
import json
from urllib.parse import urlparse
from dotenv import load_dotenv
from newspaper import Article, ArticleException
from firebase_store import FirebaseClient
from concurrent.futures import ThreadPoolExecutor, as_completed

load_dotenv()

# API Keys
NEWS_API_KEY = os.getenv("NEWS_API_KEY")
TWITTER_BEARER = os.getenv("TWITTER_BEARER")
ALPHA_VANTAGE_KEY = os.getenv("ALPHA_VANTAGE_KEY")
FINANCIAL_MODELING_PREP_KEY = os.getenv("FMP_API_KEY")

# Initialize Firebase for URL deduplication
firebase_client = FirebaseClient(
    key_path="news-analysis-c63db-firebase-adminsdk-fbsvc-bc62247bc2.json"
)


class NewsAggregator:
    """Enhanced news aggregator with improved deduplication and multiple sources"""

    def __init__(self):
        # Initialize Twitter client if credentials are available
        if TWITTER_BEARER:
            self.twitter_client = tweepy.Client(
                bearer_token=TWITTER_BEARER, wait_on_rate_limit=True
            )
        else:
            self.twitter_client = None

        # In-memory cache for current session
        self.fetched_urls = set()
        self.url_content_hash_map = {}

        # Configuration
        self.max_news = 10
        self.max_workers = 5  # For parallel fetching
        self.default_rss_feeds = [
            "https://finance.yahoo.com/rss/",
            # "https://www.cnbc.com/id/100003114/device/rss/rss.html",
            # "https://www.reuters.com/business/finance/rss",
            # "https://seekingalpha.com/feed.xml",
            # "https://www.ft.com/rss/markets",
        ]

        # Load previously fetched URLs from Firebase
        self._load_fetched_urls()

    def _load_fetched_urls(self):
        """Load previously fetched URLs from Firebase to prevent reprocessing"""
        try:
            # Get the last 1000 processed URLs
            docs = firebase_client.get_latest_analyses("processed_urls", 1000)
            for doc in docs:
                url = doc.get("url")
                if url:
                    self.fetched_urls.add(url)
            print(f"Loaded {len(self.fetched_urls)} previously processed URLs")
        except Exception as e:
            print(f"Error loading fetched URLs: {e}")

    def _save_processed_url(self, url: str, content_hash: str):
        """Save processed URL to Firebase for deduplication across runs"""
        try:
            doc_id = hashlib.md5(url.encode()).hexdigest()
            firebase_client.save_analysis(
                "processed_urls",
                doc_id,
                {
                    "url": url,
                    "content_hash": content_hash,
                    "processed_at": datetime.datetime.utcnow().isoformat(),
                },
            )
        except Exception as e:
            print(f"Error saving processed URL: {e}")

    def _normalize_url(self, url: str) -> str:
        """Normalize URL to prevent duplicates with different query parameters"""
        parsed = urlparse(url)
        # Keep domain, path, and fragment, but remove query parameters that might vary
        return f"{parsed.scheme}://{parsed.netloc}{parsed.path}"

    def _generate_content_hash(self, content: str) -> str:
        """Generate a hash of the content to detect duplicates with different URLs"""
        # Remove common dynamic elements like dates, timestamps, and formatting
        # This helps identify the same content even if minor details change
        return hashlib.sha256(content.encode()).hexdigest()

    def _is_duplicate(self, url: str, content: str) -> bool:
        """Check if URL or content is a duplicate"""
        normalized_url = self._normalize_url(url)

        # Check if URL has been processed before
        if normalized_url in self.fetched_urls:
            return True

        # Check if content is duplicate by comparing content hash
        content_hash = self._generate_content_hash(content)
        for existing_hash in self.url_content_hash_map.values():
            # Use similarity threshold to catch near-duplicates
            if self._hash_similarity(content_hash, existing_hash) > 0.9:
                return True

        # Not a duplicate, add to tracking
        self.fetched_urls.add(normalized_url)
        self.url_content_hash_map[normalized_url] = content_hash
        self._save_processed_url(normalized_url, content_hash)
        return False

    def _hash_similarity(self, hash1: str, hash2: str) -> float:
        """Calculate similarity between two hashes (0-1)"""
        # Simple implementation - count matching characters
        if len(hash1) != len(hash2):
            return 0

        matches = sum(1 for a, b in zip(hash1, hash2) if a == b)
        return matches / len(hash1)

    def fetch_full_article(self, url: str) -> Dict:
        """Fetch full article content with enhanced error handling and metadata extraction"""
        try:
            # Enhanced headers to mimic a real browser
            headers = {
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "Accept-Encoding": "gzip, deflate, br",
                "Connection": "keep-alive",
                "Upgrade-Insecure-Requests": "1",
                "Sec-Fetch-Dest": "document",
                "Sec-Fetch-Mode": "navigate",
                "Sec-Fetch-Site": "none",
                "Sec-Fetch-User": "?1",
                "Cache-Control": "max-age=0"
            }
            
            # For Yahoo Finance, add specific cookies to bypass consent
            cookies = {}
            if "finance.yahoo.com" in url:
                cookies = {
                    "consent": "true",
                    "EuConsent": "CPZxMgAPZxMgAAHABBENC6CsAP_AAH_AAAAAJNNf_X__b3_j-_5_f_t0eY1P9_7_v-0zjhfdt-8N3f_X_L8X42M7vF36pq4KuR4Eu3LBIQdlHOHcTUmw6okVrzPsbk2cr7NKJ7PEmnMbO2dYGH9_n93TuZKY7___f__z_v-v_v____f_7-3_3__5_3---_e_V_99zLv9____39nP___9v-_9_____4IhgEmGpeQBdiWODJtGlUKIEYVhIdAKACigGFoisIHVwU7K4CPUEDABAagIwIgQYgoxYBAAIBAEhEQEgB4IBEARAIAAQAqwEIACNgEFgBYGAQACgGhYgRQBCBIQZHBUcpgQFSLRQT2ViCUHexphCGWeBJljAKI-QgA",
                    "GUC": "AQEAAAAWAEt3TkIq9jRm9RXIAQE"
                }
            
            # Make the initial request
            response = requests.get(url, headers=headers, cookies=cookies, timeout=15)
            
            # Handle Yahoo Finance consent page specifically
            if "consent.yahoo.com" in response.url:
                print(f"📝 Detected Yahoo consent page, bypassing for: {url}")
                
                # Extract necessary tokens from the consent page
                import re
                session_token_match = re.search(r'sessionId":"([^"]+)"', response.text)
                session_token = session_token_match.group(1) if session_token_match else None
                
                if session_token:
                    # Consent to cookies
                    consent_url = "https://consent.yahoo.com/v2/collectConsent"
                    consent_payload = {
                        "sessionId": session_token,
                        "consent": {
                            "accepts": ["analytics", "advertising", "personalization", "necessary"]
                        }
                    }
                    consent_headers = {
                        **headers,
                        "Content-Type": "application/json",
                        "Referer": response.url
                    }
                    
                    # Send consent
                    requests.post(consent_url, headers=consent_headers, json=consent_payload, timeout=10)
                    
                    # Get the original URL again with consent cookies
                    enhanced_cookies = {
                        **cookies,
                        "consent": "true"
                    }
                    response = requests.get(url, headers=headers, cookies=enhanced_cookies, timeout=15)
                    
                    # If still on consent page, use more aggressive approach
                    if "consent.yahoo.com" in response.url:
                        # Try to extract the destination URL from the consent page
                        destination_match = re.search(r'Dsturl=([^&]+)', response.url)
                        if destination_match:
                            destination = destination_match.group(1)
                            import urllib.parse
                            destination = urllib.parse.unquote(destination)
                            # Fetch the destination URL directly
                            response = requests.get(destination, headers=headers, cookies=enhanced_cookies, timeout=15)

            article = Article(response.url)
            article.download(input_html=response.text)
            article.parse()

            # Extract additional metadata
            metadata = {
                "title": article.title,
                "authors": article.authors,
                "publish_date": (
                    article.publish_date.isoformat() if article.publish_date else None
                ),
                "top_image": article.top_image,
                "url": url,
                "source": urlparse(url).netloc,
            }

            # Try to extract keywords and summary if available
            try:
                article.nlp()
                metadata["keywords"] = article.keywords
                metadata["summary"] = article.summary
            except:
                # NLP might fail but we still want the article content
                pass

            return {
                "title": article.title,
                "content": article.text,
                "metadata": metadata,
            }
        except ArticleException as e:
            print(f"❌ Article extraction error for {url}: {str(e)}")
            return None
        except Exception as e:
            print(f"❌ Unexpected error fetching {url}: {str(e)}")
            return None

    def fetch_newsapi(self, query: str = "Tesla", days: int = 2) -> List[Dict]:
        """Fetch news from NewsAPI with enhanced filtering and deduplication"""
        url = "https://newsapi.org/v2/everything"

        # Calculate date range
        to_date = datetime.datetime.now()
        from_date = to_date - datetime.timedelta(days=days)

        params = {
            "q": query,
            "language": "en",
            "sortBy": "publishedAt",
            "pageSize": 100,  # Request more to account for filtering
            "from": from_date.strftime("%Y-%m-%d"),
            "to": to_date.strftime("%Y-%m-%d"),
            "apiKey": NEWS_API_KEY,
        }

        try:
            res = requests.get(url, params=params, timeout=15)
            data = res.json()

            if res.status_code != 200:
                print(f"❌ NewsAPI error: {data.get('message', 'Unknown error')}")
                return []

            results = []
            articles = data.get("articles", [])

            # Process articles in parallel for efficiency
            with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
                # First, submit all fetch tasks
                future_to_article = {}
                for article in articles:
                    article_url = article.get("url")
                    if not article_url:
                        continue

                    # Skip if URL is already known
                    if self._normalize_url(article_url) in self.fetched_urls:
                        continue

                    # Create a basic article object from the API response
                    basic_article = {
                        "title": article.get("title", "No title"),
                        "content": f"{article.get('title', '')}\n{article.get('description', '')}".strip(),
                        "metadata": {
                            "source": article.get("source", {}).get("name", "NewsAPI"),
                            "published_at": article.get("publishedAt", ""),
                            "url": article_url,
                            "author": article.get("author", ""),
                            "urlToImage": article.get("urlToImage", ""),
                        },
                    }

                    # Check if we should fetch the full article
                    if (
                        len(basic_article["content"]) < 200
                    ):  # If description is too short
                        future = executor.submit(self.fetch_full_article, article_url)
                        future_to_article[future] = basic_article
                    else:
                        # Use the basic article if it has enough content
                        if not self._is_duplicate(
                            article_url, basic_article["content"]
                        ):
                            results.append(basic_article)

                            # Stop if we have enough articles
                            if len(results) >= self.max_news:
                                break

                # Process completed fetches
                for future in as_completed(future_to_article):
                    basic_article = future_to_article[future]
                    try:
                        full_article = future.result()
                        if full_article:
                            # Check for duplicates
                            if not self._is_duplicate(
                                full_article["metadata"]["url"], full_article["content"]
                            ):
                                results.append(full_article)

                                # Stop if we have enough articles
                                if len(results) >= self.max_news:
                                    break
                    except Exception as e:
                        print(f"❌ Error processing article: {e}")

            return results[: self.max_news]  # Ensure we don't exceed max_news

        except requests.exceptions.RequestException as e:
            print(f"❌ Network Error: {str(e)}")
        except ValueError as e:
            print("❌ Invalid JSON response")
        except KeyError as e:
            print(f"❌ Missing expected data field: {str(e)}")

        return []

    def fetch_rss(self, feed_urls: Optional[List[str]] = None) -> List[Dict]:
        """Fetch news from multiple RSS feeds with parallel processing"""
        if feed_urls is None:
            feed_urls = self.default_rss_feeds

        all_results = []

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            future_to_feed = {
                executor.submit(self._process_feed, feed_url): feed_url
                for feed_url in feed_urls
            }

            for future in as_completed(future_to_feed):
                feed_url = future_to_feed[future]
                try:
                    results = future.result()
                    all_results.extend(results)

                    # Stop if we have enough articles
                    if len(all_results) >= self.max_news:
                        break
                except Exception as e:
                    print(f"❌ Error processing feed {feed_url}: {e}")

        return all_results[: self.max_news]  # Ensure we don't exceed max_news

    def _process_feed(self, feed_url: str) -> List[Dict]:
        """Process a single RSS feed"""
        try:
            feed = feedparser.parse(feed_url)
            results = []

            for entry in feed.entries:
                if not hasattr(entry, "link"):
                    continue

                link = entry.link
                normalized_url = self._normalize_url(link)

                # Skip if URL is already known
                if normalized_url in self.fetched_urls:
                    continue

                try:
                    # Fetch full article
                    article_data = self.fetch_full_article(link)
                    if not article_data:
                        continue

                    # Check for duplicates
                    if not self._is_duplicate(link, article_data["content"]):
                        # Add source information
                        article_data["metadata"]["feed_title"] = feed.feed.get(
                            "title", "Unknown Feed"
                        )
                        article_data["metadata"]["feed_url"] = feed_url
                        article_data["source"] = "RSS"

                        results.append(article_data)

                        # Stop if we have enough articles from this feed
                        if len(results) >= self.max_news // len(self.default_rss_feeds):
                            break

                except Exception as e:
                    print(f"Error fetching article from {link}: {e}")

            return results

        except Exception as e:
            print(f"Error processing feed {feed_url}: {e}")
            return []

    def fetch_twitter(self, query: str = "TSLA", days: int = 2) -> List[Dict]:
        """Fetch financial news from Twitter with enhanced filtering"""
        if not self.twitter_client:
            print(
                "Twitter client not initialized. Check TWITTER_BEARER environment variable."
            )
            return []

        results = []

        try:
            # Add financial keywords to the query for better results
            enhanced_query = f"{query} (finance OR stock OR market OR earnings OR investor) -is:retweet"

            # Calculate start time
            start_time = (
                datetime.datetime.now() - datetime.timedelta(days=days)
            ).strftime("%Y-%m-%dT%H:%M:%SZ")

            tweets = self.twitter_client.search_recent_tweets(
                query=enhanced_query,
                max_results=100,  # Request more to account for filtering
                start_time=start_time,
                tweet_fields=["created_at", "public_metrics", "entities", "author_id"],
            )

            if not tweets.data:
                return []

            for tweet in tweets.data:
                # Skip if already processed
                tweet_url = f"https://twitter.com/i/web/status/{tweet.id}"
                if tweet_url in self.fetched_urls:
                    continue

                # Filter out low-quality tweets
                metrics = getattr(tweet, "public_metrics", {})
                if metrics:
                    # Skip tweets with very low engagement
                    if (
                        metrics.get("retweet_count", 0) + metrics.get("like_count", 0)
                        < 5
                    ):
                        continue

                # Extract entities if available
                entities = []
                if hasattr(tweet, "entities") and tweet.entities:
                    if "cashtags" in tweet.entities:
                        entities.extend(
                            [f"${tag['tag']}" for tag in tweet.entities["cashtags"]]
                        )
                    if "hashtags" in tweet.entities:
                        entities.extend(
                            [f"#{tag['tag']}" for tag in tweet.entities["hashtags"]]
                        )

                # Create article-like structure
                content = tweet.text

                # Check for duplicates
                if not self._is_duplicate(tweet_url, content):
                    results.append(
                        {
                            "title": f"Tweet about {query}",
                            "content": content,
                            "metadata": {
                                "source": "Twitter",
                                "published_at": (
                                    tweet.created_at.isoformat()
                                    if hasattr(tweet, "created_at")
                                    else ""
                                ),
                                "url": tweet_url,
                                "author_id": tweet.author_id,
                                "entities": entities,
                                "metrics": metrics,
                            },
                        }
                    )

                    # Stop if we have enough tweets
                    if len(results) >= self.max_news:
                        break

            return results

        except Exception as e:
            print(f"❌ Twitter API error: {str(e)}")
            return []

    def fetch_financial_data(self, symbol: str) -> Dict:
        """Fetch financial data for a stock symbol"""
        if not ALPHA_VANTAGE_KEY:
            print(
                "Alpha Vantage API key not set. Check ALPHA_VANTAGE_KEY environment variable."
            )
            return {}

        try:
            # Get company overview
            overview_url = f"https://www.alphavantage.co/query?function=OVERVIEW&symbol={symbol}&apikey={ALPHA_VANTAGE_KEY}"
            overview_response = requests.get(overview_url, timeout=10)
            overview_data = overview_response.json()

            # Get recent news
            news_url = f"https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers={symbol}&apikey={ALPHA_VANTAGE_KEY}"
            news_response = requests.get(news_url, timeout=10)
            news_data = news_response.json()

            # Combine data
            return {
                "overview": overview_data,
                "news": news_data.get("feed", [])[:5],  # Limit to 5 news items
            }

        except Exception as e:
            print(f"❌ Financial data API error: {str(e)}")
            return {}

    def get_all_news(self, query: str = "TSLA") -> List[Dict]:
        """Get news from all sources with smart deduplication"""
        all_results = []

        # Fetch from multiple sources
        newsapi_results = self.fetch_newsapi(query)
        rss_results = []
        # twitter_results = self.fetch_twitter(query)
        twitter_results = [] # Temporarily disabled for testing

        # Combine results with source tracking
        for article in newsapi_results:
            article["source"] = "NewsAPI"
            all_results.append(article)

        for article in rss_results:
            article["source"] = "RSS"
            all_results.append(article)

        for article in twitter_results:
            article["source"] = "Twitter"
            all_results.append(article)

        # Sort by recency (if available)
        def get_published_date(article):
            published_at = article.get("metadata", {}).get("published_at", "")
            if published_at:
                try:
                    # Ensure all datetime objects are offset-aware
                    return datetime.datetime.fromisoformat(
                        published_at.replace("Z", "+00:00")
                    ).astimezone(datetime.timezone.utc)
                except:
                    pass
            return datetime.datetime.min.replace(tzinfo=datetime.timezone.utc)

        all_results.sort(key=get_published_date, reverse=True)

        # Return limited results
        return all_results[: self.max_news]
