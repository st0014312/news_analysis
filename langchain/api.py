#!/usr/bin/env python3
"""
Financial News Analysis API
RESTful API with Protobuf payloads for the Flutter mobile application
"""

import os
import json
import logging
import asyncio
import uvicorn
from fastapi import FastAPI, HTTPException, Depends, Query, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional, Union
from datetime import datetime, timedelta
import jwt
from jwt.exceptions import PyJWTError
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import auth

from news_analysis_chain import analyze_news
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
        logging.FileHandler("api.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize components
vector_db = NewsVectorDB()
firebase_client = FirebaseClient(key_path="news-analysis-c63db-firebase-adminsdk-fbsvc-bc62247bc2.json")
aggregator = NewsAggregator()

# Initialize FastAPI app
app = FastAPI(
    title="Financial News Analysis API",
    description="API for the Financial News Analysis Flutter application",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# JWT Configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        if client_id in self.active_connections:
            del self.active_connections[client_id]

    async def send_personal_message(self, message: str, client_id: str):
        if client_id in self.active_connections:
            await self.active_connections[client_id].send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections.values():
            await connection.send_text(message)


manager = ConnectionManager()

# Pydantic models for request/response
class TokenData(BaseModel):
    user_id: Optional[str] = None


class Token(BaseModel):
    access_token: str
    token_type: str
    user: Dict[str, Any]


class UserCreate(BaseModel):
    email: str
    password: str
    display_name: str


class UserLogin(BaseModel):
    email: str
    password: str


class NewsFilter(BaseModel):
    sentiment: Optional[str] = None
    entity: Optional[str] = None
    from_date: Optional[str] = None
    to_date: Optional[str] = None
    source: Optional[str] = None


class NewsItem(BaseModel):
    id: str
    title: str
    summary: str
    sentiment: Dict[str, Any]
    entities: List[Dict[str, Any]]
    published_at: str
    source: str


class NewsDetail(BaseModel):
    id: str
    title: str
    content: str
    summary: str
    sentiment: Dict[str, Any]
    entities: List[Dict[str, Any]]
    topics: List[str]
    published_at: str
    analyzed_at: str
    source: str
    url: str
    related_articles: Optional[List[Dict[str, Any]]] = None


class NewsFeed(BaseModel):
    items: List[NewsItem]
    total: int
    page: int
    limit: int


class SubscriptionPlan(BaseModel):
    id: str
    name: str
    price: float
    interval: str
    features: List[str]


class SubscriptionPlans(BaseModel):
    plans: List[SubscriptionPlan]


class SubscriptionCreate(BaseModel):
    plan_id: str
    payment_method: str


class NotificationSettings(BaseModel):
    sentiment_threshold: float = Field(0.7, ge=0, le=1)
    relevance_threshold: float = Field(0.5, ge=0, le=1)
    watchlist: List[str] = []


class UserPreferences(BaseModel):
    notification_settings: NotificationSettings
    theme: str = "light"
    default_view: str = "feed"


# Authentication functions
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        token_data = TokenData(user_id=user_id)
    except PyJWTError:
        raise credentials_exception
    
    user = firebase_client.get_user(token_data.user_id)
    if user is None:
        raise credentials_exception
    return user


# API Routes
@app.post("/api/auth/register", response_model=Token)
async def register_user(user_data: UserCreate):
    try:
        # Create user in Firebase Auth
        user_record = auth.create_user(
            email=user_data.email,
            password=user_data.password,
            display_name=user_data.display_name
        )
        
        # Create user document in Firestore
        user_id = user_record.uid
        user_doc = {
            "email": user_data.email,
            "display_name": user_data.display_name,
            "created_at": datetime.utcnow().isoformat(),
            "last_login": datetime.utcnow().isoformat(),
            "subscription_tier": "free",
            "preferences": {
                "notification_settings": {
                    "sentiment_threshold": 0.7,
                    "relevance_threshold": 0.5,
                    "watchlist": []
                },
                "theme": "light",
                "default_view": "feed"
            }
        }
        firebase_client.save_user(user_id, user_doc)
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user_id}, expires_delta=access_token_expires
        )
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": user_id,
                "email": user_data.email,
                "display_name": user_data.display_name,
                "subscription_tier": "free"
            }
        }
    except Exception as e:
        logger.error(f"Registration error: {str(e)}")
        raise HTTPException(
            status_code=400,
            detail=f"Registration failed: {str(e)}"
        )


@app.post("/api/auth/login", response_model=Token)
async def login(user_data: UserLogin):
    try:
        # Verify credentials with Firebase Auth
        user = auth.get_user_by_email(user_data.email)
        
        # In a real implementation, you would verify the password
        # Firebase Admin SDK doesn't support password verification directly
        # You would typically use Firebase Authentication REST API for this
        
        # Update last login
        user_doc = firebase_client.get_user(user.uid)
        if user_doc:
            user_doc["last_login"] = datetime.utcnow().isoformat()
            firebase_client.save_user(user.uid, user_doc)
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.uid}, expires_delta=access_token_expires
        )
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": {
                "id": user.uid,
                "email": user.email,
                "display_name": user.display_name,
                "subscription_tier": user_doc.get("subscription_tier", "free") if user_doc else "free"
            }
        }
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password"
        )


