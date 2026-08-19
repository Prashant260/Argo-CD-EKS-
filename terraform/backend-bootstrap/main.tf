terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.55.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "argocd-eks-terraform-state-755729228993"
  force_destroy = false

  tags = {
    Project     = "Argo-CD-EKS"
    Environment = "dev"
    Terraform   = "true"
    Purpose     = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
  }
}

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state S3 bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name        = "argocd-eks-terraform-state-kms"
    Project     = "Argo-CD-EKS"
    Environment = "dev"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/argocd-eks-terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}
