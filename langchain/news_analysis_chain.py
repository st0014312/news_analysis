from langchain.prompts import PromptTemplate
from os import getenv
from dotenv import load_dotenv
from langchain_openai import ChatOpenAI
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser, JsonOutputParser
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.chains import SequentialChain, LLMChain
from pydantic import BaseModel, Field
from typing import List, Dict, Optional, Union, Any
import hashlib
import json
from datetime import datetime

from firebase_store import FirebaseClient
from news import News
from vector_db import NewsVectorDB

load_dotenv()
# Initialize storage
vector_db = NewsVectorDB()
firebase_store = FirebaseClient(key_path="news-analysis-c63db-firebase-adminsdk-fbsvc-bc62247bc2.json")


class SentimentAnalysisOutput(BaseModel):
    """Output schema for sentiment analysis"""
    compound_score: float = Field(description="Sentiment score between -1 (negative) and 1 (positive)")
    category: str = Field(description="Categorical sentiment: positive, negative, or neutral")
    positive_aspects: List[str] = Field(description="Key positive aspects mentioned in the article")
    negative_aspects: List[str] = Field(description="Key negative aspects mentioned in the article")
    neutral_aspects: List[str] = Field(description="Key neutral or factual aspects mentioned in the article")


class EntityOutput(BaseModel):
    """Output schema for entity recognition"""
    name: str = Field(description="Name of the entity")
    type: str = Field(description="Type of entity: company, ticker, person, product, sector, etc.")
    relevance: float = Field(description="Relevance score between 0 and 1")
    sentiment: Optional[float] = Field(description="Entity-specific sentiment between -1 and 1")


class CausalRelationOutput(BaseModel):
    """Output schema for causal relationships"""
    cause: str = Field(description="The cause event or entity")
    effect: str = Field(description="The effect or outcome")
    confidence: float = Field(description="Confidence in this causal relationship (0-1)")
    explanation: str = Field(description="Brief explanation of the causal relationship")


class NewsAnalysisOutput(BaseModel):
    """Output schema for the complete news analysis"""
    valid: bool = Field(description="Whether this is a valid financial article")
    subject: str = Field(description="Main subject of the article (company, ticker, market)")
    sentiment: SentimentAnalysisOutput = Field(description="Detailed sentiment analysis")
    entities: List[EntityOutput] = Field(description="Entities mentioned in the article")
    topics: List[str] = Field(description="Topics discussed from predefined list")
    causal_relationships: List[CausalRelationOutput] = Field(description="Extracted causal relationships")
    summary: str = Field(description="Concise summary preserving key financial metrics")
    confidence: float = Field(description="Overall confidence in the analysis (0-1)")
    model_version: str = Field(description="Version of the analysis model used")


def create_text_chunker():
    """Create a text chunker for long-form content"""
    return RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
        separators=["\n\n", "\n", ". ", " ", ""]
    )


