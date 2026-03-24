# AWS Infrastructure Deployment Guide

## 📁 Directory Structure

```
infra/aws/dev/
├── networking/          # Phase 1: VPC, Subnets, NAT Gateway
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
├── ecs/                 # Phase 2: ECS Cluster, Services
│   ├── backend.tf
│   ├── data.tf          # References networking state
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
└── alb/                 # Phase 3: Application Load Balancer
    ├── backend.tf
    ├── data.tf          # References networking + ECS
    ├── main.tf
    ├── outputs.tf
    ├── provider.tf
    ├── variables.tf
    └── DEPLOYMENT.md    # Detailed deployment guide
```

## 🚀 Deployment Order

### Phase 1: Deploy Networking Infrastructure

```bash
# Navigate to networking directory
cd infra/aws/dev/networking

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy networking infrastructure
terraform apply

# Verify outputs
terraform output
```

**Expected Outputs:**
- VPC ID
- Public subnet IDs (2 subnets across 2 AZs)
- Private subnet IDs (2 subnets across 2 AZs)
- NAT Gateway ID
- Internet Gateway ID

---

### Phase 2: Deploy ECS Infrastructure

**Prerequisites:** Phase 1 must be completed successfully.

```bash
# Navigate to ECS directory
cd ../ecs

# Initialize Terraform (references networking state)
terraform init

# Review the plan
terraform plan

# Deploy ECS infrastructure
terraform apply

# Verify outputs
terraform output
```

**Expected Outputs:**
- ECS Cluster ARN
- Backend service name
- Frontend service name
- Security group IDs
- CloudWatch log group names

---

### Phase 3: Deploy Application Load Balancer

**Prerequisites:** Phase 1 and Phase 2 must be completed.

```bash
# Navigate to ALB directory
cd ../alb

# Initialize Terraform (references networking + ECS states)
terraform init

# Review the plan
terraform plan

# Deploy ALB infrastructure
terraform apply

# Get application URL
terraform output application_url
```

**Expected Outputs:**
- ALB DNS name
- Frontend URL (http://<ALB_DNS>/)
- Backend API URL (http://<ALB_DNS>/api)
- Target group ARNs

**⚠️ IMPORTANT:** After ALB deployment, you must update ECS services to attach to target groups. See [alb/DEPLOYMENT.md](alb/DEPLOYMENT.md) for detailed instructions.

---

## 📊 What Gets Deployed

### Phase 1: Networking
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (ap-south-1a, ap-south-1b)
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24 (ap-south-1a, ap-south-1b)
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: Single NAT in public subnet 1 (cost optimized)
- **Route Tables**: Public (IGW) and Private (NAT)

### Phase 2: ECS
- **ECS Cluster**: fullstack-app-dev-fullstack-cluster
- **Backend Service**:
  - Container: FastAPI (port 8000)
  - Fargate: 512 CPU / 1024 MB RAM
  - Running in private subnets
- **Frontend Service**:
  - Container: Next.js (port 3000)
  - Fargate: 512 CPU / 1024 MB RAM
  - Running in private subnets
- **Security Groups**: Separate SGs for backend and frontend
- **IAM Roles**: Task execution and task roles
- **CloudWatch Logs**: 7-day retention

### Phase 3: Application Load Balancer
- **ALB**: Internet-facing, deployed in public subnets
- **ALB Security Group**: Allow HTTP (port 80) from internet
- **Target Groups**:
  - Frontend TG: Port 3000, health check on `/`
  - Backend TG: Port 8000, health check on `/health`
- **Routing Rules**:
  - `/api/*` → Backend service
  - `/*` → Frontend service
- **Integration**: ALB → Target Groups → ECS Services (private subnets)

---

## ⚠️ Important Notes

### Current Limitations

1. **Placeholder Docker Images**: Currently using `nginx:latest`
   - Backend and frontend services will fail health checks
   - Need to replace with actual application images from ECR

2. **No External Access**: Services are in private subnets
   - No ALB configured yet (Phase 3)
   - No direct internet access

3. **No Inter-Service Communication**:
   - Backend and frontend can't communicate yet
   - Need service discovery (Phase 3)

### State Management

- **Networking State**: `s3://mahesh-tf-state-2026-devops/dev/networking/terraform.tfstate`
- **ECS State**: `s3://mahesh-tf-state-2026-devops/dev/ecs/terraform.tfstate`
- **ALB State**: `s3://mahesh-tf-state-2026-devops/dev/alb/terraform.tfstate`
- **State Locking**: DynamoDB table `terraform-lock`

---

## 🔧 Common Operations

### View Networking Outputs
```bash
cd infra/aws/dev/networking
terraform output
```

### View ECS Outputs
```bash
cd infra/aws/dev/ecs
terraform output
```

### View ALB Outputs
```bash
cd infra/aws/dev/alb
terraform output application_url
```

### Destroy Infrastructure (Reverse Order)

```bash
# First update ECS to remove load balancer blocks
cd infra/aws/dev/ecs
# Edit main.tf to remove load_balancer configuration
terraform apply

# Then destroy ALB
cd ../alb
terraform destroy

# Then destroy ECS
cd ../ecs
terraform destroy

# Finally destroy networking
cd ../networking
terraform destroy
```

### Update ECS Services

```bash
cd infra/aws/dev/ecs
terraform plan
terraform apply
```

---

## 🔜 Next Steps (Phase 4)

1. **ECR Repositories**: Create registries for backend/frontend images
2. **Build & Push Images**: Dockerize applications and push to ECR
3. **Update Task Definitions**: Use real ECR images instead of nginx
4. **HTTPS/SSL**: Add ACM certificate and HTTPS listener
5. **Custom Domain**: Route53 for custom domain
6. **Monitoring**: CloudWatch dashboards and alarms

---

## 🐛 Troubleshooting

### Terraform Init Fails
- Ensure AWS CLI is configured with `devops` profile
- Verify S3 bucket `mahesh-tf-state-2026-devops` exists
- Verify DynamoDB table `terraform-lock` exists

### ECS Tasks Not Starting
- Check CloudWatch logs: `/ecs/fullstack-app-dev/backend-service`
- Verify security groups allow traffic
- Check NAT Gateway is functioning (private subnets need internet for pulling images)

### Can't Access Services via ALB
- Ensure ALB is deployed (Phase 3)
- Check ECS services are attached to target groups
- Verify health checks are passing
- Review ALB listener rules and target group health
