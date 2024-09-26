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

  set {
    name = "service.enabled"
    value = "true"
  }

  set {
    name = "service.internalTrafficPolicy"
    value = "Local"
  }

  set {
    name = "config.extensions.zpages.endpoint"
    value = "localhost:55679"
  }

  set {
    name = "config.receivers.otlp.protocols.grpc.endpoint"
    value = "localhost:4317"
  }

  set {
    name = "config.receivers.otlp.protocols.http.endpoint"
    value = "localhost:4318"
  }

  set {
    name = "config.receivers.jaeger.protocols.thrift_http.endpoint"
    value = "localhost:14268"
  }

  set {
    name = "config.exporters.otlp.endpoint"
    value = "localhost:4319"
  }

  set {
    name = "config.service.pipelines.logs.exporters"
    value = "{otlp}"
  }

  set {
    name = "config.service.pipelines.logs.processors"
    value = "{batch}"
  }

  set {
    name = "config.service.pipelines.logs.receivers"
    value = "{otlp}"
  }

  set {
    name = "config.service.pipelines.metrics.exporters"
    value = "{otlp}"
  }

  set {
    name = "config.service.pipelines.metrics.processors"
    value = "{batch}"
  }

  set {
    name = "config.service.pipelines.metrics.receivers"
    value = "{otlp}"
  }

  set {
    name = "config.service.pipelines.traces.exporters"
    value = "{otlp}"
  }

  set {
    name = "config.service.pipelines.traces.processors"
    value = "{batch}"
  }

  set {
    name = "config.service.pipelines.traces.receivers"
    value = "{jaeger}"
  }
}

### Strimzi Kafka Cluster Operator

resource "helm_release" "kafka_operator" {
  name       = "my-kafka"
  namespace  = "strimzi"
  create_namespace = true
  repository = "https://strimzi.io/charts/"
  chart      = "strimzi/strimzi-kafka-operator"
  version    = "0.32.0"
}

### RabbitMQ Cluster Operator

resource "helm_release" "rabbitmq_operator" {
  name       = "my-rabbitmq"
  namespace  = "rabbitmq"
  create_namespace = true
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "bitnami/rabbitmq-cluster-operator"
}