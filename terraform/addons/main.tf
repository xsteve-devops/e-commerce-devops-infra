# Argo CD installation

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

}

# AWS Load Balancer Controller IAM resources

resource "aws_iam_policy" "alb_controller" {
  name   = "aws-load-balancer-controller"
  policy = file("${path.module}/policies/aws-load-balancer-controller-iam-policy.json")
}

resource "aws_iam_role" "alb_controller" {
  name = "aws-load-balancer-controller"
  assume_role_policy = jsonencode({

    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          Federated = data.terraform_remote_state.eks.outputs.oidc_provider_arn
        }
        "Condition" : {
          "StringEquals" : {
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:aud" : "sts.amazonaws.com",
            "${data.terraform_remote_state.eks.outputs.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
        "Action" : "sts:AssumeRoleWithWebIdentity",
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# Application Load Balancer Controller installation

resource "helm_release" "alb_controller" {
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "3.2.2"

  values = [
    yamlencode({
      clusterName = data.terraform_remote_state.eks.outputs.cluster_name
      region      = var.aws_region
      vpcId       = data.terraform_remote_state.eks.outputs.vpc_id

      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
        }
      }
    })
  ]
  depends_on = [
    aws_iam_role_policy_attachment.alb_controller
  ]

}
