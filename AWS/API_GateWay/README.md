# AWS Serverless REST API Deployment Guide

This guide helps you deploy a serverless REST API using AWS API Gateway, Lambda, and DynamoDB with Terraform. After following the deployment steps, use the verification section to confirm your resources are correctly configured.

## Project Overview

This project implements a serverless REST API with:
- **API Gateway**: Creates REST API endpoints for `GET` and `POST` methods
- **Lambda Function**: Python function to handle API requests
- **DynamoDB**: NoSQL database to store items
- **IAM**: Roles and policies for secure service access

## Deployment Steps

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Validate your configuration**:
   ```bash
   terraform validate
   ```

3. **Preview the changes**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

5. After successful deployment, Terraform will output the API URL you can use to test your API.

## Verification Steps

### 1. API Gateway Verification

1. **Navigate to API Gateway Console**:
   - Go to AWS Management Console → API Gateway
   - Find and click on your API named "my-api" (or your custom name from var.api_name)

2. **Verify API Structure**:
   - Confirm the "/items" resource exists
   - Check that GET and POST methods are configured on this resource
   - Verify integrations point to your Lambda function

3. **Verify Deployment**:
   - Go to "Stages" in the left navigation
   - Confirm a "dev" stage exists (or your custom stage from var.stage_name)
   - Note the "Invoke URL" - this is what you'll use to test your API

4. **Test API Directly in Console**:
   - In the Resources section, select the GET method on /items
   - Click the "TEST" link
   - Leave the request body empty and click "Test"
   - Verify you receive a 200 response

### 2. Lambda Function Verification

1. **Navigate to Lambda Console**:
   - Go to AWS Management Console → Lambda
   - Find and click on your function named "api-lambda-function" (or your custom name from var.lambda_function_name)

2. **Verify Function Configuration**:
   - Check the Runtime is Python 3.9
   - Verify the Handler is set to "lambda_function.lambda_handler"
   - Confirm Memory is set to 128 MB and Timeout to 10 seconds

3. **Verify Code Content**:
   - Review the function code to ensure it contains the API handling logic
   - Verify it has handlers for both GET and POST methods

4. **Check Permissions**:
   - Navigate to the "Configuration" tab and select "Permissions"
   - Verify the execution role has access to both DynamoDB and CloudWatch Logs

5. **Test Lambda Function**:
   - Click "Test" tab
   - Create a new test event with the following template for a GET request:
     ```json
     {
       "httpMethod": "GET",
       "path": "/items",
       "headers": {},
       "queryStringParameters": {},
       "body": null
     }
     ```
   - Run the test and verify you get a successful execution

### 3. DynamoDB Verification

1. **Navigate to DynamoDB Console**:
   - Go to AWS Management Console → DynamoDB
   - Find and click on your table named "api-items" (or your custom name from var.dynamodb_table_name)

2. **Verify Table Structure**:
   - Confirm the primary key is "id" (String)
   - Verify the table is using on-demand (PAY_PER_REQUEST) billing mode

3. **Add a Test Item**:
   - Click "Create Item"
   - Add an item with:
     - id: "test-id-1" (String)
     - content: "Test content" (String)
     - createdAt: (current date in ISO format, e.g., "2025-04-16T12:00:00Z")
   - Save the item

### 4. End-to-End Testing

1. **Test GET Endpoint**:
   Use curl or a similar tool:
   ```bash
   curl -X GET <your-api-url>
   ```
   You should receive a JSON response containing your test item.

2. **Test POST Endpoint**:
   ```bash
   curl -X POST <your-api-url> \
     -H "Content-Type: application/json" \
     -d '{"content": "Item created via API"}'
   ```
   You should receive a response with a new item containing a generated UUID, your content, and a creation timestamp.

3. **Verify in DynamoDB**:
   - Return to DynamoDB console
   - Use the "Explore table items" feature to confirm your new item was added

## Understanding How It Works

- **Lambda Integration**: API Gateway sends requests to Lambda using the AWS_PROXY integration type, which passes the full request details to Lambda
- **Request Processing**: The Lambda function parses the request, identifies the HTTP method, and routes to the appropriate handler
- **DynamoDB Interaction**: Lambda uses boto3 to read from and write to DynamoDB
- **Response Format**: The Lambda function formats responses with proper status codes, headers (including CORS headers), and JSON body content

## Troubleshooting Tips

1. **Check CloudWatch Logs**:
   - Navigate to CloudWatch → Log groups
   - Find the log group for your Lambda function (/aws/lambda/api-lambda-function)
   - Review recent log streams for error messages

2. **API Gateway Execution Issues**:
   - In API Gateway console, enable CloudWatch logs for your API
   - Set the Log Level to "INFO" for detailed request/response logging

3. **Permission Problems**:
   - Verify the Lambda execution role has the necessary permissions for DynamoDB and CloudWatch Logs
   - Check the Lambda resource policy allows invocation from API Gateway

## Next Steps

Now that you have a working API, consider enhancing it with:

1. **Authentication**: Add AWS Cognito or API keys
2. **Input Validation**: Implement request validation using API Gateway validators
3. **Caching**: Enable API Gateway caching to improve performance
4. **Custom Domain**: Configure a custom domain name for your API
5. **Additional Operations**: Implement PUT and DELETE methods for complete CRUD functionality