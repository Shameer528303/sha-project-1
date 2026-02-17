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
  backend "s3" {
     bucket = "terraform-state-bucket-shalih"
     key    = "principal-sre-assessment/terraform.tfstate"
     region = "ap-south-1"
   }
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

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# Public subnets (ALB + NAT)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

# Private subnets (EKS nodes / app / Redis)
resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  }
}

# NAT Gateway (one NAT for cost saving; prod best is 2 NAT - one per AZ)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.name_prefix}-nat"
  }
}

# Route tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# TODO: Create ECR repository for container images
resource "aws_ecr_repository" "app" {
   name                 = "${var.project_name}-app"
   image_tag_mutability = "MUTABLE"
 
   image_scanning_configuration {
     scan_on_push = true
   }
}

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

