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
  
  # S3 backend for state
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

# Create ECR repository for container images
resource "aws_ecr_repository" "app" {
   name                 = "${var.project_name}-app"
   image_tag_mutability = "MUTABLE"
 
   image_scanning_configuration {
     scan_on_push = true
   }
}

# Keep last N images only (cost control)
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 20 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

#EKS role creation
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "eks.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Optional but useful for troubleshooting: SSM access to nodes
resource "aws_iam_role_policy_attachment" "eks_node_AmazonSSMManagedInstanceCore" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Security Group for EKS 
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.name_prefix}-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.main.id

  # Allow outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-eks-cluster-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController
  ]

  tags = {
    Name = "${var.name_prefix}-eks"
  }
}

# Managed Node Group (PRIVATE subnets)
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.eks_node_desired
    min_size     = var.eks_node_min
    max_size     = var.eks_node_max
  }

  instance_types = [var.eks_node_instance_type]
  capacity_type  = "ON_DEMAND"

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "${var.name_prefix}-nodegroup"
  }
}

#S3 Bucket
resource "aws_s3_bucket" "document_storage" {
  bucket = "${var.name_prefix}-storage-shahil"

  tags = {
    Name        = "${var.name_prefix}-storage-shahil"
  }
}

# Enable versioning (safe for deletes/overwrites)
resource "aws_s3_bucket_versioning" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}


#ElastiCache Redis
# Security group allowing Redis only from EKS nodes (inside VPC)
resource "aws_security_group" "redis_sg" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Allow Redis from within VPC (EKS nodes)"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-redis-sg"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "Redis cache for document service"
  engine                     = "redis"
  engine_version             = "7.1"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis_sg.id]

  automatic_failover_enabled = true
  multi_az_enabled           = true

  num_cache_clusters         = 2

  tags = {
    Name = "${var.name_prefix}-redis"
  }
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

#Loadbalancer Part
# Find EKS worker node instances by cluster tag
data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:kubernetes.io/cluster/${aws_eks_cluster.this.name}"
    values = ["owned", "shared"]
  }
}

# Security Group for the CLB (public)
resource "aws_security_group" "document_clb_sg" {
  name   = "${var.name_prefix}-doc-clb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Allow CLB -> Nodes on NodePort (30080)
# NOTE: Using EKS cluster security group because EKS attaches it to nodes as well.
resource "aws_security_group_rule" "nodes_allow_from_clb_nodeport" {
  type                     = "ingress"
  security_group_id        = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.document_clb_sg.id
}

# Classic Load Balancer in PUBLIC subnets
resource "aws_elb" "document_clb" {
  name            = substr("${var.name_prefix}-doc-clb", 0, 32)
  subnets         = aws_subnet.public[*].id
  security_groups = [aws_security_group.document_clb_sg.id]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 30080
    instance_protocol = "http"
  } # <-- IMPORTANT: this closing brace was missing in your code

  health_check {
    target              = "HTTP:30080/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = data.aws_instances.eks_nodes.ids

  depends_on = [aws_eks_node_group.default]
}

output "document_clb_dns" {
  value = aws_elb.document_clb.dns_name
}


# CloudWatch for EKS + CLB
# EKS Control Plane Log Group
resource "aws_cloudwatch_log_group" "eks_control_plane" {
  name              = "/aws/eks/${aws_eks_cluster.this.name}/cluster"
  retention_in_days = 7
}

# CLB CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "clb_unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-clb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    LoadBalancerName = aws_elb.document_clb.name
  }
}

resource "aws_cloudwatch_metric_alarm" "clb_healthy_hosts_low" {
  alarm_name          = "${var.name_prefix}-clb-healthy-hosts-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancerName = aws_elb.document_clb.name
  }
}

resource "aws_cloudwatch_metric_alarm" "clb_latency_high" {
  alarm_name          = "${var.name_prefix}-clb-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancerName = aws_elb.document_clb.name
  }
}


# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "document_service" {
  dashboard_name = "${var.name_prefix}-document-service"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "CLB Healthy vs Unhealthy Hosts"
          region = var.aws_region
          metrics = [
            ["AWS/ELB", "HealthyHostCount",   "LoadBalancerName", aws_elb.document_clb.name],
            ["AWS/ELB", "UnHealthyHostCount", "LoadBalancerName", aws_elb.document_clb.name]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "CLB Latency"
          region = var.aws_region
          metrics = [
            ["AWS/ELB", "Latency", "LoadBalancerName", aws_elb.document_clb.name]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}




















# TODO: Create CloudWatch resources
# - Log groups
# - Custom metrics (optional)
# - Dashboards
# - Alarms



