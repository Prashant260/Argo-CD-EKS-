#!/usr/bin/env bash
set -euo pipefail

GITOPS_REPO=${GITOPS_REPO:-}
GITOPS_TOKEN=${GITOPS_REPO_TOKEN:-}
IMAGE=${1:-}

if [[ -z "$GITOPS_REPO" || -z "$IMAGE" ]]; then
  echo "Usage: GITOPS_REPO=<repo> [GITOPS_REPO_TOKEN=<token>] $0 <image:tag>"
  exit 1
fi

workdir=""
cleanup_tmp=false

# Determine how to obtain the repo: local path or remote URL
if [[ -d "$GITOPS_REPO" ]]; then
  # local directory — operate in-place
  workdir="$GITOPS_REPO"
else
  tmpdir=$(mktemp -d)
  cleanup_tmp=true
  # support HTTPS clone with token when provided
  if [[ -n "$GITOPS_TOKEN" && ( "$GITOPS_REPO" == http* || "$GITOPS_REPO" == *github.com* ) ]]; then
    git clone "https://x-access-token:${GITOPS_TOKEN}@${GITOPS_REPO}" "$tmpdir"
  else
    git clone "$GITOPS_REPO" "$tmpdir"
  fi
  workdir="$tmpdir"
fi

pushd "$workdir" > /dev/null

# ensure git user is set for CI clones
git config user.email "ci@local" || true
git config user.name "ci-bot" || true

# If this is not a git repo (local skeleton), initialize one so commits work
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git init
  git add -A
  git commit -m "chore: initial commit (gitops skeleton)" || true
fi

# Replace common placeholders in YAML/kustomize files.
# Handles occurrences like `image: REPLACE_WITH_IMAGE`, `REPLACE_WITH_IMAGE`,
# and kustomize `images: - name: ... newName: ...` entries.
shopt -s globstar || true
changed=false
for f in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \) ); do
  if grep -q -E "REPLACE_WITH_IMAGE|REPLACE_WITH_ECR_REPO" "$f"; then
    sed -E -i \
      -e "s|(image:\s*)REPLACE_WITH_IMAGE|\1${IMAGE}|g" \
      -e "s|REPLACE_WITH_IMAGE|${IMAGE}|g" \
      -e "s|REPLACE_WITH_ECR_REPO[:=]?\s*.*|${IMAGE}|g" \
      -e "s|(newName:\s*)REPLACE_WITH_IMAGE|\1${IMAGE}|g" \
      "$f"
    changed=true
  fi
done

if [[ "$changed" = true ]]; then
  git add -A
  if git diff --cached --quiet; then
    echo "No changes to commit"
  else
    git commit -m "ci: update image to ${IMAGE}" || true
    # Try to push, but do not fail the script if push is not possible
    git push || true
  fi
else
  echo "No placeholders found; nothing to update"
fi

popd > /dev/null

if $cleanup_tmp; then
  rm -rf "$tmpdir"
fi

echo "GitOps repo updated"
