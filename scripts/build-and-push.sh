#!/bin/bash

# Build and Push Docker Images to ECR
# Usage: ./scripts/build-and-push.sh [backend|frontend|all]

set -e

# Configuration
AWS_REGION="ap-south-1"
AWS_PROFILE="devops"
PROJECT_DIR="/home/mahesh/code/devops-project/DevOps-Assignment"
ECR_DIR="$PROJECT_DIR/infra/aws/dev/ecr"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get ECR repository URLs from Terraform
get_ecr_urls() {
    log_info "Getting ECR repository URLs from Terraform..."
    cd "$ECR_DIR"

    BACKEND_REPO_URL=$(terraform output -raw backend_repository_url 2>/dev/null || echo "")
    FRONTEND_REPO_URL=$(terraform output -raw frontend_repository_url 2>/dev/null || echo "")

    if [ -z "$BACKEND_REPO_URL" ] || [ -z "$FRONTEND_REPO_URL" ]; then
        log_error "ECR repositories not found. Please run 'terraform apply' in infra/aws/dev/ecr first."
        exit 1
    fi

    log_info "Backend ECR: $BACKEND_REPO_URL"
    log_info "Frontend ECR: $FRONTEND_REPO_URL"
}

# ECR login
ecr_login() {
    log_info "Logging into ECR..."
    aws ecr get-login-password \
        --region $AWS_REGION \
        --profile $AWS_PROFILE | \
    docker login \
        --username AWS \
        --password-stdin \
        ${BACKEND_REPO_URL%/*}

    if [ $? -eq 0 ]; then
        log_info "ECR login successful"
    else
        log_error "ECR login failed"
        exit 1
    fi
}

# Build and push backend
build_backend() {
    log_info "Building backend Docker image..."
    cd "$PROJECT_DIR/backend"

    docker build \
        --platform linux/amd64 \
        -t fullstack-backend:latest \
        -t fullstack-backend:$(git rev-parse --short HEAD 2>/dev/null || echo "local") \
        .

    log_info "Tagging backend image for ECR..."
    docker tag fullstack-backend:latest $BACKEND_REPO_URL:latest
    docker tag fullstack-backend:latest $BACKEND_REPO_URL:$(git rev-parse --short HEAD 2>/dev/null || echo "local")

    log_info "Pushing backend image to ECR..."
    docker push $BACKEND_REPO_URL:latest
    docker push $BACKEND_REPO_URL:$(git rev-parse --short HEAD 2>/dev/null || echo "local")

    log_info "✅ Backend image pushed successfully"
}

# Build and push frontend
build_frontend() {
    log_info "Building frontend Docker image..."
    cd "$PROJECT_DIR/frontend"

    docker build \
        --platform linux/amd64 \
        -t fullstack-frontend:latest \
        -t fullstack-frontend:$(git rev-parse --short HEAD 2>/dev/null || echo "local") \
        .

    log_info "Tagging frontend image for ECR..."
    docker tag fullstack-frontend:latest $FRONTEND_REPO_URL:latest
    docker tag fullstack-frontend:latest $FRONTEND_REPO_URL:$(git rev-parse --short HEAD 2>/dev/null || echo "local")

    log_info "Pushing frontend image to ECR..."
    docker push $FRONTEND_REPO_URL:latest
    docker push $FRONTEND_REPO_URL:$(git rev-parse --short HEAD 2>/dev/null || echo "local")

    log_info "✅ Frontend image pushed successfully"
}

# Main execution
main() {
    local component=${1:-all}

    log_info "Starting deployment for: $component"

    # Get ECR URLs
    get_ecr_urls

    # Login to ECR
    ecr_login

    # Build and push based on component
    case $component in
        backend)
            build_backend
            ;;
        frontend)
            build_frontend
            ;;
        all)
            build_backend
            build_frontend
            ;;
        *)
            log_error "Invalid component: $component. Use 'backend', 'frontend', or 'all'"
            exit 1
            ;;
    esac

    log_info "🎉 Deployment completed successfully!"
    log_info "Next steps:"
    log_info "1. Update ECS task definitions with new image URLs"
    log_info "2. Run: cd $PROJECT_DIR/infra/aws/dev/ecs && terraform apply"
}

# Run main function
main "$@"
