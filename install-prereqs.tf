locals {
  namespace = "cert-manager"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

### Cert Manager

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = local.namespace
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = local.namespace
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.2" 

  set {
    name  = "installCRDs"
    value = "true"
  }
}