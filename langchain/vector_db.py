from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_openai import OpenAIEmbeddings
from langchain.vectorstores.utils import filter_complex_metadata
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor
from langchain_core.documents import Document
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import ChatOpenAI
from langchain.prompts import PromptTemplate
from typing import List, Dict, Any, Optional, Union
import os
from dotenv import load_dotenv
import logging

load_dotenv()


class NewsVectorDB:
    """Enhanced vector database for semantic search of news articles"""
    
    def __init__(self, embedding_model: str = "huggingface"):
        """Initialize vector database with specified embedding model"""
        # Configure logging
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)
        
        # Set up embedding model
        if embedding_model == "openai" and os.getenv("OPENAI_API_KEY"):
            self.logger.info("Using OpenAI embeddings")
            self.embedding = OpenAIEmbeddings(
                model="text-embedding-3-small"
            )
        else:
            self.logger.info("Using HuggingFace embeddings")
            self.embedding = HuggingFaceEmbeddings(
                model_name="sentence-transformers/all-MiniLM-L6-v2"  # Faster, smaller model
            )
        
        # Set up persistence directory
        self.persist_dir = "./chroma_db"
        os.makedirs(self.persist_dir, exist_ok=True)
        
        # Initialize vector store
        self.vector_store = Chroma(
            persist_directory=self.persist_dir,
            embedding_function=self.embedding,
            collection_metadata={
                "hnsw:space": "cosine",
                "allow_duplicates": False,
                "hnsw:M": 16  # More connections per node for better recall
            },
            # Ensure the collection is created if it doesn't exist
            create_collection_if_not_exists=True
        )
        # self.logger.info(f"test {self.vector_store._collection}")
        # self.logger.info(f"Vector store initialized with {self.vector_store._collection.count()} documents")
    
    def save_from_documents(self, documents: List[Document]):
        """Save documents to vector store with error handling"""
        try:
            filtered_docs = []
            for doc in documents:
                # Ensure document has content
                if not doc.page_content or len(doc.page_content.strip()) < 10:
                    self.logger.warning(f"Skipping document with insufficient content: {doc.metadata.get('id', 'unknown')}")
                    continue
                
                # Filter complex metadata
                doc.metadata = filter_complex_metadata(doc.metadata)
                filtered_docs.append(doc)
            
            if not filtered_docs:
                self.logger.warning("No valid documents to save")
                return
            
            self.vector_store.add_documents(filtered_docs)
            self.vector_store.persist()
            self.logger.info(f"Saved {len(filtered_docs)} documents to vector store")
        except Exception as e:
            self.logger.error(f"Error saving documents: {str(e)}")
            raise
    
    def store_documents(self, documents: List[Document]):
        """Store processed documents with metadata"""
        try:
            if not documents:
                self.logger.warning("No documents to store")
                return
            
            texts = []
            metadatas = []
            for doc in documents:
                # Ensure the input is a Document object
                if not isinstance(doc, Document):
                    self.logger.error("Invalid document type. Expected a Document object.")
                    raise ValueError("Invalid document type. Expected a Document object.")
                
                texts.append(doc.page_content)
                metadatas.append(filter_complex_metadata(doc.metadata))
            
            self.vector_store.add_texts(texts=texts, metadatas=metadatas)
            self.vector_store.persist()
            self.logger.info(f"Stored {len(documents)} documents in vector store")
        except Exception as e:
            self.logger.error(f"Error storing documents: {str(e)}")
            raise
    
    def hybrid_search(self, query: str, filters: Optional[Dict[str, Any]] = None,
                     k: int = 5, alpha: float = 0.5) -> List[Document]:
        """Perform hybrid search combining semantic and keyword matching"""
        try:
            # Semantic search
            semantic_results = self.vector_store.similarity_search_with_score(
                query=query,
                k=k*2,  # Get more results for hybrid reranking
                filter=filters,
            )
            
            # Extract documents and scores
            documents = [doc for doc, _ in semantic_results]
            semantic_scores = [score for _, score in semantic_results]
            
            # Keyword matching (simple implementation)
            keyword_scores = []
            query_terms = set(query.lower().split())
            
            for doc in documents:
                content = doc.page_content.lower()
                # Count term frequency
                term_matches = sum(1 for term in query_terms if term in content)
                # Normalize by document length
                keyword_score = term_matches / (len(content.split()) + 1)
                keyword_scores.append(keyword_score)
            
            # Normalize scores
            max_semantic = max(semantic_scores) if semantic_scores else 1
            max_keyword = max(keyword_scores) if keyword_scores else 1
            
            normalized_semantic = [score/max_semantic for score in semantic_scores]
            normalized_keyword = [score/max_keyword for score in keyword_scores]
            
            # Combine scores with alpha weighting
            combined_scores = [
                (alpha * sem_score) + ((1-alpha) * key_score)
                for sem_score, key_score in zip(normalized_semantic, normalized_keyword)
            ]
            
            # Sort by combined score
            results = list(zip(documents, combined_scores))
            results.sort(key=lambda x: x[1], reverse=True)
            
            # Return top k documents
            return [doc for doc, _ in results[:k]]
        except Exception as e:
            self.logger.error(f"Error in hybrid search: {str(e)}")
            # Fallback to regular similarity search
            return self.vector_store.similarity_search(
                query=query,
                k=k,
                filter=filters,
            )
    
    def semantic_search(self, query: str, filters: Optional[Dict[str, Any]] = None,
                       k: int = 5) -> List[Document]:
        """Perform semantic search with metadata filtering"""
        try:
            return self.vector_store.similarity_search(
                query=query,
                k=k,
                filter=filters,
            )
        except Exception as e:
            self.logger.error(f"Error in semantic search: {str(e)}")
            return []
    
    def get_retriever(self, use_compression: bool = False):
        """Create retriever with optional contextual compression"""
        base_retriever = self.vector_store.as_retriever(
            search_type="similarity_score_threshold",
            search_kwargs={
                "k": 5,
                "score_threshold": 0.65,
                "filter": {"valid": True},
            },
        )
        
        if not use_compression:
            return base_retriever
        
        # Create LLM for compression
        llm = ChatOpenAI(
            openai_api_key=os.getenv("OPENROUTER_API_KEY"),
            openai_api_base=os.getenv("OPENROUTER_BASE_URL"),
            model_name="google/gemini-2.0-flash-thinking-exp:free",
            temperature=0,
        )
        
        # Create compressor
        compressor = LLMChainExtractor.from_llm(llm)
        
        # Create compression retriever
        compression_retriever = ContextualCompressionRetriever(
            base_compressor=compressor,
            base_retriever=base_retriever
        )
        
        return compression_retriever
    
    def get_similar_articles(self, article_id: str, k: int = 3) -> List[Dict[str, Any]]:
        """Find articles similar to a given article ID"""
        try:
            # Get the document by ID
            results = self.vector_store.similarity_search(
                query="",
                k=1,
                filter={"id": article_id}
            )
            
            if not results:
                self.logger.warning(f"Article with ID {article_id} not found")
                return []
            
            # Use the document as query
            source_doc = results[0]
            similar_docs = self.vector_store.similarity_search_with_score(
                query=source_doc.page_content,
                k=k+1,  # +1 because the article itself will be included
                filter={"id": {"$ne": article_id}}  # Exclude the source article
            )
            
            # Format results
            return [
                {
                    "id": doc.metadata.get("id", ""),
                    "title": doc.metadata.get("title", ""),
                    "similarity": float(score)
                }
                for doc, score in similar_docs[:k]
            ]
        except Exception as e:
            self.logger.error(f"Error finding similar articles: {str(e)}")
            return []
    
    def delete_document(self, document_id: str) -> bool:
        """Delete a document from the vector store"""
        try:
            self.vector_store.delete(filter={"id": document_id})
            self.vector_store.persist()
            self.logger.info(f"Deleted document {document_id} from vector store")
            return True
        except Exception as e:
            self.logger.error(f"Error deleting document: {str(e)}")
            return False
    
    def get_document_count(self) -> int:
        """Get the number of documents in the vector store"""
        try:
            return self.vector_store._collection.count()
        except Exception as e:
            self.logger.error(f"Error getting document count: {str(e)}")
            return 0
