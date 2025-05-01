# provider.tf - AWS Provider Configuration

# Configure the AWS Provider
# This sets up the connection to AWS using your credentials
provider "aws" {
  region = var.aws_region # Using the region defined in variables.tf

  # Optional: Add profile configuration if you're using AWS profiles
  # profile = "default"

  # Default tags to apply to all resources
  default_tags {
    tags = var.default_tags
  }
}

# Required Terraform version and providers
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Using version 5.x of the AWS provider
    }
  }

  required_version = ">= 1.0.0" # Requires Terraform 1.0.0 or higher
}