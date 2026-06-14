variable "aws_region" {

  description = "The AWS region where EKS infrastructure resources are created."
  type        = string
  default     = "ap-northeast-1"

}

variable "cluster_name" {

  description = "The name of the EKS cluster."
  type        = string
  default     = "e-commerce-devops"

}

variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
  default     = "e-commerce-devops-vpc"
}

variable "vpc_cidr" {

  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

}

variable "public_subnet_cidrs" {

  description = "The CIDR block for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

}

variable "private_subnet_cidrs" {

  description = "The CIDR block for the private subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "cluster_version" {

  description = "The version of the EKS cluster."
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {

  description = "The instance types for the EKS nodes."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {

  description = "The minimum number of EKS nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {

  description = "The maximum number of EKS nodes."
  type        = number
  default     = 3
}

variable "node_desired_size" {

  description = "The desired number of EKS nodes."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
    Project     = "e-commerce-devops"
  }
}