# Scenarios

* CRE-2024-006: Kafka Topic Operator Thread Blocked
* CRE-2024-007: RabbitMQ Mnesia overloaded
* CRE-2024-009: OpenTelemetry Collector OOM Crash

## Setup

* Helm repo setup

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add prequel https://prequel-dev.github.io/helm
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

* Install Prometheus, Graphana, Jaeger

```
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.15.3 --set crds.enabled=true
kubectl create namespace jaeger
helm install -n prometheus --create-namespace kube-prometheus-stack prometheus-community/kube-prometheus-stack
helm install -n jaeger --create-namespace jaeger jaegertracing/jaeger-operator
```

Create a jaeger-install.yaml file and add the following to it:

```
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: simplest
```

```
kubectl -n jaeger apply -f ./jager-install.yaml
```

* Install RabbitMQ Cluster Operator

```
kubectl create namespace rabbitmq-system
kubectl -n rabbitmq-system apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
```
