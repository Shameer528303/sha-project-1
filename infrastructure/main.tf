# Main Terraform configuration
# TODO: Complete this infrastructure setup

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # TODO: Configure S3 backend for state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "principal-sre-assessment/terraform.tfstate"
  #   region = "us-east-1"
  #   # Optional: Enable DynamoDB for state locking
  #   # dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "principal-sre-assessment"
      Environment = var.environment
      ManagedBy   = "Terraform"
      # IMPORTANT: Candidate tag is required for cost tracking
      # The budget only tracks costs for resources tagged with your candidate name
      Candidate   = var.candidate_name
    }
  }
}

# TODO: Create VPC and networking
# - VPC with CIDR block
# - Public and private subnets (multi-AZ)
# - Internet Gateway
# - NAT Gateway
# - Route tables

# TODO: Create ECR repository for container images
# resource "aws_ecr_repository" "app" {
#   name                 = "${var.project_name}-app"
#   image_tag_mutability = "MUTABLE"
# 
#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

# TODO: Create EKS cluster OR ECS cluster
# Option A: EKS
# - EKS cluster
# - Node group(s) in private subnets
# - IAM roles for service accounts

# Option B: ECS Fargate
# - ECS cluster
# - Fargate task definition
# - ECS service

# TODO: Create Application Load Balancer
# - ALB in public subnets
# - Target group
# - Listener
# - Security groups

# TODO: Create IAM roles
# - EKS node group role / ECS task role
# - Application service account role
# - CI/CD role

# TODO: Create CloudWatch resources
# - Log groups
# - Custom metrics (optional)
# - Dashboards
# - Alarms

# TODO: Create Secrets Manager
# - Secret for API keys (if using OpenAI)

# TODO: Create security groups
# - ALB security group
# - Application security group
# - Minimal required ports only

