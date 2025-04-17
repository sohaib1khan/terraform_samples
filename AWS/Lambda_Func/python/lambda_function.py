import json
import logging
import os
import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Main Lambda function handler
    
    Parameters:
    - event: The event dict that contains the parameters sent when the function is invoked
    - context: Runtime information provided by AWS Lambda
    
    Returns:
    - API Gateway compatible response
    """
    logger.info("Lambda function invoked")
    logger.info(f"Event: {json.dumps(event)}")
    
    # Get environment variables
    environment = os.environ.get('ENVIRONMENT', 'dev')
    
    # Process the event
    try:
        # Extract query parameters if they exist
        query_params = event.get('queryStringParameters', {}) or {}
        
        # Extract path parameters if they exist
        path_params = event.get('pathParameters', {}) or {}
        
        # Extract body if it exists
        body = {}
        if event.get('body'):
            body = json.loads(event.get('body'))
        
        # Example processing logic
        current_time = datetime.datetime.now().isoformat()
        
        # Prepare response data
        response_data = {
            "message": "Hello from Lambda!",
            "timestamp": current_time,
            "environment": environment,
            "receivedQueryParams": query_params,
            "receivedPathParams": path_params,
            "receivedBody": body,
            "lambdaRequestId": context.aws_request_id
        }
        
        # Return successful response
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(response_data)
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        
        # Return error response
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": "Error processing request",
                "error": str(e)
            })
        }