#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-alffino}
APP=${APP:-alffino-python-hello}
REPLICAS=${REPLICAS:-2}
ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}

kubectl patch application "$APP" -n "$ARGOCD_NAMESPACE" --type merge \
  -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true},"syncOptions":["CreateNamespace=true","PruneLast=true"],"retry":{"limit":3,"backoff":{"duration":"10s","factor":2,"maxDuration":"2m"}}}}}'
kubectl annotate application "$APP" -n "$ARGOCD_NAMESPACE" \
  argocd.argoproj.io/refresh=hard \
  --overwrite
kubectl scale deployment "$APP" -n "$NAMESPACE" --replicas="$REPLICAS" || true
kubectl rollout status "deployment/${APP}" -n "$NAMESPACE" --timeout=5m

echo "Argo CD sync is restored; application is returning to the GitOps desired state."
