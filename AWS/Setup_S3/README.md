# S3 Bucket Lab Challenge - Terraform Setup

This project creates an S3 bucket with various configurations to practice for AWS certifications, specifically focusing on:

- Bucket and object properties
- Bucket policies
- Static website hosting
- CloudFront integration (optional)

## Prerequisites

1.  AWS CLI installed and configured
2.  Terraform installed (v1.0.0+)
3.  Basic knowledge of AWS S3 concepts

## Files

- `provider.tf` - AWS provider configuration
- `variables.tf` - Variable definitions
- `terraform.tfvars` - Variable values
- `main.tf` - S3 bucket configuration
- `cloudfront.tf` - Optional CloudFront distribution
- `tfvars.tf` - For variable exports (if needed)
- `aws-login.sh` - Script for AWS authentication
- `test_s3_bucket.py` - Python script to verify bucket configuration

## Setup Instructions

1.  Update your AWS credentials:
    
    ```bash
    ./aws-login.sh
    ```
    
2.  Initialize Terraform:
    
    ```bash
    terraform init
    ```
    
3.  Review the plan:
    
    ```bash
    terraform plan
    ```
    
4.  Apply the configuration:
    
    ```bash
    terraform apply
    ```
    
5.  Confirm by typing `yes` when prompted
    

## Configuration Options

Edit the `terraform.tfvars` file to customize:

- `bucket_name` - Name of your S3 bucket
- `enable_website` - Enable static website hosting
- `enable_versioning` - Enable object versioning
- `enable_encryption` - Enable server-side encryption
- `create_cloudfront` - Create a CloudFront distribution (default: false)

## Lab Challenge Features

This setup demonstrates:

1.  **Bucket Properties**
    
    - Versioning
    - Encryption
    - Public access controls
    - Ownership controls
2.  **Website Hosting**
    
    - Index document
    - Error document
    - Sample HTML files
3.  **Bucket Policies**
    
    - Public read permissions (when website hosting enabled)
    - Customizable policy via variable
4.  **CloudFront Integration**
    
    - Distribution linked to S3 bucket
    - HTTPS redirection
    - Caching configuration

## Verifying Your Deployment

After applying the Terraform configuration, you can verify your deployment in several ways:

1.  **AWS Management Console**:
    
    - Navigate to the S3 service in the AWS Management Console: https://console.aws.amazon.com/s3/
    - Find your bucket in the list and click on it
    - Verify settings under the "Properties" tab (versioning, encryption, static website hosting)
    - Check bucket policies under the "Permissions" tab
    - View uploaded files under the "Objects" tab
2.  **Using the Python Testing Script**:
    
    ```bash
    python3 test_s3_bucket.py --bucket YOUR_BUCKET_NAME --region YOUR_REGION
    ```
    
    This script will check various bucket configurations and display the results.
    
3.  **Static Website Testing**:
    
    - If website hosting is enabled, you can access your website at: `http://YOUR_BUCKET_NAME.s3-website-YOUR_REGION.amazonaws.com`
    - You can find this URL in the Terraform outputs or in the AWS Console under the bucket's "Properties" tab
4.  **CloudFront Testing** (if enabled):
    
    - Access your website through the CloudFront distribution URL: `https://DISTRIBUTION_ID.cloudfront.net`
    - This URL is available in the Terraform outputs or in the CloudFront section of the AWS Console
5.  **AWS CLI Verification**:
    
    ```bash
    # Check bucket exists
    aws s3 ls s3://YOUR_BUCKET_NAME/
    
    # Check website configuration
    aws s3api get-bucket-website --bucket YOUR_BUCKET_NAME
    
    # Check bucket policy
    aws s3api get-bucket-policy --bucket YOUR_BUCKET_NAME
    
    # Check versioning
    aws s3api get-bucket-versioning --bucket YOUR_BUCKET_NAME
    
    # Check encryption
    aws s3api get-bucket-encryption --bucket YOUR_BUCKET_NAME
    ```
    

## Cleanup

When you're done with the lab, destroy the resources:

```bash
terraform destroy
```

Confirm by typing `yes` when prompted.