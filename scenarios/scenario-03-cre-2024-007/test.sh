#!/bin/bash

pushd "$(mktemp -d)" || exit 1

set -x
kubectl -n rabbitmq exec import-definitions-v4-server-0 -c rabbitmq -- rabbitmqadmin \
  --format=raw_json --vhost=/ --username=guest \
  --password=guest --host=import-definitions-v4.rabbitmq.svc \
  list queues 

popd || exit 1
