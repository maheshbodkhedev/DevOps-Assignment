# Terraform Remote State Configuration
# S3 Backend: Stores Terraform state file securely in S3
# DynamoDB: Provides state locking to prevent concurrent modifications

terraform {
  backend "s3" {
    bucket         = "mahesh-tf-state-2026-devops"
    key            = "dev/networking/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "devops"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
