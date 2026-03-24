# Input Variables for ECS Infrastructure

# ============================================
# AWS Configuration
# ============================================

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

# ============================================
# Project Configuration
# ============================================

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

# ============================================
# ECS Cluster Configuration
# ============================================

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "fullstack-cluster"
}

# ============================================
# Backend Service Configuration
# ============================================

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
  default     = "backend-service"
}

variable "backend_container_name" {
  description = "Name of the backend container"
  type        = string
  default     = "backend"
}

variable "backend_container_port" {
  description = "Port exposed by backend container"
  type        = number
  default     = 8000
}

variable "backend_image" {
  description = "Docker image for backend from ECR"
  type        = string
  default     = "376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend:latest"
}

variable "backend_cpu" {
  description = "CPU units for backend task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

# ============================================
# Frontend Service Configuration
# ============================================

variable "frontend_service_name" {
  description = "Name of the frontend service"
  type        = string
  default     = "frontend-service"
}

variable "frontend_container_name" {
  description = "Name of the frontend container"
  type        = string
  default     = "frontend"
}

variable "frontend_container_port" {
  description = "Port exposed by frontend container"
  type        = number
  default     = 3000
}

variable "frontend_image" {
  description = "Docker image for frontend from ECR"
  type        = string
  default     = "376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-frontend:latest"
}

variable "frontend_cpu" {
  description = "CPU units for frontend task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "frontend_memory" {
  description = "Memory for frontend task in MB"
  type        = number
  default     = 1024
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}

# ============================================
# CloudWatch Configuration
# ============================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}
