variable "aws_region" {

  description = "The AWS region where Terraform backend resources are created."
  type        = string
}

variable "state_bucket_name" {

  description = "The name of the S3 bucket where Terraform state is stored."
  type        = string
}

variable "tags" {

  description = "tags for bootstrap resources"
  type        = map(string)
  default = {
    Project     = "e-commerce-devops"
    Managed-by  = "terraform"
    Environment = "bootstrap"
  }
}