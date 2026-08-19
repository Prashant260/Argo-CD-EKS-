# GitHub Actions AWS Credentials

The current workflow uses GitHub repository secrets containing AWS access keys.
OIDC remains documented below as the preferred future migration because it
avoids storing long-lived credentials in GitHub.

- AWS account: `755729228993`
- AWS region: `ap-southeast-2`
- GitHub repository: `Prashant260/Argo-CD-EKS-`
- Deployment branch: `main`
- GitHub secrets: `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

## Current setup: access-key secrets

In **GitHub -> Settings -> Secrets and variables -> Actions**, create these
repository secrets:

- `AWS_ACCESS_KEY_ID`: the IAM access key ID.
- `AWS_SECRET_ACCESS_KEY`: the matching IAM secret access key.

The IAM identity behind these keys needs only the permissions required by this
workflow: Terraform infrastructure changes, ECR push and scan operations, EKS
cluster access, and the required `iam:PassRole` permissions. Do not use the
root account credentials or an unrestricted administrator key.

The workflow uses `aws-actions/configure-aws-credentials@v4` with these secrets
and `aws-region: ap-southeast-2`.

## Preferred alternative: GitHub Actions OIDC

The following setup is optional and is not required for the current workflow.
It can replace access-key secrets later with the role
`arn:aws:iam::755729228993:role/GitHubActionsEKSDeploy`.

## 1. Create the GitHub OIDC provider

Run this once. If the provider already exists, skip this step. Prefer the AWS
Console to create the provider because AWS manages the current certificate
thumbprint. First check whether the provider already exists:

```bash
aws iam list-open-id-connect-providers
```

If the provider is absent, create it from the IAM Console at **IAM -> Identity
providers -> Add provider**, using:

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

## 2. Save this trust policy

Save the following JSON as `github-actions-trust-policy.json`. It permits only
this repository's `main` branch to assume the deployment role.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsMainBranch",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::755729228993:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:Prashant260/Argo-CD-EKS-:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

## 3. Create or update the IAM role

Create the role if it does not exist:

```bash
aws iam create-role \
  --role-name GitHubActionsEKSDeploy \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --description "GitHub Actions deployment role for Prashant260/Argo-CD-EKS-"
```

For an existing role, update its trust policy:

```bash
aws iam update-assume-role-policy \
  --role-name GitHubActionsEKSDeploy \
  --policy-document file://github-actions-trust-policy.json
```

The trust policy controls **who may assume the role**. The role also needs an
appropriate permissions policy for the workflow's operations, including the
Terraform-managed AWS resources, ECR image publishing, and EKS access. Grant
only the permissions required by the deployment rather than attaching
`AdministratorAccess`.

## 4. Configure the GitHub secret

In **GitHub -> Settings -> Secrets and variables -> Actions**, create or update
this repository secret:

- Name: `AWS_ROLE_TO_ASSUME`
- Value: `arn:aws:iam::755729228993:role/GitHubActionsEKSDeploy`

The workflow already uses `aws-actions/configure-aws-credentials@v4` with
`aws-region: ap-southeast-2` and `role-to-assume` set from this secret.

## Security note

This policy intentionally trusts only pushes to `main`. It does not trust
arbitrary branches or fork pull requests. The current workflow's AWS-backed
Terraform plan on pull requests therefore requires a separate review of the
workflow design before enabling credentials for untrusted pull request code.
Never add a wildcard `sub` condition such as `repo:Prashant260/Argo-CD-EKS-:*`
to a production deployment role.
