# This file contains the variables for the AWS Lambda function Terraform configuration.

# It defines the AWS region to be used for all resources.
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

# It defines aws lambda function name
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "tf_python_lambda"
}

# It defines lambda function runtime
variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.9"
}

# It defines the lambda function handler
variable "lambda_handler" {
  description = "Handler for the Lambda function"
  type        = string
  default     = "lambda_function.lambda_handler"
}

# It defines the lambda timeout
variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
  default     = 10
}

# It defines the lambda memory size
variable "lambda_memory_size" {
  description = "Memory size for Lambda function in MB"
  type        = number
  default     = 128
}