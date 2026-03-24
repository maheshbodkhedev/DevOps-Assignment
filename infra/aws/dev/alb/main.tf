# ============================================
# SECURITY GROUP FOR ALB
# ============================================

resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    description = "Allow HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.terraform_remote_state.networking.outputs.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# UPDATE ECS SECURITY GROUPS TO ALLOW ALB
# ============================================

# Allow ALB to communicate with backend
resource "aws_security_group_rule" "backend_from_alb" {
  type                     = "ingress"
  from_port                = var.backend_container_port
  to_port                  = var.backend_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = data.terraform_remote_state.ecs.outputs.backend_security_group_id
  description              = "Allow traffic from ALB to backend"
}

# Allow ALB to communicate with frontend
resource "aws_security_group_rule" "frontend_from_alb" {
  type                     = "ingress"
  from_port                = var.frontend_container_port
  to_port                  = var.frontend_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = data.terraform_remote_state.ecs.outputs.frontend_security_group_id
  description              = "Allow traffic from ALB to frontend"
}

# ============================================
# APPLICATION LOAD BALANCER
# ============================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-${var.alb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.networking.outputs.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout              = var.idle_timeout

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ============================================
# TARGET GROUPS
# ============================================

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path_frontend
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = var.deregistration_delay

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-tg"
  }
}

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path_backend
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = var.deregistration_delay

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-tg"
  }
}

# ============================================
# ALB LISTENER
# ============================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action - forward to frontend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-http-listener"
  }
}

# ============================================
# LISTENER RULES - PATH-BASED ROUTING
# ============================================

# Rule: Forward /api/* to backend
resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-rule"
  }
}

# Rule: Forward / to frontend (explicit rule for clarity)
resource "aws_lb_listener_rule" "frontend_root" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-rule"
  }
}
