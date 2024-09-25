# CRE-2024-009: OpenTelemetry Collector OOM Crash

### Introduction

* The OpenTelemetry Collector is a key component in the OpenTelemetry project that acts as a centralized agent or service for collecting, processing, and exporting telemetry data such as traces, metrics, and logs from different applications and systems.

* This exercise will introduce you to collecting and analyzing Jaeger traces with an OpenTelemetry collector. You will learn how to discover and troubleshoot problems with missing Observability data caused by a known issue. And finally, you will learn how to better manage and operate an OpenTelemetry collector at scale.

### Setup

* Install 

```
helm install otelcol open-telemetry/opentelemetry-collector --set image.repository="otel/opentelemetry-collector-k8s" --set mode=deployment -f ./config.yaml
```

### Lab

* Part 1
** Validate you are seeing application traces in Jaeger from the OpenTelemetry collector.
** Learn how to discover and troubleshoot problems with missing trace data by simulating a known problem with the OpenTelemetry collector.
** Learn how to write and deploy an AlertManager rule to detect restart loops

* Part 2
** Learn how to automatically detect the known issue using reliability intelligence
** Learn how to quickly identify the cause of the problem 
** Learn how to identify where the trace data is coming from during the problem
** Learn how to implement a recommended mitigation for the known issue to stop the problem

### Key Takeaways
