# variables.tf - Input variables for the ElastiCache cluster configuration

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1" # Change this to your preferred region
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Lab"
    Project     = "ElastiCacheCluster"
    ManagedBy   = "Terraform"
  }
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
  default     = "" # You'll need to provide this or create a new VPC
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ElastiCache subnet group"
  type        = list(string)
  default     = [] # You'll need to provide these or create new subnets
}

variable "elasticache_cluster_name" {
  description = "Name for the ElastiCache cluster"
  type        = string
  default     = "memcached-lab-cluster"
}

variable "elasticache_node_type" {
  description = "Node type for ElastiCache cluster"
  type        = string
  default     = "cache.t3.micro" # Smallest instance type suitable for a lab
}

variable "elasticache_num_nodes" {
  description = "Number of nodes in the ElastiCache cluster"
  type        = number
  default     = 2 # Minimum recommended for a distributed setup
}

variable "elasticache_engine" {
  description = "Cache engine type - Memcached or Redis"
  type        = string
  default     = "memcached"
}

variable "elasticache_port" {
  description = "Port number for the ElastiCache cluster"
  type        = number
  default     = 11211 # Default Memcached port
}