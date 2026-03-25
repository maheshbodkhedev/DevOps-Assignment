# Phase 5: CI/CD Pipeline - Summary

## ✅ What We Created

### 1. GitHub Actions Workflow
**File:** `.github/workflows/deploy.yml`

**Trigger:** Push to `main` branch

**Pipeline:**
```
Push to main
   ↓
Build Backend Image (FastAPI)
   ↓
Push to ECR
   ↓
Build Frontend Image (Next.js)
   ↓
Push to ECR
   ↓
Deploy Backend to ECS (rolling)
   ↓
Deploy Frontend to ECS (rolling)
   ↓
✅ Live in 8-12 minutes
```

---

## 🔑 Required GitHub Secrets (3)

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS access key | `aws configure get aws_access_key_id --profile devops` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `aws configure get aws_secret_access_key --profile devops` |
| `NEXT_PUBLIC_API_URL` | ALB URL | `cd infra/aws/dev/alb && terraform output -raw application_url` |

**Add at:** GitHub Repo → Settings → Secrets and variables → Actions

---

## 📁 Files Created

```
.github/
└── workflows/
    └── deploy.yml           # Main CI/CD workflow

CICD-SETUP.md               # Comprehensive guide
GITHUB-SECRETS-SETUP.md     # Quick secrets setup
PHASE5-SUMMARY.md          # This file
```

---

## 🎯 How It Works

### Docker Build Process

**Backend (FastAPI):**
```dockerfile
FROM python:3.11-slim
→ Install dependencies in venv
→ Copy application code
→ Run as non-root user
→ Expose port 8000
→ CMD: uvicorn app.main:app
```

**Frontend (Next.js):**
```dockerfile
FROM node:18-alpine
→ Build with NEXT_PUBLIC_API_URL
→ Create optimized production build
→ Run as non-root user
→ Expose port 3000
→ CMD: node server.js
```

### Image Tagging Strategy

**Two tags per image:**
1. **Commit SHA:** `376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend:abc1234`
   - Tracks exact version
   - Enables rollback
   - Immutable

2. **Latest:** `376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend:latest`
   - Always points to newest
   - Used by ECS task definitions
   - Auto-updated

### ECS Deployment Strategy

**Type:** Rolling deployment

**Process:**
1. New task starts with new image
2. Health checks run (30s × 2 = 60s)
3. Once healthy, ALB switches traffic
4. Old task drains connections (30s)
5. Old task terminates
6. Deployment complete

**Benefits:**
- Zero downtime
- Automatic rollback on health check failure
- No manual intervention needed

---

## 🚀 Testing the Pipeline

### Step 1: Add Secrets to GitHub

Follow [GITHUB-SECRETS-SETUP.md](GITHUB-SECRETS-SETUP.md)

### Step 2: Make a Test Change

```bash
# Make a small change
echo "# Testing CI/CD" >> README.md

# Commit
git add README.md
git commit -m "test: trigger CI/CD pipeline"

# Push (this triggers workflow)
git push origin main
```

### Step 3: Watch Deployment

**GitHub Actions:**
```
Repository → Actions tab → Latest workflow run
```

**Timeline:**
- ⏱️ 0-2 min: Checkout and setup
- ⏱️ 2-4 min: Build backend image
- ⏱️ 4-6 min: Build frontend image
- ⏱️ 6-7 min: Push images to ECR
- ⏱️ 7 min: Trigger ECS deployments
- ⏱️ 7-12 min: ECS rolling deployment + health checks
- ✅ 12 min: New version live!

### Step 4: Verify Deployment

```bash
# Get ALB URL
cd infra/aws/dev/alb
ALB_URL=$(terraform output -raw application_url)

# Test backend
curl $ALB_URL/api/health

# Test frontend (in browser)
open $ALB_URL
```

---

## 📊 Monitoring

### GitHub Actions
```
Actions → Latest run → Each step shows:
- Build logs
- Docker output
- ECS deployment status
```

### AWS CloudWatch
```bash
# Backend logs
aws logs tail /ecs/fullstack-app-dev/backend-service --follow \
  --profile devops --region ap-south-1

# Frontend logs
aws logs tail /ecs/fullstack-app-dev/frontend-service --follow \
  --profile devops --region ap-south-1
```

