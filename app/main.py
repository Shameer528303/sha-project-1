"""
Simple Document Service
A REST API service for storing and retrieving documents with caching.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import logging
import os
from typing import Optional
import boto3
import json
import redis
from datetime import datetime

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s", "module": "%(name)s"}'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Document Service", version="1.0.0")

# TODO: Initialize AWS clients
# s3_client = boto3.client('s3', region_name=os.getenv('AWS_REGION', 'us-east-1'))
# OR
# dynamodb = boto3.resource('dynamodb', region_name=os.getenv('AWS_REGION', 'us-east-1'))

# TODO: Initialize cache client (Redis)
# cache_client = redis.Redis(
#     host=os.getenv('CACHE_HOST', 'localhost'),
#     port=int(os.getenv('CACHE_PORT', 6379)),
#     decode_responses=True
# )

# Configuration
MAX_CONTENT_SIZE = 100 * 1024  # 100 KB
STORAGE_BUCKET = os.getenv('STORAGE_BUCKET', 'document-service-storage')
STORAGE_TYPE = os.getenv('STORAGE_TYPE', 's3')  # 's3', 'dynamodb', 'rds'


class DocumentRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=MAX_CONTENT_SIZE, description="Document content")


class DocumentResponse(BaseModel):
    id: str
    content: str
    created_at: Optional[str] = None


def get_secret(secret_name: str) -> str:
    """
    Retrieve secret from AWS Secrets Manager.
    TODO: Implement this function to fetch secrets.
    """
    # Example implementation:
    # secrets_client = boto3.client('secretsmanager', region_name=os.getenv('AWS_REGION', 'us-east-1'))
    # response = secrets_client.get_secret_value(SecretId=secret_name)
    # return response['SecretString']
    return os.getenv(secret_name.upper().replace('-', '_'), '')


def store_document(document_id: str, content: str) -> bool:
    """
    Store document in durable storage.
    TODO: Implement based on your storage choice (S3, DynamoDB, RDS).
    
    Returns True if successful, False otherwise.
    """
    try:
        # Example S3 implementation:
        # s3_client.put_object(
        #     Bucket=STORAGE_BUCKET,
        #     Key=f"documents/{document_id}",
        #     Body=content.encode('utf-8'),
        #     ContentType='text/plain'
        # )
        
        # Example DynamoDB implementation:
        # table = dynamodb.Table('documents')
        # table.put_item(
        #     Item={
        #         'id': document_id,
        #         'content': content,
        #         'created_at': datetime.utcnow().isoformat()
        #     }
        # )
        
        logger.info(f"Stored document {document_id} in storage")
        return True
    except Exception as e:
        logger.error(f"Error storing document {document_id}: {str(e)}", exc_info=True)
        return False


def retrieve_document(document_id: str) -> Optional[str]:
    """
    Retrieve document from durable storage.
    TODO: Implement based on your storage choice.
    
    Returns document content or None if not found.
    """
    try:
        # Example S3 implementation:
        # response = s3_client.get_object(
        #     Bucket=STORAGE_BUCKET,
        #     Key=f"documents/{document_id}"
        # )
        # return response['Body'].read().decode('utf-8')
        
        # Example DynamoDB implementation:
        # table = dynamodb.Table('documents')
        # response = table.get_item(Key={'id': document_id})
        # if 'Item' in response:
        #     return response['Item']['content']
        # return None
        
        logger.info(f"Retrieved document {document_id} from storage")
        return None  # Placeholder
    except Exception as e:
        logger.error(f"Error retrieving document {document_id}: {str(e)}", exc_info=True)
        return None


def get_from_cache(document_id: str) -> Optional[str]:
    """
    Get document from cache.
    TODO: Implement cache retrieval.
    """
    try:
        # Example Redis implementation:
        # cached = cache_client.get(f"document:{document_id}")
        # if cached:
        #     logger.info(f"Cache hit for document {document_id}")
        #     return cached
        # logger.info(f"Cache miss for document {document_id}")
        return None
    except Exception as e:
        logger.warning(f"Cache error for document {document_id}: {str(e)}")
        return None  # Graceful degradation - fallback to storage


def set_in_cache(document_id: str, content: str, ttl: int = 3600) -> bool:
    """
    Store document in cache.
    TODO: Implement cache storage.
    """
    try:
        # Example Redis implementation:
        # cache_client.setex(f"document:{document_id}", ttl, content)
        # logger.info(f"Cached document {document_id}")
        return True
    except Exception as e:
        logger.warning(f"Cache error storing document {document_id}: {str(e)}")
        return False  # Non-fatal - cache is optional


def invalidate_cache(document_id: str) -> None:
    """
    Invalidate cache entry for document.
    TODO: Implement cache invalidation.
    """
    try:
        # Example Redis implementation:
        # cache_client.delete(f"document:{document_id}")
        # logger.info(f"Invalidated cache for document {document_id}")
        pass
    except Exception as e:
        logger.warning(f"Cache invalidation error for document {document_id}: {str(e)}")


@app.get("/health")
async def health_check():
    """
    Health check endpoint.
    TODO: Check storage and cache connectivity.
    """
    health_status = {
        "status": "healthy",
        "service": "document-service",
        "version": "1.0.0",
        "storage": "unknown",  # TODO: Check storage connectivity
        "cache": "unknown"     # TODO: Check cache connectivity
    }
    
    # TODO: Add actual health checks
    # try:
    #     # Check storage
    #     # Check cache
    #     pass
    # except Exception as e:
    #     health_status["status"] = "unhealthy"
    #     health_status["error"] = str(e)
    
    status_code = 200 if health_status["status"] == "healthy" else 503
    return health_status


@app.put("/documents/{document_id}")
async def put_document(document_id: str, request: DocumentRequest):
    """
    Store a document.
    """
    try:
        logger.info(f"Storing document {document_id}, size: {len(request.content)} bytes")
        
        # Validate content size
        if len(request.content) > MAX_CONTENT_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"Content exceeds maximum size of {MAX_CONTENT_SIZE} bytes"
            )
        
        # Store in durable storage
        if not store_document(document_id, request.content):
            raise HTTPException(
                status_code=500,
                detail="Failed to store document in durable storage"
            )
        
        # Invalidate cache (write-through or cache-aside pattern)
        invalidate_cache(document_id)
        
        # Optionally: Update cache (write-through pattern)
        # set_in_cache(document_id, request.content)
        
        logger.info(f"Successfully stored document {document_id}")
        
        return {
            "id": document_id,
            "status": "stored",
            "size": len(request.content)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error storing document {document_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.get("/documents/{document_id}", response_model=DocumentResponse)
async def get_document(document_id: str):
    """
    Retrieve a document.
    Implements cache-aside pattern: check cache first, then storage.
    """
    try:
        logger.info(f"Retrieving document {document_id}")
        
        # Try cache first (cache-aside pattern)
        cached_content = get_from_cache(document_id)
        if cached_content:
            logger.info(f"Cache hit for document {document_id}")
            return DocumentResponse(
                id=document_id,
                content=cached_content,
                created_at=datetime.utcnow().isoformat()
            )
        
        # Cache miss - retrieve from storage
        logger.info(f"Cache miss for document {document_id}, fetching from storage")
        content = retrieve_document(document_id)
        
        if content is None:
            raise HTTPException(status_code=404, detail=f"Document {document_id} not found")
        
        # Populate cache for future reads (cache-aside pattern)
        set_in_cache(document_id, content)
        
        logger.info(f"Successfully retrieved document {document_id}")
        
        return DocumentResponse(
            id=document_id,
            content=content,
            created_at=datetime.utcnow().isoformat()
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving document {document_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
