data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "e-commercial-devops-project-remote-state"
    key    = "e-commerce-devops/eks/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    use_lockfile = true
  }   
}

data "aws_eks_cluster" "this" {

  name = var.cluster_name

}

data "aws_eks_cluster_auth" "this" {

  name = var.cluster_name

}