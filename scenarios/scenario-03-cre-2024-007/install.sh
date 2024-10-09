#!/usr/bin/env bash

kubectl -n rabbitmq create configmap definitions --from-file=definitions.json
kubectl -n rabbitmq apply -f ./rabbitmq-00.yaml
