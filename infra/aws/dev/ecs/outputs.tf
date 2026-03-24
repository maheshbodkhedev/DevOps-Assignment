# Output values for ECS infrastructure

# ============================================
# ECS Cluster Outputs
# ============================================

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

# ============================================
# Backend Service Outputs
# ============================================

output "backend_service_name" {
  description = "Name of the backend ECS service"
  value       = aws_ecs_service.backend.name
}

output "backend_service_id" {
  description = "ID of the backend ECS service"
  value       = aws_ecs_service.backend.id
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}

output "backend_security_group_id" {
  description = "Security group ID for backend tasks"
  value       = aws_security_group.backend.id
}

output "backend_log_group_name" {
  description = "CloudWatch log group name for backend"
  value       = aws_cloudwatch_log_group.backend.name
}

# ============================================
# Frontend Service Outputs
# ============================================

output "frontend_service_name" {
  description = "Name of the frontend ECS service"
  value       = aws_ecs_service.frontend.name
}

output "frontend_service_id" {
  description = "ID of the frontend ECS service"
  value       = aws_ecs_service.frontend.id
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.arn
}

output "frontend_security_group_id" {
  description = "Security group ID for frontend tasks"
  value       = aws_security_group.frontend.id
}

output "frontend_log_group_name" {
  description = "CloudWatch log group name for frontend"
  value       = aws_cloudwatch_log_group.frontend.name
}

# ============================================
# IAM Role Outputs
# ============================================

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "backend_task_role_arn" {
  description = "ARN of the backend task role"
  value       = aws_iam_role.backend_task.arn
}

output "frontend_task_role_arn" {
  description = "ARN of the frontend task role"
  value       = aws_iam_role.frontend_task.arn
}

# ============================================
# Reference to Networking (from Phase 1)
# ============================================

output "vpc_id" {
  description = "VPC ID from networking module"
  value       = data.terraform_remote_state.networking.outputs.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where ECS tasks are running"
  value       = data.terraform_remote_state.networking.outputs.private_subnet_ids
}
