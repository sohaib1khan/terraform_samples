#!/usr/bin/env python3
"""
S3 Bucket Testing Script

This script tests various features of an S3 bucket created with Terraform.
It demonstrates how to interact with S3 using the boto3 library.
"""

import boto3
import json
import argparse
import sys
from botocore.exceptions import ClientError


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Test S3 bucket features')
    parser.add_argument('--bucket', required=True, help='S3 bucket name')
    parser.add_argument('--region', default='us-east-1', help='AWS region')
    parser.add_argument('--profile', default=None, help='AWS profile')
    return parser.parse_args()


def get_s3_client(region, profile):
    """Create an S3 client."""
    session = boto3.Session(profile_name=profile, region_name=region) if profile else boto3.Session(region_name=region)
    return session.client('s3')


def check_bucket_exists(s3_client, bucket_name):
    """Check if the bucket exists."""
    try:
        s3_client.head_bucket(Bucket=bucket_name)
        print(f"✅ Bucket '{bucket_name}' exists")
        return True
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == '404':
            print(f"❌ Bucket '{bucket_name}' does not exist")
        elif error_code == '403':
            print(f"❌ Access denied to bucket '{bucket_name}'")
        else:
            print(f"❌ Error checking bucket: {e}")
        return False


def check_bucket_policy(s3_client, bucket_name):
    """Check and display the bucket policy."""
    try:
        policy = s3_client.get_bucket_policy(Bucket=bucket_name)
        policy_json = json.loads(policy['Policy'])
        print(f"✅ Bucket policy found:")
        print(json.dumps(policy_json, indent=2))
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchBucketPolicy':
            print("❓ No bucket policy configured")
        else:
            print(f"❌ Error getting bucket policy: {e}")
        return False


def check_versioning(s3_client, bucket_name):
    """Check if versioning is enabled."""
    try:
        versioning = s3_client.get_bucket_versioning(Bucket=bucket_name)
        status = versioning.get('Status', 'Not configured')
        
        if status == 'Enabled':
            print("✅ Versioning is enabled")
            return True
        else:
            print(f"ℹ️ Versioning status: {status}")
            return False
    except ClientError as e:
        print(f"❌ Error checking versioning: {e}")
        return False


def check_encryption(s3_client, bucket_name):
    """Check if encryption is enabled."""
    try:
        encryption = s3_client.get_bucket_encryption(Bucket=bucket_name)
        rules = encryption.get('ServerSideEncryptionConfiguration', {}).get('Rules', [])
        
        if rules:
            print("✅ Encryption is enabled:")
            for rule in rules:
                print(f"  - Algorithm: {rule.get('ApplyServerSideEncryptionByDefault', {}).get('SSEAlgorithm', 'Unknown')}")
            return True
        else:
            print("❓ No encryption rules found")
            return False
    except ClientError as e:
        if e.response['Error']['Code'] == 'ServerSideEncryptionConfigurationNotFoundError':
            print("❌ Encryption is not enabled")
        else:
            print(f"❌ Error checking encryption: {e}")
        return False


def check_website_config(s3_client, bucket_name):
    """Check if static website hosting is enabled."""
    try:
        website = s3_client.get_bucket_website(Bucket=bucket_name)
        print("✅ Website hosting is enabled:")
        
        if 'IndexDocument' in website:
            print(f"  - Index document: {website['IndexDocument']['Suffix']}")
        
        if 'ErrorDocument' in website:
            print(f"  - Error document: {website['ErrorDocument']['Key']}")
        
        endpoint = f"http://{bucket_name}.s3-website-{s3_client.meta.region_name}.amazonaws.com"
        print(f"  - Website endpoint: {endpoint}")
        
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchWebsiteConfiguration':
            print("ℹ️ Website hosting is not enabled")
        else:
            print(f"❌ Error checking website config: {e}")
        return False


def list_objects(s3_client, bucket_name, max_items=10):
    """List objects in the bucket."""
    try:
        objects = s3_client.list_objects_v2(Bucket=bucket_name, MaxKeys=max_items)
        
        if 'Contents' in objects:
            print(f"✅ Objects in bucket (showing up to {max_items}):")
            for obj in objects['Contents']:
                print(f"  - {obj['Key']} ({obj['Size']} bytes, last modified: {obj['LastModified']})")
            
            if objects.get('IsTruncated', False):
                print(f"  ... and more objects (truncated)")
        else:
            print("ℹ️ Bucket is empty")
        
        return True
    except ClientError as e:
        print(f"❌ Error listing objects: {e}")
        return False


def upload_test_object(s3_client, bucket_name):
    """Upload a test object to the bucket."""
    test_key = 'test-upload.txt'
    test_content = 'This is a test file uploaded by the S3 bucket testing script.'
    
    try:
        s3_client.put_object(
            Bucket=bucket_name,
            Key=test_key,
            Body=test_content,
            ContentType='text/plain'
        )
        print(f"✅ Test object '{test_key}' uploaded successfully")
        return True
    except ClientError as e:
        print(f"❌ Error uploading test object: {e}")
        return False


def main():
    """Main function to test S3 bucket features."""
    args = parse_arguments()
    
    print(f"\n🔍 Testing S3 bucket: {args.bucket} in region {args.region}\n")
    
    # Create S3 client
    s3_client = get_s3_client(args.region, args.profile)
    
    # Check if bucket exists
    if not check_bucket_exists(s3_client, args.bucket):
        sys.exit(1)
    
    print("\n--- Bucket Configuration ---")
    check_bucket_policy(s3_client, args.bucket)
    check_versioning(s3_client, args.bucket)
    check_encryption(s3_client, args.bucket)
    check_website_config(s3_client, args.bucket)
    
    print("\n--- Bucket Contents ---")
    list_objects(s3_client, args.bucket)
    
    # Ask if user wants to upload a test object
    upload = input("\nDo you want to upload a test object to the bucket? (y/n): ")
    if upload.lower() == 'y':
        upload_test_object(s3_client, args.bucket)
        list_objects(s3_client, args.bucket)
    
    print("\n✨ S3 bucket testing completed ✨\n")


if __name__ == "__main__":
    main()