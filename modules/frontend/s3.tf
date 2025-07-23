// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

# S3 bucket for static website hosting
resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name

  tags = merge(local.common_tags, {
    Name = var.frontend_bucket_name
    Type = "StaticWebsite"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy for CloudFront OAC access
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = local.s3_bucket_policy

  depends_on = [
    aws_s3_bucket_public_access_block.frontend,
    aws_cloudfront_distribution.frontend
  ]
}

# Upload default index.html file
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  content_type = "text/html"
  kms_key_id   = var.kms_key_id

  content = templatefile("${path.module}/website/index.html", {
    api_url                        = local.api_url
    identity_center_issuer_url     = var.identity_center_issuer_url
    identity_center_client_id      = var.identity_center_client_id
    website_url                    = local.website_url
  })

  etag = md5(templatefile("${path.module}/website/index.html", {
    api_url                        = local.api_url
    identity_center_issuer_url     = var.identity_center_issuer_url
    identity_center_client_id      = var.identity_center_client_id
    website_url                    = local.website_url
  }))

  tags = local.common_tags
}

# Upload default error.html file
resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "error.html"
  content_type = "text/html"
  kms_key_id   = var.kms_key_id

  content = file("${path.module}/website/error.html")
  etag    = filemd5("${path.module}/website/error.html")

  tags = local.common_tags
}

# Upload JavaScript application
resource "aws_s3_object" "app_js" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "js/app.js"
  content_type = "application/javascript"
  kms_key_id   = var.kms_key_id

  content = templatefile("${path.module}/website/js/app.js", {
    api_url                        = local.api_url
    identity_center_issuer_url     = var.identity_center_issuer_url
    identity_center_client_id      = var.identity_center_client_id
    website_url                    = local.website_url
  })

  etag = md5(templatefile("${path.module}/website/js/app.js", {
    api_url                        = local.api_url
    identity_center_issuer_url     = var.identity_center_issuer_url
    identity_center_client_id      = var.identity_center_client_id
    website_url                    = local.website_url
  }))

  tags = local.common_tags
}

# Upload CSS styles
resource "aws_s3_object" "app_css" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "css/app.css"
  content_type = "text/css"
  kms_key_id   = var.kms_key_id

  content = file("${path.module}/website/css/app.css")
  etag    = filemd5("${path.module}/website/css/app.css")

  tags = local.common_tags
}