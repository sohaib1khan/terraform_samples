# Terraform Samples

This repository contains sample Terraform code for various cloud providers and use cases.

## Getting Started

To use the Terraform code in this repository, you'll need to have Terraform installed on your local machine. You can download Terraform from the [official website](https://www.terraform.io/downloads.html).

Once you have Terraform installed, you can clone this repository and run the `terraform init` command in each subdirectory to initialize the Terraform modules and providers.

For example, to initialize the Terraform code for AWS EC2 instances, navigate to the `aws_ec2_instance` directory and run the following command:

```
cd aws_ec2_instance
terraform init
```

After initializing the Terraform code, you can use the `terraform plan` and `terraform apply` commands to create and update the infrastructure resources.

## Sample Code

This repository includes Terraform code for the following cloud providers and use cases:

- AWS EC2 instances (`aws_ec2_instance`)
- Azure Virtual Machines (`azure_virtual_machine`)
- Google Cloud Compute Engine instances (`gcp_compute_instance`)
- Kubernetes cluster on AWS using EKS (`kubernetes_aws_eks`)

Each subdirectory contains a `README.md` file with more information about the specific Terraform code and resources it creates.