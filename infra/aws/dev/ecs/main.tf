# ============================================
# SECURITY GROUPS
# ============================================

# Backend Security Group
# Allows inbound traffic on port 8000 (FastAPI)
resource "aws_security_group" "backend" {
  name_prefix = "${var.project_name}-${var.environment}-backend-"
  description = "Security group for backend ECS tasks"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    description = "Allow HTTP traffic from VPC"
    from_port   = var.backend_container_port
    to_port     = var.backend_container_port
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.networking.outputs.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Frontend Security Group
# Allows inbound traffic on port 3000 (Next.js)
resource "aws_security_group" "frontend" {
  name_prefix = "${var.project_name}-${var.environment}-frontend-"
  description = "Security group for frontend ECS tasks"
  vpc_id      = data.terraform_remote_state.networking.outputs.vpc_id

  ingress {
    description = "Allow HTTP traffic from VPC"
    from_port   = var.frontend_container_port
    to_port     = var.frontend_container_port
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.networking.outputs.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================
# IAM ROLES AND POLICIES
# ============================================

# ECS Task Execution Role
# Used by ECS agent to pull images and push logs
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for ECR access (for private images)
resource "aws_iam_role_policy" "ecs_task_execution_ecr" {
  name = "${var.project_name}-${var.environment}-ecs-ecr-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Task Role (for application permissions)
# Backend task role - can be extended with S3, DynamoDB, etc.
resource "aws_iam_role" "backend_task" {
  name = "${var.project_name}-${var.environment}-backend-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-task-role"
  }
}

# Minimal policy for backend (can be extended later)
resource "aws_iam_role_policy" "backend_task" {
  name = "${var.project_name}-${var.environment}-backend-task-policy"
  role = aws_iam_role.backend_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Frontend task role
resource "aws_iam_role" "frontend_task" {
  name = "${var.project_name}-${var.environment}-frontend-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-task-role"
  }
}

# Minimal policy for frontend
resource "aws_iam_role_policy" "frontend_task" {
  name = "${var.project_name}-${var.environment}-frontend-task-policy"
  role = aws_iam_role.frontend_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================
# CLOUDWATCH LOG GROUPS
# ============================================

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-${var.environment}/${var.backend_service_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-logs"
    ServiceName = var.backend_service_name
  }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-${var.environment}/${var.frontend_service_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-logs"
    ServiceName = var.frontend_service_name
  }
}

# ============================================
# ECS CLUSTER
# ============================================

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-${var.ecs_cluster_name}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# ============================================
# ECS TASK DEFINITIONS
# ============================================

# Backend Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-${var.backend_service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.backend_task.arn

  container_definitions = jsonencode([
    {
      name      = var.backend_container_name
      image     = var.backend_image
      essential = true

      portMappings = [
        {
          containerPort = var.backend_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.backend_container_port)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.backend_container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-task"
  }
}

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-${var.environment}-${var.frontend_service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.frontend_task.arn

  container_definitions = jsonencode([
    {
      name      = var.frontend_container_name
      image     = var.frontend_image
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.frontend_container_port)
        },
        {
          name  = "NEXT_PUBLIC_API_URL"
          value = "http://backend:${var.backend_container_port}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.frontend_container_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-task"
  }
}

# ============================================
# ECS SERVICES
# ============================================

# Backend ECS Service
# Runs in private subnets for security
resource "aws_ecs_service" "backend" {
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

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-service"
  }
}

# Frontend ECS Service
# Runs in private subnets for security
resource "aws_ecs_service" "frontend" {
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

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-service"
  }
}
