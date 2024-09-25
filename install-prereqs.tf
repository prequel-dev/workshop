provider "helm" {
  kubernetes {
    config_path = "~/.kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "~/.kubeconfig"
}

### Cert Manager

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.15.2" 

  set {
    name  = "installCRDs"
    value = "true"
  }
}

### Prometheus

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = "monitoring"
  create_namespace = true
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  set {
    name  = "server.persistentVolume.size"
    value = "8Gi"
  }
}

### Jaeger

resource "helm_release" "jaeger" {
  name       = "jaeger"
  namespace  = "monitoring"
  create_namespace = true
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"

  depends_on = [
    helm_release.prometheus
  ]

  set {
    name  = "ingress.enabled"
    value = "true"
  }
}

### OpenTelemetry Collector

resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  namespace  = "monitoring"
  create_namespace = true

  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"

  set {
    name = "resources.limits.memory"
    value = "500Mi"
  }

  set {
    name = "resources.requests.memory"
    value = "500Mi"
  }

  set {
    name = "image.repository"
    value = "otel/opentelemetry-collector-k8s"
  }

  set {
    name = "mode"
    value = "deployment"
  }

}