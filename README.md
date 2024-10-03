# Workshop

## Setup

First we need to install the pre-requisite software into the workshop Kubernetes cluster using the Terraform script in `/setup`.

This script installs and configures the following Helm charts:

* OpenTelemetry Collector
* Strimzi Kafka
* RabbitMQ

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
