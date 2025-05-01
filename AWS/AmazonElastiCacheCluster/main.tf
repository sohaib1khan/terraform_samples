# main.tf - Main configuration for setting up an Amazon ElastiCache Cluster
# This file defines all resources required for the ElastiCache lab

# Local variable to determine which VPC ID to use
locals {
  used_vpc_id = var.vpc_id != "" ? var.vpc_id : (length(aws_vpc.main) > 0 ? aws_vpc.main[0].id : "")
}

# Create a security group for ElastiCache
resource "aws_security_group" "elasticache_sg" {
  name        = "elasticache-security-group"
  description = "Security group for ElastiCache cluster"
  vpc_id      = local.used_vpc_id

  # Inbound rule for ElastiCache port
  ingress {
    from_port   = var.elasticache_port
    to_port     = var.elasticache_port
    protocol    = "tcp"
    description = "Allow incoming ElastiCache connections"
    cidr_blocks = ["0.0.0.0/0"]  # For lab purposes only; restrict this in production
  }

  # Outbound rule allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elasticache-sg"
  }
}

# Create an ElastiCache subnet group
resource "aws_elasticache_subnet_group" "cache_subnet_group" {
  name        = "elasticache-subnet-group"
  description = "ElastiCache subnet group for lab"
  
  # Use created subnets if subnet_ids is empty, otherwise use provided subnet_ids
  subnet_ids  = length(var.subnet_ids) > 0 ? var.subnet_ids : [for subnet in aws_subnet.main : subnet.id]
}

# Create the ElastiCache cluster
resource "aws_elasticache_cluster" "memcached_cluster" {
  # Basic cluster configuration
  cluster_id           = var.elasticache_cluster_name
  engine               = var.elasticache_engine
  node_type            = var.elasticache_node_type
  num_cache_nodes      = var.elasticache_num_nodes
  parameter_group_name = "default.memcached1.6"  # Using default parameter group for Memcached 1.6
  port                 = var.elasticache_port
  
  # Network configuration
  subnet_group_name    = aws_elasticache_subnet_group.cache_subnet_group.name
  security_group_ids   = [aws_security_group.elasticache_sg.id]
  
  # Maintenance and backup
  maintenance_window   = "sun:05:00-sun:06:00"  # Weekly maintenance window
  
  # Tags for resource management
  tags = {
    Name = var.elasticache_cluster_name
  }
}

# Create an EC2 instance to connect to the ElastiCache cluster
resource "aws_instance" "ec2_client" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI - update this to the latest AMI ID
  instance_type = "t2.micro"

  # Use the created subnet if subnet_ids is empty, otherwise use the provided subnet
  subnet_id = length(var.subnet_ids) > 0 ? var.subnet_ids[0] : aws_subnet.main[0].id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Rest of the code remains the same
  user_data = <<-EOF
    #!/bin/bash
    # Install PHP and required extensions for Memcached
    yum update -y
    yum install -y httpd php php-devel php-pear gcc zlib-devel
    amazon-linux-extras install -y php7.4
    
    # Install the Memcached PHP extension
    pecl install memcached
    
    # Add the extension to PHP configuration
    echo "extension=memcached.so" > /etc/php.d/memcached.ini
    
    # Start Apache web server
    systemctl start httpd
    systemctl enable httpd
    
    # Create a simple PHP test file
    cat > /var/www/html/memcached_test.php << 'PHPFILE'
    <?php
    $memcached = new Memcached();
    
    // Add ElastiCache server
    $memcached->addServer('${aws_elasticache_cluster.memcached_cluster.configuration_endpoint}', ${var.elasticache_port});
    
    // Check connection status
    $status = $memcached->getStats();
    echo "<h1>ElastiCache Connection Test</h1>";
    
    if (empty($status)) {
        echo "<p>Connection to ElastiCache failed.</p>";
    } else {
        echo "<p>Successfully connected to ElastiCache cluster!</p>";
        
        // Store and retrieve a test value
        $memcached->set('test_key', 'Hello from ElastiCache!');
        $value = $memcached->get('test_key');
        echo "<p>Retrieved value: " . $value . "</p>";
    }
    
    // Print server information
    echo "<h2>Server Stats:</h2>";
    echo "<pre>";
    print_r($status);
    echo "</pre>";
    ?>
    PHPFILE
  EOF

  tags = {
    Name = "elasticache-client"
  }

  # Wait for the ElastiCache cluster to be available
  depends_on = [aws_elasticache_cluster.memcached_cluster]
}

# Security group for EC2 client instance
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-elasticache-client-sg"
  description = "Security group for EC2 ElastiCache client"
  vpc_id      = local.used_vpc_id

  # Allow HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access"
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For lab purposes only; restrict this in production
    description = "Allow SSH access"
  }

  # Allow outbound access to ElastiCache
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-elasticache-client-sg"
  }
}

# Create a VPC if var.vpc_id is empty
resource "aws_vpc" "main" {
  count = var.vpc_id == "" ? 1 : 0

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "elasticache-lab-vpc"
  }
}

# Create subnets if var.subnet_ids is empty
resource "aws_subnet" "main" {
  count = length(var.subnet_ids) == 0 ? 2 : 0

  vpc_id                  = local.used_vpc_id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true

  tags = {
    Name = "elasticache-lab-subnet-${count.index}"
  }
}

# Create an Internet Gateway for the VPC if needed
resource "aws_internet_gateway" "main" {
  count = var.vpc_id == "" ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name = "elasticache-lab-igw"
  }
}

# Create a route table for the VPC if needed
resource "aws_route_table" "main" {
  count = var.vpc_id == "" ? 1 : 0

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "elasticache-lab-rt"
  }
}

# Associate the route table with the subnets if needed
resource "aws_route_table_association" "main" {
  count = length(var.subnet_ids) == 0 ? 2 : 0

  subnet_id      = aws_subnet.main[count.index].id
  route_table_id = aws_route_table.main[0].id
}

# Output section - These values will be displayed after successful deployment
output "elasticache_endpoint" {
  description = "The endpoint of the ElastiCache cluster"
  value       = aws_elasticache_cluster.memcached_cluster.configuration_endpoint
}

output "elasticache_port" {
  description = "The port of the ElastiCache cluster"
  value       = aws_elasticache_cluster.memcached_cluster.port
}

output "ec2_client_public_ip" {
  description = "Public IP address of the EC2 client instance"
  value       = aws_instance.ec2_client.public_ip
}

output "memcached_test_url" {
  description = "URL to test the Memcached connection"
  value       = "http://${aws_instance.ec2_client.public_ip}/memcached_test.php"
}