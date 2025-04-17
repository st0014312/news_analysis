import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

from news import News


class FirebaseClient:
    def __init__(self, key_path: str):
        self.cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(self.cred)
        self.db = firestore.client()

    def save_analysis(self, collection: str, article_id: str, analysis_result: News):
        doc_ref = self.db.collection(collection).document(article_id)
        analysis_result["timestamp"] = datetime.utcnow().isoformat()
        doc_ref.set(analysis_result)

    def get_latest_analyses(self, collection: str, limit: int = 10):
        docs = (
            self.db.collection(collection)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(limit)
            .stream()
        )
        return [doc.to_dict() for doc in docs]
