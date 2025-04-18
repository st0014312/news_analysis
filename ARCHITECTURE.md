# Financial News Analysis System Architecture

## System Overview

This document outlines the architecture for a production-ready Flutter mobile application integrated with a Python/LangChain news analysis backend. The system provides real-time financial news analysis with sentiment scoring, entity recognition, and personalized alerts.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        News Analysis Backend                         │
├─────────────┬─────────────┬────────────────┬────────────────────────┤
│ News Sources│ LangChain   │ Vector Database│ Firebase Integration   │
│ - NewsAPI   │ Processing  │ - Embeddings   │ - Authentication       │
│ - RSS Feeds │ - Chunking  │ - Semantic     │ - Firestore Database   │
│ - Twitter   │ - Analysis  │   Search       │ - Cloud Functions      │
└─────┬───────┴──────┬──────┴────────┬───────┴────────────┬───────────┘
      │              │               │                    │
      │              │               │                    │
┌─────▼──────────────▼───────────────▼────────────────────▼───────────┐
│                           API Layer                                  │
│ - RESTful Endpoints with Protobuf                                    │
│ - WebSocket for Real-time Updates                                    │
│ - JWT Authentication                                                 │
│ - Caching Layer                                                      │
└─────────────────────────────────┬───────────────────────────────────┘
                                  │
                                  │
┌─────────────────────────────────▼───────────────────────────────────┐
│                      Flutter Mobile Application                      │
├─────────────┬─────────────┬────────────────┬────────────────────────┤
│ Presentation│ Business    │ Data           │ Infrastructure          │
│ - Screens   │ Logic       │ - Repositories │ - Network               │
│ - Widgets   │ - BLoC      │ - Models       │ - Local Storage         │
│ - Themes    │ - Services  │ - DTOs         │ - Authentication        │
└─────────────┴─────────────┴────────────────┴────────────────────────┘
```

## Component Details

### 1. News Analysis Backend

#### News Sources Module
- **NewsAggregator**: Fetches news from multiple sources
  - NewsAPI integration for mainstream financial news
  - RSS feed parser for specialized financial feeds
  - Twitter API integration for real-time market sentiment
  - URL deduplication to prevent redundant analysis

#### LangChain Processing Pipeline
- **Document Processing**:
  - Chunking strategy for long-form content
  - Text cleaning and normalization
- **Analysis Chain**:
  - Sentiment analysis (compound score + categorical)
  - Entity recognition (stock tickers, companies, sectors)
  - Context-aware summarization
  - Causal relationship extraction

#### Vector Database
- **Embedding Generation**: Using HuggingFace embeddings
- **Semantic Search**: For finding related news articles
- **Hybrid Search**: Combining metadata filtering with semantic search

#### Firebase Integration
- **Authentication**: User management and security
- **Firestore Database**: Structured storage for all system data
- **Cloud Functions**: Serverless processing for background tasks

### 2. API Layer

#### RESTful API
- **Endpoints**:
  - `/news`: Get news feed with filtering options
  - `/news/{id}`: Get detailed news analysis
  - `/user/preferences`: Manage user preferences
  - `/subscriptions`: Handle premium subscriptions
- **Protobuf Payloads**: Efficient binary serialization

#### WebSocket
- Real-time updates for news analysis
- Push notifications for subscribed topics

#### Authentication
- JWT-based authentication with refresh tokens
- Role-based access control

#### Caching
- Redis-based caching for frequent queries
- Cache invalidation strategy

### 3. Flutter Mobile Application

#### Presentation Layer
- **Screens**:
  - News Feed Screen
  - Detail View Screen
  - Profile Screen
  - Subscription Management
  - Settings Screen
- **Widgets**:
  - News Card
  - Sentiment Badge
  - Stock Price Preview
  - Filter Controls

#### Business Logic Layer
- **BLoC Pattern**:
  - NewsBloc
  - AuthBloc
  - SubscriptionBloc
  - PreferencesBloc
- **Services**:
  - NewsService
  - AuthService
  - AnalyticsService
  - NotificationService

#### Data Layer
- **Repositories**:
  - NewsRepository
  - UserRepository
  - SubscriptionRepository
- **Models**:
  - News
  - User
  - Subscription
  - Preferences

#### Infrastructure Layer
- **Network**:
  - API Client
  - WebSocket Client
  - Certificate Pinning
- **Local Storage**:
  - Hive Database
  - Secure Storage
  - Image Caching

## Database Schema

### Firestore Collections

#### `users` Collection
```
users/{userId}
  - email: string
  - displayName: string
  - createdAt: timestamp
  - lastLogin: timestamp
  - subscriptionTier: string (free, premium)
  - subscriptionExpiry: timestamp
  - preferences: {
      alertThresholds: {
        sentiment: number,
        relevance: number
      },
      watchlist: [string] (stock tickers)
    }
  - deviceTokens: [string]
