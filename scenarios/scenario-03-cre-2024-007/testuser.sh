#!/usr/bin/env bash

kubectl -n rabbitmq exec import-definitions-v4-server-1 -c rabbitmq -- rabbitmqctl add_user test test
kubectl -n rabbitmq exec import-definitions-v4-server-1 -c rabbitmq -- rabbitmqctl set_user_tags test administrator
kubectl -n rabbitmq exec import-definitions-v4-server-1 -c rabbitmq -- rabbitmqctl set_permissions -p "/" test ".*" ".*" ".*"
