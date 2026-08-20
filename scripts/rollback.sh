#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-alffino}
DEPLOYMENT=${DEPLOYMENT:-alffino-python-hello}
REVISION=${1:-}

if [[ -n "$REVISION" ]]; then
  kubectl rollout undo "deployment/${DEPLOYMENT}" -n "$NAMESPACE" --to-revision="$REVISION"
else
  kubectl rollout undo "deployment/${DEPLOYMENT}" -n "$NAMESPACE"
fi

kubectl rollout status "deployment/${DEPLOYMENT}" -n "$NAMESPACE" --timeout=5m
