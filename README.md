# E-Commerce DevOps Infrastructure

## 项目概述

本仓库用于管理 E-Commerce DevOps 实践项目中的基础设施和 Kubernetes 部署配置。

本项目采用应用代码与基础设施配置分离的方式进行管理：

- 应用仓库负责源码、Dockerfile、CI 流水线、镜像构建与推送
- Infra 仓库负责 Terraform、Kubernetes YAML、Argo CD 配置以及 GitOps 部署状态

这样设计的目的是让应用交付和基础设施部署边界更加清晰，同时也更接近真实团队中的 DevOps / GitOps 工作方式。

## 服务范围说明

本项目从 OpenTelemetry Demo 中选取了三个核心服务作为 DevOps 改造重点：

- Ad Service
- Product Catalog Service
- Recommendation Service

这三个服务会完整实现 Dockerfile 编写、GitHub Actions CI、镜像扫描、镜像推送，并基于 OpenTelemetry Demo 原始 Kubernetes manifests 进行部署配置调整，最终通过 GitOps 流程部署到 EKS。

需要说明的是，OpenTelemetry Demo 是一个完整的微服务系统。为了让最终电商 Demo 能够完整运行，除上述三个核心服务外，还需要部署其他 supporting services，例如 frontend、cart、checkout、currency、payment、shipping、email、redis、otel-collector、flagd 等。

这些 supporting services 主要用于保证系统整体运行，不作为本项目 CI/CD 改造重点。后续部署时会优先使用 OpenTelemetry Demo 官方镜像或原始 Kubernetes 配置，并将其纳入本仓库的声明式部署管理中。

## 仓库职责

本仓库主要负责以下内容：

- 使用 Terraform 创建 AWS 基础设施资源
- 创建 AWS EKS 集群及相关网络、IAM 配置
- 编写 Kubernetes Deployment、Service 等声明式部署文件
- 使用 Argo CD 监听 Git 中的部署状态
- 将应用镜像部署到 Kubernetes 集群中

## 当前阶段

当前项目正在逐步完成 Ad Service 的端到端 DevOps 流程。

已完成或正在进行的内容包括：

- App 仓库中已完成 Ad Service Dockerfile
- App 仓库中已完成 Ad Service CI Workflow
- App 仓库中已完成 Docker Build、Trivy Image Scan、镜像推送流程
- 当前仓库将开始编写 Ad Service 的 Kubernetes Deployment 和 Service YAML

## 仓库结构

```text
k8s/
  ad-service/
    deployment.yaml
    service.yaml

terraform/
  # 后续添加 EKS、VPC、Node Group、IAM 等 Terraform 配置

argocd/
  # 后续添加 Argo CD Application 配置


部署设计
整体部署流程设计如下：

Application Code Change
        |
        v
GitHub Actions CI
        |
        v
Build Docker Image
        |
        v
Push Image to Container Registry
        |
        v
Update Kubernetes Manifest
        |
        v
Argo CD Sync
        |
        v
Deploy to AWS EKS

在该流程中，CI 负责构建和发布不可变镜像，Infra 仓库负责记录 Kubernetes 集群中的期望部署状态。Argo CD 会监听本仓库中的 YAML 文件变化，并将变化同步到 EKS 集群。