def create_analysis_chain():
    """Create enhanced analysis chain with structured output parsing"""
    # Use a more capable model for complex analysis
    llm = ChatOpenAI(
        openai_api_key=getenv("OPENROUTER_API_KEY"),
        openai_api_base=getenv("OPENROUTER_BASE_URL"),
        model_name="openai/gpt-4o-mini",  # Using a more capable model for complex analysis
        temperature=0,
    )
    
    # Enhanced prompt with more detailed analysis requirements
    template = """You are a professional financial news analyst with expertise in sentiment analysis, entity recognition, and causal relationship extraction.
    Analyze the following news article and extract structured insights:

    1. Determine whether this is a valid financial article. It's invalid if it's:
       - An advertisement or sponsored content
       - Unrelated to financial markets
       - Lacking financially meaningful information

    2. For valid articles, perform these analyses:
       a. SENTIMENT ANALYSIS:
          - Calculate a compound sentiment score (-1 to 1)
          - Categorize as positive/negative/neutral
          - List key positive, negative, and neutral aspects

       b. ENTITY RECOGNITION:
          - Identify companies, stock tickers, people, products, sectors
          - Assign relevance scores (0-1) to each entity
          - Calculate entity-specific sentiment where applicable

       c. TOPIC CLASSIFICATION:
          - Identify topics from: [M&A, Earnings, Regulations, Innovation, Market Trends,
            Economic Indicators, Central Bank Policies, Geopolitical Events, Corporate Governance]

       d. CAUSAL RELATIONSHIP EXTRACTION:
          - Identify cause-effect relationships between market events
          - Assign confidence scores to each relationship
          - Provide brief explanations

       e. SUMMARY:
          - Create a concise summary preserving key financial metrics
          - Include specific numbers, percentages, and financial terms

    News Content:
    {news}

    Respond with a JSON object matching the following schema:
    {format_instructions}
    """

    # Create parser with the output schema
    parser = JsonOutputParser(pydantic_object=NewsAnalysisOutput)
    
    # Create the prompt with format instructions
    prompt = PromptTemplate(
        template=template,
        input_variables=["news"],
        partial_variables={"format_instructions": parser.get_format_instructions()}
    )
    
    # Create the analysis chain
    analysis_chain = prompt | llm | parser
    return analysis_chain


def process_long_content(content):
    """Process long-form content by chunking and analyzing each chunk"""
    # Create text chunker
    text_splitter = create_text_chunker()
    
    # Split the content into chunks
    chunks = text_splitter.split_text(content)
    
    # If content is short enough, return it as is
    if len(chunks) <= 1:
        return content
    
    # For longer content, create a summary chain
    llm = ChatOpenAI(
        openai_api_key=getenv("OPENROUTER_API_KEY"),
        openai_api_base=getenv("OPENROUTER_BASE_URL"),
        model_name="google/gemini-2.0-flash-thinking-exp:free",
        temperature=0,
    )
    
    summary_template = """Summarize the following chunk of a financial news article, preserving all key financial metrics,
    numbers, percentages, and important facts:

    {chunk}
    
    Summary:"""
    
    summary_prompt = PromptTemplate(template=summary_template, input_variables=["chunk"])
    summary_chain = summary_prompt | llm | StrOutputParser()
    
    # Process each chunk and collect summaries
    chunk_summaries = []
    for chunk in chunks:
        summary = summary_chain.invoke({"chunk": chunk})
        chunk_summaries.append(summary)
    
    # Combine the summaries
    combined_summary = "\n\n".join(chunk_summaries)
    
    # If the combined summary is still too long, recursively summarize it
    if len(combined_summary) > 4000:
        return process_long_content(combined_summary)
    
    return combined_summary


def analyze_news(article):
    """Enhanced process for news article analysis with chunking for long content"""
    try:
        # Check if content is too long and needs chunking
        content = article["content"]
        if len(content) > 4000:
            processed_content = process_long_content(content)
            article["processed_content"] = processed_content
        else:
            article["processed_content"] = content
        
        # Proceed with analysis
        analysis_chain = create_analysis_chain()
        result = analysis_chain.invoke({"news": article["processed_content"]})
        
        # Add metadata
        result["model_version"] = "1.0.0"
        result["analyzed_at"] = datetime.utcnow().isoformat()
        
        # Create document for vector storage
        doc = News(article, result)
        
        # Save to Firebase
        firebase_store.save_analysis("news_articles", doc.id, doc.__dict__)
        
        # Save to vector database for semantic search
        vector_db.store_documents([Document(
            page_content=article["processed_content"],
            metadata={
                "id": doc.id,
                "title": doc.title,
                "sentiment_score": result["sentiment"]["compound_score"],
                "entities": [entity["name"] for entity in result["entities"]],
                "topics": result["topics"]
            }
        )])
        
        return doc
    except Exception as e:
        print(f"❌ Analysis failed: {e}")
        import traceback
        traceback.print_exc()
        return None
