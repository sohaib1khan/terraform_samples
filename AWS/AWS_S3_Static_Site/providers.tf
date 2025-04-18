# This file is used to configure the AWS provider for Terraform.


# It specifies the required provider version and the AWS region to be used.
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    required_version = ">= 1.2.0"
}

# Configure the AWS Provider 
provider "aws" {
    region = "us-west-2"
}