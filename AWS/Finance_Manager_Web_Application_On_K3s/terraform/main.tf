# main.tf - Main Terraform configuration file for Finance Manager on K3s

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  # Using default AWS profile (authenticated via aws-login.sh)
  # No explicit credentials needed here since we're using the aws-login.sh script
}

# Retrieve latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create a VPC
resource "aws_vpc" "finance_app_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "finance-app-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "finance_app_igw" {
  vpc_id = aws_vpc.finance_app_vpc.id

  tags = {
    Name = "finance-app-igw"
  }
}

# Create a Public Subnet
resource "aws_subnet" "finance_app_subnet" {
  vpc_id                  = aws_vpc.finance_app_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"  # Use first AZ in the region

  tags = {
    Name = "finance-app-subnet"
  }
}

# Create Route Table
resource "aws_route_table" "finance_app_rt" {
  vpc_id = aws_vpc.finance_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.finance_app_igw.id
  }

  tags = {
    Name = "finance-app-rt"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "finance_app_rta" {
  subnet_id      = aws_subnet.finance_app_subnet.id
  route_table_id = aws_route_table.finance_app_rt.id
}

# Create Security Group for K3s server
resource "aws_security_group" "finance_app_sg" {
  name        = "finance-app-sg"
  description = "Security group for Finance Manager K3s deployment"
  vpc_id      = aws_vpc.finance_app_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting to your IP for production
    description = "SSH"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # NodePort access for the Finance Manager app
  ingress {
    from_port   = 30001
    to_port     = 30001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort for Finance Manager App"
  }

  # K3s API Server
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting to your IP for production
    description = "K3s API Server"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "finance-app-sg"
  }
}

# Create EC2 Instance for K3s
resource "aws_instance" "finance_app_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.finance_app_subnet.id
  vpc_security_group_ids = [aws_security_group.finance_app_sg.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # User data for initial setup
  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname k3s-finance-app
    yum update -y
    yum install -y python3
  EOF

  tags = {
    Name = "k3s-finance-app"
  }
}

# Create Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tmpl",
    {
      public_ip  = aws_instance.finance_app_instance.public_ip
      private_ip = aws_instance.finance_app_instance.private_ip
      key_path   = var.key_path
      key_name   = var.key_name
    }
  )
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  depends_on = [aws_instance.finance_app_instance]
}

# Output EC2 instance public IP
output "ec2_public_ip" {
  value       = aws_instance.finance_app_instance.public_ip
  description = "The public IP address of the EC2 instance"
}

# Output EC2 instance private IP
output "ec2_private_ip" {
  value       = aws_instance.finance_app_instance.private_ip
  description = "The private IP address of the EC2 instance"
}

# Output Finance Manager application URL
output "finance_app_url" {
  value       = "http://${aws_instance.finance_app_instance.public_ip}:30001"
  description = "URL to access the Finance Manager application"
}