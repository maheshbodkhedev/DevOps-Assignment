# 15-Minute DevOps Project Demo Guide

## 🎯 Demo Overview

**Project:** Full-stack application with automated CI/CD on AWS
**Duration:** 15 minutes
**Audience:** Technical (understands cloud, DevOps concepts)

---

## 📋 Demo Outline (Time-boxed)

1. **Introduction** (1 min) - Project overview
2. **Architecture** (2 min) - Infrastructure walkthrough
3. **Live Application** (2 min) - Show running app
4. **Infrastructure as Code** (3 min) - Terraform demo
5. **CI/CD Pipeline** (4 min) - Live deployment demo
6. **Verification** (2 min) - Show deployed changes
7. **Q&A** (1 min) - Closing

---

## 🎬 PART 1: Introduction (1 minute)

### What to Say:
"I've built a production-grade, cloud-native full-stack application with automated CI/CD on AWS. Let me show you what makes this special:

- **Frontend:** Next.js (React)
- **Backend:** FastAPI (Python)
- **Infrastructure:** AWS ECS Fargate with Terraform
- **CI/CD:** GitHub Actions with zero-downtime deployments
- **Architecture:** Production-ready with proper networking, load balancing, and security"

### Key Points to Highlight:
- Fully automated deployment pipeline
- Infrastructure as Code
- Zero-downtime deployments
- Git SHA versioning

---

## 🏗️ PART 2: Architecture (2 minutes)

### Show: Architecture Diagram (Draw or Display)

```
┌─────────────────────────────────────────────────────────┐
│                       INTERNET                          │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────────┐
│              Application Load Balancer                  │
│     (Path-based routing: /api/* → Backend)             │
└─────────────────┬───────────────────────────────────────┘
                  │
         ┌────────┴────────┐
         ↓                 ↓
    [Frontend]        [Backend]
    ECS Fargate       ECS Fargate
    (Private)         (Private)
         ↓                 ↓
    [ECR Images]      [ECR Images]
         ↓                 ↓
┌─────────────────────────────────────────────────────────┐
│              VPC (10.0.0.0/16)                          │
│  ┌──────────────────┐    ┌──────────────────┐          │
│  │ Public Subnets   │    │ Private Subnets  │          │
│  │ (ALB, NAT)       │    │ (ECS Tasks)      │          │
│  └──────────────────┘    └──────────────────┘          │
└─────────────────────────────────────────────────────────┘
```

### What to Say:
"The architecture follows AWS best practices:

1. **VPC with public and private subnets** across 2 availability zones for high availability
2. **ALB in public subnets** handles incoming traffic with path-based routing
3. **ECS Fargate tasks in private subnets** for security - no direct internet access
4. **NAT Gateway** allows private subnets to reach internet for updates
5. **Docker images stored in ECR** for version control

This design ensures:
- Security (containers isolated in private network)
- High availability (multi-AZ deployment)
- Scalability (ECS Fargate auto-scaling ready)
- Cost efficiency (single NAT Gateway)"

---

## 🌐 PART 3: Live Application (2 minutes)

### Demo Commands:

```bash
# Show ALB URL
cd /home/mahesh/code/devops-project/DevOps-Assignment/infra/aws/dev/alb
terraform output application_url

# Test backend API
curl http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com/api/health
curl http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com/api/message
```

### What to Show:
1. **Open browser** → Show frontend (clean UI)
2. **Test API** → Show backend responses (JSON)
3. **Highlight path-based routing:**
   - `/` → Frontend (Next.js)
   - `/api/*` → Backend (FastAPI)

### What to Say:
"Here's the live application running on AWS:
- Frontend built with Next.js serving the UI
- Backend API built with FastAPI handling business logic
- ALB intelligently routes traffic based on URL path
- Both services running in private subnets, accessible only through the load balancer"

---

## 📦 PART 4: Infrastructure as Code (3 minutes)

### Show: Project Structure

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment
tree infra/aws/dev -L 2
```

### Demo Commands:

```bash
# Show networking infrastructure
cd infra/aws/dev/networking
ls -la
cat main.tf | head -50

# Show ECS configuration
cd ../ecs
cat variables.tf | grep "variable" | head -20

