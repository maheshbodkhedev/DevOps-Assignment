# ECS + ALB Integration Fix

## 🐛 Problem

**Symptoms:**
- ALB returns 503 Service Unavailable
- Target groups show 0 registered targets
- ECS services show "deployment failed" or tasks not healthy
- `aws elbv2 describe-target-health` shows no targets

## 🔍 Root Cause

The ECS services were missing the `load_balancer` configuration block, which is required to register ECS tasks with ALB target groups.

**What was wrong:**
```hcl
resource "aws_ecs_service" "backend" {
  # ... other config ...

  network_configuration { ... }

  # ❌ MISSING: load_balancer block
  # Without this, ECS tasks never register with target groups!
}
```

## ✅ Solution Applied

### 1. Added ALB Data Source
**File:** `ecs/data.tf`

```hcl
data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket  = "mahesh-tf-state-2026-devops"
    key     = "dev/alb/terraform.tfstate"
    region  = "ap-south-1"
    profile = "devops"
  }
}
```

### 2. Updated Backend Service
**File:** `ecs/main.tf`

```hcl
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

  # ✅ ADDED: Attach to ALB target group
  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.backend_target_group_arn
    container_name   = var.backend_container_name  # Must match task definition
    container_port   = var.backend_container_port  # Must match target group
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # ✅ ADDED: Ensure ALB exists first
  depends_on = [data.terraform_remote_state.alb]

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-service"
  }
}
```

### 3. Updated Frontend Service
Same changes applied to `frontend` service.

## 🚀 Deploy the Fix

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecs

# Review changes
terraform plan

# Apply the fix
terraform apply
```

**Expected Output:**
```
Plan: 0 to add, 2 to change, 0 to destroy.

Changes:
  ~ aws_ecs_service.backend  # will be updated in-place
  ~ aws_ecs_service.frontend # will be updated in-place
```

## 📊 Verification Steps

### 1. Check ECS Service Status
```bash
aws ecs describe-services \
  --cluster fullstack-app-dev-fullstack-cluster \
  --services backend-service frontend-service \
  --profile devops \
  --region ap-south-1 \
  --query 'services[*].[serviceName,status,runningCount,desiredCount]' \
  --output table
```

**Expected:** `runningCount` = `desiredCount`

### 2. Check Target Health
```bash
# Get target group ARN
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
BACKEND_TG=$(terraform output -raw backend_target_group_arn)
FRONTEND_TG=$(terraform output -raw frontend_target_group_arn)

# Check backend target health
aws elbv2 describe-target-health \
  --target-group-arn $BACKEND_TG \
  --profile devops \
  --region ap-south-1

# Check frontend target health
aws elbv2 describe-target-health \
  --target-group-arn $FRONTEND_TG \
  --profile devops \
  --region ap-south-1
```

**Expected:** Status = `healthy` (after health check passes)

### 3. Test ALB Endpoints
```bash
# Get ALB DNS
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
ALB_DNS=$(terraform output -raw alb_dns_name)

# Test frontend
curl http://$ALB_DNS/

# Test backend
curl http://$ALB_DNS/api/health
```

## 🔧 Why Targets Were Not Registering

### Critical Requirements for ECS + ALB Integration

1. **`load_balancer` block is MANDATORY**
   - Without it, ECS has no idea which target group to register tasks with
   - ECS tasks run but never join the target group

2. **Container name must match exactly**
   - `container_name` in `load_balancer` block must match `name` in task definition
   - Mismatch = no registration

3. **Container port must match**
   - `container_port` must match both:
     - Task definition `portMappings.containerPort`
     - Target group `port`

4. **Network mode must be `awsvpc`**
   - Required for Fargate
   - Allows IP-based target registration

5. **Target type must be `ip`**
   - Required for Fargate (already correct in ALB config)

## 📝 Key Configuration Points

### Task Definition (Already Correct)
```hcl
container_definitions = jsonencode([{
  name = var.backend_container_name  # ✅ "backend"
  portMappings = [{
    containerPort = var.backend_container_port  # ✅ 8000
    protocol      = "tcp"
  }]
}])
```

### Target Group (Already Correct)
```hcl
resource "aws_lb_target_group" "backend" {
  port        = var.backend_container_port  # ✅ 8000
  target_type = "ip"  # ✅ Required for Fargate
}
```

### ECS Service (NOW FIXED)
```hcl
load_balancer {
  target_group_arn = data.terraform_remote_state.alb.outputs.backend_target_group_arn
  container_name   = var.backend_container_name  # ✅ "backend" - matches task def
  container_port   = var.backend_container_port  # ✅ 8000 - matches target group
}
```

## ⚠️ Common Pitfalls Avoided

1. ❌ Container name typo → No registration
2. ❌ Wrong port number → Health checks fail
3. ❌ Missing data source → Terraform error
4. ❌ Hardcoded ARNs → Not maintainable
5. ✅ Used variables and outputs → Clean, maintainable

## 🎯 Expected Timeline

After `terraform apply`:
1. **0-30s**: ECS initiates new deployment
2. **30-60s**: New tasks start with load balancer attached
3. **60-90s**: Tasks register with target groups
4. **90-120s**: Health checks begin passing
5. **120-180s**: Old tasks drain and terminate
6. **~3 minutes**: Deployment complete, ALB returns 200

## 🐛 If Still Seeing 503

Check these in order:

1. **Container not starting?**
   ```bash
   # Check logs
   aws logs tail /ecs/fullstack-app-dev/backend-service --follow \
     --profile devops --region ap-south-1
   ```

2. **Health check failing?**
   - Ensure `/health` endpoint exists (backend)
   - Ensure `/` returns 200 (frontend)
   - Check app is listening on correct port (8000/3000)

3. **Security groups blocking?**
   - ALB SG must allow outbound to VPC
   - ECS SG must allow inbound from ALB SG
   - (Already configured correctly)

4. **Task not healthy?**
   ```bash
   aws ecs describe-tasks \
     --cluster fullstack-app-dev-fullstack-cluster \
     --tasks $(aws ecs list-tasks --cluster fullstack-app-dev-fullstack-cluster \
       --service-name backend-service --profile devops --region ap-south-1 \
       --query 'taskArns[0]' --output text) \
     --profile devops --region ap-south-1
   ```

## 📚 References

- [AWS ECS Service Load Balancing](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-load-balancing.html)
- [Target Group Health Checks](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [ECS Task Networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html)
