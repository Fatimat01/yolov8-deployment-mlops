provider "aws" {
  region = "us-east-2"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "yolov8-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  create_igw           = true

  tags = {
    Project = "YOLOv8-EKS"
  }
}


module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  cluster_name                         = "yolov8-cluster"
  cluster_version                      = "1.31"
  cluster_endpoint_public_access_cidrs = ["70.130.71.90/32"]
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  subnet_ids = module.vpc.private_subnets
  vpc_id     = module.vpc.vpc_id

  # cluster_security_group_additional_rules = {
  #   ingress_from_node = {
  #     description                = "Allow node to communicate with control plane"
  #     protocol                   = "tcp"
  #     from_port                  = 10250
  #     to_port                    = 10250
  #     type                       = "ingress"
  #     source_node_security_group = true
  #   }
  # }

  # node_security_group_additional_rules = {
  #   egress_all = {
  #     description = "Allow all egress"
  #     protocol    = "-1"
  #     from_port   = 0
  #     to_port     = 0
  #     type        = "egress"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }

  #   alb_health_check = {
  #     description = "Allow ALB health checks"
  #     protocol    = "tcp"
  #     from_port   = 80
  #     to_port     = 80
  #     type        = "ingress"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  #   alb_to_nodes = {
  #     description = "Allow ALB to access YOLOv8 pods"
  #     protocol    = "tcp"
  #     from_port   = 30080
  #     to_port     = 30080
  #     type        = "ingress"
  #     cidr_blocks = ["0.0.0.0/0"]
  #   }
  # }

  enable_irsa = false

  # iam_role_arn = aws_iam_role.eks_cluster_role.arn
  eks_managed_node_groups = {
    yolov8-ng = {
      ami_type       = "AL2_x86_64"
      instance_types = ["t3.medium"]

      min_size     = 2
      max_size     = 2
      desired_size = 2
#      iam_role_arn = aws_iam_role.eks_node_role.arn
    }
  }

  tags = {
    Project = "YOLOv8-EKS"
  }
}

resource "aws_eks_access_entry" "eks" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.id}:user/fatimat-admin"
  type          = "STANDARD"
  depends_on    = [module.eks]

}

resource "aws_eks_access_policy_association" "eks" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = aws_eks_access_entry.eks.principal_arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_policy_association" "cluster" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.eks.principal_arn

  access_scope {
    type = "cluster"
  }
}