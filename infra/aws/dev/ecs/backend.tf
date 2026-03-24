# Terraform Remote State Configuration for ECS
# Separate state file from networking for modularity

terraform {
  backend "s3" {
    bucket         = "mahesh-tf-state-2026-devops"
    key            = "dev/ecs/terraform.tfstate"
    region         = "ap-south-1"
    profile        = "devops"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
