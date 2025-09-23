# Project Bedrock - EKS Retail Store Deployment

> **Assignment Solution**: Complete retail-store-sample-app deployment on AWS EKS with cost optimization

## Prerequisites

- AWS CLI configured
- GitHub repository with environment variables set

## GitHub Environment Setup

### Required Variables:
```
AWS_REGION = eu-west-1
ENVIRONMENT = dev
TF_STATE_BUCKET = your-unique-bucket-name
TF_STATE_KEY = bedrock/terraform.tfstate
CLUSTER_NAME = dev-bedrock-eks
```

### Required Secrets:
```
AWS_ACCESS_KEY_ID = your-aws-access-key
AWS_SECRET_ACCESS_KEY = your-aws-secret-key
```

### Optional:
```
DOMAIN_NAME = your-domain.com
ENABLE_INGRESS = true
```

## Architecture

```mermaid
graph TB
    %% External Access
    Internet([Internet]) --> ALB[Application Load Balancer]
    Developer[Developer] --> EKS
    GitHub[GitHub Actions] --> Terraform[Terraform]

    %% AWS VPC Structure
    subgraph VPC["AWS VPC (10.0.0.0/16)"]
        subgraph PubSubnet1["Public Subnet AZ-1 (10.0.101.0/24)"]
            NAT1[NAT Gateway]
            ALB
        end

        subgraph PubSubnet2["Public Subnet AZ-2 (10.0.102.0/24)"]
            NAT2[NAT Gateway]
        end

        subgraph PrivSubnet1["Private Subnet AZ-1 (10.0.1.0/24)"]
            EKSNodes1[EKS Worker Nodes]
        end

        subgraph PrivSubnet2["Private Subnet AZ-2 (10.0.2.0/24)"]
            EKSNodes2[EKS Worker Nodes]
        end

        subgraph DBSubnet1["DB Subnet AZ-1 (10.0.201.0/24)"]
            RDS1[(RDS MySQL)]
        end

        subgraph DBSubnet2["DB Subnet AZ-2 (10.0.202.0/24)"]
            RDS2[(RDS PostgreSQL)]
        end
    end

    %% EKS Cluster
    subgraph EKS["EKS Cluster (dev-bedrock-eks)"]
        subgraph ControlPlane["EKS Control Plane"]
            APIServer[Kubernetes API Server]
            ETCD[etcd]
        end

        subgraph WorkerNodes["Worker Nodes (t3.small)"]
            subgraph Pods["Application Pods"]
                UI[UI Service]
                Catalog[Catalog Service]
                Cart[Cart Service]
                Orders[Orders Service]
                Checkout[Checkout Service]
                Assets[Assets Service]
            end

            subgraph SystemPods["System Pods"]
                ALBController[AWS Load Balancer Controller]
                CoreDNS[CoreDNS]
                KubeProxy[kube-proxy]
            end
        end
    end

    %% AWS Services
    subgraph AWSServices["AWS Services"]
        DynamoDB[(DynamoDB)]
        ACM[ACM Certificate]
        Route53[Route 53]
        S3[S3 Backend]
        CloudWatch[CloudWatch Logs]
    end

    %% IAM
    subgraph IAM["IAM Roles & Users"]
        ClusterRole[EKS Cluster Role]
        NodeRole[EKS Node Group Role]
        DevUser[Developer User]
        ALBRole[ALB Controller Role]
    end

    %% CI/CD
    subgraph CICD["CI/CD Pipeline"]
        Terraform --> VPC
        Terraform --> EKS
        Terraform --> RDS1
        Terraform --> RDS2
        Terraform --> DynamoDB
        Terraform --> IAM
    end

    %% Connections
    ALB --> UI
    UI --> Catalog
    UI --> Cart
    UI --> Orders
    UI --> Checkout
    UI --> Assets

    Catalog --> RDS1
    Orders --> RDS2
    Cart --> DynamoDB

    NAT1 --> EKSNodes1
    NAT2 --> EKSNodes2

    EKS --> CloudWatch
    ALBController --> ALB

    DevUser -.-> EKS
    ClusterRole -.-> ControlPlane
    NodeRole -.-> WorkerNodes
    ALBRole -.-> ALBController

    Route53 --> ALB
    ACM -.-> ALB

    %% Styling
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff
    classDef k8s fill:#326CE5,stroke:#fff,stroke-width:2px,color:#fff
    classDef db fill:#4CAF50,stroke:#fff,stroke-width:2px,color:#fff
    classDef app fill:#2196F3,stroke:#fff,stroke-width:2px,color:#fff
    classDef cicd fill:#9C27B0,stroke:#fff,stroke-width:2px,color:#fff

    class VPC,ALB,NAT1,NAT2,ACM,Route53,S3,CloudWatch,DynamoDB aws
    class EKS,ControlPlane,WorkerNodes,UI,Catalog,Cart,Orders,Checkout,Assets,ALBController,CoreDNS,KubeProxy k8s
    class RDS1,RDS2 db
    class GitHub,Terraform,Developer cicd
```

