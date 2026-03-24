# Phase 4: Deploy Real Applications

## 📋 Overview

Deploy FastAPI backend and Next.js frontend to replace nginx placeholder images.

**What we're fixing:**
- ❌ Nginx on port 80 → ✅ Backend on port 8000
- ❌ Nginx on port 80 → ✅ Frontend on port 3000
- ❌ 502 Bad Gateway → ✅ Applications working

---

## 🚀 Step-by-Step Deployment

### Step 1: Create ECR Repositories

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecr

# Initialize Terraform
terraform init

# Review plan
terraform plan

# Create ECR repositories
terraform apply

# Save repository URLs
terraform output
```

**Expected Output:**
```
backend_repository_url  = "376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend"
frontend_repository_url = "376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-frontend"
```

---

### Step 2: Build and Push Docker Images

**Option A: Using the Automated Script (Recommended)**

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment

# Make script executable
chmod +x scripts/build-and-push.sh

# Build and push both images
./scripts/build-and-push.sh all

# Or build individually
./scripts/build-and-push.sh backend
./scripts/build-and-push.sh frontend
```

**Option B: Manual Commands**

```bash
# Get ECR URLs
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecr
BACKEND_REPO=$(terraform output -raw backend_repository_url)
FRONTEND_REPO=$(terraform output -raw frontend_repository_url)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile devops)

# Login to ECR
aws ecr get-login-password \
  --region ap-south-1 \
  --profile devops | \
docker login \
  --username AWS \
  --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

# Build and push backend
cd /home/mahesh/code/devops-project/DevOps-Assignment/backend
docker build --platform linux/amd64 -t $BACKEND_REPO:latest .
docker push $BACKEND_REPO:latest

# Build and push frontend
cd /home/mahesh/code/devops-project/DevOps-Assignment/frontend
docker build --platform linux/amd64 -t $FRONTEND_REPO:latest .
docker push $FRONTEND_REPO:latest
```

---

### Step 3: Update ECS Task Definitions

Update the ECS variables to use ECR images instead of nginx.

**Edit:** `infra/aws/dev/ecs/variables.tf`

Find and replace:

```hcl
# BEFORE (nginx placeholder)
variable "backend_image" {
  description = "Docker image for backend (placeholder)"
  type        = string
  default     = "nginx:latest"
}

variable "frontend_image" {
  description = "Docker image for frontend (placeholder)"
  type        = string
  default     = "nginx:latest"
}
```

**Replace with:**

```hcl
# AFTER (ECR images)
variable "backend_image" {
  description = "Docker image for backend from ECR"
  type        = string
  default     = "376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend:latest"
}

variable "frontend_image" {
  description = "Docker image for frontend from ECR"
  type        = string
  default     = "376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-frontend:latest"
}
```

**⚠️ Replace `376276261481` with your AWS account ID!**

---

### Step 4: Add ECR Data Source (Optional but Recommended)

**Edit:** `infra/aws/dev/ecs/data.tf`

Add ECR data source:

```hcl
# Reference ECR infrastructure
data "terraform_remote_state" "ecr" {
  backend = "s3"

  config = {
    bucket  = "mahesh-tf-state-2026-devops"
    key     = "dev/ecr/terraform.tfstate"
    region  = "ap-south-1"
    profile = "devops"
  }
}
```

---

### Step 5: Deploy Updated Task Definitions

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecs

# Review changes (should show task definitions updating)
terraform plan

# Apply changes
terraform apply
```

**Expected:**
```
Plan: 0 to add, 2 to change, 0 to destroy.

Changes:
  ~ aws_ecs_task_definition.backend  # image updated
  ~ aws_ecs_task_definition.frontend # image updated
```

---

### Step 6: Monitor Deployment

ECS will automatically trigger a rolling deployment:

```bash
# Watch service status
watch -n 5 'aws ecs describe-services \
  --cluster fullstack-app-dev-fullstack-cluster \
  --services backend-service frontend-service \
  --profile devops \
  --region ap-south-1 \
  --query "services[*].[serviceName,runningCount,desiredCount,deployments[0].rolloutState]" \
  --output table'
```

**Expected states:**
1. `IN_PROGRESS` (0-2 minutes)
2. `COMPLETED` (after health checks pass)

---

### Step 7: Verify Health Checks

```bash
# Check target health
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb

# Backend health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw backend_target_group_arn) \
  --profile devops \
  --region ap-south-1 \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
  --output table

# Frontend health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw frontend_target_group_arn) \
  --profile devops \
  --region ap-south-1 \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Description]' \
  --output table
```

**Expected:** `State: healthy`

---

### Step 8: Test Application

```bash
# Get ALB URL
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
ALB_URL=$(terraform output -raw application_url)

echo "Application URL: $ALB_URL"

# Test backend health
curl $ALB_URL/api/health

# Expected: {"status":"healthy","message":"Backend is running successfully"}

# Test backend API
curl $ALB_URL/api/message

# Expected: {"message":"You've successfully integrated the backend!"}

