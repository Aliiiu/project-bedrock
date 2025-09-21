terraform {
  required_version = ">= 1.2"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.92"
    }
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = "~> 2.28"
    }
    helm = {
        source = "hashicorp/helm"
        version = "~> 3.0.1"
    }
    random = {
        source = "hashicorp/random"
        version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket = "aliu-project-bedrock"
    key = "bedrock/terraform.tfstate"
    region = "eu-west-1"
  }

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project = "bedrock"
      ManagedBy = "terraform"
    }
  }
  
}

data "aws_availability_zones" "available" {
  filter {
    name = "opt-in-status"
    values = [ "opt-in-not-required" ]
  }
}

locals {
  cluster_name = "${var.environment}-bedrock-eks"
  azs          = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source = "./modules/vpc"

  cluster_name        = local.cluster_name
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones  = local.azs
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

module "iam" {
  source = "./modules/iam"

  cluster_name      = local.cluster_name
  environment       = var.environment
}

module "eks" {
  source = "./modules/eks"

  cluster_name                           = local.cluster_name
  environment                            = var.environment
  kubernetes_version                     = var.kubernetes_version
  public_subnet_ids                      = module.vpc.public_subnet_ids
  private_subnet_ids                     = module.vpc.private_subnet_ids
  cluster_endpoint_public_access_cidrs   = var.cluster_endpoint_public_access_cidrs
  node_instance_types                    = var.node_instance_types
  node_desired_size                      = var.node_desired_size
  node_max_size                          = var.node_max_size
  node_min_size                          = var.node_min_size
  cluster_role_arn                       = module.iam.cluster_role_arn
  node_group_role_arn                    = module.iam.node_group_role_arn

  depends_on = [module.vpc, module.iam]
}

# RDS Module
module "rds" {
  count  = var.enable_managed_databases ? 1 : 0
  source = "./modules/rds"

  cluster_name              = local.cluster_name
  environment              = var.environment
  vpc_id                   = module.vpc.vpc_id
  vpc_cidr                 = var.vpc_cidr
  private_subnet_ids       = module.vpc.private_subnet_ids
  mysql_instance_class     = var.mysql_instance_class
  postgres_instance_class  = var.postgres_instance_class
  aws_region              = var.aws_region

  depends_on = [module.eks]
}

# Configure kubectl provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# AWS Load Balancer Controller (Bonus)
resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_alb_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.4"

  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.eks.aws_load_balancer_controller_role_arn
    }
  ]

  depends_on = [module.eks]
}

# Certificate Manager
resource "aws_acm_certificate" "main" {
  count = var.enable_ssl_certificate && var.domain_name != "" ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${local.cluster_name}-certificate"
    Environment = var.environment
  }
}

# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  count = var.enable_route53 && var.domain_name != "" ? 1 : 0

  name = var.domain_name

  tags = {
    Name        = "${local.cluster_name}-zone"
    Environment = var.environment
  }
}

# Certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = var.enable_ssl_certificate && var.enable_route53 && var.domain_name != "" ? {
    for dvo in aws_acm_certificate.main[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main[0].zone_id
}

resource "aws_acm_certificate_validation" "main" {
  count = var.enable_ssl_certificate && var.enable_route53 && var.domain_name != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Kubernetes RBAC for developer (after EKS cluster exists)
resource "kubernetes_cluster_role" "developer_readonly" {
  metadata {
    name = "developer-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "events", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [module.eks]
}

resource "kubernetes_cluster_role_binding" "developer_readonly" {
  metadata {
    name = "developer-readonly-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.developer_readonly.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "developer"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [module.eks, kubernetes_cluster_role.developer_readonly]
}

# AWS Auth ConfigMap update
resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = module.iam.developer_user_arn
        username = "developer"
        groups   = ["developer-readonly"]
      }
    ])
  }

  force = true
  depends_on = [module.eks, module.iam]
}