// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name

  # Website URLs
  website_url = var.enable_custom_domain ? "https://${var.website_domain_name}" : "https://${aws_cloudfront_distribution.frontend.domain_name}"
  api_url     = var.enable_custom_domain ? "https://${var.api_domain_name}" : aws_api_gateway_rest_api.chatbot_api.execution_arn

  # CORS origins - use custom domain if enabled, otherwise CloudFront domain
  cors_origins = var.enable_custom_domain ? var.cors_allowed_origins : [
    "https://${aws_cloudfront_distribution.frontend.domain_name}"
  ]

  # Lambda environment variables
  lambda_environment = {
    BEDROCK_AGENT_ID       = var.bedrock_agent_id
    BEDROCK_AGENT_ALIAS_ID = var.bedrock_agent_alias_id
    CORS_ORIGIN           = join(",", local.cors_origins)
    JWT_ISSUER_URL        = var.identity_center_issuer_url
    JWT_CLIENT_ID         = var.identity_center_client_id
    LOG_LEVEL             = "INFO"
  }

  # Common tags
  common_tags = {
    Application = var.app_name
    Environment = var.env_name
    Module      = "frontend"
    ManagedBy   = "terraform"
  }

  # S3 bucket policy for CloudFront OAC
  s3_bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })

  # API Gateway CORS configuration
  cors_configuration = {
    allow_credentials = true
    allow_headers     = var.cors_allowed_headers
    allow_methods     = var.cors_allowed_methods
    allow_origins     = local.cors_origins
    expose_headers    = ["Date", "x-api-id"]
    max_age          = 300
  }
}