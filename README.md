# News Analysis Dashboard

## Overview
The News Analysis Dashboard is a web application designed to analyze financial news articles using semantic search and machine learning. It provides insights such as sentiment analysis, key entities, and topics discussed in the articles. The application is built using Python and integrates tools like LangChain, Firebase, and Streamlit.

## Features
- **Semantic Search**: Search for news articles using keywords or phrases.
- **Sentiment Analysis**: Analyze the sentiment of news articles (positive, negative, or neutral).
- **Entity Extraction**: Identify key entities mentioned in the articles.
- **Topic Categorization**: Classify articles into topics like M&A, Earnings, Regulations, etc.
- **Interactive Dashboard**: Visualize and explore results in a user-friendly interface.

## Installation

### Prerequisites
- Python 3.12 or higher
- Firebase account and credentials
- API keys for OpenRouter, NewsAPI, and Twitter

### Steps
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd langchain
   ```
2. Install dependencies:
   ```bash
   uv install
   ```
3. Set up environment variables:
   Create a `.env` file in the `langchain` folder and add the following:
   ```env
   OPENROUTER_API_KEY=<your_openrouter_api_key>
   OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
   NEWS_API_KEY=<your_news_api_key>
   TWITTER_BEARER=<your_twitter_bearer_token>
   ```
4. Add your Firebase credentials:
   Place your Firebase JSON credentials file in the `langchain` folder and update the path in `news_analysis_chain.py`.

## Usage
1. Start the Streamlit application:
   ```bash
   streamlit run langchain/app.py
   ```
2. Open the application in your browser at `http://localhost:8501`.
3. Use the search bar to find news articles and explore the analysis results.

## Project Structure
- `langchain/app.py`: Streamlit application for the dashboard.
- `langchain/news_analysis_chain.py`: Defines the analysis pipeline using LangChain.
- `langchain/news_sources.py`: Fetches news articles from various sources (NewsAPI, RSS, Twitter).
- `langchain/vector_db.py`: Handles vector database operations for semantic search.
- `langchain/firebase_store.py`: Manages data storage in Firebase.
- `langchain/main.py`: Example script for fetching and analyzing news articles.

## Dependencies
Key dependencies include:
- `langchain`
- `firebase-admin`
- `streamlit`
- `sentence-transformers`
- `newspaper3k`

Refer to `pyproject.toml` for the full list of dependencies.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments
- [LangChain](https://langchain.com/)
- [Streamlit](https://streamlit.io/)
- [Firebase](https://firebase.google.com/)

---
Feel free to contribute to this project by submitting issues or pull requests.