# S3 bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = merge(
    {
      Name = var.bucket_name
    },
    var.tags
  )
}

# S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Make the bucket public
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket ACL
resource "aws_s3_bucket_acl" "website" {
  depends_on = [
    aws_s3_bucket_ownership_controls.website,
    aws_s3_bucket_public_access_block.website,
  ]

  bucket = aws_s3_bucket.website.id
  acl    = "public-read"
}

# Enable website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# S3 bucket policy to allow public read access
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      },
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Upload sample index.html
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = var.index_document
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to my S3 Static Website</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
        }
        h1 {
            color: #333;
        }
    </style>
</head>
<body>
    <h1>Hello from S3!</h1>
    <p>This is a static website hosted on AWS S3.</p>
</body>
</html>
EOF
  content_type = "text/html"
}

# Upload sample error.html
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.website.id
  key          = var.error_document
  content      = <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Error - Page Not Found</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
            color: #666;
        }
        h1 {
            color: #D32F2F;
        }
    </style>
</head>
<body>
    <h1>Error: Page Not Found</h1>
    <p>The page you are looking for doesn't exist or another error occurred.</p>
    <p><a href="/">Go back to homepage</a></p>
</body>
</html>
EOF
  content_type = "text/html"
}

# Output the website endpoint URL
output "website_endpoint" {
  description = "S3 static website endpoint"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "website_url" {
  description = "URL of the static website"
  value       = "http://${aws_s3_bucket_website_configuration.website.website_endpoint}"
}