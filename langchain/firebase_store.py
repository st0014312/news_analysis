import firebase_admin
from firebase_admin import credentials, firestore, auth
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union
import json
import hashlib

from news import News


class FirebaseClient:
    """Enhanced Firebase client for storing and retrieving news analysis data"""
    
    def __init__(self, key_path: str):
        """Initialize Firebase client with credentials"""
        try:
            # Try to get existing app
            firebase_admin.get_app()
        except ValueError:
            # Initialize app if not already initialized
            self.cred = credentials.Certificate(key_path)
            firebase_admin.initialize_app(self.cred)
        
        self.db = firestore.client()
    
    def save_analysis(self, collection: str, article_id: str, analysis_result: Dict[str, Any]):
        """Save analysis result to Firestore with timestamp"""
        doc_ref = self.db.collection(collection).document(article_id)
        
        # Add timestamp if not present
        if "timestamp" not in analysis_result:
            analysis_result["timestamp"] = datetime.utcnow().isoformat()
        
        # Set the document with merge to avoid overwriting existing fields
        doc_ref.set(analysis_result, merge=True)
        
        return article_id
    
    def get_latest_analyses(self, collection: str, limit: int = 10):
        """Get latest analyses ordered by timestamp"""
        docs = (
            self.db.collection(collection)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(limit)
            .stream()
        )
        return [doc.to_dict() for doc in docs]
    
    def get_analysis_by_id(self, collection: str, article_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific analysis by ID"""
        doc_ref = self.db.collection(collection).document(article_id)
        doc = doc_ref.get()
        
        if doc.exists:
            return doc.to_dict()
        return None
    
    def query_analyses(self, collection: str, filters: Dict[str, Any],
                       order_by: str = "timestamp", limit: int = 20,
                       direction: str = "DESCENDING") -> List[Dict[str, Any]]:
        """Query analyses with filters and ordering"""
        query = self.db.collection(collection)
        
        # Apply filters
        for field, value in filters.items():
            if isinstance(value, dict) and "operator" in value:
                # Handle complex filters with operators
                operator = value["operator"]
                filter_value = value["value"]
                
                if operator == "==":
                    query = query.where(field, "==", filter_value)
                elif operator == ">":
                    query = query.where(field, ">", filter_value)
                elif operator == ">=":
                    query = query.where(field, ">=", filter_value)
                elif operator == "<":
                    query = query.where(field, "<", filter_value)
                elif operator == "<=":
                    query = query.where(field, "<=", filter_value)
                elif operator == "in":
                    query = query.where(field, "in", filter_value)
                elif operator == "array-contains":
                    query = query.where(field, "array_contains", filter_value)
                elif operator == "array-contains-any":
                    query = query.where(field, "array_contains_any", filter_value)
            else:
                # Simple equality filter
                query = query.where(field, "==", value)
        
        # Apply ordering
        dir_value = firestore.Query.DESCENDING if direction == "DESCENDING" else firestore.Query.ASCENDING
        query = query.order_by(order_by, direction=dir_value)
        
        # Apply limit
        query = query.limit(limit)
        
        # Execute query
        docs = query.stream()
        return [doc.to_dict() for doc in docs]
    
    def save_user(self, user_id: str, user_data: Dict[str, Any]) -> str:
        """Save user data to Firestore"""
        doc_ref = self.db.collection("users").document(user_id)
        
        # Add timestamps if not present
        if "created_at" not in user_data:
            user_data["created_at"] = datetime.utcnow().isoformat()
        
        user_data["updated_at"] = datetime.utcnow().isoformat()
        
        # Set the document with merge to avoid overwriting existing fields
        doc_ref.set(user_data, merge=True)
        
        return user_id
    
    def get_user(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get user data by ID"""
        doc_ref = self.db.collection("users").document(user_id)
        doc = doc_ref.get()
        
        if doc.exists:
            return doc.to_dict()
        return None
    
    def save_subscription(self, user_id: str, subscription_data: Dict[str, Any]) -> str:
        """Save subscription data to Firestore"""
        # Generate subscription ID
        subscription_id = hashlib.md5(f"{user_id}:{datetime.utcnow().isoformat()}".encode()).hexdigest()
        
        # Create document reference
        doc_ref = self.db.collection("user_subscriptions").document(subscription_id)
        
        # Add user ID and timestamps
        subscription_data["user_id"] = user_id
        subscription_data["created_at"] = datetime.utcnow().isoformat()
        subscription_data["updated_at"] = datetime.utcnow().isoformat()
        
        # Set the document
        doc_ref.set(subscription_data)
        
        # Update user's subscription information
        user_ref = self.db.collection("users").document(user_id)
        user_ref.update({
            "subscription_tier": subscription_data.get("tier", "free"),
            "subscription_id": subscription_id,
            "subscription_expiry": subscription_data.get("end_date"),
            "updated_at": datetime.utcnow().isoformat()
        })
        
        return subscription_id
    
    def save_notification(self, user_id: str, article_id: str, notification_data: Dict[str, Any]) -> str:
        """Save notification data to Firestore"""
        # Generate notification ID
        notification_id = hashlib.md5(f"{user_id}:{article_id}:{datetime.utcnow().isoformat()}".encode()).hexdigest()
        
        # Create document reference
        doc_ref = self.db.collection("notifications").document(notification_id)
        
        # Add IDs and timestamps
        notification_data["user_id"] = user_id
        notification_data["article_id"] = article_id
        notification_data["sent_at"] = datetime.utcnow().isoformat()
        
        # Set the document
        doc_ref.set(notification_data)
        
        return notification_id
    
    def save_entity_relationship(self, entity_a: str, entity_b: str, relationship_type: str,
                                strength: float, article_id: str) -> str:
        """Save entity relationship data to Firestore"""
        # Generate relationship ID (consistent for the same entity pair)
        relationship_id = hashlib.md5(f"{entity_a}:{entity_b}:{relationship_type}".encode()).hexdigest()
        
        # Create document reference
        doc_ref = self.db.collection("entity_relationships").document(relationship_id)
        
        # Check if relationship already exists
        doc = doc_ref.get()
        if doc.exists:
            # Update existing relationship
            doc_ref.update({
                "strength": strength,  # Update with new strength
                "articles": firestore.ArrayUnion([article_id]),  # Add article to list
                "updated_at": datetime.utcnow().isoformat()
            })
        else:
            # Create new relationship
            doc_ref.set({
                "entity_a": entity_a,
                "entity_b": entity_b,
                "relationship_type": relationship_type,
                "strength": strength,
                "articles": [article_id],
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat()
            })
        
        return relationship_id
    
    def get_entity_relationships(self, entity: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get relationships for a specific entity"""
        # Query where entity is either entity_a or entity_b
        query_a = self.db.collection("entity_relationships").where("entity_a", "==", entity)
        query_b = self.db.collection("entity_relationships").where("entity_b", "==", entity)
        
        # Execute queries
        docs_a = list(query_a.stream())
        docs_b = list(query_b.stream())
        
        # Combine and sort by strength
        all_docs = [doc.to_dict() for doc in docs_a + docs_b]
        all_docs.sort(key=lambda x: x.get("strength", 0), reverse=True)
        
        return all_docs[:limit]
