terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region

  # If you're using a specific profile, uncomment the line below
  # profile = "your-profile-name"
  
  default_tags {
    tags = {
      Environment = "lab"
      Project     = "nginx-ecs-demo"
      ManagedBy   = "terraform"
    }
  }
}