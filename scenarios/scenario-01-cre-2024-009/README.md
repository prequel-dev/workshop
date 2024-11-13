# CRE-2024-009: OpenTelemetry Collector OOM Crash

## Overview

You are an SRE at a fast-growing fintech company. Your responsibilities include monitoring all layers of the application and putting the appropriate observability tooling in place.
The tool of choice is the Grafana/Prometheus stack. 

The OpenTelemetry Collector is a key component in the [OpenTelemetry project](https://opentelemetry.io/) and you use it as a centralized agent for collecting, processing, and exporting telemetry data such as traces, metrics, and logs from different applications and systems. 

To make sure your team has the visibility they need, you actively monitor these collectors in addition to your applications.  

This exercise will introduce you to monitoring the OpenTelemetry Collector. You will learn how to discover and troubleshoot problems with the Collector, enabling it to better operate at scale.

## Lab (about 20 minutes)

### Step 1: Monitor metrics for the OpenTelemetry Collector (1 minute)

Open a browser and load the Prometheus UI. The URL will be http://studentXX.detect.sh:9090. Change `XX` to your lab number found on your lab worksheet printout (e.g. 1, 2, ... 10).

Memory is one of the most propular metrics to monitor.  Let's visualize memory usage for the Opentelemetry Collector by viewing a graph of the `container_memory_rss` metric in the `monitoring` namespace.

```bash
container_memory_rss{namespace="monitoring", container="otel-collector"}
```

<img width="1434" alt="Screenshot 2024-11-12 at 3 42 29 PM" src="https://github.com/user-attachments/assets/91139f09-5599-487e-9adb-511737351cb6">

The metric `container_memory_rss` measures the Resident Set Size (RSS), which is the amount of memory that a container has in RAM. Specifically, it shows the non-swapped physical memory used by the container, which is a critical indicator of how much memory the container is actively using from the available RAM. 

Kubernetes memory resource limits measure RSS usage to determine whether a resource has exceeded its limit. At this point, the container will be OOMKilled (Out of Memory) by Linux. OOMKills are indicative of resource waste and scaling limitations.  When they occur, they can result in data loss, unpredictability, and service disruption.   With successive crashes, there is the risk that the container enters a CrashLoopBackOff state, where Kubernetes stops trying to restart it immediately and instead waits for longer periods between each restart attempt. 

`container_memory_rss` is useful for monitoring memory usage trends and alerting on potential memory pressure.

### Step 2: Trigger problem (2 minutes)

To see how our collector performs under load, let's generate some application traces and send them to the OpenTelemetry Collector for processing. 

You should already have an SSH session open to the workshop environment. In your terminal, run the following commands:

Change directories to the relevant scenario folder:

```bash
$ cd /home/studentXX/workshop/scenarios/scenario-01-cre-2024-009
$ pwd
/home/studentXX/workshop/scenarios/scenario-01-cre-2024-009
```

Change XX to your lab number found on your lab worksheet printout (e.g. 1, 2, ... 10).

Run the `trigger.sh` script to trigger the scenario problem. 

This script will create a Kubernetes job that generates Jaeger traces and sends them to the OpenTelemetry Collector. It takes a few minutes to complete.

```bash
./trigger.sh 
Error from server (NotFound): jobs.batch "traces-generator-job" not found
Deploying the problem trigger job...
job.batch/traces-generator-job created
Waiting for the Job 'traces-generator-job' to complete...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' is still running. Checking again in 5 seconds...
Job 'traces-generator-job' completed at 2024-10-10T02:24:36Z.
job.batch "traces-generator-job" deleted
Trigger completed
```

While the job is running, use Prometheus to monitor the `container_memory_rss{namespace="monitoring", container="opentelemetry-collector"}` metric for the OpenTelemetry Collector container in the `monitoring` namespace to see how the Collector is doing. 

#### Question 1: What do you see happening in Prometheus?

_Hints:_

Monitor the `container_memory_rss{namespace="monitoring", container="opentelemetry-collector"}` metric in Prometheus. Is it increasing?

Other metrics to explore:

```bash
container_oom_events_total{namespace="monitoring", image="docker.io/otel/opentelemetry-collector-k8s:0.111.0"}
```

```bash
kube_pod_container_status_last_terminated_reason{namespace="monitoring", container="opentelemetry-collector"}
```

#### Question 2: Why is it happening? What steps would you need to take to figure it out?

_Hints:_

Look at the Kubernetes logs and search for errors:

```bash
kubectl -n monitoring logs deployments/otel-collector | grep -i error
```

Check the Kubernetes events for any unhealthy or warning events:

```bash
kubectl -n monitoring get events -w -A | grep -E "Unhealthy|Warning"
```

You should see a cgroup out of memory warning: 

```bash
default      101s        Warning   OOMKilling         node/gke-lab-default-pool-4fa5bdf0-v2jq   Memory cgroup out of memory: Killed process 1021235 (otelcol-k8s) total-vm:1553900kB, anon-rss:201972kB, file-rss:70040kB, shmem-rss:0kB, UID:10001 pgtables:784kB oom_score_adj:994
```

#### Question 3: How could we fix this problem?

_Hints:_

* We can fix the export configuration to ensure that traces are forwarded successfully
* We can reduce the data sent to the OpenTelemetry Collector to prevent it from being overwhelmed

### Step 3: Use Prequel to detect and manage the problem (1 minute)

Go to https://app-beta.prequel.dev and log in using your credentials. The credentials are found on your lab worksheet printout.

Click on the most recent detection and explore the detection data and graph.

<img width="1427" alt="image" src="https://github.com/user-attachments/assets/6ac5240e-c506-4f03-a273-7cbb2bc20639">

Prequel has already done the heavy-lifting. Detecting the issue and stitching together relevant context.  

* Look at the `otel-collector` Logs in the detection. Do you see the same errors? 
* Change the data source filter to 'process' to view process CPU and memory. 
* Look at HTTP data. And look at Kubernetes events.
* View the Graph in the detection. Where are the traces coming from?

How do we fix the issue? Prequel has a recommendation:

Click on How To Mitigate -> Details. Does the rule help explain the problem and recommend mitigations?

#### Problem Explanation

Note the following log lines in the OpenTelemetry Collector:

<img width="1435" alt="image" src="https://github.com/user-attachments/assets/e1c6575f-44ea-4281-b62a-c7e6bc4601dd">

The OpenTelemetry Collector receives traces from your cluster and forwards it on to a destination source, such as Prometheus. The logs above indicate that the collector is unable to forward the data it is receiving. 

<img width="1438" alt="image" src="https://github.com/user-attachments/assets/dd318074-d9a2-40d4-8fc4-6bcb5747f98f">

This data builds up in the collector's memory, eventually consuming more than its resource limit. 

<img width="1439" alt="image" src="https://github.com/user-attachments/assets/59cfb93b-e955-49d7-83ef-c0974088fe56">

When this resource limit is exceeded, the container is terminated by Linux. This container status event shows up in Kuberetes as an `OOMKilling` event.

<img width="1436" alt="image" src="https://github.com/user-attachments/assets/6b502f54-29a9-4b30-a53f-16d16e62f7b9">

The Prequel Graph collects relevant data from neighboring services to help us understand where the trace data is coming from.

#### Common Reliability Enumeration (CRE) 2024-009

Reliability intelligence provides a way to describe known problems with software in a machine readable way. This enables you to automatically detect and mitigate problems in your environment without spending time figuring out which metrics to montior and saves time troubleshooting and researching the problem yourself.

This problem is defined in CRE-2024-009. As noted above, it is a [known issue](https://github.com/open-telemetry/opentelemetry-collector/discussions/4010) with using the OpenTelemetry Collector.

```
{
    "title": "OpenTelemetry Collector OOM Crash",
    "description": "There is a known problem with the OpenTelemetry Collector where the collector can crash due to an out-of-memory (OOM) condition. This can cause the collector to stop processing telemetry data and can lead to gaps in the collected data. This can cause the collector to become unresponsive and can lead to liveness probe failures and restarts of the OpenTelemetry Collector.",
    "type": "memory problems",
    "severity": "critical",
    "metrics": "container_memory_rss",
    "symptoms": [
        "liveness/readiness probe timeouts",
        "most of the memory is coming from ingested OTLP data"
    ],
    "reports": 2,
    "applications": [
        {
            "application": "opentelemetry-collector",
            "versions": [
                "0.104.0",
                "0.105.0",
                "0.106.0",
                "0.107.0",
                "0.108.0",
                "0.109.0",
                "0.110.0",
                "0.111.0"
            ]
        }
    ],
    "cause": "backpressure exporting OTLP data to upstream destinations",
    "solutions": [
        "Use the memory_limiter processor"
    ],
    "tags": [
        "OpenTelemetry",
        "crash",
        "memory"
    ],
    "detections": [
        {
            "query language": "Prequel",
            "rule": "k8(image_url=\"docker.io/otel/opentelemetry-collector*\", event=OOMKilling)"
        }
    ],
    "references": [
        "https://github.com/open-telemetry/opentelemetry-collector/discussions/4010"
    ]
}
```

### Step 4: Implement mitigation (10 minutes)

Click on How To Mitigate -> Details. Then edit the OpenTelemetry configuration and apply the recommended Prequel mitigation.

Use `diff -y` to compare the current configuration with the new configuration implementing the recommended mitigation.

```bash
$ diff -y otel-config-00.yaml otel-config-01.yaml 
apiVersion: v1                                  apiVersion: v1
data:                                           data:
  relay: |                                        relay: |
    exporters:                                      exporters:
      debug: {}                                       debug: {}
      otlp:                                           otlp:
        endpoint: localhost:4319                        endpoint: localhost:4319
    extensions:                                     extensions:
      health_check:                                   health_check:
        endpoint: ${env:MY_POD_IP}:13133                endpoint: ${env:MY_POD_IP}:13133
      zpages:                                         zpages:
        endpoint: ${env:MY_POD_IP}:55679                endpoint: ${env:MY_POD_IP}:55679
    processors:                                     processors:
      batch: {}                                       batch: {}
                                                >     memory_limiter:
                                                >       check_interval: 5s
                                                >       limit_percentage: 80
                                                >       spike_limit_percentage: 25
    receivers:                                      receivers:
      jaeger:                                         jaeger:
        protocols:                                      protocols:
          thrift_http:                                    thrift_http:
            endpoint: ${env:MY_POD_IP}:14268                endpoint: ${env:MY_POD_IP}:14268
      otlp:                                           otlp:
        protocols:                                      protocols:
          grpc:                                           grpc:
            endpoint: ${env:MY_POD_IP}:4317                 endpoint: ${env:MY_POD_IP}:4317
      prometheus:                                     prometheus:
        config:                                         config:
          scrape_configs:                                 scrape_configs:
          - job_name: opentelemetry-collector             - job_name: opentelemetry-collector
            scrape_interval: 10s                            scrape_interval: 10s
            static_configs:                                 static_configs:
            - targets:                                      - targets:
              - ${env:MY_POD_IP}:8888                         - ${env:MY_POD_IP}:8888
      zipkin:                                         zipkin:
        endpoint: ${env:MY_POD_IP}:9411                 endpoint: ${env:MY_POD_IP}:9411
    service:                                        service:
      extensions:                                     extensions:
      - health_check                                  - health_check
      pipelines:                                      pipelines:
        logs:                                           logs:
          exporters:                                      exporters:
          - otlp                                          - otlp
          processors:                                     processors:
          - batch                                         - batch
                                                >         - memory_limiter
          receivers:                                      receivers:
          - otlp                                          - otlp
        metrics:                                        metrics:
          exporters:                                      exporters:
          - otlp                                          - otlp
          processors:                                     processors:
          - batch                                         - batch
                                                >         - memory_limiter
          receivers:                                      receivers:
          - otlp                                          - otlp
        traces:                                         traces:
          exporters:                                      exporters:
          - otlp                                          - otlp
          processors:                                     processors:
          - batch                                         - batch
                                                >         - memory_limiter
          receivers:                                      receivers:
          - jaeger                                        - jaeger
```

Update the OpenTelemetry Collector configuration to use the mitigation.

```bash
kubectl -n monitoring apply -f ./otel-config-01.yaml 
```

Restart the collector to apply the configuration changes and ensure it started running successfully.

```bash
$ kubectl -n monitoring rollout restart deployment otel-collector
$ kubectl -n monitoring get pods
NAME                              READY   STATUS    RESTARTS   AGE
otel-collector-77595fd49d-hjx64   1/1     Running   0          69s
```

### Step 5: Trigger problem (2 minutes)

Re-run the instructions in Step 2 to try and re-create the problem.

### Step 6: Monitor memory growth (1 minute)

Use both Prometheus and Prequel to see if the problem happens again.

## Key Takeaways

* The OpenTelemetry Collector `memory_limiter` processor is an important pipeline component, especially in larger scale environments
* Reliability research and intelligence can reduce the time to monitor, understand, and mitigate problems
* Wildcard support for fields like `image_urls` can reduce the number of rules required to detect problems
* Visualizing service graphs in the context of a specific detection can help further identify contributing factors to an ongoing problem
