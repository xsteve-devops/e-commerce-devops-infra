# E-Commerce DevOps Infrastructure

## Overview

This repository contains the infrastructure, Kubernetes manifests, and GitOps deployment configuration for my E-Commerce DevOps portfolio project.

The project is based on the OpenTelemetry Demo. I selected three microservices from the original demo and rebuilt the deployment workflow with a DevOps-focused approach:

- Ad Service
- Product Catalog Service
- Recommendation Service

This repository is responsible for the infrastructure and deployment side of the project:

- Terraform infrastructure provisioning
- AWS EKS cluster creation
- Kubernetes manifests
- Argo CD Applications
- GitOps desired state
- Bootstrap and cleanup scripts

The project uses a two-repository design:

- `e-commerce-devops-app`: application source code, Dockerfiles, GitHub Actions workflows, image build, image scan, and image publishing
- `e-commerce-devops-infra`: Terraform infrastructure code, Kubernetes manifests, Argo CD Applications, and GitOps desired state

The application repository builds and publishes immutable Docker images. This infrastructure repository stores the desired Kubernetes deployment state. Argo CD synchronizes that desired state to AWS EKS.

## Architecture

![Two Repository GitOps Workflow](docs/images/two-repo-gitops-workflow.png)

## Current Status

The infrastructure and GitOps implementation has been completed and validated on AWS EKS.

| Area | Status |
|---|---|
| Terraform bootstrap backend | Completed |
| Terraform EKS stack | Completed |
| Terraform addons stack | Completed |
| Argo CD App of Apps | Completed |
| AWS Load Balancer Controller | Completed |
| Kubernetes manifests for selected services | Completed |
| End-to-end EKS validation | Completed |
| Cleanup validation | Completed |

Validated services:

| Service | Manifest Path | Argo CD Application |
|---|---|---|
| Ad Service | `kubernetes/core-services/ad` | `ad-service` |
| Product Catalog Service | `kubernetes/core-services/product-catalog` | `product-catalog-service` |
| Recommendation Service | `kubernetes/core-services/recommendation` | `recommendation-service` |

## Repository Structure

```text
argocd/
  root-app.yaml
  applications/
    platform.yaml
    shared-services.yaml
    ad-service.yaml
    product-catalog-service.yaml
    recommendation-service.yaml
    demo-supporting-services.yaml

kubernetes/
  platform/
    namespace.yaml
    serviceaccount.yaml

  shared-services/
    flagd/

  core-services/
    ad/
    product-catalog/
    recommendation/

  demo-supporting-services/
    frontend/
    frontendproxy/
    cart/
    checkout/
    payment/
    shipping/
    ...

terraform/
  bootstrap/
    # Creates the S3 backend for Terraform remote state

  eks/
    # Creates VPC, subnets, NAT Gateway, EKS cluster, node group, and EKS addons

  addons/
    # Installs Argo CD and AWS Load Balancer Controller

scripts/
  bootstrap.sh
  destroy.sh
```

## Terraform Design

The Terraform code is split into three stacks.

### `terraform/bootstrap`

Creates the S3 bucket used as the remote backend for Terraform state.

This stack is separated because the remote backend must exist before the other Terraform stacks can store their state in S3.

### `terraform/eks`

Creates the core AWS infrastructure:

- VPC
- Public subnets
- Private subnets
- NAT Gateway
- EKS cluster
- Managed node group
- EKS managed addons

The EKS worker nodes are placed in private subnets. Public subnets are used for resources such as the NAT Gateway and internet-facing ALB.

### `terraform/addons`

Installs cluster-level addons:

- Argo CD
- AWS Load Balancer Controller

The addons stack reads required outputs from the EKS stack through Terraform remote state.

## GitOps Design

![Infra GitOps Architecture](docs/images/infra-gitops-architecture.png)

Argo CD is configured with the App of Apps pattern.

```text
root-app
  -> platform
  -> shared-services
  -> ad-service
  -> product-catalog-service
  -> recommendation-service
  -> demo-supporting-services
```

The root application points to:

```text
argocd/applications
```

Child applications are stored as declarative YAML files in Git. When a new service Application is added to this directory, the root app can discover and manage it.

Current sync order:

```text
platform                  wave 0
shared-services           wave 1
ad-service                wave 2
product-catalog-service   wave 2
recommendation-service    wave 2
demo-supporting-services  wave 2
```

