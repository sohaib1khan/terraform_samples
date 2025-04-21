# This Terraform configuration sets up a CloudFront distribution for an S3 bucket

# Define the CloudFront distribution variable
variable "create_cloudfront" {
  description = "Whether to create a CloudFront distribution for the S3 website"
  type        = bool
  default     = false
}


# Create a CloudFront distribution for the S3 bucket
resource "aws_cloudfront_distribution" "s3_distribution" {
  count = (var.enable_website && var.create_cloudfront) ? 1 : 0

  origin {
    domain_name = aws_s3_bucket.lab_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.lab_bucket.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.index_document

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.lab_bucket.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

output "cloudfront_domain_name" {
  value       = (var.enable_website && var.create_cloudfront) ? aws_cloudfront_distribution.s3_distribution[0].domain_name : null
  description = "CloudFront distribution domain name"
}