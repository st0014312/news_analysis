import streamlit as st
from vector_db import NewsVectorDB
import pandas as pd

# Initialize vector database connection
db = NewsVectorDB()

# Configure Streamlit page
st.set_page_config(
    page_title="News Analyst Dashboard",
    page_icon="📈",
    layout="wide"
)

# Main interface
st.title("News Analysis Dashboard")
st.markdown("### Semantic search and analysis of news articles")

# Search controls
col1, col2 = st.columns([3, 1])
with col1:
    query = st.text_input("Search news articles", placeholder="Enter keywords or phrases...")

with col2:
    result_count = st.slider("Results to show", 1, 20, 5)

# Filters sidebar
with st.sidebar:
    st.header("Filter Options")
    source_filter = st.selectbox("Content Source", ["news_api", "all_sources"], index=0)
    date_filter = st.date_input("Date range", [])
    validated_only = st.checkbox("Show only validated content", True)

if query:
    # Build search filters
    filters = {}
    if source_filter != "all_sources":
        filters["source"] = source_filter
    if validated_only:
        filters["valid"] = "Yes"
    
    # Execute search
    results = db.hybrid_search(query, k=result_count)
    
    # Display results
    if results:
        # Create dataframe for tabular view
        df = pd.DataFrame([{
            "Title": doc.metadata.get("title", "Untitled"),
            "Source": doc.metadata.get("source", "Unknown"),
            "Date": doc.metadata.get("published_at", "N/A"),
            "Sentiment": doc.metadata.get("sentiment", "Neutral"),
            "Content Preview": doc.page_content[:150] + "..."
        } for doc in results])
        
        # Show metrics
        col1, col2, col3 = st.columns(3)
        col1.metric("Total Results", len(results))
        col2.metric("Primary Source", df['Source'].mode()[0])
        col3.metric("Avg Sentiment", df['Sentiment'].value_counts().idxmax())
        
        # Display interactive table
        st.dataframe(
            df,
            use_container_width=True,
            hide_index=True,
            column_config={
                "Content Preview": st.column_config.TextColumn(
                    width="large"
                )
            }
        )
        
        # Detailed view in expanders
        st.divider()
        st.subheader("Article Details")
        for doc in results:
            with st.expander(f"{doc.metadata.get('title', 'Untitled Article')}"):
                st.markdown(f"**Source**: {doc.metadata.get('source')}")
                st.markdown(f"**Date**: {doc.metadata.get('date')}")
                st.markdown(f"**Sentiment**: {doc.metadata.get('sentiment')}")
                st.markdown("**Content**")
                st.write(doc.page_content)
    else:
        st.warning("No matching articles found")
else:
    st.info("Enter a search query to analyze news content")