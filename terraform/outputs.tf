output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = helm_release.argocd.namespace
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "ecr_repository_url" {
  description = "ECR repository URL for GitHub Actions ECR_REPOSITORY"
  value       = aws_ecr_repository.app.repository_url
}

output "application_domain" {
  description = "Public application hostname."
  value       = var.application_domain
}

output "application_certificate_arn" {
  description = "Validated ACM certificate ARN for the application ALB."
  value       = aws_acm_certificate_validation.application.certificate_arn
}

output "route53_name_servers" {
  description = "Name servers to delegate when Terraform creates the hosted zone."
  value       = var.create_route53_zone ? aws_route53_zone.application[0].name_servers : []
}