# Show Terraform state
terraform show | head -30
```

### What to Say:
"Infrastructure is fully defined as code using Terraform:

**Phase 1 - Networking:**
- VPC with 2 public and 2 private subnets
- Internet Gateway and NAT Gateway
- Route tables for traffic routing

**Phase 2 - ECS:**
- Fargate cluster with task definitions
- IAM roles with least privilege
- CloudWatch log groups for monitoring

**Phase 3 - Load Balancer:**
- Application Load Balancer in public subnets
- Target groups with health checks
- Listener rules for path-based routing

**Phase 4 - Container Registry:**
- ECR repositories for Docker images
- Lifecycle policies for old image cleanup
- Image scanning for security vulnerabilities

**Benefits:**
- Version controlled (Git)
- Reproducible environments
- Easy to destroy and recreate
- Remote state in S3 with DynamoDB locking"

---

## 🚀 PART 5: CI/CD Pipeline (4 minutes) **[MAIN HIGHLIGHT]**

### Show: GitHub Actions Workflow

```bash
cd /home/mahesh/code/devops-project/DevOps-Assignment
cat .github/workflows/deploy.yml | head -80
```

### What to Say:
"The CI/CD pipeline is the crown jewel of this project. Let me show you how a single git push automatically deploys to production."

### Live Demo - Make a Code Change:

```bash
# Show current backend code
cat backend/app/main.py

# Make a visible change
cat >> backend/app/main.py << 'EOF'

@app.get("/api/demo")
async def demo():
    return {"message": "This was deployed automatically via CI/CD!", "timestamp": "2026-03-25"}
EOF

# Show the change
tail -5 backend/app/main.py

# Commit and push
git add backend/app/main.py
git commit -m "feat: add demo endpoint for presentation"
git push origin main
```

### What to Say During Push:
"Watch what happens now:

**Trigger:** Git push to main branch

**GitHub Actions automatically:**
1. ✅ Builds backend Docker image
2. ✅ Builds frontend Docker image
3. ✅ Tags with Git commit SHA (not just 'latest')
4. ✅ Pushes to AWS ECR
5. ✅ Downloads current ECS task definitions
6. ✅ Updates task definitions with NEW SHA-tagged images
7. ✅ Registers new task definition revisions
8. ✅ Deploys to ECS Fargate
9. ✅ Waits for service stability (health checks)
10. ✅ Verifies correct version is running

Total time: 15-18 minutes"

### Show GitHub Actions (while it runs):

**Open:** GitHub repository → Actions tab

**Highlight:**
- Real-time build logs
- Each step clearly defined
- Success/failure indicators
- Deployment timeline

### Key Points to Emphasize:

**Why Git SHA Tagging Matters:**
```
Old approach: Uses :latest tag
Problem: Cache issues, can't track versions

New approach: Uses Git commit SHA
Benefits:
✅ Every deployment traceable to specific code
✅ Easy rollback (just deploy previous SHA)
✅ No cache confusion
✅ Audit trail for compliance
```

---

## ✅ PART 6: Verification (2 minutes)

### While CI/CD is Running, Show:

```bash
# Watch ECS deployment
aws ecs describe-services \
  --cluster fullstack-app-dev-fullstack-cluster \
  --services backend-service frontend-service \
  --profile devops --region ap-south-1 \
  --query 'services[*].[serviceName,runningCount,desiredCount,deployments[0].rolloutState]' \
  --output table
```

### What to Say:
"ECS is performing a rolling deployment:
- New tasks start with new image
- Health checks verify new tasks are healthy
- Once healthy, ALB switches traffic
- Old tasks drain connections gracefully
- **Zero downtime** throughout the process"

### After Deployment Completes:

```bash
# Verify deployed version
aws ecs describe-tasks \
  --cluster fullstack-app-dev-fullstack-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster fullstack-app-dev-fullstack-cluster \
    --service-name backend-service \
    --query 'taskArns[0]' --output text \
    --profile devops --region ap-south-1) \
  --profile devops --region ap-south-1 \
  --query 'tasks[0].containers[0].image'

