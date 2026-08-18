module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.24.1"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  enable_irsa = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  control_plane_subnet_ids = module.vpc.private_subnets

  addons = {
    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    vpc-cni = {
      most_recent = true
    }

    eks-pod-identity-agent = {
      most_recent = true
    }
  }
  eks_managed_node_groups = {
    default = {
      name = "${var.cluster_name}-nodes"

      instance_types = [var.node_instance_type]

      min_size     = var.min_capacity
      max_size     = var.max_capacity
      desired_size = var.desired_capacity

      subnet_ids = module.vpc.private_subnets

      capacity_type = "ON_DEMAND"

      labels = {
        role = "general"
      }

      tags = {
        Name        = "${var.cluster_name}-node"
        Project     = "Argo-CD-EKS"
        Environment = "dev"
      }
    }
  }

  tags = {
    Project     = "Argo-CD-EKS"
    Environment = "dev"
    Terraform   = "true"
  }
}