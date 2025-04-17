import json
import logging
import boto3
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

def process_data_handler(event, context):
    """
    Lambda function to process data from S3 and store results in DynamoDB
    
    Parameters:
    - event: Contains information about the S3 event trigger
    - context: Runtime information provided by AWS Lambda
    
    Returns:
    - Processing result
    """
    logger.info("Data processor Lambda function invoked")
    logger.info(f"Event: {json.dumps(event)}")
    
    try:
        # Process S3 event
        for record in event.get('Records', []):
            # Extract S3 bucket and key information
            if 's3' in record:
                bucket = record['s3']['bucket']['name']
                key = record['s3']['object']['key']
                
                logger.info(f"Processing file {key} from bucket {bucket}")
                
                # Get the object from S3
                response = s3_client.get_object(Bucket=bucket, Key=key)
                content = response['Body'].read().decode('utf-8')
                
                # Example: Process CSV data
                if key.endswith('.csv'):
                    process_csv_data(content, bucket, key)
                # Example: Process JSON data
                elif key.endswith('.json'):
                    process_json_data(content, bucket, key)
                else:
                    logger.warning(f"Unsupported file type: {key}")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Data processing completed successfully",
                "timestamp": datetime.now().isoformat()
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing data: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Error processing data",
                "error": str(e)
            })
        }

def process_csv_data(content, bucket, key):
    """
    Process CSV data from S3
    
    Parameters:
    - content: The content of the CSV file
    - bucket: S3 bucket name
    - key: S3 object key
    """
    logger.info(f"Processing CSV data from {bucket}/{key}")
    
    # Example implementation - processing CSV data
    lines = content.strip().split('\n')
    header = lines[0].split(',')
    
    # Process each row
    for i, line in enumerate(lines[1:], 1):
        try:
            values = line.split(',')
            row_data = dict(zip(header, values))
            
            # Store processed data in DynamoDB
            store_in_dynamodb(row_data, f"{bucket}_{key}_{i}")
            
        except Exception as e:
            logger.error(f"Error processing row {i}: {str(e)}")

def process_json_data(content, bucket, key):
    """
    Process JSON data from S3
    
    Parameters:
    - content: The content of the JSON file
    - bucket: S3 bucket name
    - key: S3 object key
    """
    logger.info(f"Processing JSON data from {bucket}/{key}")
    
    # Parse JSON content
    data = json.loads(content)
    
    # Process the data
    if isinstance(data, list):
        # Process list of items
        for i, item in enumerate(data):
            store_in_dynamodb(item, f"{bucket}_{key}_{i}")
    elif isinstance(data, dict):
        # Process single item
        store_in_dynamodb(data, f"{bucket}_{key}")
    else:
        logger.warning(f"Unsupported JSON structure in {bucket}/{key}")

def store_in_dynamodb(data, id_prefix):
    """
    Store processed data in DynamoDB
    
    Parameters:
    - data: The data to store
    - id_prefix: Prefix for the item ID
    """
    try:
        # Get the DynamoDB table
        table = dynamodb.Table('ProcessedData')  # Assume this table exists
        
        # Generate a unique ID
        item_id = f"{id_prefix}_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Add metadata
        item = {
            'id': item_id,
            'timestamp': datetime.now().isoformat(),
            'data': data
        }
        
        # Store in DynamoDB
        table.put_item(Item=item)
        logger.info(f"Successfully stored item with ID: {item_id}")
        
    except Exception as e:
        logger.error(f"Error storing data in DynamoDB: {str(e)}")
        raise