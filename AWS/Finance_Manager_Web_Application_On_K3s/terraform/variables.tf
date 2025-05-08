# variables.tf - Variable definitions for the Finance Manager on K3s deployment

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # N. Virginia region, change as needed
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (Free tier eligible)"
  type        = string
  default     = "t2.micro"  # Free tier eligible instance type
}

variable "key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
  default     = "finance-app-key"  # This will be overridden by the deploy script
}

variable "key_path" {
  description = "Path to the SSH private key file"
  type        = string
  default     = "~/.ssh/id_rsa"  # This will be overridden by the deploy script
}