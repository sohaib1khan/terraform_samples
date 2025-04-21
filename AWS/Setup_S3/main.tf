resource "aws_s3_bucket" "lab_bucket" {
  bucket = var.bucket_name
  tags   = var.tags
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "lab_bucket_ownership" {
  bucket = aws_s3_bucket.lab_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block public access configuration
resource "aws_s3_bucket_public_access_block" "lab_bucket_public_access" {
  bucket                  = aws_s3_bucket.lab_bucket.id
  block_public_acls       = !var.enable_website # Allow if website is enabled
  block_public_policy     = !var.enable_website # Allow if website is enabled
  ignore_public_acls      = !var.enable_website # Allow if website is enabled
  restrict_public_buckets = !var.enable_website # Allow if website is enabled
}

# Enable versioning if specified
resource "aws_s3_bucket_versioning" "lab_bucket_versioning" {
  bucket = aws_s3_bucket.lab_bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Enable server-side encryption if specified
resource "aws_s3_bucket_server_side_encryption_configuration" "lab_bucket_encryption" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.lab_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Configure static website hosting if enabled
resource "aws_s3_bucket_website_configuration" "lab_bucket_website" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.lab_bucket.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# Sample website index.html file
resource "aws_s3_object" "index_html" {
  count        = var.enable_website ? 1 : 0
  bucket       = aws_s3_bucket.lab_bucket.id
  key          = var.index_document
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>S3 Lab Challenge - Index</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            text-align: center;
        }
        h1 {
            color: #0066cc;
        }
    </style>
</head>
<body>
    <h1>S3 Lab Challenge</h1>
    <p>This is the index page for the AWS Certification S3 Lab Challenge.</p>
    <p>This bucket was created using Terraform!</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# Sample website error.html file
resource "aws_s3_object" "error_html" {
  count        = var.enable_website ? 1 : 0
  bucket       = aws_s3_bucket.lab_bucket.id
  key          = var.error_document
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>S3 Lab Challenge - Error</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            text-align: center;
        }
        h1 {
            color: #cc0000;
        }
    </style>
</head>
<body>
    <h1>Error 404</h1>
    <p>The requested file was not found.</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# Bucket policy - conditionally apply based on enable_website
resource "aws_s3_bucket_policy" "lab_bucket_policy" {
  bucket = aws_s3_bucket.lab_bucket.id
  policy = var.bucket_policy_json != "" ? var.bucket_policy_json : var.enable_website ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.lab_bucket.arn}/*"
      }
    ]
  }) : null

  # Only apply policy if website is enabled or custom policy is provided
  count = (var.enable_website || var.bucket_policy_json != "") ? 1 : 0

  # Make sure to apply this after the public access block is configured
  depends_on = [aws_s3_bucket_public_access_block.lab_bucket_public_access]
}

# Output the website endpoint if website hosting is enabled
output "website_endpoint" {
  value       = var.enable_website ? aws_s3_bucket_website_configuration.lab_bucket_website[0].website_endpoint : null
  description = "S3 static website endpoint"
}

# Output the bucket ARN
output "bucket_arn" {
  value       = aws_s3_bucket.lab_bucket.arn
  description = "S3 bucket ARN"
}

# Output the bucket name
output "bucket_name" {
  value       = aws_s3_bucket.lab_bucket.id
  description = "S3 bucket name"
}

# Output the bucket region
output "bucket_region" {
  value       = var.aws_region
  description = "S3 bucket region"
}