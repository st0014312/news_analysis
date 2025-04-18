# Financial News Analysis System

A production-ready Flutter mobile application integrated with a Python/LangChain news analysis backend.

## Project Overview

This project consists of two main components:

1. **LangChain Backend**: A Python-based backend that fetches, processes, and analyzes financial news using LangChain and various NLP techniques.
2. **Flutter Mobile App**: A cross-platform mobile application that displays the analyzed news with advanced features like sentiment analysis, entity recognition, and personalized alerts.

## System Architecture

The system follows a client-server architecture with the following components:

- **News Analysis Backend**: Fetches news from various sources, processes them using LangChain, and stores the results in Firestore.
- **API Layer**: RESTful API with Protobuf payloads for efficient communication between the backend and mobile app.
- **Flutter Mobile App**: User-facing application with features like news feed, detail view, and subscription management.

For more details, see the [ARCHITECTURE.md](ARCHITECTURE.md) file.

## Backend Features

- **News Ingestion**: Fetches news from NewsAPI, RSS feeds, and Twitter with URL deduplication.
- **Content Processing**: Implements chunking strategy for long-form content.
- **Sentiment Analysis**: Provides compound scores and categorical classification.
- **Entity Recognition**: Identifies stock tickers, companies, and market sectors.
- **Context-aware Summarization**: Preserves key financial metrics.
- **Causal Relationship Extraction**: Identifies relationships between market events.
- **Vector Database**: Enables semantic search for related articles.
- **Firestore Integration**: Stores structured data for efficient retrieval.

## Mobile App Features

- **News Feed Interface**: Infinite-scroll list with filtering and sorting options.
- **Detail View**: Progressive loading of content with semantic highlighting.
- **Subscription System**: Premium features with secure payment integration.
- **Offline Mode**: Hive-based local caching for offline access.
- **Push Notifications**: Real-time alerts for important news.
- **Portfolio Dashboard**: Visualizations of news impact on stocks.

## Project Structure

```
.
├── ARCHITECTURE.md           # Detailed system architecture
├── README.md                 # This file
├── langchain/                # Backend code
│   ├── api.py                # API layer
│   ├── firebase_store.py     # Firestore integration
│   ├── main.py               # Entry point
│   ├── news.py               # News data model
│   ├── news_analysis_chain.py # LangChain processing
│   ├── news_sources.py       # News aggregation
│   └── vector_db.py          # Vector database
└── flutter_app/              # Mobile application
    ├── assets/               # App assets
    └── lib/                  # Dart code
        ├── app/              # Application layer
        │   ├── blocs/        # BLoC state management
        │   ├── routes/       # Routing
        │   ├── screens/      # UI screens
        │   ├── theme/        # App theme
        │   └── app.dart      # App entry point
        ├── core/             # Core functionality
        │   ├── config/       # Configuration
        │   ├── services/     # Services
        │   └── utils/        # Utilities
        └── main.dart         # Entry point
```

## Getting Started

### Prerequisites

- Python 3.8+
- Flutter 3.0+
- Firebase account
- NewsAPI key
- OpenRouter API key (or other LLM provider)

### Backend Setup

1. Navigate to the backend directory:
   ```
   cd langchain
   ```

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Set up environment variables:
   ```
   cp .env.example .env
   ```
   Then edit the `.env` file with your API keys.

4. Run the backend:
   ```
   python main.py
   ```

### Flutter App Setup

1. Navigate to the Flutter app directory:
   ```
   cd flutter_app
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the app:
   ```
   flutter run
   ```

## API Documentation

The API follows RESTful principles with the following main endpoints:

- `GET /api/news`: Get a paginated list of news articles with filtering options.
- `GET /api/news/{id}`: Get detailed information about a specific news article.
- `GET /api/subscriptions`: Get available subscription plans.
- `POST /api/subscriptions`: Subscribe to a plan.

For more details, see the API documentation in the [ARCHITECTURE.md](ARCHITECTURE.md) file.

## Implementation Roadmap

1. **Phase 1**: Core Backend Development
   - Enhance news ingestion with URL deduplication
   - Implement chunking strategy for long-form content
   - Improve sentiment analysis with compound scoring
   - Develop entity recognition focusing on financial entities
   - Create Firestore database schema

2. **Phase 2**: API Development
   - Design and implement RESTful API with Protobuf
   - Set up authentication flow with JWT
   - Implement WebSocket for real-time updates
   - Create caching layer for frequent queries

3. **Phase 3**: Flutter App Development
   - Set up project structure with BLoC pattern
   - Implement news feed interface with filtering
   - Create detail view with progressive loading
   - Develop offline mode with Hive-based caching

4. **Phase 4**: Premium Features
   - Implement Stripe payment integration
   - Set up push notification system
   - Create portfolio dashboard
   - Develop batch analysis for watchlists

5. **Phase 5**: Quality Assurance
   - Implement performance optimizations
   - Set up security measures
   - Ensure GDPR compliance
   - Create comprehensive test suite

## License

This project is licensed under the MIT License - see the LICENSE file for details.