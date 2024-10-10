# CRE-2024-006: Kafka Topic Operator Thread Blocked

## Overview

[Apache Kafka](https://kafka.apache.org/) is an open-source distributed event streaming platform primarily used for building real-time data pipelines and streaming applications. It was originally developed by LinkedIn and is now maintained by the Apache Software Foundation.

This exercise will introduce you to creating and using Kafka topics. You will learn how to discover and troubleshoot a [known problem](https://github.com/strimzi/strimzi-kafka-operator/issues/6046) with Kafka.

## Lab (about 20 minutes)

### Step 1: Add a new Kafka topic (5 minutes)

This lab exercise uses [Strimzi Kafka for Kubernetes](https://strimzi.io/). Strimzi provides a way to run an Apache Kafka cluster on Kubernetes in various deployment configurations. 

Let's discover how to add new Kafka topics. Kafka topics are the categories used to organize messages. Each topic has a name that is unique across the entire Kafka cluster. Messages are sent to and read from specific topics. Producers write data to topics and consumers read data from topics. 

The Strimzi Kafka [entity operator](https://strimzi.io/docs/operators/0.28.0/full/configuring#assembly-kafka-entity-operator-str) is used to manage Kafka-related entities in a running Kafka cluster. It contains a user and topic operator. The operators are automatically configured to monitor and manage the topics and users of the Kafka cluster.

Change directories to the scenario folder:
    
```bash
$ cd /home/student/prequel/workshop/scenarios/scenario-02-cre-2024-009
$ pwd
/home/student/prequel/workshop/scenarios/scenario-01-cre-2024-009
```

Add a new topic by applying the `topic-00.yaml` configuration file. 

```bash
$ kubectl -n strimzi apply -f ./topic-00.yaml 
kafkatopic.kafka.strimzi.io/topic-00 created
```

After a few minutes you should see that the new topic `topic-00` is ready.

```bash
$ kubectl -n strimzi get kafkatopics.kafka.strimzi.io 
NAME                                                                                               CLUSTER      PARTITIONS   REPLICATION FACTOR   READY
topic-00                                                                                           my-cluster   3            1                    True
```

### Step 2: Monitor metrics for Kafka (1 minutes)

Open a browser and load the Prometheus UI. The URL will be http://prometheusXX.classroom.superorbital.io/ (change `XX` to your lab number found on your lab worksheet printout).

Use Prometheus to visualize the health of Kafka topic creation using the following metric:

```
kafka_controller_controllerstats_topicchangerateandtimems{container="kafka", namespace="strimzi", quantile="0.999"}
```

![Kafka Topic Operator metrics](./images/kafka-changetime.png)

The Kafka metric `kafka_controller_controllerstats_topicchangerateandtimems` is a controller-level metric that measures the rate and time taken for changes related to Kafka topics. It captures two key pieces of information:

1. Topic Change Rate: This part of the metric tracks how frequently changes to Kafka topics occur. Topic changes could include operations such as creating, deleting, or altering a topic's configuration or partition structure.

2. Topic Change Time (in milliseconds): This part tracks the time taken for the controller to process these topic changes, measured in milliseconds. It reflects how long the Kafka controller takes to detect and apply these changes.

This metric is useful for monitoring the responsiveness of the Kafka controller to topic-related changes and understanding the load that topic modifications place on the system. High change rates or long processing times could indicate bottlenecks or performance issues in the Kafka controller.

The 0.999 quantile means that 99.9% of the time, topic changes take less than or equal to the value reported by this metric.

You can explore additional Kafka metrics by typing `kafka_` in the search bar and reviewing the list of metrics. Or you can use the Metrics Explorer interface next to the Execute button.

Question:

* What other Kafka metrics might be important to monitor the health of Kafka topic creation?

### Step 3: Trigger problem (10 minutes)

Now let's recreate the problem associated with CRE-2024-006.

```bash
$ kubectl -n strimzi apply -f ./kafka-metrics-01.yaml
kafka.kafka.strimzi.io/my-cluster configured
configmap/kafka-metrics unchanged
```

Monitor Kubernetes events to wait until the entity operator is successfully re-created. This can take a few minutes for the Strimzi Kafka operator to reconcile the configuration change. 

```bash
$ kubectl -n strimzi get events -w -A | grep -E 'strimzi.*SuccessfulCreate'
strimzi      0s          Normal    SuccessfulCreate    replicaset/my-cluster-entity-operator-67cb786575   Created pod: my-cluster-entity-operator-67cb786575-46888
```

Now create another topic.

```bash
$ kubectl -n strimzi apply -f ./topic-01.yaml 
kafkatopic.kafka.strimzi.io/topic-01 configured
```

Watch the `kafkatopics.kafka.strimzi.io` resources.

```bash
$ kubectl -n strimzi get kafkatopics.kafka.strimzi.io -w
NAME                                                                                               CLUSTER      PARTITIONS   REPLICATION FACTOR   READY
topic-00                                                                                           my-cluster   3            1                    True
topic-01                                                                                           my-cluster   3            1                    
```

Questions: 

* What do you observe with the new topic? Does it get created? Why or why not?
* Does the `kafka_controller_controllerstats_topicchangerateandtimems` metric in Prometheus help you understand what is happening?
* Why isn't the new topic being created? What steps would you need to take to figure this out?
* How would we fix it?
* What other metrics can we explore to help monitor this problem? Do any of the `vertx*` metrics help?
* How could you create an alert for this with Prometheus/Alertmanager?

### Step 4: Use Prequel to detect problem (1 minute)

Go to https://app-beta.prequel.dev and log in using your credentials. The credentials are found on your lab worksheet printout.

Click on the most recent detection and explore the detection data.

Questions:

* What does the detection tell you is happening?
* Are you able to figure out why it might be happening from the log data in the detection?
* Are you able to figure out how to mitigate the problem?

#### Problem Explanation

Note the following details in the `topic-operator` in the Kafka `entity-operator`:

```bash
$ kubectl -n strimzi logs deployments/my-cluster-entity-operator -c topic-operator
2024-10-09 17:38:09,11626 INFO  [vert.x-eventloop-thread-0] Session:205 - Starting
2024-10-09 17:38:12,21498 WARN  [vertx-blocked-thread-checker] BlockedThreadChecker: - Thread Thread[vert.x-eventloop-thread-0,5,main] has been blocked for 2897 ms, time limit is 2000 ms
2024-10-09 17:38:12,71510 WARN  [vertx-blocked-thread-checker] BlockedThreadChecker: - Thread Thread[vert.x-eventloop-thread-0,5,main] has been blocked for 3897 ms, time limit is 2000 ms
2024-10-09 17:38:13,71506 WARN  [vertx-blocked-thread-checker] BlockedThreadChecker: - Thread Thread[vert.x-eventloop-thread-0,5,main] has been blocked for 4897 ms, time limit is 2000 ms
2024-10-09 17:38:14,91513 WARN  [vertx-blocked-thread-checker] BlockedThreadChecker: - Thread Thread[vert.x-eventloop-thread-0,5,main] has been blocked for 5897 ms, time limit is 2000 ms
io.vertx.core.VertxException: Thread blocked
	at java.security.MessageDigest.digest(MessageDigest.java:405) ~[?:?]
	at com.sun.crypto.provider.HmacCore.engineDoFinal(HmacCore.java:227) ~[?:?]
	at javax.crypto.Mac.doFinal(Mac.java:581) ~[?:?]
	at javax.crypto.Mac.doFinal(Mac.java:624) ~[?:?]
	at com.sun.crypto.provider.PBKDF2KeyImpl.deriveKey(PBKDF2KeyImpl.java:192) ~[?:?]
	at com.sun.crypto.provider.PBKDF2KeyImpl.<init>(PBKDF2KeyImpl.java:117) ~[?:?]
	at com.sun.crypto.provider.PBKDF2Core.engineGenerateSecret(PBKDF2Core.java:69) ~[?:?]
	at com.sun.crypto.provider.PBES2Core.engineInit(PBES2Core.java:280) ~[?:?]
	at com.sun.crypto.provider.PBES2Core.engineInit(PBES2Core.java:307) ~[?:?]
	at javax.crypto.Cipher.implInit(Cipher.java:847) ~[?:?]
	at javax.crypto.Cipher.chooseProvider(Cipher.java:901) ~[?:?]
	at javax.crypto.Cipher.init(Cipher.java:1576) ~[?:?]
	at javax.crypto.Cipher.init(Cipher.java:1507) ~[?:?]
	at sun.security.pkcs12.PKCS12KeyStore.lambda$engineLoad$1(PKCS12KeyStore.java:2111) ~[?:?]
	at sun.security.pkcs12.PKCS12KeyStore$$Lambda$253/0x00000008402d0c40.tryOnce(Unknown Source) ~[?:?]
	at sun.security.pkcs12.PKCS12KeyStore$RetryWithZero.run(PKCS12KeyStore.java:276) ~[?:?]
	at sun.security.pkcs12.PKCS12KeyStore.engineLoad(PKCS12KeyStore.java:2106) ~[?:?]
	at sun.security.util.KeyStoreDelegator.engineLoad(KeyStoreDelegator.java:243) ~[?:?]
	at java.security.KeyStore.load(KeyStore.java:1479) ~[?:?]
	at org.apache.kafka.common.security.ssl.DefaultSslEngineFactory$FileBasedStore.load(DefaultSslEngineFactory.java:372) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.security.ssl.DefaultSslEngineFactory$FileBasedStore.<init>(DefaultSslEngineFactory.java:347) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.security.ssl.DefaultSslEngineFactory.createKeystore(DefaultSslEngineFactory.java:297) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.security.ssl.DefaultSslEngineFactory.configure(DefaultSslEngineFactory.java:161) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.security.ssl.SslFactory.instantiateSslEngineFactory(SslFactory.java:140) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.security.ssl.SslFactory.configure(SslFactory.java:97) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.network.SslChannelBuilder.configure(SslChannelBuilder.java:73) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.network.ChannelBuilders.create(ChannelBuilders.java:192) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.common.network.ChannelBuilders.clientChannelBuilder(ChannelBuilders.java:81) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.clients.ClientUtils.createChannelBuilder(ClientUtils.java:105) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.clients.admin.KafkaAdminClient.createInternal(KafkaAdminClient.java:524) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.clients.admin.KafkaAdminClient.createInternal(KafkaAdminClient.java:485) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.clients.admin.Admin.create(Admin.java:134) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at org.apache.kafka.clients.admin.AdminClient.create(AdminClient.java:39) ~[org.apache.kafka.kafka-clients-3.3.1.jar:?]
	at io.strimzi.operator.topic.Session.start(Session.java:210) ~[io.strimzi.topic-operator-0.32.0.jar:0.32.0]
	at io.vertx.core.impl.DeploymentManager.lambda$doDeploy$5(DeploymentManager.java:196) ~[io.vertx.vertx-core-4.3.4.jar:4.3.4]
	at io.vertx.core.impl.DeploymentManager$$Lambda$222/0x00000008402b0040.handle(Unknown Source) ~[?:?]
	at io.vertx.core.impl.ContextInternal.dispatch(ContextInternal.java:264) ~[io.vertx.vertx-core-4.3.4.jar:4.3.4]
	at io.vertx.core.impl.ContextInternal.dispatch(ContextInternal.java:246) ~[io.vertx.vertx-core-4.3.4.jar:4.3.4]
	at io.vertx.core.impl.EventLoopContext.lambda$runOnContext$0(EventLoopContext.java:43) ~[io.vertx.vertx-core-4.3.4.jar:4.3.4]
	at io.vertx.core.impl.EventLoopContext$$Lambda$223/0x00000008402b0c40.run(Unknown Source) ~[?:?]
	at io.netty.util.concurrent.AbstractEventExecutor.runTask(AbstractEventExecutor.java:174) ~[io.netty.netty-common-4.1.77.Final.jar:4.1.77.Final]
	at io.netty.util.concurrent.AbstractEventExecutor.safeExecute(AbstractEventExecutor.java:167) ~[io.netty.netty-common-4.1.77.Final.jar:4.1.77.Final]
	at io.netty.util.concurrent.SingleThreadEventExecutor.runAllTasks(SingleThreadEventExecutor.java:470) ~[io.netty.netty-common-4.1.77.Final.jar:4.1.77.Final]
	at io.netty.channel.nio.NioEventLoop.run(NioEventLoop.java:503) ~[io.netty.netty-transport-4.1.77.Final.jar:4.1.77.Final]
	at io.netty.util.concurrent.SingleThreadEventExecutor$4.run(SingleThreadEventExecutor.java:995) ~[io.netty.netty-common-4.1.77.Final.jar:4.1.77.Final]
	at io.netty.util.internal.ThreadExecutorMap$2.run(ThreadExecutorMap.java:74) ~[io.netty.netty-common-4.1.77.Final.jar:4.1.77.Final]
	at io.netty.util.concurrent.FastThreadLocalRunnable.run(FastThreadLocalRunnable.java:30) ~[io.netty.netty-common-4.1.77.Final.jar:4.1.77.Final]
	at java.lang.Thread.run(Thread.java:829) ~[?:?]
```

The main event loop is blocked. As a result, the `topic-operator` is unable to monitor and update Kafka topics.

#### Common Relability Enumeration (CRE) 2024-009

Reliability intelligence provides a way to describe known problems with software in a machine readable way. This enables you to automatically detect and mitigate problems in your environment without spending time troubleshooting and researching the problem yourself.

This scenario explores CRE-2024-006, a [known issue](https://github.com/strimzi/strimzi-kafka-operator/issues/6046) with the Strimzi Kafka topic operator.

```
{
    "title": "Strimzi Kafka Topic Operator Thread Blocked",
    "description": "There is a known issue in the Strimzi Kafka Topic Operator where the operator thread can become blocked. This can cause the operator to stop processing events and can lead to a backlog of events. This can cause the operator to become unresponsive and can lead to liveness probe failures and restarts of the Strimzi Kafka Topic Operator.",
    "type": "message-queue-problems",
    "severity": "critical",
    "metrics": "",
    "symptoms": [
        "blocked threads"
    ],
    "reports": 1,
    "applications": [
        {
            "application": "Strimzi kafka"
        }
    ],
    "cause": "CPU limitations",
    "solutions": [
        "Use the Zookeeper store instead of the Kafka Streams store for the Strimzi Kafka Topic Operator"
    ],
    "tags": [
        "kafka",
        "threads",
        "strimzi"
    ],
    "detections": [
        {
            "query language": "Prequel",
            "rule": "k8(container_name=\"topic-operator\", event=STARTUP) | log( pattern=\"io.vertx.core.VertxException: Thread blocked\", window=90s)"
        }
    ],
    "references": [
        "[https://github.com/strimzi/strimzi-kafka-operator/issues/6046](https://github.com/strimzi/strimzi-kafka-operator/issues/6046)"
    ]
}
```

### Step 5: Implement mitigation (2 minutes)

Click on How To Mitigate -> Details. What are the recommended changes to fix this problem?

Use `diff -y` to see the changes before applying them.

```bash
$ diff -y kafka-metrics-01.yaml kafka-metrics-00.yaml
  entityOperator:						                          entityOperator:
    template:							                              template:
      topicOperatorContainer:					                    topicOperatorContainer:
        env:							                                  env:
        - name: STRIMZI_USE_ZOOKEEPER_TOPIC_STORE           - name: STRIMZI_USE_ZOOKEEPER_TOPIC_STORE
          value: "false"				                    |	        value: "true"
    topicOperator:						                          topicOperator:
							                                      >	    startupProbe:
							                                      >	      initialDelaySeconds: 60
							                                      >	      timeoutSeconds: 5 
      resources:						                              resources:
        limits:							                                limits:
          cpu: 60m					                        |	        cpu: 500m
          memory: 540Mi						                            memory: 540Mi
        requests:						                                requests:
          cpu: 20m					                        |	        cpu: 100m
          memory: 300Mi						                            memory: 300Mi
```

Apply the recommended Prequel mitigation.

```bash
$ kubectl -n strimzi apply -f ./kafka-metrics-00.yaml
```

Watch the `kafkatopics.kafka.strimzi.io` resources to ensure the new topic is created.

```bash
$ kubectl -n strimzi get kafkatopics.kafka.strimzi.io -w
NAME                                                                                               CLUSTER      PARTITIONS   REPLICATION FACTOR   READY
topic-00                                                                                           my-cluster   3            1                    True
topic-01                                                                                           my-cluster   3            1                    True
```

## Key Takeaways

* Reliability problems can be challenging to detect using just metrics
* Creating detections that join data across metrics, events, and logs can enable the creation of detections with low signal-to-noise ratios
* Relability intelligence can reduce the time to learn about known failure
