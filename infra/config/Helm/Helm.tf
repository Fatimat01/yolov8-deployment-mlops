# resource "helm_release" "nginx" {
#   name       = "nginx"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "nginx"

#   values = [
#     file("${path.module}/nginx-values.yaml")
#   ]
# }

resource "null_resource" "helm_repo_setup" {
  provisioner "local-exec" {
    command = <<EOT
      helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
      helm repo add argo https://argoproj.github.io/argo-helm
      helm repo add bitnami https://charts.bitnami.com/bitnami
      helm repo update
    EOT
  }
}




#Install ArgoCD in CLuster
resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.24.1"

  name      = "argocd"
  namespace = "argocd"
  create_namespace = false

  # values = [
  #    file("${path.module}/argo-values.yaml") #file containing config for intial application startups using argo
  #  ]
  
  depends_on = [null_resource.helm_repo_setup]
}


#Wait for Argocd, CRD needs to be fully installed before creating the Root app

resource "null_resource" "wait_for_argocd_crds" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    # This ensures it runs with Bash (important on Windows)
    interpreter = ["bash", "-c"]

    command = <<EOT
      echo "Waiting for ArgoCD CRD to become available..."
      aws eks update-kubeconfig \
      --region us-east-2 \
      --name Cluster_B \
      --role-arn arn:aws:iam::306617143793:role/eks-admin-role
      for i in $(seq 1 20); do
        if kubectl get crd applications.argoproj.io --kubeconfig ../modules/Infra/kubeconfig.yaml>/dev/null 2>&1; then
          echo "CRD found!"
          exit 0
        else
          echo "Waiting for CRD... ($i)"
          sleep 5
        fi
      done
      echo "Timed out waiting for CRD"
      exit 1
    EOT
  }
}


#Create Root App That manages other apps
resource "null_resource" "apply_root_app" {
  depends_on = [null_resource.wait_for_argocd_crds]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/root-app.yaml --kubeconfig ../modules/Infra/kubeconfig.yaml"
  }
}

#Create Root App That manages other apps
/*resource "kubernetes_manifest" "root_app" {
  manifest = yamldecode(file("${path.module}/root-app.yaml"))
  depends_on = [null_resource.wait_for_argocd_crds]
}
*/


#Install Prometheus CRDs
resource "null_resource" "Install_Prom_CRD" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<EOT
      set -e -x

      # Clean up if the folder already exists
      rm -rf prometheus-operator

      # Clone fresh copy
      git clone --depth 1 https://github.com/prometheus-operator/prometheus-operator

      # Apply all CRDs server-side
      kubectl apply --server-side -f prometheus-operator/example/prometheus-operator-crd/ --kubeconfig ../modules/Infra/kubeconfig.yaml
    EOT
  }
}



#OR   kubectl apply --server-side -f https://github.com/prometheus-operator/prometheus-operator/raw/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
/*
resource "null_resource" "Install_Prom_CRD" {
  depends_on = [null_resource.wait_for_argocd_crds]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command = <<EOT
      set -e
      echo "Installing Prometheus Operator CRDs..."

      kubectl create -f https://github.com/prometheus-operator/prometheus-operator/raw/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
      kubectl create -f https://github.com/prometheus-operator/prometheus-operator/raw/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
      kubectl create -f https://github.com/prometheus-operator/prometheus-operator/raw/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
      kubectl create -f https://github.com/prometheus-operator/prometheus-operator/raw/main/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml
      kubectl create -f https://github.com/prometheus-operator/prometheus-operator/raw/main/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml

      echo "Prometheus CRDs installed successfully."
    EOT
  }
}*/





#OR THIS INSTEAD OF ABOVE



#Install Nginx in Cluster directly through Terraform/Helm provider

resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.replicaCount"
    value = "2"
  }
  depends_on = [null_resource.helm_repo_setup]
}

  # set {
  #   name  = "controller.service.type"
  #   value = "LoadBalancer"
  # }
  
 
  #   [null_resource.wait_for_nodes,
  # null_resource.update_kubeconfig]



#Destroy Helm release via terraform
#terraform destroy -target=helm_release.argocd
# kubectl delete ns argocd --wait
# terraform apply


#CReate application through Helm


# resource "helm_release" "argo" {
#   name = "argocd"
#   repository = "https://argoproj.github.io/argo-helm"
#   chart      = "argo-cd" namespace  = "argo" version    = "5.34.5"

#   # An option for setting values that I generally use
#   values = [jsonencode({
#     someKey = "someValue"
#   })]

#   # Another option, individual sets
#   set {
#     name  = "someKey"
#     value = "someValue"
#   }

#   set_sensitive {
#     name  = "someOtherKey"
#     value = "someOtherValue"
#   } 
# }


#Creating ArgoCD application
# # Helm application
# resource "argocd_application" "helm" {
#   metadata {
#     name      = "helm-app"
#     namespace = "argocd"
#     labels = {
#       test = "true"
#     }
#   }

#   spec {
#     destination {
#       server    = "https://kubernetes.default.svc"
#       namespace = "default"
#     }

#     source {
#       repo_url        = "https://some.chart.repo.io"
#       chart           = "mychart"
#       target_revision = "1.2.3"
#       helm {
#         release_name = "testing"
#         parameter {
#           name  = "image.tag"
#           value = "1.2.3"
#         }
#         parameter {
#           name  = "someotherparameter"
#           value = "true"
#         }
#         value_files = ["values-test.yml"]
#         values = yamlencode({
#           someparameter = {
#             enabled   = true
#             someArray = ["foo", "bar"]
#           }
#         })
#       }
#     }
#   }
# }

# # Multiple Application Sources with Helm value files from external Git repository
# resource "argocd_application" "multiple_sources" {
#   metadata {
#     name      = "helm-app-with-external-values"
#     namespace = "argocd"
#   }

#   spec {
#     project = "default"

#     source {
#       repo_url        = "https://charts.helm.sh/stable"
#       chart           = "wordpress"
#       target_revision = "9.0.3"
#       helm {
#         value_files = ["$values/helm-dependency/values.yaml"]
#       }
#     }

#     source {
#       repo_url        = "https://github.com/argoproj/argocd-example-apps.git"
#       target_revision = "HEAD"
#       ref             = "values"
#     }

#     destination {
#       server    = "https://kubernetes.default.svc"
#       namespace = "default"
#     }
#   }
# }