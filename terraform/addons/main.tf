data "aws_eks_cluster" "this" {

  name = var.cluster_name

}

data "aws_eks_cluster_auth" "this" {

  name = var.cluster_name

}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

}