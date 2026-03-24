# Input Variables for ECR

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "devops"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "fullstack-app"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}
