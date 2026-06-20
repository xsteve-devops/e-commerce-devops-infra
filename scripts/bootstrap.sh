#!/usr/bin/env bash

# Deploy the e-commerce devops bootstrap resources
# Usage: ./scripts/bootstrap.sh
# Deploy EKS cluster and supporting services

set -euo pipefail

# Get the directory of the current script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

cd "$PROJECT_ROOT"

echo "Initializing EKS Terraform stack..."
terraform -chdir=terraform/eks init

echo "Applying EKS Terraform stack..."
terraform -chdir=terraform/eks apply

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region ap-northeast-1 --name e-commerce-devops

echo "Waiting for worker nodes..."
kubectl wait --for=condition=Ready nodes --all --timeout=10m

echo "Installing Argo CD..."
terraform -chdir=terraform/addons init
terraform -chdir=terraform/addons apply

echo "Waiting for Argo CD Application CRD..."
kubectl wait --for=condition=Established crd/applications.argoproj.io --timeout=120s

echo "Applying Argo CD root application..."
kubectl apply -f argocd/root-app.yaml

echo "Argo CD applications:"
kubectl get applications -n argocd

# Print the URL of the ALB
echo "Waiting for ALB address..."
ALB_ADDRESS=""

for i in {1..15}; do
  ALB_ADDRESS=$(kubectl get ingress frontend-proxy -n e-commerce-devops \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)

  if [ -n "$ALB_ADDRESS" ]; then
    echo "ALB address: http://${ALB_ADDRESS}"
    break
  fi

  echo "ALB address is not ready yet. Retrying..."
  sleep 20
done

if [ -z "$ALB_ADDRESS" ]; then
  echo "ALB address was not ready within the timeout."
  kubectl get ingress -n e-commerce-devops || true
  exit 1
fi

echo "Bootstrap completed"  