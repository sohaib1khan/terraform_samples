#!/bin/bash

# Get the AWS access key ID and secret access key from the credentials file
access_key=$(grep aws_access_key_id ~/.aws/credentials | cut -d' ' -f3)
secret_key=$(grep aws_secret_access_key ~/.aws/credentials | cut -d' ' -f3)

# Set the AWS access key ID and secret access key as environment variables
export AWS_ACCESS_KEY_ID=$access_key
export AWS_SECRET_ACCESS_KEY=$secret_key

# Log in to the AWS CLI
aws configure

# Confirm that you are logged in to the AWS CLI
aws sts get-caller-identity