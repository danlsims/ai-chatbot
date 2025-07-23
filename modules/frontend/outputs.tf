// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Website URLs
output "website_url" {
  description = "URL of the frontend website"
  value       = local.website_url
}

output "api_url" {
  description = "URL of the API Gateway"
  value       = var.enable_custom_domain ? "https://${var.api_domain_name}" : "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/${var.api_stage_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

# S3 Resources
output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket hosting the frontend"
  value       = aws_s3_bucket.frontend.arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

# CloudFront Resources
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}

# API Gateway Resources
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.chatbot_api.id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.chatbot_api.arn
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.chatbot_api.execution_arn
}

output "api_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

# Lambda Resources
output "api_proxy_lambda_arn" {
  description = "ARN of the API proxy Lambda function"
  value       = aws_lambda_function.api_proxy.arn
}

output "api_proxy_lambda_name" {
  description = "Name of the API proxy Lambda function"
  value       = aws_lambda_function.api_proxy.function_name
}

output "jwt_authorizer_lambda_arn" {
  description = "ARN of the JWT authorizer Lambda function"
  value       = aws_lambda_function.jwt_authorizer.arn
}

output "jwt_authorizer_lambda_name" {
  description = "Name of the JWT authorizer Lambda function"
  value       = aws_lambda_function.jwt_authorizer.function_name
}

output "health_check_lambda_arn" {
  description = "ARN of the health check Lambda function"
  value       = aws_lambda_function.health_check.arn
}

output "health_check_lambda_name" {
  description = "Name of the health check Lambda function"
  value       = aws_lambda_function.health_check.function_name
}

# Security Resources
output "lambda_security_group_id" {
  description = "ID of the Lambda security group"
  value       = aws_security_group.lambda_api.id
}

# DNS Resources (conditional)
output "api_domain_name" {
  description = "Custom domain name for the API (if enabled)"
  value       = var.enable_custom_domain ? var.api_domain_name : null
}

output "website_domain_name" {
  description = "Custom domain name for the website (if enabled)"
  value       = var.enable_custom_domain ? var.website_domain_name : null
}

# CloudWatch Log Groups
output "api_proxy_log_group_name" {
  description = "Name of the API proxy Lambda log group"
  value       = aws_cloudwatch_log_group.api_proxy_lambda.name
}

output "jwt_authorizer_log_group_name" {
  description = "Name of the JWT authorizer Lambda log group"
  value       = aws_cloudwatch_log_group.jwt_authorizer_lambda.name
}

output "health_check_log_group_name" {
  description = "Name of the health check Lambda log group"
  value       = aws_cloudwatch_log_group.health_check_lambda.name
}

output "api_gateway_log_group_name" {
  description = "Name of the API Gateway log group (if enabled)"
  value       = var.enable_api_gateway_logging ? aws_cloudwatch_log_group.api_gateway[0].name : null
}

# Usage Plan
output "api_usage_plan_id" {
  description = "ID of the API Gateway usage plan"
  value       = aws_api_gateway_usage_plan.main.id
}

# Additional metadata
output "cors_origins" {
  description = "Configured CORS origins"
  value       = local.cors_origins
}

output "identity_center_configuration" {
  description = "Identity Center configuration details"
  value = {
    issuer_url = var.identity_center_issuer_url
    client_id  = var.identity_center_client_id
  }
  sensitive = false
}