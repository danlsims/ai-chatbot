#!/usr/bin/env python3
"""
Health Check Lambda Function

Simple health check endpoint for the Bedrock Chatbot API.
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Health check handler
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        Health check response
    """
    logger.info("Health check requested")
    
    # Get CORS origin
    cors_origin = os.environ.get('CORS_ORIGIN', '*')
    
    # Prepare health check response
    health_data = {
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'service': 'bedrock-chatbot-api',
        'version': '1.0.0',
        'region': os.environ.get('AWS_REGION', 'unknown'),
        'requestId': context.aws_request_id if context else None
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': cors_origin,
            'Access-Control-Allow-Headers': 'Content-Type,X-Requested-With',
            'Access-Control-Allow-Methods': 'GET,OPTIONS',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0'
        },
        'body': json.dumps(health_data)
    }