// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "env_name" {
  description = "Environment name"
  type        = string
}

variable "app_region" {
  description = "Application region"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
}

# Identity Center Configuration
variable "identity_center_instance_arn" {
  description = "ARN of the existing AWS Identity Center instance"
  type        = string
}

variable "identity_center_issuer_url" {
  description = "Identity Center OIDC issuer URL"
  type        = string
}

variable "identity_center_client_id" {
  description = "Identity Center application client ID"
  type        = string
}

variable "identity_center_client_secret" {
  description = "Identity Center application client secret"
  type        = string
  sensitive   = true
}

variable "frontend_application_name" {
  description = "Name for the frontend application in Identity Center"
  type        = string
  default     = "bedrock-fitness-chatbot"
}

# Domain Configuration
variable "enable_custom_domain" {
  description = "Enable custom domain for the frontend"
  type        = bool
  default     = false
}

variable "website_domain_name" {
  description = "Custom domain name for the website"
  type        = string
  default     = ""
}

variable "api_domain_name" {
  description = "Custom domain name for the API"
  type        = string
  default     = ""
}

variable "route53_hosted_zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
  default     = ""
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN (must be in us-east-1 for CloudFront)"
  type        = string
  default     = ""
}

# S3 Configuration
variable "frontend_bucket_name" {
  description = "S3 bucket name for static website hosting"
  type        = string
}

# CloudFront Configuration
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "cloudfront_comment" {
  description = "CloudFront distribution comment"
  type        = string
  default     = "Bedrock Fitness Chatbot Distribution"
}

# API Gateway Configuration
variable "api_gateway_name" {
  description = "API Gateway name"
  type        = string
  default     = "bedrock-chatbot-api"
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

# CORS Configuration
variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]
}

variable "cors_allowed_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["Content-Type", "Authorization", "X-Requested-With"]
}

# Lambda Configuration
variable "api_lambda_function_name" {
  description = "Lambda function name for API proxy"
  type        = string
  default     = "bedrock-chatbot-api-proxy"
}

variable "api_lambda_memory_size" {
  description = "Lambda memory size"
  type        = number
  default     = 1024
}

variable "api_lambda_timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "api_lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

# Security Configuration
variable "jwt_token_expiration" {
  description = "JWT token expiration in seconds"
  type        = number
  default     = 3600
}

variable "api_throttle_burst_limit" {
  description = "API throttle burst limit"
  type        = number
  default     = 200
}

variable "api_throttle_rate_limit" {
  description = "API throttle rate limit"
  type        = number
  default     = 100
}

# Monitoring Configuration
variable "enable_api_gateway_logging" {
  description = "Enable API Gateway logging"
  type        = bool
  default     = true
}

variable "api_gateway_log_level" {
  description = "API Gateway log level"
  type        = string
  default     = "INFO"
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

variable "api_lambda_log_retention_days" {
  description = "Lambda log retention in days"
  type        = number
  default     = 14
}

variable "api_gateway_log_retention_days" {
  description = "API Gateway log retention in days"
  type        = number
  default     = 14
}

# Bedrock Agent Integration
variable "bedrock_agent_id" {
  description = "Bedrock Agent ID"
  type        = string
}

variable "bedrock_agent_alias_id" {
  description = "Bedrock Agent Alias ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for Lambda deployment"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "VPC subnet IDs for Lambda deployment"
  type        = list(string)
}

variable "cidr_blocks_sg" {
  description = "CIDR blocks for security group"
  type        = list(string)
}