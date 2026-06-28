#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
cd "$PROJECT_ROOT"

echo "Adding Argo CD cascading delete finalizers..."
for app in root-app platform shared-services ad-service product-catalog-service recommendation-service demo-supporting-services; do
  if kubectl get application "$app" -n argocd >/dev/null 2>&1; then
    kubectl patch application "$app" \
      -n argocd \
      --type merge \
      -p '{"metadata":{"finalizers":["resources-finalizer.argocd.argoproj.io"]}}'
  fi
done

echo "Deleting Argo CD applications..."
for app in root-app demo-supporting-services ad-service product-catalog-service recommendation-service shared-services platform; do
  kubectl delete application "$app" -n argocd --ignore-not-found || true
done

echo "Deleting frontend ingress..."
kubectl delete ingress frontend-proxy -n e-commerce-devops --ignore-not-found --wait=false

echo "Waiting for frontend ingress to be deleted..."
if kubectl get ingress frontend-proxy -n e-commerce-devops >/dev/null 2>&1; then
  kubectl wait --for=delete ingress/frontend-proxy -n e-commerce-devops --timeout=10m
fi

echo "Deleting addons..."
terraform -chdir=terraform/addons destroy

echo "Deleting EKS cluster..."
terraform -chdir=terraform/eks destroy

echo "Done"
