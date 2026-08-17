# Argo-CD-EKS-

Architecture
------------

Developer
			     │
			     │ git push
			     ▼
		    ┌──────────────┐
		    │   GitHub     │
		    │ Application  │
		    │ Source Code  │
		    └──────┬───────┘
			     │
			     ▼
		 ┌──────────────────┐
		 │ GitHub Actions   │
		 │                  │
		 │ 1. Test          │
		 │ 2. SAST          │
		 │ 3. SCA           │
		 │ 4. Secret Scan   │
		 │ 5. Build Image   │
		 │ 6. Scan Image    │
		 └────────┬─────────┘
			    │
			    │ push image
			    ▼
		   ┌──────────────┐
		   │  Amazon ECR  │
		   │ Docker Image │
		   └──────┬───────┘
			    │
			    │ image tag
			    ▼
		  ┌─────────────────┐
		  │ GitOps Repo     │
		  │ Kubernetes /    │
		  │ Helm manifests  │
		  └────────┬────────┘
			     │
			     │ Argo CD detects change
			     ▼
		     ┌────────────┐
		     │  Argo CD   │
		     └─────┬──────┘
			     │
			     │ deploy
			     ▼
		  ┌──────────────────┐
		  │     AWS EKS      │
		  │                  │
		  │ ┌──────────────┐ │
		  │ │ Python Pods  │ │
		  │ └──────┬───────┘ │
		  │        │          │
		  │ Kubernetes Service│
		  └────────┼──────────┘
			     │
			     ▼
		     AWS ALB
			     │
			     │ HTTPS
			     ▼
	    https://app.magnitdev.com

What I added
------------
- **CI workflow**: [.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml)
- **Dockerfile**: [Dockerfile](Dockerfile)
- **Kubernetes manifests**: [k8s/deployment.yaml](k8s/deployment.yaml), [k8s/service.yaml](k8s/service.yaml), [k8s/ingress.yaml](k8s/ingress.yaml)
- **Argo CD Application**: [argocd/app.yaml](argocd/app.yaml)
- **GitOps updater script**: [scripts/update-gitops.sh](scripts/update-gitops.sh)

Quick setup
-----------
1. Create these repository secrets in GitHub: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `ECR_REPOSITORY` (e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app), and `GITOPS_REPO` and `GITOPS_REPO_TOKEN` (a PAT with repo access for the GitOps repo).
2. Adjust the values in `.github/workflows/ci-cd.yml` and `scripts/update-gitops.sh` to match your org and repo names.
3. Install the AWS Load Balancer Controller in your EKS cluster and set up IAM/service account for ALB.
4. Create an Argo CD `Application` using [argocd/app.yaml](argocd/app.yaml) to point to your GitOps repo path.

Notes
-----
- The CI workflow includes placeholders for tests and SAST/SCA scans — adapt to your tech stack (pytest, pytest-cov, CodeQL, Trivy, Snyk, etc.).
- `scripts/update-gitops.sh` demonstrates how to update the image tag in the GitOps repo; use an image policy or image updater (e.g., Flux Image Automation or Argo CD Image Updater) if you prefer automated image updates.

If you want, I can customize the workflow to your specific test commands, language, or GitOps repo layout.
