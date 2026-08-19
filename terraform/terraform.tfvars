aws_region         = "ap-southeast-2"
cluster_name       = "argocd-eks"
kubernetes_version = "1.33"

node_instance_type = "t3.small"
node_capacity_type = "ON_DEMAND"

desired_capacity = 2
min_capacity     = 1
max_capacity     = 3

cluster_endpoint_public_access_cidrs = ["122.181.102.92/32"]
