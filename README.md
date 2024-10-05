# Workshop

## Setup

### Run Terraform Script

First we need to install the pre-requisite software into the workshop Kubernetes cluster using the Terraform script.

This script installs and configures the following Helm charts:

* OpenTelemetry Collector
* Strimzi Kafka
* RabbitMQ
* Prequel

```bash
$ cd ./setup
$ terraform init
$ terraform apply
var.prequel_cluster_name
  Prequel cluster name

  Enter a value: prequel-org-1

var.prequel_provision_token
  Prequel provision token

  Enter a value: <XXXXXX>
```

### Install pod monitors for scenarios

```bash
$ cd ./setup/monitors
$ kubectl -n strimzi apply -f strimzi-entity-operator-podmonitor.yaml
$ kubectl -n strimzi apply -f strimzi-kafka-podmonitor.yaml
$ kubectl -n strimzi apply -f strimzi-zookeeper-podmonitor.yaml
```

### Install Prequel exceptions
