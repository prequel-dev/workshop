#!/usr/bin/env bash

kubectl -n rabbitmq apply -f ./rabbitmq-podmonitor.yaml
kubectl -n strimzi apply -f ./strimzi-entity-operator-podmonitor.yaml
kubectl -n strimzi apply -f ./strimzi-kafka-podmonitor.yaml
kubectl -n strimzi apply -f ./strimzi-zookeeper-podmonitor.yaml
