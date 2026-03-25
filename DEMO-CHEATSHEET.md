# Demo Cheat Sheet - Quick Reference

## 🔗 Application URL
```
http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com
```

---

## ⚡ Quick Commands

### Test Application
```bash
# Backend health
curl http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com/api/health

# Backend message
curl http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com/api/message
```

### Show Infrastructure
```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev
tree -L 2
```

### Live Deployment Demo
```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment

# Add demo endpoint
cat >> backend/app/main.py << 'EOF'

@app.get("/api/demo")
async def demo():
    return {"message": "Deployed automatically via CI/CD!", "version": "demo-v1"}
EOF

# Commit and push
git add backend/app/main.py
git commit -m "feat: add demo endpoint for presentation"
git push origin main
```

### Monitor Deployment
```bash
# Watch ECS
aws ecs describe-services \
  --cluster fullstack-app-dev-fullstack-cluster \
  --services backend-service frontend-service \
  --profile devops --region ap-south-1 \
  --query 'services[*].[serviceName,deployments[0].rolloutState]' \
  --output table

# Check deployed version
aws ecs describe-tasks \
  --cluster fullstack-app-dev-fullstack-cluster \
  --tasks $(aws ecs list-tasks --cluster fullstack-app-dev-fullstack-cluster --service-name backend-service --query 'taskArns[0]' --output text --profile devops --region ap-south-1) \
  --profile devops --region ap-south-1 \
  --query 'tasks[0].containers[0].image'

# Test new endpoint
curl http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com/api/demo
```

---

## 💬 Key Talking Points

### Architecture (30 seconds)
- VPC with public/private subnets (security)
- ALB in public, ECS in private (best practice)
- Multi-AZ deployment (high availability)
- Path-based routing (/, /api/*)

### Infrastructure as Code (1 min)
- Terraform manages all AWS resources
- Version controlled in Git
- Reproducible environments
- Remote state in S3

### CI/CD Pipeline (2 min)
**Trigger:** Push to main
**Process:**
1. Build Docker images
2. Tag with Git SHA (not latest!)
3. Push to ECR
4. Update task definitions
5. Deploy to ECS
6. Wait for stability
7. Verify version

**Key benefit:** Zero downtime, full traceability

### Security (30 seconds)
- Non-root containers
- Private subnets
- IAM least privilege
- Secrets in GitHub Secrets
- CloudWatch logging

---

## ⏱️ Time Allocation

| Part | Time | Must Show? |
|------|------|------------|
| Intro | 1 min | ✅ |
| Architecture | 2 min | ✅ |
| Live App | 2 min | ✅ |
| IaC | 3 min | ⚠️ |
| **CI/CD** | **4 min** | **✅✅✅** |
| Verify | 2 min | ✅ |
| Q&A | 1 min | ✅ |

---

## 🎯 Demo Flow

1. **[0-1 min]** Intro + Architecture diagram
2. **[1-3 min]** Show live app (browser + curl)
3. **[3-6 min]** Quick IaC tour (tree, show files)
4. **[6-10 min]** 🌟 **CI/CD DEMO** (change code, push, watch)
5. **[10-12 min]** Monitor deployment, explain steps
6. **[12-13 min]** Verify deployed, test new endpoint
7. **[13-14 min]** Summarize benefits
8. **[14-15 min]** Q&A

---

## 🚨 If Things Go Wrong

**CI/CD too slow?**
→ Show previous successful run in GitHub Actions
→ Explain process verbally

**Network issues?**
→ Have screenshots ready
→ Focus on code and architecture

**Forgot command?**
→ This cheat sheet!

---

## 🎤 Opening Line

"I've built a production-grade application that deploys itself automatically. Let me show you - I'll push code to GitHub and you'll see it go live in production."

## 🎤 Closing Line

"This is the same architecture used by tech startups and enterprises. Fully automated, zero downtime, production-ready. Questions?"

---

## ✅ Pre-Demo Checklist

- [ ] Infrastructure running (all services healthy)
- [ ] Browser tab: Application URL
- [ ] Browser tab: GitHub Actions
- [ ] Terminal ready at project root
- [ ] Commands tested once
- [ ] Architecture diagram ready
- [ ] Calm and confident!

---

## 🔢 Key Numbers to Remember

- **15-18 min** - Full CI/CD pipeline time
- **2 AZs** - High availability
- **3 phases** - Networking, ECS, ALB, ECR, CI/CD
- **~$2/day** - Running cost
- **0 downtime** - Rolling deployments
- **100% automated** - No manual steps

---

## GitHub Actions URL
```
https://github.com/maheshbodkhedev/DevOps-Assignment/actions
```

---

**🎉 You've got this! Focus on the CI/CD automation - that's your killer feature!**
