#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
cd "$PROJECT_ROOT"

echo "Deleting root app..."
kubectl delete -f argocd/root-app.yaml --ignore-not-found || true


echo "Deleting argocd..."
terraform -chdir=terraform/addons destroy

echo "Deleting EKS cluster..."  
terraform -chdir=terraform/eks destroy

echo "Done"