# This file contains the variables for the S3 bucket setup in AWS using Terraform.


# Define the AWS region variable
aws_region        = "us-east-1"
bucket_name       = "my-s3-lab-challenge-bucket"
enable_website    = true
enable_versioning = true
enable_encryption = true

# Define the website endpoint variable
tags = {
  Environment = "Lab"
  Project     = "AWS Certification Practice"
  Owner       = "DevOps Engineer"
}