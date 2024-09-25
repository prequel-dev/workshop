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

  set {
    name  = "ingress.enabled"
    value = "true"
  }
}

### OpenTelemetry Collector

resource "helm_release" "otel_collector" {
  name       = "otel-collector"
  namespace  = "monitoring"
  chart      = "open-telemetry/opentelemetry-collector"

  set {
    name = "image.repository"
    value = "otel/opentelemetry-collector-k8s"
  }

  set {
    name = "mode"
    value = "deployment"
  }

  values = [
    <<EOF
resources:
  limits:
    memory: "500Mi"
  requests:
    memory: "500Mi"

config:
  extensions:
    zpages:
      endpoint: "localhost:55679"
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "localhost:4317"
        http:
          endpoint: "localhost:4318"
    jaeger:
      protocols:
        thrift_http:
          endpoint: "localhost:14268"
  processors:
    batch: {}
  exporters:
    otlp:
      endpoint: "localhost:4319"
    jaeger:
      endpoint: http://jaeger-collector.monitoring.svc.cluster.local:14268/api/traces
  service:
    pipelines:
      logs:
        exporters:
        - otlp
        processors:
        - batch
        receivers:
        - otlp
      metrics:
        exporters:
        - otlp
        processors:
        - batch
        receivers:
        - otlp
      traces:
        exporters:
        - otlp
        processors:
        - batch
        receivers:
        - otlp
        - jaeger
EOF
  ]
}