# AWS Lambda Functions Project

This project deploys three AWS Lambda functions using Terraform:
1. **API Lambda** - Accessible via API Gateway
2. **Data Processor Lambda** - Triggered by S3 file uploads
3. **Scheduled Task Lambda** - Runs daily via CloudWatch Events

## Deployed Resources

- **API Gateway URL**: https://cgbbkf0225.execute-api.us-east-1.amazonaws.com/
- **S3 Bucket for Data Processing**: data-processing-8ji2xhvc

## Verification Steps

### 1. Verify API Lambda Function

This Lambda function is exposed via API Gateway and returns information about the request.

```bash
# Test using curl
curl -X GET "https://cgbbkf0225.execute-api.us-east-1.amazonaws.com/"

# Test with query parameters
curl -X GET "https://cgbbkf0225.execute-api.us-east-1.amazonaws.com/?param1=value1&param2=value2"

# Test with POST request and JSON body
curl -X POST "https://cgbbkf0225.execute-api.us-east-1.amazonaws.com/" \
  -H "Content-Type: application/json" \
  -d '{"key1":"value1", "key2":"value2"}'
```

Expected response:
```json
{
  "message": "Hello from Lambda!",
  "timestamp": "2025-04-16T12:34:56.789Z",
  "environment": "dev",
  "receivedQueryParams": {...},
  "receivedPathParams": {...},
  "receivedBody": {...},
  "lambdaRequestId": "a1b2c3d4-5678-90ab-cdef-EXAMPLE11111"
}
```

### 2. Verify Data Processor Lambda Function

This Lambda function is triggered when files are uploaded to the S3 bucket.

```bash
# Upload the sample JSON file
aws s3 cp sample-data.json s3://data-processing-8ji2xhvc/

# Upload the sample CSV file
aws s3 cp sample-data.csv s3://data-processing-8ji2xhvc/
```

To verify:
1. Check the CloudWatch Logs for the data-processor Lambda function:
   ```bash
   aws logs filter-log-events --log-group-name "/aws/lambda/data-processor" --limit 5
   ```

2. Check if data was stored in DynamoDB:
   ```bash
   aws dynamodb scan --table-name ProcessedData --limit 10
   ```

### 3. Verify Scheduled Task Lambda Function

This Lambda function runs daily, but you can test it by invoking it manually:

```bash
# Invoke the Lambda function manually
aws lambda invoke \
  --function-name scheduled-task \
  --payload '{}' \
  output.json

# Check the output
cat output.json
```

To verify it's working correctly:

1. Check the CloudWatch Logs:
   ```bash
   aws logs filter-log-events --log-group-name "/aws/lambda/scheduled-task" --limit 5
   ```

2. Check if SNS topics received messages (if any alerts or reports were generated):
   ```bash
   # List recent SNS published messages (this may require CloudTrail to be enabled)
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=Publish
   ```

## Monitoring and Debugging

### View Lambda Function Logs

```bash
# View API Lambda logs
aws logs filter-log-events --log-group-name "/aws/lambda/api-lambda"

# View Data Processor Lambda logs
aws logs filter-log-events --log-group-name "/aws/lambda/data-processor"

# View Scheduled Task Lambda logs
aws logs filter-log-events --log-group-name "/aws/lambda/scheduled-task"
```

### Check Lambda Function Configurations

```bash
# List all Lambda functions
aws lambda list-functions

# Get details about a specific function
aws lambda get-function --function-name api-lambda
```

### Check CloudWatch Metrics

You can view Lambda performance metrics in the AWS Management Console under CloudWatch → Metrics → Lambda, or using the AWS CLI:

```bash
# Get Lambda function metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=api-lambda \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum
```

## Cleaning Up

When you're done testing, you can destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### API Gateway Issues

If the API Gateway URL doesn't work:
1. Check if the API Gateway deployment was successful
2. Verify the Lambda permission allows API Gateway to invoke the function
3. Check API Gateway CloudWatch logs

### S3 Trigger Issues

If the Data Processor isn't triggered by S3 uploads:
1. Verify the S3 bucket notification configuration
2. Check Lambda permissions allow S3 to invoke the function
3. Make sure the file suffixes match the configured triggers (.csv or .json)

### DynamoDB Issues

If data isn't appearing in DynamoDB:
1. Check the Lambda execution role has DynamoDB write permissions
2. Verify the table name matches in the code and Terraform configuration
3. Check for errors in the Lambda function logs