# Data Sources
# Reference networking infrastructure from Phase 1

data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket  = "mahesh-tf-state-2026-devops"
    key     = "dev/networking/terraform.tfstate"
    region  = "ap-south-1"
    profile = "devops"
  }
}

# Get AWS account ID for IAM roles
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}
