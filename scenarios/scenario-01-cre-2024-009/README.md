# CRE-2024-009: OpenTelemetry Collector OOM Crash

## Overview

The OpenTelemetry Collector is a key component in the [OpenTelemetry project](https://opentelemetry.io/) that acts as a centralized agent for collecting, processing, and exporting telemetry data such as traces, metrics, and logs from different applications and systems.

This exercise will introduce you to monitoring the OpenTelemetry Collector. You will learn how to discover and troubleshoot problems with the Collector. And you will learn how to better manage and operate an OpenTelemetry collector at scale.

## Common Relability Enumeration (CRE) 2024-009

Reliability intelligence provides a way to describe known problems with software in a machine readiable way. This enables you to automatically detect and mitigate problems in your environment without spending troubleshooting and researching the problem yourself.

This scenario explores CRE-2024-009, a [known issue](https://github.com/open-telemetry/opentelemetry-collector/discussions/4010) with using the OpenTelemetry Collector.

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
            "rule": "k8(image_url=\"docker.io/otel/opentelemetry-collector*\", event=OOM)"
        }
    ],
    "references": [
        "https://github.com/open-telemetry/opentelemetry-collector/discussions/4010"
    ]
}
```

## Lab (about 20 minutes)

### Step 1: Monitor metrics for OpenTelemetry Collector (1 minute)

Open a browser and load the Prometheus UI. The URL will be http://prometheusXX.classroom.superorbital.io/ (change `XX` to your lab number found on your lab worksheet printout).

Visualize memory usage for the Opentelemetry Collector by viewing a graph of the `container_memory_rss` metric in the `monitoring` namespace.

```
container_memory_rss{namespace="monitoring", container="opentelemetry-collector"}
```

![Monitor OTel Collector memory](./images/otel-rss.png)

### Step 2: Trigger problem (2 minutes)

Now let's generate traces and send them to the OpenTelemetry Collector. In your terminal, run the following commands:

```bash
$ cd ./trace_generator/k8s
$ kubectl -n monitoring apply -f ./deploy.yaml
deployment.apps/traces-generator-deployment created
$ kubectl -n monitoring logs deployments/traces-generator-deployment -f 
Using collector address: otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:14268
Generating 400 total traces using 4 workers...
2024/10/07 18:38:23 Post "http://otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:14268/api/traces": EOF
2024/10/07 18:38:27 Post "http://otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:14268/api/traces": dial tcp 10.119.252.93:14268: connect: connection refused
```

Delete the deployment when you see the above EOF and connection refused errors.

```bash
$ k -n monitoring delete deployments.apps traces-generator-deployment 
deployment.apps "traces-generator-deployment" deleted
```

Use Prometheus to monitor the metrics for the OpenTelemetry Collector container in the `monitoring` namespace.

Questions: 

* What do you see happening in Prometheus?
* Why is it happening? What steps would you need to take to figure it out?
* How would we fix it?
* How could you create an alert for this with Prometheus/Alertmanager?

### Step 3: Use Prequel to detect problem (1 minute)

Go to https://app-beta.prequel.dev and log in using your credentials. The credentials are found on your lab worksheet printout.

Click on the most recent detection and explore the detection data and graph.

Questions:

* What does the detection tell you is happening?
* Are you able to figure out why it might be happening from the log and HTTP data in the detection?
* Where is it coming from using the graph?
* Are you able to figure out how to mitigate the problem?

### Step 4: Implement mitigation (10 minutes)

Click on How To Mitigate -> Details

Then edit the OpenTelemetry configuration and apply the recommended Prequel mitigation.

```
$ kubectl -n monitoring edit configmap otel-collector-opentelemetry-collector 
```

Ensure that the `memory_limiter` processor is configured.

```bash
processors:
  batch: {}
  memory_limiter:
    check_interval: 5s
    limit_percentage: 50
    spike_limit_percentage: 30
```

And make sure that the traces pipeline uses the processor.

```bash
traces:
  exporters:
  - otlp
  processors:
  - batch
  - memory_limiter
  receivers:
  - jaeger
```

Restart the collector to apply the configuration changes and ensure it started running successfully.

```bash
$ kubectl -n monitoring rollout restart deployment otel-collector-opentelemetry-collector
$ kubectl -n monitoring get pods
NAME                                                      READY   STATUS    RESTARTS   AGE
otel-collector-opentelemetry-collector-555844884d-hvs7g   1/1     Running   0          34s
```

### Step 5: Trigger problem (2 minutes)

Re-run the instructions in Step 2 to try and re-create the problem.

### Step 6: Monitor memory growth (1 minute)

Use both Prometheus and Prequel to see if the problem happens again.

## Key Takeaways

* All the data in one place
