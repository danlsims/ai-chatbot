// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# API Gateway REST API
resource "aws_api_gateway_rest_api" "chatbot_api" {
  name        = "${var.api_gateway_name}-${var.app_name}-${var.env_name}"
  description = "API Gateway for Bedrock Fitness Chatbot"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:${local.partition}:execute-api:${local.region}:${local.account_id}:*/*"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.api_gateway_name}-${var.app_name}-${var.env_name}"
  })
}

# JWT Authorizer for Identity Center
resource "aws_api_gateway_authorizer" "jwt_authorizer" {
  name                   = "IdentityCenterJWTAuthorizer"
  rest_api_id            = aws_api_gateway_rest_api.chatbot_api.id
  type                   = "JWT"
  identity_source        = "method.request.header.Authorization"
  authorizer_credentials = aws_iam_role.api_gateway_authorizer.arn
  authorizer_uri         = aws_lambda_function.jwt_authorizer.invoke_arn

  # For JWT authorizer, we use a Lambda authorizer
  # since API Gateway JWT authorizer is for HTTP API, not REST API
}

# Chat resource
resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  parent_id   = aws_api_gateway_rest_api.chatbot_api.root_resource_id
  path_part   = "chat"
}

# Health check resource
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  parent_id   = aws_api_gateway_rest_api.chatbot_api.root_resource_id
  path_part   = "health"
}

# POST method for chat
resource "aws_api_gateway_method" "chat_post" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.jwt_authorizer.id

  request_validator_id = aws_api_gateway_request_validator.body_validator.id
  request_models = {
    "application/json" = aws_api_gateway_model.chat_request.name
  }
}

# OPTIONS method for CORS preflight (chat)
resource "aws_api_gateway_method" "chat_options" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# GET method for health check
resource "aws_api_gateway_method" "health_get" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda integration for chat POST
resource "aws_api_gateway_integration" "chat_post" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_proxy.invoke_arn

  depends_on = [aws_api_gateway_method.chat_post]
}

# CORS integration for chat OPTIONS
resource "aws_api_gateway_integration" "chat_options" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.chat_options]
}

# Lambda integration for health GET
resource "aws_api_gateway_integration" "health_get" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.health_check.invoke_arn

  depends_on = [aws_api_gateway_method.health_get]
}

# Method responses
resource "aws_api_gateway_method_response" "chat_post_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_post.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin"  = true
    "Access-Control-Allow-Headers" = true
    "Access-Control-Allow-Methods" = true
  }

  response_models = {
    "application/json" = aws_api_gateway_model.chat_response.name
  }
}

resource "aws_api_gateway_method_response" "chat_options_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin"  = true
    "Access-Control-Allow-Headers" = true
    "Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_method_response" "health_get_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.health.id
  http_method = aws_api_gateway_method.health_get.http_method
  status_code = "200"

  response_headers = {
    "Access-Control-Allow-Origin" = true
  }
}

# Integration responses
resource "aws_api_gateway_integration_response" "chat_options_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_options.http_method
  status_code = aws_api_gateway_method_response.chat_options_200.status_code

  response_headers = {
    "Access-Control-Allow-Origin"  = "'${join(",", local.cors_origins)}'"
    "Access-Control-Allow-Headers" = "'${join(",", var.cors_allowed_headers)}'"
    "Access-Control-Allow-Methods" = "'${join(",", var.cors_allowed_methods)}'"
  }

  depends_on = [aws_api_gateway_integration.chat_options]
}

# Request models
resource "aws_api_gateway_model" "chat_request" {
  rest_api_id  = aws_api_gateway_rest_api.chatbot_api.id
  name         = "ChatRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "Chat Request Schema"
    type      = "object"
    required  = ["message"]
    properties = {
      message = {
        type        = "string"
        minLength   = 1
        maxLength   = 4000
        description = "User message to send to the chatbot"
      }
      sessionId = {
        type        = "string"
        description = "Optional session ID for conversation continuity"
      }
    }
  })
}

resource "aws_api_gateway_model" "chat_response" {
  rest_api_id  = aws_api_gateway_rest_api.chatbot_api.id
  name         = "ChatResponse"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "Chat Response Schema"
    type      = "object"
    required  = ["response", "sessionId"]
    properties = {
      response = {
        type        = "string"
        description = "Chatbot response message"
      }
      sessionId = {
        type        = "string"
        description = "Session ID for conversation continuity"
      }
      metadata = {
        type        = "object"
        description = "Additional metadata about the response"
      }
    }
  })
}

# Request validator
resource "aws_api_gateway_request_validator" "body_validator" {
  name                        = "BodyValidator"
  rest_api_id                 = aws_api_gateway_rest_api.chatbot_api.id
  validate_request_body       = true
  validate_request_parameters = false
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id

  # Force redeployment when configuration changes
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.chat.id,
      aws_api_gateway_resource.health.id,
      aws_api_gateway_method.chat_post.id,
      aws_api_gateway_method.chat_options.id,
      aws_api_gateway_method.health_get.id,
      aws_api_gateway_integration.chat_post.id,
      aws_api_gateway_integration.chat_options.id,
      aws_api_gateway_integration.health_get.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.chat_post,
    aws_api_gateway_method.chat_options,
    aws_api_gateway_method.health_get,
    aws_api_gateway_integration.chat_post,
    aws_api_gateway_integration.chat_options,
    aws_api_gateway_integration.health_get,
  ]
}

# API Gateway stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  stage_name    = var.api_stage_name

  # Enable logging if configured
  dynamic "access_log_settings" {
    for_each = var.enable_api_gateway_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        error          = "$context.error.message"
        errorType      = "$context.error.messageString"
      })
    }
  }

  # Enable X-Ray tracing if configured
  xray_tracing_enabled = var.enable_xray_tracing

  tags = merge(local.common_tags, {
    Name = "${var.api_gateway_name}-${var.app_name}-${var.env_name}-${var.api_stage_name}"
  })
}

# API Gateway usage plan
resource "aws_api_gateway_usage_plan" "main" {
  name = "${var.api_gateway_name}-${var.app_name}-${var.env_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.chatbot_api.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    rate_limit  = var.api_throttle_rate_limit
    burst_limit = var.api_throttle_burst_limit
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  tags = local.common_tags
}

# CloudWatch log group for API Gateway (conditional)
resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.enable_api_gateway_logging ? 1 : 0
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.chatbot_api.id}/${var.api_stage_name}"
  retention_in_days = var.api_gateway_log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "api-gateway-logs"
  })
}