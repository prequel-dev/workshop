provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
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
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "rabbitmq-cluster-operator"
}
