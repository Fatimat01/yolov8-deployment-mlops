terraform {
  backend "s3" {
    bucket   = "habeeb-k8-state-buck"
    key      = "terraform/helm-terraform.tfstate"
    region   = "us-east-2"
    }
}

#Helm provider uses your kubeconfig to autheticate to cluster
provider "helm" {
  kubernetes {
    config_path = "../modules/Infra/kubeconfig.yaml"
  }
}

provider "kubernetes" {
  config_path = "../modules/Infra/kubeconfig.yaml"  # Or your specific kubeconfig path
}


# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }

# data "aws_eks_cluster" "eks" {
#   name = aws_eks_cluster.bibbo_cluster.name
# }

# data "aws_eks_cluster_auth" "eks" {
#   name = aws_eks_cluster.bibbo_cluster.name
# }








 










#YOU COULD PUT ALL PROIVERS IN A SINLG BLOCK LIKE THIS:
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 5.80.0"
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = ">= 2.11.0"
#     }
#     null = {
#       source  = "hashicorp/null"
#       version = ">= 3.2.1"
#     }
#   }
# }




# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.bibbo_cluster.cluster_endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.bibbo_cluster.cluster_certificate_authority_data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.bibbo_cluster.cluster_name]
#       command     = "aws"
#     }
#   }

# }
