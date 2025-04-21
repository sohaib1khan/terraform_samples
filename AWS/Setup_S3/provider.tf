provider "aws" {
  region = var.aws_region
  # If you're using aws-login.sh to set up credentials, 
  # you might not need explicit profile configuration here
  # Uncomment if needed
  # profile = var.aws_profile

}


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# If you want to use a backend for state storage
# backend "s3" {
#   bucket = "your-terraform-state-bucket"
#   key    = "setup-s3/terraform.tfstate"
#   region = "your-region"
# }
