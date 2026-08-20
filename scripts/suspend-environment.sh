#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-alffino}
APP=${APP:-alffino-python-hello}
ARGOCD_NAMESPACE=${ARGOCD_NAMESPACE:-argocd}

kubectl patch application "$APP" -n "$ARGOCD_NAMESPACE" --type merge \
  -p '{"spec":{"syncPolicy":null}}' || true
kubectl delete ingress "$APP" -n "$NAMESPACE" --ignore-not-found
kubectl delete hpa "$APP" -n "$NAMESPACE" --ignore-not-found
kubectl scale deployment "$APP" -n "$NAMESPACE" --replicas=0

cat <<MSG
Argo CD automated sync is paused, application pods are scaled to zero, and
the public ingress is deleted so the AWS Load Balancer Controller can remove
the internet-facing ALB.

For larger savings, scale the EKS managed node group to zero:

aws eks update-nodegroup-config \
  --cluster-name "\$CLUSTER_NAME" \
  --nodegroup-name "\$NODEGROUP_NAME" \
  --scaling-config minSize=0,maxSize=1,desiredSize=0
MSG
