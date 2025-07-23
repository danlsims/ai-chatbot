// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.app_name}-${var.env_name}"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy.json
  
  tags = {
    Name        = "${var.app_name}-${var.env_name}-kms-key"
    Environment = var.env_name
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.app_name}-${var.env_name}-key"
  target_key_id = aws_kms_key.main.key_id
}