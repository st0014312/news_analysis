from langchain.prompts import PromptTemplate
from os import getenv
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser
import hashlib

from firebase_store import FirebaseClient
from news import News
from vector_db import NewsVectorDB

load_dotenv()
# store = NewsVectorDB()
store = FirebaseClient(key_path="news-analysis-c63db-firebase-adminsdk-fbsvc-bc62247bc2.json")


def create_analysis_chain():
    """Create analysis chain with OpenRouter API"""
    # 用 GPT-3.5 或 GPT-4 都可以
    # google/gemini-2.0-flash-thinking-exp:free
    # openai/gpt-4o-mini
    llm = ChatOpenAI(
        openai_api_key=getenv("OPENROUTER_API_KEY"),
        openai_api_base=getenv("OPENROUTER_BASE_URL"),
        model_name="google/gemini-2.0-flash-thinking-exp:free",
        temperature=0,
    )
    # 合併 prompt
    template = """You are a professional financial news analyst. Please analyze the following news article and extract structured insights based on the steps below:

    1. Determine whether this news article is a **valid financial article**. It should be considered **invalid** if it is:
    - An advertisement or sponsored content
    - Unrelated to the stock or currency market
    - Lacking any financially meaningful information

    2. If the article is valid, extract the following:
    a. Identify the **main stock, company, or financial market** this article is about (e.g., Tesla, USD, Nikkei 225).
    b. Analyze the **sentiment** of the article toward the main subject (positive / negative / neutral).
    c. Extract key **entities** mentioned (e.g., companies, products, financial terms).
    d. Identify topics discussed from the following list: [M&A, Earnings, Regulations, Innovation, Market Trends].

    Return the result in the following **JSON** format:
    {{
    "valid": "Yes" | "No",
    "subject": "e.g. Tesla, USD, Nikkei 225",
    "sentiment": "positive" | "negative" | "neutral",
    "entities": ["entity1", "entity2"],
    "topics": ["topic1", "topic2"],
    "reason": "Brief explanation of how you determined the sentiment and relevance.",
    "confidence": float (between 0 and 1),
    "summary": "Concise 1-2 sentence summary of the key points in the article."
    }}

    News Content:
    {news}
    """

    prompt = PromptTemplate(template=template, input_variables=["stock_symbol", "news"])
    analysis_chain = prompt | llm | StrOutputParser()
    return analysis_chain


def analyze_news(article):
    """Process news article through analysis pipeline with duplicate check"""
    # Proceed with analysis for new content
    analysis_chain = create_analysis_chain()
    result = analysis_chain.invoke({"news": article["content"]})
    try:
        import json

        # Clean the result string by removing markdown code block syntax if present
        cleaned_result = result
        if result.strip().startswith("```") and result.strip().endswith("```"):
            # Extract content between markdown code blocks
            cleaned_result = result.strip().split("```")[1]
            # Remove json label if present
            if cleaned_result.startswith("json"):
                cleaned_result = cleaned_result[4:].strip()

        analysis_data = json.loads(cleaned_result)
        doc = News(article, analysis_data)
        # Save the document to the vector store
        store.save_analysis("news_analysis", doc.id, doc.__dict__)
        return doc
    except Exception as e:
        print(f"❌ Analysis failed: {e}")
        print("Raw response:", result)
        return None
