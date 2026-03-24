# Output values for ALB infrastructure

# ============================================
# ALB Outputs
# ============================================

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

# ============================================
# Target Group Outputs
# ============================================

output "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  value       = aws_lb_target_group.frontend.arn
}

output "frontend_target_group_name" {
  description = "Name of the frontend target group"
  value       = aws_lb_target_group.frontend.name
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

output "backend_target_group_name" {
  description = "Name of the backend target group"
  value       = aws_lb_target_group.backend.name
}

# ============================================
# Listener Outputs
# ============================================

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

# ============================================
# Application URL
# ============================================

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_lb.main.dns_name}/"
}

output "backend_api_url" {
  description = "Backend API URL"
  value       = "http://${aws_lb.main.dns_name}/api"
}
