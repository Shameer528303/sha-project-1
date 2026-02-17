# Output values for Terraform configuration

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

output "azs" {
  value = local.azs
}

#ECR repository output
output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

#EKS cluster output
output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "eks_cluster_ca" {
  value     = aws_eks_cluster.this.certificate_authority[0].data
  sensitive = true
}

output "eks_nodegroup_name" {
  value = aws_eks_node_group.default.node_group_name
}





























# TODO: Define outputs for important resources
# Examples:

# output "alb_dns_name" {
#   description = "DNS name of the Application Load Balancer"
#   value       = aws_lb.main.dns_name
# }

# output "ecr_repository_url" {
#   description = "URL of the ECR repository"
#   value       = aws_ecr_repository.app.repository_url
# }

# output "eks_cluster_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = aws_eks_cluster.main.endpoint
# }

# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = aws_ecs_cluster.main.name
# }

# output "cloudwatch_log_group" {
#   description = "CloudWatch log group name"
#   value       = aws_cloudwatch_log_group.app.name
# }

