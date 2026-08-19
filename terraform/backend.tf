terraform {
  backend "s3" {
    bucket       = "argocd-eks-terraform-state-755729228993"
    key          = "terraform/argocd-eks.tfstate"
    region       = "ap-southeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
