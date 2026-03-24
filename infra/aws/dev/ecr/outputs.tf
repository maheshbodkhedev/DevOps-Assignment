# Output values for ECR repositories

# ============================================
# Backend Repository Outputs
# ============================================

output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_arn" {
  description = "ARN of the backend ECR repository"
  value       = aws_ecr_repository.backend.arn
}

output "backend_repository_name" {
  description = "Name of the backend ECR repository"
  value       = aws_ecr_repository.backend.name
}

# ============================================
# Frontend Repository Outputs
# ============================================

output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_arn" {
  description = "ARN of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.arn
}

output "frontend_repository_name" {
  description = "Name of the frontend ECR repository"
  value       = aws_ecr_repository.frontend.name
}

# ============================================
# Registry Information
# ============================================

output "registry_id" {
  description = "Registry ID (AWS Account ID)"
  value       = aws_ecr_repository.backend.registry_id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}
