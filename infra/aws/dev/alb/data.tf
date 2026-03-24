# Data Sources
# Reference networking and ECS infrastructure

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket  = "mahesh-tf-state-2026-devops"
    key     = "dev/networking/terraform.tfstate"
    region  = "ap-south-1"
    profile = "devops"
  }
}

data "terraform_remote_state" "ecs" {
  backend = "s3"

  config = {
    bucket  = "mahesh-tf-state-2026-devops"
    key     = "dev/ecs/terraform.tfstate"
    region  = "ap-south-1"
    profile = "devops"
  }
}

# Get current region
data "aws_region" "current" {}
