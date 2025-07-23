// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Security group for Lambda functions
resource "aws_security_group" "lambda_api" {
  name        = "lambda-api-security-group-${var.app_name}-${var.env_name}"
  vpc_id      = var.vpc_id
  description = "Security Group for Frontend API Lambda Functions"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_sg
    description = "Allow HTTPS egress to AWS services"
  }

  tags = merge(local.common_tags, {
    Name = "lambda-api-security-group-${var.app_name}-${var.env_name}"
  })
}

# IAM role for API proxy Lambda
resource "aws_iam_role" "api_proxy_lambda" {
  name = "frontend-api-proxy-lambda-role-${var.app_name}-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for API proxy Lambda
resource "aws_iam_role_policy" "api_proxy_lambda" {
  name = "frontend-api-proxy-lambda-policy-${var.app_name}-${var.env_name}"
  role = aws_iam_role.api_proxy_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.api_lambda_function_name}-${var.app_name}-${var.env_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock-agent-runtime:InvokeAgent"
        ]
        Resource = [
          "arn:${local.partition}:bedrock:${local.region}:${local.account_id}:agent-alias/${var.bedrock_agent_id}/${var.bedrock_agent_alias_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [
          var.kms_key_id
        ]
      }
    ]
  })
}

# Attach VPC execution policy to API proxy Lambda role
resource "aws_iam_role_policy_attachment" "api_proxy_lambda_vpc" {
  role       = aws_iam_role.api_proxy_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# IAM role for JWT authorizer Lambda
resource "aws_iam_role" "jwt_authorizer_lambda" {
  name = "frontend-jwt-authorizer-lambda-role-${var.app_name}-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for JWT authorizer Lambda
resource "aws_iam_role_policy" "jwt_authorizer_lambda" {
  name = "frontend-jwt-authorizer-lambda-policy-${var.app_name}-${var.env_name}"
  role = aws_iam_role.jwt_authorizer_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/jwt-authorizer-${var.app_name}-${var.env_name}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          var.kms_key_id
        ]
      }
    ]
  })
}

# IAM role for API Gateway authorizer
resource "aws_iam_role" "api_gateway_authorizer" {
  name = "frontend-api-gateway-authorizer-role-${var.app_name}-${var.env_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for API Gateway authorizer
resource "aws_iam_role_policy" "api_gateway_authorizer" {
  name = "frontend-api-gateway-authorizer-policy-${var.app_name}-${var.env_name}"
  role = aws_iam_role.api_gateway_authorizer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.jwt_authorizer.arn
      }
    ]
  })
}

# Create Lambda deployment packages
data "archive_file" "api_proxy_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda-packages/api-proxy.zip"
  source_dir  = "${path.module}/lambda-code/api-proxy"
}

data "archive_file" "jwt_authorizer_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda-packages/jwt-authorizer.zip"
  source_dir  = "${path.module}/lambda-code/jwt-authorizer"
}

data "archive_file" "health_check_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda-packages/health-check.zip"
  source_dir  = "${path.module}/lambda-code/health-check"
}

# API Proxy Lambda function
resource "aws_lambda_function" "api_proxy" {
  filename      = data.archive_file.api_proxy_lambda.output_path
  function_name = "${var.api_lambda_function_name}-${var.app_name}-${var.env_name}"
  role          = aws_iam_role.api_proxy_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.api_lambda_runtime
  timeout       = var.api_lambda_timeout
  memory_size   = var.api_lambda_memory_size
  kms_key_arn   = var.kms_key_id

  source_code_hash = data.archive_file.api_proxy_lambda.output_base64sha256

  environment {
    variables = local.lambda_environment
  }

  vpc_config {
    subnet_ids         = var.vpc_subnet_ids
    security_group_ids = [aws_security_group.lambda_api.id]
  }

  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  tags = merge(local.common_tags, {
    Name = "${var.api_lambda_function_name}-${var.app_name}-${var.env_name}"
  })

  depends_on = [
    aws_iam_role_policy.api_proxy_lambda,
    aws_iam_role_policy_attachment.api_proxy_lambda_vpc,
    aws_cloudwatch_log_group.api_proxy_lambda
  ]
}

# JWT Authorizer Lambda function
resource "aws_lambda_function" "jwt_authorizer" {
  filename      = data.archive_file.jwt_authorizer_lambda.output_path
  function_name = "jwt-authorizer-${var.app_name}-${var.env_name}"
  role          = aws_iam_role.jwt_authorizer_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.api_lambda_runtime
  timeout       = 10
  memory_size   = 512
  kms_key_arn   = var.kms_key_id

  source_code_hash = data.archive_file.jwt_authorizer_lambda.output_base64sha256

  environment {
    variables = {
      JWT_ISSUER_URL = var.identity_center_issuer_url
      JWT_CLIENT_ID  = var.identity_center_client_id
      LOG_LEVEL      = "INFO"
    }
  }

  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  tags = merge(local.common_tags, {
    Name = "jwt-authorizer-${var.app_name}-${var.env_name}"
  })

  depends_on = [
    aws_iam_role_policy.jwt_authorizer_lambda,
    aws_cloudwatch_log_group.jwt_authorizer_lambda
  ]
}

# Health Check Lambda function
resource "aws_lambda_function" "health_check" {
  filename      = data.archive_file.health_check_lambda.output_path
  function_name = "health-check-${var.app_name}-${var.env_name}"
  role          = aws_iam_role.jwt_authorizer_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = var.api_lambda_runtime
  timeout       = 5
  memory_size   = 256
  kms_key_arn   = var.kms_key_id

  source_code_hash = data.archive_file.health_check_lambda.output_base64sha256

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  tags = merge(local.common_tags, {
    Name = "health-check-${var.app_name}-${var.env_name}"
  })

  depends_on = [
    aws_cloudwatch_log_group.health_check_lambda
  ]
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "api_proxy_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_proxy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "jwt_authorizer_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jwt_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/authorizers/${aws_api_gateway_authorizer.jwt_authorizer.id}"
}

resource "aws_lambda_permission" "health_check_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/*/*"
}

# CloudWatch log groups for Lambda functions
resource "aws_cloudwatch_log_group" "api_proxy_lambda" {
  name              = "/aws/lambda/${var.api_lambda_function_name}-${var.app_name}-${var.env_name}"
  retention_in_days = var.api_lambda_log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "api-proxy-lambda-logs"
  })
}

resource "aws_cloudwatch_log_group" "jwt_authorizer_lambda" {
  name              = "/aws/lambda/jwt-authorizer-${var.app_name}-${var.env_name}"
  retention_in_days = var.api_lambda_log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "jwt-authorizer-lambda-logs"
  })
}

resource "aws_cloudwatch_log_group" "health_check_lambda" {
  name              = "/aws/lambda/health-check-${var.app_name}-${var.env_name}"
  retention_in_days = var.api_lambda_log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(local.common_tags, {
    Name = "health-check-lambda-logs"
  })
}