### Infrastructure Components

- **VPC**: Multi-AZ setup with public/private subnets across 2 availability zones
- **EKS**: Kubernetes 1.28 cluster with t3.small worker nodes (cost-optimized)
- **RDS**: MySQL (catalog) + PostgreSQL (orders) with db.t3.micro instances
- **DynamoDB**: NoSQL database for cart service
- **ALB**: Application Load Balancer with SSL/TLS termination
- **IAM**: Granular roles for cluster, nodes, and read-only developer access
- **Route 53**: DNS management (optional)
- **ACM**: SSL certificate management (optional)

## Manual Deployment

```bash
# 1. Clone and setup
git clone <repo-url>
cd project-bedrock

# 2. Configure AWS
aws configure

# 3. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 4. Deploy application
aws eks update-kubeconfig --region eu-west-1 --name dev-bedrock-eks
kubectl apply -f https://github.com/aws-containers/retail-store-sample-app/releases/latest/download/kubernetes.yaml

# 5. Check status
kubectl get pods
kubectl get svc ui
```

## Access Information

### Application Access:
```bash
# Get application URL
kubectl get svc ui

# Port forward for local access
kubectl port-forward svc/ui 8080:80
# Then visit: http://localhost:8080
```

### Developer Access:
```bash
# Configure read-only access
aws configure set aws_access_key_id $(terraform output -raw developer_access_key_id)
aws configure set aws_secret_access_key $(terraform output -raw developer_secret_access_key)
aws eks update-kubeconfig --region eu-west-1 --name dev-bedrock-eks

# Available commands for developers
kubectl get pods
kubectl get svc
kubectl logs -f deployment/ui
kubectl describe pod <pod-name>
```

## Assignment Requirements Met

### Core Requirements
- [x] Infrastructure as Code (Terraform)
- [x] VPC with public/private subnets
- [x] EKS cluster with IAM roles
- [x] Retail store application deployed
- [x] Read-only developer IAM user
- [x] CI/CD pipeline with GitHub Actions

### Bonus Features 
- [x] Managed databases (RDS MySQL/PostgreSQL, DynamoDB)
- [x] AWS Load Balancer Controller
- [x] SSL/TLS with ACM (when domain provided)
- [x] Route 53 integration (when domain provided)
- [x] Kubernetes Ingress for advanced routing

## 🚀 Current Workflow

### Automated Deployment
1. **Setup**: Configure GitHub environment variables and secrets (see above)
2. **Trigger**: Push to `main` branch
3. **Pipeline**: GitHub Actions automatically:
   - Plans and applies Terraform infrastructure
   - Deploys EKS cluster with all modules (VPC, IAM, RDS)
   - Installs AWS Load Balancer Controller (if enabled)
   - Deploys retail store application from upstream
   - Sets up Ingress (if enabled)
4. **Access**: Get application URL from `kubectl get svc ui` or Load Balancer

### Pipeline Stages
- **terraform-plan.yml**: Validates Terraform on PRs
- **terraform-apply.yml**: Deploys infrastructure and application on main branch

## Troubleshooting

```bash
# Check infrastructure status
terraform show

# Check application status
kubectl get all
kubectl get events --sort-by='.lastTimestamp'

# Check specific service
kubectl logs -f deployment/catalog
kubectl describe pod -l app=ui
```

## Project Structure

```
project-bedrock/
terraform/           # Infrastructure as Code
modules/        # Reusable Terraform modules
terraform.tfvars # Configuration variables
.github/workflows/  # CI/CD pipelines
k8s-manifests/     # Kubernetes configurations
scripts/           # Deployment scripts
```

---

**Current Implementation Status**:
- ✅ Terraform modules: VPC, EKS, IAM, RDS
- ✅ GitHub Actions: terraform-plan.yml, terraform-apply.yml
- ✅ Kubernetes: Ingress configurations
- ✅ Scripts: Environment setup and kubectl configuration

**Estimated deployment time**: 15 minutes