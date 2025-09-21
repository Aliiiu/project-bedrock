# Project Bedrock - Assignment Configuration

aws_region   = "eu-west-1"
environment  = "dev"

# Network Configuration
vpc_cidr        = "10.0.0.0/16"
public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

# EKS Configuration - Cost Optimized
kubernetes_version = "1.28"
node_instance_types = ["t3.small"]  # Cheapest option
node_desired_size = 2
node_max_size = 3
node_min_size = 1

# Security
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# Core Features
enable_managed_databases = true
enable_alb_controller = true

# Bonus Features (conditional)
enable_ssl_certificate = false  # Set to true if you have a domain
enable_route53 = false          # Set to true if you have a domain
domain_name = ""                # Add your domain if available

# Database Configuration - Cheapest instances
mysql_instance_class = "db.t3.micro"
postgres_instance_class = "db.t3.micro"