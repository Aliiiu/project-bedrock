variable "cluster_name" {
  description = "Name of the EKS cluster"
  type = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the EKS cluster endpoint"
  type        = list(string)
}

variable "environment" {
    description = "Environment name"
    type        = string
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 5
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "cluster_role_arn" {
  description = "EKS cluster service role ARN"
  type        = string
}

variable "node_group_role_arn" {
  description = "EKS node group role ARN"
  type        = string
}

