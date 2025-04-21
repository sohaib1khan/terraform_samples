# This file defines the variables used in the Terraform configuration for setting up an S3 bucket.

# Define the AWS region variable
variable "aws_region" {
  description = " AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}


# Define the  AWS profile variable
variable "aws_profile" {
  description = "AWS profile to use for authentication"
  type        = string
  default     = "default"
}


# Define the S3 bucket name variable
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}


#  Defines the enable website variable for static website hosting
variable "enable_website" {
  description = " Whether to enable static website hosting"
  type        = bool
  default     = false
}


# Define the website endpoint variable
variable "index_document" {
  description = "Index document for static website"
  type        = string
  default     = "index.html"
}


# Define the error document variable
variable "error_document" {
  description = "Error document for static website"
  type        = string
  default     = "error.html"
}


# Define the bucket policy variable
variable "bucket_policy_json" {
  description = "Custom bucket policy JSON document (optional)"
  type        = string
  default     = ""
}


# Define  tags variable 
variable "tags" {
  description = "Tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}


# Define enable versioning variable 
variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = false
}


# Define enable encryption variable
variable "enable_encryption" {
  description = "Enable server-side encryption for the bucket"
  type        = bool
  default     = true
}