@app.get("/api/news", response_model=NewsFeed)
async def get_news_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    sentiment: Optional[str] = None,
    entity: Optional[str] = None,
    from_date: Optional[str] = None,
    to_date: Optional[str] = None,
    sort: str = "date",
    order: str = "desc",
    current_user: Dict = Depends(get_current_user)
):
    try:
        # Build filters
        filters = {}
        if sentiment:
            filters["sentiment.category"] = sentiment
        if entity:
            filters["entities"] = {"operator": "array-contains", "value": {"name": entity}}
        if from_date:
            filters["published_at"] = {"operator": ">=", "value": from_date}
        if to_date:
            filters["published_at"] = {"operator": "<=", "value": to_date}
        
        # Determine sort field
        sort_field = "analyzed_at"
        if sort == "relevance":
            sort_field = "confidence"
        elif sort == "sentiment":
            sort_field = "sentiment.compound_score"
        
        # Determine sort direction
        direction = "DESCENDING" if order.lower() == "desc" else "ASCENDING"
        
        # Query Firestore
        results = firebase_client.query_analyses(
            collection="news_articles",
            filters=filters,
            order_by=sort_field,
            limit=limit,
            direction=direction
        )
        
        # Calculate total (in a real implementation, you would use a more efficient approach)
        total = len(results)
        
        # Format results
        items = []
        for result in results:
            # Convert to NewsItem format
            items.append({
                "id": result.get("id", ""),
                "title": result.get("title", ""),
                "summary": result.get("summary", ""),
                "sentiment": result.get("sentiment", {}),
                "entities": result.get("entities", [])[:3],  # Limit to top 3 entities
                "published_at": result.get("published_at", ""),
                "source": result.get("source", "")
            })
        
        return {
            "items": items,
            "total": total,
            "page": page,
            "limit": limit
        }
    except Exception as e:
        logger.error(f"Error fetching news feed: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching news feed: {str(e)}"
        )


@app.get("/api/news/{news_id}", response_model=NewsDetail)
async def get_news_detail(
    news_id: str,
    current_user: Dict = Depends(get_current_user)
):
    try:
        # Get article from Firestore
        article = firebase_client.get_analysis_by_id("news_articles", news_id)
        if not article:
            raise HTTPException(
                status_code=404,
                detail=f"Article with ID {news_id} not found"
            )
        
        # Get related articles
        related_articles = vector_db.get_similar_articles(news_id, k=3)
        
        # Add related articles to response
        article["related_articles"] = related_articles
        
        return article
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching news detail: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching news detail: {str(e)}"
        )


@app.get("/api/subscriptions", response_model=SubscriptionPlans)
async def get_subscription_plans(current_user: Dict = Depends(get_current_user)):
    # In a real implementation, these would come from a database
    plans = [
        {
            "id": "free",
            "name": "Free",
            "price": 0.0,
            "interval": "month",
            "features": [
                "Basic news feed",
                "Limited article access",
                "Standard analysis"
            ]
        },
        {
            "id": "premium_monthly",
            "name": "Premium Monthly",
            "price": 9.99,
            "interval": "month",
            "features": [
                "Unlimited news feed",
                "Full article access",
                "Advanced sentiment analysis",
                "Real-time notifications",
                "Portfolio dashboard"
            ]
        },
        {
            "id": "premium_yearly",
            "name": "Premium Yearly",
            "price": 99.99,
            "interval": "year",
            "features": [
                "Unlimited news feed",
                "Full article access",
                "Advanced sentiment analysis",
                "Real-time notifications",
                "Portfolio dashboard",
                "Batch analysis requests",
                "20% discount over monthly"
            ]
        }
    ]
    
    return {"plans": plans}


