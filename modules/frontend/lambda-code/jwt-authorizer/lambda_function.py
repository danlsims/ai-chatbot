#!/usr/bin/env python3
"""
JWT Authorizer Lambda Function for AWS Identity Center

This function validates JWT tokens from AWS Identity Center and provides
authorization decisions for API Gateway.
"""

import json
import os
import logging
import time
from typing import Dict, Any, Optional
import urllib.request
import base64
from jose import jwt, JWTError
from jose.exceptions import ExpiredSignatureError, JWTClaimsError

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.environ.get('LOG_LEVEL', 'INFO'))

# Cache for JWKS (JSON Web Key Set)
JWKS_CACHE = {}
JWKS_CACHE_TTL = 3600  # 1 hour

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Main Lambda handler for JWT authorization
    
    Args:
        event: API Gateway authorizer event
        context: Lambda context
        
    Returns:
        IAM policy document
    """
    logger.info(f"Authorizer event: {json.dumps(event, default=str)}")
    
    try:
        # Extract the JWT token from the Authorization header
        token = extract_token(event)
        
        # Validate the JWT token
        claims = validate_jwt_token(token)
        
        # Extract user information
        user_info = extract_user_claims(claims)
        
        # Generate allow policy
        policy = generate_policy(
            principal_id=user_info['userId'],
            effect='Allow',
            resource=event['methodArn'],
            context=user_info
        )
        
        logger.info(f"Authorization successful for user: {user_info['userId']}")
        return policy
        
    except ValueError as e:
        logger.error(f"Token validation error: {str(e)}")
        raise Exception('Unauthorized')
        
    except ExpiredSignatureError:
        logger.error("Token has expired")
        raise Exception('Unauthorized')
        
    except JWTError as e:
        logger.error(f"JWT error: {str(e)}")
        raise Exception('Unauthorized')
        
    except Exception as e:
        logger.error(f"Authorization error: {str(e)}")
        raise Exception('Unauthorized')

def extract_token(event: Dict[str, Any]) -> str:
    """
    Extract JWT token from the Authorization header
    
    Args:
        event: API Gateway authorizer event
        
    Returns:
        JWT token string
        
    Raises:
        ValueError: If token is missing or invalid format
    """
    # Check different possible locations for the token
    token = None
    
    # Method 1: authorizationToken (for TOKEN authorizer)
    if 'authorizationToken' in event:
        auth_header = event['authorizationToken']
    
    # Method 2: headers (for REQUEST authorizer)
    elif 'headers' in event and 'Authorization' in event['headers']:
        auth_header = event['headers']['Authorization']
    
    # Method 3: headers with lowercase
    elif 'headers' in event and 'authorization' in event['headers']:
        auth_header = event['headers']['authorization']
    
    else:
        raise ValueError("Authorization header is missing")
    
    # Extract token from "Bearer <token>" format
    if not auth_header:
        raise ValueError("Authorization header is empty")
    
    parts = auth_header.split()
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        raise ValueError("Authorization header must be in format 'Bearer <token>'")
    
    token = parts[1]
    
    if not token:
        raise ValueError("JWT token is empty")
    
    return token

def validate_jwt_token(token: str) -> Dict[str, Any]:
    """
    Validate JWT token against Identity Center JWKS
    
    Args:
        token: JWT token string
        
    Returns:
        JWT claims dictionary
        
    Raises:
        JWTError: If token validation fails
    """
    issuer_url = os.environ['JWT_ISSUER_URL']
    client_id = os.environ['JWT_CLIENT_ID']
    
    # Get JWKS (JSON Web Key Set)
    jwks = get_jwks(issuer_url)
    
    # Decode and validate the token
    try:
        claims = jwt.decode(
            token,
            jwks,
            algorithms=['RS256'],
            audience=client_id,
            issuer=issuer_url,
            options={
                'verify_signature': True,
                'verify_aud': True,
                'verify_iss': True,
                'verify_exp': True,
                'verify_nbf': True,
                'verify_iat': True,
                'require_aud': True,
                'require_iss': True,
                'require_exp': True
            }
        )
        
        logger.info(f"Token validation successful for subject: {claims.get('sub', 'unknown')}")
        return claims
        
    except ExpiredSignatureError:
        logger.error("JWT token has expired")
        raise
        
    except JWTClaimsError as e:
        logger.error(f"JWT claims validation failed: {str(e)}")
        raise
        
    except JWTError as e:
        logger.error(f"JWT validation failed: {str(e)}")
        raise

def get_jwks(issuer_url: str) -> Dict[str, Any]:
    """
    Get JSON Web Key Set (JWKS) from Identity Center
    
    Args:
        issuer_url: Identity Center issuer URL
        
    Returns:
        JWKS dictionary
    """
    # Check cache first
    cache_key = f"jwks_{issuer_url}"
    current_time = time.time()
    
    if cache_key in JWKS_CACHE:
        cached_jwks, cache_time = JWKS_CACHE[cache_key]
        if current_time - cache_time < JWKS_CACHE_TTL:
            logger.debug("Using cached JWKS")
            return cached_jwks
    
    # Fetch JWKS from Identity Center
    jwks_url = f"{issuer_url}/.well-known/jwks.json"
    
    try:
        logger.info(f"Fetching JWKS from: {jwks_url}")
        
        with urllib.request.urlopen(jwks_url, timeout=10) as response:
            jwks_data = json.loads(response.read().decode('utf-8'))
        
        # Cache the JWKS
        JWKS_CACHE[cache_key] = (jwks_data, current_time)
        
        logger.info("JWKS fetched and cached successfully")
        return jwks_data
        
    except Exception as e:
        logger.error(f"Failed to fetch JWKS: {str(e)}")
        
        # Try to use cached version even if expired
        if cache_key in JWKS_CACHE:
            logger.warning("Using expired JWKS cache due to fetch failure")
            cached_jwks, _ = JWKS_CACHE[cache_key]
            return cached_jwks
        
        raise Exception(f"Unable to fetch JWKS: {str(e)}")

def extract_user_claims(claims: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract user information from JWT claims
    
    Args:
        claims: JWT claims dictionary
        
    Returns:
        User information dictionary
    """
    # Map Identity Center claims to user info
    user_info = {
        'userId': claims.get('sub', ''),
        'email': claims.get('email', ''),
        'name': claims.get('name', ''),
        'username': claims.get('username', ''),
        'groups': claims.get('custom:groups', []),
        'tokenUse': claims.get('token_use', ''),
        'issuer': claims.get('iss', ''),
        'audience': claims.get('aud', ''),
        'issuedAt': claims.get('iat', 0),
        'expiresAt': claims.get('exp', 0)
    }
    
    # Handle groups if they're a string (convert to list)
    if isinstance(user_info['groups'], str):
        user_info['groups'] = [user_info['groups']]
    
    return user_info

def generate_policy(principal_id: str, effect: str, resource: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate IAM policy for API Gateway
    
    Args:
        principal_id: User identifier
        effect: 'Allow' or 'Deny'
        resource: Resource ARN
        context: Additional context to pass to the API
        
    Returns:
        IAM policy document
    """
    # Build the policy
    policy = {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {
                    'Action': 'execute-api:Invoke',
                    'Effect': effect,
                    'Resource': resource
                }
            ]
        },
        'context': {
            # Convert all context values to strings (API Gateway requirement)
            key: str(value) if not isinstance(value, str) else value
            for key, value in context.items()
            if value is not None
        }
    }
    
    logger.debug(f"Generated policy: {json.dumps(policy, default=str)}")
    return policy