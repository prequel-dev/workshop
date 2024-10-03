provider "helm" {
  kubernetes {
    config_path = "~/.kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "~/.kubeconfig"
}

variable "prequel_provision_token" {
  description = "Prequel provision token"
  type        = string
}

variable "prequel_cluster_name" {
  description = "Prequel cluster name"
  type        = string
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
  chart      = "strimzi-kafka-operator"
  version    = "0.32.0"
}

### RabbitMQ Cluster Operator

resource "helm_release" "rabbitmq_operator" {
  name       = "my-rabbitmq"
  namespace  = "rabbitmq"
  create_namespace = true
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "rabbitmq-cluster-operator"
}

### Prequel

resource "helm_release" "prequel" {
  name       = "prequel-latest"
  namespace  = "prequel"
  create_namespace = true
  repository = "https://prequel-dev.github.io/helm"
  chart      = "prequel-collector"
  wait = false

  set {
    name = "api.token"
    value = var.prequel_provision_token
  }

  set {
    name = "api.clusterName"
    value = var.prequel_cluster_name
  }
}