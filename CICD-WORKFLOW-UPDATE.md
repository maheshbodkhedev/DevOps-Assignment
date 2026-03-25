# GitHub Actions Workflow Update - Task Definition Management

## 🎯 What Changed

### Before (Old Approach)
```yaml
# Just forced new deployment
aws ecs update-service --force-new-deployment
```

**Problem:**
- Doesn't update task definition
- ECS might use cached `:latest` tag
- No guarantee the new SHA-tagged image is used
- Can't verify which version is running

### After (New Approach)
```yaml
1. Download current task definition from ECS
2. Update image URI with SHA-tagged image
3. Register new task definition revision
4. Deploy new revision to ECS
5. Wait for service stability
6. Verify correct image is running
```

**Benefits:**
- ✅ Guarantees ECS uses exact Git SHA image
- ✅ Creates new task definition revision
- ✅ Waits for deployment to complete
- ✅ Verifies running image matches deployed SHA
- ✅ Enables easy rollback to specific versions

---

## 🔧 Key Improvements

### 1. Task Definition Download
```yaml
- name: Download backend task definition
  run: |
    aws ecs describe-task-definition \
      --task-definition backend-service \
      --query taskDefinition > backend-task-def.json
```

Gets the current task definition JSON from ECS.

### 2. Image Update with Official Action
```yaml
- name: Update backend task definition
  uses: aws-actions/amazon-ecs-render-task-definition@v1
  with:
    task-definition: backend-task-def.json
    container-name: backend
    image: 376276261481.dkr.ecr.ap-south-1.amazonaws.com/backend:abc1234
```

Uses official AWS action to update the image URI in task definition.

### 3. Deploy with Stability Check
```yaml
- name: Deploy backend to ECS
  uses: aws-actions/amazon-ecs-deploy-task-definition@v2
  with:
    task-definition: ${{ steps.backend-task-def.outputs.task-definition }}
    service: backend-service
    cluster: fullstack-app-dev-fullstack-cluster
    wait-for-service-stability: true  # Waits for deployment to complete
```

Deploys and waits for ECS service to be stable (all tasks healthy).

### 4. Verification Step
```yaml
- name: Verify deployment
  run: |
    # Get running task
    # Check image URI
    # Verify it matches deployed SHA
    # Exit with error if mismatch
```

Ensures the running tasks are using the correct image version.

---

## 📋 GitHub Secrets Required

### Same as Before (No Changes)

| Secret | Value | How to Get |
|--------|-------|------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | `aws configure get aws_access_key_id --profile devops` |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | `aws configure get aws_secret_access_key --profile devops` |
| `NEXT_PUBLIC_API_URL` | ALB URL | `cd infra/aws/dev/alb && terraform output -raw application_url` |

**No additional secrets needed!** ✅

---

## 📊 Workflow Steps Comparison

### Old Workflow (10 steps)
1. Checkout
2. AWS auth
3. ECR login
4. Build backend
5. Push backend
6. Build frontend
7. Push frontend
8. Force backend deployment ❌
9. Force frontend deployment ❌
10. Summary

### New Workflow (12 steps)
1. Checkout
2. AWS auth
3. ECR login
4. Build backend
5. Push backend
6. Build frontend
7. Push frontend
8. **Download backend task def** ✨
9. **Update backend task def with SHA image** ✨
10. **Deploy backend with stability wait** ✨
11. **Download frontend task def** ✨
12. **Update frontend task def with SHA image** ✨
13. **Deploy frontend with stability wait** ✨
14. **Verify deployment** ✨

---

## 🎯 What Happens Now

### Image Tagging
```
Build: abc1234567890 (Git commit SHA)
  ↓
Push to ECR:
  - 376276261481.dkr.ecr.ap-south-1.amazonaws.com/backend:abc1234567890
  - 376276261481.dkr.ecr.ap-south-1.amazonaws.com/backend:latest
  ↓
Task Definition Updated:
  - Uses: backend:abc1234567890 (SHA, not latest!)
  ↓
ECS Deployment:
  - Pulls exact SHA image
  - Guaranteed version consistency
```

### Deployment Flow
```
1. Build images → Push to ECR (5-7 min)
   ↓
2. Download current task defs (5 sec)
   ↓
3. Update with SHA-tagged images (5 sec)
   ↓
4. Register new task def revisions (5 sec)
   ↓
5. Deploy to ECS (10 sec)
   ↓
6. Wait for stability (3-5 min)
   ↓
7. Verify running images (10 sec)
   ↓
8. ✅ Complete! (~8-12 min total)
```

---

## 🔍 Verification Details

The verification step checks:

1. **Lists running tasks** for each service
2. **Gets container image** from each task
3. **Compares with deployed SHA**
4. **Exits with error** if mismatch

