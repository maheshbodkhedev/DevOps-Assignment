# CI/CD Setup Guide - GitHub Actions

## 🎯 Overview

Automated CI/CD pipeline that builds Docker images, pushes to ECR, and deploys to ECS on every push to `main`.

---

## 🔑 Required GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these **3 secrets**:

### 1. AWS_ACCESS_KEY_ID
**Value:** Your AWS access key ID
**How to get:**
```bash
aws configure get aws_access_key_id --profile devops
```

### 2. AWS_SECRET_ACCESS_KEY
**Value:** Your AWS secret access key
**How to get:**
```bash
aws configure get aws_secret_access_key --profile devops
```

### 3. NEXT_PUBLIC_API_URL
**Value:** Your ALB URL
**Example:** `http://fullstack-app-dev-fullstack-alb-906471544.ap-south-1.elb.amazonaws.com`

**How to get:**
```bash
cd infra/aws/dev/alb
terraform output application_url
# Copy the URL (without quotes)
```

---

## 📋 Setup Checklist

- [ ] Copy GitHub repository URL
- [ ] Add all 3 secrets to GitHub repository
- [ ] Verify secrets are saved (no typos)
- [ ] Push code to main branch
- [ ] Watch GitHub Actions run

---

## 🚀 How It Works

### Trigger
```
git push origin main
  ↓
GitHub Actions workflow starts
```

### Pipeline Steps

**1. Checkout Code** (5s)
- Clones repository to runner

**2. Configure AWS Credentials** (2s)
- Authenticates with AWS using secrets
- Sets up AWS CLI

**3. Login to ECR** (3s)
- Gets ECR authentication token
- Configures Docker to push to ECR

**4. Build Backend Image** (60-90s)
- Builds Docker image from `./backend`
- Tags with commit SHA: `376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend:abc1234`
- Tags with latest: `376276261481.dkr.ecr.ap-south-1.amazonaws.com/fullstack-app-dev-backend:latest`

**5. Push Backend Image** (30s)
- Pushes both tags to ECR
- Makes image available for ECS

**6. Build Frontend Image** (90-120s)
- Builds Docker image from `./frontend`
- Passes `NEXT_PUBLIC_API_URL` as build argument
- Tags with commit SHA and latest

**7. Push Frontend Image** (30s)
- Pushes both tags to ECR

**8. Deploy Backend to ECS** (2s)
- Runs `aws ecs update-service --force-new-deployment`
- Triggers rolling deployment
- ECS pulls new image and replaces old tasks

**9. Deploy Frontend to ECS** (2s)
- Same as backend
- Triggers rolling deployment

**Total Time:** ~5-7 minutes (build) + 3-5 minutes (ECS deployment)

---

## 🔄 What Happens During Deployment

### ECS Rolling Deployment Process

1. **New Task Starts** (60s)
   - ECS pulls latest image from ECR
   - Starts new container with new code

2. **Health Checks** (60-90s)
   - ALB health checks run every 30s
   - Needs 2 consecutive passes to be "healthy"

3. **Traffic Switch** (instant)
   - ALB routes traffic to new task
   - Old task stops receiving new requests

4. **Graceful Shutdown** (30s)
   - Old task drains existing connections
   - Old task terminates

5. **Deployment Complete** ✅
   - New version is live
   - Zero downtime achieved

---

## 📊 Workflow Structure

```yaml
name: Deploy to AWS ECS

on:
  push:
    branches: [main]

env:
  # Centralized configuration
  AWS_REGION: ap-south-1
  ECR_REPOSITORIES: backend, frontend
  ECS_CLUSTER: fullstack-app-dev-fullstack-cluster

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      1. Checkout
      2. AWS Auth
      3. ECR Login
      4. Build + Push Backend
      5. Build + Push Frontend
      6. Deploy Backend (ECS)
      7. Deploy Frontend (ECS)
      8. Summary
```

---

## 🎨 Customization

### Change Trigger
```yaml
# Deploy on push to main or develop
on:
  push:
    branches:
      - main
      - develop

# Deploy on pull request merge
on:
  pull_request:
    types: [closed]
    branches: [main]
```

### Add Manual Trigger
```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:  # Manual trigger from GitHub UI
```

### Deploy Only Specific Service