### ECS Console
```
AWS Console → ECS → Clusters → fullstack-app-dev-fullstack-cluster
→ Services → backend-service → Deployments
```

---

## 🔧 Dockerfile Review

### ✅ Backend Dockerfile - Production Ready

**Strengths:**
- ✅ Multi-stage build (optimized)
- ✅ Virtual environment isolation
- ✅ Non-root user (security)
- ✅ Health check included
- ✅ No secrets embedded
- ✅ Minimal base image (python:3.11-slim)

**No changes needed!**

### ✅ Frontend Dockerfile - Production Ready

**Strengths:**
- ✅ Multi-stage build (builder + runner)
- ✅ Accepts build args (NEXT_PUBLIC_API_URL)
- ✅ Non-root user (nextjs:nodejs)
- ✅ Health check included
- ✅ Standalone build (optimized)
- ✅ Minimal base image (node:18-alpine)

**No changes needed!**

### Why These Dockerfiles Work Well for CI/CD

1. **Fast builds:** Multi-stage builds cache layers
2. **Small images:** Optimized sizes (~150MB backend, ~200MB frontend)
3. **Secure:** Non-root users, no secrets
4. **Portable:** Work locally and in CI/CD
5. **Health checks:** ECS can verify container health

---

## 🎨 Workflow Customization

### Deploy Only on Tag

```yaml
on:
  push:
    tags:
      - 'v*'  # Trigger on v1.0.0, v2.0.0, etc.
```

### Add Manual Approval

```yaml
jobs:
  build:
    # Build steps

  deploy:
    needs: build
    environment:
      name: production
      # Requires manual approval in GitHub
```

### Deploy to Multiple Environments

```yaml
on:
  push:
    branches:
      - main      # → production
      - staging   # → staging
      - develop   # → dev
```

### Add Slack Notifications

```yaml
- name: Notify Slack on success
  if: success()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H 'Content-Type: application/json' \
      -d '{"text":"✅ Deployment successful"}'

- name: Notify Slack on failure
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H 'Content-Type: application/json' \
      -d '{"text":"❌ Deployment failed"}'
```

---

## 🐛 Common Issues & Solutions

### Issue: "Cannot connect to Docker daemon"
**Cause:** Docker not available
**Solution:** This shouldn't happen in GitHub Actions (Docker pre-installed)

### Issue: "denied: Your authorization token has expired"
**Cause:** AWS credentials invalid
**Solution:** Regenerate and update GitHub secrets

### Issue: "Service not found"
**Cause:** Wrong ECS service name
**Solution:** Verify service names match in workflow env vars

### Issue: ECS deployment rolls back
**Cause:** Health checks failing
**Solution:** Check CloudWatch logs for application errors

### Issue: Frontend shows old version
**Cause:** Browser cache
**Solution:** Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)

---

## 🔒 Security Best Practices

### ✅ What We're Doing Right

1. **Secrets in GitHub** - Not in code
2. **Non-root containers** - Limited permissions
3. **Multi-stage builds** - Smaller attack surface
4. **No hardcoded credentials** - Externalized config
5. **Least privilege IAM** - Minimal AWS permissions
6. **HTTPS ready** - ALB can be upgraded to HTTPS easily

### 🚀 Production Enhancements (Optional)

1. **Add HTTPS:**
   - Get SSL certificate (ACM)
   - Update ALB listener to HTTPS
   - Redirect HTTP → HTTPS

2. **Add WAF:**
   - Protect against common attacks
   - Rate limiting
   - IP filtering

3. **Add monitoring:**
   - CloudWatch alarms
   - SNS notifications
   - Datadog/NewRelic integration

4. **Add vulnerability scanning:**
   - Trivy/Snyk in CI/CD
   - Scan images before push
   - Block on critical vulnerabilities

---

## 💰 Cost Breakdown with CI/CD

**Running costs (per day):**
- NAT Gateway: $1.08
- ALB: $0.60
- ECS Fargate: $0.40
- ECR storage: $0.003
- **Total: ~$2.08/day**