Example verification output:
```
========================================
🎉 DEPLOYMENT COMPLETED SUCCESSFULLY
========================================

📦 Deployed images:
  Backend:  376276261481.dkr.ecr.ap-south-1.amazonaws.com/backend:abc1234
  Frontend: 376276261481.dkr.ecr.ap-south-1.amazonaws.com/frontend:abc1234

🚀 ECS services stable:
  ✅ backend-service
  ✅ frontend-service

📋 Running task images:
  Backend:  376276261481.dkr.ecr.ap-south-1.amazonaws.com/backend:abc1234
  Frontend: 376276261481.dkr.ecr.ap-south-1.amazonaws.com/frontend:abc1234

✅ Backend running correct version (abc1234)
✅ Frontend running correct version (abc1234)

==========================================
🎊 All services deployed and verified!
==========================================
```

---

## 💡 Benefits of This Approach

### 1. Version Traceability
- Every deployment has a unique SHA
- Easy to identify which code is running
- Git history links to deployed versions

### 2. Reliable Rollback
```bash
# Roll back to specific version
git log --oneline  # Find commit SHA
# Trigger deployment of that commit
git revert HEAD  # Or cherry-pick specific commit
git push origin main
```

### 3. No Cache Issues
- Always pulls exact SHA image
- No `:latest` tag confusion
- Predictable deployments

### 4. Deployment Verification
- Workflow fails if wrong version deploys
- Catches deployment issues early
- Confidence in production state

### 5. Task Definition History
- New revision for each deployment
- Easy to compare changes
- Can manually roll back in ECS console

---

## 🧪 Testing the Updated Workflow

### 1. Commit and Push
```bash
# Make a small change
echo "# Testing updated workflow" >> README.md

git add README.md
git commit -m "test: verify task definition update workflow"
git push origin main
```

### 2. Watch GitHub Actions
```
Repository → Actions → Latest workflow run
```

Look for:
- ✅ Image builds complete
- ✅ Task definitions updated
- ✅ Services deployed and stable
- ✅ Verification passed

### 3. Check ECS Console
```
AWS Console → ECS → Task Definitions
```

You should see:
- New revision numbers (e.g., backend-service:5 → backend-service:6)
- Image URIs with commit SHAs

### 4. Verify Running Image
```bash
# Check what's actually running
aws ecs describe-tasks \
  --cluster fullstack-app-dev-fullstack-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster fullstack-app-dev-fullstack-cluster \
    --service-name backend-service \
    --query 'taskArns[0]' --output text \
    --profile devops --region ap-south-1) \
  --profile devops --region ap-south-1 \
  --query 'tasks[0].containers[0].image'
```

Should show: `376276261481.dkr.ecr.ap-south-1.amazonaws.com/backend:<git-sha>`

---

## 🚨 Troubleshooting

### Workflow fails at "Deploy to ECS"
**Cause:** Service not stable after 10 minutes (default timeout)
**Solution:** Check CloudWatch logs for container errors

### Workflow fails at "Verify deployment"
**Cause:** Running image doesn't match deployed SHA
**Solution:**
- Check task definition was updated correctly
- Verify images were pushed to ECR
- Check ECS service events for failures

### Task definition not found
**Cause:** Service name doesn't match task definition family
**Solution:** Ensure task definition family name matches service name

---

## 🔒 Security Notes

### Task Definition Downloads
- Task definitions are downloaded at runtime
- Contains sensitive info (IAM roles, environment vars)
- Stored temporarily in GitHub Actions runner
- Automatically cleaned up after workflow

### Image Verification
- Ensures deployed image matches expected version
- Prevents deployment of tampered images
- Catches misconfiguration early

---

## 📈 Advanced Usage

### Manual Rollback to Specific Version

1. Find the commit SHA you want to deploy:
```bash
git log --oneline
```

2. Cherry-pick that commit:
```bash
git cherry-pick <commit-sha>
git push origin main
```

3. Or manually update ECS to use previous task definition:
```bash
aws ecs update-service \
  --cluster fullstack-app-dev-fullstack-cluster \
  --service backend-service \
  --task-definition backend-service:5 \
  --profile devops --region ap-south-1
```

### View Task Definition History
```bash
# List all revisions
aws ecs list-task-definitions \
  --family-prefix backend-service \
  --profile devops --region ap-south-1

# Compare two revisions
aws ecs describe-task-definition \
  --task-definition backend-service:5 \
  --profile devops --region ap-south-1

aws ecs describe-task-definition \
  --task-definition backend-service:6 \
  --profile devops --region ap-south-1
```

---

## 🎓 Key Concepts

### Task Definition
- JSON blueprint for your container
- Specifies image, CPU, memory, ports, environment vars
- Immutable - each change creates new revision
- Versioned: `backend-service:1`, `backend-service:2`, etc.

### Task Definition Revision
- New version created on every deployment
- Old revisions remain available for rollback
- ECS service references specific revision

### Service Stability
- All desired tasks running and healthy
- Health checks passing
- No deployment failures
- Ready to receive traffic

---

## ✅ Summary

**Old approach:**
- Force new deployment
- Hope it uses new image
- No verification
- ❌ Unreliable

**New approach:**
- Update task definition with SHA image
- Register new revision
- Deploy and wait for stability
- Verify correct version running
- ✅ Reliable, traceable, verifiable

**No additional secrets needed - same 3 secrets as before!**

🎉 **Your CI/CD pipeline is now production-grade with proper version management!**
