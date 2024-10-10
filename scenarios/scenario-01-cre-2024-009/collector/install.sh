#!/usr/bin/env bash

set -x

kubectl create namespace monitoring
kubectl -n monitoring create -f ../otel-config-00.yaml
kubectl -n monitoring apply -f ./deploy.yaml
