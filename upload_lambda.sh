#!/bin/bash
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

# This script packages and uploads the Lambda function code to S3

set -e

# Get the bucket name from terraform.tfvars
BUCKET_NAME=$(grep code_base_bucket terraform.tfvars | cut -d '=' -f2 | tr -d ' "')
ZIP_NAME=$(grep code_base_zip terraform.tfvars | cut -d '=' -f2 | tr -d ' "')

# Check if bucket exists, if not create it
aws s3api head-bucket --bucket $BUCKET_NAME 2>/dev/null || aws s3 mb s3://$BUCKET_NAME

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory $TEMP_DIR"

# Copy Lambda code to temporary directory
cp -r lambda-code/lambda-funtion/* $TEMP_DIR/

# Install dependencies
cd $TEMP_DIR
pip install -r requirements.txt -t .

# Create zip file
zip -r $ZIP_NAME ./*

# Upload to S3
aws s3 cp $ZIP_NAME s3://$BUCKET_NAME/

# Clean up
cd -
rm -rf $TEMP_DIR

echo "Lambda code uploaded to s3://$BUCKET_NAME/$ZIP_NAME"