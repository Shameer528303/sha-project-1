# Variable definitions for Terraform configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "text-similarity-service"
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