This keeps platform-level resources, shared dependencies, and service workloads separated while still allowing them to be managed from a single GitOps entry point.

## Kubernetes Deployment Design

The selected core services are managed separately under:

```text
kubernetes/core-services
```

Each service has its own Kubernetes Deployment and Service manifest.

The demo application also needs supporting services such as frontend, cart, checkout, payment, shipping, Kafka, Valkey, and others. These are kept under:

```text
kubernetes/demo-supporting-services
```

Shared components used by multiple services are placed under:

```text
kubernetes/shared-services
```

## AWS Load Balancer Controller

AWS Load Balancer Controller is installed through Terraform using Helm.

It is configured with IRSA so that the controller can access AWS APIs through a dedicated IAM role instead of using broad node-level permissions.

The controller watches Kubernetes Ingress resources and creates the corresponding AWS ALB resources.

The frontend is exposed through an ALB-backed Ingress:

```text
User Browser
  -> AWS ALB
  -> Kubernetes Ingress
  -> frontendproxy
  -> frontend / backend services
```

## Bootstrap

To create the environment:

```bash
./scripts/bootstrap.sh
```

The bootstrap script performs the following steps:

```text
1. Apply the EKS Terraform stack
2. Update local kubeconfig
3. Wait for worker nodes to become Ready
4. Apply the addons Terraform stack
5. Wait for the Argo CD Application CRD
6. Apply the Argo CD root application
7. Wait for the ALB address
```

The script runs each setup step separately, making it easier to identify which layer fails during testing.

## Cleanup

To destroy the environment:

```bash
./scripts/destroy.sh
```

The destroy script cleans up resources in the following order:

```text
1. Patch Argo CD Applications with cascading delete finalizers
2. Delete Argo CD Applications
3. Delete and wait for the frontend Ingress
4. Destroy the addons Terraform stack
5. Destroy the EKS Terraform stack
```

This order is important because the AWS Load Balancer Controller must still be running when the Ingress is deleted. Otherwise, ALB-related AWS resources such as Security Groups may remain and block VPC deletion.

The cleanup script handles all Argo CD Applications:

```text
root-app
platform
shared-services
ad-service
product-catalog-service
recommendation-service
demo-supporting-services
```

## Validation

The end-to-end deployment was validated on AWS EKS.

Validated items:

- Terraform provisioned the EKS cluster and addons successfully
- Argo CD synced all Applications successfully
- Ad, Product Catalog, and Recommendation services were deployed with SHA-tagged images
- All application pods were Running without restarts
- AWS Load Balancer Controller created an ALB for the frontend ingress
- The frontend returned HTTP 200 through the ALB endpoint
- The destroy script cleaned up EKS, ALB, NAT Gateway, EC2, EIP, and VPC resources

Useful verification commands:

```bash
kubectl get applications -n argocd
kubectl get deploy -n e-commerce-devops
kubectl get pods -n e-commerce-devops
kubectl get svc -n e-commerce-devops
kubectl get ingress -n e-commerce-devops
```

Check external access:

```bash
curl -I http://<alb-dns-name>
```

Check AWS cleanup:

```bash
terraform -chdir=terraform/addons state list
terraform -chdir=terraform/eks state list
aws eks list-clusters --region ap-northeast-1
```

Additional cleanup checks:

```bash
aws elbv2 describe-load-balancers --region ap-northeast-1
aws ec2 describe-nat-gateways --region ap-northeast-1
aws ec2 describe-addresses --region ap-northeast-1
aws ec2 describe-vpcs --region ap-northeast-1
aws ec2 describe-instances --region ap-northeast-1
```

## Future Improvements

The end-to-end CI/CD and GitOps deployment flow has been validated successfully.

Future improvements may include:

- Add monitoring dashboards with Prometheus and Grafana
- Extend the same CI/CD and GitOps pattern to additional microservices

## Related Repository

Application source code, Dockerfiles, and GitHub Actions workflows are managed in:

```text
e-commerce-devops-app
```

## Tech Stack

- Cloud: AWS
- Kubernetes Platform: Amazon EKS
- Infrastructure as Code: Terraform
- GitOps: Argo CD
- Package Manager: Helm
- Load Balancing: AWS Load Balancer Controller, AWS ALB
- Container Platform: Kubernetes
- Container Images: Docker
- CI/CD Integration: GitHub Actions
