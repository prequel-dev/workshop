provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "prequel_provision_token" {
  description = "Prequel provision token"
  type        = string
}

variable "prequel_cluster_name" {
  description = "Prequel cluster name"
  type        = string
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
