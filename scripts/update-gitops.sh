#!/usr/bin/env bash
set -euo pipefail

GITOPS_REPO=${GITOPS_REPO:-}
GITOPS_TOKEN=${GITOPS_REPO_TOKEN:-}
IMAGE=${1:-}

if [[ -z "$GITOPS_REPO" || -z "$GITOPS_TOKEN" || -z "$IMAGE" ]]; then
  echo "Usage: GITOPS_REPO=<repo> GITOPS_REPO_TOKEN=<token> $0 <image:tag>"
  exit 1
fi

tmpdir=$(mktemp -d)
git clone https://x-access-token:${GITOPS_TOKEN}@${GITOPS_REPO} "$tmpdir"
pushd "$tmpdir" > /dev/null
# naive replacement: find and replace image references
grep -R --line-number "REPLACE_WITH_ECR_REPO" || true
find . -type f -name "*.yaml" -exec sed -i "s|REPLACE_WITH_ECR_REPO:.*|${IMAGE}|g" {} + || true
git add -A
git commit -m "ci: update image to ${IMAGE}" || true
git push
popd
rm -rf "$tmpdir"

echo "GitOps repo updated"
