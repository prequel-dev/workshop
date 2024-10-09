# Setup

## Step 1: Provision org OIDC applications

* Log into https://console.cloud.google.com using the prequelworkshop@gmail.com account.
* Go to API Services
* Go to Credentials
* Ensure there is one Device Auth OIDC application
* Ensure there are enough lab org OIDC applications
* Ensure that the Prequel product is provisioned with the OIDC applications (the device credentials are shared across all organizations)
* There are 10 organizations in the orgs/ directory that you can use. They are pre-configured with OIDC credentials. These can change if someone deleted the OIDC applications.

## Step 2: Provision exceptions for each org

* In the exceptions/ directory, install the exceptions for each organization using your Prequel admin credentials.
* The `install.sh` script can be used for this.

## Step 3: Install the scenario software in the lab environment

* Obtain a provision token for the lab org
* Run the terraform script

```bash
terraform init
terraform apply
```

Use the provision token and a cluster name that uniquely identifies the org for the student as the two input variables for the script.

```bash
$ terraform apply
var.prequel_cluster_name
  Prequel cluster name

  Enter a value: cluster-lab-0

var.prequel_provision_token
  Prequel provision token

  Enter a value: eyJhbGciOiJIUzI1NiIsI.....asdfasdf7A
```

## Step 4: Install Prometheus monitors

Install https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack if it isn't already present in the cluster.

Then install all of the monitors in the monitors/ directory to configure Prometheus to begin scraping metrics for the scenarios. 

```bash
lab[default] student@0:~/prequel/workshop/setup/monitors
$ kubectl -n rabbitmq apply -f ./rabbitmq-podmonitor.yaml 
podmonitor.monitoring.coreos.com/rabbitmq created
lab[default] student@0:~/prequel/workshop/setup/monitors
$ kubectl -n strimzi apply -f ./strimzi-entity-operator-podmonitor.yaml 
podmonitor.monitoring.coreos.com/strimzi-entity-operator-pods created
lab[default] student@0:~/prequel/workshop/setup/monitors
$ kubectl -n strimzi apply -f ./strimzi-kafka-podmonitor.yaml 
podmonitor.monitoring.coreos.com/strimzi-kafka created
lab[default] student@0:~/prequel/workshop/setup/monitors
$ kubectl -n strimzi apply -f ./strimzi-zookeeper-podmonitor.yaml 
podmonitor.monitoring.coreos.com/strimzi-zookeeper created
```

Check Prometheus metrics to ensure that these service metrics are available.

## Step 5: Set up the scenarios

Ensure that the latest rules package is installed on all of the clusters.

### scenario-01-cre-2024-009

Ensure that the Jaeger receiver is configured to use the pod IP address:

```bash
thrift_http:
  endpoint: ${env:MY_POD_IP}:14268
```

### scenario-02-cre-2024-006

Change directories to the scenario folder.

Create the initial cluster.

```bash
$ kubectl -n strimzi apply -f ./kafka-metrics-00.yaml 
kafka.kafka.strimzi.io/my-cluster created
configmap/kafka-metrics created
```

Check Prometheus metrics for Kafka to ensure there is some recent data.

### scenario-03-cre-2024-007

Change directories to this scenario.

Create the initial cluster and configmap using the install script.

```bash
$ ./install.sh 
configmap/definitions created
rabbitmqcluster.rabbitmq.com/my-rabbitmq-cluster created
```

Once the cluster is in the ready state, check Prometheus metrics to ensure we see recent data from RabbitMQ metrics.
