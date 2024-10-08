# CRE-2024-007: RabbitMQ Mnesia overloaded 

## Overview

## Common Relability Enumeration (CRE) 2024-007

[RabbitMQ](https://www.rabbitmq.com/) is a messaging system that allows different parts of a software application to communicate with each other by sending and receiving messages. Think of it as a postal service within a software system where messages (letters) are sent to queues (mailboxes), and other parts of the system can retrieve those messages when they're ready.

Reliability intelligence provides a way to describe known problems with software in a machine readiable way. This enables you to automatically detect and mitigate problems in your environment without spending troubleshooting and researching the problem yourself.

This scenario explores CRE-2024-007, a [known issue](https://github.com/rabbitmq/rabbitmq-server/issues/1713) with RabbitMQ queues.

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

Just like any other application, RabbitMQ uses memory (RAM) to perform its operations. It stores messages in memory, especially when they are waiting in queues to be processed. However, memory is a limited resource, and if RabbitMQ uses too much memory, it can negatively impact the overall system performance or even cause the system to run out of memory.

To prevent using too much memory, RabbitMQ has a safety mechanism called the memory watermark. This is similar to setting a limit on how much water can fill a tank to prevent overflow. It's a predefined threshold (limit) of memory usage. When RabbitMQ's memory usage reaches this threshold, it takes action to prevent further memory consumption.

The `rabbitmq_alarms_memory_used_watermark` indicates when RabbitMQ has entered this alarm state and, as a result, will stop processing all new messages.

You can explore additional RabbitMQ metrics by typing `rabbitmq` in the search bar and reviewing the list of metrics. Or you can use the Metrics Explorer interface next to the Execute button.

Question:

* What other RabbitMQ metrics might be important to monitor? 

### Step 3: Trigger problem (10 minutes)

Now let's recreate the problem associated with CRE-2024-007.

```bash
$ time ./trigger.sh 
Deploying the Job...
job.batch/messages-generator-job created
Waiting for the Job 'messages-generator-job' to complete...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' is still running. Checking again in 5 seconds...
Job 'messages-generator-job' completed at 2024-10-08T20:19:32Z.
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "my-rabbitmq-cluster-server-0" force deleted
pod "my-rabbitmq-cluster-server-1" force deleted
Trigger completed

real	1m48.059s
user	0m6.544s
sys	0m1.090s
```

Questions: 

* Monit

### Step 4: Use Prequel to detect problem (1 minute)

Go to https://app-beta.prequel.dev and log in using your credentials. The credentials are found on your lab worksheet printout.

Click on the most recent detection and explore the detection data.

Questions:

* What does the detection tell you is happening?
* Are you able to figure out why it might be happening from the log data in the detection?
* Are you able to figure out how to mitigate the problem?
* What are the differences between an Alertmanager rule for this problem and a reliability intelligence detection?

#### Problem Explanation

Note the following details in the RabbitMQ logs.

```bash
$ kubectl -n rabbitmq logs my-rabbitmq-cluster-server-0 -f
2024-10-08 20:51:10.016352+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.1647.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016352+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016352+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016386+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.5457.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016386+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016386+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016410+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.1722.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016410+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016410+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016466+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.9450.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016466+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016466+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016489+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.1689.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016489+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016489+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016502+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.2464.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016502+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016502+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016523+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.3078140120.3381919745.170350>}} from <0.228.0> to <0.9358.0> in an old incarnation (1728420096) of this node (1728420613)
2024-10-08 20:51:10.016523+00:00 [erro] <0.228.0> 
2024-10-08 20:51:10.016523+00:00 [erro] <0.228.0> 
2024-10-08 20:51:13.025141+00:00 [info] <0.518.0> Starting message stores for vhost '/'
2024-10-08 20:51:13.027194+00:00 [info] <0.523.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_transient": using rabbit_msg_store_ets_index to provide index
2024-10-08 20:51:13.033736+00:00 [info] <0.518.0> Started message store of type transient for vhost '/'
2024-10-08 20:51:13.041279+00:00 [info] <0.527.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_persistent": using rabbit_msg_store_ets_index to provide index
2024-10-08 20:51:13.045213+00:00 [warn] <0.527.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_persistent": rebuilding indices from scratch
2024-10-08 20:53:37.827165+00:00 [info] <0.518.0> Started message store of type persistent for vhost '/'
2024-10-08 20:54:22.217300+00:00 [warn] <0.286.0> Mnesia('rabbit@my-rabbitmq-cluster-server-0.my-rabbitmq-cluster-nodes.rabbitmq'): ** WARNING ** Mnesia is overloaded: {dump_log,write_threshold}
2024-10-08 20:54:22.217300+00:00 [warn] <0.286.0> 
2024-10-08 20:54:50.923258+00:00 [warn] <0.286.0> Mnesia('rabbit@my-rabbitmq-cluster-server-0.my-rabbitmq-cluster-nodes.rabbitmq'): ** WARNING ** Mnesia is overloaded: {dump_log,write_threshold}
2024-10-08 20:56:22.845471+00:00 [info] <0.518.0> Recovering 872 queues of type rabbit_classic_queue took 312609ms
```

#### What is happening?

The RabbitMQ cluster is processing a large number of persistent mirrored queues at boot. There are so many that the underlying Erlang process, `Mnesia`, is reporting that it is overloaded while recoving these queues on boot. During this period, RabbitMQ is unable to process any new messages, which can lead to outages.

Note that there are no RabbitMQ VM threshold watermark alerts.

### Step 5: Implement mitigation (2 minutes)

Click on How To Mitigate -> Details. What are the recommended changes to fix this problem?

## Key Takeaways

* Stuff 