# Test frontend (in browser)
# Open: http://fullstack-app-dev-fullstack-alb-XXXXXXX.ap-south-1.elb.amazonaws.com/
```

---

## 📊 What Was Created

### Dockerfiles

✅ **backend/Dockerfile**
- Multi-stage build (optimized)
- Python 3.11 slim base
- Non-root user (security)
- Health check included
- Port 8000 exposed

✅ **frontend/Dockerfile**
- Multi-stage build (optimized)
- Node 18 Alpine base
- Standalone Next.js build
- Non-root user (security)
- Port 3000 exposed

### ECR Repositories

✅ **fullstack-app-dev-backend**
- Image scanning enabled
- AES256 encryption
- Lifecycle policy (keep last 10 images)

✅ **fullstack-app-dev-frontend**
- Image scanning enabled
- AES256 encryption
- Lifecycle policy (keep last 10 images)

---

## 🔧 Optimizations Applied

### Backend Dockerfile
1. ✅ Multi-stage build (smaller image)
2. ✅ Virtual environment in builder stage
3. ✅ No cache files (`--no-cache-dir`)
4. ✅ Non-root user (appuser)
5. ✅ Health check endpoint
6. ✅ Environment variables set

### Frontend Dockerfile
1. ✅ Multi-stage build
2. ✅ Next.js standalone output (smaller)
3. ✅ Production dependencies only
4. ✅ Non-root user (nextjs)
5. ✅ Health check endpoint
6. ✅ Static files optimized

### Next.js Configuration
1. ✅ Standalone output enabled
2. ✅ React strict mode
3. ✅ Environment variables for API URL

---

## ⚠️ Troubleshooting

### Build Fails

**Backend:** Check Python version and dependencies
```bash
cd backend
python --version  # Should be 3.11+
pip install -r requirements.txt
```

**Frontend:** Check Node version and dependencies
```bash
cd frontend
node --version  # Should be 18+
npm install
npm run build
```

### Push to ECR Fails

**Authentication error:**
```bash
# Re-login to ECR
aws ecr get-login-password \
  --region ap-south-1 \
  --profile devops | \
docker login \
  --username AWS \
  --password-stdin \
  $(aws sts get-caller-identity --query Account --output text --profile devops).dkr.ecr.ap-south-1.amazonaws.com
```

### Health Checks Still Failing

**Check container logs:**
```bash
# Backend logs
aws logs tail /ecs/fullstack-app-dev/backend-service --follow \
  --profile devops --region ap-south-1

# Frontend logs
aws logs tail /ecs/fullstack-app-dev/frontend-service --follow \
  --profile devops --region ap-south-1
```

**Common issues:**
1. Port mismatch → Verify Dockerfile EXPOSE matches task definition
2. Health endpoint missing → Check `/api/health` exists
3. Container crash → Check application logs

### Deployment Not Starting

**Force new deployment:**
```bash
aws ecs update-service \
  --cluster fullstack-app-dev-fullstack-cluster \
  --service backend-service \
  --force-new-deployment \
  --profile devops \
  --region ap-south-1

aws ecs update-service \
  --cluster fullstack-app-dev-fullstack-cluster \
  --service frontend-service \
  --force-new-deployment \
  --profile devops \
  --region ap-south-1
```

---

## 🎯 Success Criteria

✅ **All green when:**
1. Docker images built successfully
2. Images pushed to ECR
3. ECS task definitions updated
4. New tasks running (runningCount = desiredCount)
5. Target health shows "healthy"
6. `curl $ALB_URL/api/health` returns 200 OK
7. Frontend loads in browser

---

## 📚 Files Created

```
DevOps-Assignment/
├── backend/
│   └── Dockerfile                    # ✅ Created
├── frontend/
│   ├── Dockerfile                    # ✅ Created
│   └── next.config.js                # ✅ Created
├── infra/aws/dev/ecr/
│   ├── backend.tf                    # ✅ Created
│   ├── provider.tf                   # ✅ Created
│   ├── variables.tf                  # ✅ Created
│   ├── main.tf                       # ✅ Created
│   └── outputs.tf                    # ✅ Created
├── scripts/
│   └── build-and-push.sh             # ✅ Created
└── PHASE4-DEPLOYMENT.md              # ✅ This file
```

---

## 🔜 Next Steps (Optional Enhancements)

1. **HTTPS/SSL**: Add ACM certificate and HTTPS listener
2. **Custom Domain**: Route53 DNS configuration
3. **CI/CD Pipeline**: GitHub Actions for automated deployments
4. **Monitoring**: CloudWatch dashboards and alarms
5. **Autoscaling**: Configure ECS service autoscaling
6. **Database**: Add RDS PostgreSQL
7. **Caching**: Add ElastiCache Redis
8. **Secrets**: AWS Secrets Manager for sensitive data

---

## 💡 Pro Tips

1. **Tag images with git commit SHA** for traceability
2. **Use ECR image scanning** to detect vulnerabilities
3. **Enable CloudWatch Container Insights** for metrics
4. **Set up ALB access logs** for debugging
5. **Use AWS X-Ray** for distributed tracing

---

Ready to deploy? Start with **Step 1: Create ECR Repositories**! 🚀
