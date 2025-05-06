terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment these lines once you've created your S3 bucket for state storage
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "k3s-deployment/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "K3s-AWS-Deployment"
      Environment = var.environment
      Terraform   = "true"
    }
  }
}