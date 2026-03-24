# Destroy and Recreate Infrastructure

## 🛑 Destroy Resources (Tonight)

Destroy in **reverse order** to avoid dependency issues:

### Step 1: Destroy ECS Services
```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/ecs

# Review what will be destroyed
terraform plan -destroy

# Destroy ECS cluster and services
terraform destroy -auto-approve
```

**Destroyed:**
- ECS services (backend, frontend)
- ECS cluster
- Task definitions
- CloudWatch log groups
- IAM roles

**Time:** ~2 minutes

---

### Step 2: Destroy ALB
```bash
cd ../alb

# Destroy Application Load Balancer
terraform destroy -auto-approve
```

**Destroyed:**
- Application Load Balancer
- Target groups
- ALB security group
- Listener rules

**Time:** ~3 minutes

---

### Step 3: Destroy ECR Repositories (Optional - Images will be deleted!)

**⚠️ WARNING:** This will delete your Docker images! You'll need to rebuild tomorrow.

**Option A: Keep ECR (Recommended - costs ~$0.10/month)**
```bash
# Skip this step - keep images for tomorrow
```

**Option B: Delete ECR (Save ~$0.10/month, rebuild tomorrow)**
```bash
cd ../ecr

# Delete images first
aws ecr batch-delete-image \
  --repository-name fullstack-app-dev-backend \
  --image-ids imageTag=latest \
  --profile devops \
  --region ap-south-1

aws ecr batch-delete-image \
  --repository-name fullstack-app-dev-frontend \
  --image-ids imageTag=latest \
  --profile devops \
  --region ap-south-1

# Destroy repositories
terraform destroy -auto-approve
```

**Time:** ~1 minute

---

### Step 4: Destroy Networking
```bash
cd ../networking

# Destroy VPC, subnets, NAT gateway
terraform destroy -auto-approve
```

**Destroyed:**
- NAT Gateway (saves $1.08/day)
- Elastic IP
- VPC
- Subnets
- Internet Gateway
- Route tables

**Time:** ~5 minutes

---

## 🎯 What's Preserved (Safe!)

✅ **Terraform state files** (in S3)
✅ **All code** (committed to Git)
✅ **ECR images** (if you kept them)
✅ **S3 state bucket** (not managed by Terraform)
✅ **DynamoDB lock table** (not managed by Terraform)

---

## 🚀 Recreate Tomorrow (Phase 5 - CI/CD)

When you're ready to continue:

### Quick Recreate (5-10 minutes)

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment

# Step 1: Recreate Networking (2 min)
cd infra/aws/dev/networking
terraform apply -auto-approve

# Step 2: Recreate ECR (if destroyed) (30 sec)
cd ../ecr
terraform apply -auto-approve

# Step 3: Rebuild & Push Images (if ECR was destroyed) (5-10 min)
cd ../../../..
./scripts/build-and-push.sh all

# Step 4: Recreate ALB (1 min)
cd infra/aws/dev/alb
terraform apply -auto-approve

# Step 5: Recreate ECS (3 min)
cd ../ecs
terraform apply -auto-approve

# Wait 3-5 minutes for health checks, then test:
cd ../alb
curl $(terraform output -raw application_url)/api/health
```

**Total time to recreate:** 10-15 minutes

---

## 💡 Smart Option: Destroy Only Expensive Resources

Keep ECR and destroy only the expensive stuff:

```bash
# Destroy ECS (saves Fargate costs)
cd infra/aws/dev/ecs
terraform destroy -auto-approve

# Destroy ALB (saves ALB costs)
cd ../alb
terraform destroy -auto-approve

# Destroy Networking (saves NAT Gateway costs)
cd ../networking
terraform destroy -auto-approve

# Keep ECR - images ready for tomorrow!
```

**Saves:** ~$2/day
**Tomorrow:** Just run terraform apply on networking → alb → ecs (5 min total, no rebuild needed!)

---

## 📊 Cost Comparison

| Option | Tonight | Tomorrow | Total Time Tomorrow |
|--------|---------|----------|---------------------|
| **Keep Everything** | $2 | $0 | 0 min (ready to use) |
| **Destroy All** | $0 | Rebuild images | 15 min |
| **Smart Destroy** | $0.003 | Use existing images | 5 min |

**Recommendation:** Use **Smart Destroy** (keep ECR, destroy ECS/ALB/VPC)

---

## 🔍 Verify Destruction

```bash
# Check no ECS clusters
aws ecs list-clusters --profile devops --region ap-south-1

# Check no load balancers
aws elbv2 describe-load-balancers --profile devops --region ap-south-1

# Check no NAT gateways
aws ec2 describe-nat-gateways --profile devops --region ap-south-1 \
  --filter "Name=state,Values=available"

# ECR should show repositories (if kept)
aws ecr describe-repositories --profile devops --region ap-south-1
```

Expected after smart destroy:
```
ECS Clusters: []
Load Balancers: []
NAT Gateways: []
ECR Repos: [backend, frontend]  ← If kept
```

---

## ⚠️ Important Notes

1. **State files are safe** - stored in S3, not affected by destroy
2. **Code is safe** - committed to Git
3. **Destroy in reverse order** - prevents dependency errors
4. **NAT Gateway is most expensive** - destroy this to save most money
5. **ECR storage is cheap** - keep images to save rebuild time tomorrow

---

## 🎓 Tomorrow's Plan (Phase 5)

When you recreate infrastructure tomorrow, you'll add:
1. **GitHub Actions CI/CD pipeline**
2. **Automated Docker builds**
3. **Automated ECS deployments**
4. **Secrets management**

With infrastructure already defined in code, CI/CD will be straightforward! 🚀