**CI/CD costs:**
- GitHub Actions: Free (2000 minutes/month for public repos)
- Each deployment: ~5-7 minutes
- ~60 deployments/month = 420 minutes (well within free tier)

**If you destroy resources overnight:**
- Keep only ECR: $0.10/month
- Recreate daily: 5 minutes
- CI/CD still works when infrastructure is up!

---

## 🎓 What You've Learned

### DevOps Skills

✅ **Infrastructure as Code** - Terraform for VPC, ECS, ALB
✅ **Containerization** - Docker multi-stage builds
✅ **Container Registry** - AWS ECR
✅ **Container Orchestration** - AWS ECS Fargate
✅ **Load Balancing** - AWS ALB with path-based routing
✅ **CI/CD** - GitHub Actions workflows
✅ **Zero-downtime deployments** - Rolling updates
✅ **Monitoring** - CloudWatch logs
✅ **Security** - Non-root containers, secrets management

### AWS Services

✅ VPC, Subnets, NAT Gateway, Internet Gateway
✅ ECS (Elastic Container Service) with Fargate
✅ ECR (Elastic Container Registry)
✅ ALB (Application Load Balancer)
✅ IAM (Identity and Access Management)
✅ CloudWatch (Logs and monitoring)
✅ S3 (Terraform state)
✅ DynamoDB (Terraform locking)

---

## 🚀 Next Steps (Optional)

1. **Add HTTPS**
   - Request SSL certificate in ACM
   - Update ALB listener
   - Update secrets with HTTPS URL

2. **Add Custom Domain**
   - Register domain (Route53)
   - Create alias record to ALB
   - Update frontend API URL

3. **Add Database**
   - RDS PostgreSQL in private subnet
   - Update backend to connect
   - Add connection string as secret

4. **Add Caching**
   - ElastiCache Redis
   - Cache API responses
   - Session storage

5. **Add Staging Environment**
   - Duplicate infrastructure
   - Deploy develop branch to staging
   - Test before production

6. **Add Monitoring**
   - CloudWatch dashboards
   - Alarms for errors/latency
   - SNS notifications

---

## 📝 Quick Commands Reference

```bash
# Get GitHub secrets values
aws configure get aws_access_key_id --profile devops
aws configure get aws_secret_access_key --profile devops
cd infra/aws/dev/alb && terraform output -raw application_url

# Watch GitHub Actions
# Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/actions

# Watch ECS deployment
aws ecs describe-services \
  --cluster fullstack-app-dev-fullstack-cluster \
  --services backend-service frontend-service \
  --profile devops --region ap-south-1 \
  --query 'services[*].[serviceName,deployments[0].rolloutState]' \
  --output table

# Check running image version
aws ecs describe-tasks \
  --cluster fullstack-app-dev-fullstack-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster fullstack-app-dev-fullstack-cluster \
    --service-name backend-service \
    --query 'taskArns[0]' --output text \
    --profile devops --region ap-south-1) \
  --profile devops --region ap-south-1 \
  --query 'tasks[0].containers[0].image'

# Tail logs
aws logs tail /ecs/fullstack-app-dev/backend-service --follow \
  --profile devops --region ap-south-1
```

---

## 🎉 Congratulations!

You've successfully built a **production-grade cloud-native application** with:

✅ Automated CI/CD pipeline
✅ Zero-downtime deployments
✅ Containerized microservices
✅ Infrastructure as Code
✅ Proper security (non-root, secrets)
✅ Monitoring and logging
✅ Scalable architecture

This is the same architecture used by companies like:
- Startups (cost-effective, scalable)
- Enterprise (secure, maintainable)
- SaaS platforms (multi-tenant ready)

**Your DevOps journey is complete!** 🚀

---

## 📚 Documentation Reference

- [CICD-SETUP.md](CICD-SETUP.md) - Detailed CI/CD guide
- [GITHUB-SECRETS-SETUP.md](GITHUB-SECRETS-SETUP.md) - Quick secrets setup
- [DESTROY-AND-RECREATE.md](DESTROY-AND-RECREATE.md) - Cost savings guide
- [PHASE4-DEPLOYMENT.md](PHASE4-DEPLOYMENT.md) - Phase 4 recap
- [QUICK-START.md](QUICK-START.md) - Quick start commands
