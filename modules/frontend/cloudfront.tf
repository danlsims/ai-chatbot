// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.app_name}-${var.env_name}-frontend-oac"
  description                       = "Origin Access Control for ${var.app_name} frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution for frontend
resource "aws_cloudfront_distribution" "frontend" {
  comment             = var.cloudfront_comment
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  retain_on_delete    = false
  wait_for_deployment = true

  # S3 origin configuration
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
    origin_id                = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${aws_s3_bucket.frontend.id}"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    # Response headers policy for security
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id

    # Function associations for SPA routing
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_router.arn
    }
  }

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern           = "/js/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  ordered_cache_behavior {
    path_pattern           = "/css/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.frontend.id}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000
  }

  # Custom error responses for SPA
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Geo restrictions (optional)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS configuration
  viewer_certificate {
    dynamic "acm_certificate_arn" {
      for_each = var.enable_custom_domain ? [1] : []
      content {
        acm_certificate_arn      = var.ssl_certificate_arn
        ssl_support_method       = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
      }
    }

    dynamic "cloudfront_default_certificate" {
      for_each = var.enable_custom_domain ? [] : [1]
      content {
        cloudfront_default_certificate = true
      }
    }
  }

  # Custom domain configuration
  dynamic "aliases" {
    for_each = var.enable_custom_domain ? [var.website_domain_name] : []
    content {
      aliases = [var.website_domain_name]
    }
  }

  # Logging configuration
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  tags = merge(local.common_tags, {
    Name = "${var.app_name}-${var.env_name}-frontend-distribution"
  })

  depends_on = [
    aws_cloudfront_origin_access_control.frontend,
    aws_s3_bucket.frontend
  ]
}

# CloudFront function for SPA routing
resource "aws_cloudfront_function" "spa_router" {
  name    = "${var.app_name}-${var.env_name}-spa-router"
  runtime = "cloudfront-js-1.0"
  comment = "Function to handle SPA routing"
  publish = true
  code    = file("${path.module}/cloudfront-functions/spa-router.js")
}

# Security headers policy
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${var.app_name}-${var.env_name}-security-headers"
  comment = "Security headers for frontend application"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' ${var.identity_center_issuer_url} ${local.api_url};"
      override                = true
    }
  }

  cors_config {
    access_control_allow_credentials = true
    access_control_allow_headers {
      items = var.cors_allowed_headers
    }
    access_control_allow_methods {
      items = var.cors_allowed_methods
    }
    access_control_allow_origins {
      items = local.cors_origins
    }
    access_control_expose_headers {
      items = ["Date", "x-api-id"]
    }
    access_control_max_age_sec = 300
    origin_override           = true
  }
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.frontend_bucket_name}-cloudfront-logs"

  tags = merge(local.common_tags, {
    Name = "${var.frontend_bucket_name}-cloudfront-logs"
    Type = "CloudFrontLogs"
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}