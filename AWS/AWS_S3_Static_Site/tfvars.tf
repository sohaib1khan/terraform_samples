# This file contains the variables for the S3 static site deployment.

# This variable defines the region where the AWS resources will be deployed.
variable "region" {
  description = "AWS region to deploy the resources"
  default     = "us-east-1"
}

# This variable defines the name of the S3 bucket that will be used for static website hosting.
variable "bucket_name" {
  description = "Name of the S3 bucket for the static website hosting"
  type        = string
}



# This variable defines the index document for the static website hosting.
variable "index_document" {
  description = "The name of the index document for the static website"
  type        = string
  default     = "index.html"
}


# This variable defines the error document for the static website hosting.
variable "error_document" {
  description = "The name of the error document for the static website"
  type        = string
  default     = "error.html"
}


variable "tags" {
  description = "Tags for the S3 bucket"
  type        = map(string)
  default     = {
    Environment = "Production"
    Owner       = "Admin"
  }
}