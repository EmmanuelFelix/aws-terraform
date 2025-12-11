terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------------------------------------------------------
# 1. STATIC ASSETS BUCKET (Public Read, Website Hosting)
# -------------------------------------------------------------------------
resource "aws_s3_bucket" "static_assets" {
  bucket = "my-company-static-assets-${random_id.suffix.hex}"
  force_destroy = true # EASIER CLEANUP FOR DEMO
}

# Allow public read access for website assets
resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.static_assets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_assets.arn}/*"
      },
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.static_assets]
}

# -------------------------------------------------------------------------
# 2. BACKUP BUCKET (Private, Versioning, Lifecycle Rules)
# -------------------------------------------------------------------------
resource "aws_s3_bucket" "backups" {
  bucket = "my-company-backups-${random_id.suffix.hex}"

  # --- ADD THIS LINE ---
  force_destroy = true 
  # ---------------------
}

# Enable versioning to recover accidental overwrites/deletes
resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt data at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Move old backups to cheaper storage (Glacier) after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "archive-old-backups"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# -------------------------------------------------------------------------
# 3. LOGS BUCKET (Strictly Private, Object Lock)
# -------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  bucket = "my-company-logs-${random_id.suffix.hex}"

  # --- ADD THIS LINE ---
  force_destroy = true 
  # ---------------------
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Helper to generate unique names
resource "random_id" "suffix" {
  byte_length = 4
}