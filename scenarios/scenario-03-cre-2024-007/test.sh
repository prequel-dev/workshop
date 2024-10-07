#!/bin/bash

pushd "$(mktemp -d)" || exit 1

set -x
kubectl -n rabbitmq exec import-definitions-v3-server-0 -c rabbitmq -- rabbitmqadmin \
  --format=raw_json --vhost=hello-world --username=hello-world \
  --password=hello-world --host=import-definitions-v3.rabbitmq.svc \
  list queues 

popd || exit 1
