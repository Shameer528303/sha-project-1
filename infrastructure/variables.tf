# Variable definitions for Terraform configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "shahil-project"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "candidate_name" {
  description = "Candidate name for resource tagging (required for cost tracking). Extract from repository name: principal-sre-assessment-<candidate-name>"
  type        = string
  # Default will be extracted from repository name or set manually
  # Example: If repo is "principal-sre-assessment-john-doe", candidate_name = "john-doe"
}

# TODO: Add more variables as needed
# Examples:
# - VPC CIDR blocks
# - Instance types
# - Desired capacity
# - Domain names
# - etc.
# TODO: Add more variables as needed
# Examples:
# - VPC CIDR blocks

variable "name_prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "one"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs (2)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs (2)"
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

#eks cluster variables

variable "eks_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.29"
}

variable "eks_node_instance_type" {
  type        = string
  description = "Instance type for EKS managed node group"
  default     = "t3.small"
}

variable "eks_node_min" {
  type    = number
  default = 1
}

variable "eks_node_desired" {
  type    = number
  default = 2
}

variable "eks_node_max" {
  type    = number
  default = 3
}

#redis variables
variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type"
  default     = "cache.t3.micro"
}





