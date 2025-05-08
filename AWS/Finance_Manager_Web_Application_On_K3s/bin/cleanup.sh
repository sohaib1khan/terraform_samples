#!/bin/bash

# cleanup.sh - Script to destroy all resources created for the Finance Manager application

# Set script to exit immediately if a command exits with a non-zero status
set -e

# Display banner
echo "======================================================="
echo "    Finance Manager Web Application Cleanup Tool       "
echo "======================================================="

# Source AWS login script if exists
if [ -f "./aws-login.sh" ]; then
    echo "Sourcing AWS login script..."
    source ./aws-login.sh
else
    echo "Warning: aws-login.sh not found. Make sure you're authenticated with AWS."
fi

# Set variables
TERRAFORM_DIR="./terraform"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Error: terraform is not installed. Please install it before proceeding."
    exit 1
fi

# Ask for confirmation
read -p "This will destroy all AWS resources created for the Finance Manager application. Are you sure? (y/n): " confirm
if [[ $confirm != [Yy]* ]]; then
    echo "Cleanup aborted by user."
    exit 0
fi

# Change to Terraform directory
cd "$TERRAFORM_DIR"

# Destroy all resources
echo "Destroying all AWS resources..."
terraform destroy -auto-approve

# Go back to project root
cd ..

echo "======================================================="
echo "Cleanup completed successfully!"
echo "All AWS resources have been destroyed."
echo "======================================================="