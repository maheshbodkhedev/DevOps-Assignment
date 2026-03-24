# ============================================
# ECS SERVICE UPDATES FOR ALB INTEGRATION
# ============================================
# This file contains updated ECS service definitions that integrate with ALB
# Replace the existing service definitions in main.tf with these

# Get ALB target group ARNs from ALB state
data "terraform_remote_state" "alb" {
  backend = "s3"

  config = {
    bucket  = "mahesh-tf-state-2026-devops"
    key     = "dev/alb/terraform.tfstate"
    region  = "ap-south-1"
    profile = "devops"
  }
}

# Backend ECS Service with ALB integration
resource "aws_ecs_service" "backend_with_alb" {
  name            = var.backend_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.networking.outputs.private_subnet_ids
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.backend_target_group_arn
    container_name   = var.backend_container_name
    container_port   = var.backend_container_port
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Wait for ALB target group to be created
  depends_on = [data.terraform_remote_state.alb]

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-service"
  }
}

# Frontend ECS Service with ALB integration
resource "aws_ecs_service" "frontend_with_alb" {
  name            = var.frontend_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.networking.outputs.private_subnet_ids
    security_groups  = [aws_security_group.frontend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.frontend_target_group_arn
    container_name   = var.frontend_container_name
    container_port   = var.frontend_container_port
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Wait for ALB target group to be created
  depends_on = [data.terraform_remote_state.alb]

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-service"
  }
}
