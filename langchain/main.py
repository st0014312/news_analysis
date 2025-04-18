#!/usr/bin/env python3
"""
Financial News Analysis System
Main entry point for the LangChain news analysis backend
"""

import os
import argparse
import json
import logging
from datetime import datetime
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv

from news_analysis_chain import analyze_news, process_long_content
from news_sources import NewsAggregator
from vector_db import NewsVectorDB
from firebase_store import FirebaseClient

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("news_analysis.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize components
vector_db = NewsVectorDB()
firebase_client = FirebaseClient(key_path="news-analysis-c63db-firebase-adminsdk-fbsvc-bc62247bc2.json")
aggregator = NewsAggregator()


def analyze_stock_news(symbol: str, max_articles: int = 5) -> List[Dict[str, Any]]:
    """Analyze news for a specific stock symbol"""
    logger.info(f"Analyzing news for {symbol}")
    
    # Fetch news
    news_list = aggregator.get_all_news(symbol)
    logger.info(f"Fetched {len(news_list)} news articles for {symbol}")
    
    # Process and analyze each article
    results = []
    for i, news in enumerate(news_list[:max_articles], 1):
        logger.info(f"Processing article {i}/{min(max_articles, len(news_list))}: {news.get('title', 'No title')}")
        
        try:
            # Analyze the news
            result = analyze_news(news)
            
            if result:
                logger.info(f"Analysis complete: {result.subject} (Sentiment: {result.sentiment['category']})")
                results.append(result.to_dict())
                
                # Process entity relationships
                for entity in result.entities:
                    if entity["type"] in ["company", "ticker"] and entity["name"] != result.subject:
                        # Save relationship between main subject and this entity
                        firebase_client.save_entity_relationship(
                            entity_a=result.subject,
                            entity_b=entity["name"],
                            relationship_type="mentioned_with",
                            strength=entity.get("relevance", 0.5),
                            article_id=result.id
                        )
            else:
                logger.warning(f"Analysis failed for article {i}")
        except Exception as e:
            logger.error(f"Error analyzing article {i}: {str(e)}")
    
    return results


def search_news(query: str, filters: Optional[Dict[str, Any]] = None, limit: int = 5) -> List[Dict[str, Any]]:
    """Search for news articles using vector search"""
    logger.info(f"Searching for news with query: '{query}'")
    
    # Perform hybrid search
    results = vector_db.hybrid_search(query=query, filters=filters, k=limit)
    
    # Format results
    formatted_results = []
    for doc in results:
        article_id = doc.metadata.get("id")
        if article_id:
            # Get full article data from Firestore
            article_data = firebase_client.get_analysis_by_id("news_articles", article_id)
            if article_data:
                formatted_results.append(article_data)
            else:
                # Fallback to document metadata if Firestore lookup fails
                formatted_results.append({
                    "id": article_id,
                    "title": doc.metadata.get("title", "Unknown Title"),
                    "summary": doc.page_content[:200] + "...",
                    "sentiment": {
                        "score": doc.metadata.get("sentiment_score", 0),
                        "category": "neutral"
                    },
                    "source": doc.metadata.get("source", "Unknown")
                })
    
    logger.info(f"Found {len(formatted_results)} results for query: '{query}'")
    return formatted_results


def get_related_stocks(symbol: str, limit: int = 5) -> List[Dict[str, Any]]:
    """Get stocks related to the given symbol based on news co-occurrence"""
    logger.info(f"Finding stocks related to {symbol}")
    
    # Get entity relationships
    relationships = firebase_client.get_entity_relationships(symbol, limit=limit)
    
    # Format results
    related_stocks = []
    for rel in relationships:
        related_entity = rel["entity_a"] if rel["entity_b"] == symbol else rel["entity_b"]
        related_stocks.append({
            "symbol": related_entity,
            "relationship_type": rel["relationship_type"],
            "strength": rel["strength"],
            "article_count": len(rel["articles"])
        })
    
    logger.info(f"Found {len(related_stocks)} stocks related to {symbol}")
    return related_stocks


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Financial News Analysis System")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Analyze command
    analyze_parser = subparsers.add_parser("analyze", help="Analyze news for a stock")
    analyze_parser.add_argument("symbol", help="Stock symbol to analyze")
    analyze_parser.add_argument("--max", type=int, default=5, help="Maximum number of articles to analyze")
    
    # Search command
    search_parser = subparsers.add_parser("search", help="Search news articles")
    search_parser.add_argument("query", help="Search query")
    search_parser.add_argument("--limit", type=int, default=5, help="Maximum number of results")
    
    # Related stocks command
    related_parser = subparsers.add_parser("related", help="Find related stocks")
    related_parser.add_argument("symbol", help="Stock symbol to find related stocks for")
    related_parser.add_argument("--limit", type=int, default=5, help="Maximum number of results")
    
    args = parser.parse_args()
    
    if args.command == "analyze":
        results = analyze_stock_news(args.symbol, args.max)
        print(json.dumps(results, indent=2))
    elif args.command == "search":
        results = search_news(args.query, limit=args.limit)
        print(json.dumps(results, indent=2))
    elif args.command == "related":
        results = get_related_stocks(args.symbol, args.limit)
        print(json.dumps(results, indent=2))
    else:
        # Default behavior - analyze Tesla news
        symbol = "TSLA"
        print(f"Analyzing news for {symbol}...")
        results = analyze_stock_news(symbol)
        print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
