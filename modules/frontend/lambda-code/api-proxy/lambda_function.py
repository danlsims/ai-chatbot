#!/usr/bin/env python3
"""
API Proxy Lambda Function for Bedrock Agent

This function serves as a proxy between the frontend application and the Bedrock Agent,
handling user authentication and message routing.
"""

import json
import os
import uuid
import logging
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError, BotoCoreError

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
bedrock_client = boto3.client('bedrock-agent-runtime')

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Main Lambda handler function
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    logger.info(f"Received event: {json.dumps(event, default=str)}")
    
    try:
        # Parse the request
        request_data = parse_request(event)
        
        # Extract user information from the JWT token (set by authorizer)
        user_info = extract_user_info(event)
        
        # Generate or use existing session ID
        session_id = request_data.get('sessionId', generate_session_id())
        
        # Call Bedrock Agent
        agent_response = invoke_bedrock_agent(
            message=request_data['message'],
            session_id=session_id,
            user_info=user_info
        )
        
        # Format successful response
        return format_success_response(agent_response, session_id)
        
    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return format_error_response(400, f"Invalid request: {str(e)}")
        
    except ClientError as e:
        logger.error(f"AWS service error: {str(e)}")
        error_code = e.response.get('Error', {}).get('Code', 'UnknownError')
        
        if error_code in ['AccessDeniedException', 'UnauthorizedOperation']:
            return format_error_response(403, "Access denied to Bedrock Agent")
        elif error_code in ['ThrottlingException', 'ServiceQuotaExceededException']:
            return format_error_response(429, "Service temporarily unavailable. Please try again later.")
        else:
            return format_error_response(500, "Internal service error")
            
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return format_error_response(500, "An unexpected error occurred")

def parse_request(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Parse and validate the API Gateway request
    
    Args:
        event: API Gateway event
        
    Returns:
        Parsed request data
        
    Raises:
        ValueError: If request is invalid
    """
    if not event.get('body'):
        raise ValueError("Request body is required")
    
    try:
        body = json.loads(event['body'])
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON in request body")
    
    # Validate required fields
    message = body.get('message')
    if not message or not isinstance(message, str):
        raise ValueError("Message is required and must be a string")
    
    if len(message.strip()) == 0:
        raise ValueError("Message cannot be empty")
    
    if len(message) > 4000:
        raise ValueError("Message too long (maximum 4000 characters)")
    
    return {
        'message': message.strip(),
        'sessionId': body.get('sessionId')
    }

def extract_user_info(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract user information from the JWT token
    
    Args:
        event: API Gateway event
        
    Returns:
        User information dictionary
    """
    # User info is set by the JWT authorizer
    authorizer_context = event.get('requestContext', {}).get('authorizer', {})
    
    return {
        'userId': authorizer_context.get('userId', 'anonymous'),
        'email': authorizer_context.get('email', ''),
        'name': authorizer_context.get('name', ''),
        'groups': authorizer_context.get('groups', [])
    }

def generate_session_id() -> str:
    """
    Generate a new session ID
    
    Returns:
        UUID-based session ID
    """
    return str(uuid.uuid4())

def invoke_bedrock_agent(message: str, session_id: str, user_info: Dict[str, Any]) -> str:
    """
    Invoke the Bedrock Agent with the user's message
    
    Args:
        message: User's message
        session_id: Session ID for conversation continuity
        user_info: User information
        
    Returns:
        Agent's response text
        
    Raises:
        ClientError: If Bedrock Agent call fails
    """
    agent_id = os.environ['BEDROCK_AGENT_ID']
    agent_alias_id = os.environ['BEDROCK_AGENT_ALIAS_ID']
    
    logger.info(f"Invoking Bedrock Agent {agent_id} with alias {agent_alias_id}")
    logger.info(f"Session ID: {session_id}, User: {user_info.get('userId', 'anonymous')}")
    
    try:
        response = bedrock_client.invoke_agent(
            agentId=agent_id,
            agentAliasId=agent_alias_id,
            sessionId=session_id,
            inputText=message,
            # Add user context for personalization
            sessionState={
                'sessionAttributes': {
                    'userId': user_info.get('userId', ''),
                    'userEmail': user_info.get('email', ''),
                    'userName': user_info.get('name', '')
                }
            }
        )
        
        # Process the streaming response
        return process_agent_response(response)
        
    except ClientError as e:
        logger.error(f"Bedrock Agent invocation failed: {str(e)}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error invoking Bedrock Agent: {str(e)}")
        raise ClientError(
            error_response={'Error': {'Code': 'InternalError', 'Message': str(e)}},
            operation_name='InvokeAgent'
        )

def process_agent_response(response: Dict[str, Any]) -> str:
    """
    Process the streaming response from Bedrock Agent
    
    Args:
        response: Bedrock Agent response
        
    Returns:
        Concatenated response text
    """
    response_text = ""
    
    try:
        # Handle streaming response
        event_stream = response.get('body', {})
        
        for event in event_stream:
            if 'chunk' in event:
                chunk = event['chunk']
                if 'bytes' in chunk:
                    chunk_data = json.loads(chunk['bytes'].decode('utf-8'))
                    if 'outputText' in chunk_data:
                        response_text += chunk_data['outputText']
                        
    except Exception as e:
        logger.error(f"Error processing agent response: {str(e)}")
        # Fallback to basic response if streaming fails
        return "I apologize, but I encountered an issue processing the response. Please try again."
    
    if not response_text.strip():
        return "I apologize, but I couldn't generate a response to your question. Please try rephrasing or ask something else."
    
    return response_text.strip()

def format_success_response(agent_response: str, session_id: str) -> Dict[str, Any]:
    """
    Format a successful API response
    
    Args:
        agent_response: Response from Bedrock Agent
        session_id: Session ID
        
    Returns:
        API Gateway response
    """
    cors_origin = os.environ.get('CORS_ORIGIN', '*')
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': cors_origin,
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Requested-With',
            'Access-Control-Allow-Methods': 'POST,OPTIONS',
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': json.dumps({
            'response': agent_response,
            'sessionId': session_id,
            'timestamp': context.aws_request_id if 'context' in locals() else None
        })
    }

def format_error_response(status_code: int, error_message: str) -> Dict[str, Any]:
    """
    Format an error API response
    
    Args:
        status_code: HTTP status code
        error_message: Error message
        
    Returns:
        API Gateway error response
    """
    cors_origin = os.environ.get('CORS_ORIGIN', '*')
    
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': cors_origin,
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Requested-With',
            'Access-Control-Allow-Methods': 'POST,OPTIONS',
            'Access-Control-Allow-Credentials': 'true'
        },
        'body': json.dumps({
            'error': error_message,
            'statusCode': status_code
        })
    }