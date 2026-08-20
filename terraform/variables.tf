variable "aws_region" {
  description = "AWS region where the infrastructure will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "argocd-eks"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.33"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_capacity_type" {
  description = "Capacity type for EKS worker nodes. Use SPOT for non-production cost optimization."
  type        = string
  default     = "SPOT"
}

variable "desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR ranges allowed to reach the public EKS API endpoint."
  type        = list(string)

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0 && alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Provide at least one valid CIDR for EKS API endpoint access."
  }
}

variable "ecr_repository_name" {
  description = "ECR repository name for the Python application image."
  type        = string
  default     = "alffino-python-hello"
}

variable "application_domain" {
  description = "Public DNS name for the application ALB and ACM certificate."
  type        = string
  default     = "alffino.online"
}

variable "create_route53_zone" {
  description = "Create the Route 53 hosted zone. Set false when DNS is managed elsewhere and provide route53_zone_id."
  type        = bool
  default     = true
}

variable "route53_zone_id" {
  description = "Existing Route 53 hosted zone ID when create_route53_zone is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_route53_zone || var.route53_zone_id != null
    error_message = "route53_zone_id is required when create_route53_zone is false."
  }
}
