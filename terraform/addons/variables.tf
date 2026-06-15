variable "aws_region" {

  description = "The AWS region where EKS add-ons are installed."
  type        = string
  default     = "ap-northeast-1"

}

variable "cluster_name" {

  description = "The name of the EKS cluster."
  type        = string
  default     = "e-commerce-devops"

}