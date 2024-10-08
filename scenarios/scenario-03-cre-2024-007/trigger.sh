#!/bin/bash

JOB_MANIFEST="messages_generator/k8s/deploy.yaml"
JOB_NAME="messages-generator-job"
CHECK_INTERVAL=5

echo "Deploying the Job..."
kubectl -n rabbitmq apply -f $JOB_MANIFEST

echo "Waiting for the Job '$JOB_NAME' to complete..."
while true; do
    COMPLETION_TIME=$(kubectl -n rabbitmq get job $JOB_NAME -o jsonpath='{.status.completionTime}')
    if [ -n "$COMPLETION_TIME" ]; then
        echo "Job '$JOB_NAME' completed at $COMPLETION_TIME."
        break
    else
        echo "Job '$JOB_NAME' is still running. Checking again in $CHECK_INTERVAL seconds..."
        sleep $CHECK_INTERVAL
    fi
done

kubectl -n rabbitmq delete pod my-rabbitmq-cluster-server-0 my-rabbitmq-cluster-server-1 --force

echo "Trigger completed"
