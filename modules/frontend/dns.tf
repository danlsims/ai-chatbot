// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# Custom domain for API Gateway (conditional)
resource "aws_api_gateway_domain_name" "api" {
  count           = var.enable_custom_domain ? 1 : 0
  domain_name     = var.api_domain_name
  certificate_arn = var.ssl_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name = var.api_domain_name
  })
}

# Base path mapping for API Gateway custom domain
resource "aws_api_gateway_base_path_mapping" "api" {
  count       = var.enable_custom_domain ? 1 : 0
  api_id      = aws_api_gateway_rest_api.chatbot_api.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.api[0].domain_name
}

# Route53 record for website (conditional)
resource "aws_route53_record" "website" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.route53_hosted_zone_id
  name    = var.website_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 record for API (conditional)
resource "aws_route53_record" "api" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.route53_hosted_zone_id
  name    = var.api_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api[0].cloudfront_zone_id
    evaluate_target_health = false
  }
}

# Route53 record for IPv6 website (conditional)
resource "aws_route53_record" "website_ipv6" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = var.route53_hosted_zone_id
  name    = var.website_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}