import hashlib
import json
from datetime import datetime
from typing import Dict, Any, List, Optional


class News:
    """Enhanced News class with structured data and metadata"""
    
    def __init__(self, article: Dict[str, Any], analysis_result: Optional[Dict[str, Any]] = None):
        # Handle case when analysis_result is None
        if analysis_result is None:
            analysis_result = {}
            
        # Generate a unique ID based on content hash
        content_hash = hashlib.sha256(article["content"].encode()).hexdigest()
        
        # Basic properties
        self.id = content_hash
        self.title = article.get("title", "")
        self.content = article.get("content", "")
        self.processed_content = article.get("processed_content", self.content)
        
        # Sentiment analysis
        self.sentiment = {
            "compound_score": analysis_result.get("sentiment", {}).get("compound_score", 0),
            "category": analysis_result.get("sentiment", {}).get("category", "neutral"),
            "positive_aspects": analysis_result.get("sentiment", {}).get("positive_aspects", []),
            "negative_aspects": analysis_result.get("sentiment", {}).get("negative_aspects", []),
            "neutral_aspects": analysis_result.get("sentiment", {}).get("neutral_aspects", [])
        }
        
        # Main subject and topics
        self.subject = analysis_result.get("subject", "")
        self.topics = analysis_result.get("topics", [])
        
        # Entities with detailed information
        self.entities = analysis_result.get("entities", [])
        
        # Causal relationships
        self.causal_relationships = analysis_result.get("causal_relationships", [])
        
        # Summary
        self.summary = analysis_result.get("summary", "")
        
        # Analysis confidence and model version
        self.confidence = analysis_result.get("confidence", 0.0)
        self.model_version = analysis_result.get("model_version", "1.0.0")
        
        # Timestamps
        self.published_at = article.get("metadata", {}).get("published_at", "")
        self.analyzed_at = analysis_result.get("analyzed_at", datetime.utcnow().isoformat())
        
        # Source information
        self.source = article.get("source", "news_api")
        self.url = article.get("metadata", {}).get("url", "")
        
        # Extended metadata
        self.metadata = {
            # Article metadata
            "source": self.source,
            "url": self.url,
            "author": article.get("metadata", {}).get("author", ""),
            "published_at": self.published_at,
            
            # Content identification
            "content_hash": content_hash,
            "sources": [self.url] if self.url else [],
            
            # Analysis metadata
            "analyzed_at": self.analyzed_at,
            "model_version": self.model_version,
            "confidence": self.confidence,
            
            # Additional metadata from article
            "image_url": article.get("metadata", {}).get("urlToImage", article.get("metadata", {}).get("top_image", "")),
            "keywords": article.get("metadata", {}).get("keywords", []),
        }
        
        # Add any additional fields from the article metadata
        for key, value in article.get("metadata", {}).items():
            if key not in self.metadata:
                self.metadata[key] = value
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage"""
        return {
            "id": self.id,
            "title": self.title,
            "content": self.content,
            "processed_content": self.processed_content,
            "sentiment": self.sentiment,
            "subject": self.subject,
            "topics": self.topics,
            "entities": self.entities,
            "causal_relationships": self.causal_relationships,
            "summary": self.summary,
            "confidence": self.confidence,
            "model_version": self.model_version,
            "published_at": self.published_at,
            "analyzed_at": self.analyzed_at,
            "source": self.source,
            "url": self.url,
            "metadata": self.metadata
        }
    
    def to_card_dict(self) -> Dict[str, Any]:
        """Convert to simplified dictionary for card display"""
        return {
            "id": self.id,
            "title": self.title,
            "summary": self.summary,
            "sentiment": {
                "score": self.sentiment["compound_score"],
                "category": self.sentiment["category"]
            },
            "entities": [{"name": entity["name"], "type": entity["type"]}
                         for entity in self.entities[:3]],  # Limit to top 3
            "topics": self.topics[:2],  # Limit to top 2
            "published_at": self.published_at,
            "source": self.source,
            "url": self.url
        }
    
    def __str__(self):
        """String representation with pretty formatting"""
        return json.dumps(self.to_dict(), indent=4, ensure_ascii=False)
