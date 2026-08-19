# GitOps Manifests

Argo CD watches this directory and deploys the `alffino-python-hello`
application to EKS. CI updates only the image override in
`kustomization.yaml`; Kubernetes rollout history and Git history provide the
rollback trail.

Required replacements before the first sync:

- `REPLACE_WITH_ECR_REPOSITORY`: ECR repository URI without a tag, for example
  `123456789012.dkr.ecr.us-east-1.amazonaws.com/alffino-python-hello`.
- `REPLACE_WITH_APP_ACM_CERTIFICATE_ARN`: ACM certificate ARN for
  `app.alffino.online`.
