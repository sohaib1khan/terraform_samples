#!/bin/bash

# Set a more descriptive script name
echo "AWS Authentication Script"

# Check if AWS credentials file exists
if [ ! -f ~/.aws/credentials ]; then
    echo "Error: AWS credentials file not found."
    echo "Creating default AWS config directory..."
    mkdir -p ~/.aws
    touch ~/.aws/credentials
    echo "Please add your credentials to ~/.aws/credentials"
    exit 1
fi

# Get the AWS access key ID and secret access key from the credentials file
# More robust pattern matching with error handling
access_key=$(grep -m 1 aws_access_key_id ~/.aws/credentials | cut -d'=' -f2 | tr -d ' ')
if [ -z "$access_key" ]; then
    echo "Error: Could not find aws_access_key_id in credentials file."
    exit 1
fi

secret_key=$(grep -m 1 aws_secret_access_key ~/.aws/credentials | cut -d'=' -f2 | tr -d ' ')
if [ -z "$secret_key" ]; then
    echo "Error: Could not find aws_secret_access_key in credentials file."
    exit 1
fi

# Set the AWS access key ID and secret access key as environment variables
export AWS_ACCESS_KEY_ID=$access_key
export AWS_SECRET_ACCESS_KEY=$secret_key

# Set AWS_PAGER to empty to disable the pager (fixes your error)
export AWS_PAGER=""

# Provide feedback
echo "AWS credentials set as environment variables."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    exit 1
fi

# Ask user if they want to reconfigure AWS CLI
read -p "Do you want to reconfigure AWS CLI? (y/n): " reconfigure
if [ "$reconfigure" = "y" ]; then
    aws configure
fi

# Confirm that you are logged in to the AWS CLI
echo "Verifying AWS identity..."
aws sts get-caller-identity

echo "AWS authentication completed successfully."
