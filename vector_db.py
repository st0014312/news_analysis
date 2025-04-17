from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain.vectorstores.utils import filter_complex_metadata
import os

# from langchain_openai import OpenAIEmbeddings


class NewsVectorDB:
    def __init__(self):
        self.embedding = HuggingFaceEmbeddings(
            model_name="sentence-transformers/multi-qa-mpnet-base-dot-v1"
        )
        # self.embedding = OpenAIEmbeddings(model="tezt-em"
        # )
        self.persist_dir = "./chroma_db"

        self.vector_store = Chroma(
            persist_directory=self.persist_dir,
            embedding_function=self.embedding,
            collection_metadata={"hnsw:space": "cosine", "allow_duplicates": False},
        )

    def save_from_documents(self, documents):
        """Save documents to vector store"""
        self.vector_store.add_documents(filter_complex_metadata(documents))

    def store_documents(self, documents):
        """Store processed documents with metadata"""
        texts = [doc.page_content for doc in documents]
        metadatas = [filter_complex_metadata(doc.metadata) for doc in documents]
        self.vector_store.add_texts(texts=texts, metadatas=metadatas)
        self.vector_store.persist()

    def hybrid_search(self, query, filters=None, k=5):
        """Perform semantic search with metadata filtering"""
        return self.vector_store.similarity_search(
            query=query,
            k=k,
            filter=filters,
        )

    def get_retriever(self):
        """Create retriever with metadata awareness"""
        return self.vector_store.as_retriever(
            search_type="similarity_score_threshold",
            search_kwargs={
                "k": 5,
                "score_threshold": 0.65,
                "filter": {"source": "news_api", "valid": "Yes"},
            },
        )
