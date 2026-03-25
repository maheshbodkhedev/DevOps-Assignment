#!/usr/bin/env python3
"""
DevOps Project Architecture Diagram Generator

Generates a professional architecture diagram as PNG.

Install required package:
    pip install diagrams

Run:
    python3 architecture_diagram.py

Output: devops_project_architecture.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import ECS, ECR
from diagrams.aws.network import ALB, InternetGateway, NATGateway
from diagrams.aws.management import Cloudwatch
from diagrams.aws.storage import S3
from diagrams.aws.database import Dynamodb
from diagrams.onprem.vcs import Github
from diagrams.onprem.ci import GithubActions
from diagrams.generic.device import Mobile

# Configure diagram
graph_attr = {
    "fontsize": "14",
    "bgcolor": "white"
}

with Diagram(
    "DevOps Project - AWS Architecture",
    show=False,
    direction="TB",
    graph_attr=graph_attr,
    filename="devops_project_architecture"
):
    # Users
    users = Mobile("Internet\nUsers")

    # CI/CD Pipeline
    with Cluster("CI/CD Pipeline", graph_attr={"bgcolor": "lightblue"}):
        github = Github("GitHub\nRepository")
        actions = GithubActions("GitHub Actions\nAutomated Pipeline")
        github >> Edge(label="push to main") >> actions

    # AWS Cloud
    with Cluster("AWS Cloud (ap-south-1)"):
        # Container Registry
        ecr = ECR("Amazon ECR\nDocker Images\nSHA-tagged")

        # Monitoring
        logs = Cloudwatch("CloudWatch\nContainer Logs")

        # State Management
        with Cluster("Terraform State", graph_attr={"bgcolor": "lightyellow"}):
            s3 = S3("S3 Bucket\nState Storage")
            dynamo = Dynamodb("DynamoDB\nState Lock")

        # VPC
        with Cluster("VPC (10.0.0.0/16)", graph_attr={"bgcolor": "lightgreen"}):
            igw = InternetGateway("Internet\nGateway")

            # Public Subnets
            with Cluster("Public Subnets (2 AZs)"):
                alb = ALB("Application\nLoad Balancer\n(Path-based)")
                nat = NATGateway("NAT\nGateway")

            # Private Subnets
            with Cluster("Private Subnets (2 AZs)"):
                with Cluster("ECS Fargate Cluster"):
                    frontend = ECS("Frontend\nNext.js\nPort 3000")
                    backend = ECS("Backend\nFastAPI\nPort 8000")

    # User traffic flow
    users >> Edge(label="HTTP", color="blue") >> igw
    igw >> Edge(color="blue") >> alb
    alb >> Edge(label="/ path", color="green") >> frontend
    alb >> Edge(label="/api/* path", color="orange") >> backend

    # CI/CD flow
    actions >> Edge(label="build & push", color="purple") >> ecr
    actions >> Edge(label="update", color="purple") >> frontend
    actions >> Edge(label="update", color="purple") >> backend
    actions >> Edge(label="state", style="dotted", color="gray") >> s3
    actions >> Edge(label="lock", style="dotted", color="gray") >> dynamo

    # Container image flow
    ecr >> Edge(label="pull", style="dashed", color="purple") >> frontend
    ecr >> Edge(label="pull", style="dashed", color="purple") >> backend

    # Logging
    frontend >> Edge(label="logs", style="dotted", color="gray") >> logs
    backend >> Edge(label="logs", style="dotted", color="gray") >> logs

    # Internet access via NAT
    frontend >> Edge(label="internet", style="dotted", color="gray") >> nat
    backend >> Edge(label="internet", style="dotted", color="gray") >> nat

print("✅ Diagram generated: devops_project_architecture.png")
print("📊 Open the PNG file to view your architecture diagram!")
