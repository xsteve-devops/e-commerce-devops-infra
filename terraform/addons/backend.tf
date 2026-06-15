terraform {

  backend "s3" {

    bucket       = "e-commercial-devops-project-remote-state"
    key          = "e-commerce-devops/addons/terraform.tfstate"
    region       = "ap-northeast-1"
    encrypt      = true
    use_lockfile = true

  }
}