aws_region         = "us-east-1"
cluster_name       = "argocd-eks"
kubernetes_version = "1.33"

node_instance_type = "t3.medium"

desired_capacity = 2
min_capacity     = 2
max_capacity     = 3