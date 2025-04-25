# Terraform Infrastructure for YOLOv8 FastAPI on EKS 🚀

This module manages the AWS infrastructure needed to deploy the YOLOv8 FastAPI live inference service using Kubernetes (EKS).  
All resources are provisioned using Terraform and automated via GitHub Actions.

---

## Resources Managed

- VPC (Virtual Private Cloud)
- Public and Private Subnets (multi-AZ)
- EKS Cluster
- Node Groups (EC2 worker nodes)
- IAM Roles and Policies
- Application Load Balancer (ALB) for external access
- Security Groups for cluster and nodes
- KMS encryption for secrets

---

## Usage

```bash
terraform init      # Initialize the backend and provider
terraform fmt       # Format and check configuration
terraform validate  # Validate the syntax
terraform plan      # Generate and show execution plan
terraform apply     # Apply changes to AWS
terraform destroy   
```