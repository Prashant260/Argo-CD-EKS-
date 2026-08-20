#!/usr/bin/env bash
set -euo pipefail

GITOPS_REPO=${GITOPS_REPO:-}
GITOPS_TOKEN=${GITOPS_REPO_TOKEN:-}
IMAGE=${1:-}

if [[ -z "$GITOPS_REPO" || -z "$IMAGE" ]]; then
  echo "Usage: GITOPS_REPO=<repo-url-or-path> [GITOPS_REPO_TOKEN=<token>] $0 <ecr-image:tag>"
  exit 1
fi

if [[ "$GITOPS_REPO" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  GITOPS_REPO="https://github.com/${GITOPS_REPO}.git"
fi

if [[ "$GITOPS_REPO" =~ ^https://github.com/[^/]+/[^/]+/?$ && "$GITOPS_REPO" != *.git && "$GITOPS_REPO" != *.git/ ]]; then
  GITOPS_REPO="${GITOPS_REPO%/}.git"
fi

if [[ "$GITOPS_REPO" == https://github.com/* && -z "$GITOPS_TOKEN" ]]; then
  echo "ERROR: GITOPS_REPO_TOKEN is required for private GitHub repositories."
  exit 1
fi

repo_without_tag="${IMAGE%:*}"
tag="${IMAGE##*:}"

if [[ "$repo_without_tag" == "$tag" ]]; then
  echo "Image must include an explicit tag: $IMAGE"
  exit 1
fi

cleanup_tmp=false
if [[ -d "$GITOPS_REPO" ]]; then
  workdir="$GITOPS_REPO"
else
  tmpdir=$(mktemp -d)
  cleanup_tmp=true
  if [[ -n "$GITOPS_TOKEN" && "$GITOPS_REPO" == https://github.com/* ]]; then
    clone_url="https://x-access-token:${GITOPS_TOKEN}@${GITOPS_REPO#https://}"
    git clone --quiet "$clone_url" "$tmpdir"
  else
    git clone --quiet "$GITOPS_REPO" "$tmpdir"
  fi
  workdir="$tmpdir"
fi

pushd "$workdir" > /dev/null

git config user.email "${GIT_AUTHOR_EMAIL:-ci@alffino.online}"
git config user.name "${GIT_AUTHOR_NAME:-github-actions}"

manifest_dir="${GITOPS_PATH:-gitops}"
if [[ ! -f "$manifest_dir/kustomization.yaml" && -f "kustomization.yaml" ]]; then
  manifest_dir="."
fi

if [[ ! -f "$manifest_dir/kustomization.yaml" ]]; then
  echo "Cannot find kustomization.yaml in $manifest_dir"
  exit 1
fi

python3 - "$manifest_dir/kustomization.yaml" "$repo_without_tag" "$tag" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
repo = sys.argv[2]
tag = sys.argv[3]
lines = path.read_text().splitlines()
out = []

for line in lines:
    stripped = line.strip()
    if stripped.startswith("newName:"):
        indent = line[: len(line) - len(line.lstrip())]
        out.append(f"{indent}newName: {repo}")
    elif stripped.startswith("newTag:"):
        indent = line[: len(line) - len(line.lstrip())]
        out.append(f"{indent}newTag: {tag}")
    else:
        out.append(line)

path.write_text("\n".join(out) + "\n")
PY

if [[ -f "$manifest_dir/k8s/deployment.yaml" ]]; then
  python3 - "$manifest_dir/k8s/deployment.yaml" "$tag" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
tag = sys.argv[2]
lines = path.read_text().splitlines()
out = []
for line in lines:
    stripped = line.strip()
    if stripped.startswith("app.kubernetes.io/version:"):
        indent = line[: len(line) - len(line.lstrip())]
        out.append(f"{indent}app.kubernetes.io/version: {tag}")
    else:
        out.append(line)
path.write_text("\n".join(out) + "\n")
PY
fi

git add "$manifest_dir"
if git diff --cached --quiet; then
  echo "No GitOps image changes to commit"
else
  git commit -m "ci: deploy ${IMAGE}"
  git fetch origin main
  git rebase origin/main
  git push
fi

popd > /dev/null

if [[ "$cleanup_tmp" == true ]]; then
  rm -rf "$tmpdir"
fi

echo "GitOps image set to $IMAGE"
