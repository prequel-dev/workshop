# CRE-2024-007: RabbitMQ Mnesia overloaded 

## Overview

## Common Relability Enumeration (CRE) 2024-007

Reliability intelligence provides a way to describe known problems with software in a machine readiable way. This enables you to automatically detect and mitigate problems in your environment without spending troubleshooting and researching the problem yourself.

This scenario explores CRE-2024-007, a [known issue](https://github.com/rabbitmq/rabbitmq-server/issues/1713) with RabbitMQ persistent quorum queues.

```
{
    "title": "RabbitMQ Mnesia overloaded recovering persistent queues",
    "description": "There is a known problem where RabbitMQ can become unresponsive due to Mnesia overload on start-up while processing several persistent queues. The only message in Rabbitmq log is Mnesia is overloaded.",
    "type": "message-queue-problems",
    "severity": "critical",
    "metrics": "rabbitmq_fd_used",
    "symptoms": [
        "number of socket connections is low"
    ],
    "reports": 1,
    "applications": [
        {
            "application": "rabbitmq"
        },
        {
            "application": "mnesia"
        }
    ],
    "cause": "CPU limitations",
    "solutions": [
        "Increase the Kubernetes CPU limits for the RabbitMQ brokers"
    ],
    "tags": [
        "rabbitmq",
        "mnesia"
    ],
    "detections": [
        {
            "query language": "Prequel",
            "rule": "k8(image_url=\"docker.io/bitnami/rabbitmq:3.9.14*\", event=READINESS) | log(pattern=\"Mnesia is overloaded\", window=90s)"
        }
    ],
    "references": [
        "[https://github.com/rabbitmq/rabbitmq-server/issues/1713](https://github.com/rabbitmq/rabbitmq-server/issues/1713)",
        "[https://github.com/rabbitmq/rabbitmq-server/issues/687](https://github.com/rabbitmq/rabbitmq-server/issues/687)"
    ]
}
```

## Lab (about 20 minutes)

### Step 1: Monitor metrics for RabbitMQ (1 minutes)

Open a browser and load the Prometheus UI. The URL will be http://prometheusXX.classroom.superorbital.io/ (change `XX` to your lab number found on your lab worksheet printout).

Use Prometheus to visualize a few relevant metrics to monitor the health of your RabbitMQ cluster.

```
rabbitmq_alarms_memory_used_watermark{namespace="rabbitmq"}
```

![RabbitMQ alarm metrics](./images/rabbitmq-alarm.png)

Question:

* What other RabbitMQ metrics might be important to monitor?

### Step 3: Trigger problem (10 minutes)

Now let's recreate the problem associated with CRE-2024-007:

Questions: 

* Some questions

### Step 4: Use Prequel to detect problem (1 minute)

Go to https://app-beta.prequel.dev and log in using your credentials. The credentials are found on your lab worksheet printout.

Click on the most recent detection and explore the detection data.

Questions:

* What does the detection tell you is happening?
* Are you able to figure out why it might be happening from the log data in the detection?
* Are you able to figure out how to mitigate the problem?
* What are the differences between an Alertmanager rule for this problem and a reliability intelligence detection?

### Step 5: Implement mitigation (2 minutes)

Click on How To Mitigate -> Details. What are the recommended changes to fix this problem?

## Key Takeaways

* Stuff 
