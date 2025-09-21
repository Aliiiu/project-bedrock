variable "cluster_name" {
  description = "Name of the EKS cluster"
  type = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS instances will be created"
  type        = string
}

variable "mysql_instance_class" {
  description = "Instance class for MySQL RDS"
  type        = string
}

variable "postgres_instance_class" {
  description = "Instance class for PostgreSQL RDS"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}