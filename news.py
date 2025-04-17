import hashlib
import json


class News:
    def __init__(self, article, analysis_result):
        content_hash = hashlib.sha256(article["content"].encode()).hexdigest()

        self.id = content_hash
        self.title = article.get("title", "")
        self.content = article.get("content", "")
        self.sentiment = analysis_result.get("sentiment", "")
        self.subject = analysis_result.get("subject", "")
        self.metadata = {
            **article["metadata"],
            **analysis_result,
            "source": article.get("source", "news_api"),
            "content_hash": content_hash,
            "sources": [article["metadata"]["url"]],  # Initialize sources list
        }

    def __str__(self):
        return json.dumps(self.__dict__, indent=4, ensure_ascii=False)