**Deploy only backend:**
```bash
# Comment out frontend steps in workflow
# Or create separate workflow files:
# - .github/workflows/deploy-backend.yml
# - .github/workflows/deploy-frontend.yml
```

### Add Slack Notifications

```yaml
- name: Notify Slack
  if: success()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "✅ Deployment successful: ${{ github.sha }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## 🐛 Troubleshooting

### Build Fails

**Error:** `denied: Your authorization token has expired`
- **Fix:** Regenerate AWS access keys and update secrets

**Error:** `Cannot connect to Docker daemon`
- **Fix:** This shouldn't happen in GitHub Actions runners (they have Docker pre-installed)

**Error:** `COPY failed: no such file or directory`
- **Fix:** Check Dockerfile paths match repository structure

### Deployment Fails

**Error:** `Service not found`
- **Fix:** Check ECS service names in workflow env vars

**Error:** `Access Denied`
- **Fix:** AWS IAM user needs these policies:
  - `AmazonEC2ContainerRegistryPowerUser` (ECR)
  - `AmazonECS_FullAccess` (ECS)

### Health Checks Fail

**Issue:** New tasks fail health checks and roll back
- **Debug:** Check CloudWatch logs for errors
```bash
aws logs tail /ecs/fullstack-app-dev/backend-service --follow \
  --profile devops --region ap-south-1
```

---

## 📈 Monitoring Deployments

### GitHub Actions UI
```
Repository → Actions → Latest workflow run
```

### ECS Console
```
AWS Console → ECS → Clusters → fullstack-app-dev-fullstack-cluster
→ Services → backend-service → Deployments tab
```

### AWS CLI
```bash
# Watch deployment status
aws ecs describe-services \
  --cluster fullstack-app-dev-fullstack-cluster \
  --services backend-service frontend-service \
  --profile devops \
  --region ap-south-1 \
  --query 'services[*].[serviceName,deployments[0].rolloutState]' \
  --output table
```

### Check Running Image Version
```bash
# See which image version is running
aws ecs describe-tasks \
  --cluster fullstack-app-dev-fullstack-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster fullstack-app-dev-fullstack-cluster \
    --service-name backend-service \
    --profile devops \
    --region ap-south-1\
    --query 'taskArns[0]' \
    --output text) \
  --profile devops \
  --region ap-south-1 \
  --query 'tasks[0].containers[0].image' \
  --output text
```

---

## 🔒 Security Best Practices

### ✅ What We're Doing Right

1. **No secrets in code** - All sensitive data in GitHub Secrets
2. **Non-root containers** - Docker images run as unprivileged users
3. **Multi-stage builds** - Smaller images, less attack surface
4. **AWS credentials rotation** - Can rotate without code changes
5. **Least privilege** - IAM user only has necessary permissions

### 🔐 Additional Security (Optional)

**Use OIDC instead of access keys:**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::376276261481:role/github-actions-role
    aws-region: ap-south-1
```
(Requires AWS IAM OIDC setup)

**Scan images for vulnerabilities:**
```yaml
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: ${{ steps.login-ecr.outputs.registry }}/backend:${{ github.sha }}
```

---

## 🎯 Next Steps

1. ✅ Add secrets to GitHub
2. ✅ Push code to main
3. ✅ Watch workflow run
4. ✅ Verify deployment works
5. 🚀 Make a code change and see automated deployment!

---

## 💡 Pro Tips

### Faster Builds with Layer Caching

GitHub Actions caches Docker layers automatically between runs, making subsequent builds faster.

### Parallel Builds

Backend and frontend build sequentially. To parallelize:
```yaml
jobs:
  build-backend:
    # Backend build steps

  build-frontend:
    # Frontend build steps

  deploy:
    needs: [build-backend, build-frontend]
    # Deploy steps
```

### Environment-Specific Deployments

```yaml
on:
  push:
    branches:
      - main        # → production
      - develop     # → staging
      - feature/*   # → dev
```

---

## 📞 Support

If deployment fails:
1. Check GitHub Actions logs
2. Check AWS CloudWatch logs
3. Verify all secrets are correct
4. Ensure infrastructure is running (not destroyed)

**Remember:** ECS tasks take 3-5 minutes to become healthy after deployment starts. Be patient! ⏳