# Test new endpoint
curl http://fullstack-app-dev-fullstack-alb-933344674.ap-south-1.elb.amazonaws.com/api/demo
```

### Expected Output:
```json
{
  "message": "This was deployed automatically via CI/CD!",
  "timestamp": "2026-03-25"
}
```

### What to Say:
"And there it is! The code I just pushed 15 minutes ago is now live in production:
- Completely automated
- Zero manual intervention
- Zero downtime
- Fully traceable to Git commit
- Ready for instant rollback if needed"

---

## 🔒 Security & Best Practices Highlight (30 seconds)

### Quick Mention:
"Security is built-in, not bolted on:

**Container Security:**
- ✅ Multi-stage Docker builds (smaller attack surface)
- ✅ Non-root users in containers
- ✅ No secrets in images

**Network Security:**
- ✅ Private subnets for applications
- ✅ No direct internet access
- ✅ ALB handles all public traffic

**Access Control:**
- ✅ IAM roles with least privilege
- ✅ GitHub Secrets for credentials
- ✅ Terraform state encrypted in S3

**Compliance:**
- ✅ Full audit trail (Git history)
- ✅ Version traceability (SHA tags)
- ✅ CloudWatch logging"

---

## 💰 Cost Optimization (30 seconds)

### What to Say:
"This is production-ready but also cost-effective:

**Daily Cost:** ~$2/day when running
- NAT Gateway: $1.08
- ALB: $0.60
- ECS Fargate: $0.40

**Cost Saving Strategy:**
- Infrastructure defined in code
- Can destroy at night, recreate in morning
- 5 minutes to recreate (no rebuilds needed)
- ECR images preserved (~$0.10/month)

**For production:**
- Runs 24/7
- Auto-scaling configured
- Multi-region deployment ready
- Total cost predictable and manageable"

---

## 🎓 Key Takeaways (30 seconds)

### What to Say:
"This project demonstrates enterprise-level DevOps:

**Technical Skills:**
- Infrastructure as Code (Terraform)
- Container orchestration (ECS Fargate)
- CI/CD automation (GitHub Actions)
- Cloud architecture (AWS)
- Networking (VPC, subnets, routing)

**DevOps Principles:**
- Automation (no manual deployments)
- Version control (everything in Git)
- Monitoring (CloudWatch logs)
- Security (defense in depth)
- Scalability (ready to handle growth)

**Business Value:**
- Faster time to market (automated deployments)
- Reduced errors (no manual steps)
- Easy rollback (version control)
- High availability (multi-AZ)
- Cost predictable (Infrastructure as Code)"

---

## ❓ Q&A (1 minute)

### Anticipated Questions & Answers:

**Q: Why ECS instead of Kubernetes?**
A: "ECS is simpler, AWS-managed, and sufficient for most use cases. Kubernetes adds complexity that wasn't needed here. ECS Fargate is serverless - no EC2 instances to manage."

**Q: How do you handle rollbacks?**
A: "Two ways: 1) Revert Git commit and push (automatic rollback), 2) Manually deploy previous task definition revision in ECS console. Git SHA tagging makes this trivial."

**Q: What about database?**
A: "Next step would be RDS PostgreSQL in private subnet. Connection string stored as secret, injected as environment variable in task definition."

**Q: How does scaling work?**
A: "ECS Service Auto Scaling based on CPU/memory metrics. ALB automatically distributes traffic. All configuration ready - just enable auto-scaling policies."

**Q: What about monitoring?**
A: "CloudWatch logs for all containers, can add CloudWatch alarms for errors/latency, integrate with Datadog or NewRelic for advanced monitoring."

**Q: Why Git SHA instead of semantic versioning?**
A: "Git SHA provides exact traceability to code. For releases, I can tag specific commits (v1.0.0) and deploy those. SHA ensures deployed version exactly matches tested code."

---

## 📊 Demo Checklist (Before Presenting)

### Pre-Demo Setup (5 min before):
- [ ] Infrastructure running (networking, ALB, ECS)
- [ ] Application accessible in browser
- [ ] Terminal windows prepared:
  - Window 1: Project root
  - Window 2: Backend monitoring
  - Window 3: AWS CLI commands
- [ ] Browser tabs open:
  - GitHub repository (Actions tab)
  - Application URL
  - AWS ECS console (optional backup)
- [ ] Test API endpoints working
- [ ] Prepare code change ahead of time (can type or paste)

### Have Ready:
- ALB URL copied
- Git commands ready to paste
- AWS CLI commands ready to run
- Architecture diagram (hand-drawn or digital)

### Backup Plan (if internet slow):
- Pre-recorded video of deployment
- Screenshots of successful pipeline
- Static presentation with key points

---

## 🎯 Time Management

| Segment | Time | Critical? |
|---------|------|-----------|
| Introduction | 1 min | Yes |
| Architecture | 2 min | Yes |
| Live App | 2 min | Yes |
| Infrastructure as Code | 3 min | Medium |
| **CI/CD Demo** | **4 min** | **YES** |
| Verification | 2 min | Yes |
| Q&A | 1 min | Flexible |

**If running short on time, skip/shorten:**
- Terraform deep dive (show less code)
- Cost optimization section
- Security details (mention briefly)

**Never skip:**
- Live CI/CD deployment
- Application demo
- Architecture overview

---

## 💡 Pro Tips for Demo

### Do:
✅ Practice timing beforehand (aim for 13-14 min, leave buffer)
✅ Prepare code change in advance (copy-paste ready)
✅ Test everything 30 minutes before
✅ Have backup screenshots
✅ Speak clearly and confidently
✅ Show enthusiasm - this is impressive work!
✅ Pause for questions if time allows

### Don't:
❌ Rush through CI/CD demo (it's the highlight!)
❌ Read code line-by-line (summarize)
❌ Apologize for "simple" features (this is enterprise-level!)
❌ Dive too deep into Terraform syntax
❌ Let CI/CD build run in silence (explain what's happening)

---

## 🚀 Alternate Demo Flow (If Pipeline Too Slow)

If CI/CD takes too long during demo:

**Plan B: Show Previous Successful Deployment**

1. Show GitHub Actions history
2. Point to recent successful deployment
3. Show Git commit that triggered it
4. Show deployed version in ECS
5. Explain process verbally with screenshots

Then:
- Trigger new deployment at end
- Show it starting
- Explain "this is now running, would complete in 15 min"

---

## 📝 Talking Points Summary

**Opening Hook:**
"I've built a production-grade cloud application that deploys itself automatically. Watch me push code to GitHub and see it go live in production in 15 minutes."

**Technical Highlights:**
- Full-stack application (React + Python)
- AWS ECS Fargate (serverless containers)
- Infrastructure as Code (Terraform)
- Automated CI/CD (GitHub Actions)
- Zero-downtime deployments
- Git SHA versioning

**Business Value:**
- Faster deployments
- Fewer errors
- Easy rollback
- Cost-effective
- Scalable architecture

**Closing:**
"This is the same architecture used by tech companies and startups. It's production-ready, scalable, and fully automated."

---

## 🎬 Demo Script (Word-for-Word)

**[Slide 1 - Title]**
"Good morning! I'm going to show you a production-grade DevOps project I built - a full-stack application with automated CI/CD on AWS."

**[Show Architecture]**
"Here's the architecture: Frontend and backend containers running on ECS Fargate, behind an Application Load Balancer, all in a secure VPC. Everything is defined as Infrastructure as Code using Terraform."

**[Open Browser]**
"Here's the live application. Let me test the backend API..." [run curl commands]

**[Show Code]**
"All infrastructure is version-controlled. VPC, subnets, load balancer, ECS cluster - everything managed by Terraform."

**[The Big Moment - CI/CD]**
"Now here's the impressive part. Watch me make a code change and push to GitHub..."

[Make change, commit, push]

"GitHub Actions is now automatically: building Docker images, pushing to ECR, updating ECS task definitions, and deploying with zero downtime. Let's watch it run..."

[Show GitHub Actions, explain steps]

"In 15 minutes, this code will be live in production. That's the power of DevOps automation."

**[Closing]**
"This demonstrates enterprise-level DevOps: automated pipelines, zero downtime, full traceability, and Infrastructure as Code. Questions?"

---

## 🎉 You're Ready!

**Remember:**
- You built something impressive - be proud!
- Focus on the CI/CD pipeline - that's the highlight
- Keep energy high
- Have fun with it!

**Good luck with your demo!** 🚀
