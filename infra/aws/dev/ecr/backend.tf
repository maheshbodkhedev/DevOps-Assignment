# Terraform Remote State Configuration for ECR

terraform {
  backend "s3" {
    bucket         = "mahesh-tf-state-2026-devops"
    key            = "dev/ecr/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "devops"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