```

#### `news_articles` Collection
```
news_articles/{articleId}
  - title: string
  - content: string
  - summary: string
  - publishedAt: timestamp
  - analyzedAt: timestamp
  - source: string
  - url: string
  - sentiment: {
      score: number (-1 to 1),
      category: string (positive, negative, neutral)
    }
  - entities: [
      {
        name: string,
        type: string (company, ticker, person, sector),
        relevance: number
      }
    ]
  - topics: [string]
  - modelVersion: string
```

#### `entity_relationships` Collection
```
entity_relationships/{relationshipId}
  - entityA: string
  - entityB: string
  - relationshipType: string (affects, owns, competes)
  - strength: number
  - articles: [string] (article IDs)
```

#### `user_subscriptions` Collection
```
user_subscriptions/{subscriptionId}
  - userId: string
  - tier: string
  - startDate: timestamp
  - endDate: timestamp
  - paymentMethod: string
  - autoRenew: boolean
  - paymentHistory: [
      {
        amount: number,
        date: timestamp,
        status: string
      }
    ]
```

#### `notifications` Collection
```
notifications/{notificationId}
  - userId: string
  - articleId: string
  - title: string
  - body: string
  - sentAt: timestamp
  - readAt: timestamp
  - type: string (alert, update)
```

## API Documentation

### News Feed API

#### GET /api/news
Get a paginated list of news articles with filtering options.

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20)
- `sentiment`: Filter by sentiment (positive, negative, neutral)
- `entity`: Filter by entity (e.g., AAPL, TSLA)
- `fromDate`: Filter by date (ISO format)
- `toDate`: Filter by date (ISO format)
- `sort`: Sort field (relevance, date, sentiment)
- `order`: Sort order (asc, desc)

**Response:**
```json
{
  "items": [
    {
      "id": "string",
      "title": "string",
      "summary": "string",
      "sentiment": {
        "score": 0.75,
        "category": "positive"
      },
      "entities": [
        {
          "name": "AAPL",
          "type": "ticker"
        }
      ],
      "publishedAt": "2023-04-15T12:00:00Z",
      "source": "string"
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

#### GET /api/news/{id}
Get detailed information about a specific news article.

**Response:**
```json
{
  "id": "string",
  "title": "string",
  "content": "string",
  "summary": "string",
  "sentiment": {
    "score": 0.75,
    "category": "positive",
    "details": {
      "positive_aspects": ["string"],
      "negative_aspects": ["string"],
      "neutral_aspects": ["string"]
    }
  },
  "entities": [
    {
      "name": "AAPL",
      "type": "ticker",
      "relevance": 0.9,
      "sentiment": 0.8
    }
  ],
  "topics": ["earnings", "innovation"],
  "publishedAt": "2023-04-15T12:00:00Z",
  "analyzedAt": "2023-04-15T12:05:00Z",
  "source": "string",
  "url": "string",
  "relatedArticles": [
    {
      "id": "string",
      "title": "string",
      "similarity": 0.85
    }
  ]
}
```

### User API

#### POST /api/auth/register
Register a new user.

**Request:**
```json
{
  "email": "string",
  "password": "string",
  "displayName": "string"
}
```

#### POST /api/auth/login
Authenticate a user.

**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "token": "string",
  "refreshToken": "string",
  "user": {
    "id": "string",
    "email": "string",
    "displayName": "string",
    "subscriptionTier": "string"
  }
}
```

### Subscription API

#### GET /api/subscriptions
Get available subscription plans.

**Response:**
```json
{
  "plans": [
    {
      "id": "string",
      "name": "string",
      "price": 9.99,
      "interval": "month",
      "features": ["string"]
    }
  ]
}
```

#### POST /api/subscriptions
Subscribe to a plan.

**Request:**
```json
{
  "planId": "string",
  "paymentMethod": "string"
}
```

## Implementation Roadmap

### Phase 1: Core Backend Development
1. Enhance news ingestion with URL deduplication
2. Implement chunking strategy for long-form content
3. Improve sentiment analysis with compound scoring
4. Develop entity recognition focusing on financial entities
5. Create Firestore database schema

### Phase 2: API Development
1. Design and implement RESTful API with Protobuf
2. Set up authentication flow with JWT
3. Implement WebSocket for real-time updates
4. Create caching layer for frequent queries

### Phase 3: Flutter App Development
1. Set up project structure with BLoC pattern
2. Implement news feed interface with filtering
3. Create detail view with progressive loading
4. Develop offline mode with Hive-based caching

### Phase 4: Premium Features
1. Implement Stripe payment integration
2. Set up push notification system
3. Create portfolio dashboard
4. Develop batch analysis for watchlists

### Phase 5: Quality Assurance
1. Implement performance optimizations
2. Set up security measures
3. Ensure GDPR compliance
4. Create comprehensive test suite