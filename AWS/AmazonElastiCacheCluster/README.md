# Amazon ElastiCache Cluster Terraform Lab

This directory contains Terraform code to create an Amazon ElastiCache Memcached cluster along with necessary AWS resources for the lab exercise.

## Prerequisites

- AWS Account
- Terraform installed (v1.0.0+)
- AWS CLI configured

## Resources Created

1. VPC and Subnets (if not specified)
2. Security Groups for ElastiCache and EC2
3. ElastiCache Subnet Group
4. ElastiCache Memcached Cluster
5. EC2 Instance with PHP to test the ElastiCache connection

## How to Use

1. Login to your AWS account:
```bash
./aws-login.sh
```

2. Initialize Terraform:
```bash
terraform init
```

3. Review the deployment plan:
```bash
terraform plan
```

4. Apply the configuration:
```bash
terraform apply
```

5. Test the ElastiCache connection by visiting the URL provided in the outputs.

6. When finished, destroy all resources:
```bash
terraform destroy
```

## Post-Deployment Verification

After successful deployment, verify the following:

1. **ElastiCache Cluster**:
- Check that the ElastiCache cluster is in "available" status in the AWS Console
- Verify the cluster has the correct number of nodes (default: 2)
- Confirm the cache engine is Memcached
- Note the configuration endpoint for connection testing

2. **EC2 Client Instance**:
- Verify the EC2 instance is in "running" state
- Confirm you can access the instance via SSH (if needed)
- Access the test URL from the Terraform outputs to verify PHP installation

3. **Connectivity Test**:
- Visit the Memcached test URL from the outputs
- Verify you see "Successfully connected to ElastiCache cluster!"
- Check that test values can be stored and retrieved
- Review the server statistics displayed on the page

4. **Networking**:
- Confirm the security groups allow proper traffic flow
- Verify the subnet group contains the expected subnets
- Check that the EC2 instance can reach the ElastiCache endpoint

5. **Benchmark Testing (Optional)**:
- Use the EC2 client to run basic performance tests
- Test storing and retrieving different sizes of data
- Verify cache operations across multiple nodes

## Variables

You can customize the deployment by modifying the variables in `variables.tf`.

