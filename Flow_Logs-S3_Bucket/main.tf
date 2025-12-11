# ------------------------------------------------------------------
# PROVIDER CONFIGURATION
# ------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # CHANGE THIS LINE from "~> 5.0" to "~> 6.0" or ">= 6.0"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Change this to your desired AWS region
}

# ------------------------------------------------------------------
# 1. DATA SOURCE: Get the current AWS Account ID and a VPC
# ------------------------------------------------------------------

# Get the current AWS Account ID for use in the S3 Bucket Policy
data "aws_caller_identity" "current" {}

# Get the default VPC ID to attach the flow log to
data "aws_vpc" "selected" {
  default = true
}

# ------------------------------------------------------------------
# 2. S3 BUCKET DESTINATION (Log Storage)
# ------------------------------------------------------------------

# Use a random pet name to ensure the bucket name is globally unique
resource "random_pet" "bucket_name_suffix" {
  length = 2
}

resource "aws_s3_bucket" "vpc_flow_log_bucket" {
  # Bucket name must be globally unique and lowercase
  bucket = "vpc-flow-logs-${data.aws_caller_identity.current.account_id}-${random_pet.bucket_name_suffix.id}"

 
  force_destroy = true
}

# Enforce S3 Object Ownership (recommended best practice)
resource "aws_s3_bucket_ownership_controls" "vpc_flow_log_bucket_controls" {
  bucket = aws_s3_bucket.vpc_flow_log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Required ACL for VPC Flow Logs to deliver to S3 (Fixes the deprecation warning)
resource "aws_s3_bucket_acl" "flow_log_acl" {
  bucket = aws_s3_bucket.vpc_flow_log_bucket.id
  acl    = "log-delivery-write"
  # This must depend on ownership controls being set
  depends_on = [aws_s3_bucket_ownership_controls.vpc_flow_log_bucket_controls] 
}

# 2b. Block public access (standard security practice)
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.vpc_flow_log_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2c. Bucket Policy to allow the AWS Log Delivery Service to write objects
data "aws_iam_policy_document" "s3_flow_log_bucket_policy" {
  # Allows the AWS Log Delivery Service Principal to write objects
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.vpc_flow_log_bucket.arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  # Allows the AWS Log Delivery Service Principal to check bucket ACL
  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = ["s3:GetBucketAcl"]
    resources = [
      aws_s3_bucket.vpc_flow_log_bucket.arn,
    ]
  }
}

resource "aws_s3_bucket_policy" "s3_flow_log_bucket_policy" {
  bucket = aws_s3_bucket.vpc_flow_log_bucket.id
  policy = data.aws_iam_policy_document.s3_flow_log_bucket_policy.json
}

# ------------------------------------------------------------------
# 3. VPC FLOW LOG RESOURCE
# ------------------------------------------------------------------

resource "aws_flow_log" "s3_flow_log" {
  # ID of the VPC to monitor
  vpc_id               = data.aws_vpc.selected.id
  
  # Log ALL traffic (ACCEPT, REJECT, or ALL)
  traffic_type         = "ALL" 
  
  # Destination is the S3 bucket ARN
  log_destination      = aws_s3_bucket.vpc_flow_log_bucket.arn
  log_destination_type = "s3"
  
  # Standard log format, can be customized
  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
  
  # Log aggregation interval (60 seconds or 600 seconds)
  max_aggregation_interval = 60
  
  # Ensure the Flow Log is created only after all bucket settings are applied
  depends_on = [
    aws_s3_bucket_policy.s3_flow_log_bucket_policy,
    aws_s3_bucket_acl.flow_log_acl
  ]
}

# ------------------------------------------------------------------
# OUTPUTS (To quickly find the created resources)
# ------------------------------------------------------------------

output "vpc_flow_log_id" {
  description = "The ID of the created VPC Flow Log."
  value       = aws_flow_log.s3_flow_log.id
}

output "s3_flow_log_bucket_name" {
  description = "The name of the S3 bucket storing the flow logs."
  value       = aws_s3_bucket.vpc_flow_log_bucket.bucket
}

output "monitored_vpc_id" {
  description = "The ID of the VPC being monitored."
  value       = data.aws_vpc.selected.id
}

# ------------------------------------------------------------------
