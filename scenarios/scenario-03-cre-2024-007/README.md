# CRE-2024-007: RabbitMQ Mnesia overloaded 

## Overview

[RabbitMQ](https://www.rabbitmq.com/) is a messaging system that allows different parts of a software application to communicate with each other by sending and receiving messages. Think of it as a postal service within a software system where messages (letters) are sent to queues (mailboxes), and other parts of the system can retrieve those messages when they're ready.

## Lab (about 20 minutes)

### Step 1: Monitor metrics for RabbitMQ (1 minutes)

Open a browser and load the Prometheus UI. The URL will be http://prometheusXX.classroom.superorbital.io/ (change `XX` to your lab number found on your lab worksheet printout).

Use Prometheus to visualize and explore RabbitMQ metrics. For example, start with:

```
rabbitmq_alarms_memory_used_watermark{namespace="rabbitmq"}
```

![RabbitMQ alarm metrics](./images/rabbitmq-alarm.png)

What does this metric measure?

Just like any other application, RabbitMQ uses memory (RAM) to perform its operations. It stores messages in memory, especially when they are waiting in queues to be processed. However, memory is a limited resource, and if RabbitMQ uses too much memory, it can negatively impact the overall system performance or even cause the system to run out of memory.

To prevent using too much memory, RabbitMQ has a safety mechanism called the memory watermark. This is similar to setting a limit on how much water can fill a tank to prevent overflow. It's a predefined threshold (limit) of memory usage. When RabbitMQ's memory usage reaches this threshold, it takes action to prevent further memory consumption.

The `rabbitmq_alarms_memory_used_watermark` indicates when RabbitMQ has entered this alarm state and, as a result, will stop processing all new messages.

You can explore additional RabbitMQ metrics by typing `rabbitmq` in the search bar and reviewing the list of metrics. Or you can use the Metrics Explorer interface next to the Execute button.

Question:

* What other RabbitMQ metrics might be important to monitor? 

### Step 3: Trigger problem (10 minutes)

Now let's recreate the problem associated with CRE-2024-007. This will take about 2 minutes.

```bash
$ time ./trigger.sh 
Error from server (NotFound): jobs.batch "messages-generator-job" not found
Deploying the problem trigger job...
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
Job 'messages-generator-job' completed at 2024-10-09T02:34:42Z.
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "my-rabbitmq-cluster-server-0" force deleted
pod "my-rabbitmq-cluster-server-1" force deleted
job.batch "messages-generator-job" deleted
Trigger completed

real	1m32.636s
user	0m6.234s
sys	0m0.995s
```

Questions:

* What RabbitMQ metrics in Prometheus are useful in understanding what is happening?

```bash
rabbitmq_connection_incoming_bytes_total{namespace="rabbitmq"}
```

```bash
rabbitmq_erlang_processes_used{namespace="rabbitmq"}
```

* What other metrics might be helpful?

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

The RabbitMQ cluster is processing a large number of persistent mirrored queues at boot. There are so many that the underlying Erlang process, `Mnesia`, is reporting that it is overloaded while recoving these queues on boot. During this period, RabbitMQ is unable to process any new messages, which can lead to outages.

Note that there are no RabbitMQ VM threshold watermark alerts.

#### Common Relability Enumeration (CRE) 2024-007

Reliability intelligence provides a way to describe known problems with software in a machine readable way. This enables you to automatically detect and mitigate problems in your environment without spending time figuring out which metrics to montior and saves time troubleshooting and researching the problem yourself.

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

### Step 5: Implement mitigation (2 minutes)

Click on How To Mitigate -> Details. What are the recommended changes to fix this problem?

Run the following `diff -y` command to see the recommended mitigations we're about to apply.

```bash
$ diff -y rabbitmq-00.yaml rabbitmq-01.yaml 
apiVersion: rabbitmq.com/v1beta1        apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster                   kind: RabbitmqCluster
metadata:                               metadata:
  name: my-rabbitmq-cluster               name: my-rabbitmq-cluster
spec:                                   spec:
  replicas: 2                       |     replicas: 4
  resources:                        <
    requests:                       <
      memory: 512Mi                 <
      cpu: 50m                      <
    limits:                         <
      memory: 4Gi                   <
      cpu: 200m                     <
```

Question:

* How would these changes help resolve the problem?

Run the following commands to apply the recommended mitigation.

```bash
$ kubectl -n rabbitmq delete -f ./rabbitmq-00.yaml
rabbitmqcluster.rabbitmq.com "my-rabbitmq-cluster" deleted
$ kubectl -n rabbitmq apply -f ./rabbitmq-01.yaml 
rabbitmqcluster.rabbitmq.com/my-rabbitmq-cluster created
```

Monitor the creation of the new cluster. Once the cluster pods enter the ready state, tail the log files of one of the clusters to see if the problem with `Mnesia` happens again.

```bash
$ k -n rabbitmq get pods -o wide -w
NAME                                                              READY   STATUS    RESTARTS   AGE   IP            NODE                                 NOMINATED NODE   READINESS GATES
my-rabbitmq-cluster-server-0                                      0/1     Running   0          82s   10.116.4.51   gke-lab-default-pool-4fa5bdf0-v2jq   <none>           <none>
my-rabbitmq-cluster-server-1                                      0/1     Running   0          81s   10.116.8.57   gke-lab-default-pool-6a8caa23-mpx1   <none>           <none>
my-rabbitmq-cluster-server-2                                      0/1     Running   0          81s   10.116.6.32   gke-lab-default-pool-6a8caa23-v4t0   <none>           <none>
my-rabbitmq-cluster-server-3                                      0/1     Running   0          81s   10.116.9.38   gke-lab-default-pool-4fa5bdf0-bljk   <none>           <none>
my-rabbitmq-rabbitmq-cluster-operator-59894fb74c-j569w            1/1     Running   0          32h   10.116.2.28   gke-lab-default-pool-a2454db7-qvgp   <none>           <none>
my-rabbitmq-rabbitmq-messaging-topology-operator-54d5dcf5fzjbch   1/1     Running   0          32h   10.116.7.28   gke-lab-default-pool-a2454db7-wvc9   <none>           <none>
my-rabbitmq-cluster-server-1                                      1/1     Running   0          82s   10.116.8.57   gke-lab-default-pool-6a8caa23-mpx1   <none>           <none>
my-rabbitmq-cluster-server-0                                      1/1     Running   0          83s   10.116.4.51   gke-lab-default-pool-4fa5bdf0-v2jq   <none>           <none>
my-rabbitmq-cluster-server-2                                      1/1     Running   0          99s   10.116.6.32   gke-lab-default-pool-6a8caa23-v4t0   <none>           <none>
my-rabbitmq-cluster-server-3                                      1/1     Running   0          102s   10.116.9.38   gke-lab-default-pool-4fa5bdf0-bljk   <none>           <none>
```

```bash
kubectl -n rabbitmq logs my-rabbitmq-cluster-server-1 -f
2024-10-09 02:57:21.449927+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.4211663329.4243849217.73908>}} from <0.228.0> to <0.5050.0> in an old incarnation (1728442498) of this node (1728442635)
2024-10-09 02:57:21.449927+00:00 [erro] <0.228.0> 
2024-10-09 02:57:21.449927+00:00 [erro] <0.228.0> 
2024-10-09 02:57:21.449977+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.4211663329.4243849217.73908>}} from <0.228.0> to <0.3845.0> in an old incarnation (1728442498) of this node (1728442635)
2024-10-09 02:57:21.449977+00:00 [erro] <0.228.0> 
2024-10-09 02:57:21.449977+00:00 [erro] <0.228.0> 
2024-10-09 02:57:21.450001+00:00 [erro] <0.228.0> Discarding message {'$gen_cast',{force_event_refresh,#Ref<0.4211663329.4243849217.73908>}} from <0.228.0> to <0.3732.0> in an old incarnation (1728442498) of this node (1728442635)
2024-10-09 02:57:21.450001+00:00 [erro] <0.228.0> 
2024-10-09 02:57:21.450001+00:00 [erro] <0.228.0> 
2024-10-09 02:57:21.566968+00:00 [info] <0.651.0> Making sure data directory '/bitnami/rabbitmq/mnesia/rabbit@my-rabbitmq-cluster-server-1.my-rabbitmq-cluster-nodes.rabbitmq/msg_stores/vhosts/628WB79CIFDYO9LJI6DKMI09L' for vhost '/' exists
2024-10-09 02:57:21.628743+00:00 [info] <0.651.0> Starting message stores for vhost '/'
2024-10-09 02:57:21.629335+00:00 [info] <0.655.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_transient": using rabbit_msg_store_ets_index to provide index
2024-10-09 02:57:21.631593+00:00 [info] <0.651.0> Started message store of type transient for vhost '/'
2024-10-09 02:57:21.633076+00:00 [info] <0.659.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_persistent": using rabbit_msg_store_ets_index to provide index
2024-10-09 02:57:21.634371+00:00 [warn] <0.659.0> Message store "628WB79CIFDYO9LJI6DKMI09L/msg_store_persistent": rebuilding indices from scratch
2024-10-09 02:57:24.980082+00:00 [info] <0.651.0> Started message store of type persistent for vhost '/'
2024-10-09 02:57:28.307685+00:00 [info] <0.651.0> Recovering 249 queues of type rabbit_classic_queue took 6737ms
2024-10-09 02:57:28.307768+00:00 [info] <0.651.0> Recovering 0 queues of type rabbit_quorum_queue took 0ms
2024-10-09 02:57:28.307797+00:00 [info] <0.651.0> Recovering 0 queues of type rabbit_stream_queue took 0ms
2024-10-09 02:57:28.331166+00:00 [info] <0.651.0> Mirrored queue 'pq3' in vhost '/': Adding mirror on node 'rabbit@my-rabbitmq-cluster-server-1.my-rabbitmq-cluster-nodes.rabbitmq': <0.7169.0>
2024-10-09 02:57:28.332015+00:00 [info] <0.651.0> Mirrored queue 'pq2' in vhost '/': Adding mirror on node 'rabbit@my-rabbitmq-cluster-server-1.my-rabbitmq-cluster-nodes.rabbitmq': <0.7173.0>
2024-10-09 02:57:28.332719+00:00 [info] <0.651.0> Mirrored queue 'pq1' in vhost '/': Adding mirror on node 'rabbit@my-rabbitmq-cluster-server-1.my-rabbitmq-cluster-nodes.rabbitmq': <0.7177.0>
2024-10-09 02:57:28.333389+00:00 [info] <0.228.0> Running boot step empty_db_check defined by app rabbit
2024-10-09 02:57:28.333462+00:00 [info] <0.228.0> Will not seed default virtual host and user: have definitions to load...
2024-10-09 02:57:28.333501+00:00 [info] <0.228.0> Running boot step rabbit_looking_glass defined by app rabbit
2024-10-09 02:57:28.333543+00:00 [info] <0.228.0> Running boot step rabbit_core_metrics_gc defined by app rabbit
2024-10-09 02:57:28.333869+00:00 [info] <0.228.0> Running boot step background_gc defined by app rabbit
2024-10-09 02:57:28.334251+00:00 [info] <0.228.0> Running boot step routing_ready defined by app rabbit
2024-10-09 02:57:28.334347+00:00 [info] <0.228.0> Running boot step pre_flight defined by app rabbit
2024-10-09 02:57:28.334415+00:00 [info] <0.228.0> Running boot step notify_cluster defined by app rabbit
2024-10-09 02:57:28.334459+00:00 [info] <0.228.0> Running boot step networking defined by app rabbit
2024-10-09 02:57:28.334537+00:00 [info] <0.228.0> Running boot step definition_import_worker_pool defined by app rabbit
2024-10-09 02:57:28.334680+00:00 [info] <0.563.0> Starting worker pool 'definition_import_pool' with 2 processes in it
2024-10-09 02:57:28.335282+00:00 [info] <0.228.0> Running boot step cluster_name defined by app rabbit
2024-10-09 02:57:28.335373+00:00 [info] <0.228.0> Setting cluster name to 'my-rabbitmq-cluster' as configured
2024-10-09 02:57:28.338101+00:00 [info] <0.612.0> rabbit on node 'rabbit@my-rabbitmq-cluster-server-0.my-rabbitmq-cluster-nodes.rabbitmq' up
2024-10-09 02:57:28.343261+00:00 [info] <0.228.0> Running boot step direct_client defined by app rabbit
2024-10-09 02:57:28.348287+00:00 [info] <0.228.0> Running boot step rabbit_management_load_definitions defined by app rabbitmq_management
2024-10-09 02:57:28.349571+00:00 [info] <0.7192.0> Resetting node maintenance status
2024-10-09 02:57:28.397015+00:00 [info] <0.612.0> rabbit on node 'rabbit@my-rabbitmq-cluster-server-2.my-rabbitmq-cluster-nodes.rabbitmq' up
2024-10-09 02:57:28.411162+00:00 [info] <0.612.0> rabbit on node 'rabbit@my-rabbitmq-cluster-server-3.my-rabbitmq-cluster-nodes.rabbitmq' up
2024-10-09 02:57:28.436332+00:00 [info] <0.7289.0> Management plugin: HTTP (non-TLS) listener started on port 15672
2024-10-09 02:57:28.436733+00:00 [info] <0.7317.0> Statistics database started.
2024-10-09 02:57:28.436960+00:00 [info] <0.7316.0> Starting worker pool 'management_worker_pool' with 3 processes in it
2024-10-09 02:57:28.445026+00:00 [info] <0.7333.0> Peer discovery: node cleanup is disabled
2024-10-09 02:57:28.448359+00:00 [info] <0.7341.0> Prometheus metrics: HTTP (non-TLS) listener started on port 15692
2024-10-09 02:57:28.449078+00:00 [info] <0.7192.0> Applying definitions from file at '/etc/rabbitmq/definitions.json'
2024-10-09 02:57:28.449139+00:00 [info] <0.7192.0> Asked to import definitions. Acting user: rmq-internal
2024-10-09 02:57:28.449416+00:00 [info] <0.7192.0> Importing concurrently 1 users...
2024-10-09 02:57:28.454509+00:00 [info] <0.7185.0> Successfully changed password for user 'guest'
2024-10-09 02:57:28.454576+00:00 [info] <0.7185.0> Successfully set user tags for user 'guest' to [administrator]
2024-10-09 02:57:28.454716+00:00 [info] <0.7192.0> Importing concurrently 1 vhosts...
2024-10-09 02:57:28.462451+00:00 [info] <0.7192.0> Importing concurrently 1 permissions...
2024-10-09 02:57:28.466076+00:00 [info] <0.7185.0> Successfully set permissions for 'guest' in virtual host '/' to '.*', '.*', '.*'
2024-10-09 02:57:28.466404+00:00 [info] <0.7192.0> Importing concurrently 1 exchanges...
2024-10-09 02:57:28.467932+00:00 [info] <0.7192.0> Importing sequentially 2 global runtime parameters...
2024-10-09 02:57:28.475427+00:00 [info] <0.7192.0> Importing sequentially 1 policies...
2024-10-09 02:57:28.479190+00:00 [info] <0.7192.0> Importing concurrently 3 queues...
2024-10-09 02:57:28.484416+00:00 [info] <0.7192.0> Importing concurrently 2 bindings...
2024-10-09 02:57:28.485061+00:00 [info] <0.7192.0> Ready to start client connection listeners
2024-10-09 02:57:28.490990+00:00 [info] <0.7395.0> started TCP listener on [::]:5672
 completed with 6 plugins.
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0> Server startup complete; 6 plugins started.
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0>  * rabbitmq_prometheus
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0>  * rabbitmq_peer_discovery_k8s
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0>  * rabbitmq_peer_discovery_common
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0>  * rabbitmq_management
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0>  * rabbitmq_web_dispatch
2024-10-09 02:57:28.645146+00:00 [info] <0.7192.0>  * rabbitmq_management_agent
2024-10-09 02:57:50.515748+00:00 [info] <0.612.0> rabbit on node 'rabbit@my-rabbitmq-cluster-server-0.my-rabbitmq-cluster-nodes.rabbitmq' up
```

## Key Takeaways

* Some problems are very challenging to detect using metrics
* Detecting a problem early can save hours of customer down time
* RabbitMQ/Erlang expertise is difficult to find and develop. Reliability intelligence can fill the gap.