import json
import logging
import boto3
import os
from datetime import datetime, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
cloudwatch = boto3.client('cloudwatch')
sns = boto3.client('sns')

def scheduled_task_handler(event, context):
    """
    Lambda function that runs on a schedule to perform periodic tasks
    
    Parameters:
    - event: The event dict that contains any parameters
    - context: Runtime information provided by AWS Lambda
    
    Returns:
    - Task execution result
    """
    logger.info("Scheduled task Lambda function invoked")
    
    try:
        # 1. Check CloudWatch metrics
        check_cloudwatch_metrics()
        
        # 2. Perform cleanup operations
        cleanup_old_data()
        
        # 3. Send status report
        send_status_report()
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Scheduled tasks completed successfully",
                "timestamp": datetime.now().isoformat()
            })
        }
        
    except Exception as e:
        logger.error(f"Error executing scheduled tasks: {str(e)}")
        
        # Send alert about the failure
        try:
            topic_arn = os.environ.get('ALERT_TOPIC_ARN')
            if topic_arn:
                sns.publish(
                    TopicArn=topic_arn,
                    Subject="Scheduled Task Lambda Failure",
                    Message=f"The scheduled task Lambda function failed with error: {str(e)}"
                )
        except Exception as sns_error:
            logger.error(f"Failed to send SNS alert: {str(sns_error)}")
        
        return {
            "statusCode": 500,
            "body": json.dumps({
                "message": "Error executing scheduled tasks",
                "error": str(e)
            })
        }

def check_cloudwatch_metrics():
    """
    Check CloudWatch metrics for any anomalies
    """
    logger.info("Checking CloudWatch metrics")
    
    try:
        # Example: Get CPU utilization for EC2 instances
        now = datetime.utcnow()
        response = cloudwatch.get_metric_statistics(
            Namespace='AWS/EC2',
            MetricName='CPUUtilization',
            Dimensions=[
                {
                    'Name': 'InstanceId',
                    'Value': 'i-example'  # This would be parameterized in real use
                },
            ],
            StartTime=now - timedelta(hours=1),
            EndTime=now,
            Period=300,  # 5-minute periods
            Statistics=['Average']
        )
        
        # Process metrics
        datapoints = response.get('Datapoints', [])
        if datapoints:
            # Example: Check for high CPU usage
            for datapoint in datapoints:
                if datapoint.get('Average', 0) > 80:  # 80% CPU usage threshold
                    logger.warning(f"High CPU usage detected: {datapoint}")
                    # Send alert or take corrective action
        
        logger.info(f"Processed {len(datapoints)} metric datapoints")
        
    except Exception as e:
        logger.error(f"Error checking CloudWatch metrics: {str(e)}")
        raise

def cleanup_old_data():
    """
    Clean up old data or resources
    """
    logger.info("Performing cleanup operations")
    
    try:
        # Example implementation - this would be customized based on requirements
        
        # 1. Connect to resources (e.g., S3, DynamoDB, etc.)
        s3_client = boto3.client('s3')
        
        # 2. Set threshold date (e.g., delete files older than 30 days)
        threshold_date = datetime.now() - timedelta(days=30)
        
        # 3. Example: List objects in a bucket
        bucket_name = os.environ.get('DATA_BUCKET')
        if bucket_name:
            response = s3_client.list_objects_v2(Bucket=bucket_name)
            
            # 4. Filter and delete old objects
            objects_to_delete = []
            for obj in response.get('Contents', []):
                if obj.get('LastModified').replace(tzinfo=None) < threshold_date:
                    logger.info(f"Marking for deletion: {obj.get('Key')}")
                    objects_to_delete.append({'Key': obj.get('Key')})
            
            # 5. Delete old objects
            if objects_to_delete:
                logger.info(f"Deleting {len(objects_to_delete)} old objects")
                s3_client.delete_objects(
                    Bucket=bucket_name,
                    Delete={'Objects': objects_to_delete}
                )
        
    except Exception as e:
        logger.error(f"Error performing cleanup operations: {str(e)}")
        raise

def send_status_report():
    """
    Send a status report with the results of the scheduled task
    """
    logger.info("Sending status report")
    
    try:
        # Gather status information
        status = {
            "execution_time": datetime.now().isoformat(),
            "lambda_function": os.environ.get('AWS_LAMBDA_FUNCTION_NAME', 'unknown'),
            "environment": os.environ.get('ENVIRONMENT', 'dev'),
            # Add more status information as needed
        }
        
        # Send the report (e.g., via SNS)
        topic_arn = os.environ.get('REPORT_TOPIC_ARN')
        if topic_arn:
            sns.publish(
                TopicArn=topic_arn,
                Subject="Scheduled Task Status Report",
                Message=json.dumps(status, indent=2)
            )
            logger.info("Status report sent successfully")
        
    except Exception as e:
        logger.error(f"Error sending status report: {str(e)}")
        raise