@app.post("/api/subscriptions")
async def create_subscription(
    subscription_data: SubscriptionCreate,
    current_user: Dict = Depends(get_current_user)
):
    try:
        # In a real implementation, you would integrate with Stripe or another payment processor
        
        # Get plan details
        plans = {
            "free": {"tier": "free", "price": 0.0, "interval": "month"},
            "premium_monthly": {"tier": "premium", "price": 9.99, "interval": "month"},
            "premium_yearly": {"tier": "premium", "price": 99.99, "interval": "year"}
        }
        
        plan = plans.get(subscription_data.plan_id)
        if not plan:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid plan ID: {subscription_data.plan_id}"
            )
        
        # Calculate expiry date
        if plan["interval"] == "month":
            end_date = (datetime.utcnow() + timedelta(days=30)).isoformat()
        else:
            end_date = (datetime.utcnow() + timedelta(days=365)).isoformat()
        
        # Create subscription
        subscription_id = firebase_client.save_subscription(
            user_id=current_user["id"],
            subscription_data={
                "tier": plan["tier"],
                "plan_id": subscription_data.plan_id,
                "payment_method": subscription_data.payment_method,
                "price": plan["price"],
                "interval": plan["interval"],
                "start_date": datetime.utcnow().isoformat(),
                "end_date": end_date,
                "auto_renew": True,
                "status": "active",
                "payment_history": [
                    {
                        "amount": plan["price"],
                        "date": datetime.utcnow().isoformat(),
                        "status": "succeeded"
                    }
                ]
            }
        )
        
        return {
            "subscription_id": subscription_id,
            "status": "active",
            "tier": plan["tier"],
            "start_date": datetime.utcnow().isoformat(),
            "end_date": end_date
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating subscription: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error creating subscription: {str(e)}"
        )


@app.get("/api/user/preferences", response_model=UserPreferences)
async def get_user_preferences(current_user: Dict = Depends(get_current_user)):
    try:
        preferences = current_user.get("preferences", {})
        if not preferences:
            # Default preferences
            preferences = {
                "notification_settings": {
                    "sentiment_threshold": 0.7,
                    "relevance_threshold": 0.5,
                    "watchlist": []
                },
                "theme": "light",
                "default_view": "feed"
            }
        
        return preferences
    except Exception as e:
        logger.error(f"Error fetching user preferences: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error fetching user preferences: {str(e)}"
        )


@app.put("/api/user/preferences")
async def update_user_preferences(
    preferences: UserPreferences,
    current_user: Dict = Depends(get_current_user)
):
    try:
        # Update user preferences
        current_user["preferences"] = preferences.dict()
        firebase_client.save_user(current_user["id"], current_user)
        
        return {"status": "success", "message": "Preferences updated successfully"}
    except Exception as e:
        logger.error(f"Error updating user preferences: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error updating user preferences: {str(e)}"
        )


@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket, client_id)
    try:
        while True:
            data = await websocket.receive_text()
            # Process received data
            await manager.send_personal_message(f"You sent: {data}", client_id)
    except WebSocketDisconnect:
        manager.disconnect(client_id)


# Background task for sending notifications
async def send_notifications():
    while True:
        try:
            # Get users with watchlists
            users = firebase_client.query_analyses(
                collection="users",
                filters={"preferences.notification_settings.watchlist": {"operator": "array-contains-any", "value": ["*"]}},
                limit=100
            )
            
            for user in users:
                # Get user's watchlist and thresholds
                watchlist = user.get("preferences", {}).get("notification_settings", {}).get("watchlist", [])
                sentiment_threshold = user.get("preferences", {}).get("notification_settings", {}).get("sentiment_threshold", 0.7)
                
                if not watchlist:
                    continue
                
                # Get recent news for watchlist items
                for symbol in watchlist:
                    # Get news from the last hour
                    from_date = (datetime.utcnow() - timedelta(hours=1)).isoformat()
                    
                    news_items = firebase_client.query_analyses(
                        collection="news_articles",
                        filters={
                            "entities": {"operator": "array-contains", "value": {"name": symbol}},
                            "analyzed_at": {"operator": ">=", "value": from_date},
                            "sentiment.compound_score": {"operator": ">=", "value": sentiment_threshold}
                        },
                        limit=5
                    )
                    
                    # Send notifications for each news item
                    for news in news_items:
                        # Check if notification already sent
                        existing_notifications = firebase_client.query_analyses(
                            collection="notifications",
                            filters={
                                "user_id": user["id"],
                                "article_id": news["id"]
                            },
                            limit=1
                        )
                        
                        if not existing_notifications:
                            # Create notification
                            notification_id = firebase_client.save_notification(
                                user_id=user["id"],
                                article_id=news["id"],
                                notification_data={
                                    "title": f"{symbol}: {news['title']}",
                                    "body": news["summary"],
                                    "type": "alert",
                                    "read": False
                                }
                            )
                            
                            # Send to WebSocket if connected
                            if user["id"] in manager.active_connections:
                                await manager.send_personal_message(
                                    json.dumps({
                                        "type": "notification",
                                        "notification_id": notification_id,
                                        "title": f"{symbol}: {news['title']}",
                                        "body": news["summary"],
                                        "article_id": news["id"]
                                    }),
                                    user["id"]
                                )
        except Exception as e:
            logger.error(f"Error in notification task: {str(e)}")
        
        # Wait before checking again
        await asyncio.sleep(60)  # Check every minute


@app.on_event("startup")
async def startup_event():
    # Start background tasks
    asyncio.create_task(send_notifications())


def start():
    """Start the API server"""
    uvicorn.run("api:app", host="0.0.0.0", port=8000, reload=True)


if __name__ == "__main__":
    start()