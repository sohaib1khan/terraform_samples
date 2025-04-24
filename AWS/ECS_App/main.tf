# VPC and Networking Resources
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Create two public subnets in different AZs for high availability
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate route table with public subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group for the container
resource "aws_security_group" "nginx" {
  name        = "${var.project_name}-sg"
  description = "Allow inbound traffic to Nginx"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  
  setting {
    name  = "containerInsights"
    value = "disabled"  # Disable container insights to minimize costs
  }
}

# ECS Task Definition with Nginx container
resource "aws_ecs_task_definition" "nginx" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name         = "nginx"
      image        = "nginx:latest"
      essential    = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      
      # Simple HTML test page
      mountPoints = [
        {
          sourceVolume  = "nginx-html"
          containerPath = "/usr/share/nginx/html"
          readOnly      = false
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.nginx.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
  
  volume {
    name = "nginx-html"
    
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nginx_content.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.nginx_content.id
      }
    }
  }
}

# ECS Service
resource "aws_ecs_service" "nginx" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  platform_version = var.fargate_platform_version

  network_configuration {
    subnets         = aws_subnet.public[*].id
    security_groups = [aws_security_group.nginx.id]
    assign_public_ip = true
  }
}

# CloudWatch Log Group for container logs
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 1  # Minimum retention to keep costs low for lab
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# EFS File System for Nginx content
resource "aws_efs_file_system" "nginx_content" {
  creation_token = "${var.project_name}-efs"
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "${var.project_name}-efs"
  }
}

# EFS Mount Target
resource "aws_efs_mount_target" "nginx_content" {
  count           = 2
  file_system_id  = aws_efs_file_system.nginx_content.id
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS
resource "aws_security_group" "efs" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow EFS access from ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049  # NFS port
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.nginx.id]
    description     = "Allow NFS traffic from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

# EFS Access Point for Nginx content
resource "aws_efs_access_point" "nginx_content" {
  file_system_id = aws_efs_file_system.nginx_content.id
  
  posix_user {
    gid = 101  # nginx user GID
    uid = 101  # nginx user UID
  }
  
  root_directory {
    path = "/nginx"
    creation_info {
      owner_gid   = 101
      owner_uid   = 101
      permissions = "755"
    }
  }
}

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Outputs
output "nginx_service_url" {
  description = "URL to access the Nginx service"
  value       = "http://${aws_ecs_service.nginx.network_configuration[0].assign_public_ip ? "Public IP (check AWS Console)" : "Not publicly accessible"}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.nginx.family
}