variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name for the project, used in resource naming"
  type        = string
  default     = "nginx-demo"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU units for the container (1024 units = 1 vCPU)"
  type        = number
  default     = 256 # Minimal CPU allocation
}

variable "container_memory" {
  description = "Memory for the container in MiB"
  type        = number
  default     = 512 # Minimal memory allocation
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "fargate_platform_version" {
  description = "Fargate platform version"
  type        = string
  default     = "LATEST"
}