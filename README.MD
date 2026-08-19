# Deploy a Python Application to AWS EKS Using GitOps

This repository contains a production-ready sample deployment for a Python
Hello World service on Amazon EKS using GitHub Actions, Amazon ECR, Argo CD,
Kustomize, and the AWS Load Balancer Controller.

The public application domain is `app.alffino.online`. The Argo CD UI domain is
`argocd.alffino.online`.

## Architecture

```mermaid
flowchart LR
  dev[Developer] -->|git push| gh[GitHub Repository]
  gh -->|tests and scans| gha[GitHub Actions]
  gha -->|OIDC assume role| aws[AWS IAM]
  gha -->|build and scan image| ecr[Amazon ECR]
  gha -->|commit image tag| gitops[GitOps Path]
  gitops -->|poll or webhook| argocd[Argo CD]
  argocd -->|sync desired state| eks[Amazon EKS]
  eks --> svc[Kubernetes Service]
  svc --> alb[AWS ALB]
  alb -->|HTTPS| app[app.alffino.online]
  alb -->|HTTPS| ui[argocd.alffino.online]
```

## Repository Layout

- `app/`: Flask application with health and readiness endpoints.
- `tests/`: Pytest coverage for the sample service.
- `Dockerfile`: Hardened non-root Gunicorn container image.
- `.github/workflows/ci.yml`: CI/CD workflow with DevSecOps gates.
- `terraform/`: EKS, VPC, Argo CD Helm release, and ECR infrastructure.
- `k8s/`: Kubernetes base manifests.
- `gitops/`: Argo CD watched Kustomize path.
- `argocd/`: Argo CD Application and UI ingress manifests.
- `scripts/`: Image promotion, rollback, suspend, and startup helpers.

## Deployment Workflow

1. Developer pushes to `main`.
2. GitHub Actions installs dependencies and runs unit tests.
3. Security gates run secret scanning, dependency scanning, IaC scanning, and
   container image scanning with Trivy/Gitleaks.
4. GitHub Actions assumes an AWS IAM role using OIDC and pushes the image to
   Amazon ECR with the immutable Git SHA tag.
5. The pipeline commits the image repository and tag into `gitops/kustomization.yaml`.
6. Argo CD detects the GitOps change and syncs the workload to EKS.
7. The AWS Load Balancer Controller reconciles the ALB ingress for
   `app.alffino.online`.

## Required GitHub Secrets

- `AWS_ROLE_TO_ASSUME`: IAM role ARN trusted by GitHub OIDC.
- `ECR_REPOSITORY`: ECR repository URL from Terraform output
  `ecr_repository_url`.
- `GITOPS_REPO`: GitOps repository URL. This can be the same repo.
- `GITOPS_REPO_TOKEN`: Fine-scoped token allowed to push GitOps image updates.

## First-Time Setup

Create the Terraform state backend once before initializing the main stack:

```bash
terraform -chdir=terraform/backend-bootstrap init
terraform -chdir=terraform/backend-bootstrap apply
terraform -chdir=terraform init -migrate-state
```

The bootstrap stack creates a versioned, AES256-encrypted S3 bucket with public
access blocked. The main stack uses native S3 lockfiles for state locking.

```bash
cd terraform
terraform init
terraform apply
```

Install or verify the AWS Load Balancer Controller after the cluster is ready.
The manifests assume the `alb` ingress class exists.

Apply Argo CD objects after replacing placeholders:

```bash
kubectl apply -f argocd/app.yaml
kubectl apply -f argocd/argocd-ingress.yaml
```

Replace these values before the first sync:

- `REPLACE_WITH_GITOPS_REPO` in `argocd/app.yaml`.
- `REPLACE_WITH_ECR_REPOSITORY` in `gitops/kustomization.yaml`.
- `REPLACE_WITH_APP_ACM_CERTIFICATE_ARN` in app ingress manifests.
- `REPLACE_WITH_ARGOCD_ACM_CERTIFICATE_ARN` in `argocd/argocd-ingress.yaml`.

## SSL/TLS And DNS

Create ACM certificates in the same region as the ALB for:

- `app.alffino.online`
- `argocd.alffino.online`

Use DNS validation. Hand the ACM validation CNAME records to the DNS operator.
After the ALBs are created, provide these final DNS records:

- `app.alffino.online` CNAME or ALIAS to the application ALB DNS name.
- `argocd.alffino.online` CNAME or ALIAS to the shared/public ALB DNS name.

Both ingresses enforce HTTP to HTTPS redirects and use the TLS 1.2/1.3 ALB
security policy.

## Rollback

Preferred GitOps rollback:

```bash
git revert <gitops-image-update-commit>
git push
```

Emergency Kubernetes rollback:

```bash
kubectl rollout history deployment/alffino-python-hello -n alffino
scripts/rollback.sh
scripts/rollback.sh <revision>
```

Argo CD self-heal will eventually return the cluster to Git desired state, so
commit a GitOps rollback after any emergency cluster-level rollback.

## Suspend And Start For Cost Optimization

Suspend public access and application compute:

```bash
scripts/suspend-environment.sh
```

For deeper savings, scale the managed node group to zero after suspension:

```bash
aws eks update-nodegroup-config \
  --cluster-name argocd-eks \
  --nodegroup-name argocd-eks-nodes \
  --scaling-config minSize=0,maxSize=1,desiredSize=0
```

Start the environment:

```bash
aws eks update-nodegroup-config \
  --cluster-name argocd-eks \
  --nodegroup-name argocd-eks-nodes \
  --scaling-config minSize=1,maxSize=3,desiredSize=2

scripts/start-environment.sh
```

For non-production environments, Terraform defaults worker nodes to Spot
capacity and keeps ECR image retention to the most recent 20 images.

## Security Controls

- GitHub Actions uses AWS OIDC instead of long-lived AWS access keys.
- Tests must pass before image publication.
- Gitleaks scans for accidental secrets.
- Trivy scans dependencies, IaC, Kubernetes manifests, and container images.
- ECR scan-on-push and lifecycle retention are enabled.
- Pods run as non-root with privilege escalation disabled, all Linux
  capabilities dropped, seccomp runtime default, and read-only root filesystem.
- Readiness/liveness probes, resource limits, HPA, PDB, ClusterIP service, and
  ALB TLS termination are configured.
- Argo CD automated sync uses prune, self-heal, retry, and Git-backed rollback.
