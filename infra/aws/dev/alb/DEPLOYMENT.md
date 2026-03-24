# Phase 3: ALB Deployment Guide

## 📁 Directory Structure

```
infra/aws/dev/
├── networking/          # Phase 1
├── ecs/                 # Phase 2
└── alb/                 # Phase 3 (NEW)
    ├── backend.tf
    ├── data.tf         # References networking + ECS
    ├── main.tf
    ├── outputs.tf
    ├── provider.tf
    └── variables.tf
```

## 🚀 Deployment Steps

### Step 1: Deploy ALB Infrastructure

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy ALB
terraform apply
```

### Step 2: Update ECS Services (IMPORTANT)

After ALB is deployed, you need to update the ECS services to register with the target groups.

**Option A: Manual Update (Recommended for first time)**

1. Open `/infra/aws/dev/ecs/main.tf`
2. Find the `aws_ecs_service.backend` resource (around line 390)
3. Add the following block inside the resource (after `network_configuration`):

```hcl
  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.backend_target_group_arn
    container_name   = var.backend_container_name
    container_port   = var.backend_container_port
  }
```

4. Find the `aws_ecs_service.frontend` resource (around line 418)
5. Add the following block inside the resource (after `network_configuration`):

```hcl
  load_balancer {
    target_group_arn = data.terraform_remote_state.alb.outputs.frontend_target_group_arn
    container_name   = var.frontend_container_name
    container_port   = var.frontend_container_port
  }
```

6. Add data source at the top of `ecs/main.tf` or `ecs/data.tf`:

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

7. Apply the changes:

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecs
terraform apply
```

**Option B: Use Pre-built Updates**

A reference implementation is available at `/infra/aws/dev/ecs/ecs-service-updates.tf`. You can use it as a guide.

### Step 3: Verify Deployment

```bash
# Get ALB DNS name
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
terraform output application_url

# Test frontend
curl http://<ALB_DNS_NAME>/

# Test backend API
curl http://<ALB_DNS_NAME>/api/health
```

---

## 🏗️ Architecture Overview

```
Internet
   |
   v
ALB (Public Subnets)
   |
   ├─> Frontend Target Group ──> ECS Frontend Tasks (Private Subnets)
   |                               Port 3000
   |
   └─> Backend Target Group  ──> ECS Backend Tasks (Private Subnets)
                                  Port 8000
```

## 🔧 Design Decisions

### **1. Load Balancer Type**
- **Application Load Balancer (ALB)**: Layer 7 routing, path-based routing
- Deployed in **public subnets** for internet access
- Internal = `false` (internet-facing)

### **2. Security Architecture**
- **ALB Security Group**: Allow HTTP (port 80) from 0.0.0.0/0
- **ECS Security Groups**: Updated to allow traffic from ALB SG only
- ECS tasks remain in private subnets (no public IPs)

### **3. Target Groups**
- **Type**: `ip` (Fargate requires IP target type)
- **Frontend TG**: Port 3000, health check on `/`
- **Backend TG**: Port 8000, health check on `/health`
- Deregistration delay: 30 seconds

### **4. Routing Rules**
- **Priority 100**: `/api/*` → Backend Target Group
- **Priority 200**: `/*` → Frontend Target Group (catch-all)
- Default action: Forward to Frontend

### **5. Health Checks**
- Interval: 30 seconds
- Timeout: 5 seconds
- Healthy threshold: 2
- Unhealthy threshold: 3
- Expected status: 200-299

### **6. State Management**
- ALB state: `dev/alb/terraform.tfstate`
- References networking and ECS states via `terraform_remote_state`

---

## 📊 What Gets Deployed

### Resources Created
- **ALB**: Public-facing load balancer
- **ALB Security Group**: HTTP access from internet
- **Frontend Target Group**: Routes to frontend containers
- **Backend Target Group**: Routes to backend API containers
- **HTTP Listener**: Port 80
- **Listener Rules**: Path-based routing
- **Security Group Rules**: Allow ALB → ECS communication

### Resources Updated (Manual Step)
- **ECS Backend Service**: Registers with backend target group
- **ECS Frontend Service**: Registers with frontend target group

---

## ⚠️ Important Notes

### Health Check Requirements

Your application containers MUST implement health check endpoints:

**Backend (FastAPI):**
```python
@app.get("/health")
def health_check():
    return {"status": "healthy"}
```

**Frontend (Next.js):**
- Default route `/` should return 200 OK
- Or implement custom health endpoint

### Expected Behavior

After deployment:
1. ALB DNS name will be available (e.g., `fullstack-app-dev-fullstack-alb-1234567890.ap-south-1.elb.amazonaws.com`)
2. Frontend accessible at: `http://<ALB_DNS>/`
3. Backend API accessible at: `http://<ALB_DNS>/api/*`
4. ECS tasks will automatically register with target groups

### Common Issues

**1. 503 Service Unavailable**
- ECS tasks not registered with target groups
- Health checks failing
- Check CloudWatch logs for container issues

**2. Tasks failing health checks**
- Ensure application is listening on correct port
- Verify health check endpoint returns 200
- Check security group rules

**3. ALB not routing correctly**
- Verify listener rules priority
- Check target group attachments
- Review ALB access logs

---

## 🔜 Next Steps (Phase 4)

1. **ECR Repositories**: Create container registries
2. **Docker Images**: Build and push real application images
3. **Environment Variables**: Configure backend API URL in frontend
4. **HTTPS/SSL**: Add ACM certificate and HTTPS listener
5. **Custom Domain**: Route53 for custom domain
6. **Monitoring**: CloudWatch dashboards and alarms

---

## 🧹 Cleanup

To destroy resources (reverse order):

```bash
# 1. Update ECS services to remove load balancer blocks
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecs
# Edit main.tf to remove load_balancer blocks
terraform apply

# 2. Destroy ALB
cd ../alb
terraform destroy

# 3. Destroy ECS (optional)
cd ../ecs
terraform destroy

# 4. Destroy Networking (optional)
cd ../networking
terraform destroy
```
