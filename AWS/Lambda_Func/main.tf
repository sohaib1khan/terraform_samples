# Common IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Basic execution policy attachment
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Additional permissions for S3 and DynamoDB access
resource "aws_iam_policy" "lambda_s3_dynamodb" {
  name        = "lambda-s3-dynamodb-policy"
  description = "Allow Lambda to access S3 and DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:s3:::*/*", "arn:aws:s3:::*"]
      },
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:*:*:table/*"
      },
      {
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_dynamodb.arn
}

# Create DynamoDB table for processed data
resource "aws_dynamodb_table" "processed_data" {
  name         = "ProcessedData"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Create S3 bucket for data processing
resource "aws_s3_bucket" "data_bucket" {
  bucket = "data-processing-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# SNS Topics for alerts and reports
resource "aws_sns_topic" "alerts" {
  name = "lambda-alerts"
}

resource "aws_sns_topic" "reports" {
  name = "lambda-reports"
}

# 1. API Lambda Function
data "archive_file" "api_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/python/lambda_function.py"
  output_path = "${path.module}/api_lambda.zip"
}

resource "aws_lambda_function" "api_function" {
  filename         = data.archive_file.api_lambda_package.output_path
  function_name    = "api-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = var.lambda_runtime
  source_code_hash = data.archive_file.api_lambda_package.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      ENVIRONMENT = "dev"
    }
  }
}

resource "aws_cloudwatch_log_group" "api_lambda_logs" {
  name              = "/aws/lambda/api-lambda"
  retention_in_days = 14
}

# API Gateway for API Lambda
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "api-lambda-gateway"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda_stage" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.lambda_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.api_function.invoke_arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# 2. Data Processor Lambda Function
data "archive_file" "data_processor_package" {
  type        = "zip"
  source_file = "${path.module}/python/data_processor.py"
  output_path = "${path.module}/data_processor.zip"
}

resource "aws_lambda_function" "data_processor" {
  filename         = data.archive_file.data_processor_package.output_path
  function_name    = "data-processor"
  role             = aws_iam_role.lambda_role.arn
  handler          = "data_processor.process_data_handler"
  runtime          = var.lambda_runtime
  source_code_hash = data.archive_file.data_processor_package.output_base64sha256
  timeout          = 60  # Longer timeout for data processing
  memory_size      = 256 # More memory for data processing

  environment {
    variables = {
      ENVIRONMENT = "dev"
    }
  }
}

resource "aws_cloudwatch_log_group" "data_processor_logs" {
  name              = "/aws/lambda/data-processor"
  retention_in_days = 14
}

# S3 Event Trigger for Data Processor
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.data_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.data_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.data_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}

# 3. Scheduled Task Lambda Function
data "archive_file" "scheduled_task_package" {
  type        = "zip"
  source_file = "${path.module}/python/scheduled_task.py"
  output_path = "${path.module}/scheduled_task.zip"
}

resource "aws_lambda_function" "scheduled_task" {
  filename         = data.archive_file.scheduled_task_package.output_path
  function_name    = "scheduled-task"
  role             = aws_iam_role.lambda_role.arn
  handler          = "scheduled_task.scheduled_task_handler"
  runtime          = var.lambda_runtime
  source_code_hash = data.archive_file.scheduled_task_package.output_base64sha256
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      ENVIRONMENT      = "dev"
      DATA_BUCKET      = aws_s3_bucket.data_bucket.id
      ALERT_TOPIC_ARN  = aws_sns_topic.alerts.arn
      REPORT_TOPIC_ARN = aws_sns_topic.reports.arn
    }
  }
}

resource "aws_cloudwatch_log_group" "scheduled_task_logs" {
  name              = "/aws/lambda/scheduled-task"
  retention_in_days = 14
}

# CloudWatch Event Rule for scheduled execution
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "run-lambda-on-schedule"
  description         = "Run Lambda function on a schedule"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "scheduled_lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.scheduled_task.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_task.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# Output the API Gateway URL
output "api_gateway_url" {
  value = "${aws_apigatewayv2_api.lambda_api.api_endpoint}/"
}

# Output the S3 bucket name for data processing
output "data_bucket_name" {
  value = aws_s3_bucket.data_bucket.id
}