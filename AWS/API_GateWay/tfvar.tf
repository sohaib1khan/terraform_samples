
# This variable defines  the AWS region where the resources will be deployed.
variable "aws_region" {
    description = "AWS region to deploy resources"
    type        = string
    default     = "us-east-1"
}

# This variable defines the name of API Gateway to be created.
variable "api_name" {
    description = "Name of the API Gateway"
    type        = string
    default     = "my-api-tf"
}

#  This variable defines the stage name for the API Gateway.
variable "stage_name" {
    description = "Stage name for the API Gateway"
    type        = string
    default     = "dev"
}


# This variable defines the name of the Lambda function to be created.
variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "api-lambda-function"
}

# This variable defines the dynamodb table name to be created.
variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "api-items"
}