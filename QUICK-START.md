# Quick Start Guide - Phase 4 Deployment

## 🚀 Deploy in 5 Commands

```bash
# 1. Create ECR repositories
cd infra/aws/dev/ecr && terraform init && terraform apply -auto-approve

# 2. Build and push Docker images
cd ../../../.. && ./scripts/build-and-push.sh all

# 3. Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --profile devops)
echo "Your AWS Account ID: $AWS_ACCOUNT_ID"

# 4. Update ECS task definition images
# Edit infra/aws/dev/ecs/variables.tf
# Replace '376276261481' with your AWS Account ID in backend_image and frontend_image defaults

# 5. Deploy updated ECS tasks
cd infra/aws/dev/ecs && terraform apply -auto-approve
```

## ⏱️ Timeline

- Step 1 (ECR): ~30 seconds
- Step 2 (Build/Push): ~5-10 minutes
- Step 3 (Account ID): ~1 second
- Step 4 (Edit file): ~1 minute
- Step 5 (Deploy): ~3-5 minutes

**Total: ~10-15 minutes**

## ✅ Verification

```bash
# Get ALB URL and test
cd infra/aws/dev/alb
curl $(terraform output -raw application_url)/api/health

# Expected: {"status":"healthy","message":"Backend is running successfully"}
```

## 📖 Full Documentation

See [PHASE4-DEPLOYMENT.md](PHASE4-DEPLOYMENT.md) for detailed steps and troubleshooting.
