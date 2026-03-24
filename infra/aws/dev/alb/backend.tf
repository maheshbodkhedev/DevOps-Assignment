# Terraform Remote State Configuration for ALB
# Separate state file for load balancer

terraform {
  backend "s3" {
    bucket         = "mahesh-tf-state-2026-devops"
    key            = "dev/alb/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "devops"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
