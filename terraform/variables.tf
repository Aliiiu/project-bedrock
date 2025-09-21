
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Bonus variables
variable "enable_managed_databases" {
  description = "Enable managed AWS databases (RDS, DynamoDB)"
  type        = bool
  default     = true
}

variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_ssl_certificate" {
  description = "Enable SSL certificate with ACM"
  type        = bool
  default     = true
}

variable "enable_route53" {
  description = "Enable Route 53 hosted zone"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "mysql_instance_class" {
  description = "RDS MySQL instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "postgres_instance_class" {
  description = "RDS PostgreSQL instance class"
  type        = string
  default     = "db.t3.micro"
}