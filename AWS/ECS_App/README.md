# Nginx on AWS ECS with Terraform

This project deploys a simple Nginx web server on AWS ECS (Elastic Container Service) using Terraform. The setup is minimal and optimized for lab/testing purposes.

## Architecture

This Terraform configuration:

- Creates a VPC with two public subnets across different availability zones
- Sets up a security group allowing HTTP traffic (port 80)
- Deploys an ECS cluster using Fargate (serverless)
- Creates an ECS task definition with Nginx container
- Sets up an ECS service to run the container
- Uses EFS for persistent storage of Nginx content
- Configures the necessary IAM roles and policies

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform 1.2.0 or newer
- Basic understanding of AWS and Terraform concepts

## Usage

1. Initialize the Terraform configuration:
   ```
   terraform init
   ```

2. Review the execution plan:
   ```
   terraform plan
   ```

3. Apply the configuration:
   ```
   terraform apply
   ```

4. After deployment completes, you'll see outputs including the URL to access your Nginx service.

5. To clean up all resources when done:
   ```
   terraform destroy
   ```

## Customization

You can customize the deployment by modifying the variables in `variables.tf`. The default configuration uses minimal resources to keep costs low for lab purposes.

## Adding Custom Content

To customize the Nginx welcome page:

1. After the infrastructure is deployed, connect to the EFS file system
2. Upload your HTML files to the `/nginx` directory
3. Restart the ECS service to pick up the changes

## Resources Created

- VPC with public subnets
- Security groups
- ECS cluster
- ECS task definition
- ECS service
- EFS file system
- CloudWatch log group
- IAM roles and policies

## Notes

- This setup uses AWS Fargate, which is serverless and doesn't require managing EC2 instances
- The configuration prioritizes minimal resource usage for lab environments
- For production use, additional considerations like HTTPS, load balancing, and hardened security would be needed