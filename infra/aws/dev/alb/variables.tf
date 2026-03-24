# Input Variables for ALB Infrastructure

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
# ALB Configuration
# ============================================

variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "fullstack-alb"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false  # Disabled for dev environment
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

# ============================================
# Target Group Configuration
# ============================================

variable "frontend_container_port" {
  description = "Port exposed by frontend container"
  type        = number
  default     = 3000
}

variable "backend_container_port" {
  description = "Port exposed by backend container"
  type        = number
  default     = 8000
}

variable "health_check_path_frontend" {
  description = "Health check path for frontend"
  type        = string
  default     = "/"
}

variable "health_check_path_backend" {
  description = "Health check path for backend"
  type        = string
  default     = "/health"
}

variable "health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout (seconds)"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Number of consecutive health checks to be considered healthy"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Number of consecutive failed health checks to be considered unhealthy"
  type        = number
  default     = 3
}

variable "deregistration_delay" {
  description = "Time to wait before deregistering target (seconds)"
  type        = number
  default     = 30
}
