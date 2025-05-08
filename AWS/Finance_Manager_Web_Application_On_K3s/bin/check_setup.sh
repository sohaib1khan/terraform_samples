#!/bin/bash

# check_setup.sh - Script to verify and fix project structure

# Set script to exit immediately if a command exits with a non-zero status
set -e

# Display banner
echo "======================================================="
echo "    Finance Manager Project Structure Verification     "
echo "======================================================="

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Get the project root directory (parent of bin)
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Change to project root
cd "$PROJECT_ROOT"

echo "Checking and fixing project structure..."

# Create required directories
echo "Creating required directories..."
mkdir -p "$PROJECT_ROOT/ansible/files"
mkdir -p "$PROJECT_ROOT/ansible/inventory"
mkdir -p "$PROJECT_ROOT/ansible/playbooks"
mkdir -p "$PROJECT_ROOT/terraform/templates"
mkdir -p "$PROJECT_ROOT/bin"

# Check and move deployment manifest
if [ -f "$PROJECT_ROOT/ansible/playbooks/finance-app-deployment.yml" ] && [ ! -f "$PROJECT_ROOT/ansible/files/finance-app-deployment.yml" ]; then
    echo "Moving deployment manifest to the correct location..."
    cp "$PROJECT_ROOT/ansible/playbooks/finance-app-deployment.yml" "$PROJECT_ROOT/ansible/files/finance-app-deployment.yml"
    echo "Deployment manifest moved successfully."
elif [ ! -f "$PROJECT_ROOT/ansible/files/finance-app-deployment.yml" ] && [ ! -f "$PROJECT_ROOT/ansible/playbooks/finance-app-deployment.yml" ]; then
    echo "ERROR: Deployment manifest not found!"
    echo "Please make sure finance-app-deployment.yml exists in either ansible/files or ansible/playbooks directory."
fi

# Check and move service manifest (handling both possible filenames)
if [ -f "$PROJECT_ROOT/ansible/playbooks/finance-app-services.yml" ] && [ ! -f "$PROJECT_ROOT/ansible/files/finance-app-service.yml" ]; then
    echo "Moving service manifest to the correct location and renaming..."
    cp "$PROJECT_ROOT/ansible/playbooks/finance-app-services.yml" "$PROJECT_ROOT/ansible/files/finance-app-service.yml"
    echo "Service manifest moved and renamed successfully."
elif [ -f "$PROJECT_ROOT/ansible/playbooks/finance-app-service.yml" ] && [ ! -f "$PROJECT_ROOT/ansible/files/finance-app-service.yml" ]; then
    echo "Moving service manifest to the correct location..."
    cp "$PROJECT_ROOT/ansible/playbooks/finance-app-service.yml" "$PROJECT_ROOT/ansible/files/finance-app-service.yml"
    echo "Service manifest moved successfully."
elif [ ! -f "$PROJECT_ROOT/ansible/files/finance-app-service.yml" ] && [ ! -f "$PROJECT_ROOT/ansible/playbooks/finance-app-service.yml" ] && [ ! -f "$PROJECT_ROOT/ansible/playbooks/finance-app-services.yml" ]; then
    echo "ERROR: Service manifest not found!"
    echo "Please make sure finance-app-service.yml or finance-app-services.yml exists in either ansible/files or ansible/playbooks directory."
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$PROJECT_ROOT/bin/deploy.sh"
chmod +x "$PROJECT_ROOT/bin/cleanup.sh"
chmod +x "$PROJECT_ROOT/bin/check_setup.sh"
if [ -f "$PROJECT_ROOT/aws-login.sh" ]; then
    chmod +x "$PROJECT_ROOT/aws-login.sh"
fi

# Print project structure
echo "Current project structure:"
find "$PROJECT_ROOT" -type f | sort

echo "======================================================="
echo "Verification and fixes completed!"
echo "You may now run ./bin/deploy.sh to deploy the application."
echo "======================================================="